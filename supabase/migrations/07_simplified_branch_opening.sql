set search_path=academy,extensions,public;
alter table academy.branches add column slug text unique;
create or replace function academy.list_my_branches() returns jsonb language sql stable security definer set search_path=pg_catalog,academy as $$
 select coalesce(jsonb_agg(jsonb_build_object('id',b.id,'name',b.name,'slug',b.slug,'organizationName',o.name,'isOwner',ow.user_id=auth.uid()) order by b.created_at),'[]') from academy.branches b join academy.branch_memberships m on m.branch_id=b.id and m.user_id=auth.uid() and m.is_active join academy.organizations o on o.id=b.organization_id left join academy.branch_owners ow on ow.organization_id=o.id where b.is_active;
$$;
create or replace function academy.open_academy_branch(p_request_id uuid,p_name text,p_slug text,p_organization_name text default null) returns jsonb language plpgsql security definer set search_path=pg_catalog,academy as $$
declare actor uuid:=auth.uid(); org uuid; branch uuid; yr uuid; cl uuid; prog uuid; offering uuid; rule uuid; entry record; subject uuid; payload jsonb; result jsonb; old academy.branch_open_commands; prior text:=current_setting('academy.branch_override',true); begin
 if actor is null or not exists(select 1 from auth.users where id=actor and email_confirmed_at is not null) then raise exception 'Verify your email before opening a branch.'; end if;
 if p_request_id is null or length(btrim(p_name)) not between 2 and 120 or p_slug!~'^[a-z0-9][a-z0-9-]{2,62}$' then raise exception 'Enter a branch name and a unique URL slug (3–63 lowercase letters, digits or hyphens).'; end if;
 payload:=jsonb_build_object('name',btrim(p_name),'slug',p_slug,'organizationName',p_organization_name);
 perform pg_advisory_xact_lock(hashtextextended(actor::text,7));
 select * into old from academy.branch_open_commands where user_id=actor and request_id=p_request_id;
 if found then if old.payload<>payload then raise exception 'Request already used for different input.'; end if; return old.result; end if;
 select organization_id into org from academy.branch_owners where user_id=actor;
 if org is null then
  if exists(select 1 from academy.branch_memberships where user_id=actor) then raise exception 'Only the institution owner can open branches.'; end if;
  if length(btrim(coalesce(p_organization_name,''))) not between 2 and 120 then raise exception 'Enter your institution name for the first branch.'; end if;
  insert into academy.organizations(code,name,setup_completed_at,setup_identity_confirmed_at) values('ORG-'||substr(replace(gen_random_uuid()::text,'-',''),1,12),btrim(p_organization_name),now(),now()) returning id into org;
  insert into academy.branch_owners values(org,actor);
 end if;
 insert into academy.profiles(id,display_name) select actor,coalesce(nullif(raw_user_meta_data->>'full_name',''),email) from auth.users where id=actor on conflict(id) do nothing;
 insert into academy.branches(organization_id,code,name,slug) values(org,upper(p_slug),btrim(p_name),p_slug) returning id into branch;
 insert into academy.branch_memberships values(branch,actor,true);
 perform set_config('academy.branch_override',branch::text,true);
 insert into academy.user_role_assignments(profile_id,role_id,branch_id,assigned_by) select actor,id,branch,actor from academy.system_roles where code='ADMIN';
 insert into academy.academic_years(organization_id,name,starts_on,ends_on) values(org,extract(year from current_date)::text,date_trunc('year',current_date)::date,(date_trunc('year',current_date)+interval '1 year - 1 day')::date) returning id into yr;
 insert into academy.classes(organization_id,code,name,sort_order) values(org,'CLASS_8','Class 8',8),(org,'CLASS_9','Class 9',9),(org,'CLASS_10','Class 10',10),(org,'CLASS_11','Class 11',11),(org,'CLASS_12','Class 12',12),(org,'JOB','Job Preparation',20);
 insert into academy.programs(organization_id,code,name,description) values(org,'JR_SCHOLARSHIP','Junior Scholarship Programme','Starter academic template; review before opening intake.'),(org,'SSC','SSC Preparation Programme','Secondary school preparation.'),(org,'HSC','HSC Preparation Programme','Higher secondary preparation.'),(org,'JOB','Job Preparation Programme','Competitive examination preparation.');
 insert into academy.subjects(organization_id,code,name) values(org,'BANGLA','Bangla'),(org,'ENGLISH','English'),(org,'MATH','Mathematics'),(org,'SCIENCE','General Science'),(org,'PHYSICS','Physics'),(org,'CHEMISTRY','Chemistry'),(org,'BIOLOGY','Biology'),(org,'ICT','ICT'),(org,'GK','General Knowledge'),(org,'REASONING','Reasoning'),(org,'BANGLADESH','Bangladesh Affairs');
 insert into academy.academic_groups(organization_id,code,name) values(org,'GENERAL','General'),(org,'SCIENCE','Science'),(org,'HUMANITIES','Humanities'),(org,'BUSINESS','Business Studies');
 insert into academy.guardian_relationships(organization_id,code,name) values(org,'FATHER','Father'),(org,'MOTHER','Mother'),(org,'GUARDIAN','Guardian');
 insert into academy.lead_sources(organization_id,code,name) values(org,'WEB','Website'),(org,'WALK_IN','Walk-in'),(org,'REFERRAL','Referral');
 insert into academy.business_rule_versions(domain,rule_key,version,status,payload,change_reason) values('academics','batch_capacity_policy',1,'ACTIVE','{"max_students":12}','Starter capacity; edit after branch review') returning id into rule;
 for entry in select * from(values('JR_SCHOLARSHIP','CLASS_8'),('SSC','CLASS_10'),('HSC','CLASS_12'),('JOB','JOB')) as starter(program_code,class_code) loop
  select id into cl from academy.classes where scope_branch_id=branch and code=entry.class_code;
  select id into prog from academy.programs where scope_branch_id=branch and code=entry.program_code;
  insert into academy.programme_offerings(organization_id,branch_id,academic_year_id,class_id,program_id,code,name,status,is_website_visible,is_accepting_applications,created_by)
   select org,branch,yr,cl,prog,entry.program_code||'-'||extract(year from current_date),name,'ACTIVE',false,false,actor from academy.programs where id=prog returning id into offering;
  insert into academy.batches(organization_id,branch_id,academic_year_id,class_id,program_id,code,name,capacity,created_by,offering_id,capacity_policy_version_id) values(org,branch,yr,cl,prog,entry.program_code||'-A',entry.program_code||' Starter Batch',12,actor,offering,rule);
  insert into academy.programme_offering_subjects(offering_id,subject_id,sort_order) select offering,id,row_number() over(order by code) from academy.subjects where scope_branch_id=branch and(case entry.program_code when 'JR_SCHOLARSHIP' then code in('BANGLA','ENGLISH','MATH','SCIENCE') when 'SSC' then code in('BANGLA','ENGLISH','MATH','SCIENCE','ICT') when 'HSC' then code in('BANGLA','ENGLISH','PHYSICS','CHEMISTRY','BIOLOGY','ICT') else code in('BANGLA','ENGLISH','MATH','GK','REASONING','BANGLADESH') end);
 end loop;
 insert into academy.audit_events(actor_profile_id,branch_id,entity_type,entity_id,action,reason) values(actor,branch,'BRANCH',branch::text,'OPEN_BRANCH','Opened with editable academic templates; no fictional people or finance.');
 result:=jsonb_build_object('id',branch,'slug',p_slug,'name',btrim(p_name));
 insert into academy.branch_open_commands values(actor,p_request_id,payload,result);
 perform set_config('academy.branch_override',coalesce(prior,''),true);
 return result;
end $$;
create or replace function academy.add_branch_member(p_email text,p_role_code text) returns jsonb language plpgsql security definer set search_path=pg_catalog,academy as $$
declare branch uuid:=academy_private.current_branch_id(); target uuid; role uuid; begin
 if branch is null or not academy.has_permission('system.users.manage') then raise exception 'Branch user management permission required.'; end if;
 if p_role_code not in('ADMIN','ACADEMIC_DIRECTOR','OPERATOR','TEACHER') then raise exception 'Choose an operational role.'; end if;
 select id into target from auth.users where lower(email)=lower(btrim(p_email)) and email_confirmed_at is not null;
 if target is null then raise exception 'This person must sign up and verify their email first.'; end if;
 select id into role from academy.system_roles where code=p_role_code and is_active;
 if role is null then raise exception 'Role is unavailable.'; end if;
 insert into academy.profiles(id,display_name) select id,coalesce(nullif(raw_user_meta_data->>'full_name',''),email) from auth.users where id=target on conflict(id) do nothing;
 insert into academy.branch_memberships values(branch,target,true) on conflict(branch_id,user_id) do update set is_active=true;
 if exists(select 1 from academy.branch_owners ow join academy.branches b on b.organization_id=ow.organization_id where b.id=branch and ow.user_id=target) and p_role_code<>'ADMIN' then raise exception 'The institution owner must retain admin access.';end if;
 update academy.user_role_assignments set is_active=false,effective_to=current_date where profile_id=target and scope_branch_id=branch and is_active;
 insert into academy.user_role_assignments(profile_id,role_id,branch_id,assigned_by) values(target,role,branch,auth.uid());
 insert into academy.audit_events(actor_profile_id,branch_id,entity_type,entity_id,action,reason) values(auth.uid(),branch,'USER',target::text,'ADD_BRANCH_MEMBER','Verified user added to this branch only.');
 return jsonb_build_object('id',target,'branchId',branch);
end $$;
revoke all on function academy.list_my_branches(),academy.open_academy_branch(uuid,text,text,text),academy.add_branch_member(text,text) from public,anon;
grant execute on function academy.list_my_branches(),academy.open_academy_branch(uuid,text,text,text),academy.add_branch_member(text,text) to authenticated;
reset search_path;
