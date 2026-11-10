-- CI ONLY: replace Supabase's auth schema with minimal local stubs.
create schema if not exists auth;
create table auth.users (id uuid primary key, email text not null unique);
create or replace function auth.uid()
returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid;
$$;
do $$ begin
 if not exists (select 1 from pg_roles where rolname='authenticated') then
   create role authenticated nologin;
 end if;
 if not exists (select 1 from pg_roles where rolname='anon') then
   create role anon nologin;
 end if;
 if not exists (select 1 from pg_roles where rolname='service_role') then
   create role service_role nologin bypassrls;
 end if;
end $$;
grant usage on schema public to authenticated, anon, service_role;
grant usage on schema auth to authenticated, anon, service_role;
grant execute on function auth.uid() to authenticated;
insert into auth.users(id,email) values
 ('11111111-1111-4111-8111-111111111111','admin.test@example.invalid');
