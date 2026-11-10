-- CI only. Do not execute with production data.
set request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
set role authenticated;
do $test$
declare
  v_sale bigint;
  v_variant bigint;
  v_user bigint;
  v_return bigint;
  v_loss bigint;
  v_qty integer;
begin
  select id_venta into strict v_sale from public.ventas
    where estado='APROBADA' order by id_venta limit 1;
  select id_variante into strict v_variant from public.detalles_venta
    where id_venta=v_sale limit 1;
  select id_usuario into strict v_user from public.usuarios
    where auth_user_id='11111111-1111-4111-8111-111111111111';

  select public.guardar_devolucion(
    jsonb_build_object('id_venta',v_sale,'id_devolucion',0,
      'motivo','TALLA','descripcion','Prueba sintética',
      'tipo_respuesta','DINERO'),
    jsonb_build_array(jsonb_build_object(
      'id_variante',v_variant,'cantidad',1))
  ) into v_return;
  if (select estado from public.devoluciones
      where id_devolucion=v_return) <> 'PENDIENTE' then
    raise exception 'Devolución no quedó pendiente';
  end if;

  select stock_actual into strict v_qty
    from public.variantes_producto where id_variante=v_variant;
  select public.gestionar_perdida('guardar',jsonb_build_object(
    'id_variante',v_variant,'cantidad',1,'motivo','DAÑADO')) into v_loss;
  if (select stock_actual from public.variantes_producto
      where id_variante=v_variant) <> v_qty-1 then
    raise exception 'Pérdida no descontó stock';
  end if;
  perform public.gestionar_perdida('anular',
    jsonb_build_object('id_perdida',v_loss));
  if (select stock_actual from public.variantes_producto
      where id_variante=v_variant) <> v_qty then
    raise exception 'Anulación no restituyó stock';
  end if;

  perform public.actualizar_roles_usuario(v_user, array[1,2]::bigint[]);
  if not exists (select 1 from public.usuarios_roles
    where id_usuario=v_user and id_rol=2) then
    raise exception 'No se asignó rol secundario';
  end if;
  raise notice 'OK: devolución %, pérdida % y roles de usuario %',
    v_return,v_loss,v_user;
end $test$;
reset role;
