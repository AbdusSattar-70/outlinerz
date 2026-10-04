-- Branch isolation is enforced even inside legacy SECURITY DEFINER workflows.
set search_path=academy,extensions,public;
create schema academy_private;
revoke all on schema academy_private from public,anon,authenticated;
create role academy_executor nologin nobypassrls;
grant usage on schema academy,academy_private,auth to academy_executor;
grant execute on function auth.uid() to academy_executor;
create table academy.branch_owners(organization_id uuid primary key references academy.organizations(id),user_id uuid not null references auth.users(id));
create table academy.branch_memberships(branch_id uuid references academy.branches(id),user_id uuid references auth.users(id),is_active boolean not null default true,primary key(branch_id,user_id));
create table academy.branch_open_commands(user_id uuid references auth.users(id),request_id uuid,payload jsonb not null,result jsonb not null,primary key(user_id,request_id));
create function academy_private.current_branch_id() returns uuid language plpgsql stable security definer set search_path=pg_catalog,academy as $$
declare chosen uuid; begin
 chosen:=nullif(current_setting('academy.branch_override',true),'')::uuid;
 if chosen is null then chosen:=nullif(coalesce(nullif(current_setting('request.headers',true),''),'{}')::jsonb->>'x-academy-branch','')::uuid; end if;
 if chosen is null or auth.uid() is null or not exists(select 1 from academy.branch_memberships m join academy.branches b on b.id=m.branch_id where m.user_id=auth.uid() and m.branch_id=chosen and m.is_active and b.is_active) then return null; end if;
 return chosen;
 exception when invalid_text_representation then return null;
end $$;
grant usage on schema academy_private to authenticated;
grant execute on function academy_private.current_branch_id() to authenticated,academy_executor;
-- Financial stores are removed. Empty compatibility views preserve read-only response shapes
-- in retained academic code; they cannot store money or accept inserts/updates.
do $$ declare r record; cols text; begin
 for r in select tablename from pg_tables where schemaname='academy' and (tablename like 'finance_%' or tablename like 'general_ledger_%' or tablename like 'teacher_compensation_%' or tablename like 'referral_%' or tablename in('teacher_referrals','admission_referrals','vendors','payment_methods','admission_invoices','admission_invoice_lines','admission_payments','admission_payment_allocations','billing_terms','admission_discounts','invoice_credits','refund_authorizations','refund_payouts','admission_cancellations','billing_runs','fee_plan_versions','fee_plan_components','staff_compensation_terms','staff_payroll_records')) loop
  select string_agg(format('NULL::%s as %I',format_type(atttypid,atttypmod),attname),',' order by attnum) into cols from pg_attribute where attrelid=format('academy.%I',r.tablename)::regclass and attnum>0 and not attisdropped;
  execute format('drop table academy.%I cascade',r.tablename);
  execute format('create view academy.%I as select %s where false',r.tablename,cols);
 end loop;
end $$;
do $$ declare r record;begin for r in select t.tgname,c.relname from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace join pg_proc p on p.oid=t.tgfoid where n.nspname='academy' and not t.tgisinternal and p.proname ~ '(finance|billing|payment|discount|refund|compensation|payroll|fee_plan|referr)' loop execute format('drop trigger %I on academy.%I',r.tgname,r.relname);end loop;end $$;
-- Global profile/branch bootstrap is audited explicitly, after membership exists.
do $$ declare r record; begin for r in select t.tgname,c.relname from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname='academy' and c.relname in('profiles','organizations','branches') and not t.tgisinternal and t.tgname ilike '%audit%' loop execute format('drop trigger %I on academy.%I',r.tgname,r.relname); end loop; end $$;
-- No migration template is a real branch. It remains inaccessible as a seed reference.
update academy.branches set is_active=false;
create function academy_private.protect_branch_scope() returns trigger language plpgsql set search_path=pg_catalog as $$ begin
 if TG_OP='UPDATE' and new.scope_branch_id is distinct from old.scope_branch_id then raise exception 'A record cannot move to another branch.'; end if;
 if to_jsonb(new) ? 'branch_id' and nullif(to_jsonb(new)->>'branch_id','') is not null and (to_jsonb(new)->>'branch_id')::uuid<>new.scope_branch_id then raise exception 'Branch placement must match record scope.'; end if;
 return new; end $$;
-- All operational tables are scoped, including command keys and audit history.
do $$ declare r record; u record; begin
 for r in select tablename from pg_tables where schemaname='academy' and tablename not in('organizations','branches','profiles','system_roles','permissions','role_permissions','staff_roles','branch_owners','branch_memberships','branch_open_commands') loop
  execute format('alter table academy.%I add column scope_branch_id uuid',r.tablename);
  execute format('update academy.%I set scope_branch_id=''87a7d34b-4c6d-43ba-96b9-3dcf22da2c7c''',r.tablename);
  execute format('alter table academy.%I alter column scope_branch_id set default academy_private.current_branch_id(),alter column scope_branch_id set not null,add foreign key(scope_branch_id) references academy.branches(id)',r.tablename);
  -- Organization-level directory names/codes are independently editable in each branch.
  for u in select conname,pg_get_constraintdef(oid) def from pg_constraint where conrelid=format('academy.%I',r.tablename)::regclass and contype='u' and (pg_get_constraintdef(oid) like '%organization_id%' or pg_get_constraintdef(oid) like '%profile_id%' or pg_get_constraintdef(oid) like '%domain%' or pg_get_constraintdef(oid) like '%code%' or pg_get_constraintdef(oid) like '%name%') and pg_get_constraintdef(oid) not like '%(id,%' loop
   execute format('alter table academy.%I drop constraint %I',r.tablename,u.conname);
   execute format('alter table academy.%I add constraint %I %s',r.tablename,u.conname,replace(u.def,'UNIQUE (','UNIQUE (scope_branch_id, '));
  end loop;
  execute format('alter table academy.%I enable row level security',r.tablename);
  execute format('alter table academy.%I force row level security',r.tablename);
  execute format('create policy executor_workflows on academy.%I for all to academy_executor using(true) with check(true)',r.tablename);
  execute format('create policy branch_scope on academy.%I as restrictive for all to authenticated,academy_executor using(scope_branch_id=academy_private.current_branch_id()) with check(scope_branch_id=academy_private.current_branch_id())',r.tablename);
  execute format('create trigger protect_branch_scope before insert or update on academy.%I for each row execute function academy_private.protect_branch_scope()',r.tablename);
  if exists(select 1 from information_schema.columns where table_schema='academy' and table_name=r.tablename and column_name='id') then execute format('alter table academy.%I add unique(scope_branch_id,id)',r.tablename); end if;
 end loop;
end $$;
drop index academy.one_active_business_rule;
create unique index one_active_business_rule on academy.business_rule_versions(scope_branch_id,domain,rule_key) where status='ACTIVE';
drop index academy.staff_access_open_email;
create unique index staff_access_open_email on academy.staff_access_requests(scope_branch_id,lower(email)) where status in('PENDING','VERIFIED','INVITED');
drop index academy.areas_name_parent_uniq;
create unique index areas_name_parent_uniq on academy.areas(scope_branch_id,organization_id,lower(name),coalesce(parent_id,'00000000-0000-0000-0000-000000000000'::uuid));
-- Composite foreign keys prevent cross-branch links even for a user belonging to both branches.
do $$ declare r record; begin
 for r in select c.conrelid::regclass as src,c.confrelid::regclass as dst,a.attname as col,b.attname as target,c.conname from pg_constraint c join pg_attribute a on a.attrelid=c.conrelid and a.attnum=c.conkey[1] join pg_attribute b on b.attrelid=c.confrelid and b.attnum=c.confkey[1] where c.contype='f' and array_length(c.conkey,1)=1 and b.attname='id' and a.attname<>'scope_branch_id' and exists(select 1 from pg_attribute where attrelid=c.conrelid and attname='scope_branch_id') and exists(select 1 from pg_attribute where attrelid=c.confrelid and attname='scope_branch_id') loop
  execute format('alter table %s add constraint %I foreign key(scope_branch_id,%I) references %s(scope_branch_id,id)',r.src,'scope_'||substr(md5(r.src::text||r.conname),1,24),r.col,r.dst);
 end loop;
end $$;
-- Global identity and immutable permission templates are the only shared records.
alter table academy.organizations force row level security;
alter table academy.branches force row level security;
alter table academy.profiles force row level security;
create policy executor_workflows on academy.organizations for all to academy_executor using(true) with check(true);
create policy executor_workflows on academy.branches for all to academy_executor using(true) with check(true);
create policy executor_workflows on academy.profiles for all to academy_executor using(true) with check(true);
create policy organization_scope on academy.organizations as restrictive for all to authenticated,academy_executor using(id=(select organization_id from academy.branches where id=academy_private.current_branch_id())) with check(id=(select organization_id from academy.branches where id=academy_private.current_branch_id()));
create policy branch_registry_scope on academy.branches as restrictive for all to authenticated,academy_executor using(id=academy_private.current_branch_id()) with check(id=academy_private.current_branch_id());
create function academy_private.is_branch_member(p_profile uuid) returns boolean language sql stable security definer set search_path=pg_catalog,academy as $$ select academy_private.current_branch_id() is not null and exists(select 1 from academy.branch_memberships where user_id=p_profile and branch_id=academy_private.current_branch_id() and is_active); $$;
grant execute on function academy_private.is_branch_member(uuid) to authenticated,academy_executor;
create policy profile_scope on academy.profiles as restrictive for all to authenticated,academy_executor using(id=auth.uid() or academy_private.is_branch_member(id)) with check(id=auth.uid() or academy_private.is_branch_member(id));
alter table academy.branch_memberships enable row level security;
create policy own_memberships on academy.branch_memberships for select to authenticated,academy_executor using(user_id=auth.uid());
alter table academy.branch_owners enable row level security;
alter table academy.branch_open_commands enable row level security;
grant select on academy.branch_memberships to authenticated,academy_executor;
do $$ declare item text;begin foreach item in array array['system_roles','permissions','role_permissions','staff_roles'] loop execute format('create policy executor_catalogue_read on academy.%I for select to academy_executor using(academy_private.current_branch_id() is not null)',item);end loop;end $$;
-- Permission evaluation avoids RLS recursion and always validates branch membership.
create or replace function academy.has_permission(p_permission_code text) returns boolean language sql stable security definer set search_path=pg_catalog,academy as $$
 select auth.uid() is not null and academy_private.current_branch_id() is not null and exists(select 1 from academy.user_role_assignments ura join academy.system_roles sr on sr.id=ura.role_id join academy.role_permissions rp on rp.role_id=sr.id join academy.permissions p on p.id=rp.permission_id join academy.profiles pr on pr.id=ura.profile_id where ura.profile_id=auth.uid() and ura.scope_branch_id=academy_private.current_branch_id() and ura.is_active and sr.is_active and pr.status='ACTIVE' and ura.effective_from<=current_date and(ura.effective_to is null or ura.effective_to>=current_date) and p.code=p_permission_code);
$$;
-- Remove all financial permissions, preventing retained legacy commands from posting money.
delete from academy.role_permissions where permission_id in(select id from academy.permissions where code ~ '^(finance|accounting|compensation|referrals)\.' or code='system.roles.manage');
-- All legacy definer functions run as an RLS-bound executor, never as postgres.
grant all on all tables in schema academy to academy_executor;
grant usage,select on all sequences in schema academy to academy_executor;
grant execute on all functions in schema academy to academy_executor;
grant execute on all functions in schema academy_private to academy_executor;
do $$ declare r record; begin for r in select p.oid::regprocedure as signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='academy' and p.proname<>'has_permission' loop execute format('alter function %s owner to academy_executor',r.signature); end loop; end $$;
-- Read-only compatibility views have no public write grants. Financial/bootstrap RPCs are inaccessible.
revoke all on all functions in schema academy from anon;
revoke all on all tables in schema academy from anon;
do $$ declare r record; begin
 for r in select p.oid::regprocedure as signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='academy' and (p.proname ~ '(finance|invoice|billing|payment|discount|refund|compensation|payroll|fee_plan|referr)' or p.proname in('bootstrap_admin','set_role_permissions','handle_new_auth_user','request_staff_access','review_staff_access','set_user_operational_roles','save_academy_identity')) loop execute format('revoke execute on function %s from authenticated,anon,public',r.signature); end loop;
 for r in select viewname from pg_views where schemaname='academy' loop execute format('revoke insert,update,delete on academy.%I from authenticated,anon,academy_executor',r.viewname); end loop;
end $$;
reset search_path;
