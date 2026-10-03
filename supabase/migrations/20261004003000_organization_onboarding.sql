-- Forward migration. Applied 01_outlinerz_eduops_baseline.sql is unchanged.
begin;
create table app_private.organization_requests (
 user_id uuid not null references auth.users(id), request_id uuid not null,
 payload jsonb not null, result jsonb, primary key(user_id,request_id)
);
revoke all on app_private.organization_requests from public,anon,authenticated;
create function public.onboard_organization(p_request uuid,p_name text,p_slug text,p_branch_name text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); saved app_private.organization_requests; org uuid; branch uuid; payload jsonb; v_result jsonb;
begin
 if u is null then raise exception 'Login required' using errcode='42501'; end if;
 if p_request is null or p_name is null or length(trim(p_name)) not between 1 and 160
 or p_branch_name is null or length(trim(p_branch_name)) not between 1 and 160
 or p_slug is null or p_slug !~ '^[a-z0-9][a-z0-9-]{2,62}$' then raise exception 'Valid organization, slug, branch and request ID required'; end if;
 payload:=jsonb_build_array(trim(p_name),p_slug,trim(p_branch_name));
 insert into app_private.organization_requests values(u,p_request,payload,null) on conflict do nothing;
 select * into saved from app_private.organization_requests where user_id=u and request_id=p_request for update;
 if saved.payload<>payload then raise exception 'Request ID reused with changed inputs'; end if;
 if saved.result is not null then return saved.result; end if;
 org:=public.create_organization(trim(p_name),p_slug);
 insert into public.branches(organization_id,name,code) values(org,trim(p_branch_name),'MAIN') returning id into branch;
 v_result:=jsonb_build_object('organization_id',org,'branch_id',branch);
 update app_private.organization_requests set result=v_result where user_id=u and request_id=p_request;
 return v_result;
end $$;
revoke all on function public.onboard_organization(uuid,text,text,text) from public,anon,authenticated;
grant execute on function public.onboard_organization(uuid,text,text,text) to authenticated;
commit;
