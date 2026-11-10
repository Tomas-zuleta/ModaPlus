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
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
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
END $$;
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
