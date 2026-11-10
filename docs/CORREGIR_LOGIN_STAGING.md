# Arreglo de login en prubasmoda

El esquema provisional creó `usuarios` sin la columna `id_cliente` ni FK a `clientes`, pero `SupabaseAuthService.currentAccount` realiza una selección embebida `usuarios(...,clientes(*),usuarios_roles(...))`. PostgREST no puede resolver la relación y devuelve error de consulta, visible como «No fue posible consultar tu cuenta. Revisa tus permisos».

## Corrección
1. Ejecutar **solo en el proyecto provisional `prubasmoda`** el archivo `supabase/staging/04_corregir_login_admin.sql` desde SQL Editor (se requiere el rol `postgres` del editor).
2. Verificar la fila `id_usuario=1` con `estado=ACTIVO`, `id_cliente` no nulo y `nombre_rol=SUPERADMIN`.
3. Actualizar Flutter a este commit y volver a ejecutar en el Android con `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`.
4. El cliente perfil creado es sintético; no se utiliza información del proyecto original.

El código Dart también reconoce SUPERADMIN / SUPER_ADMIN / id_rol=1 como administrador.

## Límites
- No ejecutado ni desplegado a Supabase automáticamente.
- Esta corrección NO habilita escrituras ni RPCs financieras.
- El mensaje genérico de error no demuestra por sí solo que este sea el único problema; si persiste, revisar los logs de PostgREST para conocer el código preciso sin compartir tokens.
