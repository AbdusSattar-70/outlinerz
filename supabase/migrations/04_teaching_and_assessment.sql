set check_function_bodies=false;
CREATE OR REPLACE FUNCTION public.academic_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 actor uuid:=auth.uid();req uuid:=(p_input->>'request_id')::uuid;action text:=p_input->>'action';reason text:=btrim(coalesce(p_input->>'reason',''));key public.admission_command_keys;
 b public.batches;room public.academic_rooms;r public.academic_routines;cs public.class_sessions;cv public.curriculum_versions;teacher public.staff;year public.academic_years;
 att public.attendance_submissions;last_att public.attendance_submissions;approval public.approval_requests;
 sid uuid;rid uuid;bid uuid;subid uuid;tid uuid;roomid uuid;date_from date;date_to date;day date;st time;et time;tz text;start_at timestamptz;end_at timestamptz;
 rows jsonb;roster jsonb;entry jsonb;unit jsonb;result jsonb;created integer:=0;permission text;scope text;id_out uuid;
begin
 if actor is null or not public.has_permission('academics.view') then raise exception 'Academic access required.';end if;
 if req is null or length(reason)<5 or length(reason)>500 then raise exception 'A request identity and reason of 5–500 characters are required.';end if;
 permission:=case action when 'CREATE_ROOM' then 'academics.sessions.manage' when 'PUBLISH_CURRICULUM' then 'academics.curriculum.manage' when 'CREATE_ROUTINE' then 'academics.sessions.manage' when 'RETIRE_ROUTINE' then 'academics.sessions.manage' when 'GENERATE_SESSIONS' then 'academics.sessions.manage' when 'CREATE_SESSION' then 'academics.sessions.manage' when 'CANCEL_SESSION' then 'academics.sessions.manage' when 'SAVE_ATTENDANCE' then 'academics.attendance.record' when 'SUBMIT_ATTENDANCE' then 'academics.attendance.record' when 'DECIDE_ATTENDANCE' then 'academics.attendance.approve' else null end;
 if permission is null or not public.has_permission(permission) then raise exception 'Permission denied for this academic action.';end if;
 perform pg_advisory_xact_lock(hashtextextended(req::text,0));
 select * into key from public.admission_command_keys where request_id=req;
 if found then if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity already used for different input.';end if;return key.result;end if;
 -- Serialize schedule conflict checks and attendance/session-state transitions.
 perform pg_advisory_xact_lock(hashtextextended('sohoj-academic-operations',20));
 if action='CREATE_ROOM' then
  if not exists(select 1 from public.branches where id=(p_input->>'branch_id')::uuid and is_active) then raise exception 'Choose an active branch.';end if;
  insert into public.academic_rooms(branch_id,name,capacity,created_by) values((p_input->>'branch_id')::uuid,btrim(p_input->>'name'),(p_input->>'capacity')::integer,actor) returning id into id_out;
  result:=jsonb_build_object('id',id_out,'message','Room created.');
 elsif action='PUBLISH_CURRICULUM' then
  select * into b from public.batches where id=(p_input->>'batch_id')::uuid and is_active;
  select * into year from public.academic_years where id=b.academic_year_id;
  if b.id is null or not exists(select 1 from public.subjects where id=(p_input->>'subject_id')::uuid and organization_id=b.organization_id and is_active) then raise exception 'Choose an active batch and subject in the same organization.';end if;
  rows:=p_input->'units';
  if length(btrim(coalesce(p_input->>'title','')))<2 or rows is null or jsonb_typeof(rows)<>'array' then raise exception 'A title and curriculum units are required.';end if;
  if jsonb_array_length(rows)=0 then raise exception 'Add at least one curriculum unit.';end if;
  for unit in select x from jsonb_array_elements(rows) x loop
   if length(btrim(coalesce(unit->>'title','')))<2 or (unit->>'target_date')::date is null or (unit->>'target_date')::date not between year.starts_on and year.ends_on then raise exception 'Each unit needs a title and target date inside the academic year.';end if;
  end loop;
  insert into public.curriculum_versions(batch_id,subject_id,version,title,units,reason,published_by)
  select b.id,(p_input->>'subject_id')::uuid,coalesce(max(v.version),0)+1,btrim(p_input->>'title'),rows,btrim(p_input->>'reason'),actor from public.curriculum_versions v where v.batch_id=b.id and v.subject_id=(p_input->>'subject_id')::uuid returning id into id_out;
  result:=jsonb_build_object('id',id_out,'message','Curriculum version published. Earlier versions and session references are preserved.');
 elsif action in('CREATE_ROUTINE','GENERATE_SESSIONS','CREATE_SESSION') then
  if action='GENERATE_SESSIONS' then
   select * into r from public.academic_routines where id=(p_input->>'routine_id')::uuid and retired_at is null;
   if r.id is null then raise exception 'Active routine not found.';end if;
   bid:=r.batch_id;subid:=r.subject_id;tid:=r.teacher_id;roomid:=r.room_id;st:=r.start_time;et:=r.end_time;
   date_from:=(p_input->>'starts_on')::date;date_to:=(p_input->>'ends_on')::date;
   if date_from<r.starts_on or date_to>r.ends_on then raise exception 'Generation dates must stay inside the routine period.';end if;
  else
   bid:=(p_input->>'batch_id')::uuid;subid:=(p_input->>'subject_id')::uuid;tid:=(p_input->>'teacher_id')::uuid;roomid:=(p_input->>'room_id')::uuid;
   st:=(p_input->>'start_time')::time;et:=(p_input->>'end_time')::time;
   date_from:=(p_input->>'starts_on')::date;date_to:=case when action='CREATE_SESSION' then date_from else (p_input->>'ends_on')::date end;
  end if;
  select * into b from public.batches where id=bid and is_active for update;
  select * into room from public.academic_rooms where id=roomid;
  select * into teacher from public.staff where id=tid and status='ACTIVE';
  select * into year from public.academic_years where id=b.academic_year_id;
  select timezone into tz from public.organizations where id=b.organization_id;
  if b.id is null or b.offering_id is null or room.id is null or room.branch_id is distinct from b.branch_id or teacher.id is null then raise exception 'Choose an active batch, active teacher and room in the batch branch.';end if;
  if teacher.branch_id is not null and teacher.branch_id<>b.branch_id then raise exception 'Teacher belongs to a different branch.';end if;
  if room.capacity<b.capacity then raise exception 'Room capacity is below the configured batch capacity.';end if;
  if not exists(select 1 from public.subjects where id=subid and organization_id=b.organization_id and is_active) then raise exception 'Subject is unavailable for this organization.';end if;
  if date_from is null or date_to is null or date_to<date_from or date_from<year.starts_on or date_to>year.ends_on or st is null or et is null or et<=st then raise exception 'Enter valid same-day class times and dates inside the academic year.';end if;
  if not exists(select 1 from public.staff_subject_assignments where staff_id=tid and subject_id=subid and effective_from<=date_from and (effective_to is null or effective_to>=date_to)) or not exists(select 1 from public.staff_role_assignments a join public.staff_roles sr on sr.id=a.staff_role_id where a.staff_id=tid and sr.is_teaching_role and a.effective_from<=date_from and (a.effective_to is null or a.effective_to>=date_to)) then raise exception 'Teacher must have a teaching role and subject qualification covering these dates.';end if;
  if action='CREATE_ROUTINE' then
   if (p_input->>'weekday')::integer is null or (p_input->>'weekday')::integer not between 0 and 6 then raise exception 'Choose a weekday.';end if;
   if exists(select 1 from public.academic_routines x where x.retired_at is null and x.weekday=(p_input->>'weekday')::integer and x.starts_on<=date_to and x.ends_on>=date_from and x.start_time<et and x.end_time>st and (x.batch_id=bid or x.teacher_id=tid or x.room_id=roomid)) then raise exception 'Routine conflicts with an existing teacher, batch or room assignment.';end if;
   if exists(select 1 from public.class_sessions x where x.status='SCHEDULED' and x.session_date between date_from and date_to and extract(dow from x.session_date)=(p_input->>'weekday')::integer and (x.starts_at at time zone tz)::time<et and (x.ends_at at time zone tz)::time>st and (x.batch_id=bid or x.teacher_id=tid or x.room_id=roomid)) then raise exception 'Routine conflicts with an existing dated session.';end if;
   insert into public.academic_routines(batch_id,subject_id,teacher_id,room_id,weekday,start_time,end_time,starts_on,ends_on,created_by)
   values(bid,subid,tid,roomid,(p_input->>'weekday')::integer,st,et,date_from,date_to,actor) returning id into id_out;
   result:=jsonb_build_object('id',id_out,'message','Routine created. Generate dated sessions to make classes operational.');
  else
   if date_to-date_from>93 then raise exception 'Generate at most 94 days per request; split larger jobs.';end if;
   scope:=btrim(coalesce(p_input->>'planned_scope',''));
   if length(scope)<2 then raise exception 'Describe the planned scope for these classes.';end if;
   if nullif(p_input->>'curriculum_id','') is not null then
    select * into cv from public.curriculum_versions where id=(p_input->>'curriculum_id')::uuid and batch_id=bid and subject_id=subid;
    if cv.id is null then raise exception 'Curriculum version must match the session batch and subject.';end if;
   end if;
   for day in select d::date from generate_series(date_from::timestamp,date_to::timestamp,interval '1 day') d loop
    if action='GENERATE_SESSIONS' and extract(dow from day)<>r.weekday then continue;end if;
    if action='GENERATE_SESSIONS' and exists(select 1 from public.class_sessions where routine_id=r.id and session_date=day) then continue;end if;
    start_at:=(day+st) at time zone tz;end_at:=(day+et) at time zone tz;
    if exists(select 1 from public.class_sessions x where x.status='SCHEDULED' and x.starts_at<end_at and x.ends_at>start_at and (x.batch_id=bid or x.teacher_id=tid or x.room_id=roomid)) then raise exception 'Session conflict on %: teacher, batch or room is occupied. Nothing was posted.',day;end if;
    if exists(select 1 from public.academic_routines x where x.retired_at is null and x.id is distinct from r.id and x.weekday=extract(dow from day) and day between x.starts_on and x.ends_on and x.start_time<et and x.end_time>st and (x.batch_id=bid or x.teacher_id=tid or x.room_id=roomid)) then raise exception 'Session conflicts with a reserved routine on %.',day;end if;
    insert into public.class_sessions(routine_id,batch_id,subject_id,teacher_id,room_id,curriculum_version_id,planned_scope,session_date,starts_at,ends_at,created_by)
    values(r.id,bid,subid,tid,roomid,cv.id,scope,day,start_at,end_at,actor) returning id into id_out;
    created:=created+1;
   end loop;
   result:=jsonb_build_object('id',coalesce(id_out,r.id),'message',created||' dated sessions created. Existing routine dates were preserved.');
  end if;
 elsif action='RETIRE_ROUTINE' then
  update public.academic_routines set retired_at=now() where id=(p_input->>'routine_id')::uuid and retired_at is null returning id into id_out;
  if id_out is null then raise exception 'Active routine not found.';end if;
  result:=jsonb_build_object('id',id_out,'message','Routine retired. Existing dated sessions remain; cancel affected occurrences explicitly.');
 else
  if action='DECIDE_ATTENDANCE' then
   select * into approval from public.approval_requests where id=(p_input->>'approval_id')::uuid and workflow_type='ATTENDANCE';
   if approval.id is null then raise exception 'Attendance approval not found.';end if;
   sid:=approval.entity_id::uuid;
  else sid:=(p_input->>'session_id')::uuid;end if;
  if not public.can_access_class_session(sid) then raise exception 'This class is outside your assigned scope.';end if;
  select * into cs from public.class_sessions where id=sid for update;
  select * into last_att from public.attendance_submissions where session_id=sid order by revision desc limit 1;
  if action='CANCEL_SESSION' then
   if cs.status='CANCELLED' then raise exception 'Session already cancelled.';end if;
   if exists(select 1 from public.attendance_submissions where session_id=sid and status in('SUBMITTED','APPROVED')) then raise exception 'A session with submitted or approved attendance cannot be cancelled.';end if;
   update public.class_sessions set status='CANCELLED',cancellation_reason=reason,cancelled_by=actor,cancelled_at=now() where id=sid;
   result:=jsonb_build_object('id',sid,'message','Session cancelled; the original schedule and reason remain in history.');
  elsif action='SAVE_ATTENDANCE' then
   if cs.status<>'SCHEDULED' or cs.starts_at>now() then raise exception 'Attendance can be recorded only after a scheduled class has started.';end if;
   if last_att.status='SUBMITTED' then raise exception 'Attendance is awaiting a decision.';end if;
   if last_att.id is distinct from nullif(p_input->>'base_id','')::uuid then raise exception 'Attendance changed. Refresh before saving a new revision.';end if;
   -- Lock placement while the first roster is snapshotted. Later revisions retain that roster.
   perform 1 from public.batches where id=cs.batch_id for update;
   if last_att.id is null then
    select coalesce(jsonb_agg(jsonb_build_object('student_id',s.id,'enrollment_id',e.id,'number',s.student_no,'name',s.full_name) order by s.student_no),'[]'::jsonb) into roster
    from public.enrollments e join public.students s on s.id=e.student_id where e.batch_id=cs.batch_id and e.admission_date<=cs.session_date and (e.ended_on is null or e.ended_on>cs.session_date) and e.status in('ACTIVE','WITHDRAWN','COMPLETED');
   else roster:=last_att.entries;end if;
   rows:=p_input->'entries';
   if rows is null or jsonb_typeof(rows)<>'array' then raise exception 'Attendance entries are required.';end if;
   if jsonb_array_length(roster)=0 or jsonb_array_length(rows)<>jsonb_array_length(roster) or (select count(distinct x->>'enrollment_id') from jsonb_array_elements(rows) x)<>jsonb_array_length(rows) then raise exception 'Record exactly one attendance status for every roster member. Refresh if the roster changed.';end if;
   for entry in select x from jsonb_array_elements(rows) x loop
    if coalesce(entry->>'status','') not in('PRESENT','ABSENT','LATE','EXCUSED') or not exists(select 1 from jsonb_array_elements(roster) x where x->>'enrollment_id'=entry->>'enrollment_id') or length(coalesce(entry->>'note',''))>500 then raise exception 'Invalid attendance status, note or roster member.';end if;
   end loop;
   select jsonb_agg(x||jsonb_build_object('status',y->>'status','note',coalesce(y->>'note','')) order by x->>'number') into rows from jsonb_array_elements(roster) x join jsonb_array_elements(rows) y on x->>'enrollment_id'=y->>'enrollment_id';
   insert into public.attendance_submissions(session_id,revision,entries,reason,recorded_by) values(sid,coalesce(last_att.revision,0)+1,rows,reason,actor) returning id into id_out;
   result:=jsonb_build_object('id',id_out,'message','Attendance draft saved. Submit it for independent approval.');
  elsif action='SUBMIT_ATTENDANCE' then
   if cs.status<>'SCHEDULED' or last_att.id is distinct from (p_input->>'attendance_id')::uuid or last_att.status<>'DRAFT' then raise exception 'Only the latest saved draft can be submitted.';end if;
   if last_att.recorded_by<>actor then raise exception 'Only the draft author may submit it. Save your own reviewed revision first.';end if;
   insert into public.approval_requests(workflow_type,entity_type,entity_id,requested_action,payload_snapshot,request_note,requested_by,correlation_id)
   values('ATTENDANCE','CLASS_SESSION',sid::text,action,jsonb_build_object('attendance_id',last_att.id,'revision',last_att.revision,'entries',last_att.entries),reason,actor,req) returning id into id_out;
   update public.attendance_submissions set status='SUBMITTED',approval_id=id_out where id=last_att.id;
   result:=jsonb_build_object('id',id_out,'message','Attendance submitted for independent approval.');
  elsif action='DECIDE_ATTENDANCE' then
   if approval.status<>'PENDING' then raise exception 'Attendance request already decided.';end if;
   select * into att from public.attendance_submissions where id=(approval.payload_snapshot->>'attendance_id')::uuid and status='SUBMITTED';
   if att.id is null then raise exception 'Submitted attendance not found.';end if;
   if actor=approval.requested_by or actor=att.recorded_by then raise exception 'Maker-checker: another authorized person must decide attendance.';end if;
   if p_input->>'decision' not in('APPROVED','REJECTED') or p_input->>'decision' is null then raise exception 'Choose Approve or Reject.';end if;
   update public.attendance_submissions set status=p_input->>'decision' where id=att.id;
   update public.approval_requests set status=(p_input->>'decision')::public.approval_status,decided_by=actor,decided_at=now(),decision_note=reason where id=approval.id;
   result:=jsonb_build_object('id',att.id,'message','Attendance '||lower(p_input->>'decision')||'. Prior approved revisions remain in history.');
  end if;
 end if;
 insert into public.audit_events(correlation_id,actor_profile_id,entity_type,entity_id,action,reason,after_data,metadata)
 values(req,actor,'ACADEMIC_WORKFLOW',result->>'id',action,reason,result,p_input);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(req,actor,p_input,result);
 return result;
end; $function$
;

CREATE OR REPLACE FUNCTION public.academic_workspace(p_from date, p_to date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare manager boolean:=public.has_permission('academics.sessions.manage');curriculum_manager boolean:=public.has_permission('academics.curriculum.manage');begin
 if auth.uid() is null or not public.has_permission('academics.view') then raise exception 'Academic access required.';end if;
 if p_from is null or p_to is null or p_to<p_from or p_to-p_from>366 then raise exception 'Choose a date range of at most 367 days.';end if;
 return jsonb_build_object(
 'branches',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name)) from public.branches where is_active),'[]'::jsonb),
 'batches',case when manager or curriculum_manager then coalesce((select jsonb_agg(jsonb_build_object('id',b.id,'name',b.name||' · '||y.name,'branchId',b.branch_id,'capacity',b.capacity)) from public.batches b join public.academic_years y on y.id=b.academic_year_id where b.is_active and b.offering_id is not null),'[]'::jsonb) else '[]'::jsonb end,
 'subjects',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name)) from public.subjects where is_active),'[]'::jsonb),
 'teachers',case when manager then coalesce((select jsonb_agg(jsonb_build_object('id',s.id,'name',s.full_name,'subjects',coalesce((select jsonb_agg(subject_id) from public.staff_subject_assignments where staff_id=s.id),'[]'::jsonb))) from public.staff s where s.status='ACTIVE' and exists(select 1 from public.staff_subject_assignments where staff_id=s.id)),'[]'::jsonb) else '[]'::jsonb end,
 'rooms',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name,'branchId',branch_id,'capacity',capacity)) from public.academic_rooms),'[]'::jsonb),
 'curricula',coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'batchId',v.batch_id,'subjectId',v.subject_id,'batch',b.name,'subject',s.name,'version',v.version,'title',v.title,'units',v.units) order by v.published_at desc) from public.curriculum_versions v join public.batches b on b.id=v.batch_id join public.subjects s on s.id=v.subject_id where manager or curriculum_manager or exists(select 1 from public.class_sessions x where x.curriculum_version_id=v.id and public.can_access_class_session(x.id))),'[]'::jsonb),
 'routines',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'batchId',r.batch_id,'subjectId',r.subject_id,'batch',b.name,'subject',s.name,'teacher',t.full_name,'room',rm.name,'weekday',r.weekday,'startTime',r.start_time,'endTime',r.end_time,'startsOn',r.starts_on,'endsOn',r.ends_on,'retired',r.retired_at is not null)) from public.academic_routines r join public.batches b on b.id=r.batch_id join public.subjects s on s.id=r.subject_id join public.staff t on t.id=r.teacher_id join public.academic_rooms rm on rm.id=r.room_id where manager or t.profile_id=auth.uid()),'[]'::jsonb),
 'sessions',coalesce((select jsonb_agg(jsonb_build_object('id',x.id,'batch',b.name,'subject',s.name,'teacher',t.full_name,'room',rm.name,'date',x.session_date,'startTime',to_char(x.starts_at at time zone o.timezone,'HH24:MI'),'endTime',to_char(x.ends_at at time zone o.timezone,'HH24:MI'),'timezone',o.timezone,'status',x.status,'scope',x.planned_scope,'latestStatus',(select status from public.attendance_submissions where session_id=x.id order by revision desc limit 1),'approvedRevision',(select max(revision) from public.attendance_submissions where session_id=x.id and status='APPROVED')) order by x.starts_at) from public.class_sessions x join public.batches b on b.id=x.batch_id join public.organizations o on o.id=b.organization_id join public.subjects s on s.id=x.subject_id join public.staff t on t.id=x.teacher_id join public.academic_rooms rm on rm.id=x.room_id where x.session_date between p_from and p_to and public.can_access_class_session(x.id)),'[]'::jsonb)
 );
end; $function$
;

CREATE OR REPLACE FUNCTION public.assessment_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare actor uuid:=auth.uid(); act text:=p_input->>'action'; rid uuid:=(p_input->>'request_id')::uuid;
  a public.academic_assessments; r public.assessment_result_submissions; key public.admission_command_keys;
  v_entries jsonb:=coalesce(p_input->'entries','[]'::jsonb); expected integer; result jsonb;
  v_batch uuid; v_subject uuid; v_date date; v_max numeric;
begin
 if actor is null or not public.has_permission('academics.view') then raise exception 'Academic access required.'; end if;
 if rid is null then raise exception 'Request identity required.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(rid::text,0));
 select * into key from public.admission_command_keys where request_id=rid;
 if found then
   if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity already used for different input.'; end if;
   return key.result;
 end if;
 if act='CREATE' then
   if not public.has_permission('academics.assessments.record') then raise exception 'Assessment recording permission required.'; end if;
   v_batch:=(p_input->>'batch_id')::uuid; v_subject:=(p_input->>'subject_id')::uuid;
   if not public.can_access_assessment(v_batch,v_subject) then raise exception 'Assessment is outside your teaching scope.'; end if;
   if not exists(select 1 from public.class_sessions where batch_id=v_batch and subject_id=v_subject) then raise exception 'Schedule a class for this batch and subject first.'; end if;
   v_date:=(p_input->>'assessment_date')::date; v_max:=(p_input->>'max_marks')::numeric;
   if v_date is null or v_max is null or v_max<=0 or v_max>1000
     or length(btrim(coalesce(p_input->>'title',''))) not between 3 and 180 then raise exception 'Enter assessment title, date and valid maximum marks.'; end if;
   if not exists(select 1 from public.batches b join public.academic_years y on y.id=b.academic_year_id where b.id=v_batch and v_date between y.starts_on and y.ends_on) then raise exception 'Assessment date must be in the batch academic year.'; end if;
   insert into public.academic_assessments(batch_id,subject_id,title,assessment_date,max_marks,author_id)
   values(v_batch,v_subject,btrim(p_input->>'title'),v_date,v_max,actor) returning * into a;
 else
   select * into a from public.academic_assessments where id=(p_input->>'assessment_id')::uuid for update;
   if a.id is null or not public.can_access_assessment(a.batch_id,a.subject_id) then raise exception 'Assessment not found in your scope.'; end if;
   if act='PUBLISH' then
     if a.status<>'DRAFT' or not public.has_permission('academics.assessments.record') then raise exception 'Only a draft can be published.'; end if;
     if a.author_id<>actor and not public.has_permission('academics.sessions.manage') then raise exception 'Only the author may publish this assessment.'; end if;
     update public.academic_assessments set status='PUBLISHED',published_at=now() where id=a.id returning * into a;
   elsif act='SAVE_RESULTS' then
     if a.status<>'PUBLISHED' or not public.has_permission('academics.assessments.record') then raise exception 'Published assessment and recording permission required.'; end if;
     if jsonb_typeof(v_entries)<>'array' or jsonb_array_length(v_entries)>500 then raise exception 'Check result entries.'; end if;
     select count(*) into expected from public.enrollments e where e.batch_id=a.batch_id and e.admission_date<=a.assessment_date
       and (e.ended_on is null or e.ended_on>a.assessment_date) and e.status in ('ACTIVE','WITHDRAWN','COMPLETED');
     if expected=0 or expected<>jsonb_array_length(v_entries) then raise exception 'Record exactly one result for every eligible student.'; end if;
     if exists(select 1 from jsonb_array_elements(v_entries) e where
       not (e ? 'enrollment_id' and e ? 'score') or (e->>'score') !~ '^([0-9]+)(\.[0-9]{1,2})?$'
       or (e->>'score')::numeric>a.max_marks or length(coalesce(e->>'feedback',''))>500
       or not exists(select 1 from public.enrollments x where x.id=(e->>'enrollment_id')::uuid and x.batch_id=a.batch_id
         and x.admission_date<=a.assessment_date and (x.ended_on is null or x.ended_on>a.assessment_date)
         and x.status in ('ACTIVE','WITHDRAWN','COMPLETED')))
       or (select count(distinct e->>'enrollment_id') from jsonb_array_elements(v_entries) e)<>expected
       then raise exception 'Invalid or duplicate result entries.'; end if;
     select * into r from public.assessment_result_submissions where assessment_id=a.id and status='DRAFT' for update;
     if r.id is null then
       if exists(select 1 from public.assessment_result_submissions where assessment_id=a.id and status='SUBMITTED') then raise exception 'Results are awaiting independent review.'; end if;
       insert into public.assessment_result_submissions(assessment_id,revision,entries,author_id)
       values(a.id,(select coalesce(max(revision),0)+1 from public.assessment_result_submissions where assessment_id=a.id),v_entries,actor) returning * into r;
     else
       if r.author_id<>actor then raise exception 'Only the draft author can change these results.'; end if;
       update public.assessment_result_submissions set entries=v_entries where id=r.id returning * into r;
     end if;
   elsif act='SUBMIT_RESULTS' then
     select * into r from public.assessment_result_submissions where assessment_id=a.id and status='DRAFT' for update;
     if r.id is null or r.author_id<>actor then raise exception 'Save your result draft before submitting.'; end if;
     update public.assessment_result_submissions set status='SUBMITTED',submitted_at=now() where id=r.id returning * into r;
   elsif act in ('APPROVE_RESULTS','REJECT_RESULTS') then
     if not public.has_permission('academics.assessments.approve') then raise exception 'Assessment review permission required.'; end if;
     select * into r from public.assessment_result_submissions where assessment_id=a.id and status='SUBMITTED' for update;
     if r.id is null then raise exception 'No submitted result revision is awaiting review.'; end if;
     if r.author_id=actor then raise exception 'Result author cannot approve or reject their own submission.'; end if;
     if length(btrim(coalesce(p_input->>'review_note','')))<5 then raise exception 'Enter a review reason.'; end if;
     update public.assessment_result_submissions set status=case when act='APPROVE_RESULTS' then 'APPROVED' else 'REJECTED' end,
       reviewer_id=actor,review_note=btrim(p_input->>'review_note'),reviewed_at=now() where id=r.id returning * into r;
   else raise exception 'Unknown assessment action.'; end if;
 end if;
 result:=jsonb_build_object('id',a.id,'status',coalesce(r.status,a.status),'revision',r.revision);
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,after_data)
 values(actor,'ASSESSMENT',a.id::text,act,case when r.id is null then to_jsonb(a) else to_jsonb(r) end);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(rid,actor,p_input,result);
 return result;
end $function$
;

CREATE OR REPLACE FUNCTION public.assessment_workspace()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare actor uuid:=auth.uid();
begin
 if actor is null or not public.has_permission('academics.view') then raise exception 'Academic access required.'; end if;
 return jsonb_build_object(
  'scopes',coalesce((select jsonb_agg(jsonb_build_object('batchId',cs.batch_id,'subjectId',cs.subject_id,'batch',b.name,'subject',s.name) order by b.name,s.name)
    from (select distinct batch_id,subject_id from public.class_sessions) cs
    join public.batches b on b.id=cs.batch_id join public.subjects s on s.id=cs.subject_id
    where public.can_access_assessment(cs.batch_id,cs.subject_id)),'[]'::jsonb),
  'assessments',coalesce((select jsonb_agg(jsonb_build_object(
    'id',a.id,'batchId',a.batch_id,'subjectId',a.subject_id,'batch',b.name,'subject',s.name,
    'title',a.title,'date',a.assessment_date,'maxMarks',a.max_marks,'status',a.status,
    'authorId',a.author_id,'roster',coalesce((select jsonb_agg(jsonb_build_object('enrollmentId',e.id,'studentNo',st.student_no,'name',st.full_name) order by st.student_no)
      from public.enrollments e join public.students st on st.id=e.student_id
      where e.batch_id=a.batch_id and e.admission_date<=a.assessment_date
        and (e.ended_on is null or e.ended_on>a.assessment_date) and e.status in ('ACTIVE','WITHDRAWN','COMPLETED')),'[]'::jsonb),
    'submissions',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'revision',r.revision,'status',r.status,'entries',r.entries,'authorId',r.author_id,'reviewNote',r.review_note,'createdAt',r.created_at) order by r.revision desc)
      from public.assessment_result_submissions r where r.assessment_id=a.id),'[]'::jsonb)
    ) order by a.assessment_date desc)
    from public.academic_assessments a join public.batches b on b.id=a.batch_id join public.subjects s on s.id=a.subject_id
    where public.can_access_assessment(a.batch_id,a.subject_id)),'[]'::jsonb)
 );
end $function$
;

CREATE OR REPLACE FUNCTION public.can_access_assessment(p_batch uuid, p_subject uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select auth.uid() is not null and public.has_permission('academics.view') and (
  public.has_permission('academics.assessments.approve') or public.has_permission('academics.sessions.manage')
  or exists(select 1 from public.class_sessions cs join public.staff st on st.id=cs.teacher_id
    where cs.batch_id=p_batch and cs.subject_id=p_subject and st.profile_id=auth.uid())
 );
$function$
;

CREATE OR REPLACE FUNCTION public.can_access_class_session(p_session uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select auth.uid() is not null and public.has_permission('academics.view') and exists(select 1 from public.class_sessions cs join public.staff st on st.id=cs.teacher_id where cs.id=p_session and (public.has_permission('academics.sessions.manage') or public.has_permission('academics.attendance.approve') or st.profile_id=auth.uid()));
$function$
;

CREATE OR REPLACE FUNCTION public.class_log_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor uuid := auth.uid();
  rid uuid := nullif(p_input->>'request_id','')::uuid;
  sid uuid := nullif(p_input->>'session_id','')::uuid;
  act text := p_input->>'action';
  why text := trim(coalesce(p_input->>'reason',''));
  key public.admission_command_keys;
  cs public.class_sessions;
  latest public.class_logs;
  draft public.class_logs;
  review public.class_logs;
  progress jsonb := coalesce(p_input->'unit_progress','[]'::jsonb);
  unit_count integer;
  summary text := trim(coalesce(p_input->>'class_summary',''));
  unfinished text := trim(coalesce(p_input->>'unfinished_reason',''));
  homework_value text := trim(coalesce(p_input->>'homework',''));
  next_value text := trim(coalesce(p_input->>'next_session_plan',''));
  result jsonb;
  new_revision integer;
  branch uuid;
begin
  if actor is null or not public.has_permission('academics.view') then
    raise exception 'Academic access required.';
  end if;

  if rid is null or sid is null or length(why) < 5 or length(why) > 500 then
    raise exception 'Session, request identity and reason (5–500 characters) are required.';
  end if;

  if act = 'DECIDE' then
    if not public.has_permission('academics.attendance.approve') then
      raise exception 'Academic review permission required.';
    end if;
  elsif not (
    public.has_permission('academics.attendance.record')
    or public.has_permission('academics.sessions.manage')
  ) then
    raise exception 'Attendance recording permission required.';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(rid::text,0));
  select * into key from public.admission_command_keys where request_id=rid;
  if found then
    if key.actor_id<>actor or key.payload<>p_input then
      raise exception 'Request identity already used for different input.';
    end if;
    return key.result;
  end if;

  perform pg_advisory_xact_lock(hashtextextended(sid::text,21));

  select * into cs
  from public.class_sessions
  where id=sid
  for update;

  if cs.id is null then
    raise exception 'Class session not found.';
  end if;

  select branch_id
  into branch
  from public.batches
  where id=cs.batch_id;

  if act='DECIDE' then
    select *
    into review
    from public.class_logs
    where id=nullif(p_input->>'class_log_id','')::uuid
      and session_id=sid
      and status='SUBMITTED'
    for update;

    if review.id is null then
      raise exception 'No submitted class log is awaiting review.';
    end if;

    if review.authored_by=actor then
      raise exception 'The class-log author cannot approve or reject their own submission.';
    end if;

    if p_input->>'decision' not in ('APPROVED','REJECTED') then
      raise exception 'Choose Approve or Reject.';
    end if;

    if length(trim(coalesce(p_input->>'review_note',''))) < 5
      or length(trim(coalesce(p_input->>'review_note',''))) > 1000 then
      raise exception 'Enter a review note of 5–1000 characters.';
    end if;

    update public.class_logs
    set status=p_input->>'decision',
        reviewer_id=actor,
        review_note=trim(p_input->>'review_note'),
        reviewed_at=now()
    where id=review.id
    returning * into review;

    result:=jsonb_build_object(
      'id',review.id,
      'revision',review.revision,
      'status',review.status,
      'message',case when review.status='APPROVED'
        then 'Class log approved.'
        else 'Class log rejected. The teacher can prepare a corrected revision.'
      end
    );

  else
    if not public.can_access_class_session(sid) then
      raise exception 'This class is outside your assigned scope.';
    end if;

    if cs.status<>'SCHEDULED' then
      raise exception 'A cancelled class cannot receive a class log.';
    end if;

    if cs.starts_at>now() then
      raise exception 'Class log opens after the scheduled class starts.';
    end if;

    if not public.has_permission('academics.sessions.manage')
      and not exists(
        select 1
        from public.staff st
        where st.profile_id=actor and st.id=cs.teacher_id
      ) then
      raise exception 'Only the assigned teacher may record this class.';
    end if;

    select * into latest
    from public.class_logs
    where session_id=sid
    order by revision desc
    limit 1;

    select * into draft
    from public.class_logs
    where session_id=sid
      and status='DRAFT'
    for update;

    if act='SAVE_DRAFT' then
      if latest.status='SUBMITTED' then
        raise exception 'This class log is awaiting admin review. Correct it only after a review decision.';
      end if;

      if jsonb_typeof(progress)<>'array' or jsonb_array_length(progress)>200 then
        raise exception 'Check curriculum progress entries.';
      end if;

      select coalesce(jsonb_array_length(cv.units),0)
      into unit_count
      from public.class_sessions x
      left join public.curriculum_versions cv on cv.id=x.curriculum_version_id
      where x.id=sid;

      if jsonb_array_length(progress)>unit_count then
        raise exception 'Progress must refer only to the curriculum pinned to this class.';
      end if;

      if exists(
        select 1
        from jsonb_array_elements(progress) e
        where (e->>'unit_index')::integer<0
          or (e->>'unit_index')::integer>=unit_count
          or e->>'status' not in ('COVERED','PARTIAL','NOT_COVERED')
          or length(coalesce(e->>'note',''))>500
      ) then
        raise exception 'Invalid curriculum progress entry.';
      end if;

      if summary='' or length(summary)>4000
        or length(unfinished)>2000
        or length(homework_value)>2000
        or length(next_value)>2000 then
        raise exception 'Class summary is required; keep each field within its limit.';
      end if;

      if exists(
        select 1 from jsonb_array_elements(progress) e
        where e->>'status' in ('PARTIAL','NOT_COVERED')
      ) and unfinished='' then
        raise exception 'Explain any planned curriculum left incomplete.';
      end if;

      if draft.id is not null and draft.authored_by<>actor then
        raise exception 'Another staff member owns the current draft.';
      end if;

      if draft.id is null then
        select coalesce(max(revision),0)+1
        into new_revision
        from public.class_logs
        where session_id=sid;

        insert into public.class_logs(
          session_id,revision,previous_log_id,status,unit_progress,
          class_summary,unfinished_reason,homework,next_session_plan,
          reason,authored_by
        )
        values(
          sid,new_revision,latest.id,'DRAFT',progress,summary,
          unfinished,homework_value,next_value,why,actor
        )
        returning * into draft;
      else
        update public.class_logs
        set unit_progress=progress,
            class_summary=summary,
            unfinished_reason=unfinished,
            homework=homework_value,
            next_session_plan=next_value,
            reason=why
        where id=draft.id
        returning * into draft;
      end if;

      result:=jsonb_build_object(
        'id',draft.id,
        'revision',draft.revision,
        'status',draft.status,
        'message','Class-log draft saved.'
      );

    elsif act='SUBMIT' then
      if draft.id is null or draft.authored_by<>actor then
        raise exception 'Save your class-log draft before submitting it.';
      end if;

      update public.class_logs
      set status='SUBMITTED',
          submitted_at=now()
      where id=draft.id
      returning * into draft;

      result:=jsonb_build_object(
        'id',draft.id,
        'revision',draft.revision,
        'status',draft.status,
        'message','Class log submitted for admin review.'
      );

    else
      raise exception 'Unsupported class-log action.';
    end if;
  end if;

  insert into public.audit_events(
    actor_profile_id,
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
    actor,
    branch,
    'CLASS_LOG',
    coalesce(draft.id,review.id)::text,
    act,
    why,
    null,
    case when review.id is not null then to_jsonb(review) else to_jsonb(draft) end,
    jsonb_build_object('session_id',sid,'revision',coalesce(draft.revision,review.revision))
  );

  insert into public.admission_command_keys(request_id,actor_id,payload,result)
  values(rid,actor,p_input,result);

  return result;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.class_log_workspace(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare result jsonb;
begin
 if not public.can_access_class_session(p_session_id) then raise exception 'This class is outside your assigned scope.'; end if;
 select jsonb_build_object(
  'logs',coalesce((select jsonb_agg(to_jsonb(l) order by revision desc) from public.class_logs l where l.session_id=p_session_id),'[]'::jsonb),
  'units',coalesce((select cv.units from public.class_sessions cs join public.curriculum_versions cv on cv.id=cs.curriculum_version_id where cs.id=p_session_id),'[]'::jsonb)
 ) into result;
 return result;
end $function$
;

CREATE OR REPLACE FUNCTION public.class_session_workspace(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare cs public.class_sessions;latest public.attendance_submissions;roster jsonb;begin
 if not public.can_access_class_session(p_session_id) then raise exception 'This class is outside your assigned scope.';end if;
 select * into cs from public.class_sessions where id=p_session_id;
 select * into latest from public.attendance_submissions where session_id=cs.id order by revision desc limit 1;
 if latest.id is null then
  select coalesce(jsonb_agg(jsonb_build_object('enrollment_id',e.id,'student_id',s.id,'number',s.student_no,'name',s.full_name) order by s.student_no),'[]'::jsonb) into roster from public.enrollments e join public.students s on s.id=e.student_id where e.batch_id=cs.batch_id and e.admission_date<=cs.session_date and (e.ended_on is null or e.ended_on>cs.session_date) and e.status in('ACTIVE','WITHDRAWN','COMPLETED');
 else roster:=latest.entries;end if;
 return jsonb_build_object(
 'session',(select jsonb_build_object('id',cs.id,'batch',b.name,'subject',s.name,'teacher',t.full_name,'teacherProfileId',t.profile_id,'room',r.name,'date',cs.session_date,'canRecordNow',cs.starts_at<=now(),'startsAt',cs.starts_at,'endsAt',cs.ends_at,'timezone',o.timezone,'status',cs.status,'scope',cs.planned_scope,'cancellationReason',cs.cancellation_reason,'curriculumTitle',v.title,'curriculumVersion',v.version,'units',coalesce(v.units,'[]'::jsonb)) from public.batches b join public.organizations o on o.id=b.organization_id cross join public.subjects s cross join public.staff t cross join public.academic_rooms r left join public.curriculum_versions v on v.id=cs.curriculum_version_id where b.id=cs.batch_id and s.id=cs.subject_id and t.id=cs.teacher_id and r.id=cs.room_id),
 'roster',roster,
 'submissions',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'revision',a.revision,'status',a.status,'entries',a.entries,'reason',a.reason,'recordedBy',a.recorded_by,'recorder',p.display_name,'createdAt',a.created_at,'approvalId',a.approval_id,'decisionNote',r.decision_note) order by a.revision desc) from public.attendance_submissions a join public.profiles p on p.id=a.recorded_by left join public.approval_requests r on r.id=a.approval_id where a.session_id=cs.id),'[]'::jsonb)
 );
end; $function$
;

CREATE OR REPLACE FUNCTION public.guard_submitted_class_log()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  if tg_op = 'DELETE' then
    raise exception 'Class-log history cannot be deleted.';
  end if;

  if old.status = 'DRAFT' then
    if new.status = 'DRAFT' then
      return new;
    end if;

    if new.status = 'SUBMITTED'
      and (to_jsonb(new) - array['status','submitted_at','reviewer_id','review_note','reviewed_at'])
          is distinct from
          (to_jsonb(old) - array['status','submitted_at','reviewer_id','review_note','reviewed_at']) then
      raise exception 'Submit the saved class-log draft without changing its contents.';
    end if;

    if new.status not in ('DRAFT','SUBMITTED') then
      raise exception 'A class-log draft must be submitted before review.';
    end if;

    return new;
  end if;

  if old.status = 'SUBMITTED' then
    if new.status not in ('APPROVED','REJECTED') then
      raise exception 'Submitted class-log evidence must be approved or rejected.';
    end if;

    if (to_jsonb(new) - array['status','reviewer_id','review_note','reviewed_at'])
       is distinct from
       (to_jsonb(old) - array['status','reviewer_id','review_note','reviewed_at']) then
      raise exception 'Submitted class-log evidence is immutable; create a new revision after rejection or approval.';
    end if;

    if new.reviewer_id is null or new.reviewed_at is null or length(btrim(coalesce(new.review_note,''))) < 5 then
      raise exception 'A class-log review requires a reviewer, time and review note.';
    end if;

    return new;
  end if;

  raise exception 'Finalized class-log evidence is immutable; create a new revision.';
end;
$function$
;

CREATE OR REPLACE FUNCTION public.homework_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare actor uuid:=auth.uid(); rid uuid:=(p_input->>'request_id')::uuid;
  sid uuid:=(p_input->>'session_id')::uuid; log_id uuid:=(p_input->>'class_log_id')::uuid;
  v_enrollment_id uuid:=(p_input->>'enrollment_id')::uuid; cs public.class_sessions;
  log_row public.class_logs; previous integer; check_row public.homework_checks;
  key public.admission_command_keys; result jsonb; feedback_value text:=btrim(coalesce(p_input->>'feedback',''));
  submitted_on_value date;
begin
  if actor is null or not public.has_permission('academics.view') or not (public.has_permission('academics.attendance.record') or public.has_permission('academics.sessions.manage')) then raise exception 'Teaching permission required.'; end if;
  if rid is null or sid is null or log_id is null or v_enrollment_id is null then raise exception 'Homework request identity and scope are required.'; end if;
  perform pg_advisory_xact_lock(hashtextextended(rid::text,0));
  select * into key from public.admission_command_keys where request_id=rid;
  if found then
    if key.actor_id<>actor or key.payload<>p_input then raise exception 'Request identity already used for different input.'; end if;
    return key.result;
  end if;
  if not public.can_access_class_session(sid) then raise exception 'This class is outside your assigned scope.'; end if;
  select * into cs from public.class_sessions where id=sid;
  if cs.status<>'SCHEDULED' or (not public.has_permission('academics.sessions.manage') and not exists(select 1 from public.staff st where st.id=cs.teacher_id and st.profile_id=actor)) then raise exception 'Only the assigned teacher may check homework.'; end if;
  select * into log_row from public.class_logs where id=log_id and session_id=sid and status='SUBMITTED' and btrim(homework)<>'';
  if log_row.id is null then raise exception 'Submit the class log with homework before follow-up.'; end if;
  if not exists(select 1 from public.enrollments e where e.id=v_enrollment_id and e.batch_id=cs.batch_id
    and e.admission_date<=cs.session_date and (e.ended_on is null or e.ended_on>cs.session_date)
    and e.status in ('ACTIVE','WITHDRAWN','COMPLETED')) then raise exception 'Student was not on this class roster.'; end if;
  if p_input->>'status' not in ('NOT_SUBMITTED','NEEDS_WORK','COMPLETE') or length(feedback_value)>1000
    or (p_input->>'status'='NEEDS_WORK' and length(feedback_value)<5) then raise exception 'Choose a status and explain work that needs attention.'; end if;
  submitted_on_value:=nullif(p_input->>'submitted_on','')::date;
  if submitted_on_value>current_date or (p_input->>'status'='NOT_SUBMITTED' and submitted_on_value is not null) then raise exception 'Check the homework submission date.'; end if;
  perform pg_advisory_xact_lock(hashtextextended(log_id::text||v_enrollment_id::text,31));
  select coalesce(max(revision),0) into previous from public.homework_checks where class_log_id=log_id and enrollment_id=v_enrollment_id;
  if previous<>coalesce((p_input->>'base_revision')::integer,0) then raise exception 'Homework review changed. Refresh and try again.'; end if;
  insert into public.homework_checks(class_log_id,enrollment_id,revision,status,submitted_on,feedback,recorded_by)
  values(log_id,v_enrollment_id,previous+1,p_input->>'status',submitted_on_value,feedback_value,actor) returning * into check_row;
  result:=jsonb_build_object('id',check_row.id,'revision',check_row.revision);
  insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,after_data)
  values(actor,'HOMEWORK_CHECK',check_row.id::text,'RECORD',to_jsonb(check_row));
  insert into public.admission_command_keys(request_id,actor_id,payload,result) values(rid,actor,p_input,result);
  return result;
end $function$
;

CREATE OR REPLACE FUNCTION public.homework_workspace(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare log_row public.class_logs; session_row public.class_sessions;
begin
  if not public.can_access_class_session(p_session_id) then raise exception 'This class is outside your assigned scope.'; end if;
  select * into session_row from public.class_sessions where id=p_session_id;
  select * into log_row from public.class_logs where session_id=p_session_id and status='SUBMITTED' and btrim(homework)<>'' order by revision desc limit 1;
  return jsonb_build_object(
    'assignment',case when log_row.id is null then null else jsonb_build_object('id',log_row.id,'revision',log_row.revision,'description',log_row.homework,'submittedAt',log_row.submitted_at) end,
    'students',coalesce((select jsonb_agg(jsonb_build_object(
      'enrollmentId',e.id,'studentNo',s.student_no,'name',s.full_name,
      'latestRevision',hc.revision,'status',hc.status,'submittedOn',hc.submitted_on,'feedback',hc.feedback
      ) order by s.student_no)
      from public.enrollments e join public.students s on s.id=e.student_id
      left join lateral (select * from public.homework_checks h where h.class_log_id=log_row.id and h.enrollment_id=e.id order by revision desc limit 1) hc on true
      where log_row.id is not null and e.batch_id=session_row.batch_id and e.admission_date<=session_row.session_date
      and (e.ended_on is null or e.ended_on>session_row.session_date) and e.status in ('ACTIVE','WITHDRAWN','COMPLETED')),'[]'::jsonb),
    'history',coalesce((select jsonb_agg(jsonb_build_object('id',h.id,'enrollmentId',h.enrollment_id,'revision',h.revision,'status',h.status,'submittedOn',h.submitted_on,'feedback',h.feedback,'recordedAt',h.recorded_at) order by h.recorded_at desc)
      from public.homework_checks h where h.class_log_id=log_row.id),'[]'::jsonb)
  );
end $function$
;

CREATE OR REPLACE FUNCTION public.legacy_attendance_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare actor uuid:=auth.uid();sid uuid:=(p_input->>'staff_id')::uuid;request uuid:=(p_input->>'request_id')::uuid;old_key public.admission_command_keys;
 action text:=p_input->>'action';reason text:=btrim(p_input->>'reason');before_data jsonb;after_data jsonb;result jsonb;day date;start_time timestamptz;end_time timestamptz;
begin
 if actor is null or not public.has_permission('workforce.manage') or not exists(select 1 from public.profiles where id=actor and status='ACTIVE') then raise exception 'Workforce management permission required.';end if;
 if request is null or coalesce(length(reason),0)<5 then raise exception 'A request ID and clear reason are required.';end if;
 perform pg_advisory_xact_lock(hashtextextended(request::text,0));
 select * into old_key from public.admission_command_keys where request_id=request;
 if found then if old_key.actor_id<>actor or old_key.payload<>p_input then raise exception 'Request identity conflict.';end if;return old_key.result;end if;
 perform 1 from public.staff where id=sid and status in('ACTIVE','ON_LEAVE') for update;
 if not found then raise exception 'Choose an active staff identity.';end if;
 if action='RECORD_ATTENDANCE' then
  day:=(p_input->>'work_date')::date;
  if day is null or day>(now() at time zone 'Asia/Dhaka')::date then raise exception 'Actual attendance cannot be recorded for a future date.';end if;
  if p_input->>'status'='PRESENT' then
   start_time:=(p_input->>'started_at')::timestamptz;end_time:=(p_input->>'ended_at')::timestamptz;
   if start_time is null or end_time is null or end_time>now() or (start_time at time zone 'Asia/Dhaka')::date<>day then raise exception 'Check the actual start, end and Bangladesh work date.';end if;
  end if;
  if start_time is not null and exists(select 1 from public.staff_attendance_records where staff_id=sid and work_date<>day and status='PRESENT' and started_at<end_time and ended_at>start_time) then raise exception 'These work hours overlap another attendance record.';end if;
  select to_jsonb(a) into before_data from public.staff_attendance_records a where staff_id=sid and work_date=day;
  insert into public.staff_attendance_records(staff_id,work_date,status,started_at,ended_at,break_minutes,recorded_by,reason)
  values(sid,day,p_input->>'status',start_time,end_time,case when p_input->>'status'='PRESENT' then coalesce((p_input->>'break_minutes')::integer,0) else 0 end,actor,reason)
  on conflict(staff_id,work_date) do update set status=excluded.status,started_at=excluded.started_at,ended_at=excluded.ended_at,break_minutes=excluded.break_minutes,recorded_by=actor,reason=excluded.reason,updated_at=now()
  returning to_jsonb(staff_attendance_records.*) into after_data;
 else raise exception 'Unknown workforce action.';end if;
 insert into public.audit_events(actor_profile_id,entity_type,entity_id,action,reason,before_data,after_data,correlation_id)
 values(actor,'STAFF_WORKFORCE',sid::text,action,reason,before_data,after_data,request);
 result:=jsonb_build_object('id',sid,'ok',true);
 insert into public.admission_command_keys(request_id,actor_id,payload,result) values(request,actor,p_input,result);return result;
end $function$
;

CREATE OR REPLACE FUNCTION public.protect_academic_record()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if tg_op='DELETE' then
    raise exception 'Academic history cannot be deleted.';
  end if;

  if tg_table_name='academic_routines' then
    if (to_jsonb(new)-'retired_at') is distinct from (to_jsonb(old)-'retired_at')
      or old.retired_at is not null
      or new.retired_at is null then
      raise exception 'Routine terms are immutable; retire and create a replacement.';
    end if;
  elsif tg_table_name='class_sessions' then
    if (to_jsonb(new)-array[
      'status','cancellation_reason','cancelled_by','cancelled_at'
    ]) is distinct from (to_jsonb(old)-array[
      'status','cancellation_reason','cancelled_by','cancelled_at'
    ])
      or old.status<>'SCHEDULED'
      or new.status<>'CANCELLED' then
      raise exception 'Session schedule is immutable; cancel and create a replacement occurrence.';
    end if;
  else
    if (to_jsonb(new)-array[
      'status','approval_id','reviewer_id','review_note','reviewed_at'
    ]) is distinct from (to_jsonb(old)-array[
      'status','approval_id','reviewer_id','review_note','reviewed_at'
    ]) then
      raise exception 'Attendance evidence is immutable; create a new revision.';
    end if;

    if old.status='DRAFT'
      and new.status='SUBMITTED'
      and new.approval_id is not null
      and new.reviewer_id is null
      and new.reviewed_at is null then
      return new;
    end if;

    if old.status='SUBMITTED'
      and new.status in ('APPROVED','REJECTED')
      and new.approval_id=old.approval_id
      and new.reviewer_id is not null
      and new.reviewed_at is not null
      and length(btrim(coalesce(new.review_note,'')))>=5 then
      if new.reviewer_id=old.recorded_by then
        raise exception 'The submitting teacher cannot review their own attendance.';
      end if;
      return new;
    end if;

    if old.status in ('APPROVED','REJECTED') then
      raise exception 'Reviewed attendance evidence is immutable; create a new revision.';
    end if;

    raise exception 'Attendance evidence transition is not allowed.';
  end if;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.public_academic_directory()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
 select jsonb_build_object('classes',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by sort_order) from public.classes where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'),'programs',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from public.programs where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'),'subjects',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from public.subjects where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'),'schools',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from public.schools where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'),'sources',coalesce((select jsonb_agg(jsonb_build_object('code',code,'name',name)) from public.lead_sources where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'),'relationships',coalesce((select jsonb_agg(jsonb_build_object('code',code,'name',name)) from public.guardian_relationships where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'));
$function$
;

CREATE OR REPLACE FUNCTION public.question_bank_command(p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor uuid := auth.uid(); act text := p_input->>'action'; rid uuid;
  q public.question_bank_items; b public.batches; s public.subjects;
  v_staff_id uuid; v_batch_id uuid; v_subject_id uuid; v_curriculum_id uuid;
  options jsonb; prompt_value text; answer_value text; note text;
  command_key public.admission_command_keys; result jsonb; next_id uuid;
begin
  if actor is null or not public.has_permission('academics.view') then raise exception 'Academic access required.'; end if;
  if p_input is null or jsonb_typeof(p_input)<>'object' then raise exception 'Question command must be an object.'; end if;
  rid := (p_input->>'request_id')::uuid;
  if rid is null then raise exception 'Request identity required.'; end if;
  perform pg_advisory_xact_lock(hashtextextended(rid::text,0));
  select * into command_key from public.admission_command_keys where request_id=rid;
  if found then
    if command_key.actor_id<>actor or command_key.payload<>p_input then raise exception 'Request identity already used for different input.'; end if;
    return command_key.result;
  end if;

  if act='CREATE_DRAFT' then
    if not (public.has_permission('academics.assessments.record') or public.has_permission('academics.sessions.manage')) then raise exception 'Question authoring permission required.'; end if;
    v_batch_id := (p_input->>'batch_id')::uuid;
    v_subject_id := (p_input->>'subject_id')::uuid;
    select * into b from public.batches where id=v_batch_id and is_active;
    select * into s from public.subjects where id=v_subject_id and is_active;
    if b.id is null or s.id is null or b.organization_id<>s.organization_id then raise exception 'Choose an active batch and subject in the same public.'; end if;
    select id into v_staff_id from public.staff where profile_id=actor and status='ACTIVE';
    if not public.has_permission('academics.sessions.manage') and not exists (
      select 1 from public.class_sessions cs
      join public.staff_subject_assignments sa on sa.staff_id=cs.teacher_id and sa.subject_id=cs.subject_id
      where cs.batch_id=v_batch_id and cs.subject_id=v_subject_id and cs.teacher_id=v_staff_id
        and sa.effective_from<=cs.session_date and (sa.effective_to is null or sa.effective_to>=cs.session_date)
    ) then raise exception 'Question scope requires an assigned class and subject qualification.'; end if;
    v_curriculum_id := nullif(p_input->>'curriculum_version_id','')::uuid;
    if v_curriculum_id is not null and not exists(select 1 from public.curriculum_versions cv where cv.id=v_curriculum_id and cv.batch_id=v_batch_id and cv.subject_id=v_subject_id) then raise exception 'Curriculum version must match the batch and subject.'; end if;
    q.root_id := null;
    q.revision := 1;
  else
    select * into q from public.question_bank_items where id=(p_input->>'item_id')::uuid for update;
    if q.id is null then raise exception 'Question not found.'; end if;
    if act in ('EDIT_DRAFT','SUBMIT','REVISE_REJECTED') and q.author_id<>actor then raise exception 'Only the author can change this question.'; end if;
    if act in ('APPROVE','REJECT') then
      if not public.has_permission('academics.assessments.approve') then raise exception 'Question review permission required.'; end if;
      if q.author_id=actor then raise exception 'A question author cannot review their own work.'; end if;
      if q.status<>'SUBMITTED' then raise exception 'Only submitted questions can be reviewed.'; end if;
    elsif act='EDIT_DRAFT' or act='SUBMIT' then
      if q.status<>'DRAFT' then raise exception 'Only a draft can be edited or submitted.'; end if;
    elsif act='REVISE_REJECTED' then
      if q.status<>'REJECTED' then raise exception 'Only a rejected question can start a new revision.'; end if;
      if exists(select 1 from public.question_bank_items newer where newer.root_id=coalesce(q.root_id,q.id) and newer.revision>q.revision) then raise exception 'A newer revision already exists.'; end if;
    else raise exception 'Unknown question action.'; end if;
  end if;

  if act in ('CREATE_DRAFT','EDIT_DRAFT') then
    options := coalesce(p_input->'choices','[]'::jsonb);
    prompt_value := btrim(coalesce(p_input->>'prompt',''));
    answer_value := btrim(coalesce(p_input->>'answer_key',''));
    if length(prompt_value) not between 10 and 3000 or length(answer_value) not between 1 and 1500
      or length(btrim(coalesce(p_input->>'topic',''))) not between 2 and 180
      or coalesce(length(p_input->>'explanation'),0)>3000
      or p_input->>'difficulty' not in ('FOUNDATION','STANDARD','ADVANCED')
      or p_input->>'question_type' not in ('MCQ','SHORT_ANSWER') then raise exception 'Check the question content and difficulty.'; end if;
    if jsonb_typeof(options)<>'array' or jsonb_array_length(options)>6
      or exists(select 1 from jsonb_array_elements(options) e where jsonb_typeof(e)<>'string' or length(btrim(e#>>'{}')) not between 1 and 500) then raise exception 'Invalid answer choices.'; end if;
    if p_input->>'question_type'='MCQ' and (jsonb_array_length(options)<2 or answer_value not in ('A','B','C','D','E','F')
      or ascii(answer_value)-64>jsonb_array_length(options)) then raise exception 'MCQ needs choices and a matching answer key (A–F).'; end if;
    if p_input->>'question_type'='SHORT_ANSWER' and jsonb_array_length(options)<>0 then raise exception 'Short answers cannot have MCQ choices.'; end if;
    if act='CREATE_DRAFT' then
      insert into public.question_bank_items(batch_id,subject_id,curriculum_version_id,topic,difficulty,question_type,prompt,choices,answer_key,explanation,author_id)
      values(v_batch_id,v_subject_id,v_curriculum_id,btrim(p_input->>'topic'),p_input->>'difficulty',p_input->>'question_type',prompt_value,options,answer_value,nullif(btrim(coalesce(p_input->>'explanation','')),''),actor) returning * into q;
    else
      update public.question_bank_items set topic=btrim(p_input->>'topic'),difficulty=p_input->>'difficulty',question_type=p_input->>'question_type',prompt=prompt_value,choices=options,answer_key=answer_value,explanation=nullif(btrim(coalesce(p_input->>'explanation','')),'') where id=q.id returning * into q;
    end if;
  elsif act='REVISE_REJECTED' then
    insert into public.question_bank_items(root_id,revision,batch_id,subject_id,curriculum_version_id,topic,difficulty,question_type,prompt,choices,answer_key,explanation,author_id)
    values(coalesce(q.root_id,q.id),q.revision+1,q.batch_id,q.subject_id,q.curriculum_version_id,q.topic,q.difficulty,q.question_type,q.prompt,q.choices,q.answer_key,q.explanation,actor) returning * into q;
  elsif act='SUBMIT' then
    update public.question_bank_items set status='SUBMITTED',submitted_at=now() where id=q.id returning * into q;
  else
    note := btrim(coalesce(p_input->>'review_note',''));
    if length(note)<5 or length(note)>1000 then raise exception 'Give a review reason (5–1000 characters).'; end if;
    update public.question_bank_items set status=case when act='APPROVE' then 'APPROVED' else 'REJECTED' end,
      reviewer_id=actor,review_note=note,reviewed_at=now() where id=q.id returning * into q;
  end if;
  result := jsonb_build_object('id',q.id,'status',q.status,'revision',q.revision);
  insert into public.audit_events(actor_profile_id,branch_id,entity_type,entity_id,action,reason,after_data)
  values(actor,(select branch_id from public.batches where id=q.batch_id),'QUESTION_BANK_ITEM',q.id::text,act,
    case when act in ('APPROVE','REJECT') then note else null end,to_jsonb(q));
  insert into public.admission_command_keys(request_id,actor_id,payload,result) values(rid,actor,p_input,result);
  return result;
end $function$
;

CREATE OR REPLACE FUNCTION public.question_bank_workspace()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare actor uuid := auth.uid(); reviewer boolean;
begin
  if actor is null or not public.has_permission('academics.view') then raise exception 'Academic access required.'; end if;
  reviewer := public.has_permission('academics.assessments.approve');
  return jsonb_build_object(
    'batches', coalesce((select jsonb_agg(jsonb_build_object('id',b.id,'name',b.name) order by b.name)
      from public.batches b where b.is_active and (reviewer or public.has_permission('academics.sessions.manage')
        or exists (select 1 from public.class_sessions cs join public.staff st on st.id=cs.teacher_id
          where cs.batch_id=b.id and st.profile_id=actor))), '[]'::jsonb),
    'subjects', coalesce((select jsonb_agg(jsonb_build_object('id',s.id,'name',s.name) order by s.name)
      from public.subjects s where s.is_active and (reviewer or public.has_permission('academics.sessions.manage')
        or exists (select 1 from public.staff_subject_assignments sa join public.staff st on st.id=sa.staff_id
          where sa.subject_id=s.id and st.profile_id=actor and sa.effective_from<=current_date
            and (sa.effective_to is null or sa.effective_to>=current_date)))), '[]'::jsonb),
    'items', coalesce((select jsonb_agg(jsonb_build_object(
      'id',q.id,'rootId',q.root_id,'revision',q.revision,'batchId',q.batch_id,'batch',b.name,
      'subjectId',q.subject_id,'subject',s.name,'curriculumVersionId',q.curriculum_version_id,
      'topic',q.topic,'difficulty',q.difficulty,'questionType',q.question_type,
      'prompt',q.prompt,'choices',q.choices,'answerKey',q.answer_key,'explanation',q.explanation,
      'status',q.status,'authorId',q.author_id,'author',p.display_name,'reviewNote',q.review_note,
      'createdAt',q.created_at) order by q.created_at desc)
      from public.question_bank_items q
      join public.batches b on b.id=q.batch_id
      join public.subjects s on s.id=q.subject_id
      join public.profiles p on p.id=q.author_id
      where q.author_id=actor or reviewer), '[]'::jsonb)
  );
end $function$
;

set check_function_bodies=true;
