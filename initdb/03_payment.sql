-- ============================================================
-- 03_payment.sql
-- Payment gateway: enums, tablas de facturación avanzada,
-- cupones, descuentos, créditos, trials y notificaciones
-- ============================================================

-- ─────────────────────────────────────────────
-- ENUMS
-- ─────────────────────────────────────────────

DO $$ BEGIN CREATE TYPE public.payment_gateway AS ENUM (
  'stripe', 'conekta', 'mercadopago', 'paypal', 'manual'
); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE public.payment_method_type AS ENUM (
  'card', 'cash_voucher', 'bank_transfer', 'bank_redirect',
  'wallet', 'installments', 'real_time', 'loyalty_points',
  'gift_card', 'crypto', 'manual'
); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE public.payment_status AS ENUM (
  'PENDING', 'REQUIRES_ACTION', 'PROCESSING', 'SUCCESS',
  'FAILED', 'CANCELED', 'DISPUTED', 'REFUNDED', 'PARTIALLY_REFUNDED'
); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE public.invoice_status AS ENUM (
  'DRAFT', 'OPEN', 'PAID', 'PAST_DUE', 'VOID', 'UNCOLLECTIBLE'
); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE public.coupon_duration AS ENUM (
  'once', 'repeating', 'forever'
); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE public.discount_type AS ENUM (
  'percentage', 'fixed_amount', 'volume', 'referral'
); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE public.gateway_event_status AS ENUM (
  'processed', 'failed', 'skipped'
); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─────────────────────────────────────────────
-- GATEWAY CUSTOMERS / EVENTS
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.payment_gateway_customers (
  id                   uuid        NOT NULL DEFAULT gen_random_uuid(),
  account_id           uuid        NOT NULL,
  gateway              public.payment_gateway NOT NULL,
  external_customer_id text        NOT NULL,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pgc_pkey                PRIMARY KEY (id),
  CONSTRAINT pgc_account_gateway_key UNIQUE (account_id, gateway),
  CONSTRAINT pgc_external_key        UNIQUE (gateway, external_customer_id),
  CONSTRAINT pgc_account_fkey        FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_pgc_account ON public.payment_gateway_customers (account_id);
CREATE INDEX IF NOT EXISTS idx_pgc_gateway ON public.payment_gateway_customers (gateway, external_customer_id);

CREATE TABLE IF NOT EXISTS public.payment_gateway_events (
  gateway           public.payment_gateway      NOT NULL,
  external_event_id text                        NOT NULL,
  event_type        text                        NOT NULL,
  event_status      public.gateway_event_status NOT NULL DEFAULT 'processed',
  payload           jsonb                       NULL,
  error_message     text                        NULL,
  retry_count       int                         NOT NULL DEFAULT 0,
  processed_at      timestamptz                 NOT NULL DEFAULT now(),
  CONSTRAINT pge_pkey PRIMARY KEY (gateway, external_event_id)
);
CREATE INDEX IF NOT EXISTS idx_pge_type      ON public.payment_gateway_events (gateway, event_type);
CREATE INDEX IF NOT EXISTS idx_pge_processed ON public.payment_gateway_events (processed_at DESC);

-- ─────────────────────────────────────────────
-- PAYMENT METHODS
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.payment_methods (
  id             uuid        NOT NULL DEFAULT gen_random_uuid(),
  account_id     uuid        NOT NULL,
  gateway        public.payment_gateway     NOT NULL,
  method_type    public.payment_method_type NOT NULL DEFAULT 'card',
  external_token text        NOT NULL,
  metadata       jsonb       NOT NULL DEFAULT '{}',
  brand          text        NULL,
  last4          char(4)     NULL,
  exp_month      smallint    NULL,
  exp_year       smallint    NULL,
  fingerprint    text        NULL,
  is_default     bool        NOT NULL DEFAULT false,
  is_active      bool        NOT NULL DEFAULT true,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pm_pkey          PRIMARY KEY (id),
  CONSTRAINT pm_external_key  UNIQUE (gateway, external_token),
  CONSTRAINT pm_exp_month_chk CHECK (exp_month IS NULL OR exp_month BETWEEN 1 AND 12),
  CONSTRAINT pm_exp_year_chk  CHECK (exp_year  IS NULL OR exp_year >= 2024),
  CONSTRAINT pm_account_fkey  FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_pm_account         ON public.payment_methods (account_id);
CREATE INDEX IF NOT EXISTS idx_pm_gateway         ON public.payment_methods (gateway, external_token);
CREATE INDEX IF NOT EXISTS idx_pm_account_gateway ON public.payment_methods (account_id, gateway);
CREATE UNIQUE INDEX IF NOT EXISTS uq_pm_default
  ON public.payment_methods (account_id) WHERE is_default = true;

-- ─────────────────────────────────────────────
-- FISCAL / TAX
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.fiscal_profiles (
  id             uuid      NOT NULL DEFAULT gen_random_uuid(),
  account_id     uuid      NOT NULL,
  rfc            text      NOT NULL,
  razon_social   text      NOT NULL,
  regimen_fiscal text      NOT NULL,
  codigo_postal  char(5)   NOT NULL,
  cfdi_use       text      NOT NULL DEFAULT 'G03',
  is_default     bool      NOT NULL DEFAULT false,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fsc_pkey        PRIMARY KEY (id),
  CONSTRAINT fsc_rfc_length  CHECK (char_length(rfc) IN (12, 13)),
  CONSTRAINT fsc_cp_digits   CHECK (codigo_postal ~ '^\d{5}$'),
  CONSTRAINT fsc_account_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_fiscal_account ON public.fiscal_profiles (account_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_fiscal_default
  ON public.fiscal_profiles (account_id) WHERE is_default = true;

CREATE TABLE IF NOT EXISTS public.tax_rates (
  id            uuid         NOT NULL DEFAULT gen_random_uuid(),
  name          text         NOT NULL,
  country       char(2)      NOT NULL,
  region        text         NULL,
  rate_percent  numeric(6,4) NOT NULL,
  is_inclusive  bool         NOT NULL DEFAULT false,
  sat_tax_key   text         NULL DEFAULT '002',
  is_active     bool         NOT NULL DEFAULT true,
  valid_from    date         NOT NULL DEFAULT CURRENT_DATE,
  valid_until   date         NULL,
  created_at    timestamptz  NOT NULL DEFAULT now(),
  CONSTRAINT tr_pkey PRIMARY KEY (id)
);

-- IVA México 16% (idempotente)
INSERT INTO public.tax_rates (name, country, rate_percent, sat_tax_key, valid_from)
VALUES ('IVA México 16%', 'MX', 16.0000, '002', '2014-01-01')
ON CONFLICT DO NOTHING;

-- ─────────────────────────────────────────────
-- COUPONS / PROMO CODES
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.coupons (
  id                uuid                   NOT NULL DEFAULT gen_random_uuid(),
  internal_name     text                   NOT NULL,
  discount_type     public.discount_type   NOT NULL,
  amount_off        numeric(10,2)          NULL,
  currency          text                   NULL DEFAULT 'MXN',
  percent_off       numeric(5,4)           NULL,
  coupon_duration   public.coupon_duration NOT NULL DEFAULT 'once',
  duration_in_months int                   NULL,
  max_redemptions   int                    NULL,
  times_redeemed    int                    NOT NULL DEFAULT 0,
  redeem_by         timestamptz            NULL,
  min_amount        numeric(10,2)          NULL,
  first_time_only   bool                   NOT NULL DEFAULT false,
  applies_to_plans  uuid[]                 NULL,
  gateway           public.payment_gateway NULL,
  gateway_coupon_id text                   NULL,
  is_active         bool                   NOT NULL DEFAULT true,
  metadata          jsonb                  NOT NULL DEFAULT '{}',
  created_by        uuid                   NOT NULL,
  created_at        timestamptz            NOT NULL DEFAULT now(),
  updated_at        timestamptz            NOT NULL DEFAULT now(),
  CONSTRAINT cp_pkey       PRIMARY KEY (id),
  CONSTRAINT cp_value_chk  CHECK (
    (amount_off IS NOT NULL AND percent_off IS NULL) OR
    (amount_off IS NULL     AND percent_off IS NOT NULL)
  ),
  CONSTRAINT cp_repeating_chk CHECK (
    coupon_duration != 'repeating' OR duration_in_months IS NOT NULL
  ),
  CONSTRAINT cp_percent_chk CHECK (
    percent_off IS NULL OR (percent_off > 0 AND percent_off <= 1)
  ),
  CONSTRAINT cp_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);

CREATE TABLE IF NOT EXISTS public.promotion_codes (
  id                    uuid                   NOT NULL DEFAULT gen_random_uuid(),
  coupon_id             uuid                   NOT NULL,
  code                  text                   NOT NULL,
  max_redemptions       int                    NULL,
  times_redeemed        int                    NOT NULL DEFAULT 0,
  expires_at            timestamptz            NULL,
  restricted_to_account uuid                   NULL,
  is_active             bool                   NOT NULL DEFAULT true,
  gateway               public.payment_gateway NULL,
  gateway_promo_id      text                   NULL,
  created_by            uuid                   NOT NULL,
  created_at            timestamptz            NOT NULL DEFAULT now(),
  CONSTRAINT pc_pkey        PRIMARY KEY (id),
  CONSTRAINT pc_code_key    UNIQUE (code),
  CONSTRAINT pc_coupon_fkey  FOREIGN KEY (coupon_id)             REFERENCES public.coupons(id),
  CONSTRAINT pc_account_fkey FOREIGN KEY (restricted_to_account) REFERENCES public.accounts(id),
  CONSTRAINT pc_created_fkey FOREIGN KEY (created_by)            REFERENCES public.users(id)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_promo_code_lower
  ON public.promotion_codes (LOWER(code));

-- ─────────────────────────────────────────────
-- INVOICES
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.invoices (
  id                    uuid                   NOT NULL DEFAULT gen_random_uuid(),
  account_id            uuid                   NOT NULL,
  organization_id       uuid                   NOT NULL,
  subscription_id       uuid                   NULL,
  gateway               public.payment_gateway NULL,
  external_invoice_id   text                   NULL,
  invoice_number        text                   NOT NULL,
  invoice_status        public.invoice_status  NOT NULL DEFAULT 'DRAFT',
  subtotal              numeric(10,2)          NOT NULL,
  discount_amount       numeric(10,2)          NOT NULL DEFAULT 0,
  tax_amount            numeric(10,2)          NOT NULL DEFAULT 0,
  total_amount          numeric(10,2)          NOT NULL,
  currency              text                   NOT NULL DEFAULT 'MXN',
  period_start          timestamptz            NULL,
  period_end            timestamptz            NULL,
  due_at                timestamptz            NULL,
  paid_at               timestamptz            NULL,
  voided_at             timestamptz            NULL,
  invoice_pdf_url       text                   NULL,
  fiscal_profile_id     uuid                   NULL,
  receiver_rfc          text                   NULL,
  receiver_razon_social text                   NULL,
  receiver_regimen      text                   NULL,
  receiver_cp           char(5)                NULL,
  cfdi_use              text                   NULL,
  cfdi_payment_form     text                   NULL,
  cfdi_payment_method   text                   NULL DEFAULT 'PUE',
  cfdi_uuid             text                   NULL,
  cfdi_xml_url          text                   NULL,
  cfdi_pdf_url          text                   NULL,
  cfdi_stamped_at       timestamptz            NULL,
  provider_response     jsonb                  NULL,
  metadata              jsonb                  NOT NULL DEFAULT '{}',
  created_at            timestamptz            NOT NULL DEFAULT now(),
  updated_at            timestamptz            NOT NULL DEFAULT now(),
  CONSTRAINT inv_pkey          PRIMARY KEY (id),
  CONSTRAINT inv_number_key    UNIQUE (invoice_number),
  CONSTRAINT inv_cfdi_uuid_key UNIQUE (cfdi_uuid),
  CONSTRAINT inv_account_fkey  FOREIGN KEY (account_id)       REFERENCES public.accounts(id),
  CONSTRAINT inv_org_fkey      FOREIGN KEY (organization_id)  REFERENCES public.organizations(id),
  CONSTRAINT inv_sub_fkey      FOREIGN KEY (subscription_id)  REFERENCES public.subscriptions(id),
  CONSTRAINT inv_fiscal_fkey   FOREIGN KEY (fiscal_profile_id) REFERENCES public.fiscal_profiles(id)
);
CREATE INDEX IF NOT EXISTS idx_inv_account  ON public.invoices (account_id);
CREATE INDEX IF NOT EXISTS idx_inv_org      ON public.invoices (organization_id);
CREATE INDEX IF NOT EXISTS idx_inv_sub      ON public.invoices (subscription_id);
CREATE INDEX IF NOT EXISTS idx_inv_status   ON public.invoices (invoice_status);
CREATE INDEX IF NOT EXISTS idx_inv_due_open ON public.invoices (due_at) WHERE invoice_status = 'OPEN';
CREATE INDEX IF NOT EXISTS idx_inv_cfdi     ON public.invoices (cfdi_uuid) WHERE cfdi_uuid IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.invoice_line_items (
  id              uuid          NOT NULL DEFAULT gen_random_uuid(),
  invoice_id      uuid          NOT NULL,
  description     text          NOT NULL,
  line_type       text          NOT NULL,
  quantity        numeric(10,4) NOT NULL DEFAULT 1,
  unit_amount     numeric(10,2) NOT NULL,
  discount_amount numeric(10,2) NOT NULL DEFAULT 0,
  tax_amount      numeric(10,2) NOT NULL DEFAULT 0,
  total_amount    numeric(10,2) NOT NULL,
  period_start    timestamptz   NULL,
  period_end      timestamptz   NULL,
  plan_id         uuid          NULL,
  sat_product_key text          NULL,
  sat_unit_key    text          NULL DEFAULT 'E48',
  sort_order      int           NOT NULL DEFAULT 0,
  metadata        jsonb         NOT NULL DEFAULT '{}',
  created_at      timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT li_pkey         PRIMARY KEY (id),
  CONSTRAINT li_invoice_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoices(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_li_invoice ON public.invoice_line_items (invoice_id);

CREATE TABLE IF NOT EXISTS public.invoice_line_item_taxes (
  id             uuid          NOT NULL DEFAULT gen_random_uuid(),
  line_item_id   uuid          NOT NULL,
  tax_rate_id    uuid          NOT NULL,
  taxable_amount numeric(10,2) NOT NULL,
  tax_amount     numeric(10,2) NOT NULL,
  created_at     timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT lit_pkey          PRIMARY KEY (id),
  CONSTRAINT lit_line_fkey     FOREIGN KEY (line_item_id) REFERENCES public.invoice_line_items(id) ON DELETE CASCADE,
  CONSTRAINT lit_tax_rate_fkey FOREIGN KEY (tax_rate_id)  REFERENCES public.tax_rates(id)
);
CREATE INDEX IF NOT EXISTS idx_lit_line ON public.invoice_line_item_taxes (line_item_id);

-- ─────────────────────────────────────────────
-- PAYMENTS (full gateway version)
-- ─────────────────────────────────────────────

-- Nota: existe una tabla `payments` básica en 02_schema.sql.
-- En producción se migra a esta versión completa. Para dev,
-- verificamos si ya existe y la reemplazamos si es la versión básica.

DO $$
BEGIN
  -- Si la tabla payments no tiene la columna gateway_payment_id es la versión básica.
  -- La renombramos y creamos la versión completa.
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'payments' AND column_name = 'gateway_payment_id'
  ) THEN
    ALTER TABLE public.payments RENAME TO payments_legacy;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.payments (
  id                  uuid                       NOT NULL DEFAULT gen_random_uuid(),
  invoice_id          uuid                       NOT NULL,
  account_id          uuid                       NOT NULL,
  organization_id     uuid                       NOT NULL,
  gateway             public.payment_gateway     NOT NULL,
  gateway_payment_id  text                       NULL,
  idempotency_key     text                       NULL,
  payment_method_type public.payment_method_type NOT NULL,
  payment_method_id   uuid                       NULL,
  payment_method_meta jsonb                      NOT NULL DEFAULT '{}',
  amount              numeric(10,2)              NOT NULL,
  currency            text                       NOT NULL DEFAULT 'MXN',
  refunded_amount     numeric(10,2)              NOT NULL DEFAULT 0,
  installments        int                        NULL,
  installment_amount  numeric(10,2)              NULL,
  payment_status      public.payment_status      NOT NULL DEFAULT 'PENDING',
  authorized_at       timestamptz                NULL,
  captured_at         timestamptz                NULL,
  initiated_at        timestamptz                NULL,
  succeeded_at        timestamptz                NULL,
  failed_at           timestamptz                NULL,
  canceled_at         timestamptz                NULL,
  refunded_at         timestamptz                NULL,
  failure_code        text                       NULL,
  failure_message     text                       NULL,
  is_disputed         bool                       NOT NULL DEFAULT false,
  dispute_id          text                       NULL,
  dispute_reason      text                       NULL,
  dispute_status      text                       NULL,
  dispute_due_at      timestamptz                NULL,
  dispute_resolved_at timestamptz                NULL,
  risk_score          int                        NULL,
  risk_level          text                       NULL,
  client_ip           inet                       NULL,
  device_session_id   text                       NULL,
  provider_response   jsonb                      NULL,
  registered_by       uuid                       NULL,
  registration_notes  text                       NULL,
  metadata            jsonb                      NOT NULL DEFAULT '{}',
  created_at          timestamptz                NOT NULL DEFAULT now(),
  updated_at          timestamptz                NOT NULL DEFAULT now(),
  CONSTRAINT pay_pkey              PRIMARY KEY (id),
  CONSTRAINT pay_refunded_chk      CHECK (refunded_amount >= 0 AND refunded_amount <= amount),
  CONSTRAINT pay_installments_chk  CHECK (
    (installments IS NULL AND installment_amount IS NULL) OR
    (installments IS NOT NULL AND installment_amount IS NOT NULL)
  ),
  CONSTRAINT pay_manual_chk        CHECK (gateway != 'manual' OR registered_by IS NOT NULL),
  CONSTRAINT pay_invoice_fkey      FOREIGN KEY (invoice_id)        REFERENCES public.invoices(id),
  CONSTRAINT pay_account_fkey      FOREIGN KEY (account_id)        REFERENCES public.accounts(id),
  CONSTRAINT pay_org_fkey          FOREIGN KEY (organization_id)   REFERENCES public.organizations(id),
  CONSTRAINT pay_method_fkey       FOREIGN KEY (payment_method_id) REFERENCES public.payment_methods(id) ON DELETE SET NULL,
  CONSTRAINT pay_registered_by_fkey FOREIGN KEY (registered_by)   REFERENCES public.users(id)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_pay_gateway_id
  ON public.payments (gateway_payment_id) WHERE gateway_payment_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_pay_idempotency
  ON public.payments (idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_pay_invoice   ON public.payments (invoice_id);
CREATE INDEX IF NOT EXISTS idx_pay_account   ON public.payments (account_id);
CREATE INDEX IF NOT EXISTS idx_pay_status    ON public.payments (payment_status);
CREATE INDEX IF NOT EXISTS idx_pay_disputed  ON public.payments (is_disputed) WHERE is_disputed = true;
CREATE INDEX IF NOT EXISTS idx_pay_method    ON public.payments (payment_method_id) WHERE payment_method_id IS NOT NULL;

-- ─────────────────────────────────────────────
-- DISCOUNTS / REFUNDS / CREDITS / TRIALS
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.discounts (
  id                  uuid                   NOT NULL DEFAULT gen_random_uuid(),
  coupon_id           uuid                   NOT NULL,
  promotion_code_id   uuid                   NULL,
  account_id          uuid                   NOT NULL,
  subscription_id     uuid                   NULL,
  invoice_id          uuid                   NULL,
  applied_amount_off  numeric(10,2)          NULL,
  applied_percent_off numeric(5,4)           NULL,
  starts_at           timestamptz            NOT NULL DEFAULT now(),
  ends_at             timestamptz            NULL,
  gateway             public.payment_gateway NULL,
  gateway_discount_id text                   NULL,
  created_at          timestamptz            NOT NULL DEFAULT now(),
  CONSTRAINT dc_pkey       PRIMARY KEY (id),
  CONSTRAINT dc_target_chk CHECK (
    (subscription_id IS NOT NULL AND invoice_id IS NULL) OR
    (subscription_id IS NULL     AND invoice_id IS NOT NULL)
  ),
  CONSTRAINT dc_coupon_fkey FOREIGN KEY (coupon_id)           REFERENCES public.coupons(id),
  CONSTRAINT dc_promo_fkey  FOREIGN KEY (promotion_code_id)   REFERENCES public.promotion_codes(id),
  CONSTRAINT dc_account_fkey FOREIGN KEY (account_id)         REFERENCES public.accounts(id),
  CONSTRAINT dc_sub_fkey    FOREIGN KEY (subscription_id)     REFERENCES public.subscriptions(id),
  CONSTRAINT dc_invoice_fkey FOREIGN KEY (invoice_id)         REFERENCES public.invoices(id)
);
CREATE INDEX IF NOT EXISTS idx_dc_account ON public.discounts (account_id);
CREATE INDEX IF NOT EXISTS idx_dc_sub     ON public.discounts (subscription_id);
CREATE INDEX IF NOT EXISTS idx_dc_invoice ON public.discounts (invoice_id);

CREATE TABLE IF NOT EXISTS public.refunds (
  id                uuid          NOT NULL DEFAULT gen_random_uuid(),
  payment_id        uuid          NOT NULL,
  account_id        uuid          NOT NULL,
  gateway_refund_id text          NULL,
  refund_amount     numeric(10,2) NOT NULL,
  currency          text          NOT NULL DEFAULT 'MXN',
  reason            text          NOT NULL DEFAULT 'requested_by_customer',
  refund_status     text          NOT NULL DEFAULT 'PENDING',
  authorized_by     uuid          NOT NULL,
  notes             text          NULL,
  provider_response jsonb         NULL,
  created_at        timestamptz   NOT NULL DEFAULT now(),
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT ref_pkey         PRIMARY KEY (id),
  CONSTRAINT ref_amount_chk   CHECK (refund_amount > 0),
  CONSTRAINT ref_payment_fkey FOREIGN KEY (payment_id)   REFERENCES public.payments(id),
  CONSTRAINT ref_account_fkey FOREIGN KEY (account_id)   REFERENCES public.accounts(id),
  CONSTRAINT ref_auth_by_fkey FOREIGN KEY (authorized_by) REFERENCES public.users(id)
);
CREATE INDEX IF NOT EXISTS idx_ref_payment ON public.refunds (payment_id);
CREATE INDEX IF NOT EXISTS idx_ref_account ON public.refunds (account_id);

CREATE TABLE IF NOT EXISTS public.trials (
  id                      uuid          NOT NULL DEFAULT gen_random_uuid(),
  subscription_id         uuid          NOT NULL,
  organization_id         uuid          NOT NULL,
  trial_type              text          NOT NULL DEFAULT 'free',
  trial_starts_at         timestamptz   NOT NULL DEFAULT now(),
  trial_ends_at           timestamptz   NOT NULL,
  trial_amount            numeric(10,2) NULL DEFAULT 0,
  trial_currency          text          NULL DEFAULT 'MXN',
  requires_payment_method bool          NOT NULL DEFAULT false,
  end_behavior            text          NOT NULL DEFAULT 'convert',
  extension_count         int           NOT NULL DEFAULT 0,
  last_extended_by        uuid          NULL,
  last_extended_at        timestamptz   NULL,
  extension_reason        text          NULL,
  reminder_3d_sent_at     timestamptz   NULL,
  reminder_1d_sent_at     timestamptz   NULL,
  converted_at            timestamptz   NULL,
  created_at              timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT tri_pkey     PRIMARY KEY (id),
  CONSTRAINT tri_sub_key  UNIQUE (subscription_id),
  CONSTRAINT tri_sub_fkey FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id),
  CONSTRAINT tri_org_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id),
  CONSTRAINT tri_ext_fkey FOREIGN KEY (last_extended_by) REFERENCES public.users(id)
);
CREATE INDEX IF NOT EXISTS idx_tri_org  ON public.trials (organization_id);
CREATE INDEX IF NOT EXISTS idx_tri_ends ON public.trials (trial_ends_at) WHERE converted_at IS NULL;

CREATE TABLE IF NOT EXISTS public.credits (
  id                 uuid          NOT NULL DEFAULT gen_random_uuid(),
  account_id         uuid          NOT NULL,
  credit_source      text          NOT NULL,
  amount             numeric(10,2) NOT NULL,
  currency           text          NOT NULL DEFAULT 'MXN',
  remaining_amount   numeric(10,2) NOT NULL,
  expires_at         timestamptz   NULL,
  referral_reward_id uuid          NULL,
  payment_id         uuid          NULL,
  notes              text          NULL,
  created_by         uuid          NULL,
  created_at         timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT cre_pkey          PRIMARY KEY (id),
  CONSTRAINT cre_amount_chk    CHECK (amount > 0),
  CONSTRAINT cre_remaining_chk CHECK (remaining_amount >= 0 AND remaining_amount <= amount),
  CONSTRAINT cre_account_fkey  FOREIGN KEY (account_id) REFERENCES public.accounts(id),
  CONSTRAINT cre_by_fkey       FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE INDEX IF NOT EXISTS idx_cre_account ON public.credits (account_id);
CREATE INDEX IF NOT EXISTS idx_cre_active
  ON public.credits (account_id, remaining_amount) WHERE remaining_amount > 0;

-- ─────────────────────────────────────────────
-- BILLING NOTIFICATIONS / SUPPORT CASES
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.billing_notifications (
  id                  uuid        NOT NULL DEFAULT gen_random_uuid(),
  account_id          uuid        NOT NULL,
  organization_id     uuid        NULL,
  invoice_id          uuid        NULL,
  payment_id          uuid        NULL,
  notification_type   text        NOT NULL,
  channel             text        NOT NULL,
  recipient           text        NOT NULL,
  delivery_status     text        NOT NULL DEFAULT 'PENDING',
  sent_at             timestamptz NULL,
  delivered_at        timestamptz NULL,
  failed_at           timestamptz NULL,
  failure_reason      text        NULL,
  provider_message_id text        NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT bn_pkey        PRIMARY KEY (id),
  CONSTRAINT bn_account_fkey FOREIGN KEY (account_id)     REFERENCES public.accounts(id),
  CONSTRAINT bn_org_fkey    FOREIGN KEY (organization_id) REFERENCES public.organizations(id),
  CONSTRAINT bn_invoice_fkey FOREIGN KEY (invoice_id)     REFERENCES public.invoices(id),
  CONSTRAINT bn_payment_fkey FOREIGN KEY (payment_id)     REFERENCES public.payments(id)
);
CREATE INDEX IF NOT EXISTS idx_bn_account ON public.billing_notifications (account_id);
CREATE INDEX IF NOT EXISTS idx_bn_invoice ON public.billing_notifications (invoice_id);
CREATE INDEX IF NOT EXISTS idx_bn_type    ON public.billing_notifications (notification_type, sent_at);

CREATE TABLE IF NOT EXISTS public.support_billing_cases (
  id          uuid        NOT NULL DEFAULT gen_random_uuid(),
  account_id  uuid        NOT NULL,
  payment_id  uuid        NULL,
  invoice_id  uuid        NULL,
  reason      text        NOT NULL,
  description text        NOT NULL,
  case_status text        NOT NULL DEFAULT 'open',
  assigned_to uuid        NULL,
  resolution  text        NULL,
  resolved_at timestamptz NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT sbc_pkey         PRIMARY KEY (id),
  CONSTRAINT sbc_account_fkey FOREIGN KEY (account_id)  REFERENCES public.accounts(id),
  CONSTRAINT sbc_payment_fkey FOREIGN KEY (payment_id)  REFERENCES public.payments(id),
  CONSTRAINT sbc_invoice_fkey FOREIGN KEY (invoice_id)  REFERENCES public.invoices(id),
  CONSTRAINT sbc_assigned_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id)
);
CREATE INDEX IF NOT EXISTS idx_sbc_account ON public.support_billing_cases (account_id);
CREATE INDEX IF NOT EXISTS idx_sbc_status  ON public.support_billing_cases (case_status);

-- ─────────────────────────────────────────────
-- SUBSCRIPTION CHANGES / USAGE EVENTS
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.subscription_plan_changes (
  id                   uuid          NOT NULL DEFAULT gen_random_uuid(),
  subscription_id      uuid          NOT NULL,
  previous_plan_id     uuid          NOT NULL,
  new_plan_id          uuid          NOT NULL,
  change_type          text          NOT NULL,
  proration_amount     numeric(10,2) NULL,
  proration_invoice_id uuid          NULL,
  effective_at         timestamptz   NOT NULL DEFAULT now(),
  changed_by           uuid          NULL,
  notes                text          NULL,
  created_at           timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT spc_pkey     PRIMARY KEY (id),
  CONSTRAINT spc_sub_fkey FOREIGN KEY (subscription_id)      REFERENCES public.subscriptions(id),
  CONSTRAINT spc_inv_fkey FOREIGN KEY (proration_invoice_id) REFERENCES public.invoices(id),
  CONSTRAINT spc_by_fkey  FOREIGN KEY (changed_by)           REFERENCES public.users(id)
);
CREATE INDEX IF NOT EXISTS idx_spc_sub ON public.subscription_plan_changes (subscription_id);

CREATE TABLE IF NOT EXISTS public.usage_events (
  id               uuid          NOT NULL DEFAULT gen_random_uuid(),
  organization_id  uuid          NOT NULL,
  subscription_id  uuid          NOT NULL,
  metric_name      text          NOT NULL,
  quantity         numeric(14,4) NOT NULL DEFAULT 1,
  unit_label       text          NULL,
  period_start     timestamptz   NOT NULL,
  period_end       timestamptz   NOT NULL,
  resource_id      uuid          NULL,
  resource_type    text          NULL,
  idempotency_key  text          NULL,
  recorded_at      timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT ue_pkey     PRIMARY KEY (id),
  CONSTRAINT ue_idem_key UNIQUE (idempotency_key),
  CONSTRAINT ue_org_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id),
  CONSTRAINT ue_sub_fkey FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id)
);
CREATE INDEX IF NOT EXISTS idx_ue_org_metric
  ON public.usage_events (organization_id, metric_name, period_start);
CREATE INDEX IF NOT EXISTS idx_ue_sub
  ON public.usage_events (subscription_id, period_start);

-- ─────────────────────────────────────────────
-- REFERRALS / VOLUME DISCOUNTS
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.referral_codes (
  id         uuid        NOT NULL DEFAULT gen_random_uuid(),
  account_id uuid        NOT NULL,
  code       text        NOT NULL,
  max_uses   int         NULL,
  total_uses int         NOT NULL DEFAULT 0,
  is_active  bool        NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT rc_pkey        PRIMARY KEY (id),
  CONSTRAINT rc_account_key UNIQUE (account_id),
  CONSTRAINT rc_code_key    UNIQUE (code),
  CONSTRAINT rc_account_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_rc_code_lower ON public.referral_codes (LOWER(code));

CREATE TABLE IF NOT EXISTS public.referral_rewards (
  id                    uuid          NOT NULL DEFAULT gen_random_uuid(),
  referrer_account_id   uuid          NOT NULL,
  referral_code_id      uuid          NOT NULL,
  referred_account_id   uuid          NOT NULL,
  referrer_reward_type  text          NOT NULL,
  referrer_reward_value numeric(10,2) NOT NULL,
  referrer_coupon_id    uuid          NULL,
  referred_reward_type  text          NOT NULL,
  referred_reward_value numeric(10,2) NOT NULL,
  referred_coupon_id    uuid          NULL,
  reward_status         text          NOT NULL DEFAULT 'PENDING',
  qualifying_payment_id uuid          NULL,
  earned_at             timestamptz   NULL,
  applied_at            timestamptz   NULL,
  expires_at            timestamptz   NULL,
  created_at            timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT rr_pkey            PRIMARY KEY (id),
  CONSTRAINT rr_referrer_fkey   FOREIGN KEY (referrer_account_id) REFERENCES public.accounts(id),
  CONSTRAINT rr_code_fkey       FOREIGN KEY (referral_code_id)    REFERENCES public.referral_codes(id),
  CONSTRAINT rr_referred_fkey   FOREIGN KEY (referred_account_id) REFERENCES public.accounts(id),
  CONSTRAINT rr_ref_coupon_fkey FOREIGN KEY (referrer_coupon_id)  REFERENCES public.coupons(id),
  CONSTRAINT rr_red_coupon_fkey FOREIGN KEY (referred_coupon_id)  REFERENCES public.coupons(id)
);
CREATE INDEX IF NOT EXISTS idx_rr_referrer ON public.referral_rewards (referrer_account_id);
CREATE INDEX IF NOT EXISTS idx_rr_referred ON public.referral_rewards (referred_account_id);

CREATE TABLE IF NOT EXISTS public.volume_discounts (
  id            uuid                 NOT NULL DEFAULT gen_random_uuid(),
  plan_id       uuid                 NOT NULL,
  name          text                 NOT NULL,
  min_units     int                  NOT NULL,
  max_units     int                  NULL,
  discount_type public.discount_type NOT NULL,
  percent_off   numeric(5,4)         NULL,
  amount_off    numeric(10,2)        NULL,
  is_active     bool                 NOT NULL DEFAULT true,
  created_at    timestamptz          NOT NULL DEFAULT now(),
  CONSTRAINT vd_pkey      PRIMARY KEY (id),
  CONSTRAINT vd_range_chk CHECK (max_units IS NULL OR max_units > min_units),
  CONSTRAINT vd_value_chk CHECK (
    (percent_off IS NOT NULL AND amount_off IS NULL) OR
    (percent_off IS NULL     AND amount_off IS NOT NULL)
  )
);
CREATE INDEX IF NOT EXISTS idx_vd_plan ON public.volume_discounts (plan_id);