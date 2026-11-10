-- Read-only staging smoke checks. Safe to run in SQL Editor.
select 'public_tables' as test, count(*)::text as observed
from information_schema.tables
where table_schema='public' and table_type='BASE TABLE'
union all
select 'demo_products',count(*)::text from public.productos where referencia='DEMO-001'
union all
select 'demo_customers',count(*)::text from public.clientes where correo='cliente.demo@example.invalid'
union all
select 'read_policies',count(*)::text from pg_policies
where schemaname='public' and policyname='modaplus_admin_lectura'
union all
select 'rls_enabled',count(*)::text from pg_class c
join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind='r' and c.relrowsecurity;
