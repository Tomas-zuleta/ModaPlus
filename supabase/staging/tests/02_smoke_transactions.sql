-- CI ONLY: ejecutar en PostgreSQL aislado con cuenta sintética.
set request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
set role authenticated;

do $test$
declare
  v_provider bigint;
  v_client bigint;
  v_variant bigint;
  v_purchase bigint;
  v_sale bigint;
  v_plan bigint;
  v_payment bigint;
  v_qty integer;
  v_module bigint;
  v_permission bigint;
  v_total numeric;
begin
  insert into public.proveedores(nit,razon_social,estado)
    values ('CI-90000','Proveedor falso CI','ACTIVO')
    returning id_proveedor into v_provider;
  insert into public.clientes(nombres,apellidos,correo,identificacion,telefono)
    values ('Cliente','CI','cliente-ci@example.invalid','CI999','30000000')
    returning id_cliente into v_client;
  select v.id_variante into strict v_variant
    from public.variantes_producto v
    join public.productos p on p.id_producto=v.id_producto
    where p.referencia='DEMO-001'
    limit 1;
  select public.guardar_compra(
    jsonb_build_object('id_compra',0,'id_proveedor',v_provider,
      'factura','FACTURA-CI-0001','estado','ACTIVA',
      'fecha_compra',current_date),
    jsonb_build_array(jsonb_build_object('id_variante',v_variant,
      'cantidad',5,'costo_unitario',20000))
  ) into v_purchase;
  select stock_actual into strict v_qty from public.variantes_producto
    where id_variante=v_variant;
  if v_qty <> 5 then raise exception 'Compra no aumentó stock: %',v_qty; end if;

  select public.guardar_venta(
    jsonb_build_object('id_venta',0,'id_cliente',v_client,
      'estado','APROBADA','origen','ADMIN','metodo_pago','EFECTIVO',
      'descuento',0,'total_venta',90000),
    jsonb_build_array(jsonb_build_object('id_variante',v_variant,
      'cantidad',2,'precio_unitario',45000,'subtotal',90000))
  ) into v_sale;
  select stock_actual into strict v_qty from public.variantes_producto
    where id_variante=v_variant;
  if v_qty <> 3 then raise exception 'Venta no descontó stock: %',v_qty; end if;

  -- Debe rechazar una venta sin existencias y deshacer cambios.
  begin
    perform public.guardar_venta(
      jsonb_build_object('id_venta',0,'id_cliente',v_client,
        'estado','APROBADA','origen','ADMIN','metodo_pago','EFECTIVO',
        'descuento',0,'total_venta',450000),
      jsonb_build_array(jsonb_build_object('id_variante',v_variant,
        'cantidad',10,'precio_unitario',45000,'subtotal',450000))
    );
    raise exception 'Se permitió vender sin existencias';
  exception when others then
    if sqlerrm = 'Se permitió vender sin existencias' then
      raise;
    end if;
  end;
  select stock_actual into strict v_qty from public.variantes_producto
    where id_variante=v_variant;
  if v_qty <> 3 then raise exception 'Stock alterado por venta fallida'; end if;

  select public.guardar_plan_separe(
    jsonb_build_object('id_plan_separe',0,'id_cliente',v_client,
      'estado','ACTIVO','fecha_inicio',current_date,
      'fecha_vencimiento',(current_date+interval '2 months')::date,
      'abono_inicial',20000,'metodo_abono_inicial','EFECTIVO'),
    jsonb_build_array(jsonb_build_object('id_variante',v_variant,
      'cantidad',1,'precio_unitario',45000))
  ) into v_plan;
  select stock_actual into strict v_qty from public.variantes_producto
    where id_variante=v_variant;
  if v_qty<>2 then raise exception 'Plan no reservó stock: %',v_qty; end if;
  select public.registrar_abono_separe(v_plan,10000,'EFECTIVO','Prueba CI')
    into v_payment;
  select coalesce(sum(valor_abono),0) into v_total from public.abonos_separe
    where id_plan_separe=v_plan and estado='ACTIVO';
  if v_total<>10000 then raise exception 'Abono no registrado'; end if;

  perform public.anular_abono(v_payment);
  if (select estado from public.abonos_separe
      where id_abono=v_payment)<>'ANULADO' then
    raise exception 'La anulación no conservó estado ANULADO.';
  end if;
  perform public.anular_plan_separe(v_plan);
  select stock_actual into strict v_qty from public.variantes_producto
    where id_variante=v_variant;
  if v_qty<>3 then raise exception 'Anulación no devolvió stock: %',v_qty; end if;

  select id_modulo into strict v_module from public.modulos
    where codigo='ventas';
  select id_permiso into strict v_permission from public.permisos
    where codigo='view';
  perform public.modaplus_actualizar_permisos_rol(
    2,jsonb_build_array(jsonb_build_object(
      'id_modulo',v_module,'id_permiso',v_permission))
  );
  if (select count(*) from public.roles_permisos where id_rol=2)<>1 then
    raise exception 'No se guardó la matriz de permisos.';
  end if;
  raise notice 'OK: compra %, venta %, plan %, abono % y permisos.',
    v_purchase,v_sale,v_plan,v_payment;
end $test$;

reset role;
