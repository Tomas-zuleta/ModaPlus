-- MODAPLUS STAGING PASO 06 — Operaciones comerciales ficticias.
-- SOLO prubasmoda, después de pasos 01-05. NO PRODUCCION.
-- El administrador debe estar autenticado; todas las operaciones son atómicas.
BEGIN;
DO $$
BEGIN
  IF to_regclass('public.usuarios_roles') IS NULL OR
    NOT EXISTS (SELECT 1 FROM public.productos WHERE referencia = 'DEMO-001') OR
    NOT EXISTS (SELECT 1 FROM public.roles WHERE id_rol=1
               AND nombre_rol='SUPERADMIN') THEN
    RAISE EXCEPTION 'No es el staging esperado (DEMO-001/SUPERADMIN).';
  END IF;
  IF to_regprocedure('public.modaplus_protect_stock()') IS NULL THEN
    RAISE EXCEPTION 'Ejecuta primero el paso 05 de CRUD y protección de stock.';
  END IF;
END $$;

-- NO CONCEDER EXECUTE DIRECTO a este helper.
CREATE OR REPLACE FUNCTION public.modaplus_verificar_admin()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  IF (SELECT auth.uid()) IS NULL
     OR NOT public.modaplus_es_administrador() THEN
    RAISE EXCEPTION 'Solo un administrador activo puede registrar movimientos.'
      USING ERRCODE = '42501';
  END IF;
END $$;
REVOKE ALL ON FUNCTION public.modaplus_verificar_admin() FROM PUBLIC, anon, authenticated;

-- Cambia stock de forma atómica y evita vender unidades que no existen.
-- NO ES UN RPC PUBLICO; se invoca solo desde funciones autorizadas.
CREATE OR REPLACE FUNCTION public.modaplus_cambiar_stock(
  p_variante bigint, p_delta integer
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  IF p_variante IS NULL OR p_variante <= 0 OR p_delta = 0 THEN
    RAISE EXCEPTION 'Variante o unidades inválidas.';
  END IF;
  PERFORM set_config('modaplus.stock_rpc', 'yes', true);
  UPDATE public.variantes_producto
  SET stock_actual = stock_actual + p_delta
  WHERE id_variante = p_variante AND estado = 'ACTIVO'
    AND stock_actual + p_delta >= 0;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sin existencias suficientes para variante #%.', p_variante;
  END IF;
END $$;
REVOKE ALL ON FUNCTION public.modaplus_cambiar_stock(bigint, integer)
FROM PUBLIC, anon, authenticated;

-- COMPRAS: alta aumenta stock; ANULADA revierte stock solo si hay unidades.
CREATE OR REPLACE FUNCTION public.guardar_compra(
  p_compra jsonb, p_detalles jsonb
)
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_id bigint;
  v_proveedor bigint;
  v_line jsonb;
  v_variant bigint;
  v_qty integer;
  v_cost numeric;
  v_invoice text;
  v_state text;
  v_current text;
BEGIN
  PERFORM public.modaplus_verificar_admin();
  v_id := COALESCE((p_compra->>'id_compra')::bigint, 0);
  IF v_id > 0 THEN
    IF upper(COALESCE(p_compra->>'estado', '')) <> 'ANULADA' THEN
      RAISE EXCEPTION 'Las compras registradas no se pueden editar.';
    END IF;
    SELECT estado INTO v_current FROM public.compras
      WHERE id_compra=v_id FOR UPDATE;
    IF NOT FOUND OR v_current='ANULADA' THEN
      RAISE EXCEPTION 'Compra inexistente o ya anulada.';
    END IF;
    FOR v_variant, v_qty IN
      SELECT id_variante, cantidad FROM public.detalles_compra
      WHERE id_compra=v_id ORDER BY id_variante
    LOOP
      PERFORM public.modaplus_cambiar_stock(v_variant, -v_qty);
    END LOOP;
    UPDATE public.compras SET estado='ANULADA' WHERE id_compra=v_id;
    RETURN v_id;
  END IF;
  IF jsonb_typeof(p_detalles) IS DISTINCT FROM 'array'
     OR jsonb_array_length(p_detalles) = 0 THEN
    RAISE EXCEPTION 'Selecciona al menos un producto.';
  END IF;
  v_proveedor := (p_compra->>'id_proveedor')::bigint;
  IF NOT EXISTS (SELECT 1 FROM public.proveedores
                 WHERE id_proveedor=v_proveedor AND estado='ACTIVO') THEN
    RAISE EXCEPTION 'Selecciona un proveedor activo.';
  END IF;
  v_invoice := trim(COALESCE(p_compra->>'factura', ''));
  IF v_invoice = '' THEN
    RAISE EXCEPTION 'La factura del proveedor es obligatoria.';
  END IF;
  IF upper(COALESCE(p_compra->>'estado', 'ACTIVA')) <> 'ACTIVA' THEN
    RAISE EXCEPTION 'El estado inicial de una compra debe ser ACTIVA.';
  END IF;
  INSERT INTO public.compras(
    id_proveedor,fecha_compra,fecha_registro,
    numero_factura_proveedor,tipo_pago,estado
  ) VALUES (
    v_proveedor,
    COALESCE((p_compra->>'fecha_compra')::date, current_date),
    current_date, v_invoice, 'CONTADO','ACTIVA'
  ) RETURNING id_compra INTO v_id;
  FOR v_line IN SELECT value FROM jsonb_array_elements(p_detalles) LOOP
    v_variant := (v_line->>'id_variante')::bigint;
    v_qty := (v_line->>'cantidad')::integer;
    v_cost := (v_line->>'costo_unitario')::numeric;
    IF v_qty IS NULL OR v_qty <= 0 OR v_cost IS NULL OR v_cost < 0 THEN
      RAISE EXCEPTION 'Cantidad o costo inválido.';
    END IF;
    IF EXISTS (SELECT 1 FROM public.detalles_compra
               WHERE id_compra=v_id AND id_variante=v_variant) THEN
      RAISE EXCEPTION 'No repitas el mismo producto en una compra.';
    END IF;
    PERFORM public.modaplus_cambiar_stock(v_variant, v_qty);
    INSERT INTO public.detalles_compra(
      id_compra,id_variante,cantidad,costo_unitario,precio_venta
    ) VALUES (v_id,v_variant,v_qty,v_cost,
      NULLIF(v_line->>'precio_venta','')::numeric);
  END LOOP;
  RETURN v_id;
END $$;

-- VENTAS PRESENCIALES: precio tomado siempre del inventario del servidor.
CREATE OR REPLACE FUNCTION public.guardar_venta(
  p_venta jsonb, p_detalles jsonb
)
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_id bigint;
  v_client bigint;
  v_line jsonb;
  v_variant bigint;
  v_qty integer;
  v_price numeric;
  v_gross numeric := 0;
  v_discount numeric;
  v_method text;
BEGIN
  PERFORM public.modaplus_verificar_admin();
  IF COALESCE((p_venta->>'id_venta')::bigint,0) <> 0 THEN
    RAISE EXCEPTION 'Esta operación solo registra ventas nuevas.';
  END IF;
  IF upper(COALESCE(p_venta->>'origen','ADMIN')) <> 'ADMIN'
     OR upper(COALESCE(p_venta->>'estado','')) <> 'APROBADA' THEN
    RAISE EXCEPTION 'Para pruebas usa ventas presenciales aprobadas.';
  END IF;
  IF jsonb_typeof(p_detalles) IS DISTINCT FROM 'array'
     OR jsonb_array_length(p_detalles)=0 THEN
    RAISE EXCEPTION 'Elige al menos una prenda.';
  END IF;
  v_client := (p_venta->>'id_cliente')::bigint;
  IF NOT EXISTS (SELECT 1 FROM public.clientes
                 WHERE id_cliente=v_client AND estado='ACTIVO') THEN
    RAISE EXCEPTION 'El cliente está inactivo o no existe.';
  END IF;
  v_method := upper(COALESCE(p_venta->>'metodo_pago',''));
  IF v_method NOT IN ('EFECTIVO','TRANSFERENCIA','QR') THEN
    RAISE EXCEPTION 'Método de pago no permitido.';
  END IF;
  v_discount := COALESCE((p_venta->>'descuento')::numeric, 0);
  IF v_discount < 0 THEN RAISE EXCEPTION 'Descuento inválido.'; END IF;

  -- Bloqueo de variantes antes de descontar stock (evita ventas simultáneas).
  FOR v_line IN SELECT value FROM jsonb_array_elements(p_detalles) LOOP
    v_variant := (v_line->>'id_variante')::bigint;
    v_qty := (v_line->>'cantidad')::integer;
    IF v_qty IS NULL OR v_qty <= 0 THEN
      RAISE EXCEPTION 'Cantidad inválida.';
    END IF;
    IF (SELECT count(*) FROM jsonb_array_elements(p_detalles) x
      WHERE (x->>'id_variante')::bigint=v_variant) > 1 THEN
      RAISE EXCEPTION 'No repitas la misma variante.';
    END IF;
    SELECT precio_venta INTO v_price
    FROM public.variantes_producto WHERE id_variante=v_variant
      AND estado='ACTIVO' FOR UPDATE;
    IF NOT FOUND OR v_price <= 0 THEN
      RAISE EXCEPTION 'Precio o producto inválido.';
    END IF;
    IF abs(v_price - COALESCE((v_line->>'precio_unitario')::numeric,-1)) > 0.01 THEN
      RAISE EXCEPTION 'El precio cambió. Actualiza el formulario.';
    END IF;
    v_gross := v_gross + v_qty * v_price;
  END LOOP;
  IF v_discount > v_gross OR
     abs(COALESCE((p_venta->>'total_venta')::numeric,-1) -
         (v_gross-v_discount)) > 0.01 THEN
    RAISE EXCEPTION 'El total cambió. Verifica cantidades y descuento.';
  END IF;
  INSERT INTO public.ventas(
    id_cliente,fecha_venta,metodo_pago,subtotal,descuento,
    total_venta,saldo_aplicado,estado,origen
  ) VALUES (v_client,current_date,v_method,v_gross,v_discount,
            v_gross-v_discount,0,'APROBADA','ADMIN')
    RETURNING id_venta INTO v_id;
  FOR v_line IN SELECT value FROM jsonb_array_elements(p_detalles) LOOP
    v_variant := (v_line->>'id_variante')::bigint;
    v_qty := (v_line->>'cantidad')::integer;
    SELECT precio_venta INTO v_price
    FROM public.variantes_producto WHERE id_variante=v_variant;
    PERFORM public.modaplus_cambiar_stock(v_variant, -v_qty);
    INSERT INTO public.detalles_venta(
      id_venta,id_variante,cantidad,precio_unitario,subtotal
    ) VALUES (v_id,v_variant,v_qty,v_price,v_price*v_qty);
  END LOOP;
  RETURN v_id;
END $$;

-- PLAN SEPARE: reserva stock y aplica cuota mínima ficticia de COP 20.000 por unidad.
CREATE OR REPLACE FUNCTION public.guardar_plan_separe(
  p_plan jsonb, p_detalles jsonb
)
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_id bigint;
  v_client bigint;
  v_initial numeric;
  v_total numeric := 0;
  v_units integer := 0;
  v_line jsonb;
  v_variant bigint;
  v_qty integer;
  v_price numeric;
  v_start date;
  v_due date;
  v_method text;
BEGIN
  PERFORM public.modaplus_verificar_admin();
  IF COALESCE((p_plan->>'id_plan_separe')::bigint,0) <> 0 THEN
    RAISE EXCEPTION 'Un plan registrado no se puede editar.';
  END IF;
  IF jsonb_typeof(p_detalles) IS DISTINCT FROM 'array'
     OR jsonb_array_length(p_detalles)=0 THEN
    RAISE EXCEPTION 'Elige los productos del plan.';
  END IF;
  v_client := (p_plan->>'id_cliente')::bigint;
  IF NOT EXISTS (SELECT 1 FROM public.clientes
                 WHERE id_cliente=v_client AND estado='ACTIVO') THEN
    RAISE EXCEPTION 'Cliente inválido.';
  END IF;
  v_start := COALESCE((p_plan->>'fecha_inicio')::date,current_date);
  v_due := COALESCE((p_plan->>'fecha_vencimiento')::date,
    (v_start+interval '2 months')::date);
  IF v_due <= v_start OR v_due > (v_start+interval '2 months')::date THEN
    RAISE EXCEPTION 'El plazo máximo del plan es de dos meses.';
  END IF;
  v_method := upper(COALESCE(p_plan->>'metodo_abono_inicial',''));
  IF v_method NOT IN ('EFECTIVO','TRANSFERENCIA','QR') THEN
    RAISE EXCEPTION 'Método de abono inicial inválido.';
  END IF;
  FOR v_line IN SELECT value FROM jsonb_array_elements(p_detalles) LOOP
    v_variant := (v_line->>'id_variante')::bigint;
    v_qty := (v_line->>'cantidad')::integer;
    IF v_qty IS NULL OR v_qty <= 0 THEN RAISE EXCEPTION 'Cantidad inválida.'; END IF;
    IF (SELECT count(*) FROM jsonb_array_elements(p_detalles) x
      WHERE (x->>'id_variante')::bigint=v_variant) > 1 THEN
      RAISE EXCEPTION 'No repitas el mismo producto en el plan.';
    END IF;
    SELECT precio_venta INTO v_price FROM public.variantes_producto
    WHERE id_variante=v_variant AND estado='ACTIVO' FOR UPDATE;
    IF NOT FOUND OR v_price <= 0 THEN RAISE EXCEPTION 'Producto o precio inválido.'; END IF;
    IF abs(v_price - COALESCE((v_line->>'precio_unitario')::numeric,-1)) > 0.01 THEN
      RAISE EXCEPTION 'Precio desactualizado. Reabre el formulario.';
    END IF;
    v_total := v_total + v_price*v_qty;
    v_units := v_units + v_qty;
  END LOOP;
  v_initial := (p_plan->>'abono_inicial')::numeric;
  IF v_initial IS NULL OR v_initial < 20000*v_units OR v_initial > v_total THEN
    RAISE EXCEPTION 'Abono inicial: mínimo COP 20.000 por prenda y máximo el total.';
  END IF;
  INSERT INTO public.planes_separe(
    id_cliente,fecha_inicio,fecha_vencimiento,estado,
    abono_inicial,metodo_abono_inicial
  ) VALUES (v_client,v_start,v_due,'ACTIVO',v_initial,v_method)
  RETURNING id_plan_separe INTO v_id;
  FOR v_line IN SELECT value FROM jsonb_array_elements(p_detalles) LOOP
    v_variant := (v_line->>'id_variante')::bigint;
    v_qty := (v_line->>'cantidad')::integer;
    SELECT precio_venta INTO v_price FROM public.variantes_producto
      WHERE id_variante=v_variant;
    PERFORM public.modaplus_cambiar_stock(v_variant, -v_qty);
    INSERT INTO public.detalles_plan_separe(
      id_plan_separe,id_variante,cantidad,precio_unitario
    ) VALUES (v_id,v_variant,v_qty,v_price);
  END LOOP;
  RETURN v_id;
END $$;

-- ABONOS: verificación del saldo dentro de la misma transacción.
CREATE OR REPLACE FUNCTION public.registrar_abono_separe(
  p_id_plan bigint, p_valor numeric, p_metodo text, p_observacion text DEFAULT ''
)
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_status text;
  v_initial numeric;
  v_total numeric;
  v_paid numeric;
  v_id bigint;
BEGIN
  PERFORM public.modaplus_verificar_admin();
  IF p_id_plan IS NULL OR p_id_plan <= 0 OR p_valor IS NULL
     OR p_valor <= 0 THEN RAISE EXCEPTION 'Plan o valor inválido.'; END IF;
  IF upper(COALESCE(p_metodo,'')) NOT IN ('EFECTIVO','TRANSFERENCIA','QR') THEN
    RAISE EXCEPTION 'Selecciona un método de pago.';
  END IF;
  SELECT estado,abono_inicial INTO v_status,v_initial
  FROM public.planes_separe WHERE id_plan_separe=p_id_plan FOR UPDATE;
  IF NOT FOUND OR v_status <> 'ACTIVO' THEN
    RAISE EXCEPTION 'Este Plan Separe no permite más abonos.';
  END IF;
  SELECT COALESCE(sum(cantidad*precio_unitario),0) INTO v_total
  FROM public.detalles_plan_separe WHERE id_plan_separe=p_id_plan;
  SELECT COALESCE(sum(valor_abono),0) INTO v_paid
  FROM public.abonos_separe WHERE id_plan_separe=p_id_plan AND estado='ACTIVO';
  IF p_valor > v_total - v_initial - v_paid THEN
    RAISE EXCEPTION 'El abono excede el saldo pendiente.';
  END IF;
  INSERT INTO public.abonos_separe(
    id_plan_separe,fecha_abono,valor_abono,metodo_pago,observacion,estado
  ) VALUES (p_id_plan,current_date,p_valor,upper(p_metodo),
            trim(COALESCE(p_observacion,'')),'ACTIVO')
  RETURNING id_abono INTO v_id;
  RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.anular_abono(p_id bigint)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_plan bigint;
  v_state text;
BEGIN
  PERFORM public.modaplus_verificar_admin();
  SELECT id_plan_separe INTO v_plan FROM public.abonos_separe
  WHERE id_abono=p_id;
  IF v_plan IS NULL THEN RAISE EXCEPTION 'Abono inexistente.'; END IF;
  PERFORM 1 FROM public.planes_separe
    WHERE id_plan_separe=v_plan AND estado='ACTIVO' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'El plan no está activo.'; END IF;
  SELECT estado INTO v_state FROM public.abonos_separe
    WHERE id_abono=p_id FOR UPDATE;
  IF v_state <> 'ACTIVO' THEN RAISE EXCEPTION 'El abono ya fue anulado.'; END IF;
  UPDATE public.abonos_separe
    SET estado='ANULADO',fecha_anulacion=now()
  WHERE id_abono=p_id;
END $$;

-- ANULACION DE PLANES (solo datos ficticios). El criterio 50% requiere
-- revisión jurídica y reconciliación contable ANTES de producción.
CREATE OR REPLACE FUNCTION public.anular_plan_separe(p_id bigint)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_plan public.planes_separe%ROWTYPE;
  v_total numeric;
  v_paid numeric;
  v_percentage numeric;
  v_dest text;
  v_item record;
BEGIN
  PERFORM public.modaplus_verificar_admin();
  SELECT * INTO v_plan FROM public.planes_separe
    WHERE id_plan_separe=p_id FOR UPDATE;
  IF NOT FOUND OR v_plan.estado <> 'ACTIVO' THEN
    RAISE EXCEPTION 'Plan inexistente o ya anulado.';
  END IF;
  SELECT COALESCE(sum(cantidad*precio_unitario),0) INTO v_total
    FROM public.detalles_plan_separe WHERE id_plan_separe=p_id;
  SELECT COALESCE(sum(valor_abono),0) + v_plan.abono_inicial INTO v_paid
    FROM public.abonos_separe
    WHERE id_plan_separe=p_id AND estado='ACTIVO';
  IF v_total <= 0 THEN RAISE EXCEPTION 'El plan no tiene detalle válido.'; END IF;
  v_percentage := 100 * v_paid / v_total;
  v_dest := CASE WHEN v_percentage >= 50 THEN 'SALDO_CLIENTE' ELSE 'TIENDA' END;
  FOR v_item IN SELECT id_variante,cantidad FROM public.detalles_plan_separe
    WHERE id_plan_separe=p_id ORDER BY id_variante
  LOOP
    PERFORM public.modaplus_cambiar_stock(v_item.id_variante, v_item.cantidad);
  END LOOP;
  IF v_dest='SALDO_CLIENTE' AND v_paid > 0 THEN
    UPDATE public.clientes SET saldo_favor=saldo_favor+v_paid
    WHERE id_cliente=v_plan.id_cliente;
  END IF;
  UPDATE public.planes_separe
  SET estado='ANULADO',fecha_anulacion=now(),
    destino_abonos=v_dest,porcentaje_pagado_anulacion=v_percentage
  WHERE id_plan_separe=p_id;
END $$;

REVOKE ALL ON FUNCTION public.guardar_compra(jsonb,jsonb) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.guardar_venta(jsonb,jsonb) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.guardar_plan_separe(jsonb,jsonb) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.registrar_abono_separe(bigint,numeric,text,text)
FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.anular_abono(bigint) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.anular_plan_separe(bigint) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.guardar_compra(jsonb,jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.guardar_venta(jsonb,jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.guardar_plan_separe(jsonb,jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.registrar_abono_separe(bigint,numeric,text,text)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.anular_abono(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.anular_plan_separe(bigint) TO authenticated;
COMMIT;

-- Solo metadatos, sin alterar registros:
SELECT proname AS rpc_disponible FROM pg_proc
WHERE pronamespace='public'::regnamespace
  AND proname IN ('guardar_compra','guardar_venta','guardar_plan_separe',
    'registrar_abono_separe','anular_abono','anular_plan_separe')
ORDER BY proname;
