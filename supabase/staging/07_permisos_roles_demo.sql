-- PASO 07. SOLO prubasmoda. Requiere esquema provisional y pasos previos.
-- Permisos por rol se guardan juntos. El SUPERADMIN no puede modificarse.
begin;
do $guard$
begin
  if not exists (select 1 from public.productos where referencia='DEMO-001')
     or not exists (select 1 from public.roles where id_rol=1
                    and nombre_rol='SUPERADMIN') then
    raise exception 'Este SQL solo puede ejecutarse en el entorno DEMO de ModaPlus.';
  end if;
end $guard$;

create or replace function public.modaplus_actualizar_permisos_rol(
  p_rol bigint, p_permisos jsonb
)
returns void
language plpgsql
security definer
set search_path = '' as $func$
declare
  v_permission jsonb;
  v_modulo bigint;
  v_permiso bigint;
begin
  if auth.uid() is null or not exists (
    select 1 from public.usuarios u
    join public.usuarios_roles ur on ur.id_usuario=u.id_usuario
    join public.roles r on r.id_rol=ur.id_rol
    where u.auth_user_id=auth.uid()
      and u.estado='ACTIVO' and r.estado='ACTIVO'
      and ur.id_rol=1
  ) then
    raise exception 'Solo SUPERADMIN puede cambiar permisos de roles.'
      using errcode='42501';
  end if;
  if p_rol is null or p_rol<=1 or not exists (
    select 1 from public.roles where id_rol=p_rol and estado='ACTIVO'
  ) then
    raise exception 'Rol inválido o protegido.';
  end if;
  if jsonb_typeof(p_permisos) is distinct from 'array'
     or jsonb_array_length(p_permisos)>200 then
    raise exception 'Envía una lista válida de permisos (máximo 200).';
  end if;

  perform 1 from public.roles where id_rol=p_rol for update;
  delete from public.roles_permisos where id_rol=p_rol;

  for v_permission in select value from jsonb_array_elements(p_permisos)
  loop
    v_modulo := (v_permission->>'id_modulo')::bigint;
    v_permiso := (v_permission->>'id_permiso')::bigint;
    if not exists (select 1 from public.modulos where id_modulo=v_modulo)
       or not exists (select 1 from public.permisos where id_permiso=v_permiso) then
      raise exception 'Hay módulos o acciones de permisos inválidos.';
    end if;
    insert into public.roles_permisos (id_rol,id_modulo,id_permiso)
      values (p_rol,v_modulo,v_permiso)
      on conflict do nothing;
  end loop;
end
$func$;
revoke all on function public.modaplus_actualizar_permisos_rol(bigint,jsonb)
  from public, anon;
grant execute on function public.modaplus_actualizar_permisos_rol(bigint,jsonb)
  to authenticated;

-- En el seed inicial se crearon ids 1 y 2 manualmente; adelantar secuencia
-- para no provocar conflicto al crear el siguiente rol por INSERT.
select setval(pg_get_serial_sequence('public.roles','id_rol'),
  greatest((select coalesce(max(id_rol),1) from public.roles),1), true);

commit;

select
  'modaplus_actualizar_permisos_rol' as rpc,
  has_function_privilege('authenticated',
    'public.modaplus_actualizar_permisos_rol(bigint,jsonb)', 'EXECUTE')
    as disponible_para_autenticados;
