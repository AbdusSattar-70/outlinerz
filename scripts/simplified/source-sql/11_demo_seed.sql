-- Demo records are created atomically when a verified owner opens a branch.
-- No synthetic Auth users, passwords, financial records or cross-branch IDs.
create function public.seed_demo_branch() returns void language plpgsql security definer set search_path=pg_catalog,public as $$
declare branch uuid:=academy_private.current_branch_id(); b record; i integer; n integer:=0; intake jsonb; aid uuid; teacher jsonb; tid uuid; room jsonb; subject uuid; subjects jsonb; begin
 if branch is null or not public.has_permission('system.users.manage') then raise exception 'Branch administrator required.';end if;
 if exists(select 1 from public.audit_events where scope_branch_id=branch and action='SEED_DEMO') then return;end if;
 select jsonb_agg(id) into subjects from public.subjects where scope_branch_id=branch;
 teacher:=public.create_staff_member(jsonb_build_object('full_name','DEMO — Ayesha Rahman','staff_role_code','TEACHER','mobile','01900000001','subject_ids',subjects,'notes','Demo record for testing; no login account.'));
 tid:=(teacher->>'staff_id')::uuid;
 perform public.create_staff_member(jsonb_build_object('full_name','DEMO — Hasan Ahmed','staff_role_code','TEACHER','mobile','01900000002','subject_ids',subjects,'notes','Demo record for testing; no login account.'));
 room:=public.academic_command(jsonb_build_object('request_id',gen_random_uuid(),'action','CREATE_ROOM','reason','Demo academic setup','branch_id',branch,'name','DEMO Classroom','capacity',12));
 for b in select * from public.batches where scope_branch_id=branch order by code loop
  for i in 1..2 loop
   n:=n+1;
   intake:=public.create_staff_admission_intake(jsonb_build_object('request_id',gen_random_uuid(),'student_name','DEMO Student '||n,'guardian_name','DEMO Guardian '||n,'mobile','017000000'||lpad(n::text,2,'0'),'guardian_address','Demo address — replace before real use','consent_to_contact',true,'offering_id',b.offering_id,'batch_id',b.id,'reason','Demo seed for testing'));
   aid:=(intake->>'admission_id')::uuid;
   perform public.admission_command(jsonb_build_object('request_id',gen_random_uuid(),'action','READY','admission_id',aid,'reason','Demo verified placement'));
   perform public.admission_command(jsonb_build_object('request_id',gen_random_uuid(),'action','FINALIZE','admission_id',aid,'reason','Demo academic enrollment'));
  end loop;
  select subject_id into subject from public.programme_offering_subjects where offering_id=b.offering_id order by sort_order limit 1;
  perform public.academic_command(jsonb_build_object('request_id',gen_random_uuid(),'action','CREATE_SESSION','reason','Demo lesson','batch_id',b.id,'subject_id',subject,'teacher_id',tid,'room_id',room->>'id','starts_on',current_date+n/2,'start_time','18:00','end_time','19:00','planned_scope','DEMO lesson — edit before real use'));
 end loop;
 update public.programme_offerings set is_website_visible=true,is_accepting_applications=true where scope_branch_id=branch;
 insert into public.audit_events(actor_profile_id,branch_id,entity_type,entity_id,action,reason) values(auth.uid(),branch,'BRANCH',branch::text,'SEED_DEMO','Demo students, teachers, room and lessons; no finance or login accounts.');
end $$;
revoke all on function public.seed_demo_branch() from public,anon,authenticated;
