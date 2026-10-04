-- CLI login roles must never remain owners of privileged application helpers.
-- Preserve the non-bypass owner on academic workflows; normalize only privileged
-- bootstrap, membership and public projection helpers to the stable administrator.
grant usage on schema auth to postgres,academy_executor;
grant execute on function auth.uid() to postgres,academy_executor;
grant select on auth.users to postgres,academy_executor;
do $$ declare item record; begin
 for item in
  select p.oid::regprocedure as signature
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  join pg_roles r on r.oid=p.proowner
  where n.nspname in ('public','academy_private') and p.prosecdef
   and r.rolname <> 'academy_executor'
 loop
  execute format('alter function %s owner to postgres',item.signature);
 end loop;
end $$;
