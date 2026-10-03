-- Sohoj CRM presentation adapted to the fresh Outlinerz tenant model.
-- Forward migration: baseline 01 and existing customer data remain intact.
begin;
alter table public.class_levels add column code text;
create unique index class_levels_crm_code on public.class_levels(organization_id,code);
alter table public.class_groups add column code text;
create unique index class_groups_crm_code on public.class_groups(organization_id,code);
alter table public.subjects add column code text;
create unique index subjects_crm_code on public.subjects(organization_id,code);
alter table public.programmes add column code text;
create unique index programmes_crm_code on public.programmes(organization_id,code);
alter table public.class_levels add column sort_order integer not null default 100;
create table public.areas (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
 name text not null check(length(trim(name)) between 1 and 180), code text,
 active boolean not null default true, created_at timestamptz not null default now(),
  unique(organization_id,id), unique(organization_id,name), unique(organization_id,code)
);
alter table public.areas enable row level security;
revoke all on public.areas from anon,authenticated;
grant select,insert,update on public.areas to authenticated;
create policy crm_read on public.areas for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']));
create policy crm_insert on public.areas for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN']) and app_private.module_enabled(organization_id,'CRM'));
create policy crm_update on public.areas for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']) and app_private.module_enabled(organization_id,'CRM')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN']) and app_private.module_enabled(organization_id,'CRM'));
create trigger identity_guard before update on public.areas for each row execute function app_private.protect_identity();
create trigger audit after insert or update on public.areas for each row execute function app_private.audit_row();
create table public.schools (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
 name text not null check(length(trim(name)) between 1 and 180), code text,
 active boolean not null default true, created_at timestamptz not null default now(),
 area_id uuid, is_verified boolean not null default false, foreign key(organization_id,area_id) references public.areas(organization_id,id), unique(organization_id,id), unique(organization_id,name), unique(organization_id,code)
);
alter table public.schools enable row level security;
revoke all on public.schools from anon,authenticated;
grant select,insert,update on public.schools to authenticated;
create policy crm_read on public.schools for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']));
create policy crm_insert on public.schools for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN']) and app_private.module_enabled(organization_id,'CRM'));
create policy crm_update on public.schools for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']) and app_private.module_enabled(organization_id,'CRM')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN']) and app_private.module_enabled(organization_id,'CRM'));
create trigger identity_guard before update on public.schools for each row execute function app_private.protect_identity();
create trigger audit after insert or update on public.schools for each row execute function app_private.audit_row();
create table public.lead_sources (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
 name text not null check(length(trim(name)) between 1 and 180), code text,
 active boolean not null default true, created_at timestamptz not null default now(),
  unique(organization_id,id), unique(organization_id,name), unique(organization_id,code)
);
alter table public.lead_sources enable row level security;
revoke all on public.lead_sources from anon,authenticated;
grant select,insert,update on public.lead_sources to authenticated;
create policy crm_read on public.lead_sources for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']));
create policy crm_insert on public.lead_sources for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN']) and app_private.module_enabled(organization_id,'CRM'));
create policy crm_update on public.lead_sources for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']) and app_private.module_enabled(organization_id,'CRM')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN']) and app_private.module_enabled(organization_id,'CRM'));
create trigger identity_guard before update on public.lead_sources for each row execute function app_private.protect_identity();
create trigger audit after insert or update on public.lead_sources for each row execute function app_private.audit_row();
create table public.guardian_relationships (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
 name text not null check(length(trim(name)) between 1 and 180), code text,
 active boolean not null default true, created_at timestamptz not null default now(),
  unique(organization_id,id), unique(organization_id,name), unique(organization_id,code)
);
alter table public.guardian_relationships enable row level security;
revoke all on public.guardian_relationships from anon,authenticated;
grant select,insert,update on public.guardian_relationships to authenticated;
create policy crm_read on public.guardian_relationships for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN','ACADEMIC','OPERATOR']));
create policy crm_insert on public.guardian_relationships for insert to authenticated with check(app_private.has_role(organization_id,array['OWNER','ADMIN']) and app_private.module_enabled(organization_id,'CRM'));
create policy crm_update on public.guardian_relationships for update to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']) and app_private.module_enabled(organization_id,'CRM')) with check(app_private.has_role(organization_id,array['OWNER','ADMIN']) and app_private.module_enabled(organization_id,'CRM'));
create trigger identity_guard before update on public.guardian_relationships for each row execute function app_private.protect_identity();
create trigger audit after insert or update on public.guardian_relationships for each row execute function app_private.audit_row();
alter table public.prospects
 add column application_snapshot jsonb not null default '{}' check(jsonb_typeof(application_snapshot)='object'),
 add column school_id uuid,
 add column assigned_user_id uuid,
 add column next_follow_up_at timestamptz,
 add column submission_intent text not null default 'interest' check(submission_intent in ('interest','admission')),
 add foreign key(organization_id,school_id) references public.schools(organization_id,id),
 add foreign key(organization_id,assigned_user_id) references public.memberships(organization_id,user_id);
alter table public.followups
 add column followup_type text not null default 'OTHER' check(followup_type in ('CALL','WHATSAPP','IN_PERSON','COUNSELLING','TRIAL','OTHER')),
 add column outcome text,
 add column recorded_by uuid,
 add column next_follow_up_at timestamptz,
 add foreign key(organization_id,recorded_by) references public.memberships(organization_id,user_id);

create function public.crm_assign(p_org uuid,p_prospect uuid,p_user uuid) returns void
language plpgsql security definer set search_path='' as $$
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','OPERATOR']);
 perform app_private.require_module(p_org,'CRM');
 if p_user is not null and not exists(select 1 from public.memberships where organization_id=p_org and user_id=p_user and active and role in ('OWNER','ADMIN','OPERATOR')) then raise exception 'Invalid assignee'; end if;
 update public.prospects set assigned_user_id=p_user where organization_id=p_org and id=p_prospect;
 if not found then raise exception 'Prospect not found'; end if;
 if p_user is not null then update public.followups set assigned_user_id=p_user where organization_id=p_org and prospect_id=p_prospect and completed_at is null; end if;
end $$;
create function public.crm_followup(p_org uuid,p_request uuid,p_input jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r jsonb; p public.prospects; next_time timestamptz; new_stage text;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN','OPERATOR']);
 perform app_private.require_module(p_org,'CRM');
 r:=app_private.begin_command(p_org,p_request,'crm_followup',p_input); if r is not null then return r; end if;
 select * into p from public.prospects where organization_id=p_org and id=(p_input->>'prospect_id')::uuid for update;
 if not found or p.stage='ADMITTED' then raise exception 'Prospect is unavailable for follow-up'; end if;
 new_stage:=p_input->>'stage';
 if new_stage is null or new_stage not in ('NEW','CONTACTED','INTERESTED','LOST') or length(trim(coalesce(p_input->>'note','')))<2 then raise exception 'Invalid follow-up'; end if;
 next_time:=nullif(p_input->>'next_follow_up_at','')::timestamptz;
 update public.followups set completed_at=now(),recorded_by=auth.uid() where organization_id=p_org and prospect_id=p.id and completed_at is null;
 insert into public.followups(organization_id,prospect_id,assigned_user_id,due_at,note,completed_at,followup_type,outcome,recorded_by,next_follow_up_at)
 values(p_org,p.id,coalesce(p.assigned_user_id,auth.uid()),now(),p_input->>'note',now(),p_input->>'followup_type',p_input->>'outcome',auth.uid(),next_time);
 if next_time is not null then
 insert into public.followups(organization_id,prospect_id,assigned_user_id,due_at,note)
 values(p_org,p.id,coalesce(p.assigned_user_id,auth.uid()),next_time,'Scheduled follow-up');
 end if;
 update public.prospects set stage=new_stage,lost_reason=case when new_stage='LOST' then p_input->>'lost_reason' else null end,next_follow_up_at=next_time where id=p.id;
 return app_private.end_command(p_org,p_request,jsonb_build_object('stage',new_stage));
end $$;

create function public.crm_master(p_org uuid,p_request uuid,p_input jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare tab text; row_id uuid; rec jsonb; changes jsonb; r jsonb; entity text:=p_input->>'entity';
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN']);perform app_private.require_module(p_org,'CRM');
 r:=app_private.begin_command(p_org,p_request,'crm_master',p_input);if r is not null then return r;end if;
 tab:=case entity when 'academic_year' then 'academic_years' when 'class' then 'class_levels' when 'group' then 'class_groups' when 'subject' then 'subjects' when 'program' then 'programmes' when 'school' then 'schools' when 'lead_source' then 'lead_sources' when 'guardian_relationship' then 'guardian_relationships' end;
 if tab is null or length(trim(coalesce(p_input->>'name','')))<1 or length(trim(coalesce(p_input->>'reason','')))<5 then raise exception 'Invalid directory details';end if;
 changes:=jsonb_build_object('name',trim(p_input->>'name'),'active',(p_input->>'isActive')::boolean);
 if entity='academic_year' then changes:=changes||jsonb_build_object('starts_on',p_input->>'startsOn','ends_on',p_input->>'endsOn');
 elsif entity='school' then changes:=changes||jsonb_build_object('area_id',nullif(p_input->>'areaId',''),'is_verified',coalesce((p_input->>'isVerified')::boolean,false));
 else
 if coalesce(p_input->>'code','') !~ '^[A-Za-z0-9_-]{1,40}$' then raise exception 'Invalid code';end if;
 changes:=changes||jsonb_build_object('code',upper(trim(p_input->>'code')));
 end if;
 if entity='class' then changes:=changes||jsonb_build_object('sort_order',coalesce((p_input->>'sortOrder')::integer,100));end if;
 if entity='program' then changes:=changes||jsonb_build_object('description',p_input->>'description');end if;
 row_id:=nullif(p_input->>'id','')::uuid;
 if row_id is null then
 row_id:=gen_random_uuid();rec:=jsonb_build_object('id',row_id,'organization_id',p_org,'created_at',now())||changes;
 execute format('insert into public.%I select (jsonb_populate_record(null::public.%I,$1)).*',tab,tab) using rec;
 else
 execute format('select to_jsonb(t) from public.%I t where organization_id=$1 and id=$2 for update',tab) into rec using p_org,row_id;
 if rec is null then raise exception 'Record not found';end if;
 rec:=rec||changes;
 -- Only explicitly allowed columns are updated; identity and tenant stay immutable.
 execute format('update public.%I set name=$1,active=$2 where organization_id=$3 and id=$4',tab) using rec->>'name',(rec->>'active')::boolean,p_org,row_id;
 if entity='academic_year' then execute 'update public.academic_years set starts_on=$1,ends_on=$2 where organization_id=$3 and id=$4' using (rec->>'starts_on')::date,(rec->>'ends_on')::date,p_org,row_id;
 elsif entity='school' then execute 'update public.schools set area_id=$1,is_verified=$2 where organization_id=$3 and id=$4' using nullif(rec->>'area_id','')::uuid,(rec->>'is_verified')::boolean,p_org,row_id;
 else execute format('update public.%I set code=$1 where organization_id=$2 and id=$3',tab) using rec->>'code',p_org,row_id;
 end if;
 if entity='class' then update public.class_levels set sort_order=(rec->>'sort_order')::integer where organization_id=p_org and id=row_id;end if;
 if entity='program' then update public.programmes set description=rec->>'description' where organization_id=p_org and id=row_id;end if;
 end if;
 return app_private.end_command(p_org,p_request,jsonb_build_object('id',row_id));
end $$;
revoke all on function public.crm_master(uuid,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.crm_master(uuid,uuid,jsonb) to authenticated;

-- Explicit anonymous projections; no grants on tenant directories or prospects.
create function public.crm_public_options(p_slug text) returns jsonb
language sql stable security definer set search_path='' as $$
 select jsonb_build_object(
 'organization',jsonb_build_object('name',o.name,'slug',o.slug),
 'classes',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by sort_order,name) from public.class_levels where organization_id=o.id and active),'[]'),
 'programs',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from public.programmes where organization_id=o.id and active),'[]'),
 'subjects',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from public.subjects where organization_id=o.id and active),'[]'),
 'schools',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from public.schools where organization_id=o.id and active),'[]'),
 'sources',coalesce((select jsonb_agg(jsonb_build_object('code',code,'name',name) order by name) from public.lead_sources where organization_id=o.id and active and code is not null),'[]'),
 'relationships',coalesce((select jsonb_agg(jsonb_build_object('code',code,'name',name) order by name) from public.guardian_relationships where organization_id=o.id and active and code is not null),'[]'))
 from public.organizations o where o.slug=p_slug and app_private.module_enabled(o.id,'CRM');
$$;
create function public.crm_public_catalogue(p_slug text) returns jsonb
language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(card order by card->>'name'),'[]') from (
 select jsonb_build_object(
 'id',f.id,'code',f.code,'name',f.name,'class_id',f.class_level_id,'program_id',f.programme_id,'group_id',f.class_group_id,
 'branch_id',f.branch_id,'academic_year_id',f.academic_year_id,'academic_year_name',y.name,'branch_name',b.name,'class_name',c.name,'group_name',g.name,
 'showcase_title',f.public_copy->>'showcase_title','showcase_title_bn',f.public_copy->>'showcase_title_bn',
 'showcase_description',f.public_copy->>'showcase_description','showcase_description_bn',f.public_copy->>'showcase_description_bn',
 'showcase_eyebrow',f.public_copy->>'showcase_eyebrow','showcase_eyebrow_bn',f.public_copy->>'showcase_eyebrow_bn','showcase_icon',f.public_copy->>'showcase_icon',
 'public_schedule',f.public_copy->>'public_schedule','public_schedule_bn',f.public_copy->>'public_schedule_bn',
 'public_requirements',f.public_copy->>'public_requirements','public_requirements_bn',f.public_copy->>'public_requirements_bn',
 'admission_policy',f.public_copy->>'admission_policy','admission_policy_bn',f.public_copy->>'admission_policy_bn',
 'active_batch_count',(select count(*) from public.batches where organization_id=o.id and offering_id=f.id and active),
 'current_total_seats',(select coalesce(sum(capacity),0) from public.batches where organization_id=o.id and offering_id=f.id and active),
 'current_open_seats',(select coalesce(sum(greatest(0,x.capacity-(select count(*) from public.enrollments e where e.organization_id=o.id and e.batch_id=x.id and e.status='ACTIVE'))),0) from public.batches x where x.organization_id=o.id and x.offering_id=f.id and x.active),
 'showcase_sort_order',0,'is_accepting_applications',f.intake_open,'application_state',case when f.intake_open then 'OPEN' else 'CLOSED' end,
 'applications_open_on',null,'applications_close_on',null,'created_at',f.created_at,
 'subjects',coalesce((select jsonb_agg(jsonb_build_object('id',s.id,'code',coalesce(s.code,''),'name',s.name)) from public.offering_subjects os join public.subjects s on s.organization_id=os.organization_id and s.id=os.subject_id where os.organization_id=o.id and os.offering_id=f.id),'[]'),
 'fee_plan',(select jsonb_build_object('billing_cycle',t.frequency,'currency_code',o.currency,'components',jsonb_build_array(jsonb_build_object('code','TUITION','name','Tuition','amount',t.amount,'charge_type','TUITION','recurrence',t.frequency))) from public.fee_terms t where t.organization_id=o.id and t.offering_id=f.id and t.active and t.effective_on<=current_date order by t.effective_on desc limit 1)) card
 from public.offerings f join public.organizations o on o.id=f.organization_id
 join public.academic_years y on y.organization_id=o.id and y.id=f.academic_year_id
 join public.branches b on b.organization_id=o.id and b.id=f.branch_id
 join public.class_levels c on c.organization_id=o.id and c.id=f.class_level_id
 left join public.class_groups g on g.organization_id=o.id and g.id=f.class_group_id
 where o.slug=p_slug and f.active and f.public_visible and app_private.module_enabled(o.id,'CRM') and app_private.module_enabled(o.id,'ACADEMIC')
 ) cards;
$$;

create function public.crm_public_interest(p_slug text,p_request uuid,p_payload jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare o uuid; r jsonb; pid uuid; snap jsonb; offering public.offerings; class_name text; now_hour timestamptz:=date_trunc('hour',now());
begin
 select id into o from public.organizations where slug=p_slug;
 if o is null then raise exception 'Registration unavailable'; end if;
 perform app_private.require_module(o,'CRM');
 if octet_length(p_payload::text)>20000 or length(trim(coalesce(p_payload->>'studentName','')))<2 or length(trim(coalesce(p_payload->>'guardianName','')))<2 or coalesce(p_payload->>'mobile','') !~ '^[+0-9 ()-]{10,30}$' then raise exception 'Invalid registration'; end if;
 r:=app_private.begin_command(o,p_request,'crm_public_interest',p_payload); if r is not null then return r; end if;
 -- Serialized tenant limits apply even when callers bypass the web form.
 perform pg_advisory_xact_lock(hashtextextended(o::text,0));
 if (select count(*) from public.prospects where organization_id=o and created_at>=now_hour and source='PUBLIC_FORM')>=100 or
 (select count(*) from public.prospects where organization_id=o and created_at>=now()-interval '1 hour' and phone=p_payload->>'mobile' and source='PUBLIC_FORM')>=3 then raise exception 'Too many requests. Try later'; end if;
 select name into class_name from public.class_levels where organization_id=o and id=(p_payload->>'classId')::uuid and active;
 if class_name is null then raise exception 'Invalid class'; end if;
 if nullif(p_payload->>'offeringId','') is not null then
 select * into offering from public.offerings where organization_id=o and id=(p_payload->>'offeringId')::uuid and active and public_visible and intake_open for share;
 if not found then raise exception 'Applications closed'; end if;
 elsif p_payload->>'intent'='admission' then raise exception 'Choose an open offering'; end if;
 if nullif(p_payload->>'schoolId','') is not null and not exists(select 1 from public.schools where organization_id=o and id=(p_payload->>'schoolId')::uuid and active) then raise exception 'Invalid school'; end if;
 if exists(select 1 from jsonb_array_elements_text(coalesce(p_payload->'programIds','[]')) x(id) where not exists(select 1 from public.programmes where organization_id=o and id=x.id::uuid and active)) or
 exists(select 1 from jsonb_array_elements_text(coalesce(p_payload->'subjectIds','[]')) x(id) where not exists(select 1 from public.subjects where organization_id=o and id=x.id::uuid and active)) then raise exception 'Invalid academic choices'; end if;
 snap:=p_payload||jsonb_build_object('class_label',class_name,'offering_label',offering.name,
 'schoolNameSnapshot',coalesce((select name from public.schools where organization_id=o and id=nullif(p_payload->>'schoolId','')::uuid),p_payload->>'schoolNameSnapshot'),
 'program_labels',coalesce((select jsonb_agg(name order by name) from public.programmes where organization_id=o and id in (select value::uuid from jsonb_array_elements_text(coalesce(p_payload->'programIds','[]')))),'[]'),
 'subject_labels',coalesce((select jsonb_agg(name order by name) from public.subjects where organization_id=o and id in (select value::uuid from jsonb_array_elements_text(coalesce(p_payload->'subjectIds','[]')))),'[]'));
 insert into public.prospects(organization_id,student_name,guardian_name,phone,class_level_id,offering_id,school_id,source,submission_intent,notes,application_snapshot)
 values(o,p_payload->>'studentName',p_payload->>'guardianName',p_payload->>'mobile',(p_payload->>'classId')::uuid,offering.id,nullif(p_payload->>'schoolId','')::uuid,'PUBLIC_FORM',coalesce(p_payload->>'intent','interest'),p_payload->>'notes',snap) returning id into pid;
 return app_private.end_command(o,p_request,jsonb_build_object('prospect_no',upper(left(pid::text,8))));
end $$;
revoke all on function public.crm_assign(uuid,uuid,uuid),public.crm_followup(uuid,uuid,jsonb),public.crm_public_options(text),public.crm_public_catalogue(text),public.crm_public_interest(text,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.crm_assign(uuid,uuid,uuid),public.crm_followup(uuid,uuid,jsonb) to authenticated;
grant execute on function public.crm_public_options(text),public.crm_public_catalogue(text),public.crm_public_interest(text,uuid,jsonb) to anon,authenticated;
create function app_private.protect_completed_followup() returns trigger language plpgsql set search_path='' as $$
begin
 if old.completed_at is not null then raise exception 'Completed follow-up history is immutable'; end if;
 return case when TG_OP='DELETE' then old else new end;
end $$;
create trigger followup_history_guard before update or delete on public.followups for each row execute function app_private.protect_completed_followup();
revoke all on function app_private.protect_completed_followup() from public,anon,authenticated;
commit;
