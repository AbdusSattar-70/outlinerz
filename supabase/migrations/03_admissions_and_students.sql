set check_function_bodies=false;
-- Academic admission detail. Nullable keys below only preserve the source UI DTO.
CREATE OR REPLACE FUNCTION public.admission_case_detail(p_admission_id uuid) returns jsonb language plpgsql stable security definer set search_path=pg_catalog,public as $$
declare result jsonb;begin
 if auth.uid() is null or not public.has_permission('admissions.view') then raise exception 'Admission workspace access denied.';end if;
 select jsonb_build_object(
    'id', a.id,
    'number', a.admission_no,
    'status', a.status,
    'createdAt', a.created_at,
    'existingStudent', a.existing_student,
    'origin', a.origin,
    'originProspectId', a.origin_prospect_id,
    'batchId', a.batch_id,
    'batchName', b.name,
    'batchCode', b.code,
    'batchCapacity', b.capacity,
    'batchOccupied', (
      select count(*)
      from public.enrollments e
      where e.batch_id = b.id
        and e.status = 'ACTIVE'
    ),
    'offeringId', o.id,
    'offeringName', o.name,
    'className', cl.name,
    'yearName', ay.name,
    'branchName', br.name,
    'studentNo', s.student_no,
    'studentId', s.id,
    'name', a.identity_snapshot->>'student_name',
    'nameBn', a.identity_snapshot->>'student_name_bn',
    'gender', a.identity_snapshot->>'gender',
    'dateOfBirth', a.identity_snapshot->>'date_of_birth',
    'schoolName', a.identity_snapshot->>'school_name',
    'schoolRoll', a.identity_snapshot->>'school_roll',
    'guardianAddress', a.identity_snapshot->>'guardian_address',
    'alternateMobile', a.identity_snapshot->>'alternate_mobile',
    'guardianRelationship', a.identity_snapshot->>'guardian_relationship',
    'guardian', a.identity_snapshot->>'guardian_name',
    'mobile', a.identity_snapshot->>'mobile',
    'feeVersion',null,'feePlanId',null,'policyVersion',null,'paymentRequirement',null,
    'components','[]'::jsonb,'invoice',null,'receipts','[]'::jsonb,
    'tuitionTotal',0,'additionalCharges','[]'::jsonb,'discountPercent',0,'discountReason',null,
    'academyRoll',s.academy_roll::text,
    'additionalDetails',(select jsonb_object_agg(key,value #>> '{}') from jsonb_each(a.identity_snapshot))
 ) into result
 from public.admission_cases a join public.batches b on b.id=a.batch_id
 join public.programme_offerings o on o.id=b.offering_id
 join public.classes cl on cl.id=b.class_id
 join public.academic_years ay on ay.id=b.academic_year_id
 left join public.branches br on br.id=b.branch_id
 left join public.students s on s.id=a.student_id where a.id=p_admission_id;
 if result is null then raise exception 'Admission case not found.';end if;
 return result;
end $$;

CREATE OR REPLACE FUNCTION public.admission_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare actor uuid:=auth.uid();req uuid:=nullif(p_input->>'request_id','')::uuid;action text:=p_input->>'action';a public.admission_cases;b public.batches;o public.programme_offerings;p public.prospects;k public.admission_command_keys;student uuid;guardian uuid;enrollment uuid;result jsonb; begin
 if actor is null or not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if req is null or length(btrim(coalesce(p_input->>'reason','')))<5 then raise exception 'A request identity and a verification note are required.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));select * into k from public.admission_command_keys where request_id=req;
 if found then if k.actor_id<>actor or k.payload<>p_input then raise exception 'Request identity already used.'; end if; return k.result; end if;
 if action='CREATE' then
  select * into p from public.prospects where id=(p_input->>'prospect_id')::uuid for update;
  select * into b from public.batches where id=(p_input->>'batch_id')::uuid and is_active for update;
  select * into o from public.programme_offerings where id=b.offering_id and status='ACTIVE';
  if p.id is null or p.status in('LOST','CONVERTED') or o.id is null or o.id is distinct from(p_input->>'offering_id')::uuid or(p.current_class_id is not null and p.current_class_id<>o.class_id) then raise exception 'Choose an open enquiry and its matching active offering and batch.'; end if;
  if exists(select 1 from public.admission_cases where prospect_id=p.id and status<>'CANCELLED') then raise exception 'This enquiry already has an admission case.'; end if;
  if(select count(*) from public.enrollments where batch_id=b.id and status='ACTIVE')>=b.capacity then raise exception 'Selected batch is full.'; end if;
  insert into public.admission_cases(prospect_id,batch_id,identity_snapshot,created_by,consent_required,origin_prospect_id,origin)
   values(p.id,b.id,coalesce(p.application_snapshot,'{}'::jsonb)||jsonb_build_object('student_name',p.student_name,'student_name_bn',p.student_name_bn,'guardian_name',p.guardian_name,'mobile',p.mobile,'guardian_relationship',coalesce(p.guardian_relationship_snapshot,'Guardian'),'school_id',p.school_id,'school_name',p.school_name_snapshot,'gender',p.gender,'date_of_birth',p.date_of_birth,'guardian_address',p.guardian_address),actor,false,p.id,case when p.submitted_via='PUBLIC_WEB' then 'PUBLIC_APPLICATION' else 'PROSPECT_CONVERSION' end) returning * into a;
 else
  select * into a from public.admission_cases where id=(p_input->>'admission_id')::uuid for update;
  if a.id is null then raise exception 'Admission case is unavailable in this branch.'; end if;
  select * into b from public.batches where id=a.batch_id and is_active for update;
  select * into o from public.programme_offerings where id=b.offering_id and status='ACTIVE';
  if o.id is null then raise exception 'Choose an active academic placement.'; end if;
  if action='EDIT_DRAFT' and a.status in('DRAFT','READY') then
   if length(btrim(coalesce(p_input->>'student_name','')))<2 or length(btrim(coalesce(p_input->>'guardian_name','')))<2 or coalesce(p_input->>'mobile','')!~'^01[3-9][0-9]{8}$' then raise exception 'Enter valid student, guardian and mobile details.'; end if;
   update public.admission_cases set identity_snapshot=identity_snapshot||jsonb_build_object('student_name',btrim(p_input->>'student_name'),'guardian_name',btrim(p_input->>'guardian_name'),'mobile',p_input->>'mobile'),status='DRAFT' where id=a.id;
  elsif action='READY' and a.status='DRAFT' then
   if length(btrim(coalesce(a.identity_snapshot->>'student_name','')))<2 or length(btrim(coalesce(a.identity_snapshot->>'guardian_name','')))<2 or coalesce(a.identity_snapshot->>'mobile','')!~'^01[3-9][0-9]{8}$' then raise exception 'Verify student and guardian details first.'; end if;
   update public.admission_cases set status='READY' where id=a.id;
  elsif action='RETURN_TO_DRAFT' and a.status='READY' then update public.admission_cases set status='DRAFT' where id=a.id;
  elsif action in('FINALIZE','ACCEPT','ACTIVATE') and a.status='READY' then
   if(select count(*) from public.enrollments where batch_id=b.id and status='ACTIVE')>=b.capacity then raise exception 'Selected batch is full.'; end if;
   if a.existing_student then
    student:=a.student_id;
    if not exists(select 1 from public.students where id=student and status='ACTIVE' and merged_into_id is null) or exists(select 1 from public.enrollments where student_id=student and academic_year_id=b.academic_year_id and status='ACTIVE') then raise exception 'Existing student is unavailable or already enrolled in this academic year.';end if;
   else
   select * into p from public.prospects where id=a.prospect_id for update;
   if p.id is null or p.status in('CONVERTED','LOST') then raise exception 'Enquiry is no longer eligible.'; end if;
   if exists(select 1 from public.students s join public.student_guardians sg on sg.student_id=s.id join public.guardians g on g.id=sg.guardian_id where lower(s.full_name)=lower(a.identity_snapshot->>'student_name') and g.mobile=a.identity_snapshot->>'mobile') then raise exception 'A matching student already exists. Review the existing identity before continuing.'; end if;
   insert into public.students(organization_id,branch_id,full_name,name_bn,gender,date_of_birth,created_from_prospect_id,created_by) values(b.organization_id,b.branch_id,a.identity_snapshot->>'student_name',a.identity_snapshot->>'student_name_bn',a.identity_snapshot->>'gender',nullif(a.identity_snapshot->>'date_of_birth','')::date,p.id,actor) returning id into student;
   insert into public.guardians(organization_id,full_name,mobile,address,created_by) values(b.organization_id,a.identity_snapshot->>'guardian_name',a.identity_snapshot->>'mobile',a.identity_snapshot->>'guardian_address',actor) returning id into guardian;
   insert into public.student_guardians(student_id,guardian_id,relationship_snapshot,is_primary) values(student,guardian,a.identity_snapshot->>'guardian_relationship',true);
   end if;
   insert into public.enrollments(student_id,organization_id,branch_id,academic_year_id,class_id,program_id,batch_id,created_by) values(student,b.organization_id,b.branch_id,b.academic_year_id,b.class_id,b.program_id,b.id,actor) returning id into enrollment;
   update public.admission_cases set student_id=student,enrollment_id=enrollment,capacity_policy_version_id=b.capacity_policy_version_id,status='ACTIVE_ENROLLMENT' where id=a.id;
   update public.prospects set status='CONVERTED',converted_student_id=student,converted_at=now() where id=p.id;
  else raise exception 'This action is unavailable at the current admission stage.'; end if;
 end if;
 select jsonb_build_object('id',id,'status',status) into result from public.admission_cases where id=a.id;
 insert into public.audit_events(correlation_id,actor_profile_id,branch_id,entity_type,entity_id,action,reason,after_data) values(req,actor,academy_private.current_branch_id(),'ADMISSION',a.id::text,action,p_input->>'reason',result);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,actor,p_input,result);return result;
end $function$
;

CREATE OR REPLACE FUNCTION public.admission_directory_options()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if auth.uid() is null then raise exception 'Sign in required.'; end if;
 if not public.has_permission('admissions.view') then return jsonb_build_object('schools','[]'::jsonb,'relationships','[]'::jsonb); end if;
 return jsonb_build_object('schools',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from public.schools where is_active),'[]'::jsonb),
 'relationships',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from public.guardian_relationships where is_active),'[]'::jsonb));
end $function$
;

CREATE OR REPLACE FUNCTION public.admission_offering_options()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case
    when auth.uid() is null or not public.has_permission('admissions.view')
      then '[]'::jsonb
    else coalesce((
      select jsonb_agg(jsonb_build_object(
        'id',o.id,'name',o.name,'code',o.code,
        'classId',o.class_id,'className',c.name,
        'yearName',ay.name,'branchName',br.name,
        'feeReady',true
      ) order by ay.starts_on desc,o.name)
      from public.programme_offerings o
      join public.classes c on c.id=o.class_id
      join public.academic_years ay on ay.id=o.academic_year_id
      join public.organizations org on org.id=o.organization_id
      left join public.branches br on br.id=o.branch_id
      where o.status='ACTIVE'
    ),'[]'::jsonb)
  end;
$function$
;

CREATE OR REPLACE FUNCTION public.admission_workspace()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_view boolean:=public.has_permission('admissions.view'); v_result jsonb;
begin
 if auth.uid() is null or not (v_view or public.has_permission('academics.view')) then raise exception 'Workspace access denied.'; end if;
 select jsonb_build_object(
  'offerings',coalesce((select jsonb_agg(jsonb_build_object('id',o.id,'name',o.name,'code',o.code,
      'classId',o.class_id,'className',c.name,'yearName',ay.name,'branchName',br.name))
    from public.programme_offerings o join public.classes c on c.id=o.class_id
    join public.academic_years ay on ay.id=o.academic_year_id left join public.branches br on br.id=o.branch_id
    join public.organizations org on org.id=o.organization_id
    where o.status='ACTIVE' ),'[]'::jsonb),
  'capacityLimit',(select (payload->>'max_students')::integer from public.business_rule_versions where domain='academics' and rule_key='batch_capacity_policy' and status='ACTIVE'),
  'batches',coalesce((select jsonb_agg(jsonb_build_object(
    'id',b.id,'name',b.name,'code',b.code,'offeringId',b.offering_id,
    'offeringName',o.name,'classId',b.class_id,'className',c.name,
    'yearName',y.name,'branchName',br.name,'capacity',b.capacity,
    'isActive',b.is_active,
    'occupied',(select count(*) from public.enrollments e where e.batch_id=b.id and e.status='ACTIVE')
  ) order by y.starts_on desc,o.name,b.name)
    from public.batches b
    join public.programme_offerings o on o.id=b.offering_id
    join public.classes c on c.id=b.class_id
    join public.academic_years y on y.id=b.academic_year_id
    left join public.branches br on br.id=b.branch_id
  ),'[]'::jsonb),
  'prospects',case when v_view then coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'name',p.student_name,'number',p.prospect_no,'classId',p.current_class_id,'interestedOfferingId',p.interested_offering_id,'guardian',p.guardian_name,'mobile',p.mobile)) from public.prospects p where p.status not in ('CONVERTED','LOST') and not exists(select 1 from public.admission_cases a where a.prospect_id=p.id and a.status<>'CANCELLED')),'[]'::jsonb) else '[]'::jsonb end,
  'cases',case when v_view then coalesce((select jsonb_agg(public.admission_case_detail(id) order by created_at desc) from public.admission_cases),'[]'::jsonb) else '[]'::jsonb end,
  'paymentMethods','[]'::jsonb
 ) into v_result;
 return v_result;
end; $function$
;

CREATE OR REPLACE FUNCTION public.close_student_enrollment(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare e public.enrollments; today date; mode text:=p_input->>'mode'; before_data jsonb;
begin
 if auth.uid() is null or not public.has_permission('students.manage') then raise exception 'Student management permission required.'; end if;
 if mode not in('WITHDRAWN','COMPLETED') or mode is null or length(btrim(coalesce(p_input->>'reason',''))) not between 5 and 500 then raise exception 'Choose withdrawal or completion and record the reason.'; end if;
 -- Match admission command lock order to keep financial and enrollment mutations consistent.
 perform 1 from public.admission_cases where enrollment_id=(p_input->>'enrollment_id')::uuid for update;
 select * into e from public.enrollments where id=(p_input->>'enrollment_id')::uuid and student_id=(p_input->>'student_id')::uuid for update;
 if e.id is null then raise exception 'Enrollment not found for this student.'; end if;
 if e.status<>'ACTIVE' then return jsonb_build_object('id',e.id,'message','Enrollment is already closed.'); end if;
 select timezone(timezone,now())::date into today from public.organizations where id=e.organization_id;
 if today<e.admission_date then raise exception 'Enrollment start is in the future. Cancel the admission instead.'; end if;
 before_data:=to_jsonb(e);
 update public.enrollments set status=mode::public.enrollment_status,ended_on=today where id=e.id;
 update public.admission_cases set status='CLOSED_ENROLLMENT' where enrollment_id=e.id and status='ACTIVE_ENROLLMENT';
 if not exists(select 1 from public.enrollments where student_id=e.student_id and status='ACTIVE') then update public.students set status='INACTIVE' where id=e.student_id; end if;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(auth.uid(),'ENROLLMENT',e.id::text,mode,p_input->>'reason',before_data,jsonb_build_object('status',mode,'ended_on',today,'student_id',e.student_id));
 return jsonb_build_object('id',e.id,'message','Enrollment closed. Future recurring billing stops; existing invoices, payments and due balances remain.');
end $function$
;

CREATE OR REPLACE FUNCTION public.correct_admission_placement(p_input jsonb) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare a public.admission_cases;b public.batches;begin
 if not public.has_permission('admissions.manage') then raise exception 'Admission management permission required.';end if;
 select * into a from public.admission_cases where id=(p_input->>'admission_id')::uuid for update;
 select * into b from public.batches where id=(p_input->>'batch_id')::uuid and is_active;
 if a.id is null or a.status not in('DRAFT','READY') or b.id is null then raise exception 'Choose a draft admission and an active batch in this branch.';end if;
 if (select count(*) from public.enrollments where batch_id=b.id and status='ACTIVE')>=b.capacity then raise exception 'Selected batch is full.';end if;
 update public.admission_cases set batch_id=b.id,status='DRAFT',identity_revision=identity_revision+1 where id=a.id;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason) values(auth.uid(),'ADMISSION',a.id::text,'CORRECT_PLACEMENT',coalesce(p_input->>'reason','Academic placement correction'));
 return jsonb_build_object('id',a.id);
end $$;

CREATE OR REPLACE FUNCTION public.create_admission_directory_choice(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare org uuid; result jsonb; name_value text:=btrim(coalesce(p_input->>'name',''));
begin
 if auth.uid() is null or not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if length(name_value) not between 2 and 160 then raise exception 'Enter a name of 2 to 160 characters.'; end if;
 select id into org from public.organizations where is_active;
 perform pg_advisory_xact_lock(hashtextextended(lower(name_value),6));
 if p_input->>'entity'='school' then
  select jsonb_build_object('id',id,'name',name) into result from public.schools where organization_id=org and lower(name)=lower(name_value) and is_active limit 1;
  if result is null then insert into public.schools(organization_id,name,is_verified,is_active) values(org,name_value,true,true) returning jsonb_build_object('id',id,'name',name) into result; end if;
 elsif p_input->>'entity'='relationship' then
  select jsonb_build_object('id',id,'name',name) into result from public.guardian_relationships where organization_id=org and lower(name)=lower(name_value) and is_active limit 1;
  if result is null then insert into public.guardian_relationships(organization_id,code,name,is_active) values(org,'REL_'||replace(gen_random_uuid()::text,'-',''),name_value,true) returning jsonb_build_object('id',id,'name',name) into result; end if;
 else raise exception 'Only school and guardian relationship can be created during admission.';
 end if;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,after_data)
 values(auth.uid(),upper(p_input->>'entity'),result->>'id','SELECT_OR_CREATE_FOR_ADMISSION','Verified missing directory option during admission',result);
 return result;
end $function$
;

CREATE OR REPLACE FUNCTION public.create_prospect_admission(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare chosen uuid; changed uuid; p public.prospects; o public.programme_offerings; k public.admission_command_keys;
 req uuid:=nullif(p_input->>'request_id','')::uuid; result jsonb;
begin
 if auth.uid() is null or not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if req is null or p_input->>'action' is distinct from 'CREATE' or length(btrim(coalesce(p_input->>'reason','')))<5 then
  raise exception 'A valid request and verification note are required.';
 end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));
 select * into k from public.admission_command_keys where request_id=req;
 if found then
  if k.actor_id<>auth.uid() or k.payload<>p_input then raise exception 'Request identity already used.'; end if;
  return k.result;
 end if;
 select * into p from public.prospects where id=(p_input->>'prospect_id')::uuid for update;
 select * into o from public.programme_offerings where id=(p_input->>'offering_id')::uuid and status='ACTIVE';
 if p.id is null or p.status in('CONVERTED','LOST') or o.id is null or p.organization_id<>o.organization_id
 or not exists(select 1 from public.batches where id=(p_input->>'batch_id')::uuid and offering_id=o.id and is_active) then
  raise exception 'Choose an open enquiry, active offering and its batch.';
 end if;
 if (p.current_class_id is not null and p.current_class_id<>o.class_id)
   or (p.interested_offering_id is not null and p.interested_offering_id<>o.id) then
  if coalesce((p_input->>'confirm_placement_correction')::boolean,false) is not true then
   raise exception 'Confirm the corrected placement.';
  end if;
 end if;
 update public.prospects set current_class_id=o.class_id,interested_offering_id=o.id,
  application_verified_at=now(),application_verified_by=auth.uid() where id=p.id;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(req,auth.uid(),'PROSPECT',p.id::text,'VERIFY_ADMISSION_PLACEMENT',p_input->>'reason',to_jsonb(p),
   jsonb_build_object('class_id',o.class_id,'offering_id',o.id));
 if not exists(select 1 from public.organizations where id=o.organization_id and setup_completed_at is not null and is_active) then raise exception 'Complete public setup before starting admissions.'; end if;
 result:=public.admission_command(p_input);
 update public.admission_cases set identity_snapshot=identity_snapshot||jsonb_strip_nulls(jsonb_build_object(
 'guardian_address',coalesce(p.guardian_address,p.application_snapshot->>'guardian_address'),
 'alternate_mobile',p.alternate_mobile,'student_name_bn',p.student_name_bn,
 'date_of_birth',coalesce(p.date_of_birth::text,p.application_snapshot->>'date_of_birth'),
 'gender',coalesce(p.gender,p.application_snapshot->>'gender'),
 'school_roll',coalesce(p.school_roll,p.application_snapshot->>'school_roll'),
 'student_mobile',p.application_snapshot->>'student_mobile','student_email',p.application_snapshot->>'student_email','present_landmark',p.application_snapshot->>'present_landmark','permanent_address',p.application_snapshot->>'permanent_address','permanent_same_as_present',p.application_snapshot->>'permanent_same_as_present','birth_registration',p.application_snapshot->>'birth_registration','previous_result',p.application_snapshot->>'previous_result',
 'father_name',p.application_snapshot->>'father_name','mother_name',p.application_snapshot->>'mother_name',
 'emergency_contact',p.application_snapshot->>'emergency_contact','emergency_mobile',p.application_snapshot->>'emergency_mobile',
 'learning_needs',p.application_snapshot->>'learning_needs'))
 where id=(result->>'id')::uuid;

 select id into chosen from public.staff where profile_id=auth.uid() and status in('ACTIVE','ON_LEAVE');
 if chosen is not null then
 update public.prospects set assigned_to_staff_id=chosen where id=(p_input->>'prospect_id')::uuid and assigned_to_staff_id is null returning id into changed;
 if changed is not null then
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,after_data)
 values((p_input->>'request_id')::uuid,auth.uid(),'PROSPECT',changed::text,'ASSIGN_FOLLOWUP_STAFF','Staff handled verified admission conversion',jsonb_build_object('staff_id',chosen));
 end if; end if;

 return result;
end
$function$
;

CREATE OR REPLACE FUNCTION public.create_staff_admission_intake(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare actor uuid:=auth.uid();req uuid:=nullif(p_input->>'request_id','')::uuid;old public.staff_admission_intake_requests;prospect uuid;offering public.programme_offerings;result jsonb; begin
 if actor is null or not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if req is null or octet_length(p_input::text)>16000 or length(btrim(coalesce(p_input->>'reason','')))<5 or length(btrim(coalesce(p_input->>'student_name','')))<2 or length(btrim(coalesce(p_input->>'guardian_name','')))<2 or coalesce(p_input->>'mobile','')!~'^01[3-9][0-9]{8}$' or not coalesce((p_input->>'consent_to_contact')::boolean,false) then raise exception 'Enter verified student, guardian, mobile and contact consent details.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));select * into old from public.staff_admission_intake_requests where request_id=req;
 if found then if old.actor_id<>actor or old.payload<>p_input then raise exception 'Request already used for different input.';end if;return jsonb_build_object('admission_id',old.admission_id);end if;
 select * into offering from public.programme_offerings where id=(p_input->>'offering_id')::uuid and status='ACTIVE';
 if offering.id is null then raise exception 'Choose an active programme offering.';end if;
 insert into public.prospects(organization_id,branch_id,student_name,student_name_bn,guardian_name,mobile,current_class_id,interested_offering_id,guardian_address,guardian_relationship_snapshot,date_of_birth,gender,school_name_snapshot,school_roll,alternate_mobile,consent_to_contact,submitted_via,application_snapshot)
 values(offering.organization_id,offering.branch_id,btrim(p_input->>'student_name'),nullif(p_input->>'student_name_bn',''),btrim(p_input->>'guardian_name'),p_input->>'mobile',offering.class_id,offering.id,nullif(p_input->>'guardian_address',''),p_input->>'guardian_relationship',nullif(p_input->>'date_of_birth','')::date,nullif(p_input->>'gender',''),nullif(p_input->>'school_name',''),nullif(p_input->>'school_roll',''),nullif(p_input->>'alternate_mobile',''),true,'STAFF_INTAKE',p_input) returning id into prospect;
 result:=public.admission_command(jsonb_build_object('request_id',req,'action','CREATE','prospect_id',prospect,'batch_id',p_input->>'batch_id','offering_id',offering.id,'reason',p_input->>'reason'));
 update public.admission_cases set origin='DIRECT_STAFF',origin_prospect_id=null where id=(result->>'id')::uuid;
 insert into public.staff_admission_intake_requests(request_id,actor_id,payload,prospect_id,admission_id) values(req,actor,p_input,prospect,(result->>'id')::uuid);
 return jsonb_build_object('admission_id',result->>'id','admission_no',(select admission_no from public.admission_cases where id=(result->>'id')::uuid));
end $function$
;

CREATE OR REPLACE FUNCTION public.edit_admission_identity(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare a public.admission_cases; identity jsonb:=p_input->'identity'; guardian_id uuid; before_data jsonb;
begin
 if auth.uid() is null or not public.has_permission('admissions.create') then raise exception 'Admission management permission required.'; end if;
 if jsonb_typeof(identity) is distinct from 'object' or octet_length(identity::text)>5000
 or length(btrim(coalesce(p_input->>'reason','')))<5
 or length(btrim(coalesce(identity->>'student_name',''))) not between 2 and 160
 or length(btrim(coalesce(identity->>'guardian_name',''))) not between 2 and 160
 or coalesce(identity->>'mobile','') !~ '^01[3-9][0-9]{8}$'
 or length(btrim(coalesce(identity->>'guardian_address',''))) not between 5 and 300 then raise exception 'Enter verified student, guardian, contact and address details.'; end if;
 select * into a from public.admission_cases where id=(p_input->>'admission_id')::uuid for update;
 if a.id is null or a.status='CANCELLED' then raise exception 'Choose an open admission case.'; end if;
 if a.existing_student and a.student_id is null then raise exception 'Existing student identity is unavailable.'; end if;
 before_data:=a.identity_snapshot;
 if coalesce(identity->>'student_mobile','') !~ '^$|^01[3-9][0-9]{8}$' or coalesce(identity->>'student_email','') !~ '^$|^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'Check optional student contact.'; end if;
 identity:=jsonb_build_object('student_mobile',identity->>'student_mobile','student_email',identity->>'student_email','present_landmark',left(identity->>'present_landmark',160),'permanent_address',left(identity->>'permanent_address',300),'permanent_same_as_present',identity->>'permanent_same_as_present','student_name',btrim(identity->>'student_name'),'student_name_bn',nullif(btrim(identity->>'student_name_bn'),''),
 'guardian_name',btrim(identity->>'guardian_name'),'mobile',identity->>'mobile','alternate_mobile',nullif(identity->>'alternate_mobile',''),
 'guardian_address',btrim(identity->>'guardian_address'),'guardian_relationship',btrim(identity->>'guardian_relationship'),
 'date_of_birth',nullif(identity->>'date_of_birth','')::date,'gender',nullif(identity->>'gender',''),
 'school_name',btrim(identity->>'school_name'),'school_roll',btrim(identity->>'school_roll'));
 if a.student_id is not null then
  if not public.has_permission('students.manage') then raise exception 'Student correction permission required.'; end if;
  update public.students set full_name=identity->>'student_name',school_name_snapshot=identity->>'school_name' where id=a.student_id;
  -- Do not change a shared guardian identity. Link to an existing matching guardian
  -- or create the corrected guardian; keep the old guardian record intact.
  select g.id into guardian_id from public.guardians g join public.students s on s.organization_id=g.organization_id
   where s.id=a.student_id and g.mobile=identity->>'mobile' and lower(g.full_name)=lower(identity->>'guardian_name') order by g.created_at limit 1;
  if guardian_id is null then
   insert into public.guardians(organization_id,full_name,mobile,created_by)
    select organization_id,identity->>'guardian_name',identity->>'mobile',auth.uid() from public.students where id=a.student_id returning id into guardian_id;
  end if;
  update public.student_guardians set is_primary=false where student_id=a.student_id and is_primary;
  insert into public.student_guardians(student_id,guardian_id,relationship_snapshot,is_primary)
  values(a.student_id,guardian_id,identity->>'guardian_relationship',true)
  on conflict(student_id,guardian_id) do update set is_primary=true,relationship_snapshot=excluded.relationship_snapshot;
 end if;
 update public.admission_cases set identity_snapshot=identity_snapshot||identity,
  identity_revision=identity_revision+1,
  status=case when status in('DRAFT','READY') then 'DRAFT' else status end where id=a.id;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data)
 values(auth.uid(),'ADMISSION',a.id::text,'CORRECT_IDENTITY',p_input->>'reason',before_data,identity);
 return jsonb_build_object('id',a.id);
end $function$
;

CREATE OR REPLACE FUNCTION public.enforce_enrollment_batch_integrity()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
  v_batch public.batches;
  v_occupied integer;
begin
  if new.status <> 'ACTIVE' or new.batch_id is null then
    return new;
  end if;

  select * into v_batch
  from public.batches
  where id = new.batch_id
    and is_active
  for update;

  if v_batch.id is null then
    raise exception 'Selected batch is not available.';
  end if;

  if new.organization_id <> v_batch.organization_id
     or new.academic_year_id <> v_batch.academic_year_id
     or new.class_id <> v_batch.class_id
     or new.program_id is distinct from v_batch.program_id then
    raise exception 'Enrollment does not match the selected batch academic context.';
  end if;

  select count(*)::integer into v_occupied
  from public.enrollments e
  where e.batch_id = new.batch_id
    and e.status = 'ACTIVE'
    and e.id <> new.id;

  if v_occupied >= v_batch.capacity then
    raise exception 'Selected batch is full (%/%).', v_occupied, v_batch.capacity;
  end if;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.protect_record_history()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$ begin raise exception 'Historical records are immutable; record a new version or an audited correction.'; end; $function$
;

CREATE OR REPLACE FUNCTION public.record_physical_admission_consent(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare a public.admission_cases; r public.admission_physical_consent_receipts;
 req uuid:=(p_input->>'request_id')::uuid; signing date:=(p_input->>'guardian_signed_on')::date; today date;
begin
 if auth.uid() is null or not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if req is null or signing is null or length(btrim(coalesce(p_input->>'reason','')))<5 then raise exception 'Signing date and staff note are required.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));
 select * into r from public.admission_physical_consent_receipts where request_id=req;
 if found then
  if r.received_by<>auth.uid() or r.request_payload<>p_input then raise exception 'Request identity already used.'; end if;
  return jsonb_build_object('id',r.id);
 end if;
 select * into a from public.admission_cases where id=(p_input->>'admission_id')::uuid for update;
 if a.id is null or a.status in('DRAFT','CANCELLED') then raise exception 'Verify the application before receiving paper consent.'; end if;
 select timezone(o.timezone,now())::date into today from public.batches b join public.organizations o on o.id=b.organization_id where b.id=a.batch_id;
 if signing>today then raise exception 'Signing date cannot be in the future.'; end if;
 if exists(select 1 from public.admission_physical_consent_receipts where admission_id=a.id and identity_revision=a.identity_revision) then raise exception 'Consent for these details is already recorded.'; end if;
 insert into public.admission_physical_consent_receipts(request_id,request_payload,admission_id,version,guardian_signed_on,student_signed,physical_copy_reference,received_by,reason,identity_revision)
 values(req,p_input,a.id,(select coalesce(max(version),0)+1 from public.admission_physical_consent_receipts where admission_id=a.id),signing,coalesce((p_input->>'student_signed')::boolean,false),nullif(btrim(p_input->>'physical_copy_reference'),''),auth.uid(),p_input->>'reason',a.identity_revision) returning * into r;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,after_data)
 values(auth.uid(),'ADMISSION_CONSENT',r.id::text,'RECEIVE_PAPER_FORM',p_input->>'reason',to_jsonb(r));
 return jsonb_build_object('id',r.id);
end $function$
;

CREATE OR REPLACE FUNCTION public.student_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 actor uuid:=auth.uid();req uuid:=(p_input->>'request_id')::uuid;action text:=p_input->>'action';reason text:=btrim(coalesce(p_input->>'reason',''));
 key public.admission_command_keys;s public.students;target public.students;a public.admission_cases;b public.batches;dest public.batches;
 fee record;guardian record;policy public.business_rule_versions;e public.enrollments;
 sid uuid:=(p_input->>'student_id')::uuid;tid uuid:=(p_input->>'target_id')::uuid;eid uuid;aid uuid;today date;result jsonb;snapshot jsonb;
begin
 if actor is null or not public.has_permission('students.view') then raise exception 'Student access required.'; end if;
 if req is null or length(reason) not between 5 and 500 then raise exception 'Request identity and a reason of 5–500 characters required.'; end if;
 if action='CREATE_EXISTING' then
  if not public.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 elsif action in('TRANSFER','MERGE') then
  if not public.has_permission('students.manage') then raise exception 'Student management permission required.'; end if;
 else raise exception 'Unsupported student action.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));
 select * into key from public.admission_command_keys where request_id=req;
 if found then
  if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity already used.'; end if;
  return key.result;
 end if;
 if action='TRANSFER' then
  aid:=(p_input->>'admission_id')::uuid;
  select * into a from public.admission_cases where id=aid for update;
  if a.id is null or a.student_id is distinct from sid then raise exception 'Admission does not belong to this student.'; end if;
 end if;
 perform 1 from public.students where id in(sid,tid) order by id for update;
 select * into s from public.students where id=sid;
 if s.id is null or s.merged_into_id is not null or s.status='ARCHIVED' then raise exception 'Use an existing canonical student.'; end if;
 select timezone(timezone,now())::date into today from public.organizations where id=s.organization_id;
  if action='CREATE_EXISTING' then
   select * into b from public.batches where id=(p_input->>'batch_id')::uuid and is_active for update;
   if b.id is null or b.organization_id<>s.organization_id or not exists(select 1 from public.programme_offerings where id=b.offering_id and status='ACTIVE') then raise exception 'Select an active offering-linked batch in this organization.';end if;
   if exists(select 1 from public.enrollments where student_id=s.id and academic_year_id=b.academic_year_id and status='ACTIVE')
    or exists(select 1 from public.admission_cases ac join public.batches ba on ba.id=ac.batch_id where ac.student_id=s.id and ba.academic_year_id=b.academic_year_id and ac.status<>'CANCELLED') then
    raise exception 'An open admission or active enrollment already exists for this academic year. Use transfer or finish cancellation first.';end if;
   select * into policy from public.business_rule_versions where domain='academics' and rule_key='batch_capacity_policy' and status='ACTIVE';
   if policy.id is null then raise exception 'Capacity policy missing.';end if;
   if (select count(*) from public.enrollments where batch_id=b.id and status='ACTIVE')>=least(b.capacity,(policy.payload->>'max_students')::integer) then raise exception 'Selected batch is full.';end if;
   select g.full_name,g.mobile,sg.relationship_snapshot into guardian from public.student_guardians sg join public.guardians g on g.id=sg.guardian_id where sg.student_id=s.id and sg.is_primary;
   if guardian.full_name is null then raise exception 'A primary guardian is required.';end if;
   insert into public.admission_cases(batch_id,student_id,existing_student,identity_snapshot,created_by,origin,consent_required)
   values(b.id,s.id,true,jsonb_build_object('student_name',s.full_name,'guardian_name',guardian.full_name,'mobile',guardian.mobile,'guardian_relationship',coalesce(guardian.relationship_snapshot,'Guardian'),'school_id',s.school_id,'school_name',s.school_name_snapshot),actor,'EXISTING_STUDENT',false) returning id into aid;
   result:=jsonb_build_object('id',aid,'message','Enrollment draft created using the existing Student ID. Review and accept it in Admissions.');
  elsif action='TRANSFER' then
   if a.status<>'ACTIVE_ENROLLMENT' then raise exception 'Only an active enrollment can transfer.';end if;
   select * into e from public.enrollments where id=a.enrollment_id and status='ACTIVE';
   if e.id is null then raise exception 'Active enrollment not found.';end if;
   eid:=(p_input->>'batch_id')::uuid;
   perform 1 from public.batches where id in(a.batch_id,eid) order by id for update;
   select * into b from public.batches where id=a.batch_id;
   select * into dest from public.batches where id=eid and is_active;
   if dest.id is null or dest.id=b.id or dest.offering_id is distinct from b.offering_id or dest.organization_id<>b.organization_id then raise exception 'Transfer requires a different active batch in the same offering. Academic placement remains unchanged.';end if;
   select * into policy from public.business_rule_versions where domain='academics' and rule_key='batch_capacity_policy' and status='ACTIVE';
   if policy.id is null then raise exception 'Capacity policy missing.';end if;
   if (select count(*) from public.enrollments where batch_id=dest.id and status='ACTIVE')>=least(dest.capacity,(policy.payload->>'max_students')::integer) then raise exception 'Destination batch is full under the current capacity policy.';end if;
    update public.enrollments set status='WITHDRAWN',ended_on=today where id=e.id;
    insert into public.enrollments(student_id,organization_id,branch_id,academic_year_id,class_id,program_id,batch_id,admission_date,status,created_by)
    values(s.id,dest.organization_id,dest.branch_id,dest.academic_year_id,dest.class_id,dest.program_id,dest.id,today,'ACTIVE',actor) returning id into eid;
    insert into public.enrollment_transfers(student_id,admission_id,from_enrollment_id,to_enrollment_id,from_batch_id,to_batch_id,authorized_by,authorization_reason,capacity_policy_version_id,transferred_on)
    values(s.id,a.id,e.id,eid,b.id,dest.id,actor,reason,policy.id,today);
    update public.admission_cases set batch_id=dest.id,enrollment_id=eid,capacity_policy_version_id=policy.id where id=a.id;
   result:=jsonb_build_object('id',a.id,'message','Batch transfer completed; academic history preserved.');
  elsif action='MERGE' then
   select * into target from public.students where id=tid;
   if target.id is null or target.id=s.id or target.organization_id<>s.organization_id or target.merged_into_id is not null or target.status='ARCHIVED' then raise exception 'Select a different canonical student in this organization.';end if;
   if exists(select 1 from public.students where merged_into_id=s.id) then raise exception 'A canonical identity with linked duplicates cannot be merged again.';end if;
   if exists(select 1 from public.enrollments where student_id=s.id and status='ACTIVE') or exists(select 1 from public.admission_cases where student_id=s.id and status<>'CANCELLED') then raise exception 'Resolve the duplicate identity’s open admissions and enrollments before merging.';end if;
   if lower(btrim(s.full_name))<>lower(btrim(target.full_name)) and not exists(
    select 1 from public.student_guardians x join public.guardians gx on gx.id=x.guardian_id cross join public.student_guardians y join public.guardians gy on gy.id=y.guardian_id
    where x.student_id=s.id and y.student_id=target.id and gx.mobile=gy.mobile) then raise exception 'No matching name or guardian mobile. Verify the identities before requesting a merge.';end if;
   if p_input->>'confirmed_same_person' is distinct from 'true' then raise exception 'Confirm these identities belong to the same student.'; end if;
    insert into public.student_merges(source_id,target_id,authorized_by,authorization_reason,source_snapshot,target_snapshot) values(s.id,target.id,actor,reason,to_jsonb(s),to_jsonb(target));
    update public.students set merged_into_id=target.id,status='ARCHIVED' where id=s.id;
    -- History and guardian links retain their original IDs and appear in the canonical profile.
   result:=jsonb_build_object('id',target.id,'message','Duplicate archived; original records and academic history preserved.');
  end if;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data,metadata)
 values(req,actor,'STUDENT',s.id::text,action,reason,to_jsonb(s),result,p_input);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,actor,p_input,result);
 return result;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.student_profile_workspace(p_student_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s public.students;canonical uuid;ids uuid[];can_finance boolean:=public.has_permission('finance.view');result jsonb;
begin
 if auth.uid() is null or not public.has_permission('students.view') then raise exception 'Student access required.';end if;
 select * into s from public.students where id=p_student_id;
 if s.id is null then return null;end if;
 canonical:=coalesce(s.merged_into_id,s.id);
 select array_agg(id) into ids from public.students where id=canonical or merged_into_id=canonical;
 select jsonb_build_object(
 'student',jsonb_build_object('id',s.id,'number',s.student_no,'name',s.full_name,'nameBn',s.name_bn,'status',s.status,'birthDate',s.date_of_birth,'school',coalesce((select name from public.schools where id=s.school_id),s.school_name_snapshot),'createdAt',s.created_at,'canonicalId',canonical,'canonicalNumber',(select student_no from public.students where id=canonical)),
 'identities',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',full_name,'number',student_no)) from public.students where id=any(ids)),'[]'::jsonb),
 'guardians',coalesce((select jsonb_agg(jsonb_build_object('id',sg.id,'studentId',sg.student_id,'name',g.full_name,'mobile',g.mobile,'alternateMobile',g.alternate_mobile,'relationship',sg.relationship_snapshot,'primary',sg.is_primary)) from public.student_guardians sg join public.guardians g on g.id=sg.guardian_id where sg.student_id=any(ids)),'[]'::jsonb),
 'enrollments',coalesce((select jsonb_agg(jsonb_build_object('id',e.id,'studentId',e.student_id,'year',y.name,'class',c.name,'batch',b.name,'status',e.status,'startsOn',e.admission_date,'endsOn',e.ended_on) order by e.created_at desc) from public.enrollments e join public.academic_years y on y.id=e.academic_year_id join public.classes c on c.id=e.class_id left join public.batches b on b.id=e.batch_id where e.student_id=any(ids)),'[]'::jsonb),
 'admissions',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'number',a.admission_no,'studentId',a.student_id,'batchId',a.batch_id,'offeringId',b.offering_id,'batch',b.name,'status',a.status,'createdAt',a.created_at,'feeVersion',f.version) order by a.created_at desc) from public.admission_cases a join public.batches b on b.id=a.batch_id left join (SELECT NULL::uuid AS "id", NULL::uuid AS "offering_id", NULL::integer AS "version", NULL::rule_status AS "status", NULL::text AS "billing_cycle", NULL::integer AS "due_day", NULL::text AS "currency_code", NULL::date AS "effective_from", NULL::date AS "effective_to", NULL::text AS "change_reason", NULL::uuid AS "created_by", NULL::timestamp with time zone AS "created_at" WHERE false) f on f.id=null::uuid where a.student_id=any(ids)),'[]'::jsonb),
 'batches',coalesce((select jsonb_agg(jsonb_build_object('id',b.id,'name',b.name,'offeringId',b.offering_id,'offering',o.name,'year',y.name,'class',c.name,'capacity',least(b.capacity,(select (payload->>'max_students')::integer from public.business_rule_versions where domain='academics' and rule_key='batch_capacity_policy' and status='ACTIVE')),'occupied',(select count(*) from public.enrollments where batch_id=b.id and status='ACTIVE'))) from public.batches b join public.programme_offerings o on o.id=b.offering_id join public.academic_years y on y.id=b.academic_year_id join public.classes c on c.id=b.class_id where b.organization_id=s.organization_id and b.is_active and o.status='ACTIVE'),'[]'::jsonb),
 'invoices','[]'::jsonb,
 'financeVisible',false,
 'transfers',coalesce((select jsonb_agg(jsonb_build_object('id',t.id,'fromBatch',b.name,'toBatch',d.name,'date',t.transferred_on,'authorizedBy',t.authorized_by) order by t.created_at desc) from public.enrollment_transfers t join public.batches b on b.id=t.from_batch_id join public.batches d on d.id=t.to_batch_id where t.student_id=any(ids)),'[]'::jsonb),
 'candidates',case when public.has_permission('students.manage') then coalesce((select jsonb_agg(jsonb_build_object('id',t.id,'name',t.full_name,'number',t.student_no,'status',t.status,'birthDate',t.date_of_birth,'school',t.school_name_snapshot,'mobile',(select g.mobile from public.student_guardians sg join public.guardians g on g.id=sg.guardian_id where sg.student_id=t.id and sg.is_primary))) from public.students t where t.id<>s.id and t.organization_id=s.organization_id and t.merged_into_id is null and t.status<>'ARCHIVED' and (lower(btrim(t.full_name))=lower(btrim(s.full_name)) or exists(select 1 from public.student_guardians x join public.guardians gx on gx.id=x.guardian_id cross join public.student_guardians z join public.guardians gz on gz.id=z.guardian_id where x.student_id=s.id and z.student_id=t.id and gx.mobile=gz.mobile))),'[]'::jsonb) else '[]'::jsonb end
 ) into result;
 return result;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.sync_admission_student_details()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.student_id is not null and old.student_id is null then
    update public.students set
      name_bn=nullif(new.identity_snapshot->>'student_name_bn',''),
      gender=nullif(new.identity_snapshot->>'gender',''),
      date_of_birth=nullif(new.identity_snapshot->>'date_of_birth','')::date,
      school_roll=nullif(new.identity_snapshot->>'school_roll','')
    where id=new.student_id;
    update public.guardians g set
      alternate_mobile=coalesce(g.alternate_mobile,nullif(new.identity_snapshot->>'alternate_mobile','')),
      address=coalesce(g.address,nullif(new.identity_snapshot->>'guardian_address',''))
    from public.student_guardians sg where sg.student_id=new.student_id and sg.guardian_id=g.id;
  end if;
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.sync_student_optional_contact()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ begin
 if new.student_id is not null and not new.existing_student then
  update public.students set mobile=nullif(new.identity_snapshot->>'student_mobile',''),email=nullif(new.identity_snapshot->>'student_email','') where id=new.student_id;
 end if; return new;
end; $function$
;

set check_function_bodies=true;
