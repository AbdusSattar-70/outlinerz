import {PGlite} from '../database/node_modules/@electric-sql/pglite/dist/index.js';
import {readFile,readdir} from 'node:fs/promises';
export const db=new PGlite();
await db.exec(`create role anon;create role authenticated;create role service_role bypassrls;create schema extensions;create schema auth;create table auth.users(id uuid primary key,email text,email_confirmed_at timestamptz,created_at timestamptz default now(),raw_user_meta_data jsonb default '{}');create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$; grant usage on schema auth to anon,authenticated,service_role;grant execute on function auth.uid() to anon,authenticated,service_role;create schema storage;create table storage.buckets(id text primary key,name text,public boolean);create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text);alter table storage.objects enable row level security;grant usage on schema storage to authenticated;grant all on storage.objects to authenticated;`);
await db.exec('create role migration_admin nologin createrole bypassrls; grant postgres to migration_admin; create role auth_fixture_owner; alter schema auth owner to auth_fixture_owner; grant usage on schema auth to migration_admin with grant option; set role migration_admin;');
for(const f of (await readdir('supabase/migrations')).filter(f=>f.endsWith('.sql')).sort()){

 let sql=await readFile('supabase/migrations/'+f,'utf8');sql=sql.replace(/create extension if not exists pgcrypto;/gi,'');
 try{await db.exec(sql);console.log('APPLIED',f);}catch(e){console.error('FAILED',f,e.message,e.query?.slice(-1200));throw e;}
}
await db.exec('reset role; grant usage on schema auth to academy_executor; revoke usage on schema auth from migration_admin cascade; grant postgres,academy_executor to migration_admin with inherit false;');
console.log('PASS migrations (fresh baseline applied without SUPERUSER)');
