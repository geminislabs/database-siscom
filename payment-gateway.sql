-- ================================================================
-- GeminisLabs · Migración de Pagos Multi-gateway v1
-- Archivo: payment-gateway.sql

BEGIN;

-- ────────────────────────────────────────────────────────────────
-- TIPOS ENUM
-- ────────────────────────────────────────────────────────────────

DO $$ BEGIN
    CREATE TYPE public.payment_gateway AS ENUM (
        'stripe'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE public.payment_method_type AS ENUM (
        'card',
        'oxxo',
        'spei',
        'bank_transfer'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE public.gateway_event_status AS ENUM (
        'processed',
        'failed',
        'skipped'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;


-- ────────────────────────────────────────────────────────────────
-- 1. payment_gateway_customers
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.payment_gateway_customers (
    id                   uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id           uuid NOT NULL,
    gateway              public.payment_gateway NOT NULL,
    external_customer_id text NOT NULL,
    created_at           timestamptz DEFAULT now() NOT NULL,
    updated_at           timestamptz DEFAULT now() NOT NULL,

    CONSTRAINT pgc_pkey
        PRIMARY KEY (id),
    CONSTRAINT pgc_account_gateway_key
        UNIQUE (account_id, gateway),
    CONSTRAINT pgc_external_gateway_key
        UNIQUE (gateway, external_customer_id),
    CONSTRAINT pgc_account_fkey
        FOREIGN KEY (account_id)
        REFERENCES public.accounts(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_pgc_account
    ON public.payment_gateway_customers (account_id);
CREATE INDEX IF NOT EXISTS idx_pgc_gateway
    ON public.payment_gateway_customers (gateway, external_customer_id);


-- ────────────────────────────────────────────────────────────────
-- 2. payment_methods
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.payment_methods (
    id             uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id     uuid NOT NULL,
    gateway        public.payment_gateway NOT NULL,
    external_token text NOT NULL,
    type           public.payment_method_type DEFAULT 'card' NOT NULL,
    brand          text NULL,
    last4          char(4) NULL,
    exp_month      smallint NULL,
    exp_year       smallint NULL,
    fingerprint    text NULL,
    metadata       jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_default     bool DEFAULT false NOT NULL,
    created_at     timestamptz DEFAULT now() NOT NULL,
    updated_at     timestamptz DEFAULT now() NOT NULL,

    CONSTRAINT pm_pkey
        PRIMARY KEY (id),
    CONSTRAINT pm_external_gateway_key
        UNIQUE (gateway, external_token),
    CONSTRAINT pm_exp_month_chk
        CHECK (exp_month IS NULL OR exp_month BETWEEN 1 AND 12),
    CONSTRAINT pm_exp_year_chk
        CHECK (exp_year IS NULL OR exp_year >= 2024),
    CONSTRAINT pm_account_fkey
        FOREIGN KEY (account_id)
        REFERENCES public.accounts(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_pm_account
    ON public.payment_methods (account_id);
CREATE INDEX IF NOT EXISTS idx_pm_gateway
    ON public.payment_methods (gateway, external_token);
CREATE INDEX IF NOT EXISTS idx_pm_account_gateway
    ON public.payment_methods (account_id, gateway);
CREATE UNIQUE INDEX IF NOT EXISTS uq_pm_default_per_account
    ON public.payment_methods (account_id)
    WHERE is_default = true;


-- ────────────────────────────────────────────────────────────────
-- 3. payment_gateway_events
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.payment_gateway_events (
    gateway           public.payment_gateway NOT NULL,
    external_event_id text NOT NULL,
    event_type        text NOT NULL,
    processed_at      timestamptz DEFAULT now() NOT NULL,
    status            public.gateway_event_status DEFAULT 'processed' NOT NULL,
    error_message     text NULL,
    payload           jsonb NULL,

    CONSTRAINT pge_pkey
        PRIMARY KEY (gateway, external_event_id)
);

CREATE INDEX IF NOT EXISTS idx_pge_gateway_type
    ON public.payment_gateway_events (gateway, event_type);
CREATE INDEX IF NOT EXISTS idx_pge_processed
    ON public.payment_gateway_events (processed_at DESC);


ALTER TABLE public.payments
    ADD COLUMN IF NOT EXISTS gateway public.payment_gateway DEFAULT NULL;
ALTER TABLE public.payments
    ADD COLUMN IF NOT EXISTS gateway_payment_id text;
ALTER TABLE public.payments
    ADD COLUMN IF NOT EXISTS idempotency_key text;
ALTER TABLE public.payments
    ADD COLUMN IF NOT EXISTS payment_method_id uuid;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'payments'
          AND constraint_name = 'payments_payment_method_id_fkey'
    ) THEN
        ALTER TABLE public.payments
            ADD CONSTRAINT payments_payment_method_id_fkey
            FOREIGN KEY (payment_method_id)
            REFERENCES public.payment_methods(id)
            ON DELETE SET NULL;
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_gateway_payment_id
    ON public.payments (gateway_payment_id)
    WHERE gateway_payment_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_idempotency_key
    ON public.payments (idempotency_key)
    WHERE idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_payments_payment_method_id
    ON public.payments (payment_method_id)
    WHERE payment_method_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_subscriptions_external_id
    ON public.subscriptions (external_id)
    WHERE external_id IS NOT NULL;


COMMIT;