-- ONLY FOR prubasmoda: provisional staging schema created earlier.
-- The mobile login queries usuarios -> clientes, but the provisional
-- usuarios table was missing id_cliente and its foreign key.
begin;

alter table public.usuarios
  add column if not exists id_cliente bigint;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.usuarios'::regclass
      and contype = 'f'
      and confrelid = 'public.clientes'::regclass
  ) then
    alter table public.usuarios
      add constraint usuarios_id_cliente_fkey
      foreign key (id_cliente) references public.clientes(id_cliente);
  end if;
end $$;

-- Link the previously created *test* administrator (id_usuario = 1)
-- to a synthetic customer profile using the matching Auth email.
do $$
declare
  v_id bigint;
  v_email text;
  v_client bigint;
begin
  select u.id_usuario, lower(a.email)
    into v_id, v_email
  from public.usuarios u
  join auth.users a on a.id = u.auth_user_id
  where u.id_usuario = 1;

  if v_id is null or v_email is null then
    raise exception 'No se encontro la cuenta de prueba id_usuario=1 en Auth';
  end if;

  select id_cliente into v_client
  from public.clientes where lower(correo) = v_email
  order by id_cliente limit 1;

  if v_client is null then
    insert into public.clientes(nombres, apellidos, correo, estado)
      values ('Administrador', 'Pruebas', v_email, 'ACTIVO')
      returning id_cliente into v_client;
  end if;

  update public.usuarios
  set id_cliente = v_client,
      correo = coalesce(correo, v_email)
  where id_usuario = v_id;

  if not exists (
    select 1 from public.usuarios_roles
    where id_usuario = v_id and id_rol = 1
  ) then
    raise exception 'El usuario no tiene el rol de prueba SUPERADMIN';
  end if;
end $$;

commit;

-- Read-only verification (expected: one ACTIVO / SUPERADMIN row).
select u.id_usuario, u.estado, u.id_cliente, c.nombres,
       r.nombre_rol
from public.usuarios u
join public.clientes c on c.id_cliente = u.id_cliente
join public.usuarios_roles ur on ur.id_usuario = u.id_usuario
join public.roles r on r.id_rol = ur.id_rol
where u.id_usuario = 1;
