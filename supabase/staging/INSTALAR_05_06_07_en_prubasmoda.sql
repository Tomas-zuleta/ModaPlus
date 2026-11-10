-- MODAPLUS — INSTALADOR DE STAGING (tres pasos en una sola consulta).
-- EXCLUSIVAMENTE PARA prubasmoda, NUNCA usar en Supabase original.
-- Requiere que hayas ejecutado los pasos 01-04 y tu cuenta SUPERADMIN ya funcione.
-- CONTIENE operaciones ficticias; NO usa claves privadas ni información real.
-- IMPORTANTE: no es una copia verificada de la base de datos de tu compañero.
-- Antes de ejecutar, COMPRUEBA el nombre del proyecto en el Dashboard.

-- ========= PASO 5 =========

-- MODAPLUS STAGING PASO 05: solo prubasmoda (NO PRODUCCION).
-- Requiere pasos 01-04, usuario de pruebas SUPERADMIN y DEMO-001.
-- Extiende los campos usados por Flutter y habilita CRUD de tablas maestras.
BEGIN;

DO $guard$
BEGIN
  IF to_regclass('public.usuarios_roles') IS NULL
     OR to_regclass('public.variantes_producto') IS NULL
     OR NOT EXISTS (SELECT 1 FROM public.productos WHERE referencia = 'DEMO-001')
     OR NOT EXISTS (SELECT 1 FROM public.roles
                    WHERE id_rol = 1 AND nombre_rol = 'SUPERADMIN')
  THEN
    RAISE EXCEPTION 'Entorno incorrecto: se requieren los datos de staging DEMO-001 y SUPERADMIN.';
  END IF;
END
$guard$;

-- Campos del contrato de los formularios de la web y la app.
ALTER TABLE public.proveedores
  ADD COLUMN IF NOT EXISTS nit text,
  ADD COLUMN IF NOT EXISTS razon_social text,
  ADD COLUMN IF NOT EXISTS contacto text,
  ADD COLUMN IF NOT EXISTS telefono text,
  ADD COLUMN IF NOT EXISTS correo text,
  ADD COLUMN IF NOT EXISTS direccion text;
UPDATE public.proveedores SET
  razon_social = COALESCE(razon_social, nombre_proveedor),
  nit = COALESCE(nit, 'DEMO-' || id_proveedor::text)
WHERE razon_social IS NULL OR nit IS NULL;

-- La tabla provisional tenía nombre_proveedor NOT NULL.
-- El formulario utiliza razon_social: sincronizar ambos campos.
CREATE OR REPLACE FUNCTION public.modaplus_sync_supplier_name()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  NEW.razon_social := COALESCE(NULLIF(trim(NEW.razon_social), ''),
                               NULLIF(trim(NEW.nombre_proveedor), ''));
  IF NEW.razon_social IS NULL THEN
    RAISE EXCEPTION 'La razon social es obligatoria.';
  END IF;
  NEW.nombre_proveedor := NEW.razon_social;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS modaplus_supplier_name ON public.proveedores;
CREATE TRIGGER modaplus_supplier_name
BEFORE INSERT OR UPDATE ON public.proveedores FOR EACH ROW
EXECUTE FUNCTION public.modaplus_sync_supplier_name();
-- En inserciones PostgREST se requieren valores no nulos en nombre_proveedor.
-- BEFORE INSERT trigger se ejecuta antes del chequeo NOT NULL.

ALTER TABLE public.clientes
  ADD COLUMN IF NOT EXISTS tipo_documento text DEFAULT 'CC',
  ADD COLUMN IF NOT EXISTS identificacion text,
  ADD COLUMN IF NOT EXISTS telefono text,
  ADD COLUMN IF NOT EXISTS direccion text;

ALTER TABLE public.colores
  ADD COLUMN IF NOT EXISTS codigo_hex text DEFAULT '#808080',
  ADD COLUMN IF NOT EXISTS codigos_hex text[] DEFAULT ARRAY['#808080']::text[];

ALTER TABLE public.variantes_producto
  ADD COLUMN IF NOT EXISTS imagen_url text,
  ADD COLUMN IF NOT EXISTS motivo_baja text,
  ADD COLUMN IF NOT EXISTS fecha_baja date;

ALTER TABLE public.productos
  ADD COLUMN IF NOT EXISTS fecha_creacion date DEFAULT current_date;

ALTER TABLE public.planes_separe
  ADD COLUMN IF NOT EXISTS comprobante_inicial text,
  ADD COLUMN IF NOT EXISTS comprobante_inicial_nombre text,
  ADD COLUMN IF NOT EXISTS destino_abonos text,
  ADD COLUMN IF NOT EXISTS porcentaje_pagado_anulacion numeric(8,3),
  ADD COLUMN IF NOT EXISTS fecha_anulacion timestamptz;

ALTER TABLE public.abonos_separe
  ADD COLUMN IF NOT EXISTS fecha_anulacion timestamptz,
  ADD COLUMN IF NOT EXISTS anulado_por bigint,
  ADD COLUMN IF NOT EXISTS comprobante text,
  ADD COLUMN IF NOT EXISTS comprobante_nombre text;

ALTER TABLE public.devoluciones
  ADD COLUMN IF NOT EXISTS fecha_estado date;

ALTER TABLE public.ventas
  ADD COLUMN IF NOT EXISTS fecha_limite_pago date,
  ADD COLUMN IF NOT EXISTS fecha_entrega date;

-- Nadie puede aumentar o disminuir el stock con un UPDATE normal del catálogo.
-- Solo las transacciones SQL del paso 06 habilitan el marcador local.
CREATE OR REPLACE FUNCTION public.modaplus_protect_stock()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF COALESCE(NEW.stock_actual, 0) <> 0
       AND current_setting('modaplus.stock_rpc', true) IS DISTINCT FROM 'yes' THEN
      RAISE EXCEPTION 'El stock inicial debe ser cero: usa una compra.';
    END IF;
  ELSIF OLD.stock_actual IS DISTINCT FROM NEW.stock_actual
     AND current_setting('modaplus.stock_rpc', true) IS DISTINCT FROM 'yes' THEN
    RAISE EXCEPTION 'Stock protegido: registra una compra, venta o movimiento.';
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS modaplus_stock_protection ON public.variantes_producto;
CREATE TRIGGER modaplus_stock_protection
BEFORE INSERT OR UPDATE ON public.variantes_producto
FOR EACH ROW EXECUTE FUNCTION public.modaplus_protect_stock();

-- CRUD administrativo SOLO para datos maestros, con autenticación y RLS.
-- Las tablas financieras siguen sin permisos de escritura directa.
DO $policies$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'categorias','tallas','colores','proveedores','clientes',
    'roles','productos','variantes_producto'
  ] LOOP
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', t);
    EXECUTE format('DROP POLICY IF EXISTS modaplus_admin_crud ON public.%I', t);
    EXECUTE format(
      'CREATE POLICY modaplus_admin_crud ON public.%I FOR ALL TO authenticated
       USING ((SELECT public.modaplus_es_administrador()))
       WITH CHECK ((SELECT public.modaplus_es_administrador()))', t);
  END LOOP;
  FOREACH t IN ARRAY ARRAY[
    'usuarios','usuarios_roles','roles_permisos','modulos','permisos',
    'compras','detalles_compra','ventas','detalles_venta',
    'planes_separe','detalles_plan_separe','abonos_separe',
    'devoluciones','detalles_devolucion','perdidas'
  ] LOOP
    EXECUTE format('GRANT SELECT ON public.%I TO authenticated', t);
  END LOOP;
END
$policies$;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Nunca permitir que el CRUD genérico elimine o desactive el rol principal
-- ni cambie sus datos desde un cliente autenticado.
CREATE OR REPLACE FUNCTION public.modaplus_proteger_rol_admin()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $
BEGIN
  IF OLD.id_rol = 1 THEN
    IF TG_OP = 'DELETE' THEN
      RAISE EXCEPTION 'El rol principal de pruebas no se puede eliminar.';
    END IF;
    IF NEW.estado <> 'ACTIVO'
       OR NEW.nombre_rol <> OLD.nombre_rol THEN
      RAISE EXCEPTION 'El rol Superadmin no se puede desactivar ni renombrar.';
    END IF;
  END IF;
  RETURN COALESCE(NEW, OLD);
END $;
DROP TRIGGER IF EXISTS modaplus_proteger_superadmin ON public.roles;
CREATE TRIGGER modaplus_proteger_superadmin
BEFORE UPDATE OR DELETE ON public.roles FOR EACH ROW
EXECUTE FUNCTION public.modaplus_proteger_rol_admin();

-- Registro de módulo/acción para formularios y permisos (solo ficticio).
INSERT INTO public.modulos(codigo) VALUES
 ('dashboard'),('inventario'),('colores'),('tallas'),('categorias'),
 ('compras'),('proveedores'),('clientes'),('roles'),('usuarios'),
 ('ventas'),('separe'),('abonos'),('devoluciones'),('perdidas')
ON CONFLICT (codigo) DO NOTHING;
INSERT INTO public.permisos(codigo) VALUES
 ('view'),('create'),('edit'),('delete'),('annul')
ON CONFLICT (codigo) DO NOTHING;

COMMIT;

-- Verificar los campos de escritura (solo consulta).
SELECT
  (SELECT count(*) FROM pg_policies
    WHERE schemaname = 'public' AND policyname = 'modaplus_admin_crud')
    AS politicas_crud,
  (SELECT count(*) FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'proveedores'
      AND column_name = 'razon_social') AS campo_proveedor,
  (SELECT count(*) FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'clientes'
      AND column_name = 'identificacion') AS campo_cliente;


-- ========= PASO 6 =========

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


-- ========= PASO 7 =========

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


-- ========= COMPROBACION FINAL (SIN MUTACIONES) =========
SELECT
  (SELECT count(*) FROM pg_proc
     WHERE pronamespace='public'::regnamespace AND proname IN
      ('guardar_compra','guardar_venta','guardar_plan_separe','registrar_abono_separe',
       'anular_plan_separe','anular_abono','guardar_devolucion','gestionar_perdida',
       'actualizar_roles_usuario','rechazar_venta_online')) AS rpc_instalados,
  (SELECT count(*) FROM pg_policies
     WHERE schemaname='public' AND policyname='modaplus_admin_crud') AS modulos_crud,
  (SELECT count(*) FROM public.productos
     WHERE referencia='DEMO-001') AS productos_demo;
