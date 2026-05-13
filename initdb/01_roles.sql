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
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO siscom;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO siscom;