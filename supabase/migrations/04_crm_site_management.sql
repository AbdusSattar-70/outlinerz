-- Organization editorial settings preserve the Sohoj presentation template.
begin;
create table public.crm_sites (
 organization_id uuid primary key references public.organizations(id),
 revision integer not null default 1 check(revision > 0),
 settings jsonb not null check(jsonb_typeof(settings)='object'),
 updated_at timestamptz not null default now()
);
alter table public.crm_sites enable row level security;
revoke all on public.crm_sites from anon, authenticated;
grant select on public.crm_sites to authenticated;
create policy site_read on public.crm_sites for select to authenticated using(app_private.has_role(organization_id,array['OWNER','ADMIN']));
create function public.crm_site_save(p_org uuid,p_request uuid,p_revision integer,p_settings jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare old_settings jsonb; r jsonb; v_revision integer; k text; v jsonb;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN']);
 perform app_private.require_module(p_org,'CRM');
 if p_revision is null or p_revision<0 or p_settings is null then raise exception 'Invalid save request'; end if;
 r:=app_private.begin_command(p_org,p_request,'crm_site_save',jsonb_build_array(p_revision,p_settings));
 if r is not null then return r; end if;
 perform 1 from public.organizations where id=p_org for update;
 select settings into old_settings from public.crm_sites where organization_id=p_org;
 select revision into v_revision from public.crm_sites where organization_id=p_org;
 if coalesce(v_revision,0)<>p_revision then raise exception 'Site settings changed. Reload before saving.'; end if;
 if jsonb_typeof(p_settings)<>'object' or octet_length(p_settings::text)>250000 then raise exception 'Invalid site settings'; end if;
 if length(trim(coalesce(p_settings->>'nameEn',''))) not between 1 and 180 or length(trim(coalesce(p_settings->>'nameBn',''))) not between 1 and 180 then raise exception 'Both organization names are required'; end if;
 for k,v in select * from jsonb_each(p_settings) loop
 if k not in ('nameEn','nameBn','logo','mark','heroImage','learningImage','phone','email','addressEn','addressBn','copy') then raise exception 'Unknown site field'; end if;
 if k<>'copy' and (jsonb_typeof(v)<>'string' or length(v#>>'{}')>4000) then raise exception 'Invalid field'; end if;
 end loop;
 foreach k in array array['logo','mark','heroImage','learningImage'] loop
 if coalesce(p_settings->>k,'') !~ '^(https://[^[:space:]]+|/[^/[:space:]][^[:space:]]*)$' then raise exception 'Use a local image path or HTTPS image URL'; end if;
 end loop;
 if jsonb_typeof(p_settings->'copy') is distinct from 'object' then raise exception 'Invalid copy'; end if;
 for k,v in select * from jsonb_each(p_settings->'copy') loop
 if k !~ '^text_[0-9]+$' or jsonb_typeof(v)<>'object' or jsonb_typeof(v->'en') is distinct from 'string' or jsonb_typeof(v->'bn') is distinct from 'string' or length(v->>'en')>10000 or length(v->>'bn')>10000 then raise exception 'Invalid translated text'; end if;
 end loop;
 insert into public.crm_sites(organization_id,revision,settings) values(p_org,1,p_settings)
 on conflict(organization_id) do update set revision=crm_sites.revision+1,settings=excluded.settings,updated_at=now()
 returning revision into v_revision;
 insert into public.audit_events(organization_id,actor_id,table_name,row_id,operation,old_record,new_record)
 values(p_org,auth.uid(),'crm_sites',p_org,case when old_settings is null then 'INSERT' else 'UPDATE' end,old_settings,p_settings);
 update public.organizations set name=trim(p_settings->>'nameEn') where id=p_org;
 r:=jsonb_build_object('revision',v_revision);
 perform app_private.end_command(p_org,p_request,r);
 return r;
end $$;
create function public.crm_site_public(p_slug text) returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('name',o.name,'settings',s.settings) from public.organizations o
 left join public.crm_sites s on s.organization_id=o.id
 where o.slug=p_slug and app_private.module_enabled(o.id,'CRM');
$$;
revoke all on function public.crm_site_save(uuid,uuid,integer,jsonb) from public,anon;
grant execute on function public.crm_site_save(uuid,uuid,integer,jsonb) to authenticated;
revoke all on function public.crm_site_public(text) from public;
grant execute on function public.crm_site_public(text) to anon,authenticated;
create function public.crm_site_offering(p_org uuid,p_request uuid,p_offering uuid,p_expected jsonb,p_input jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare current_data jsonb; r jsonb; k text; v jsonb;
begin
 perform app_private.require_role(p_org,array['OWNER','ADMIN']);
 perform app_private.require_module(p_org,'CRM');
 r:=app_private.begin_command(p_org,p_request,'crm_site_offering',jsonb_build_array(p_offering,p_expected,p_input));
 if r is not null then return r; end if;
 select jsonb_build_object('name',name,'public_visible',public_visible,'intake_open',intake_open,'public_copy',public_copy) into current_data
 from public.offerings where organization_id=p_org and id=p_offering for update;
 if current_data is null then raise exception 'Offering unavailable'; end if;
 if current_data is distinct from p_expected then raise exception 'Reload before saving'; end if;
 if p_input is null or length(trim(coalesce(p_input->>'name',''))) not between 1 and 180
 or jsonb_typeof(p_input->'public_visible') is distinct from 'boolean' or jsonb_typeof(p_input->'intake_open') is distinct from 'boolean'
 or jsonb_typeof(p_input->'public_copy') is distinct from 'object' or octet_length(p_input::text)>50000 then raise exception 'Invalid offering copy'; end if;
 for k,v in select * from jsonb_each(p_input->'public_copy') loop
 if k not in ('showcase_title','showcase_title_bn','showcase_description','showcase_description_bn','showcase_eyebrow','showcase_eyebrow_bn','showcase_icon','public_schedule','public_schedule_bn','public_requirements','public_requirements_bn','admission_policy','admission_policy_bn') or jsonb_typeof(v)<>'string' or length(v#>>'{}')>5000 then raise exception 'Invalid publication field'; end if;
 end loop;
 update public.offerings set name=trim(p_input->>'name'),public_visible=(p_input->>'public_visible')::boolean,intake_open=(p_input->>'intake_open')::boolean,public_copy=p_input->'public_copy'
 where organization_id=p_org and id=p_offering;
 return app_private.end_command(p_org,p_request,jsonb_build_object('id',p_offering));
end $$;
revoke all on function public.crm_site_offering(uuid,uuid,uuid,jsonb,jsonb) from public,anon;
grant execute on function public.crm_site_offering(uuid,uuid,uuid,jsonb,jsonb) to authenticated;
commit;
