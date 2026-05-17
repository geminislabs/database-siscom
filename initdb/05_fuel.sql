-- Fuel type
DO $$
BEGIN
    CREATE DOMAIN public.fuel_type_t AS text
    CHECK (VALUE IN (
        'GASOLINE',
        'DIESEL',
        'HYBRID',
        'ELECTRIC',
        'UNKNOWN'
    ));
EXCEPTION WHEN duplicate_object THEN
    NULL;
END
$$;

-- Vehicle class
DO $$
BEGIN
    CREATE DOMAIN public.vehicle_class_t AS text
    CHECK (VALUE IN (
        'MOTORCYCLE',
        'SEDAN',
        'SUV',
        'PICKUP',
        'VAN',
        'LIGHT_TRUCK',
        'HEAVY_TRUCK',
        'BUS',
        'MACHINERY',
        'GENERATOR',
        'UNKNOWN'
    ));
EXCEPTION WHEN duplicate_object THEN
    NULL;
END
$$;

-- Fuel estimation method
DO $$
BEGIN
    CREATE DOMAIN public.fuel_estimation_method_t AS text
    CHECK (VALUE IN (
        'DISTANCE_PROFILE',
        'IGNITION_DISTANCE_HYBRID',
        'OBD_FUEL_RATE',
        'CAN_FUEL_SENSOR'
    ));
EXCEPTION WHEN duplicate_object THEN
    NULL;
END
$$;

-- Ignition source
DO $$
BEGIN
    CREATE DOMAIN public.ignition_source_t AS text
    CHECK (VALUE IN (
        'VIRTUAL',
        'WIRED',
        'OBD',
        'CANBUS',
        'UNKNOWN'
    ));
EXCEPTION WHEN duplicate_object THEN
    NULL;
END
$$;

CREATE TABLE IF NOT EXISTS public.device_profile (
    profile_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id text NOT NULL
        REFERENCES public.devices(device_id) ON DELETE CASCADE,
    ignition_source public.ignition_source_t
        NOT NULL DEFAULT 'VIRTUAL',
    virtual_ignition_on_seconds integer
        NOT NULL DEFAULT 60,
    virtual_ignition_off_seconds integer
        NOT NULL DEFAULT 180,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT device_profile_device_id_key UNIQUE (device_id)
);

CREATE TABLE IF NOT EXISTS public.unit_fuel_profile (
    profile_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_id uuid NOT NULL
        REFERENCES public.units(id) ON DELETE CASCADE,
    fuel_type public.fuel_type_t
        NOT NULL DEFAULT 'UNKNOWN',
    vehicle_class public.vehicle_class_t
        NOT NULL DEFAULT 'UNKNOWN',
    estimation_method public.fuel_estimation_method_t
        NOT NULL DEFAULT 'DISTANCE_PROFILE',
    km_per_liter numeric(8,2),
    idle_liters_per_hour numeric(8,2),
    min_movement_meters integer NOT NULL DEFAULT 100,
    min_speed_kph numeric(6,2) NOT NULL DEFAULT 2.0,
    traffic_penalty_factor numeric(6,3)
        NOT NULL DEFAULT 1.20,
    highway_penalty_factor numeric(6,3)
        NOT NULL DEFAULT 1.10,
    confidence_base numeric(4,3)
        NOT NULL DEFAULT 0.55,
    is_custom boolean NOT NULL DEFAULT false,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT unit_fuel_profile_unit_id_key UNIQUE (unit_id)
);

ALTER TABLE IF EXISTS public.telemetry_hourly_stats
ADD COLUMN IF NOT EXISTS distance_km numeric(10,3),
ADD COLUMN IF NOT EXISTS moving_minutes integer,
ADD COLUMN IF NOT EXISTS idle_minutes integer,
ADD COLUMN IF NOT EXISTS avg_speed_kph numeric(8,2),
ADD COLUMN IF NOT EXISTS max_speed_kph numeric(8,2),
ADD COLUMN IF NOT EXISTS gps_drift_events integer,
ADD COLUMN IF NOT EXISTS traffic_penalty_factor numeric(6,3),
ADD COLUMN IF NOT EXISTS highway_penalty_factor numeric(6,3),
ADD COLUMN IF NOT EXISTS fuel_estimate_liters numeric(10,3),
ADD COLUMN IF NOT EXISTS fuel_confidence_score numeric(4,3),
ADD COLUMN IF NOT EXISTS fuel_estimation_method public.fuel_estimation_method_t,
ADD COLUMN IF NOT EXISTS fuel_metadata jsonb;

CREATE INDEX IF NOT EXISTS idx_device_profile_device_id
ON public.device_profile(device_id);

CREATE INDEX IF NOT EXISTS idx_unit_fuel_profile_unit_id
ON public.unit_fuel_profile(unit_id);


CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW IS DISTINCT FROM OLD THEN
        NEW.updated_at = now();
    END IF;

    RETURN NEW;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'trg_device_profile_updated_at'
    ) THEN
        CREATE TRIGGER trg_device_profile_updated_at
        BEFORE UPDATE ON public.device_profile
        FOR EACH ROW
        EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'trg_unit_fuel_profile_updated_at'
    ) THEN
        CREATE TRIGGER trg_unit_fuel_profile_updated_at
        BEFORE UPDATE ON public.unit_fuel_profile
        FOR EACH ROW
        EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
END
$$;


BEGIN;

CREATE TABLE IF NOT EXISTS public.telemetry_intelligence_hourly_stats (
    device_id text NOT NULL,
    bucket timestamptz NOT NULL,

    samples integer NOT NULL DEFAULT 0,

    sum_speed double precision NOT NULL DEFAULT 0,
    count_speed integer NOT NULL DEFAULT 0,

    distance_km double precision NOT NULL DEFAULT 0,

    last_lat double precision NULL,
    last_lng double precision NULL,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT telemetry_intelligence_hourly_stats_pkey
        PRIMARY KEY (device_id, bucket)
);

-- convertir a hypertable
SELECT create_hypertable(
    'public.telemetry_intelligence_hourly_stats',
    'bucket',
    if_not_exists => TRUE
);

CREATE INDEX IF NOT EXISTS idx_telemetry_intelligence_device_time
ON public.telemetry_intelligence_hourly_stats(device_id, bucket DESC);

CREATE INDEX IF NOT EXISTS idx_telemetry_intelligence_bucket
ON public.telemetry_intelligence_hourly_stats(bucket DESC);

COMMIT;

INSERT INTO public.device_profile (
    device_id,
    ignition_source,
    virtual_ignition_on_seconds,
    virtual_ignition_off_seconds,
    metadata
)
SELECT
    d.device_id,
    'VIRTUAL',
    60,
    180,
    '{}'::jsonb
FROM public.devices d
ON CONFLICT (device_id) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_unit_devices_active_lookup
ON public.unit_devices(device_id)
WHERE unassigned_at IS NULL;