set check_function_bodies=false;
CREATE OR REPLACE FUNCTION public.add_branch_member(p_email text, p_role_code text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare branch uuid:=academy_private.current_branch_id(); target uuid; role uuid; begin
 if branch is null or not public.has_permission('system.users.manage') then raise exception 'Branch user management permission required.'; end if;
 if p_role_code not in('ADMIN','ACADEMIC_DIRECTOR','OPERATOR','TEACHER') then raise exception 'Choose an operational role.'; end if;
 select id into target from auth.users where lower(email)=lower(btrim(p_email)) and email_confirmed_at is not null;
 if target is null then raise exception 'This person must sign up and verify their email first.'; end if;
 select id into role from public.system_roles where code=p_role_code and is_active;
 if role is null then raise exception 'Role is unavailable.'; end if;
 insert into public.profiles(id,display_name) select id,coalesce(nullif(raw_user_meta_data->>'full_name',''),email) from auth.users where id=target on conflict(id) do nothing;
 insert into public.branch_memberships values(branch,target,true) on conflict(branch_id,user_id) do update set is_active=true;
 if exists(select 1 from public.branch_owners ow join public.branches b on b.organization_id=ow.organization_id where b.id=branch and ow.user_id=target) and p_role_code<>'ADMIN' then raise exception 'The institution owner must retain admin access.';end if;
 update public.user_role_assignments set is_active=false,effective_to=current_date where profile_id=target and scope_branch_id=branch and is_active;
 insert into public.user_role_assignments(profile_id,role_id,branch_id,assigned_by) values(target,role,branch,auth.uid());
 insert into public.audit_events(actor_profile_id,branch_id,entity_type,entity_id,action,reason) values(auth.uid(),branch,'USER',target::text,'ADD_BRANCH_MEMBER','Verified user added to this branch only.');
 return jsonb_build_object('id',target,'branchId',branch);
end $function$
;

CREATE OR REPLACE FUNCTION academy_private.current_branch_id()
 RETURNS uuid
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare chosen uuid; begin
 chosen:=nullif(current_setting('public.branch_override',true),'')::uuid;
 if chosen is null then chosen:=nullif(coalesce(nullif(current_setting('request.headers',true),''),'{}')::jsonb->>'x-academy-branch','')::uuid; end if;
 if chosen is null or auth.uid() is null or not exists(select 1 from public.branch_memberships m join public.branches b on b.id=m.branch_id where m.user_id=auth.uid() and m.branch_id=chosen and m.is_active and b.is_active) then return null; end if;
 return chosen;
 exception when invalid_text_representation then return null;
end $function$
;

CREATE OR REPLACE FUNCTION public.has_permission(p_permission_code text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
 select auth.uid() is not null and academy_private.current_branch_id() is not null and exists(select 1 from public.user_role_assignments ura join public.system_roles sr on sr.id=ura.role_id join public.role_permissions rp on rp.role_id=sr.id join public.permissions p on p.id=rp.permission_id join public.profiles pr on pr.id=ura.profile_id where ura.profile_id=auth.uid() and ura.scope_branch_id=academy_private.current_branch_id() and ura.is_active and sr.is_active and pr.status='ACTIVE' and ura.effective_from<=current_date and(ura.effective_to is null or ura.effective_to>=current_date) and p.code=p_permission_code);
$function$
;

CREATE OR REPLACE FUNCTION academy_private.is_branch_member(p_profile uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$ select academy_private.current_branch_id() is not null and exists(select 1 from public.branch_memberships where user_id=p_profile and branch_id=academy_private.current_branch_id() and is_active); $function$
;

CREATE OR REPLACE FUNCTION public.link_staff_profile_by_email(p_email text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  v_email text := lower(nullif(btrim(coalesce(p_email, '')), ''));
  v_user_id uuid;
  v_staff_ids uuid[];
begin
  if v_email is null then
    return null;
  end if;

  select u.id into v_user_id
  from auth.users u
  where lower(u.email) = v_email
    and u.email_confirmed_at is not null
  order by u.created_at asc
  limit 1;

  if v_user_id is null
     or not exists (select 1 from public.profiles where id = v_user_id)
     or exists (select 1 from public.staff where profile_id = v_user_id) then
    return null;
  end if;

  select array_agg(s.id) into v_staff_ids
  from public.staff s
  where s.profile_id is null
    and lower(s.email) = v_email
    and s.status in ('ACTIVE', 'ON_LEAVE');

  if coalesce(array_length(v_staff_ids, 1), 0) <> 1 then
    return null;
  end if;

  update public.staff
  set profile_id = v_user_id
  where id = v_staff_ids[1]
    and profile_id is null;

  insert into public.audit_events(entity_type, entity_id, action, reason, metadata)
  values (
    'STAFF',
    v_staff_ids[1]::text,
    'LINK_PROFILE',
    'Linked to Auth profile by confirmed email match.',
    jsonb_build_object('profile_id', v_user_id, 'email', v_email)
  );

  return v_staff_ids[1];
end;
$function$
;

CREATE OR REPLACE FUNCTION public.list_my_branches()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
 select coalesce(jsonb_agg(jsonb_build_object('id',b.id,'name',b.name,'slug',b.slug,'organizationName',o.name,'isOwner',ow.user_id=auth.uid()) order by b.created_at),'[]') from public.branches b join public.branch_memberships m on m.branch_id=b.id and m.user_id=auth.uid() and m.is_active join public.organizations o on o.id=b.organization_id left join public.branch_owners ow on ow.organization_id=o.id where b.is_active;
$function$
;

CREATE OR REPLACE FUNCTION public.my_erp_context()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin

 return (select jsonb_build_object(
    'profile_id', p.id,
    'display_name', p.display_name,
    'status', p.status,
    'staff_id', s.id,
    'staff_no', s.staff_no,
    'staff_name', s.full_name,
    'roles', coalesce((
      select jsonb_agg(distinct sr.code order by sr.code)
      from public.user_role_assignments ura
      join public.system_roles sr on sr.id = ura.role_id
      where ura.profile_id = p.id
        and ura.is_active
        and ura.effective_from <= current_date
        and (ura.effective_to is null or ura.effective_to >= current_date)
        and sr.is_active
    ), '[]'::jsonb),
    'permissions', coalesce((
      select jsonb_agg(distinct pe.code order by pe.code)
      from public.user_role_assignments ura
      join public.system_roles sr on sr.id = ura.role_id
      join public.role_permissions rp on rp.role_id = sr.id
      join public.permissions pe on pe.id = rp.permission_id
      where ura.profile_id = p.id
        and ura.is_active
        and ura.effective_from <= current_date
        and (ura.effective_to is null or ura.effective_to >= current_date)
        and sr.is_active
    ), '[]'::jsonb)
  )
  from public.profiles p
  left join public.staff s on s.profile_id = p.id
  where p.id = auth.uid());
end
$function$
;

CREATE OR REPLACE FUNCTION public.open_academy_branch(p_request_id uuid, p_name text, p_slug text, p_organization_name text DEFAULT NULL::text, p_demo boolean DEFAULT true)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare actor uuid:=auth.uid(); org uuid; branch uuid; yr uuid; cl uuid; prog uuid; offering uuid; rule uuid; entry record; subject uuid; payload jsonb; result jsonb; old public.branch_open_commands; prior text:=current_setting('public.branch_override',true); begin
 if actor is null or not exists(select 1 from auth.users where id=actor and email_confirmed_at is not null) then raise exception 'Verify your email before opening a branch.'; end if;
 if p_request_id is null or length(btrim(p_name)) not between 2 and 120 or p_slug!~'^[a-z0-9][a-z0-9-]{2,62}$' then raise exception 'Enter a branch name and a unique URL slug (3–63 lowercase letters, digits or hyphens).'; end if;
 payload:=jsonb_build_object('name',btrim(p_name),'slug',p_slug,'organizationName',p_organization_name,'demo',p_demo);
 perform pg_advisory_xact_lock(hashtextextended(actor::text,7));
 select * into old from public.branch_open_commands where user_id=actor and request_id=p_request_id;
 if found then if old.payload<>payload then raise exception 'Request already used for different input.'; end if; return old.result; end if;
 select organization_id into org from public.branch_owners where user_id=actor;
 if org is null then
  if exists(select 1 from public.branch_memberships where user_id=actor) then raise exception 'Only the institution owner can open branches.'; end if;
  if length(btrim(coalesce(p_organization_name,''))) not between 2 and 120 then raise exception 'Enter your institution name for the first branch.'; end if;
  insert into public.organizations(code,name,setup_completed_at,setup_identity_confirmed_at) values('ORG-'||substr(replace(gen_random_uuid()::text,'-',''),1,12),btrim(p_organization_name),now(),now()) returning id into org;
  insert into public.branch_owners values(org,actor);
 end if;
 insert into public.profiles(id,display_name) select actor,coalesce(nullif(raw_user_meta_data->>'full_name',''),email) from auth.users where id=actor on conflict(id) do nothing;
 insert into public.branches(organization_id,code,name,slug) values(org,upper(p_slug),btrim(p_name),p_slug) returning id into branch;
 insert into public.branch_memberships values(branch,actor,true);
 perform set_config('public.branch_override',branch::text,true);
 insert into public.user_role_assignments(profile_id,role_id,branch_id,assigned_by) select actor,id,branch,actor from public.system_roles where code='ADMIN';
 insert into public.academic_years(organization_id,name,starts_on,ends_on) values(org,extract(year from current_date)::text,date_trunc('year',current_date)::date,(date_trunc('year',current_date)+interval '1 year - 1 day')::date) returning id into yr;
 insert into public.classes(organization_id,code,name,sort_order) values(org,'CLASS_8','Class 8',8),(org,'CLASS_9','Class 9',9),(org,'CLASS_10','Class 10',10),(org,'CLASS_11','Class 11',11),(org,'CLASS_12','Class 12',12),(org,'JOB','Job Preparation',20);
 insert into public.programs(organization_id,code,name,description) values(org,'JR_SCHOLARSHIP','Junior Scholarship Programme','Starter academic template; review before opening intake.'),(org,'SSC','SSC Preparation Programme','Secondary school preparation.'),(org,'HSC','HSC Preparation Programme','Higher secondary preparation.'),(org,'JOB','Job Preparation Programme','Competitive examination preparation.');
 insert into public.subjects(organization_id,code,name) values(org,'BANGLA','Bangla'),(org,'ENGLISH','English'),(org,'MATH','Mathematics'),(org,'SCIENCE','General Science'),(org,'PHYSICS','Physics'),(org,'CHEMISTRY','Chemistry'),(org,'BIOLOGY','Biology'),(org,'ICT','ICT'),(org,'GK','General Knowledge'),(org,'REASONING','Reasoning'),(org,'BANGLADESH','Bangladesh Affairs');
 insert into public.academic_groups(organization_id,code,name) values(org,'GENERAL','General'),(org,'SCIENCE','Science'),(org,'HUMANITIES','Humanities'),(org,'BUSINESS','Business Studies');
 insert into public.guardian_relationships(organization_id,code,name) values(org,'FATHER','Father'),(org,'MOTHER','Mother'),(org,'GUARDIAN','Guardian');
 insert into public.lead_sources(organization_id,code,name) values(org,'WEB','Website'),(org,'WALK_IN','Walk-in'),(org,'REFERRAL','Referral');
 insert into public.business_rule_versions(domain,rule_key,version,status,payload,change_reason) values('academics','batch_capacity_policy',1,'ACTIVE','{"max_students":12}','Starter capacity; edit after branch review') returning id into rule;
 for entry in select * from(values('JR_SCHOLARSHIP','CLASS_8'),('SSC','CLASS_10'),('HSC','CLASS_12'),('JOB','JOB')) as starter(program_code,class_code) loop
  select id into cl from public.classes where scope_branch_id=branch and code=entry.class_code;
  select id into prog from public.programs where scope_branch_id=branch and code=entry.program_code;
  insert into public.programme_offerings(organization_id,branch_id,academic_year_id,class_id,program_id,code,name,status,is_website_visible,is_accepting_applications,created_by)
   select org,branch,yr,cl,prog,entry.program_code||'-'||extract(year from current_date),name,'ACTIVE',false,false,actor from public.programs where id=prog returning id into offering;
  insert into public.batches(organization_id,branch_id,academic_year_id,class_id,program_id,code,name,capacity,created_by,offering_id,capacity_policy_version_id) values(org,branch,yr,cl,prog,entry.program_code||'-A',entry.program_code||' Starter Batch',12,actor,offering,rule);
  insert into public.programme_offering_subjects(offering_id,subject_id,sort_order) select offering,id,row_number() over(order by code) from public.subjects where scope_branch_id=branch and(case entry.program_code when 'JR_SCHOLARSHIP' then code in('BANGLA','ENGLISH','MATH','SCIENCE') when 'SSC' then code in('BANGLA','ENGLISH','MATH','SCIENCE','ICT') when 'HSC' then code in('BANGLA','ENGLISH','PHYSICS','CHEMISTRY','BIOLOGY','ICT') else code in('BANGLA','ENGLISH','MATH','GK','REASONING','BANGLADESH') end);
 end loop;
 insert into public.audit_events(actor_profile_id,branch_id,entity_type,entity_id,action,reason) values(actor,branch,'BRANCH',branch::text,'OPEN_BRANCH','Opened with editable academic templates; no fictional people or finance.');
 result:=jsonb_build_object('id',branch,'slug',p_slug,'name',btrim(p_name));
 insert into public.branch_open_commands values(actor,p_request_id,payload,result);
 if p_demo then perform public.seed_demo_branch(); end if;
 perform set_config('public.branch_override',coalesce(prior,''),true);
 return result;
end $function$
;

CREATE OR REPLACE FUNCTION academy_private.protect_branch_scope()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$ begin
 if TG_OP='UPDATE' and new.scope_branch_id is distinct from old.scope_branch_id then raise exception 'A record cannot move to another branch.'; end if;
 if to_jsonb(new) ? 'branch_id' and nullif(to_jsonb(new)->>'branch_id','') is not null and (to_jsonb(new)->>'branch_id')::uuid<>new.scope_branch_id then raise exception 'Branch placement must match record scope.'; end if;
 return new; end $function$
;

CREATE OR REPLACE FUNCTION academy_private.public_branch_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
 select id from public.branches where slug=coalesce(nullif(current_setting('request.headers',true),''),'{}')::jsonb->>'x-academy-public-branch' and is_active;
$function$
;

CREATE OR REPLACE FUNCTION public.remove_branch_member(p_email text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare branch uuid:=academy_private.current_branch_id();target uuid;begin
 if branch is null or not public.has_permission('system.users.manage') then raise exception 'Branch user management permission required.';end if;
 select u.id into target from auth.users u join public.branch_memberships m on m.user_id=u.id and m.branch_id=branch where lower(u.email)=lower(btrim(p_email));
 if target is null then raise exception 'This person is not a member of this branch.';end if;
 if target=auth.uid() or exists(select 1 from public.branch_owners o join public.branches b on b.organization_id=o.organization_id where b.id=branch and o.user_id=target) then raise exception 'The owner and your own active membership cannot be removed.';end if;
 update public.branch_memberships set is_active=false where user_id=target and branch_id=branch;
 update public.user_role_assignments set is_active=false,effective_to=current_date where profile_id=target and scope_branch_id=branch;
 insert into public.audit_events(actor_profile_id,branch_id,entity_type,entity_id,action,reason) values(auth.uid(),branch,'USER',target::text,'REMOVE_BRANCH_MEMBER','Access removed from this branch only.');return jsonb_build_object('id',target);
end $function$
;

CREATE OR REPLACE FUNCTION public.save_academy_identity(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare branch uuid:=academy_private.current_branch_id();org uuid;owner uuid;before_data jsonb;begin
 if branch is null or not public.has_permission('system.settings.manage') then raise exception 'Branch settings permission required.';end if;
 if length(btrim(coalesce(p_input->>'name',''))) not between 2 and 160 or length(btrim(coalesce(p_input->>'branch_name',''))) not between 2 and 160 then raise exception 'Enter institution and branch names.';end if;
 select organization_id into org from public.branches where id=branch;select user_id into owner from public.branch_owners where organization_id=org;
 if (select name from public.organizations where id=org)<>btrim(p_input->>'name') then
  if owner is distinct from auth.uid() then raise exception 'Only the institution owner can change the institution name.';end if;
  update public.organizations set name=btrim(p_input->>'name') where id=org;
 end if;
 select to_jsonb(b) into before_data from public.branches b where id=branch;
 update public.branches set name=btrim(p_input->>'branch_name') where id=branch;
 insert into public.audit_events(actor_profile_id,branch_id,entity_type,entity_id,action,reason,before_data,after_data) values(auth.uid(),branch,'BRANCH',branch::text,'UPDATE_IDENTITY','Reviewed institution and branch names',before_data,p_input);
 return jsonb_build_object('id',branch);
end $function$
;

CREATE OR REPLACE FUNCTION public.staff_link_profile_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  perform public.link_staff_profile_by_email(new.email);
  return null;
end;
$function$
;

set check_function_bodies=true;
