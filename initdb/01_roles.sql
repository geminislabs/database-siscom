-- ============================================================
-- 01_roles.sql
-- Extensiones, usuario de aplicación y roles de PostgREST
-- Este script se ejecuta como el superusuario de Postgres
-- ============================================================

-- Extensiones requeridas
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE SCHEMA IF NOT EXISTS partman;
CREATE EXTENSION IF NOT EXISTS "pg_partman" SCHEMA partman;

-- Usuario de aplicación
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'siscom') THEN
    CREATE USER siscom WITH PASSWORD 'siscom';
  END IF;
END
$$;

-- Rol anónimo para PostgREST
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'web_anon') THEN
    CREATE ROLE web_anon NOLOGIN;
  END IF;
END
$$;

-- Permisos de conexión y esquema
GRANT CONNECT ON DATABASE "siscom-dev" TO siscom;
GRANT USAGE ON SCHEMA public TO siscom;
GRANT USAGE ON SCHEMA public TO web_anon;

-- Permisos sobre tablas existentes
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO siscom;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO siscom;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO web_anon;

-- Permisos sobre tablas futuras
--
-- OJO: estos dos ALTER DEFAULT PRIVILEGES no llevan FOR ROLE, asi que aplican
-- solo al rol que los ejecuta (el superusuario del initdb). Cubren lo que cree
-- ese mismo rol, NO lo que cree siscom_migrator. Por eso mas abajo se repiten
-- con FOR ROLE siscom_migrator: sin esa segunda copia, cada tabla nueva que
-- creara una migracion nace sin permisos para el usuario de runtime, y la
-- aplicacion se rompe DESPUES de una migracion que reporto exito.
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO siscom;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO siscom;

-- ============================================================
-- Usuario de MIGRACIONES
--
-- Separado del de runtime a proposito: `siscom` solo tiene DML, asi que la
-- aplicacion no puede alterar el esquema en caliente. Solo alembic, desde el
-- paso de despliegue de siscom-admin-api, usa esta credencial.
--
-- Verificado el 6 de septiembre de 2026 contra una replica del esquema de
-- produccion: los permisos de abajo son el minimo con el que la migracion de
-- reconciliacion (026) corre entera. Con menos falla, y falla tarde.
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'siscom_migrator') THEN
    -- La contrasena real se fija fuera de este archivo. Aqui solo se declara
    -- el rol para que los entornos nuevos nazcan con el.
    CREATE USER siscom_migrator WITH PASSWORD 'siscom_migrator';
  END IF;
END
$$;

GRANT CONNECT ON DATABASE "siscom-dev" TO siscom_migrator;

-- CREATE alcanza para crear tablas nuevas, pero NO para alterar las que ya
-- existen: `ALTER TABLE` y `ALTER TYPE` exigen ser dueno del objeto.
GRANT USAGE, CREATE ON SCHEMA public TO siscom_migrator;

-- Las tablas que cree el migrador nacen siendo suyas. Sin estas dos lineas el
-- usuario de runtime se queda fuera de cada tabla nueva: la migracion termina
-- bien y la aplicacion empieza a dar `permission denied`. Comprobado.
ALTER DEFAULT PRIVILEGES FOR ROLE siscom_migrator IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO siscom;

ALTER DEFAULT PRIVILEGES FOR ROLE siscom_migrator IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO siscom;