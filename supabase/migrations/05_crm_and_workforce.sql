set check_function_bodies=false;
CREATE OR REPLACE FUNCTION public.academy_setup_status()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
 select jsonb_build_object('completed',true,'ready',true,'academyName',o.name,'steps',jsonb_build_array(jsonb_build_object('id','directory','title','Review classes, subjects and programmes','href','/dashboard/crm/manage','done',exists(select 1 from public.classes)),jsonb_build_object('id','offering','title','Review programme offerings and public intake','href','/dashboard/academics/offerings','done',exists(select 1 from public.programme_offerings)),jsonb_build_object('id','batches','title','Review batch capacity','href','/dashboard/academics/batches','done',exists(select 1 from public.batches)))) from public.organizations o where public.has_permission('dashboard.view');
$function$
;

CREATE OR REPLACE FUNCTION public.assign_prospect_staff(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare p public.prospects; chosen uuid:=nullif(p_input->>'staff_id','')::uuid;
begin
 if auth.uid() is null or not public.has_permission('crm.prospects.manage') then raise exception 'CRM management permission required.'; end if;
 if length(btrim(coalesce(p_input->>'reason',''))) not between 5 and 500 then raise exception 'Assignment reason required.'; end if;
 if chosen is not null and not exists(select 1 from public.staff where id=chosen and status in('ACTIVE','ON_LEAVE')) then raise exception 'Choose an active staff member.'; end if;
 select * into p from public.prospects where id=(p_input->>'prospect_id')::uuid for update;
 if p.id is null then raise exception 'Prospect not found.'; end if;
 if chosen is not distinct from p.assigned_to_staff_id then return jsonb_build_object('id',p.id); end if;
 update public.prospects set assigned_to_staff_id=chosen where id=p.id;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(auth.uid(),'PROSPECT',p.id::text,'ASSIGN_FOLLOWUP_STAFF',p_input->>'reason',jsonb_build_object('staff_id',p.assigned_to_staff_id),jsonb_build_object('staff_id',chosen));
 return jsonb_build_object('id',p.id);
end $function$
;

CREATE OR REPLACE FUNCTION public.audit_event_list(p_correlation uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if auth.uid() is null or not public.has_permission('audit.view') then raise exception 'Audit permission required.'; end if;
 return coalesce((select jsonb_agg(row_data order by occurred_at desc,id desc) from (
 select e.id,e.occurred_at,to_jsonb(e)||jsonb_build_object(
 'actor_name',coalesce(e.metadata->>'actor_name',s.full_name,p.display_name),
 'actor_staff_no',coalesce(e.metadata->>'actor_staff_no',s.staff_no),
 'actor_role_code',coalesce(e.actor_role_code,(select string_agg(distinct r.code,', ' order by r.code) from public.user_role_assignments a join public.system_roles r on r.id=a.role_id where a.profile_id=e.actor_profile_id and a.effective_from<=e.occurred_at::date and (a.effective_to is null or a.effective_to>=e.occurred_at::date))),
 'identity_snapshot',e.metadata ? 'actor_name') as row_data
 from public.audit_events e left join public.profiles p on p.id=e.actor_profile_id
 left join public.staff s on s.id=e.actor_staff_id or (e.actor_staff_id is null and s.profile_id=e.actor_profile_id)
 where p_correlation is null or e.correlation_id=p_correlation order by e.occurred_at desc,e.id desc limit 250
 ) rows),'[]'::jsonb);
end $function$
;

CREATE OR REPLACE FUNCTION public.audit_event_page(p_filters jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare page_no integer:=greatest(1,least(coalesce((p_filters->>'page')::integer,1),100000)); page_size integer:=25;
 q text:=left(btrim(coalesce(p_filters->>'q','')),160); entity text:=left(coalesce(p_filters->>'entity',''),80); action_value text:=left(coalesce(p_filters->>'action',''),80);
 from_day date:=nullif(p_filters->>'from','')::date; to_day date:=nullif(p_filters->>'to','')::date;
 day_start timestamptz:=(now() at time zone 'Asia/Dhaka')::date::timestamp at time zone 'Asia/Dhaka'; total_rows bigint; rows jsonb; activity jsonb;
begin
 if auth.uid() is null or not public.has_permission('audit.view') then raise exception 'Audit permission required.';end if;
 if from_day is not null and to_day is not null and from_day>to_day then raise exception 'Start date must be on or before end date.';end if;
 with matched as (
 select e.id,e.occurred_at,e.action,e.entity_type,e.entity_id,e.reason,e.actor_profile_id,
 coalesce(e.metadata->>'actor_name',s.full_name,p.display_name) actor_name,
 coalesce(e.metadata->>'actor_staff_no',s.staff_no) actor_staff_no,
 coalesce(e.actor_role_code,(select string_agg(distinct r.code,', ' order by r.code) from public.user_role_assignments a join public.system_roles r on r.id=a.role_id where a.profile_id=e.actor_profile_id and a.effective_from<=e.occurred_at::date and (a.effective_to is null or a.effective_to>=e.occurred_at::date))) actor_role_code
 from public.audit_events e left join public.profiles p on p.id=e.actor_profile_id
 left join public.staff s on s.id=e.actor_staff_id or (e.actor_staff_id is null and s.profile_id=e.actor_profile_id)
 where (entity='' or e.entity_type=entity) and (action_value='' or e.action=action_value)
 and (from_day is null or e.occurred_at>=from_day::timestamp at time zone 'Asia/Dhaka')
 and (to_day is null or e.occurred_at<(to_day+1)::timestamp at time zone 'Asia/Dhaka')
 and (coalesce(p_filters->>'preset','')<>'invoices' or (e.entity_type='ADMISSION' and e.action='BILL') or (e.entity_type='FINANCE_WORKFLOW' and e.action='RUN_BILLING'))
 and (q='' or position(lower(q) in lower(concat_ws(' ',coalesce(e.metadata->>'actor_name',s.full_name,p.display_name),coalesce(e.metadata->>'actor_staff_no',s.staff_no),e.actor_profile_id::text,e.actor_role_code,replace(e.action,'_',' '),e.action,e.entity_type,e.entity_id,e.reason)))>0)
 ), paged as (select * from matched order by occurred_at desc,id desc limit page_size offset (page_no-1)*page_size)
 select (select count(*) from matched),coalesce((select jsonb_agg(to_jsonb(paged) order by occurred_at desc,id desc) from paged),'[]'::jsonb) into total_rows,rows;
 activity:=jsonb_build_object('date',(now() at time zone 'Asia/Dhaka')::date,
 'admissions',case when public.has_permission('admissions.view') then (select count(distinct entity_id) from public.audit_events where entity_type='ADMISSION' and action='FINALIZE' and occurred_at>=day_start and occurred_at<day_start+interval '1 day') else null end,
 'invoices',case when public.has_permission('finance.view') then (select count(*) from (SELECT NULL::uuid AS "id", NULL::text AS "invoice_no", NULL::uuid AS "admission_id", NULL::uuid AS "student_id", NULL::uuid AS "fee_plan_version_id", NULL::text AS "currency_code", NULL::numeric(12,2) AS "total", NULL::date AS "due_on", NULL::date AS "issued_on", NULL::uuid AS "posted_by", NULL::timestamp with time zone AS "posted_at", NULL::text AS "invoice_kind", NULL::date AS "billing_period" WHERE false) where posted_at>=day_start and posted_at<day_start+interval '1 day') else null end,
 'grossIssued',case when public.has_permission('finance.view') then (select coalesce(sum(total),0) from (SELECT NULL::uuid AS "id", NULL::text AS "invoice_no", NULL::uuid AS "admission_id", NULL::uuid AS "student_id", NULL::uuid AS "fee_plan_version_id", NULL::text AS "currency_code", NULL::numeric(12,2) AS "total", NULL::date AS "due_on", NULL::date AS "issued_on", NULL::uuid AS "posted_by", NULL::timestamp with time zone AS "posted_at", NULL::text AS "invoice_kind", NULL::date AS "billing_period" WHERE false) where posted_at>=day_start and posted_at<day_start+interval '1 day') else null end,
 'collected',case when public.has_permission('finance.view') then (select coalesce(sum(amount),0) from (SELECT NULL::uuid AS "id", NULL::uuid AS "student_id", NULL::uuid AS "payment_method_id", NULL::numeric(12,2) AS "amount", NULL::text AS "currency_code", NULL::text AS "external_reference", NULL::text AS "receipt_no", NULL::uuid AS "posted_by", NULL::timestamp with time zone AS "posted_at", NULL::text AS "reason" WHERE false) where posted_at>=day_start and posted_at<day_start+interval '1 day') else null end,
 'refunds',case when public.has_permission('finance.view') then (select coalesce(sum(a.amount),0) from (SELECT NULL::uuid AS "id", NULL::uuid AS "authorization_id", NULL::text AS "refund_no", NULL::uuid AS "payment_method_id", NULL::text AS "external_reference", NULL::uuid AS "posted_by", NULL::timestamp with time zone AS "posted_at", NULL::text AS "reason" WHERE false) r join (SELECT NULL::uuid AS "id", NULL::uuid AS "payment_id", NULL::uuid AS "invoice_id", NULL::numeric(12,2) AS "amount", NULL::timestamp with time zone AS "created_at", NULL::uuid AS "authorized_by", NULL::text AS "authorization_reason", NULL::uuid AS "correlation_id" WHERE false) a on a.id=r.authorization_id where r.posted_at>=day_start and r.posted_at<day_start+interval '1 day') else null end);
 return jsonb_build_object('rows',rows,'total',total_rows,'page',page_no,'pageSize',page_size,'activity',activity);
end $function$
;

CREATE OR REPLACE FUNCTION public.batch_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 actor uuid:=auth.uid(); req uuid:=nullif(p_input->>'request_id','')::uuid;
 action text:=p_input->>'action'; reason text:=btrim(coalesce(p_input->>'reason',''));
 key public.admission_command_keys; org uuid; batch public.batches;
 offering public.programme_offerings; policy public.business_rule_versions;
 v_requested_capacity integer; occupied integer; before_data jsonb; result jsonb;
begin
 if actor is null or not public.has_permission('academics.manage') then
  raise exception 'Batch management permission required.';
 end if;
 if req is null or length(reason)<5 then raise exception 'Request identity and a reason of at least five characters are required.'; end if;
 if action not in('CREATE_BATCH','EDIT_BATCH') then raise exception 'Unsupported batch action.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));
 select * into key from public.admission_command_keys where request_id=req;
 if found then
  if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity was already used for different input.'; end if;
  return key.result;
 end if;
 select id into org from public.organizations where is_active limit 1;
 select * into policy from public.business_rule_versions where domain='academics'
   and rule_key='batch_capacity_policy' and status='ACTIVE' order by version desc limit 1;
 if org is null or policy.id is null then raise exception 'Organization or active capacity policy is unavailable.'; end if;
 v_requested_capacity:=nullif(p_input->>'capacity','')::integer;
 if v_requested_capacity is null or v_requested_capacity<1 or v_requested_capacity>(policy.payload->>'max_students')::integer then
   raise exception 'Batch capacity must be between 1 and the active policy maximum (%).',policy.payload->>'max_students';
 end if;
 if length(btrim(coalesce(p_input->>'name','')))<2 or length(btrim(coalesce(p_input->>'code','')))<2 then
   raise exception 'Enter a batch code and a recognizable batch name.';
 end if;
 if action='CREATE_BATCH' then
  select * into offering from public.programme_offerings
   where id=(p_input->>'offering_id')::uuid and organization_id=org and status='ACTIVE' for update;
  if offering.id is null then raise exception 'Choose an active offering with a published Fee Plan.'; end if;
  insert into public.batches(organization_id,branch_id,academic_year_id,class_id,program_id,
   code,name,capacity,created_by,offering_id,capacity_policy_version_id)
  values(org,offering.branch_id,offering.academic_year_id,offering.class_id,offering.program_id,
   upper(btrim(p_input->>'code')),btrim(p_input->>'name'),v_requested_capacity,actor,offering.id,policy.id)
  returning * into batch;
  result:=jsonb_build_object('id',batch.id,'status','CREATED');
 else
  select * into batch from public.batches where id=(p_input->>'batch_id')::uuid
    and organization_id=org and offering_id is not null for update;
  if batch.id is null then raise exception 'Batch not found.'; end if;
  before_data:=to_jsonb(batch);
  select count(*) into occupied from public.enrollments where batch_id=batch.id and status='ACTIVE';
  if v_requested_capacity<occupied then raise exception 'Capacity cannot be lower than the % students already enrolled.',occupied; end if;
  update public.batches b set code=upper(btrim(p_input->>'code')),
    name=btrim(p_input->>'name'),capacity=v_requested_capacity,
    capacity_policy_version_id=policy.id,updated_at=now()
  where b.id=batch.id returning b.* into batch;
  result:=jsonb_build_object('id',batch.id,'status','UPDATED');
 end if;
 insert into public.audit_events(correlation_id,actor_profile_id,actor_staff_id,
   entity_type,entity_id,action,reason,before_data,after_data,metadata)
 values(req,actor,(select id from public.staff where profile_id=actor limit 1),
   'BATCH',batch.id::text,action,reason,
   before_data,
   to_jsonb(batch),jsonb_build_object('module','batch_register','offering_id',batch.offering_id));
 insert into public.admission_command_keys(request_id,actor_id,payload,result)
 values(req,actor,p_input,result);
 return result;
end $function$
;

CREATE OR REPLACE FUNCTION public.capture_audit_actor()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare person public.staff; name text; roles text; trace text;
begin
 if new.actor_profile_id is null and exists(select 1 from public.profiles where id=auth.uid()) then new.actor_profile_id:=auth.uid(); end if;
 if new.actor_profile_id is not null then
  select * into person from public.staff where profile_id=new.actor_profile_id;
  new.actor_staff_id:=coalesce(new.actor_staff_id,person.id);
  select display_name into name from public.profiles where id=new.actor_profile_id;
  select string_agg(distinct r.code,', ' order by r.code) into roles from public.user_role_assignments a join public.system_roles r on r.id=a.role_id
   where a.profile_id=new.actor_profile_id and a.is_active and r.is_active and a.effective_from<=current_date and (a.effective_to is null or a.effective_to>=current_date);
  new.actor_role_code:=coalesce(new.actor_role_code,roles,'AUTHENTICATED');
  new.metadata:=new.metadata||jsonb_build_object('actor_name',coalesce(person.full_name,name),'actor_staff_no',person.staff_no,'actor_roles',new.actor_role_code);
 end if;
 trace:=nullif(current_setting('sohoj.workflow_trace',true),'');
 if trace is not null then new.correlation_id:=trace::uuid; end if;
 return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.complete_academy_setup()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if auth.uid() is null or not public.has_permission('system.settings.manage') then raise exception 'Academy setup permission required.'; end if;
 perform pg_advisory_xact_lock(871604);
 if not (public.academy_setup_status()->>'ready')::boolean then raise exception 'Finish all prerequisite settings before opening operations.'; end if;
 update public.organizations set setup_completed_at=now(),setup_completed_by=auth.uid() where is_active;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason) values(auth.uid(),'ACADEMY',(select id::text from public.organizations where is_active),'COMPLETE_SETUP','Reviewed public configuration before opening operations');
 return public.academy_setup_status();
end $function$
;

CREATE OR REPLACE FUNCTION public.create_programme_offering(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_org uuid;
  v_row public.programme_offerings;
  v_reason text := btrim(coalesce(p_input->>'reason',''));
  v_correlation uuid := gen_random_uuid();
begin
 p_input:=p_input||jsonb_build_object('name',coalesce(nullif(btrim(p_input->>'name'),''),(select name from public.programs where id=(p_input->>'program_id')::uuid)));
  if v_actor is null or not public.has_permission('academics.manage') then
    raise exception 'You are not authorized to manage Programme Offerings.';
  end if;
  if length(v_reason)<5 then raise exception 'A change reason of at least five characters is required.'; end if;
  select id into v_org from public.organizations where is_active;
  if v_org is null or not exists (
    select 1 from public.branches b
    join public.academic_years y on y.id=(p_input->>'academic_year_id')::uuid
    join public.classes c on c.id=(p_input->>'class_id')::uuid
    join public.programs p on p.id=(p_input->>'program_id')::uuid
    where b.id=(p_input->>'branch_id')::uuid and b.is_active
      and b.organization_id=v_org and y.organization_id=v_org
      and c.organization_id=v_org and c.is_active
      and p.organization_id=v_org and p.is_active
      and (nullif(p_input->>'group_id','') is null or exists (
        select 1 from public.academic_groups g
        where g.id=(p_input->>'group_id')::uuid
          and g.organization_id=v_org and g.is_active))
  ) then
    raise exception 'Offering context must use active master data from the same organization.';
  end if;
  insert into public.programme_offerings(
    organization_id,branch_id,academic_year_id,class_id,program_id,
    group_id,code,name,created_by
  ) values (
    v_org,(p_input->>'branch_id')::uuid,(p_input->>'academic_year_id')::uuid,
    (p_input->>'class_id')::uuid,(p_input->>'program_id')::uuid,
    nullif(p_input->>'group_id','')::uuid,
    upper(btrim(p_input->>'code')),btrim(p_input->>'name'),v_actor
  ) returning * into v_row;
  insert into public.audit_events(correlation_id,actor_profile_id,actor_staff_id,
    branch_id,entity_type,entity_id,action,reason,after_data)
  values (v_correlation,v_actor,(select id from public.staff where profile_id=v_actor limit 1),
    v_row.branch_id,'PROGRAMME_OFFERING',v_row.id::text,'CREATE',v_reason,to_jsonb(v_row));
  return jsonb_build_object('offering_id',v_row.id,'correlation_id',v_correlation);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.create_staff_member(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_staff public.staff;
  v_role public.staff_roles;
  v_branch public.branches;
  v_subject_id uuid;
  v_subjects jsonb;
  v_mobile text;
  v_joined_on date;
  v_correlation_id uuid := gen_random_uuid();
  v_actor_role text;
begin
  if v_actor is null or not public.has_permission('staff.manage') then
    raise exception 'You are not authorized to create Staff identities.';
  end if;

  if p_input is null or jsonb_typeof(p_input) <> 'object' then
    raise exception 'Staff request must be a JSON object.';
  end if;

  if nullif(btrim(coalesce(p_input->>'full_name','')), '') is null then
    raise exception 'Full name is required.';
  end if;

  select * into v_role
  from public.staff_roles
  where code=upper(btrim(coalesce(p_input->>'staff_role_code','')))
    and is_active;

  if v_role.id is null then
    raise exception 'Select a valid Staff role.';
  end if;

  if nullif(p_input->>'branch_id','') is not null then
    begin
      select * into v_branch
      from public.branches
      where id=(p_input->>'branch_id')::uuid
        and is_active;
    exception when others then
      raise exception 'Selected branch is invalid.';
    end;
  else
    select * into v_branch
    from public.branches
    where id=academy_private.current_branch_id() and is_active
    order by created_at asc
    limit 1;
  end if;

  if v_branch.id is null then
    raise exception 'An active branch is required.';
  end if;

  begin
    v_joined_on := coalesce(
      nullif(p_input->>'joined_on','')::date,
      current_date
    );
  exception when others then
    raise exception 'Joining date is invalid.';
  end;

  v_mobile := nullif(btrim(coalesce(p_input->>'mobile','')), '');

  if v_mobile is not null and exists (
    select 1
    from public.staff s
    where regexp_replace(coalesce(s.mobile,''), '\D', '', 'g')
        = regexp_replace(v_mobile, '\D', '', 'g')
      and s.status in ('ACTIVE','ON_LEAVE')
  ) then
    raise exception 'Another active Staff identity already uses this mobile number.';
  end if;

  insert into public.staff(
    branch_id,
    full_name,
    mobile,
    alternate_mobile,
    email,
    address,
    emergency_contact_name,
    emergency_contact_mobile,
    joined_on,
    status,
    notes,
    created_by
  )
  values(
    v_branch.id,
    btrim(p_input->>'full_name'),
    v_mobile,
    nullif(btrim(coalesce(p_input->>'alternate_mobile','')), ''),
    nullif(lower(btrim(coalesce(p_input->>'email',''))), ''),
    nullif(btrim(coalesce(p_input->>'address','')), ''),
    nullif(btrim(coalesce(p_input->>'emergency_contact_name','')), ''),
    nullif(btrim(coalesce(p_input->>'emergency_contact_mobile','')), ''),
    v_joined_on,
    'ACTIVE',
    nullif(btrim(coalesce(p_input->>'notes','')), ''),
    v_actor
  )
  returning * into v_staff;

  insert into public.staff_role_assignments(
    staff_id,
    staff_role_id,
    branch_id,
    effective_from,
    is_primary,
    assigned_by
  )
  values(
    v_staff.id,
    v_role.id,
    v_branch.id,
    v_joined_on,
    true,
    v_actor
  );

  v_subjects := coalesce(p_input->'subject_ids','[]'::jsonb);

  if jsonb_typeof(v_subjects) <> 'array' then
    raise exception 'Teaching subject selection must be an array.';
  end if;

  if not v_role.is_teaching_role
     and jsonb_array_length(v_subjects) > 0 then
    raise exception 'Teaching subjects can only be selected for a teaching Staff role.';
  end if;

  for v_subject_id in
    select value::text::uuid
    from jsonb_array_elements_text(v_subjects)
  loop
    if not exists (
      select 1 from public.subjects
      where id=v_subject_id and is_active
    ) then
      raise exception 'One selected subject is not available.';
    end if;

    insert into public.staff_subject_assignments(
      staff_id,
      subject_id,
      effective_from,
      assigned_by
    )
    values(
      v_staff.id,
      v_subject_id,
      v_joined_on,
      v_actor
    );
  end loop;

  select sr.code into v_actor_role
  from public.user_role_assignments ura
  join public.system_roles sr on sr.id=ura.role_id
  where ura.profile_id=v_actor
    and ura.is_active
    and ura.effective_from<=current_date
    and (ura.effective_to is null or ura.effective_to>=current_date)
  order by case when sr.code='ADMIN' then 0 else 1 end, sr.code
  limit 1;

  insert into public.audit_events(
    correlation_id,
    actor_profile_id,
    actor_staff_id,
    actor_role_code,
    branch_id,
    entity_type,
    entity_id,
    action,
    after_data,
    metadata
  )
  values(
    v_correlation_id,
    v_actor,
    (select id from public.staff where profile_id=v_actor limit 1),
    v_actor_role,
    v_branch.id,
    'STAFF',
    v_staff.id::text,
    'CREATE',
    jsonb_build_object(
      'staff_no',v_staff.staff_no,
      'full_name',v_staff.full_name,
      'staff_role_code',v_role.code,
      'joined_on',v_staff.joined_on,
      'status',v_staff.status
    ),
    jsonb_build_object(
      'workflow','CREATE_STAFF_MEMBER',
      'subject_count',jsonb_array_length(v_subjects)
    )
  );

  return jsonb_build_object(
    'staff_id',v_staff.id,
    'staff_no',v_staff.staff_no,
    'correlation_id',v_correlation_id
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.edit_staff_record(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare original public.staff; saved public.staff; actor uuid:=auth.uid(); trace uuid:=gen_random_uuid();
begin
 if actor is null or not public.has_permission('staff.manage') then raise exception 'Staff management permission required.'; end if;
 select * into original from public.staff where id=(p_input->>'id')::uuid for update;
 if original.id is null then raise exception 'Staff identity not found.'; end if;
 if length(btrim(coalesce(p_input->>'full_name','')))<2 or length(p_input->>'full_name')>160 or length(btrim(coalesce(p_input->>'reason','')))<5 then raise exception 'Enter name and correction reason.'; end if;
 if coalesce(p_input->>'mobile','') !~ '^$|^01[3-9][0-9]{8}$' or coalesce(p_input->>'alternate_mobile','') !~ '^$|^01[3-9][0-9]{8}$' or coalesce(p_input->>'emergency_contact_mobile','') !~ '^$|^01[3-9][0-9]{8}$' then raise exception 'Check 11-digit Bangladesh mobile numbers.'; end if;
 if original.profile_id is not null and p_input ? 'email' and nullif(lower(btrim(p_input->>'email')),'') is distinct from original.email then raise exception 'Change linked account email through secure account settings.'; end if;
 if coalesce(p_input->>'email','') !~ '^$|^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'Enter a valid email.'; end if;
 update public.staff set full_name=btrim(p_input->>'full_name'), mobile=nullif(p_input->>'mobile',''),
 alternate_mobile=case when p_input ? 'alternate_mobile' then nullif(p_input->>'alternate_mobile','') else alternate_mobile end,
 email=case when p_input ? 'email' then nullif(lower(btrim(p_input->>'email')),'') else email end,
 address=case when p_input ? 'address' then left(p_input->>'address',500) else address end,
 emergency_contact_name=case when p_input ? 'emergency_contact_name' then left(p_input->>'emergency_contact_name',160) else emergency_contact_name end,
 emergency_contact_mobile=case when p_input ? 'emergency_contact_mobile' then nullif(p_input->>'emergency_contact_mobile','') else emergency_contact_mobile end,
 joined_on=case when p_input ? 'joined_on' then nullif(p_input->>'joined_on','')::date else joined_on end,
 notes=case when p_input ? 'notes' then left(p_input->>'notes',1000) else notes end where id=original.id returning * into saved;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data) values(trace,actor,'STAFF',saved.id::text,'CORRECT_DETAILS',p_input->>'reason',to_jsonb(original),to_jsonb(saved));
 return jsonb_build_object('id',saved.id);
end; $function$
;

CREATE OR REPLACE FUNCTION public.enforce_approval_decision()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if old.status <> 'PENDING' and new.status is distinct from old.status then
    raise exception 'A decided approval request cannot be decided again.';
  end if;

  if new.status = 'APPROVED' and old.requested_by = new.decided_by then
    raise exception 'Maker-checker violation: requester cannot approve their own request.';
  end if;

  if new.status in ('APPROVED','REJECTED','CANCELLED') then
    if new.decided_by is null then
      raise exception 'Decision actor is required.';
    end if;
    if new.decided_at is null then
      new.decided_at := now();
    end if;
  end if;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.enforce_batch_policy()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
  v_max integer;
begin
  select (payload->>'max_students')::integer
    into v_max
  from public.business_rule_versions
  where domain='academics'
    and rule_key='batch_capacity_policy'
    and status='ACTIVE'
  order by version desc
  limit 1;

  if v_max is null or v_max < 1 then
    raise exception 'Active batch capacity policy is missing or invalid.';
  end if;

  if new.capacity > v_max then
    raise exception 'Batch capacity exceeds the active public policy maximum of %.', v_max;
  end if;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.enforce_staff_subject_teaching_role()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if not exists (
    select 1
    from public.staff_role_assignments sra
    join public.staff_roles sr on sr.id=sra.staff_role_id
    where sra.staff_id=new.staff_id
      and sr.is_teaching_role
      and sra.effective_from<=current_date
      and (sra.effective_to is null or sra.effective_to>=current_date)
  ) then
    raise exception 'Teaching subjects can only be assigned to staff with an active teaching role.';
  end if;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.is_valid_prospect_transition(p_from prospect_status, p_to prospect_status)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select
    p_from = p_to
    or (p_from='NEW' and p_to in ('CONTACTED','COUNSELLING','FUTURE_FOLLOW_UP','LOST'))
    or (p_from='CONTACTED' and p_to in ('COUNSELLING','TRIAL_SCHEDULED','FUTURE_FOLLOW_UP','LOST'))
    or (p_from='COUNSELLING' and p_to in ('TRIAL_SCHEDULED','REGISTERED','FUTURE_FOLLOW_UP','LOST'))
    or (p_from='TRIAL_SCHEDULED' and p_to in ('TRIAL_ATTENDED','FUTURE_FOLLOW_UP','LOST'))
    or (p_from='TRIAL_ATTENDED' and p_to in ('COUNSELLING','REGISTERED','FUTURE_FOLLOW_UP','LOST'))
    or (p_from='REGISTERED' and p_to='LOST')
    or (p_from='FUTURE_FOLLOW_UP' and p_to in ('CONTACTED','COUNSELLING','TRIAL_SCHEDULED','LOST'))
    or (p_from='LOST' and p_to='FUTURE_FOLLOW_UP');
$function$
;

CREATE OR REPLACE FUNCTION public.list_public_programme_offerings()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(jsonb_agg(to_jsonb(x) order by x.showcase_sort_order, x.created_at), '[]'::jsonb)
  from (
    select o.id, o.code, o.name, o.class_id, o.program_id, o.group_id,
      o.branch_id, o.academic_year_id, ay.name as academic_year_name,
      b.name as branch_name, c.name as class_name, ag.name as group_name,
      o.showcase_title, o.showcase_title_bn, o.showcase_description,
      o.showcase_description_bn, o.showcase_eyebrow, o.showcase_eyebrow_bn,
      o.showcase_icon, o.showcase_sort_order,
      o.public_schedule, o.public_schedule_bn, o.public_requirements,
      o.public_requirements_bn, o.admission_policy, o.admission_policy_bn,
      (select count(*)::integer from public.batches bb where bb.offering_id=o.id and bb.is_active) as active_batch_count,
      (select coalesce(sum(bb.capacity),0)::integer from public.batches bb where bb.offering_id=o.id and bb.is_active) as current_total_seats,
      (select coalesce(sum(greatest(bb.capacity-(select count(*) from public.enrollments e where e.batch_id=bb.id and e.status='ACTIVE'),0)),0)::integer
       from public.batches bb where bb.offering_id=o.id and bb.is_active) as current_open_seats,
      (o.is_accepting_applications
        and (o.applications_open_on is null or o.applications_open_on <= local_day.today)
        and (o.applications_close_on is null or o.applications_close_on >= local_day.today)
      ) as is_accepting_applications,
      case when not o.is_accepting_applications then 'CLOSED'
        when o.applications_open_on > local_day.today then 'UPCOMING'
        when o.applications_close_on < local_day.today then 'CLOSED'
        else 'OPEN' end as application_state,
      o.applications_open_on, o.applications_close_on, o.created_at,
      (select coalesce(jsonb_agg(jsonb_build_object('id', s.id, 'code', s.code, 'name', s.name)
        order by pos.sort_order), '[]'::jsonb)
       from public.programme_offering_subjects pos
       join public.subjects s on s.id = pos.subject_id
       where pos.offering_id = o.id and s.is_active) as subjects,
      (select jsonb_build_object('billing_cycle', fp.billing_cycle,
        'currency_code', fp.currency_code,
        'components', coalesce((select jsonb_agg(jsonb_build_object(
          'code', fc.code, 'name', fc.name, 'amount', fc.amount,
          'charge_type', fc.charge_type, 'recurrence', fc.recurrence)
          order by fc.sort_order) from (SELECT NULL::uuid AS "id", NULL::uuid AS "fee_plan_version_id", NULL::text AS "code", NULL::text AS "name", NULL::numeric(12,2) AS "amount", NULL::text AS "charge_type", NULL::text AS "recurrence", NULL::integer AS "sort_order" WHERE false) fc
          where fc.fee_plan_version_id = fp.id), '[]'::jsonb))
       from (SELECT NULL::uuid AS "id", NULL::uuid AS "offering_id", NULL::integer AS "version", NULL::rule_status AS "status", NULL::text AS "billing_cycle", NULL::integer AS "due_day", NULL::text AS "currency_code", NULL::date AS "effective_from", NULL::date AS "effective_to", NULL::text AS "change_reason", NULL::uuid AS "created_by", NULL::timestamp with time zone AS "created_at" WHERE false) fp
       where fp.offering_id = o.id and fp.status = 'ACTIVE' limit 1) as fee_plan
    from public.programme_offerings o
    join public.organizations org on org.id = o.organization_id
    join public.academic_years ay on ay.id = o.academic_year_id
    join public.branches b on b.id = o.branch_id
    join public.classes c on c.id = o.class_id
    left join public.academic_groups ag on ag.id = o.group_id
    cross join lateral (select timezone(org.timezone, now())::date as today) local_day
    where o.scope_branch_id=academy_private.public_branch_id() and b.is_active and o.is_website_visible and o.status = 'ACTIVE'
    order by o.showcase_sort_order, o.created_at limit 24
  ) x;
$function$
;

CREATE OR REPLACE FUNCTION public.manage_crm_master_record(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_org uuid;
  v_entity text := lower(btrim(coalesce(p_input->>'entity', '')));
  v_reason text := btrim(coalesce(p_input->>'reason', ''));
  v_id uuid := nullif(p_input->>'id', '')::uuid;
  v_correlation uuid := gen_random_uuid();
  v_before jsonb;
  v_after jsonb;
  v_action text;
  v_code text;
  v_name text;
  v_is_active boolean;
  v_sort integer;
  v_starts date;
  v_ends date;
  v_description text;
  v_area_id uuid;
  v_verified boolean;
begin
  if v_actor is null or not public.has_permission('system.master_data.manage') then
    raise exception 'You are not authorized to manage CRM master data.';
  end if;
  if length(v_reason) < 5 then
    raise exception 'A change reason of at least five characters is required.';
  end if;

  select id into v_org from public.organizations where is_active limit 1;
  if v_org is null then
    raise exception 'Organization is not available.';
  end if;

  v_name := nullif(btrim(coalesce(p_input->>'name', '')), '');
  v_code := nullif(upper(btrim(coalesce(p_input->>'code', ''))), '');
  v_is_active := coalesce((p_input->>'is_active')::boolean, true);
  v_sort := coalesce((p_input->>'sort_order')::integer, 0);
  v_description := nullif(btrim(coalesce(p_input->>'description', '')), '');
  v_starts := nullif(p_input->>'starts_on', '')::date;
  v_ends := nullif(p_input->>'ends_on', '')::date;
  v_area_id := nullif(p_input->>'area_id', '')::uuid;
  v_verified := coalesce((p_input->>'is_verified')::boolean, false);

  if v_entity = 'academic_year' then
    if v_name is null or length(v_name) < 2 then
      raise exception 'Academic year name is required.';
    end if;
    if v_starts is null or v_ends is null or v_ends < v_starts then
      raise exception 'Academic year needs a valid start and end date.';
    end if;
    if v_id is null then
      insert into public.academic_years (organization_id, name, starts_on, ends_on, is_active)
      values (v_org, v_name, v_starts, v_ends, v_is_active)
      returning to_jsonb(academic_years.*) into v_after;
      v_id := (v_after->>'id')::uuid;
      v_action := 'CREATE';
    else
      select to_jsonb(y.*) into v_before from public.academic_years y where y.id = v_id and y.organization_id = v_org for update;
      if v_before is null then raise exception 'Academic year not found.'; end if;
      update public.academic_years
      set name = v_name, starts_on = v_starts, ends_on = v_ends, is_active = v_is_active
      where id = v_id
      returning to_jsonb(academic_years.*) into v_after;
      v_action := 'UPDATE';
    end if;

  elsif v_entity = 'class' then
    if v_code is null or length(v_code) < 1 then raise exception 'Class code is required.'; end if;
    if v_name is null or length(v_name) < 1 then raise exception 'Class name is required.'; end if;
    if v_id is null then
      insert into public.classes (organization_id, code, name, sort_order, is_active)
      values (v_org, v_code, v_name, v_sort, v_is_active)
      returning to_jsonb(classes.*) into v_after;
      v_id := (v_after->>'id')::uuid;
      v_action := 'CREATE';
    else
      select to_jsonb(c.*) into v_before from public.classes c where c.id = v_id and c.organization_id = v_org for update;
      if v_before is null then raise exception 'Class not found.'; end if;
      update public.classes
      set code = v_code, name = v_name, sort_order = v_sort, is_active = v_is_active
      where id = v_id
      returning to_jsonb(classes.*) into v_after;
      v_action := 'UPDATE';
    end if;

  elsif v_entity = 'group' then
    if v_code is null or length(v_code) < 1 then raise exception 'Group code is required.'; end if;
    if v_name is null or length(v_name) < 1 then raise exception 'Group name is required.'; end if;
    if v_id is null then
      insert into public.academic_groups (organization_id, code, name, is_active)
      values (v_org, v_code, v_name, v_is_active)
      returning to_jsonb(academic_groups.*) into v_after;
      v_id := (v_after->>'id')::uuid;
      v_action := 'CREATE';
    else
      select to_jsonb(g.*) into v_before from public.academic_groups g where g.id = v_id and g.organization_id = v_org for update;
      if v_before is null then raise exception 'Group not found.'; end if;
      update public.academic_groups
      set code = v_code, name = v_name, is_active = v_is_active
      where id = v_id
      returning to_jsonb(academic_groups.*) into v_after;
      v_action := 'UPDATE';
    end if;

  elsif v_entity = 'subject' then
    if v_code is null or length(v_code) < 1 then raise exception 'Subject code is required.'; end if;
    if v_name is null or length(v_name) < 1 then raise exception 'Subject name is required.'; end if;
    if v_id is null then
      insert into public.subjects (organization_id, code, name, is_active)
      values (v_org, v_code, v_name, v_is_active)
      returning to_jsonb(subjects.*) into v_after;
      v_id := (v_after->>'id')::uuid;
      v_action := 'CREATE';
    else
      select to_jsonb(s.*) into v_before from public.subjects s where s.id = v_id and s.organization_id = v_org for update;
      if v_before is null then raise exception 'Subject not found.'; end if;
      update public.subjects
      set code = v_code, name = v_name, is_active = v_is_active
      where id = v_id
      returning to_jsonb(subjects.*) into v_after;
      v_action := 'UPDATE';
    end if;

  elsif v_entity = 'program' then
    if v_code is null or length(v_code) < 1 then raise exception 'Programme code is required.'; end if;
    if v_name is null or length(v_name) < 1 then raise exception 'Programme name is required.'; end if;
    if v_id is null then
      insert into public.programs (organization_id, code, name, description, is_active)
      values (v_org, v_code, v_name, v_description, v_is_active)
      returning to_jsonb(programs.*) into v_after;
      v_id := (v_after->>'id')::uuid;
      v_action := 'CREATE';
    else
      select to_jsonb(p.*) into v_before from public.programs p where p.id = v_id and p.organization_id = v_org for update;
      if v_before is null then raise exception 'Programme not found.'; end if;
      update public.programs
      set code = v_code, name = v_name, description = v_description, is_active = v_is_active
      where id = v_id
      returning to_jsonb(programs.*) into v_after;
      v_action := 'UPDATE';
    end if;

  elsif v_entity = 'school' then
    if v_name is null or length(v_name) < 2 then raise exception 'School name is required.'; end if;
    if v_area_id is not null and not exists (
      select 1 from public.areas a where a.id = v_area_id and a.organization_id = v_org
    ) then
      raise exception 'Selected area is not available.';
    end if;
    if v_id is null then
      insert into public.schools (organization_id, area_id, name, is_verified, is_active, created_by)
      values (v_org, v_area_id, v_name, v_verified, v_is_active, v_actor)
      returning to_jsonb(schools.*) into v_after;
      v_id := (v_after->>'id')::uuid;
      v_action := 'CREATE';
    else
      select to_jsonb(s.*) into v_before from public.schools s where s.id = v_id and s.organization_id = v_org for update;
      if v_before is null then raise exception 'School not found.'; end if;
      update public.schools
      set area_id = v_area_id, name = v_name, is_verified = v_verified, is_active = v_is_active, updated_at = now()
      where id = v_id
      returning to_jsonb(schools.*) into v_after;
      v_action := 'UPDATE';
    end if;

  elsif v_entity = 'lead_source' then
    if v_code is null or length(v_code) < 1 then raise exception 'Lead source code is required.'; end if;
    if v_name is null or length(v_name) < 1 then raise exception 'Lead source name is required.'; end if;
    if v_id is null then
      insert into public.lead_sources (organization_id, code, name, is_active)
      values (v_org, v_code, v_name, v_is_active)
      returning to_jsonb(lead_sources.*) into v_after;
      v_id := (v_after->>'id')::uuid;
      v_action := 'CREATE';
    else
      select to_jsonb(l.*) into v_before from public.lead_sources l where l.id = v_id and l.organization_id = v_org for update;
      if v_before is null then raise exception 'Lead source not found.'; end if;
      update public.lead_sources
      set code = v_code, name = v_name, is_active = v_is_active
      where id = v_id
      returning to_jsonb(lead_sources.*) into v_after;
      v_action := 'UPDATE';
    end if;

  elsif v_entity = 'guardian_relationship' then
    if v_code is null or length(v_code) < 1 then raise exception 'Relationship code is required.'; end if;
    if v_name is null or length(v_name) < 1 then raise exception 'Relationship name is required.'; end if;
    if v_id is null then
      insert into public.guardian_relationships (organization_id, code, name, is_active)
      values (v_org, v_code, v_name, v_is_active)
      returning to_jsonb(guardian_relationships.*) into v_after;
      v_id := (v_after->>'id')::uuid;
      v_action := 'CREATE';
    else
      select to_jsonb(r.*) into v_before from public.guardian_relationships r where r.id = v_id and r.organization_id = v_org for update;
      if v_before is null then raise exception 'Relationship not found.'; end if;
      update public.guardian_relationships
      set code = v_code, name = v_name, is_active = v_is_active
      where id = v_id
      returning to_jsonb(guardian_relationships.*) into v_after;
      v_action := 'UPDATE';
    end if;

  else
    raise exception 'Unsupported master-data entity.';
  end if;

  insert into public.audit_events (
    correlation_id, actor_profile_id, actor_staff_id, branch_id,
    entity_type, entity_id, action, reason, before_data, after_data, metadata
  ) values (
    v_correlation,
    v_actor,
    (select id from public.staff where profile_id = v_actor limit 1),
    null,
    upper(v_entity),
    v_id::text,
    v_action,
    v_reason,
    v_before,
    v_after,
    jsonb_build_object('source', 'manage_crm', 'entity', v_entity)
  );

  return jsonb_build_object(
    'id', v_id,
    'entity', v_entity,
    'action', v_action,
    'correlation_id', v_correlation
  );
exception
  when unique_violation then
    raise exception 'A record with the same code or name already exists.';
end;
$function$
;

CREATE OR REPLACE FUNCTION public.prevent_permanent_record_delete()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin raise exception 'Do not delete this record. Use edit, inactive, withdrawal or a recorded financial correction.'; end $function$
;

CREATE OR REPLACE FUNCTION public.prospect_assignment_options()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if auth.uid() is null or not public.has_permission('crm.prospects.view') then raise exception 'CRM access required.'; end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',full_name||' · '||staff_no) order by full_name) from public.staff where status in('ACTIVE','ON_LEAVE')),'[]'::jsonb);
end $function$
;

CREATE OR REPLACE FUNCTION public.protect_active_business_rule()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  if tg_op = 'DELETE' then
    raise exception 'Business rule versions are never deleted.';
  end if;

  if old.status = 'ACTIVE' and (
    new.domain is distinct from old.domain
    or new.rule_key is distinct from old.rule_key
    or new.version is distinct from old.version
    or new.payload is distinct from old.payload
    or new.effective_from is distinct from old.effective_from
  ) then
    raise exception 'Active business rule content is immutable. Retire it and create a new version.';
  end if;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.publish_business_rule_version(p_domain text, p_rule_key text, p_payload jsonb, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare previous public.business_rule_versions; saved public.business_rule_versions; next_version integer; trace uuid:=gen_random_uuid();
begin
 if auth.uid() is null or not public.has_permission('system.settings.manage') then raise exception 'Settings management permission required.'; end if;
 if (p_domain,p_rule_key) not in (('academics','batch_capacity_policy'),('admissions','activation_policy'),('teacher_compensation','default_policy'),('referrals','acquisition_policy'),('finance','collection_discount_policy')) then raise exception 'Choose a supported operating rule.'; end if;
 if length(btrim(coalesce(p_reason,''))) not between 5 and 500 or not public.validate_business_rule_payload(p_domain,p_rule_key,p_payload) then raise exception 'Check the operating values and change reason.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_domain||'.'||p_rule_key,0));
 select * into previous from public.business_rule_versions where domain=p_domain and rule_key=p_rule_key and status='ACTIVE' for update;
 if previous.id is not null and previous.payload=p_payload then return jsonb_build_object('id',previous.id,'version',previous.version); end if;
 select coalesce(max(version),0)+1 into next_version from public.business_rule_versions where domain=p_domain and rule_key=p_rule_key;
 update public.business_rule_versions set status='RETIRED',effective_to=current_date where id=previous.id;
 insert into public.business_rule_versions(domain,rule_key,version,status,effective_from,payload,change_reason,created_by)
 values(p_domain,p_rule_key,next_version,'ACTIVE',current_date,p_payload,btrim(p_reason),auth.uid()) returning * into saved;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(trace,auth.uid(),'BUSINESS_RULE',p_domain||'.'||p_rule_key,case when previous.id is null then 'CREATE_SETTINGS' else 'SAVE_SETTINGS' end,p_reason,to_jsonb(previous),to_jsonb(saved));
 return jsonb_build_object('id',saved.id,'version',saved.version,'correlation_id',trace);
end $function$
;

CREATE OR REPLACE FUNCTION public.record_lifecycle_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare target_table text; permission text; status_column text; active_value text; inactive_value text;
 before_data jsonb; after_data jsonb; target uuid:=(p_input->>'id')::uuid; enabled boolean:=(p_input->>'active')::boolean;
begin
 case p_input->>'entity'
 when 'batch' then target_table:='batches';permission:='academics.manage';status_column:='is_active';
 when 'offering' then target_table:='programme_offerings';permission:='academics.manage';status_column:='status';active_value:='ACTIVE';inactive_value:='RETIRED';
 when 'student' then target_table:='students';permission:='students.manage';status_column:='status';active_value:='ACTIVE';inactive_value:='INACTIVE';
 when 'staff' then target_table:='staff';permission:='staff.manage';status_column:='status';active_value:='ACTIVE';inactive_value:='ARCHIVED';
 when 'referrer' then target_table:='referral_people';permission:='admissions.create';status_column:='is_active';
 else raise exception 'This record requires its dedicated correction workflow.';
 end case;
 if auth.uid() is null or not public.has_permission(permission) then raise exception 'Record management permission required.'; end if;
 if enabled is null or length(btrim(coalesce(p_input->>'reason','')))<5 then raise exception 'Select a state and provide a reason.'; end if;
 execute format('select to_jsonb(t) from public.%I t where id=$1 for update',target_table) into before_data using target;
 if before_data is null then raise exception 'Record not found.'; end if;
 if target_table='staff' and before_data->>'profile_id'=auth.uid()::text and not enabled then raise exception 'You cannot deactivate your own staff record.'; end if;
 if target_table='students' and enabled and not exists(select 1 from public.enrollments where student_id=target and status='ACTIVE') then raise exception 'Activate an enrollment before activating this student.'; end if;
 if target_table='students' and not enabled and exists(select 1 from public.enrollments where student_id=target and status='ACTIVE') then raise exception 'Withdraw or close the active enrollment first; its history and balances remain intact.'; end if;
 if status_column='is_active' then
 execute format('update public.%I set is_active=$2 where id=$1 returning to_jsonb(%I.*)',target_table,target_table) into after_data using target,enabled;
 else
 execute format('update public.%I set status=%L where id=$1 returning to_jsonb(%I.*)',target_table,case when enabled then active_value else inactive_value end,target_table) into after_data using target;
 end if;
 if target_table='programme_offerings' and not enabled then update public.programme_offerings set is_website_visible=false,is_accepting_applications=false where id=target; end if;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(auth.uid(),upper(p_input->>'entity'),target::text,case when enabled then 'REACTIVATE' else 'MARK_INACTIVE' end,p_input->>'reason',before_data,after_data);
 return jsonb_build_object('id',target);
end $function$
;

CREATE OR REPLACE FUNCTION public.record_prospect_followup(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_prospect public.prospects;
  v_followup public.prospect_followups;
  v_followup_type text;
  v_new_status public.prospect_status;
  v_next_follow_up_at timestamptz;
  v_notes text;
  v_outcome text;
  v_lost_reason text;
  v_correlation_id uuid := gen_random_uuid();
  v_actor_role text;
  v_before jsonb;
begin
  if v_actor is null or not public.has_permission('crm.followups.manage') then
    raise exception 'You are not authorized to record CRM follow-ups.';
  end if;

  begin
    select * into v_prospect
    from public.prospects
    where id=(p_input->>'prospect_id')::uuid
    for update;
  exception when others then
    raise exception 'Prospect identity is invalid.';
  end;

  if v_prospect.id is null then
    raise exception 'Prospect was not found.';
  end if;

  if v_prospect.status='CONVERTED' then
    raise exception 'Converted prospects are read-only in CRM. Continue from the Student record.';
  end if;

  v_followup_type := upper(btrim(coalesce(p_input->>'followup_type','')));
  if v_followup_type not in ('CALL','WHATSAPP','IN_PERSON','COUNSELLING','TRIAL','OTHER') then
    raise exception 'Select a valid follow-up type.';
  end if;

  v_notes := nullif(btrim(coalesce(p_input->>'notes','')), '');
  if v_notes is null then
    raise exception 'Follow-up notes are required.';
  end if;

  v_outcome := nullif(btrim(coalesce(p_input->>'outcome','')), '');
  v_lost_reason := nullif(btrim(coalesce(p_input->>'lost_reason','')), '');

  begin
    v_new_status := coalesce(
      nullif(p_input->>'new_status','')::public.prospect_status,
      v_prospect.status
    );
    v_next_follow_up_at := nullif(p_input->>'next_follow_up_at','')::timestamptz;
  exception when others then
    raise exception 'Follow-up status or next follow-up date is invalid.';
  end;

  if not public.is_valid_prospect_transition(v_prospect.status,v_new_status) then
    raise exception 'Prospect status cannot move from % to % through a follow-up.', v_prospect.status, v_new_status;
  end if;

  if v_new_status='LOST' and v_lost_reason is null then
    raise exception 'Lost reason is required when a prospect is marked LOST.';
  end if;

  if v_new_status='FUTURE_FOLLOW_UP' and v_next_follow_up_at is null then
    raise exception 'Next follow-up date is required for FUTURE FOLLOW UP.';
  end if;

  v_before := to_jsonb(v_prospect);

  insert into public.prospect_followups(
    prospect_id,
    followup_type,
    occurred_at,
    outcome,
    notes,
    next_follow_up_at,
    recorded_by
  )
  values(
    v_prospect.id,
    v_followup_type,
    now(),
    v_outcome,
    v_notes,
    v_next_follow_up_at,
    v_actor
  )
  returning * into v_followup;

  update public.prospects
  set
    status=v_new_status,
    next_follow_up_at=v_next_follow_up_at,
    lost_reason=case
      when v_new_status='LOST' then v_lost_reason
      when v_prospect.status='LOST' and v_new_status<>'LOST' then null
      else lost_reason
    end,
    updated_at=now()
  where id=v_prospect.id
  returning * into v_prospect;

  select sr.code into v_actor_role
  from public.user_role_assignments ura
  join public.system_roles sr on sr.id=ura.role_id
  where ura.profile_id=v_actor
    and ura.is_active
    and ura.effective_from<=current_date
    and (ura.effective_to is null or ura.effective_to>=current_date)
  order by case when sr.code='ADMIN' then 0 else 1 end, sr.code
  limit 1;

  insert into public.audit_events(
    correlation_id,
    actor_profile_id,
    actor_staff_id,
    actor_role_code,
    branch_id,
    entity_type,
    entity_id,
    action,
    reason,
    before_data,
    after_data,
    metadata
  )
  values(
    v_correlation_id,
    v_actor,
    (select id from public.staff where profile_id=v_actor limit 1),
    v_actor_role,
    v_prospect.branch_id,
    'PROSPECT',
    v_prospect.id::text,
    'RECORD_FOLLOW_UP',
    v_notes,
    v_before,
    to_jsonb(v_prospect),
    jsonb_build_object(
      'workflow','PROSPECT_FOLLOW_UP',
      'followup_id',v_followup.id,
      'followup_type',v_followup.followup_type,
      'outcome',v_followup.outcome
    )
  );

  return jsonb_build_object(
    'prospect_id',v_prospect.id,
    'prospect_no',v_prospect.prospect_no,
    'followup_id',v_followup.id,
    'status',v_prospect.status,
    'correlation_id',v_correlation_id
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at := now();
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.staff_task_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare actor uuid:=auth.uid();manager boolean:=public.has_permission('workforce.manage');own_staff uuid;task public.staff_work_tasks;req uuid:=(p_input->>'request_id')::uuid;old_key public.admission_command_keys;action text:=p_input->>'action';reason text:=btrim(p_input->>'reason');before_data jsonb;result jsonb;progress_value integer;
begin
 if actor is null or not exists(select 1 from public.profiles where id=actor and status='ACTIVE') or not(manager or public.has_permission('workforce.self.view')) then raise exception 'Workforce access required.';end if;
 select id into own_staff from public.staff where profile_id=actor and status='ACTIVE';
 if req is null or coalesce(length(reason),0)<5 then raise exception 'Request ID and reason are required.';end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));select * into old_key from public.admission_command_keys where request_id=req;
 if found then if old_key.actor_id<>actor or old_key.payload<>p_input then raise exception 'Request identity conflict.';end if;return old_key.result;end if;
 if action='CREATE' then
  if not manager then raise exception 'Only an administrator assigns work.';end if;
  perform 1 from public.staff where id=(p_input->>'staff_id')::uuid and status='ACTIVE' for update;if not found then raise exception 'Choose active staff.';end if;
  insert into public.staff_work_tasks(staff_id,title,instructions,due_on,created_by,updated_by) values((p_input->>'staff_id')::uuid,btrim(p_input->>'title'),coalesce(p_input->>'instructions',''),(p_input->>'due_on')::date,actor,actor) returning * into task;
 else
  select * into task from public.staff_work_tasks where id=(p_input->>'id')::uuid for update;
  if task.id is null or (not manager and task.staff_id is distinct from own_staff) then raise exception 'Task unavailable.';end if;
  before_data:=to_jsonb(task);
  if action in('REPORT','SUBMIT') then
   if task.staff_id is distinct from own_staff then raise exception 'Only the assigned person reports their progress.';end if;
   if task.status not in('OPEN','IN_PROGRESS') then raise exception 'This task is not open for progress changes.';end if;
   progress_value:=case when action='SUBMIT' then 100 else (p_input->>'progress')::integer end;
   if progress_value is null or progress_value<0 or progress_value>100 or (action='REPORT' and progress_value=100) then raise exception 'Use Submit completion for 100%% progress.';end if;
   update public.staff_work_tasks set progress=progress_value,blocker=coalesce(p_input->>'blocker',''),status=case when action='SUBMIT' then 'SUBMITTED' else 'IN_PROGRESS' end,updated_by=actor,updated_at=now() where id=task.id returning * into task;
  elsif action in('ACCEPT','RETURN') then
   if not manager or task.status<>'SUBMITTED' then raise exception 'Administrator reviews submitted completion only.';end if;
   update public.staff_work_tasks set status=case when action='ACCEPT' then 'COMPLETED' else 'IN_PROGRESS' end,review_note=reason,completed_at=case when action='ACCEPT' then now() else null end,updated_by=actor,updated_at=now() where id=task.id returning * into task;
  elsif action='EDIT' then
   if not manager or task.status not in('OPEN','IN_PROGRESS') then raise exception 'Only open tasks can be edited by an administrator.';end if;
   perform 1 from public.staff where id=(p_input->>'staff_id')::uuid and status='ACTIVE' for update;if not found then raise exception 'Choose active staff.';end if;
   if task.staff_id is distinct from (p_input->>'staff_id')::uuid then raise exception 'Cancel and create a new assignment to change the responsible person.';end if;
   update public.staff_work_tasks set title=btrim(p_input->>'title'),instructions=coalesce(p_input->>'instructions',''),due_on=(p_input->>'due_on')::date,updated_by=actor,updated_at=now() where id=task.id returning * into task;
  elsif action='CANCEL' then
   if not manager or task.status in('COMPLETED','CANCELLED') then raise exception 'Only an open assignment can be cancelled.';end if;
   update public.staff_work_tasks set status='CANCELLED',review_note=reason,updated_by=actor,updated_at=now() where id=task.id returning * into task;
  else raise exception 'Unknown task action.';end if;
 end if;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data,correlation_id) values(actor,'STAFF_TASK',task.id::text,action,reason,before_data,to_jsonb(task),req);
 result:=jsonb_build_object('id',task.id,'ok',true);insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,actor,p_input,result);return result;
end $function$
;

CREATE OR REPLACE FUNCTION public.staff_tasks_workspace(p_staff_id uuid DEFAULT NULL::uuid, p_history boolean DEFAULT false, p_page integer DEFAULT 1)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare actor uuid:=auth.uid();manager boolean:=public.has_permission('workforce.manage');sid uuid;rows jsonb;total integer;stats jsonb;
begin
 if actor is null or not exists(select 1 from public.profiles where id=actor and status='ACTIVE') or not(manager or public.has_permission('workforce.self.view')) then raise exception 'Workforce access required.';end if;
 select id into sid from public.staff where profile_id=actor and status='ACTIVE';
 if p_staff_id is not null then if not manager and p_staff_id is distinct from sid then raise exception 'Only your own tasks are available.';end if;sid:=p_staff_id;end if;
 if p_page is null or p_page<1 or p_page>10000 then raise exception 'Invalid page.';end if;
 select jsonb_build_object('open',count(*) filter(where status in('OPEN','IN_PROGRESS')),'review',count(*) filter(where status='SUBMITTED'),'completed',count(*) filter(where status='COMPLETED'),'blocked',count(*) filter(where status in('OPEN','IN_PROGRESS') and length(btrim(blocker))>0),'overdue',count(*) filter(where status in('OPEN','IN_PROGRESS','SUBMITTED') and due_on<(now() at time zone 'Asia/Dhaka')::date)) into stats from public.staff_work_tasks where staff_id=sid;
 select count(*) into total from public.staff_work_tasks where staff_id=sid and (status in('COMPLETED','CANCELLED'))=coalesce(p_history,false);
 select coalesce(jsonb_agg(to_jsonb(t) order by t.due_on,t.id),'[]'::jsonb) into rows from(select * from public.staff_work_tasks where staff_id=sid and (status in('COMPLETED','CANCELLED'))=coalesce(p_history,false) order by due_on,id limit 25 offset (p_page-1)*25) t;
 return jsonb_build_object('manager',manager,'staffId',sid,'ownStaffId',(select id from public.staff where profile_id=actor and status='ACTIVE'),'total',total,'stats',stats,'tasks',rows);
end $function$
;

CREATE OR REPLACE FUNCTION public.staff_work_workspace(p_month date DEFAULT NULL::date, p_staff_id uuid DEFAULT NULL::uuid, p_page integer DEFAULT 1)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare actor uuid:=auth.uid();manager boolean:=public.has_permission('workforce.manage');sid uuid;first_day date:=date_trunc('month',coalesce(p_month,(now() at time zone 'Asia/Dhaka')::date))::date;last_day date;rows jsonb;terms jsonb;total integer;present integer;hours numeric;effective_hours numeric;pay_date date;
begin
 if actor is null or not exists(select 1 from public.profiles where id=actor and status='ACTIVE') or not(manager or public.has_permission('workforce.self.view')) then raise exception 'Workforce access required.';end if;
 select id into sid from public.staff where profile_id=actor and status in('ACTIVE','ON_LEAVE');
 if p_staff_id is not null then if not manager and p_staff_id is distinct from sid then raise exception 'Only your own workforce records are available.';end if;sid:=p_staff_id;end if;
 if p_page<1 or p_page>10000 or p_page is null then raise exception 'Invalid page.';end if;
 last_day:=(first_day+interval '1 month')::date;
 select count(*),count(*) filter(where status='PRESENT'),coalesce(sum(case when status='PRESENT' then extract(epoch from ended_at-started_at)/3600-break_minutes/60.0 else 0 end),0)
 into total,present,hours from public.staff_attendance_records where staff_id=sid and work_date>=first_day and work_date<last_day;
 select coalesce(jsonb_agg(to_jsonb(a) order by a.work_date desc),'[]'::jsonb) into rows from(select id,work_date,status,started_at,ended_at,break_minutes,reason,round(case when status='PRESENT' then extract(epoch from ended_at-started_at)/3600-break_minutes/60.0 else 0 end,2) hours from public.staff_attendance_records where staff_id=sid and work_date>=first_day and work_date<last_day order by work_date desc limit 25 offset (p_page-1)*25) a;
 select to_jsonb(t) into terms from (SELECT NULL::uuid AS "staff_id", NULL::text AS "model", NULL::numeric(14,2) AS "monthly_base", NULL::numeric(14,2) AS "hourly_rate", NULL::integer AS "pay_day", NULL::date AS "effective_from", NULL::uuid AS "recorded_by", NULL::text AS "reason", NULL::timestamp with time zone AS "updated_at" WHERE false) t where staff_id=sid;
 select coalesce(sum(extract(epoch from ended_at-started_at)/3600-break_minutes/60.0),0) into effective_hours from public.staff_attendance_records where staff_id=sid and status='PRESENT' and work_date>=greatest(first_day,(terms->>'effective_from')::date) and work_date<last_day;
 if terms is not null then pay_date:=date_trunc('month',now() at time zone 'Asia/Dhaka')::date+((terms->>'pay_day')::integer-1);if pay_date<(now() at time zone 'Asia/Dhaka')::date then pay_date:=(date_trunc('month',now() at time zone 'Asia/Dhaka')+interval '1 month')::date+((terms->>'pay_day')::integer-1);end if;end if;
 return jsonb_build_object('manager',manager,'staffId',sid,'name',(select full_name from public.staff where id=sid),'month',first_day,'total',total,'presentDays',present,'hours',round(hours,2),'records',rows,'terms',terms,'scheduledPayDate',pay_date,
 'previousMonthPaid',(select coalesce(sum(s.amount),0) from (SELECT NULL::uuid AS "id", NULL::uuid AS "payable_id", NULL::numeric(14,2) AS "amount", NULL::uuid AS "payment_account_id", NULL::text AS "external_reference", NULL::uuid AS "settled_by", NULL::timestamp with time zone AS "settled_at", NULL::text AS "reason", NULL::uuid AS "advance_id" WHERE false) s join (SELECT NULL::uuid AS "id", NULL::text AS "payable_no", NULL::uuid AS "organization_id", NULL::text AS "payable_type", NULL::uuid AS "staff_id", NULL::uuid AS "vendor_id", NULL::text AS "source_type", NULL::text AS "source_id", NULL::uuid AS "payable_account_id", NULL::numeric(14,2) AS "original_amount", NULL::date AS "due_on", NULL::text AS "status", NULL::uuid AS "created_by", NULL::timestamp with time zone AS "created_at", NULL::uuid AS "referrer_id" WHERE false) p on p.id=s.payable_id where (p.staff_id=sid or p.referrer_id in(select id from (SELECT NULL::uuid AS "id", NULL::uuid AS "organization_id", NULL::uuid AS "staff_id", NULL::text AS "full_name", NULL::text AS "mobile", NULL::text AS "relationship_note", NULL::text AS "contact_note", NULL::uuid AS "created_by", NULL::timestamp with time zone AS "created_at", NULL::text AS "email", NULL::uuid AS "profile_id", NULL::boolean AS "is_active" WHERE false) where staff_id=sid)) and (p.payable_type in('TEACHER_COMPENSATION','STAFF_PAYROLL') or p.referrer_id is not null) and s.payment_account_id is not null and s.advance_id is null and s.settled_at>=((date_trunc('month',now() at time zone 'Asia/Dhaka')-interval '1 month') at time zone 'Asia/Dhaka') and s.settled_at<(date_trunc('month',now() at time zone 'Asia/Dhaka') at time zone 'Asia/Dhaka')),
 'hourlyEstimate',round(effective_hours*coalesce((terms->>'hourly_rate')::numeric,0),2),
 'people',case when manager then(select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',full_name,'number',staff_no) order by full_name),'[]'::jsonb) from public.staff where status in('ACTIVE','ON_LEAVE')) else '[]'::jsonb end);
end $function$
;

CREATE OR REPLACE FUNCTION public.submit_public_interest(p_payload jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare branch public.branches;chosen public.programme_offerings;prospect public.prospects;mobile_value text;item text;today date;prior text:=current_setting('public.branch_override',true);begin
 select * into branch from public.branches where id=academy_private.public_branch_id() and is_active;
 if branch.id is null then raise exception 'The public is not accepting applications yet.';end if;
 if jsonb_typeof(p_payload) is distinct from 'object' or octet_length(p_payload::text)>16000 or length(btrim(coalesce(p_payload->>'student_name','')))<2 or length(btrim(coalesce(p_payload->>'guardian_name','')))<2 then raise exception 'Enter valid student and guardian names.';end if;
 mobile_value:=regexp_replace(coalesce(p_payload->>'mobile',''),'\D','','g');if mobile_value!~'^01[3-9][0-9]{8}$' then raise exception 'A valid mobile number is required.';end if;
 if not coalesce((p_payload->>'consent_to_contact')::boolean,false) then raise exception 'Consent to contact is required.';end if;
 if not exists(select 1 from public.classes where id=nullif(p_payload->>'class_id','')::uuid and scope_branch_id=branch.id and is_active) then raise exception 'Selected class is not available.';end if;
 if nullif(p_payload->>'school_id','') is not null and not exists(select 1 from public.schools where id=(p_payload->>'school_id')::uuid and scope_branch_id=branch.id and is_active) then raise exception 'Selected school is not available.';end if;
 for item in select jsonb_array_elements_text(coalesce(p_payload->'program_ids','[]')) loop if not exists(select 1 from public.programs where id=item::uuid and scope_branch_id=branch.id and is_active) then raise exception 'One selected program is not available.';end if;end loop;
 for item in select jsonb_array_elements_text(coalesce(p_payload->'subject_ids','[]')) loop if not exists(select 1 from public.subjects where id=item::uuid and scope_branch_id=branch.id and is_active) then raise exception 'One selected subject is not available.';end if;end loop;
 if nullif(p_payload->>'offering_id','') is not null or p_payload->>'intent'='admission' then
  select * into chosen from public.programme_offerings where id=nullif(p_payload->>'offering_id','')::uuid and scope_branch_id=branch.id and status='ACTIVE' and is_website_visible;
  if chosen.id is null then raise exception 'Selected programme offering is not available.';end if;
  today:=timezone(branch.timezone,now())::date;
  if not chosen.is_accepting_applications or chosen.applications_open_on>today or chosen.applications_close_on<today then raise exception 'Applications are closed for this programme offering.';end if;
  if chosen.class_id<>(p_payload->>'class_id')::uuid then raise exception 'Selected class does not match the chosen programme offering.';end if;
  for item in select jsonb_array_elements_text(coalesce(p_payload->'subject_ids','[]')) loop if not exists(select 1 from public.programme_offering_subjects where offering_id=chosen.id and subject_id=item::uuid) then raise exception 'One selected subject is not part of the chosen programme offering.';end if;end loop;
 end if;
 perform pg_advisory_xact_lock(hashtextextended(branch.id::text||mobile_value,3));
 if exists(select 1 from public.prospects where scope_branch_id=branch.id and mobile=mobile_value and lower(student_name)=lower(btrim(p_payload->>'student_name')) and created_at>now()-interval '2 minutes') then raise exception 'A similar interest request was submitted recently. Please wait before submitting again.';end if;
 -- Explicit scope is mandatory for anonymous projection/intake; no operational read grants.
 insert into public.prospects(scope_branch_id,organization_id,branch_id,student_name,student_name_bn,guardian_name,guardian_relationship_snapshot,mobile,alternate_mobile,current_class_id,interested_offering_id,school_id,school_name_snapshot,area_snapshot,guardian_address,notes,referral_note,consent_to_contact,submitted_via,submission_intent,application_snapshot,date_of_birth,gender,school_roll)
 values(branch.id,branch.organization_id,branch.id,btrim(p_payload->>'student_name'),nullif(p_payload->>'student_name_bn',''),btrim(p_payload->>'guardian_name'),p_payload->>'guardian_relationship',mobile_value,nullif(p_payload->>'alternate_mobile',''),(p_payload->>'class_id')::uuid,chosen.id,nullif(p_payload->>'school_id','')::uuid,nullif(p_payload->>'school_name_snapshot',''),p_payload->>'area',p_payload->>'guardian_address',p_payload->>'notes',p_payload->>'referral_note',true,'PUBLIC_WEB',case when p_payload->>'intent'='admission' then 'admission' else 'interest' end,p_payload||'{"verification":"UNVERIFIED"}'::jsonb,nullif(p_payload->>'date_of_birth','')::date,nullif(p_payload->>'gender',''),nullif(p_payload->>'school_roll','')) returning * into prospect;
 insert into public.audit_events(scope_branch_id,branch_id,entity_type,entity_id,action,metadata) values(branch.id,branch.id,'PROSPECT',prospect.id::text,'RECEIVE_UNVERIFIED_APPLICATION','{"verification":"UNVERIFIED"}');
 return jsonb_build_object('prospect_no',prospect.prospect_no);
end $function$
;

CREATE OR REPLACE FUNCTION public.update_programme_offering(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_actor uuid:=auth.uid();
  v_request uuid:=nullif(p_input->>'request_id','')::uuid;
  v_reason text:=btrim(coalesce(p_input->>'reason',''));
  v_org uuid;
  v_row public.programme_offerings;
  v_before jsonb;
  v_result jsonb;
  v_branch uuid:=(p_input->>'branch_id')::uuid;
  v_year uuid:=(p_input->>'academic_year_id')::uuid;
  v_class uuid:=(p_input->>'class_id')::uuid;
  v_program uuid:=(p_input->>'program_id')::uuid;
  v_group uuid:=nullif(p_input->>'group_id','')::uuid;
  v_code text:=upper(btrim(coalesce(p_input->>'code','')));
  v_name text:=btrim(coalesce(p_input->>'name',''));
  v_existing public.admission_command_keys;
begin
 p_input:=p_input||jsonb_build_object('name',coalesce(nullif(btrim(p_input->>'name'),''),(select name from public.programs where id=(p_input->>'program_id')::uuid)));
  if v_actor is null or not public.has_permission('academics.manage') then raise exception 'You are not authorized to manage Programme Offerings.'; end if;
  if v_request is null then raise exception 'A request identity is required.'; end if;
  if length(v_reason)<5 then raise exception 'A change reason of at least five characters is required.'; end if;
  if length(v_code)<2 or length(v_code)>40 or v_code !~ '^[A-Z0-9_-]+$' then raise exception 'Use a valid offering code with letters, numbers, underscores or hyphens.'; end if;
  if length(v_name)<2 or length(v_name)>160 then raise exception 'Enter a recognizable offering name.'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_request::text,0));
  select * into v_existing from public.admission_command_keys where request_id=v_request;
  if found then
    if v_existing.actor_id<>v_actor or v_existing.payload<>p_input then raise exception 'Request identity was already used for different input.'; end if;
    return v_existing.result;
  end if;
  select id into v_org from public.organizations where is_active limit 1;
  select * into v_row from public.programme_offerings where id=(p_input->>'offering_id')::uuid and organization_id=v_org for update;
  if v_row.id is null then raise exception 'Programme Offering not found.'; end if;
  
  v_before:=to_jsonb(v_row);
  if v_row.status in('ACTIVE','RETIRED') and (
    v_branch is distinct from v_row.branch_id or v_year is distinct from v_row.academic_year_id
    or v_class is distinct from v_row.class_id or v_program is distinct from v_row.program_id
    or v_group is distinct from v_row.group_id
  ) then raise exception 'Academic context cannot change after activation. Create a new offering for a new year, class, branch or programme.'; end if;
  if v_row.status='DRAFT' and exists(select 1 from public.batches where offering_id=v_row.id) and (
    v_branch is distinct from v_row.branch_id or v_year is distinct from v_row.academic_year_id
    or v_class is distinct from v_row.class_id or v_program is distinct from v_row.program_id
    or v_group is distinct from v_row.group_id
  ) then raise exception 'Academic context cannot change after batches reference this offering.'; end if;
  if v_row.status='DRAFT' and not exists (
    select 1 from public.branches b join public.academic_years y on y.id=v_year
    join public.classes c on c.id=v_class join public.programs p on p.id=v_program
    where b.id=v_branch and b.is_active and b.organization_id=v_org and y.organization_id=v_org
      and c.organization_id=v_org and c.is_active and p.organization_id=v_org and p.is_active
      and (v_group is null or exists(select 1 from public.academic_groups g where g.id=v_group and g.organization_id=v_org and g.is_active))
  ) then raise exception 'Offering context must use active master data from the same organization.'; end if;
  update public.programme_offerings set
    branch_id=case when status='DRAFT' then v_branch else branch_id end,
    academic_year_id=case when status='DRAFT' then v_year else academic_year_id end,
    class_id=case when status='DRAFT' then v_class else class_id end,
    program_id=case when status='DRAFT' then v_program else program_id end,
    group_id=case when status='DRAFT' then v_group else group_id end,
    code=v_code,name=v_name
  where id=v_row.id returning * into v_row;
  v_result:=jsonb_build_object('offering_id',v_row.id,'correlation_id',v_request);
  insert into public.audit_events(correlation_id,actor_profile_id,actor_staff_id,branch_id,entity_type,entity_id,action,reason,before_data,after_data,metadata)
  values(v_request,v_actor,(select id from public.staff where profile_id=v_actor limit 1),v_row.branch_id,'PROGRAMME_OFFERING',v_row.id::text,'UPDATE',v_reason,v_before,to_jsonb(v_row),jsonb_build_object('request_id',v_request,'status',v_row.status));
  insert into public.admission_command_keys(request_id,actor_id,payload,result) values(v_request,v_actor,p_input,v_result);
  return v_result;
end
$function$
;

CREATE OR REPLACE FUNCTION public.update_programme_offering_public_controls(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_actor uuid := auth.uid();
  v_correlation uuid := gen_random_uuid();
  v_offering_id uuid;
  v_reason text;
  v_row public.programme_offerings%rowtype;
  v_before jsonb;
  v_title text;
  v_title_bn text;
  v_desc text;
  v_desc_bn text;
  v_eyebrow text;
  v_eyebrow_bn text;
  v_icon text;
  v_sort integer;
  v_visible boolean;
  v_accepting boolean;
  v_open date;
  v_close date;
  v_subjects jsonb;
  v_subject_id uuid;
  v_idx integer := 0;
begin
  if v_actor is null then
    raise exception 'Authentication required.';
  end if;
  if not public.has_permission('academics.manage') then
    raise exception 'You are not authorized to curate programme public controls.';
  end if;

  v_offering_id := nullif(p_input->>'offering_id', '')::uuid;
  v_reason := nullif(trim(coalesce(p_input->>'reason', '')), '');
  v_title := nullif(trim(coalesce(p_input->>'showcase_title', '')), '');
  v_title_bn := nullif(trim(coalesce(p_input->>'showcase_title_bn', '')), '');
  v_desc := nullif(trim(coalesce(p_input->>'showcase_description', '')), '');
  v_desc_bn := nullif(trim(coalesce(p_input->>'showcase_description_bn', '')), '');
  v_eyebrow := nullif(trim(coalesce(p_input->>'showcase_eyebrow', '')), '');
  v_eyebrow_bn := nullif(trim(coalesce(p_input->>'showcase_eyebrow_bn', '')), '');
  v_icon := nullif(trim(coalesce(p_input->>'showcase_icon', '')), '');
  v_sort := coalesce((p_input->>'showcase_sort_order')::integer, 100);
  v_visible := coalesce((p_input->>'is_website_visible')::boolean, false);
  v_accepting := coalesce((p_input->>'is_accepting_applications')::boolean, false);
  v_open := nullif(p_input->>'applications_open_on', '')::date;
  v_close := nullif(p_input->>'applications_close_on', '')::date;
  v_subjects := coalesce(p_input->'subject_ids', '[]'::jsonb);

  if v_offering_id is null then
    raise exception 'Offering is required.';
  end if;
  if v_reason is null or length(v_reason) < 5 then
    raise exception 'A short reason (at least 5 characters) is required for the audit trail.';
  end if;
  if v_sort < 0 or v_sort > 9999 then
    raise exception 'Sort order must be between 0 and 9999.';
  end if;
  if v_icon is not null and v_icon not in (
    'clipboard-check', 'graduation-cap', 'users-round',
    'book-open-check', 'line-chart', 'shield-check'
  ) then
    raise exception 'Unsupported showcase icon.';
  end if;
  if v_open is not null and v_close is not null and v_close < v_open then
    raise exception 'Applications close date must be on or after the open date.';
  end if;

  select * into v_row from public.programme_offerings where id = v_offering_id for update;
  if not found then
    raise exception 'Programme offering not found.';
  end if;

  if v_visible and v_row.status <> 'ACTIVE' then
    raise exception 'Only ACTIVE offerings (with a published Fee Plan) can be shown on the website.';
  end if;
  if v_visible and v_title is null then
    raise exception 'Showcase title (English) is required when website visibility is enabled.';
  end if;
  if v_visible and v_desc is null then
    raise exception 'Showcase description (English) is required when website visibility is enabled.';
  end if;
  if v_accepting and v_row.status = 'RETIRED' then
    raise exception 'Retired offerings cannot accept new applications.';
  end if;

  v_before := to_jsonb(v_row);

  update public.programme_offerings set
    showcase_title = v_title,
    showcase_title_bn = v_title_bn,
    showcase_description = v_desc,
    showcase_description_bn = v_desc_bn,
    showcase_eyebrow = v_eyebrow,
    showcase_eyebrow_bn = v_eyebrow_bn,
    showcase_icon = v_icon,
    showcase_sort_order = v_sort,
    is_website_visible = v_visible,
    is_accepting_applications = v_accepting,
    applications_open_on = v_open,
    applications_close_on = v_close,
    public_schedule = case when p_input ? 'public_schedule' then nullif(btrim(p_input->>'public_schedule'), '') else public_schedule end,
    public_requirements = case when p_input ? 'public_requirements' then nullif(btrim(p_input->>'public_requirements'), '') else public_requirements end,
    admission_policy = case when p_input ? 'admission_policy' then nullif(btrim(p_input->>'admission_policy'), '') else admission_policy end,
    public_schedule_bn = case when p_input ? 'public_schedule_bn' then nullif(btrim(p_input->>'public_schedule_bn'), '') else public_schedule_bn end,
    public_requirements_bn = case when p_input ? 'public_requirements_bn' then nullif(btrim(p_input->>'public_requirements_bn'), '') else public_requirements_bn end,
    admission_policy_bn = case when p_input ? 'admission_policy_bn' then nullif(btrim(p_input->>'admission_policy_bn'), '') else admission_policy_bn end,
    updated_at = now()
  where id = v_offering_id
  returning * into v_row;

  delete from public.programme_offering_subjects where offering_id = v_offering_id;
  if jsonb_typeof(v_subjects) = 'array' then
    for v_idx in 0 .. greatest(jsonb_array_length(v_subjects) - 1, -1) loop
      v_subject_id := nullif(v_subjects->>v_idx, '')::uuid;
      if v_subject_id is null then
        continue;
      end if;
      if not exists (
        select 1 from public.subjects s
        where s.id = v_subject_id and s.is_active
      ) then
        raise exception 'One selected subject is not available.';
      end if;
      insert into public.programme_offering_subjects (offering_id, subject_id, sort_order)
      values (v_offering_id, v_subject_id, v_idx);
    end loop;
  end if;

  insert into public.audit_events (
    correlation_id, actor_profile_id, actor_staff_id, branch_id,
    entity_type, entity_id, action, reason, before_data, after_data, metadata
  ) values (
    v_correlation,
    v_actor,
    (select id from public.staff where profile_id = v_actor limit 1),
    v_row.branch_id,
    'PROGRAMME_OFFERING',
    v_row.id::text,
    'UPDATE_PUBLIC_CONTROLS',
    v_reason,
    v_before,
    to_jsonb(v_row),
    jsonb_build_object(
      'is_website_visible', v_visible,
      'is_accepting_applications', v_accepting,
      'showcase_sort_order', v_sort,
      'subject_count', coalesce(jsonb_array_length(v_subjects), 0)
    )
  );

  return jsonb_build_object(
    'offering_id', v_row.id,
    'is_website_visible', v_row.is_website_visible,
    'is_accepting_applications', v_row.is_accepting_applications,
    'correlation_id', v_correlation
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_business_rule_payload(p_domain text, p_rule_key text, p_payload jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
begin
 if p_domain<>'academics' or p_rule_key<>'batch_capacity_policy' or jsonb_typeof(p_payload)<>'object' then return false;end if;
 return jsonb_typeof(p_payload->'max_students')='number' and (p_payload->>'max_students')::numeric between 1 and 500 and (p_payload->>'max_students')::numeric=trunc((p_payload->>'max_students')::numeric);
exception when others then return false;
end
$function$
;

CREATE OR REPLACE FUNCTION public.workforce_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$ begin
 if p_input->>'action' is distinct from 'RECORD_ATTENDANCE' then raise exception 'Only attendance is available in this version.';end if;
 return public.legacy_attendance_command(p_input);
end $function$
;

;

set check_function_bodies=true;

CREATE OR REPLACE FUNCTION public.admin_review_queue()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with queue as (
    select
      a.id,
      'ATTENDANCE'::text as review_type,
      a.id::text as entity_id,
      ('Attendance · ' || b.name || ' · ' || s.name) as title,
      coalesce(st.full_name, p.display_name) as teacher_name,
      st.staff_no as teacher_staff_no,
      b.name as batch_name,
      s.name as subject_name,
      coalesce(ar.requested_at, a.created_at) as submitted_at,
      a.revision,
      '/dashboard/academics/sessions/' || cs.id::text as href
    from public.attendance_submissions a
    left join public.approval_requests ar
      on ar.id = a.approval_id
    join public.class_sessions cs on cs.id = a.session_id
    join public.batches b on b.id = cs.batch_id
    join public.subjects s on s.id = cs.subject_id
    join public.profiles p on p.id = a.recorded_by
    left join public.staff st on st.profile_id = a.recorded_by
    where a.status = 'SUBMITTED'
      and public.has_permission('academics.attendance.approve')

    union all

    select
      l.id,
      'CLASS_LOG'::text as review_type,
      l.id::text as entity_id,
      ('Class log · ' || b.name || ' · ' || s.name) as title,
      coalesce(st.full_name, p.display_name) as teacher_name,
      st.staff_no as teacher_staff_no,
      b.name as batch_name,
      s.name as subject_name,
      l.submitted_at as submitted_at,
      l.revision,
      '/dashboard/academics/sessions/' || cs.id::text as href
    from public.class_logs l
    join public.class_sessions cs on cs.id = l.session_id
    join public.batches b on b.id = cs.batch_id
    join public.subjects s on s.id = cs.subject_id
    join public.profiles p on p.id = l.authored_by
    left join public.staff st on st.profile_id = l.authored_by
    where l.status = 'SUBMITTED'
      and public.has_permission('academics.attendance.approve')

    union all

    select
      r.id,
      'ASSESSMENT_RESULTS'::text as review_type,
      r.id::text as entity_id,
      ('Assessment results · ' || a.title) as title,
      coalesce(st.full_name, p.display_name) as teacher_name,
      st.staff_no as teacher_staff_no,
      b.name as batch_name,
      s.name as subject_name,
      coalesce(r.submitted_at, r.created_at) as submitted_at,
      r.revision,
      '/dashboard/academics/assessments?assessment=' || a.id::text as href
    from public.assessment_result_submissions r
    join public.academic_assessments a on a.id = r.assessment_id
    join public.batches b on b.id = a.batch_id
    join public.subjects s on s.id = a.subject_id
    join public.profiles p on p.id = r.author_id
    left join public.staff st on st.profile_id = r.author_id
    where r.status = 'SUBMITTED'
      and public.has_permission('academics.assessments.approve')

    union all

    select
      q.id,
      'QUESTION'::text as review_type,
      q.id::text as entity_id,
      ('Question · ' || q.topic) as title,
      coalesce(st.full_name, p.display_name) as teacher_name,
      st.staff_no as teacher_staff_no,
      b.name as batch_name,
      s.name as subject_name,
      coalesce(q.submitted_at, q.created_at) as submitted_at,
      q.revision,
      '/dashboard/academics/questions?item=' || q.id::text as href
    from public.question_bank_items q
    join public.batches b on b.id = q.batch_id
    join public.subjects s on s.id = q.subject_id
    join public.profiles p on p.id = q.author_id
    left join public.staff st on st.profile_id = q.author_id
    where q.status = 'SUBMITTED'
      and public.has_permission('academics.assessments.approve')
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', id,
        'reviewType', review_type,
        'entityId', entity_id,
        'title', title,
        'teacherName', teacher_name,
        'teacherStaffNo', teacher_staff_no,
        'batchName', batch_name,
        'subjectName', subject_name,
        'submittedAt', submitted_at,
        'revision', revision,
        'href', href
      )
      order by submitted_at asc, review_type, entity_id
    ),
    '[]'::jsonb
  )
  from queue;
$function$
;
