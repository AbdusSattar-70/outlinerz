set search_path=academy,extensions,public;
create function academy_private.public_branch_id() returns uuid language sql stable security definer set search_path=pg_catalog,academy as $$
 select id from academy.branches where slug=coalesce(nullif(current_setting('request.headers',true),''),'{}')::jsonb->>'x-academy-public-branch' and is_active;
$$;
create function academy.public_academic_directory() returns jsonb language sql stable security definer set search_path=pg_catalog,academy as $$
 select jsonb_build_object('classes',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by sort_order) from academy.classes where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'),'programs',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from academy.programs where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'),'subjects',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from academy.subjects where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'),'schools',coalesce((select jsonb_agg(jsonb_build_object('id',id,'name',name) order by name) from academy.schools where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'),'sources',coalesce((select jsonb_agg(jsonb_build_object('code',code,'name',name)) from academy.lead_sources where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'),'relationships',coalesce((select jsonb_agg(jsonb_build_object('code',code,'name',name)) from academy.guardian_relationships where scope_branch_id=academy_private.public_branch_id() and is_active),'[]'));
$$;
create or replace function academy.submit_public_interest(p_payload jsonb) returns jsonb language plpgsql security definer set search_path=pg_catalog,academy as $$
declare branch academy.branches;chosen academy.programme_offerings;prospect academy.prospects;mobile_value text;item text;today date;prior text:=current_setting('academy.branch_override',true);begin
 select * into branch from academy.branches where id=academy_private.public_branch_id() and is_active;
 if branch.id is null then raise exception 'The academy is not accepting applications yet.';end if;
 if jsonb_typeof(p_payload) is distinct from 'object' or octet_length(p_payload::text)>16000 or length(btrim(coalesce(p_payload->>'student_name','')))<2 or length(btrim(coalesce(p_payload->>'guardian_name','')))<2 then raise exception 'Enter valid student and guardian names.';end if;
 mobile_value:=regexp_replace(coalesce(p_payload->>'mobile',''),'\D','','g');if mobile_value!~'^01[3-9][0-9]{8}$' then raise exception 'A valid mobile number is required.';end if;
 if not coalesce((p_payload->>'consent_to_contact')::boolean,false) then raise exception 'Consent to contact is required.';end if;
 if not exists(select 1 from academy.classes where id=nullif(p_payload->>'class_id','')::uuid and scope_branch_id=branch.id and is_active) then raise exception 'Selected class is not available.';end if;
 if nullif(p_payload->>'school_id','') is not null and not exists(select 1 from academy.schools where id=(p_payload->>'school_id')::uuid and scope_branch_id=branch.id and is_active) then raise exception 'Selected school is not available.';end if;
 for item in select jsonb_array_elements_text(coalesce(p_payload->'program_ids','[]')) loop if not exists(select 1 from academy.programs where id=item::uuid and scope_branch_id=branch.id and is_active) then raise exception 'One selected program is not available.';end if;end loop;
 for item in select jsonb_array_elements_text(coalesce(p_payload->'subject_ids','[]')) loop if not exists(select 1 from academy.subjects where id=item::uuid and scope_branch_id=branch.id and is_active) then raise exception 'One selected subject is not available.';end if;end loop;
 if nullif(p_payload->>'offering_id','') is not null or p_payload->>'intent'='admission' then
  select * into chosen from academy.programme_offerings where id=nullif(p_payload->>'offering_id','')::uuid and scope_branch_id=branch.id and status='ACTIVE' and is_website_visible;
  if chosen.id is null then raise exception 'Selected programme offering is not available.';end if;
  today:=timezone(branch.timezone,now())::date;
  if not chosen.is_accepting_applications or chosen.applications_open_on>today or chosen.applications_close_on<today then raise exception 'Applications are closed for this programme offering.';end if;
  if chosen.class_id<>(p_payload->>'class_id')::uuid then raise exception 'Selected class does not match the chosen programme offering.';end if;
  for item in select jsonb_array_elements_text(coalesce(p_payload->'subject_ids','[]')) loop if not exists(select 1 from academy.programme_offering_subjects where offering_id=chosen.id and subject_id=item::uuid) then raise exception 'One selected subject is not part of the chosen programme offering.';end if;end loop;
 end if;
 perform pg_advisory_xact_lock(hashtextextended(branch.id::text||mobile_value,3));
 if exists(select 1 from academy.prospects where scope_branch_id=branch.id and mobile=mobile_value and lower(student_name)=lower(btrim(p_payload->>'student_name')) and created_at>now()-interval '2 minutes') then raise exception 'A similar interest request was submitted recently. Please wait before submitting again.';end if;
 -- Explicit scope is mandatory for anonymous projection/intake; no operational read grants.
 insert into academy.prospects(scope_branch_id,organization_id,branch_id,student_name,student_name_bn,guardian_name,guardian_relationship_snapshot,mobile,alternate_mobile,current_class_id,interested_offering_id,school_id,school_name_snapshot,area_snapshot,guardian_address,notes,referral_note,consent_to_contact,submitted_via,submission_intent,application_snapshot,date_of_birth,gender,school_roll)
 values(branch.id,branch.organization_id,branch.id,btrim(p_payload->>'student_name'),nullif(p_payload->>'student_name_bn',''),btrim(p_payload->>'guardian_name'),p_payload->>'guardian_relationship',mobile_value,nullif(p_payload->>'alternate_mobile',''),(p_payload->>'class_id')::uuid,chosen.id,nullif(p_payload->>'school_id','')::uuid,nullif(p_payload->>'school_name_snapshot',''),p_payload->>'area',p_payload->>'guardian_address',p_payload->>'notes',p_payload->>'referral_note',true,'PUBLIC_WEB',case when p_payload->>'intent'='admission' then 'admission' else 'interest' end,p_payload||'{"verification":"UNVERIFIED"}'::jsonb,nullif(p_payload->>'date_of_birth','')::date,nullif(p_payload->>'gender',''),nullif(p_payload->>'school_roll','')) returning * into prospect;
 insert into academy.audit_events(scope_branch_id,branch_id,entity_type,entity_id,action,metadata) values(branch.id,branch.id,'PROSPECT',prospect.id::text,'RECEIVE_UNVERIFIED_APPLICATION','{"verification":"UNVERIFIED"}');
 return jsonb_build_object('prospect_no',prospect.prospect_no);
end $$;
revoke all on function academy.public_academic_directory(),academy.submit_public_interest(jsonb) from public;
grant execute on function academy.public_academic_directory(),academy.submit_public_interest(jsonb) to anon,authenticated;
reset search_path;

set search_path=academy,extensions,public;
CREATE OR REPLACE FUNCTION academy.list_public_programme_offerings()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'academy'
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
      (select count(*)::integer from academy.batches bb where bb.offering_id=o.id and bb.is_active) as active_batch_count,
      (select coalesce(sum(bb.capacity),0)::integer from academy.batches bb where bb.offering_id=o.id and bb.is_active) as current_total_seats,
      (select coalesce(sum(greatest(bb.capacity-(select count(*) from academy.enrollments e where e.batch_id=bb.id and e.status='ACTIVE'),0)),0)::integer
       from academy.batches bb where bb.offering_id=o.id and bb.is_active) as current_open_seats,
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
       from academy.programme_offering_subjects pos
       join academy.subjects s on s.id = pos.subject_id
       where pos.offering_id = o.id and s.is_active) as subjects,
      (select jsonb_build_object('billing_cycle', fp.billing_cycle,
        'currency_code', fp.currency_code,
        'components', coalesce((select jsonb_agg(jsonb_build_object(
          'code', fc.code, 'name', fc.name, 'amount', fc.amount,
          'charge_type', fc.charge_type, 'recurrence', fc.recurrence)
          order by fc.sort_order) from academy.fee_plan_components fc
          where fc.fee_plan_version_id = fp.id), '[]'::jsonb))
       from academy.fee_plan_versions fp
       where fp.offering_id = o.id and fp.status = 'ACTIVE' limit 1) as fee_plan
    from academy.programme_offerings o
    join academy.organizations org on org.id = o.organization_id
    join academy.academic_years ay on ay.id = o.academic_year_id
    join academy.branches b on b.id = o.branch_id
    join academy.classes c on c.id = o.class_id
    left join academy.academic_groups ag on ag.id = o.group_id
    cross join lateral (select timezone(org.timezone, now())::date as today) local_day
    where o.scope_branch_id=academy_private.public_branch_id() and b.is_active and o.is_website_visible and o.status = 'ACTIVE'
    order by o.showcase_sort_order, o.created_at limit 24
  ) x;
$function$;
alter function academy.list_public_programme_offerings() owner to postgres;
grant execute on function academy.list_public_programme_offerings() to anon,authenticated;
reset search_path;
