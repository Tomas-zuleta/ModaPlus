-- ModaPlus staging: read-only admin RLS + synthetic fixtures.
-- Only apply after the provisional 23-table schema, never on original production.
begin;
create or replace function public.modaplus_es_administrador()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.usuarios u
    join public.usuarios_roles ur on ur.id_usuario = u.id_usuario
    join public.roles r on r.id_rol = ur.id_rol
    where u.auth_user_id = (select auth.uid())
      and u.estado = 'ACTIVO' and r.estado = 'ACTIVO'
      and upper(replace(r.nombre_rol, ' ', '')) in ('SUPERADMIN', 'ADMINISTRADOR')
  );
$$;
revoke all on function public.modaplus_es_administrador() from public;
grant execute on function public.modaplus_es_administrador() to authenticated;
do $$
declare t text;
begin
  foreach t in array array[
    'categorias','tallas','colores','proveedores','clientes','roles',
    'usuarios','usuarios_roles','modulos','permisos','roles_permisos',
    'productos','variantes_producto','compras','detalles_compra','ventas',
    'detalles_venta','planes_separe','detalles_plan_separe','abonos_separe',
    'devoluciones','detalles_devolucion','perdidas'
  ] loop
    execute format('drop policy if exists modaplus_admin_lectura on public.%I', t);
    execute format('create policy modaplus_admin_lectura on public.%I for select to authenticated using ((select public.modaplus_es_administrador()))', t);
  end loop;
end $$;
insert into public.roles(id_rol,nombre_rol,descripcion,estado)
values (1,'SUPERADMIN','Rol ficticio para pruebas','ACTIVO'),
       (2,'ADMINISTRADOR','Rol ficticio para pruebas','ACTIVO')
on conflict (id_rol) do nothing;
insert into public.categorias(nombre_categoria) values
 ('Camisetas DEMO'),('Pantalones DEMO'),('Vestidos DEMO')
on conflict (nombre_categoria) do nothing;
insert into public.tallas(nombre_talla) values ('S'),('M'),('L')
on conflict (nombre_talla) do nothing;
insert into public.colores(nombre_color) values
 ('Negro DEMO'),('Blanco DEMO'),('Azul DEMO')
on conflict (nombre_color) do nothing;
insert into public.proveedores(nombre_proveedor)
select 'Proveedor ficticio DEMO' where not exists (
 select 1 from public.proveedores where nombre_proveedor='Proveedor ficticio DEMO');
insert into public.clientes(nombres,apellidos,correo)
values ('Cliente','Ficticio DEMO','cliente.demo@example.invalid')
on conflict (correo) do nothing;
insert into public.productos(referencia,nombre_producto,descripcion,id_categoria,genero)
select 'DEMO-001','Camiseta de prueba','Producto ficticio sin ventas reales',
 c.id_categoria,'Mujer' from public.categorias c
where c.nombre_categoria='Camisetas DEMO'
on conflict (referencia) do nothing;
insert into public.variantes_producto(
 id_producto,id_talla,id_color,precio_venta,stock_actual,stock_minimo,stock_maximo)
select p.id_producto,t.id_talla,c.id_color,45000,0,2,20
from public.productos p
join public.tallas t on t.nombre_talla='M'
join public.colores c on c.nombre_color='Negro DEMO'
where p.referencia='DEMO-001' and not exists (
 select 1 from public.variantes_producto v
 where v.id_producto=p.id_producto and v.id_talla=t.id_talla and v.id_color=c.id_color);
commit;
select 'tablas_publicas' as verificacion,count(*)::text as resultado
from information_schema.tables where table_schema='public' and table_type='BASE TABLE'
union all
select 'productos_demo',count(*)::text from public.productos where referencia='DEMO-001'
union all
select 'roles_demo',count(*)::text from public.roles where id_rol in (1,2);
