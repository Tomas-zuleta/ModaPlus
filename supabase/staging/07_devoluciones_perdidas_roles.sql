-- MODAPLUS STAGING PASO 07. SOLO prubasmoda, después de 05 y 06.
-- Solicitudes de devolución, pérdidas, roles y rechazo de pedidos.
-- NO es el esquema original del proyecto de producción.
BEGIN;
DO $$
BEGIN
  IF to_regprocedure('public.guardar_venta(jsonb,jsonb)') IS NULL
    OR NOT EXISTS (SELECT 1 FROM public.productos WHERE referencia='DEMO-001') THEN
    RAISE EXCEPTION 'Ejecuta antes los pasos 05 y 06 en prubasmoda.';
  END IF;
END $$;

-- Devoluciones: registrar solicitud, NO entregar dinero ni reintegrar stock
-- automáticamente sin una posterior aprobación y revisión física.
CREATE OR REPLACE FUNCTION public.guardar_devolucion(
  p_devolucion jsonb, p_detalles jsonb
)
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_id bigint;
  v_sale public.ventas%ROWTYPE;
  v_line jsonb;
  v_variant bigint;
  v_qty integer;
  v_sold integer;
  v_claimed integer;
  v_reason text;
  v_description text;
BEGIN
  PERFORM public.modaplus_verificar_admin();
  IF COALESCE((p_devolucion->>'id_devolucion')::bigint,0) <> 0 THEN
    RAISE EXCEPTION 'Una devolución registrada se revisa por separado.';
  END IF;
  IF jsonb_typeof(p_detalles) IS DISTINCT FROM 'array'
    OR jsonb_array_length(p_detalles)=0 THEN
    RAISE EXCEPTION 'Selecciona las prendas que regresaron.';
  END IF;
  v_reason := trim(COALESCE(p_devolucion->>'motivo',''));
  v_description := trim(COALESCE(p_devolucion->>'descripcion',''));
  IF v_reason='' THEN RAISE EXCEPTION 'Describe el motivo de la devolución.'; END IF;
  IF upper(COALESCE(p_devolucion->>'tipo_respuesta','')) <> 'DINERO' THEN
    RAISE EXCEPTION 'Este staging solo registra solicitudes de devolución de dinero.';
  END IF;
  SELECT * INTO v_sale FROM public.ventas
    WHERE id_venta=(p_devolucion->>'id_venta')::bigint FOR UPDATE;
  IF NOT FOUND OR v_sale.estado <> 'APROBADA' THEN
    RAISE EXCEPTION 'Solo puedes solicitar devolución de una venta aprobada.';
  END IF;
  IF v_sale.fecha_venta < current_date - 14 THEN
    RAISE EXCEPTION 'La devolución excede el plazo de pruebas de 14 días.';
  END IF;
  FOR v_line IN SELECT value FROM jsonb_array_elements(p_detalles) LOOP
    v_variant := (v_line->>'id_variante')::bigint;
    v_qty := (v_line->>'cantidad')::integer;
    IF v_qty IS NULL OR v_qty <= 0 THEN
      RAISE EXCEPTION 'La cantidad devuelta debe ser positiva.';
    END IF;
    IF (SELECT count(*) FROM jsonb_array_elements(p_detalles) x
      WHERE (x->>'id_variante')::bigint=v_variant) > 1 THEN
      RAISE EXCEPTION 'No repitas una misma prenda.';
    END IF;
    SELECT COALESCE(sum(cantidad),0) INTO v_sold
    FROM public.detalles_venta
    WHERE id_venta=v_sale.id_venta AND id_variante=v_variant;
    SELECT COALESCE(sum(dd.cantidad),0) INTO v_claimed
    FROM public.detalles_devolucion dd
    JOIN public.devoluciones d ON d.id_devolucion=dd.id_devolucion
    WHERE d.id_venta=v_sale.id_venta AND dd.id_variante=v_variant
      AND d.estado <> 'ANULADA';
    IF v_sold-v_claimed < v_qty THEN
      RAISE EXCEPTION 'La cantidad supera las unidades vendidas no devueltas.';
    END IF;
  END LOOP;
  INSERT INTO public.devoluciones(
    id_venta,id_cliente,fecha_devolucion,motivo,descripcion,
    tipo_respuesta,estado,fecha_estado
  ) VALUES (v_sale.id_venta,v_sale.id_cliente,current_date,v_reason,
    v_description,'DINERO','PENDIENTE',current_date)
  RETURNING id_devolucion INTO v_id;
  FOR v_line IN SELECT value FROM jsonb_array_elements(p_detalles) LOOP
    INSERT INTO public.detalles_devolucion(
      id_devolucion,id_variante,cantidad,motivo,descripcion
    ) VALUES (v_id,(v_line->>'id_variante')::bigint,
      (v_line->>'cantidad')::integer,
      v_reason,v_description);
  END LOOP;
  RETURN v_id;
END $$;

-- Pérdidas: modifica stock solo en una operación autorizada.
CREATE OR REPLACE FUNCTION public.gestionar_perdida(
  p_accion text, p_perdida jsonb
)
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_id bigint;
  v_loss public.perdidas%ROWTYPE;
  v_variante bigint;
  v_qty integer;
  v_reason text;
BEGIN
  PERFORM public.modaplus_verificar_admin();
  IF p_accion='guardar' THEN
    IF COALESCE((p_perdida->>'id_perdida')::bigint,0) > 0 THEN
      RAISE EXCEPTION 'Una pérdida registrada no se puede editar.';
    END IF;
    v_variante := (p_perdida->>'id_variante')::bigint;
    v_qty := (p_perdida->>'cantidad')::integer;
    v_reason := trim(COALESCE(p_perdida->>'motivo',''));
    IF v_variante IS NULL OR v_qty IS NULL OR v_qty <= 0 OR v_reason='' THEN
      RAISE EXCEPTION 'Selecciona la variante, cantidad y motivo.';
    END IF;
    PERFORM public.modaplus_cambiar_stock(v_variante,-v_qty);
    INSERT INTO public.perdidas(
      id_devolucion,id_variante,cantidad,motivo,descripcion,estado
    ) VALUES (
      (p_perdida->>'id_devolucion')::bigint,
      v_variante,v_qty,v_reason,
      trim(COALESCE(p_perdida->>'descripcion','')),'ACTIVA'
    ) RETURNING id_perdida INTO v_id;
    RETURN v_id;
  END IF;
  v_id := (p_perdida->>'id_perdida')::bigint;
  SELECT * INTO v_loss FROM public.perdidas
    WHERE id_perdida=v_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Pérdida inexistente.'; END IF;
  IF p_accion='anular' THEN
    IF v_loss.estado <> 'ACTIVA' THEN
      RAISE EXCEPTION 'La pérdida ya fue anulada.';
    END IF;
    PERFORM public.modaplus_cambiar_stock(v_loss.id_variante,v_loss.cantidad);
    UPDATE public.perdidas SET estado='ANULADA' WHERE id_perdida=v_id;
    RETURN v_id;
  END IF;
  IF p_accion='eliminar' THEN
    IF v_loss.estado <> 'ANULADA' THEN
      RAISE EXCEPTION 'Anula la pérdida antes de eliminarla.';
    END IF;
    DELETE FROM public.perdidas WHERE id_perdida=v_id;
    RETURN v_id;
  END IF;
  RAISE EXCEPTION 'Acción de pérdida no admitida.';
END $$;

-- Asignaciones de roles: no crear cuentas de Auth desde el teléfono.
CREATE OR REPLACE FUNCTION public.actualizar_roles_usuario(
  p_usuario bigint, p_roles bigint[]
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_auth uuid;
  v_current bigint[];
BEGIN
  PERFORM public.modaplus_verificar_admin();
  SELECT auth_user_id INTO v_auth FROM public.usuarios
    WHERE id_usuario=p_usuario FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Usuario inexistente.'; END IF;
  IF p_roles IS NULL OR array_length(p_roles,1) IS NULL
     OR EXISTS (SELECT 1 FROM unnest(p_roles) r
         WHERE NOT EXISTS (SELECT 1 FROM public.roles
           WHERE id_rol=r AND estado='ACTIVO')) THEN
    RAISE EXCEPTION 'Selecciona roles existentes y activos.';
  END IF;
  IF v_auth=(SELECT auth.uid()) AND NOT (1=ANY(p_roles)) THEN
    RAISE EXCEPTION 'No puedes quitarte tu propio rol de Superadmin.';
  END IF;
  SELECT array_agg(id_rol) INTO v_current FROM public.usuarios_roles
    WHERE id_usuario=p_usuario;
  IF 1=ANY(COALESCE(v_current,ARRAY[]::bigint[]))
    AND NOT 1=ANY(p_roles) THEN
    RAISE EXCEPTION 'La cuenta Superadmin está protegida.';
  END IF;
  DELETE FROM public.usuarios_roles WHERE id_usuario=p_usuario;
  INSERT INTO public.usuarios_roles(id_usuario,id_rol)
  SELECT p_usuario,id FROM unnest(p_roles) AS id
  ON CONFLICT DO NOTHING;
END $$;

-- Rechazo de pedidos online PENDIENTES, sin suponer stock reservado.
CREATE OR REPLACE FUNCTION public.rechazar_venta_online(
  p_id_venta bigint, p_motivo text
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  v_sale public.ventas%ROWTYPE;
BEGIN
  PERFORM public.modaplus_verificar_admin();
  IF length(trim(COALESCE(p_motivo,''))) < 4 THEN
    RAISE EXCEPTION 'Describe el motivo del rechazo.';
  END IF;
  SELECT * INTO v_sale FROM public.ventas
    WHERE id_venta=p_id_venta FOR UPDATE;
  IF NOT FOUND OR v_sale.estado <> 'PENDIENTE'
    OR v_sale.origen <> 'TIENDA_ONLINE' THEN
    RAISE EXCEPTION 'Solo pueden rechazarse pedidos online pendientes.';
  END IF;
  UPDATE public.ventas
  SET estado='RECHAZADA',motivo_rechazo=trim(p_motivo)
  WHERE id_venta=p_id_venta;
END $$;

REVOKE ALL ON FUNCTION public.guardar_devolucion(jsonb,jsonb) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.gestionar_perdida(text,jsonb) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.actualizar_roles_usuario(bigint,bigint[])
  FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.rechazar_venta_online(bigint,text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.guardar_devolucion(jsonb,jsonb)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.gestionar_perdida(text,jsonb)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.actualizar_roles_usuario(bigint,bigint[])
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.rechazar_venta_online(bigint,text)
  TO authenticated;
COMMIT;

SELECT proname FROM pg_proc
WHERE pronamespace='public'::regnamespace
  AND proname IN ('guardar_devolucion','gestionar_perdida',
    'actualizar_roles_usuario','rechazar_venta_online')
ORDER BY proname;
