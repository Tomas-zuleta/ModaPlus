-- CI ONLY. Requiere suite previa de compras/ventas/planes.
set request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
set role authenticated;

do $smoke$
declare
  v_sale bigint;
  v_variant bigint;
  v_return bigint;
  v_loss bigint;
  v_stock_before integer;
  v_stock_after integer;
begin
  select max(id_venta) into strict v_sale from public.ventas
    where estado='APROBADA' and origen='ADMIN';
  select id_variante into strict v_variant from public.detalles_venta
    where id_venta=v_sale limit 1;
  select stock_actual into strict v_stock_before from public.variantes_producto
    where id_variante=v_variant;
  select public.guardar_devolucion(
    jsonb_build_object('id_devolucion',0,'id_venta',v_sale,
      'tipo_respuesta','DINERO','motivo','Talla incorrecta',
      'descripcion','Solicitada por cliente ficticio CI'),
    jsonb_build_array(jsonb_build_object('id_variante',v_variant,
      'cantidad',1,'motivo','Talla incorrecta'))
  ) into v_return;
  if (select estado from public.devoluciones
      where id_devolucion=v_return)<>'PENDIENTE' then
    raise exception 'La devolución no se creó en estado PENDIENTE.';
  end if;
  -- Solicitar devolución NO abona dinero ni aumenta existencias.
  select stock_actual into strict v_stock_after from public.variantes_producto
    where id_variante=v_variant;
  if v_stock_after<>v_stock_before then
    raise exception 'Devolución pendiente alteró inventario.';
  end if;
  select public.gestionar_perdida('guardar',jsonb_build_object(
    'id_variante',v_variant,'cantidad',1,'motivo','Daño ficticio',
    'estado','ACTIVA')) into v_loss;
  select stock_actual into strict v_stock_after from public.variantes_producto
    where id_variante=v_variant;
  if v_stock_after<>v_stock_before-1 then
    raise exception 'Una pérdida no disminuyó stock.';
  end if;
  perform public.gestionar_perdida('anular',jsonb_build_object(
    'id_perdida',v_loss,'estado','ANULADA'));
  select stock_actual into strict v_stock_after from public.variantes_producto
    where id_variante=v_variant;
  if v_stock_after<>v_stock_before then
    raise exception 'Anular pérdida no devolvió las existencias.';
  end if;
  if (select estado from public.perdidas
      where id_perdida=v_loss)<>'ANULADA' then
    raise exception 'No se conserva la pérdida anulada.';
  end if;
  raise notice 'OK devolucion %, pérdida %: stock consistente.',v_return,v_loss;
end $smoke$;
reset role;
