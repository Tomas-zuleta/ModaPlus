-- CI ONLY: robustecer permisos de clientes y protección de inventario.
-- No usa datos reales.
set request.jwt.claim.sub = '99999999-9999-4999-8999-999999999999';
set role authenticated;

do $test$
declare
  v_rejected boolean := false;
begin
  if public.modaplus_es_administrador() then
    raise exception 'Cuenta desconocida obtuvo permisos administrativos.';
  end if;
  begin
    perform public.guardar_venta(
      '{"id_venta":0,"id_cliente":1,"estado":"APROBADA",
        "origen":"ADMIN","metodo_pago":"EFECTIVO",
        "descuento":0,"total_venta":45000}'::jsonb,
      '[{"id_variante":1,"cantidad":1,"precio_unitario":45000}]'::jsonb);
  exception when insufficient_privilege then
    v_rejected := true;
  end;
  if not v_rejected then
    raise exception 'Un usuario no administrador accedió a guardar_venta.';
  end if;
  v_rejected := false;
  begin
    insert into public.categorias(nombre_categoria)
      values('No debería crear esta categoría');
  exception when insufficient_privilege then
    v_rejected := true;
  end;
  if not v_rejected then
    raise exception 'RLS permitió escribir sin ser administrador.';
  end if;
  raise notice 'OK: usuario desconocido sin permisos de escritura ni ventas.';
end $test$;

reset role;
set request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
set role authenticated;

do $test$
declare
  v_variant bigint;
  v_guarded boolean := false;
begin
  select v.id_variante into v_variant
    from public.variantes_producto v
    join public.productos p on p.id_producto=v.id_producto
    where p.referencia='DEMO-001' limit 1;
  begin
    update public.variantes_producto
      set stock_actual=stock_actual+100
      where id_variante=v_variant;
  exception when raise_exception then
    v_guarded := true;
  end;
  if not v_guarded then
    raise exception 'El inventario permitió modificar stock directamente.';
  end if;
  raise notice 'OK: stock protegido frente a modificaciones directas.';
end $test$;
reset role;
