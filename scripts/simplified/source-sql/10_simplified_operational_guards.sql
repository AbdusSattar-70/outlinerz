set search_path=public,extensions;
-- Internal staff lookup can resolve an existing verified account, without granting API clients auth table access.
grant select on auth.users to academy_executor;
create or replace function public.save_academy_identity(p_input jsonb) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
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
end $$;
revoke all on function public.save_academy_identity(jsonb) from public,anon;
grant execute on function public.save_academy_identity(jsonb) to authenticated;
-- Keep the approved attendance command; compensation is outside this version.
alter function public.workforce_command(jsonb) rename to legacy_attendance_command;
revoke execute on function public.legacy_attendance_command(jsonb) from authenticated,anon,public;
create function public.workforce_command(p_input jsonb) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$ begin
 if p_input->>'action' is distinct from 'RECORD_ATTENDANCE' then raise exception 'Only attendance is available in this version.';end if;
 return public.legacy_attendance_command(p_input);
end $$;
alter function public.workforce_command(jsonb) owner to academy_executor;
revoke execute on function public.workforce_command(jsonb) from public,anon;
grant execute on function public.workforce_command(jsonb) to authenticated;
-- Avoid changing a shared login's status when a branch retires a staff record.
-- Shared role templates remain immutable; membership controls branch access.
create function public.remove_branch_member(p_email text) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare branch uuid:=academy_private.current_branch_id();target uuid;begin
 if branch is null or not public.has_permission('system.users.manage') then raise exception 'Branch user management permission required.';end if;
 select u.id into target from auth.users u join public.branch_memberships m on m.user_id=u.id and m.branch_id=branch where lower(u.email)=lower(btrim(p_email));
 if target is null then raise exception 'This person is not a member of this branch.';end if;
 if target=auth.uid() or exists(select 1 from public.branch_owners o join public.branches b on b.organization_id=o.organization_id where b.id=branch and o.user_id=target) then raise exception 'The owner and your own active membership cannot be removed.';end if;
 update public.branch_memberships set is_active=false where user_id=target and branch_id=branch;
 update public.user_role_assignments set is_active=false,effective_to=current_date where profile_id=target and scope_branch_id=branch;
 insert into public.audit_events(actor_profile_id,branch_id,entity_type,entity_id,action,reason) values(auth.uid(),branch,'USER',target::text,'REMOVE_BRANCH_MEMBER','Access removed from this branch only.');return jsonb_build_object('id',target);
end $$;
revoke all on function public.remove_branch_member(text) from public,anon;
grant execute on function public.remove_branch_member(text) to authenticated;
reset search_path;
update public.system_roles set is_active=false where code not in('ADMIN','ACADEMIC_DIRECTOR','OPERATOR','TEACHER');
update public.system_roles set description='Admissions, CRM and routine academic operations.' where code='OPERATOR';
delete from public.permissions where code ~ '^(finance|accounting|compensation|referrals)\.';
alter function public.save_academy_identity(jsonb) owner to postgres;
alter function public.submit_public_interest(jsonb) owner to postgres;

set search_path=public,extensions;
CREATE OR REPLACE FUNCTION public.student_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 actor uuid:=auth.uid();req uuid:=(p_input->>'request_id')::uuid;action text:=p_input->>'action';reason text:=btrim(coalesce(p_input->>'reason',''));
 key public.admission_command_keys;s public.students;target public.students;a public.admission_cases;b public.batches;dest public.batches;
 fee public.fee_plan_versions;guardian record;policy public.business_rule_versions;e public.enrollments;
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
   insert into public.admission_cases(batch_id,fee_plan_version_id,student_id,existing_student,identity_snapshot,created_by,origin,consent_required)
   values(b.id,fee.id,s.id,true,jsonb_build_object('student_name',s.full_name,'guardian_name',guardian.full_name,'mobile',guardian.mobile,'guardian_relationship',coalesce(guardian.relationship_snapshot,'Guardian'),'school_id',s.school_id,'school_name',s.school_name_snapshot),actor,'EXISTING_STUDENT',false) returning id into aid;
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
$function$;
alter function public.student_command(jsonb) owner to academy_executor;
reset search_path;

set search_path=public,extensions;
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
$function$;
alter function public.create_staff_member(jsonb) owner to academy_executor;
grant execute on function public.create_staff_member(jsonb) to authenticated;
reset search_path;
update public.staff_roles set is_active=false where code='ACCOUNTANT';

delete from public.role_permissions where permission_id in(select id from public.permissions where code like '%compensation%' or code like '%payroll%');
delete from public.permissions where code like '%compensation%' or code like '%payroll%';

set search_path=public,extensions;
CREATE OR REPLACE FUNCTION public.admission_case_detail(p_admission_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  result jsonb; charges jsonb; extras jsonb;
begin
  if auth.uid() is null or not public.has_permission('admissions.view') then
    raise exception 'Admission workspace access denied.';
  end if;

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
    'feeVersion', f.version,
    'feePlanId', f.id,
    'policyVersion', r.version,
    'paymentRequirement', r.payload->>'payment_requirement',
    'components', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'name', fc.name,
          'amount', fc.amount,
          'recurrence', fc.recurrence
        )
        order by fc.sort_order, fc.id
      )
      from public.fee_plan_components fc
      where fc.fee_plan_version_id = f.id
    ), '[]'::jsonb),
    'invoice', case
      when i.id is null then null
      else jsonb_build_object(
        'id', i.id, 'number', i.invoice_no,
        'total', i.total,
        'dueOn', i.due_on,
        'paid', bal.paid,
        'credits', bal.credits,
        'net', bal.net,
        'refunded', bal.refunded,
        'due', bal.due,
        'credit', bal.credit_balance
      )
    end,
    'receipts', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'number', p.receipt_no,
          'amount', pa.amount,
          'postedAt', p.posted_at,
          'method', pm.name,
          'refunded', coalesce((
            select sum(ra.amount)
            from public.refund_authorizations ra
            join public.refund_payouts rp
              on rp.authorization_id = ra.id
            where ra.payment_id = p.id
          ), 0)
        )
        order by p.posted_at, p.receipt_no
      )
      from public.admission_payment_allocations pa
      join public.admission_payments p
        on p.id = pa.payment_id
      join public.payment_methods pm
        on pm.id = p.payment_method_id
      where pa.invoice_id = i.id
    ), '[]'::jsonb)
  )
  into result
  from public.admission_cases a
  left join public.fee_plan_versions f
    on f.id = a.fee_plan_version_id
  join public.batches b
    on b.id = a.batch_id
  join public.programme_offerings o
    on o.id = b.offering_id
  join public.classes cl
    on cl.id = b.class_id
  join public.academic_years ay
    on ay.id = b.academic_year_id
  left join public.branches br
    on br.id = b.branch_id
  left join public.students s
    on s.id = a.student_id
  left join public.business_rule_versions r
    on r.id = a.activation_policy_version_id
  left join public.admission_invoices i
    on i.admission_id = a.id
   and i.invoice_kind = 'INITIAL'
  left join lateral public.invoice_balance(i.id) bal
    on true
  where a.id = p_admission_id;

  if result is null then
    raise exception 'Admission Case not found.';
  end if;

  result:=result||(select jsonb_build_object('academyRoll',s.academy_roll::text,'discountPercent',a.selected_discount_percent,'discountReason',a.discount_reason,'additionalDetails',
 jsonb_build_object('student_mobile',a.identity_snapshot->>'student_mobile','student_email',a.identity_snapshot->>'student_email','present_landmark',a.identity_snapshot->>'present_landmark','permanent_same_as_present',a.identity_snapshot->>'permanent_same_as_present','father_name',a.identity_snapshot->>'father_name','mother_name',a.identity_snapshot->>'mother_name',
 'birth_registration',a.identity_snapshot->>'birth_registration','permanent_address',a.identity_snapshot->>'permanent_address',
 'emergency_contact',a.identity_snapshot->>'emergency_contact','emergency_mobile',a.identity_snapshot->>'emergency_mobile',
 'previous_result',a.identity_snapshot->>'previous_result','learning_needs',a.identity_snapshot->>'learning_needs'))
 from public.admission_cases a left join public.students s on s.id=a.student_id where a.id=p_admission_id);

 select additional_charges into charges from public.admission_cases where id=p_admission_id;
 select coalesce(jsonb_agg(jsonb_build_object('name',value->>'name','amount',(value->>'amount')::numeric,'recurrence','ONE_TIME')),'[]') into extras from jsonb_array_elements(charges) where (value->>'is_active')::boolean;
 return result||jsonb_build_object('tuitionTotal',(select coalesce(sum(c.amount),0) from public.fee_plan_components c join public.admission_cases a on a.fee_plan_version_id=c.fee_plan_version_id where a.id=p_admission_id and c.charge_type='TUITION'),'additionalCharges',charges,'components',(result->'components')||extras);
end;
$function$;
alter function public.admission_case_detail(uuid) owner to academy_executor;
reset search_path;
