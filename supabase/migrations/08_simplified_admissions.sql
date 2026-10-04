set search_path=academy,extensions,public;
alter table academy.admission_cases alter column fee_plan_version_id drop not null,alter column consent_required set default false;
drop trigger if exists admission_referral_choice_gate on academy.admission_cases;
drop trigger if exists admission_workflow_evidence_gate on academy.admission_cases;
create or replace function academy.admission_command(p_input jsonb) returns jsonb language plpgsql security definer set search_path=pg_catalog,academy as $$
declare actor uuid:=auth.uid();req uuid:=nullif(p_input->>'request_id','')::uuid;action text:=p_input->>'action';a academy.admission_cases;b academy.batches;o academy.programme_offerings;p academy.prospects;k academy.admission_command_keys;student uuid;guardian uuid;enrollment uuid;result jsonb; begin
 if actor is null or not academy.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if req is null or length(btrim(coalesce(p_input->>'reason','')))<5 then raise exception 'A request identity and a verification note are required.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));select * into k from academy.admission_command_keys where request_id=req;
 if found then if k.actor_id<>actor or k.payload<>p_input then raise exception 'Request identity already used.'; end if; return k.result; end if;
 if action='CREATE' then
  select * into p from academy.prospects where id=(p_input->>'prospect_id')::uuid for update;
  select * into b from academy.batches where id=(p_input->>'batch_id')::uuid and is_active for update;
  select * into o from academy.programme_offerings where id=b.offering_id and status='ACTIVE';
  if p.id is null or p.status in('LOST','CONVERTED') or o.id is null or o.id is distinct from(p_input->>'offering_id')::uuid or(p.current_class_id is not null and p.current_class_id<>o.class_id) then raise exception 'Choose an open enquiry and its matching active offering and batch.'; end if;
  if exists(select 1 from academy.admission_cases where prospect_id=p.id and status<>'CANCELLED') then raise exception 'This enquiry already has an admission case.'; end if;
  if(select count(*) from academy.enrollments where batch_id=b.id and status='ACTIVE')>=b.capacity then raise exception 'Selected batch is full.'; end if;
  insert into academy.admission_cases(prospect_id,batch_id,identity_snapshot,created_by,consent_required,origin_prospect_id,origin)
   values(p.id,b.id,coalesce(p.application_snapshot,'{}'::jsonb)||jsonb_build_object('student_name',p.student_name,'student_name_bn',p.student_name_bn,'guardian_name',p.guardian_name,'mobile',p.mobile,'guardian_relationship',coalesce(p.guardian_relationship_snapshot,'Guardian'),'school_id',p.school_id,'school_name',p.school_name_snapshot,'gender',p.gender,'date_of_birth',p.date_of_birth,'guardian_address',p.guardian_address),actor,false,p.id,case when p.submitted_via='PUBLIC_WEB' then 'PUBLIC_APPLICATION' else 'PROSPECT_CONVERSION' end) returning * into a;
 else
  select * into a from academy.admission_cases where id=(p_input->>'admission_id')::uuid for update;
  if a.id is null then raise exception 'Admission case is unavailable in this branch.'; end if;
  select * into b from academy.batches where id=a.batch_id and is_active for update;
  select * into o from academy.programme_offerings where id=b.offering_id and status='ACTIVE';
  if o.id is null then raise exception 'Choose an active academic placement.'; end if;
  if action='EDIT_DRAFT' and a.status in('DRAFT','READY') then
   if length(btrim(coalesce(p_input->>'student_name','')))<2 or length(btrim(coalesce(p_input->>'guardian_name','')))<2 or coalesce(p_input->>'mobile','')!~'^01[3-9][0-9]{8}$' then raise exception 'Enter valid student, guardian and mobile details.'; end if;
   update academy.admission_cases set identity_snapshot=identity_snapshot||jsonb_build_object('student_name',btrim(p_input->>'student_name'),'guardian_name',btrim(p_input->>'guardian_name'),'mobile',p_input->>'mobile'),status='DRAFT' where id=a.id;
  elsif action='READY' and a.status='DRAFT' then
   if length(btrim(coalesce(a.identity_snapshot->>'student_name','')))<2 or length(btrim(coalesce(a.identity_snapshot->>'guardian_name','')))<2 or coalesce(a.identity_snapshot->>'mobile','')!~'^01[3-9][0-9]{8}$' then raise exception 'Verify student and guardian details first.'; end if;
   update academy.admission_cases set status='READY' where id=a.id;
  elsif action='RETURN_TO_DRAFT' and a.status='READY' then update academy.admission_cases set status='DRAFT' where id=a.id;
  elsif action in('FINALIZE','ACCEPT','ACTIVATE') and a.status='READY' then
   if(select count(*) from academy.enrollments where batch_id=b.id and status='ACTIVE')>=b.capacity then raise exception 'Selected batch is full.'; end if;
   if a.existing_student then
    student:=a.student_id;
    if not exists(select 1 from academy.students where id=student and status='ACTIVE' and merged_into_id is null) or exists(select 1 from academy.enrollments where student_id=student and academic_year_id=b.academic_year_id and status='ACTIVE') then raise exception 'Existing student is unavailable or already enrolled in this academic year.';end if;
   else
   select * into p from academy.prospects where id=a.prospect_id for update;
   if p.id is null or p.status in('CONVERTED','LOST') then raise exception 'Enquiry is no longer eligible.'; end if;
   if exists(select 1 from academy.students s join academy.student_guardians sg on sg.student_id=s.id join academy.guardians g on g.id=sg.guardian_id where lower(s.full_name)=lower(a.identity_snapshot->>'student_name') and g.mobile=a.identity_snapshot->>'mobile') then raise exception 'A matching student already exists. Review the existing identity before continuing.'; end if;
   insert into academy.students(organization_id,branch_id,full_name,name_bn,gender,date_of_birth,created_from_prospect_id,created_by) values(b.organization_id,b.branch_id,a.identity_snapshot->>'student_name',a.identity_snapshot->>'student_name_bn',a.identity_snapshot->>'gender',nullif(a.identity_snapshot->>'date_of_birth','')::date,p.id,actor) returning id into student;
   insert into academy.guardians(organization_id,full_name,mobile,address,created_by) values(b.organization_id,a.identity_snapshot->>'guardian_name',a.identity_snapshot->>'mobile',a.identity_snapshot->>'guardian_address',actor) returning id into guardian;
   insert into academy.student_guardians(student_id,guardian_id,relationship_snapshot,is_primary) values(student,guardian,a.identity_snapshot->>'guardian_relationship',true);
   end if;
   insert into academy.enrollments(student_id,organization_id,branch_id,academic_year_id,class_id,program_id,batch_id,created_by) values(student,b.organization_id,b.branch_id,b.academic_year_id,b.class_id,b.program_id,b.id,actor) returning id into enrollment;
   update academy.admission_cases set student_id=student,enrollment_id=enrollment,capacity_policy_version_id=b.capacity_policy_version_id,status='ACTIVE_ENROLLMENT' where id=a.id;
   update academy.prospects set status='CONVERTED',converted_student_id=student,converted_at=now() where id=p.id;
  else raise exception 'This action is unavailable at the current admission stage.'; end if;
 end if;
 select jsonb_build_object('id',id,'status',status) into result from academy.admission_cases where id=a.id;
 insert into academy.audit_events(correlation_id,actor_profile_id,branch_id,entity_type,entity_id,action,reason,after_data) values(req,actor,academy_private.current_branch_id(),'ADMISSION',a.id::text,action,p_input->>'reason',result);
 insert into academy.admission_command_keys(request_id,actor_id,payload,result) values(req,actor,p_input,result);return result;
end $$;
alter function academy.admission_command(jsonb) owner to academy_executor;
-- The old stage dispatcher cannot bypass the new academic-only state machine.
revoke execute on function academy.execute_admission_stage(jsonb) from authenticated,anon,public;
create or replace function academy.academy_setup_status() returns jsonb language sql stable security definer set search_path=pg_catalog,academy as $$
 select jsonb_build_object('completed',true,'ready',true,'academyName',o.name,'steps',jsonb_build_array(jsonb_build_object('id','directory','title','Review classes, subjects and programmes','href','/dashboard/crm/manage','done',exists(select 1 from academy.classes)),jsonb_build_object('id','offering','title','Review programme offerings and public intake','href','/dashboard/academics/offerings','done',exists(select 1 from academy.programme_offerings)),jsonb_build_object('id','batches','title','Review batch capacity','href','/dashboard/academics/batches','done',exists(select 1 from academy.batches)))) from academy.organizations o where academy.has_permission('dashboard.view');
$$;
alter function academy.academy_setup_status() owner to academy_executor;
reset search_path;

set search_path=academy,extensions,public;
CREATE OR REPLACE FUNCTION academy.admission_workspace()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'academy'
AS $function$
declare v_view boolean:=academy.has_permission('admissions.view'); v_result jsonb;
begin
 if auth.uid() is null or not (v_view or academy.has_permission('academics.view')) then raise exception 'Workspace access denied.'; end if;
 select jsonb_build_object(
  'offerings',coalesce((select jsonb_agg(jsonb_build_object('id',o.id,'name',o.name,'code',o.code,
      'classId',o.class_id,'className',c.name,'yearName',ay.name,'branchName',br.name))
    from academy.programme_offerings o join academy.classes c on c.id=o.class_id
    join academy.academic_years ay on ay.id=o.academic_year_id left join academy.branches br on br.id=o.branch_id
    join academy.organizations org on org.id=o.organization_id
    where o.status='ACTIVE' ),'[]'::jsonb),
  'capacityLimit',(select (payload->>'max_students')::integer from academy.business_rule_versions where domain='academics' and rule_key='batch_capacity_policy' and status='ACTIVE'),
  'batches',coalesce((select jsonb_agg(jsonb_build_object(
    'id',b.id,'name',b.name,'code',b.code,'offeringId',b.offering_id,
    'offeringName',o.name,'classId',b.class_id,'className',c.name,
    'yearName',y.name,'branchName',br.name,'capacity',b.capacity,
    'isActive',b.is_active,
    'occupied',(select count(*) from academy.enrollments e where e.batch_id=b.id and e.status='ACTIVE')
  ) order by y.starts_on desc,o.name,b.name)
    from academy.batches b
    join academy.programme_offerings o on o.id=b.offering_id
    join academy.classes c on c.id=b.class_id
    join academy.academic_years y on y.id=b.academic_year_id
    left join academy.branches br on br.id=b.branch_id
  ),'[]'::jsonb),
  'prospects',case when v_view then coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'name',p.student_name,'number',p.prospect_no,'classId',p.current_class_id,'interestedOfferingId',p.interested_offering_id,'guardian',p.guardian_name,'mobile',p.mobile)) from academy.prospects p where p.status not in ('CONVERTED','LOST') and not exists(select 1 from academy.admission_cases a where a.prospect_id=p.id and a.status<>'CANCELLED')),'[]'::jsonb) else '[]'::jsonb end,
  'cases',case when v_view then coalesce((select jsonb_agg(x order by x->>'createdAt' desc) from (
    select jsonb_build_object('id',a.id,'number',a.admission_no,'status',a.status,'createdAt',a.created_at,
      'existingStudent',a.existing_student,'batchId',a.batch_id,'studentNo',s.student_no,'studentId',s.id,'name',a.identity_snapshot->>'student_name','nameBn',a.identity_snapshot->>'student_name_bn',
      'gender',a.identity_snapshot->>'gender','dateOfBirth',a.identity_snapshot->>'date_of_birth',
      'schoolName',a.identity_snapshot->>'school_name','schoolRoll',a.identity_snapshot->>'school_roll',
      'guardianAddress',a.identity_snapshot->>'guardian_address','alternateMobile',a.identity_snapshot->>'alternate_mobile',
      'guardianRelationship',a.identity_snapshot->>'guardian_relationship',
      'guardian',a.identity_snapshot->>'guardian_name','mobile',a.identity_snapshot->>'mobile',
      'feeVersion',f.version,'feePlanId',f.id,'policyVersion',r.version,'paymentRequirement',r.payload->>'payment_requirement',
      'components',coalesce((select jsonb_agg(jsonb_build_object('name',fc.name,'amount',fc.amount,'recurrence',fc.recurrence)) from academy.fee_plan_components fc where fc.fee_plan_version_id=f.id),'[]'::jsonb),
      'invoice',case when i.id is null then null else jsonb_build_object('number',i.invoice_no,'total',i.total,'dueOn',i.due_on,'paid',bal.paid,'credits',bal.credits,'net',bal.net,'refunded',bal.refunded,'due',bal.due,'credit',bal.credit_balance) end,
      'receipts',coalesce((select jsonb_agg(jsonb_build_object('number',p.receipt_no,'amount',pa.amount,'postedAt',p.posted_at,'method',pm.name,'refunded',coalesce((select sum(ra.amount) from academy.refund_authorizations ra join academy.refund_payouts rp on rp.authorization_id=ra.id where ra.payment_id=p.id),0))) from academy.admission_payment_allocations pa join academy.admission_payments p on p.id=pa.payment_id join academy.payment_methods pm on pm.id=p.payment_method_id where pa.invoice_id=i.id),'[]'::jsonb)
    ) as x
    from academy.admission_cases a left join academy.fee_plan_versions f on f.id=a.fee_plan_version_id
    left join academy.students s on s.id=a.student_id left join academy.business_rule_versions r on r.id=a.activation_policy_version_id
    left join academy.admission_invoices i on i.admission_id=a.id and i.invoice_kind='INITIAL'
    left join lateral academy.invoice_balance(i.id) bal on true
  ) rows),'[]'::jsonb) else '[]'::jsonb end,
  'paymentMethods',case when academy.has_permission('finance.payments.post') then coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name)) from academy.payment_methods where is_active),'[]'::jsonb) else '[]'::jsonb end
 ) into v_result;
 return v_result;
end; $function$;
alter function academy.admission_workspace() owner to academy_executor;
CREATE OR REPLACE FUNCTION academy.admission_offering_options()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'academy'
AS $function$
  select case
    when auth.uid() is null or not academy.has_permission('admissions.view')
      then '[]'::jsonb
    else coalesce((
      select jsonb_agg(jsonb_build_object(
        'id',o.id,'name',o.name,'code',o.code,
        'classId',o.class_id,'className',c.name,
        'yearName',ay.name,'branchName',br.name,
        'feeReady',true
      ) order by ay.starts_on desc,o.name)
      from academy.programme_offerings o
      join academy.classes c on c.id=o.class_id
      join academy.academic_years ay on ay.id=o.academic_year_id
      join academy.organizations org on org.id=o.organization_id
      left join academy.branches br on br.id=o.branch_id
      where o.status='ACTIVE'
    ),'[]'::jsonb)
  end;
$function$;
alter function academy.admission_offering_options() owner to academy_executor;
CREATE OR REPLACE FUNCTION academy.admission_case_detail(p_admission_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'academy'
AS $function$
declare
  result jsonb; charges jsonb; extras jsonb;
begin
  if auth.uid() is null or not academy.has_permission('admissions.view') then
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
      from academy.enrollments e
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
      from academy.fee_plan_components fc
      where fc.fee_plan_version_id = f.id
    ), '[]'::jsonb),
    'invoice', case
      when i.id is null then null
      else jsonb_build_object(
        'number', i.invoice_no,
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
            from academy.refund_authorizations ra
            join academy.refund_payouts rp
              on rp.authorization_id = ra.id
            where ra.payment_id = p.id
          ), 0)
        )
        order by p.posted_at, p.receipt_no
      )
      from academy.admission_payment_allocations pa
      join academy.admission_payments p
        on p.id = pa.payment_id
      join academy.payment_methods pm
        on pm.id = p.payment_method_id
      where pa.invoice_id = i.id
    ), '[]'::jsonb)
  )
  into result
  from academy.admission_cases a
  left join academy.fee_plan_versions f
    on f.id = a.fee_plan_version_id
  join academy.batches b
    on b.id = a.batch_id
  join academy.programme_offerings o
    on o.id = b.offering_id
  join academy.classes cl
    on cl.id = b.class_id
  join academy.academic_years ay
    on ay.id = b.academic_year_id
  left join academy.branches br
    on br.id = b.branch_id
  left join academy.students s
    on s.id = a.student_id
  left join academy.business_rule_versions r
    on r.id = a.activation_policy_version_id
  left join academy.admission_invoices i
    on i.admission_id = a.id
   and i.invoice_kind = 'INITIAL'
  left join lateral academy.invoice_balance(i.id) bal
    on true
  where a.id = p_admission_id;

  if result is null then
    raise exception 'Admission Case not found.';
  end if;

  result:=result||(select jsonb_build_object('academyRoll',s.academy_roll::text,'discountPercent',a.selected_discount_percent,'discountReason',a.discount_reason,'additionalDetails',
 jsonb_build_object('father_name',a.identity_snapshot->>'father_name','mother_name',a.identity_snapshot->>'mother_name',
 'birth_registration',a.identity_snapshot->>'birth_registration','permanent_address',a.identity_snapshot->>'permanent_address',
 'emergency_contact',a.identity_snapshot->>'emergency_contact','emergency_mobile',a.identity_snapshot->>'emergency_mobile',
 'previous_result',a.identity_snapshot->>'previous_result','learning_needs',a.identity_snapshot->>'learning_needs'))
 from academy.admission_cases a left join academy.students s on s.id=a.student_id where a.id=p_admission_id);

 select additional_charges into charges from academy.admission_cases where id=p_admission_id;
 select coalesce(jsonb_agg(jsonb_build_object('name',value->>'name','amount',(value->>'amount')::numeric,'recurrence','ONE_TIME')),'[]') into extras from jsonb_array_elements(charges) where (value->>'is_active')::boolean;
 return result||jsonb_build_object('tuitionTotal',(select coalesce(sum(c.amount),0) from academy.fee_plan_components c join academy.admission_cases a on a.fee_plan_version_id=c.fee_plan_version_id where a.id=p_admission_id and c.charge_type='TUITION'),'additionalCharges',charges,'components',(result->'components')||extras);
end;
$function$;
alter function academy.admission_case_detail (uuid) owner to academy_executor;
reset search_path;
set search_path=academy,extensions,public;
create or replace function academy.create_staff_admission_intake(p_input jsonb) returns jsonb language plpgsql security definer set search_path=pg_catalog,academy as $$
declare actor uuid:=auth.uid();req uuid:=nullif(p_input->>'request_id','')::uuid;old academy.staff_admission_intake_requests;prospect uuid;offering academy.programme_offerings;result jsonb; begin
 if actor is null or not academy.has_permission('admissions.create') then raise exception 'Admission permission required.'; end if;
 if req is null or octet_length(p_input::text)>16000 or length(btrim(coalesce(p_input->>'reason','')))<5 or length(btrim(coalesce(p_input->>'student_name','')))<2 or length(btrim(coalesce(p_input->>'guardian_name','')))<2 or coalesce(p_input->>'mobile','')!~'^01[3-9][0-9]{8}$' or not coalesce((p_input->>'consent_to_contact')::boolean,false) then raise exception 'Enter verified student, guardian, mobile and contact consent details.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));select * into old from academy.staff_admission_intake_requests where request_id=req;
 if found then if old.actor_id<>actor or old.payload<>p_input then raise exception 'Request already used for different input.';end if;return jsonb_build_object('admission_id',old.admission_id);end if;
 select * into offering from academy.programme_offerings where id=(p_input->>'offering_id')::uuid and status='ACTIVE';
 if offering.id is null then raise exception 'Choose an active programme offering.';end if;
 insert into academy.prospects(organization_id,branch_id,student_name,student_name_bn,guardian_name,mobile,current_class_id,interested_offering_id,guardian_address,guardian_relationship_snapshot,date_of_birth,gender,school_name_snapshot,school_roll,alternate_mobile,consent_to_contact,submitted_via,application_snapshot)
 values(offering.organization_id,offering.branch_id,btrim(p_input->>'student_name'),nullif(p_input->>'student_name_bn',''),btrim(p_input->>'guardian_name'),p_input->>'mobile',offering.class_id,offering.id,nullif(p_input->>'guardian_address',''),p_input->>'guardian_relationship',nullif(p_input->>'date_of_birth','')::date,nullif(p_input->>'gender',''),nullif(p_input->>'school_name',''),nullif(p_input->>'school_roll',''),nullif(p_input->>'alternate_mobile',''),true,'STAFF_INTAKE',p_input) returning id into prospect;
 result:=academy.admission_command(jsonb_build_object('request_id',req,'action','CREATE','prospect_id',prospect,'batch_id',p_input->>'batch_id','offering_id',offering.id,'reason',p_input->>'reason'));
 update academy.admission_cases set origin='DIRECT_STAFF',origin_prospect_id=null where id=(result->>'id')::uuid;
 insert into academy.staff_admission_intake_requests(request_id,actor_id,payload,prospect_id,admission_id) values(req,actor,p_input,prospect,(result->>'id')::uuid);
 return jsonb_build_object('admission_id',result->>'id','admission_no',(select admission_no from academy.admission_cases where id=(result->>'id')::uuid));
end $$;
alter function academy.create_staff_admission_intake(jsonb) owner to academy_executor;
-- Global account state must not change when one branch retires a staff placement.
