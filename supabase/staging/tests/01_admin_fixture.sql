-- CI ONLY: seed the admin account, following SQL Editor bootstrap.
insert into public.usuarios(id_usuario,auth_user_id,estado)
values (1,'11111111-1111-4111-8111-111111111111','ACTIVO');
insert into public.usuarios_roles(id_usuario,id_rol) values (1,1);
select setval(pg_get_serial_sequence('public.usuarios','id_usuario'),1,true);
