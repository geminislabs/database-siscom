BEGIN;

-- ────────────────────────────────────────────────────────────────
-- ENUMS
-- ────────────────────────────────────────────────────────────────

CREATE TYPE public.payment_gateway AS ENUM (
    'stripe',       
    'conekta',      
    'mercadopago', 
    'paypal',
    'manual'
);

CREATE TYPE public.payment_method_type AS ENUM (
    'card',
    'cash_voucher',
    'bank_transfer',
    'bank_redirect',
    'wallet',
    'installments',
    'real_time',
    'loyalty_points',
    'gift_card',
    'crypto',
    'manual'
);

CREATE TYPE public.payment_status AS ENUM (
    'PENDING',
    'REQUIRES_ACTION',
    'PROCESSING',
    'SUCCESS', 
    'FAILED', 
    'CANCELED', 
    'DISPUTED',
    'REFUNDED',
    'PARTIALLY_REFUNDED' 
);

CREATE TYPE public.invoice_status AS ENUM (
    'DRAFT',        
    'OPEN',       
    'PAID',   
    'PAST_DUE',     
    'VOID',        
    'UNCOLLECTIBLE' 
);

CREATE TYPE public.coupon_duration AS ENUM (
    'once',  
    'repeating', 
    'forever'  
);

CREATE TYPE public.discount_type AS ENUM (
    'percentage', 
    'fixed_amount', 
    'volume', 
    'referral' 
);

CREATE TYPE public.gateway_event_status AS ENUM (
    'processed',
    'failed', 
    'skipped'
);


CREATE TABLE public.payment_gateway_customers (
    id                   uuid        NOT NULL DEFAULT gen_random_uuid(),
    account_id           uuid        NOT NULL,
    gateway              public.payment_gateway NOT NULL,
    external_customer_id text        NOT NULL,
    created_at           timestamptz NOT NULL DEFAULT now(),
    updated_at           timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT pgc_pkey                PRIMARY KEY (id),
    CONSTRAINT pgc_account_gateway_key UNIQUE (account_id, gateway),
    CONSTRAINT pgc_external_key        UNIQUE (gateway, external_customer_id),
    CONSTRAINT pgc_account_fkey        FOREIGN KEY (account_id)
        REFERENCES public.accounts(id) ON DELETE CASCADE
);

CREATE INDEX idx_pgc_account ON public.payment_gateway_customers (account_id);
CREATE INDEX idx_pgc_gateway ON public.payment_gateway_customers (gateway, external_customer_id);


CREATE TABLE public.payment_gateway_events (
    gateway           public.payment_gateway        NOT NULL,
    external_event_id text                          NOT NULL,
    event_type        text                          NOT NULL,
    event_status      public.gateway_event_status   NOT NULL DEFAULT 'processed',
    payload           jsonb                         NULL,
    error_message     text                          NULL,
    retry_count       int                           NOT NULL DEFAULT 0,
    processed_at      timestamptz                   NOT NULL DEFAULT now(),

    CONSTRAINT pge_pkey PRIMARY KEY (gateway, external_event_id)
);

CREATE INDEX idx_pge_type      ON public.payment_gateway_events (gateway, event_type);
CREATE INDEX idx_pge_processed ON public.payment_gateway_events (processed_at DESC);


CREATE TABLE public.payment_methods (
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

    CONSTRAINT pm_pkey             PRIMARY KEY (id),
    CONSTRAINT pm_external_key     UNIQUE (gateway, external_token),
    CONSTRAINT pm_exp_month_chk    CHECK (exp_month IS NULL OR exp_month BETWEEN 1 AND 12),
    CONSTRAINT pm_exp_year_chk     CHECK (exp_year  IS NULL OR exp_year >= 2024),
    CONSTRAINT pm_account_fkey     FOREIGN KEY (account_id)
        REFERENCES public.accounts(id) ON DELETE CASCADE
);

CREATE INDEX idx_pm_account         ON public.payment_methods (account_id);
CREATE INDEX idx_pm_gateway         ON public.payment_methods (gateway, external_token);
CREATE INDEX idx_pm_account_gateway ON public.payment_methods (account_id, gateway);
CREATE UNIQUE INDEX uq_pm_default   ON public.payment_methods (account_id) WHERE is_default = true;


CREATE TABLE public.fiscal_profiles (
    id             uuid      NOT NULL DEFAULT gen_random_uuid(),
    account_id     uuid      NOT NULL,

    rfc            text      NOT NULL,
    razon_social   text      NOT NULL,
    regimen_fiscal text      NOT NULL,
    codigo_postal  char(5)   NOT NULL,
    cfdi_use       text      NOT NULL DEFAULT 'G03', -- G03 = Gastos en general
    is_default     bool      NOT NULL DEFAULT false,
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT fsc_pkey       PRIMARY KEY (id),
    CONSTRAINT fsc_rfc_length CHECK (char_length(rfc) IN (12, 13)),
    CONSTRAINT fsc_cp_digits  CHECK (codigo_postal ~ '^\d{5}$'),
    CONSTRAINT fsc_account_fkey FOREIGN KEY (account_id)
        REFERENCES public.accounts(id) ON DELETE CASCADE
);

CREATE INDEX idx_fiscal_account ON public.fiscal_profiles (account_id);
CREATE UNIQUE INDEX uq_fiscal_default ON public.fiscal_profiles (account_id) WHERE is_default = true;


CREATE TABLE public.tax_rates (
    id            uuid         NOT NULL DEFAULT gen_random_uuid(),
    name          text         NOT NULL,
    country       char(2)      NOT NULL,
    region        text         NULL,
    rate_percent  numeric(6,4) NOT NULL,
    is_inclusive  bool         NOT NULL DEFAULT false,
    sat_tax_key   text         NULL DEFAULT '002',  -- SAT: 002=IVA | 003=IEPS
    is_active     bool         NOT NULL DEFAULT true,
    valid_from    date         NOT NULL DEFAULT CURRENT_DATE,
    valid_until   date         NULL,                -- NULL = vigente indefinidamente
    created_at    timestamptz  NOT NULL DEFAULT now(),

    CONSTRAINT tr_pkey PRIMARY KEY (id)
);

-- IVA México por defecto
INSERT INTO public.tax_rates (name, country, rate_percent, sat_tax_key, valid_from)
VALUES ('IVA México 16%', 'MX', 16.0000, '002', '2014-01-01');


CREATE TABLE public.coupons (
    id                 uuid                   NOT NULL DEFAULT gen_random_uuid(),
    internal_name      text                   NOT NULL,    -- "Black Friday 2025 — 30% off"

    discount_type      public.discount_type   NOT NULL,
    amount_off         numeric(10,2)          NULL,       
    currency           text                   NULL DEFAULT 'MXN',
    percent_off        numeric(5,4)           NULL,  

    coupon_duration    public.coupon_duration NOT NULL DEFAULT 'once',
    duration_in_months int                    NULL,     

    max_redemptions    int                    NULL,   
    times_redeemed     int                    NOT NULL DEFAULT 0,
    redeem_by          timestamptz            NULL, 

    min_amount         numeric(10,2)          NULL, 
    first_time_only    bool                   NOT NULL DEFAULT false,
    applies_to_plans   uuid[]                 NULL, 

    gateway            public.payment_gateway NULL,
    gateway_coupon_id  text                   NULL,

    is_active          bool                   NOT NULL DEFAULT true,
    metadata           jsonb                  NOT NULL DEFAULT '{}',

    created_by         uuid                   NOT NULL,
    created_at         timestamptz            NOT NULL DEFAULT now(),
    updated_at         timestamptz            NOT NULL DEFAULT now(),

    CONSTRAINT cp_pkey        PRIMARY KEY (id),
    CONSTRAINT cp_value_chk   CHECK (
        (amount_off IS NOT NULL AND percent_off IS NULL) OR
        (amount_off IS NULL     AND percent_off IS NOT NULL)
    ),
    CONSTRAINT cp_repeating_chk CHECK (
        coupon_duration != 'repeating' OR duration_in_months IS NOT NULL
    ),
    CONSTRAINT cp_percent_chk CHECK (
        percent_off IS NULL OR (percent_off > 0 AND percent_off <= 1)
    ),
    CONSTRAINT cp_created_by_fkey FOREIGN KEY (created_by)
        REFERENCES public.users(id)
);


CREATE TABLE public.promotion_codes (
    id                    uuid                   NOT NULL DEFAULT gen_random_uuid(),
    coupon_id             uuid                   NOT NULL,

    code                  text                   NOT NULL,   -- "NEXUSPRO30" — lo que escribe el cliente
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
    CONSTRAINT pc_coupon_fkey FOREIGN KEY (coupon_id)
        REFERENCES public.coupons(id),
    CONSTRAINT pc_account_fkey FOREIGN KEY (restricted_to_account)
        REFERENCES public.accounts(id),
    CONSTRAINT pc_created_fkey FOREIGN KEY (created_by)
        REFERENCES public.users(id)
);

CREATE UNIQUE INDEX idx_promo_code_lower ON public.promotion_codes (LOWER(code));


CREATE TABLE public.invoices (
    id                    uuid                   NOT NULL DEFAULT gen_random_uuid(),
    account_id            uuid                   NOT NULL,
    organization_id       uuid                   NOT NULL,
    subscription_id       uuid                   NULL,

    gateway               public.payment_gateway NULL,
    external_invoice_id   text                   NULL,

    invoice_number        text                   NOT NULL,   -- "INV-2025-0001"
    invoice_status        public.invoice_status  NOT NULL DEFAULT 'DRAFT',

    subtotal              numeric(10,2)          NOT NULL,
    discount_amount       numeric(10,2)          NOT NULL DEFAULT 0,
    tax_amount            numeric(10,2)          NOT NULL DEFAULT 0,
    total_amount          numeric(10,2)          NOT NULL,   -- subtotal - discount + tax
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

    -- Forma de pago SAT: 03=SPEI|DiMo, 04=tarjeta crédito, 28=débito, 01=efectivo, 99=por definir
    cfdi_payment_form     text                   NULL,
    -- Método: PUE (una exhibición) | PPD (parcialidades/diferido)
    cfdi_payment_method   text                   NULL DEFAULT 'PUE',

    -- Datos del timbre fiscal (generados por el PAC)
    cfdi_uuid             text                   NULL, 
    cfdi_xml_url          text                   NULL,
    cfdi_pdf_url          text                   NULL,
    cfdi_stamped_at       timestamptz            NULL,
    -- ──────────────────────────────────────────────────────────

    provider_response     jsonb                  NULL,
    metadata              jsonb                  NOT NULL DEFAULT '{}',

    created_at            timestamptz            NOT NULL DEFAULT now(),
    updated_at            timestamptz            NOT NULL DEFAULT now(),

    CONSTRAINT inv_pkey          PRIMARY KEY (id),
    CONSTRAINT inv_number_key    UNIQUE (invoice_number),
    CONSTRAINT inv_cfdi_uuid_key UNIQUE (cfdi_uuid),
    CONSTRAINT inv_account_fkey  FOREIGN KEY (account_id)
        REFERENCES public.accounts(id),
    CONSTRAINT inv_org_fkey      FOREIGN KEY (organization_id)
        REFERENCES public.organizations(id),
    CONSTRAINT inv_sub_fkey      FOREIGN KEY (subscription_id)
        REFERENCES public.subscriptions(id),
    CONSTRAINT inv_fiscal_fkey   FOREIGN KEY (fiscal_profile_id)
        REFERENCES public.fiscal_profiles(id)
);

CREATE INDEX idx_inv_account  ON public.invoices (account_id);
CREATE INDEX idx_inv_org      ON public.invoices (organization_id);
CREATE INDEX idx_inv_sub      ON public.invoices (subscription_id);
CREATE INDEX idx_inv_status   ON public.invoices (invoice_status);
CREATE INDEX idx_inv_due_open ON public.invoices (due_at) WHERE invoice_status = 'OPEN';
CREATE INDEX idx_inv_cfdi     ON public.invoices (cfdi_uuid) WHERE cfdi_uuid IS NOT NULL;


CREATE TABLE public.discounts (
    id                  uuid                   NOT NULL DEFAULT gen_random_uuid(),
    coupon_id           uuid                   NOT NULL,
    promotion_code_id   uuid                   NULL,
    account_id          uuid                   NOT NULL,

    -- Solo uno de los dos puede tener valor (constraint abajo)
    subscription_id     uuid                   NULL,
    invoice_id          uuid                   NULL,

    applied_amount_off  numeric(10,2)          NULL,
    applied_percent_off numeric(5,4)           NULL,

    starts_at           timestamptz            NOT NULL DEFAULT now(),
    ends_at             timestamptz            NULL,   -- NULL = forever

    gateway             public.payment_gateway NULL,
    gateway_discount_id text                   NULL,

    created_at          timestamptz            NOT NULL DEFAULT now(),

    CONSTRAINT dc_pkey          PRIMARY KEY (id),
    CONSTRAINT dc_target_chk    CHECK (
        (subscription_id IS NOT NULL AND invoice_id IS NULL) OR
        (subscription_id IS NULL     AND invoice_id IS NOT NULL)
    ),
    CONSTRAINT dc_coupon_fkey   FOREIGN KEY (coupon_id)
        REFERENCES public.coupons(id),
    CONSTRAINT dc_promo_fkey    FOREIGN KEY (promotion_code_id)
        REFERENCES public.promotion_codes(id),
    CONSTRAINT dc_account_fkey  FOREIGN KEY (account_id)
        REFERENCES public.accounts(id),
    CONSTRAINT dc_sub_fkey      FOREIGN KEY (subscription_id)
        REFERENCES public.subscriptions(id),
    CONSTRAINT dc_invoice_fkey  FOREIGN KEY (invoice_id)
        REFERENCES public.invoices(id)
);

CREATE INDEX idx_dc_account ON public.discounts (account_id);
CREATE INDEX idx_dc_sub     ON public.discounts (subscription_id);
CREATE INDEX idx_dc_invoice ON public.discounts (invoice_id);


CREATE TABLE public.invoice_line_items (
    id              uuid          NOT NULL DEFAULT gen_random_uuid(),
    invoice_id      uuid          NOT NULL,

    description     text          NOT NULL,   -- "Plan NEXUS Pro — Mayo 2025"
    -- 'subscription' | 'proration' | 'addon' | 'discount' | 'credit' | 'usage' | 'tax'
    line_type       text          NOT NULL,

    quantity        numeric(10,4) NOT NULL DEFAULT 1,
    unit_amount     numeric(10,2) NOT NULL,   -- precio unitario antes de descuento
    discount_amount numeric(10,2) NOT NULL DEFAULT 0,
    tax_amount      numeric(10,2) NOT NULL DEFAULT 0,
    total_amount    numeric(10,2) NOT NULL,   -- (qty × unit_amount) - discount + tax

    -- Período que representa esta línea
    period_start    timestamptz   NULL,
    period_end      timestamptz   NULL,

    plan_id         uuid          NULL,

    -- Claves SAT para CFDI 4.0
    -- 81112501 = SaaS/Software en la nube
    -- 78101803 = Servicios de rastreo GPS
    -- 46171609 = Hardware GPS (dispositivos)
    sat_product_key text          NULL,
    sat_unit_key    text          NULL DEFAULT 'E48',  -- E48 = Unidad de servicio

    sort_order      int           NOT NULL DEFAULT 0,
    metadata        jsonb         NOT NULL DEFAULT '{}',
    created_at      timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT li_pkey        PRIMARY KEY (id),
    CONSTRAINT li_invoice_fkey FOREIGN KEY (invoice_id)
        REFERENCES public.invoices(id) ON DELETE CASCADE
);

CREATE INDEX idx_li_invoice ON public.invoice_line_items (invoice_id);


CREATE TABLE public.invoice_line_item_taxes (
    id              uuid          NOT NULL DEFAULT gen_random_uuid(),
    line_item_id    uuid          NOT NULL,
    tax_rate_id     uuid          NOT NULL,
    taxable_amount  numeric(10,2) NOT NULL,
    tax_amount      numeric(10,2) NOT NULL,
    created_at      timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT lit_pkey           PRIMARY KEY (id),
    CONSTRAINT lit_line_fkey      FOREIGN KEY (line_item_id)
        REFERENCES public.invoice_line_items(id) ON DELETE CASCADE,
    CONSTRAINT lit_tax_rate_fkey  FOREIGN KEY (tax_rate_id)
        REFERENCES public.tax_rates(id)
);

CREATE INDEX idx_lit_line ON public.invoice_line_item_taxes (line_item_id);


-- ────────────────────────────────────────────────────────────────
-- Columnas de método:
--   payment_method_id  → FK al vault (NULL para pagos one-off)
--   payment_method_type → siempre presente (cómo se pagó)
--   payment_method_meta → detalle específico de este intento
--     OXXO:  { "provider_type":"oxxo", "reference":"988...", "barcode_url":"...", "expires_at":"..." }
--     SPEI:  { "provider_type":"spei", "clabe":"646...", "reference":"REF001", "expires_at":"..." }
--     DiMo:  { "provider_type":"dimo", "phone":"5512345678" }
--     CoDi:  { "provider_type":"codi", "qr_url":"...", "expires_at":"..." }
--     MSI:   { "provider_type":"meses_sin_intereses", "months":12, "bank":"BBVA" }
--     Card:  { "brand":"visa", "last4":"4242" }  (solo si no hay payment_method_id)
-- ────────────────────────────────────────────────────────────────

CREATE TABLE public.payments (
    id                      uuid                       NOT NULL DEFAULT gen_random_uuid(),
    invoice_id              uuid                       NOT NULL,
    account_id              uuid                       NOT NULL,
    organization_id         uuid                       NOT NULL,
    gateway                 public.payment_gateway     NOT NULL,

    -- Stripe: pi_xxx | Conekta: ord_xxx | MercadoPago: payment_id numérico
    gateway_payment_id      text                       NULL,

    -- Clave de idempotencia para evitar pagos duplicados
    idempotency_key         text                       NULL,

    -- Método de pago
    payment_method_type     public.payment_method_type NOT NULL,
    payment_method_id       uuid                       NULL,   -- FK al vault, NULL = one-off
    payment_method_meta     jsonb                      NOT NULL DEFAULT '{}', /*Columna sugerida de metadatos*/

    -- Montos
    amount                  numeric(10,2)              NOT NULL,
    currency                text                       NOT NULL DEFAULT 'MXN',
    refunded_amount         numeric(10,2)              NOT NULL DEFAULT 0,  -- suma desnormalizada

    -- Meses Sin Intereses
    installments            int                        NULL,
    installment_amount      numeric(10,2)              NULL,

    payment_status          public.payment_status      NOT NULL DEFAULT 'PENDING',

    -- Separación autorización / captura (pre-auth flows)
    authorized_at           timestamptz                NULL,   -- banco aprobó, fondos retenidos
    captured_at             timestamptz                NULL,   -- captura real del monto

    -- Ciclo de vida del intento
    initiated_at            timestamptz                NULL,   -- cliente inició acción (fue a OXXO, hizo SPEI)
    succeeded_at            timestamptz                NULL,
    failed_at               timestamptz                NULL,
    canceled_at             timestamptz                NULL,
    refunded_at             timestamptz                NULL,

    -- Razón del fallo (para display al cliente y análisis)
    -- "insufficient_funds" | "card_expired" | "oxxo_expired" | "do_not_honor"
    failure_code            text                       NULL,
    failure_message         text                       NULL,

    -- Contracargo / Disputa con banco emisor
    is_disputed             bool                       NOT NULL DEFAULT false,
    dispute_id              text                       NULL,   -- "dp_xxx" Stripe
    dispute_reason          text                       NULL,   -- "fraudulent" | "credit_not_processed"
    dispute_status          text                       NULL,   -- "needs_response" | "under_review" | "won" | "lost"
    dispute_due_at          timestamptz                NULL,   -- fecha límite para presentar evidencia
    dispute_resolved_at     timestamptz                NULL,

    -- Antifraude
    risk_score              int                        NULL,   -- 0-100 del PSP
    risk_level              text                       NULL,   -- "normal" | "elevated" | "highest"
    client_ip               inet                       NULL,
    device_session_id       text                       NULL,   -- fingerprint del dispositivo (OpenPay/Conekta/MP)

    -- Respuesta raw del PSP (invaluable para disputas, soporte y auditoría)
    provider_response       jsonb                      NULL, 

    -- Pagos manuales (registrados por operaciones sin PSP)
    registered_by           uuid                       NULL,
    registration_notes      text                       NULL,

    metadata                jsonb                      NOT NULL DEFAULT '{}',
    created_at              timestamptz                NOT NULL DEFAULT now(),
    updated_at              timestamptz                NOT NULL DEFAULT now(),

    CONSTRAINT pay_pkey                PRIMARY KEY (id),
    CONSTRAINT pay_refunded_chk        CHECK (refunded_amount >= 0 AND refunded_amount <= amount),
    CONSTRAINT pay_installments_chk    CHECK (
        (installments IS NULL AND installment_amount IS NULL) OR
        (installments IS NOT NULL AND installment_amount IS NOT NULL)
    ),
    CONSTRAINT pay_manual_chk          CHECK (
        gateway != 'manual' OR registered_by IS NOT NULL
    ),
    CONSTRAINT pay_invoice_fkey        FOREIGN KEY (invoice_id)
        REFERENCES public.invoices(id),
    CONSTRAINT pay_account_fkey        FOREIGN KEY (account_id)
        REFERENCES public.accounts(id),
    CONSTRAINT pay_org_fkey            FOREIGN KEY (organization_id)
        REFERENCES public.organizations(id),
    CONSTRAINT pay_method_fkey         FOREIGN KEY (payment_method_id)
        REFERENCES public.payment_methods(id) ON DELETE SET NULL,
    CONSTRAINT pay_registered_by_fkey  FOREIGN KEY (registered_by)
        REFERENCES public.users(id)
);

CREATE UNIQUE INDEX idx_pay_gateway_id    ON public.payments (gateway_payment_id) WHERE gateway_payment_id IS NOT NULL;
CREATE UNIQUE INDEX idx_pay_idempotency   ON public.payments (idempotency_key)     WHERE idempotency_key IS NOT NULL;
CREATE INDEX        idx_pay_invoice       ON public.payments (invoice_id);
CREATE INDEX        idx_pay_account       ON public.payments (account_id);
CREATE INDEX        idx_pay_status        ON public.payments (payment_status);
CREATE INDEX        idx_pay_disputed      ON public.payments (is_disputed) WHERE is_disputed = true;
CREATE INDEX        idx_pay_method        ON public.payments (payment_method_id) WHERE payment_method_id IS NOT NULL;


CREATE TABLE public.refunds (
    id                uuid          NOT NULL DEFAULT gen_random_uuid(),
    payment_id        uuid          NOT NULL,
    account_id        uuid          NOT NULL,

    -- "re_xxx" Stripe | "refund_id" Conekta
    gateway_refund_id text          NULL,

    refund_amount     numeric(10,2) NOT NULL,
    currency          text          NOT NULL DEFAULT 'MXN',

    -- "duplicate" | "fraudulent" | "requested_by_customer" | "product_not_received" | "other"
    reason            text          NOT NULL DEFAULT 'requested_by_customer',

    -- PENDING | SUCCESS | FAILED
    refund_status     text          NOT NULL DEFAULT 'PENDING',

    authorized_by     uuid          NOT NULL,
    notes             text          NULL,

    provider_response jsonb         NULL,
    created_at        timestamptz   NOT NULL DEFAULT now(),
    updated_at        timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT ref_pkey           PRIMARY KEY (id),
    CONSTRAINT ref_amount_chk     CHECK (refund_amount > 0),
    CONSTRAINT ref_payment_fkey   FOREIGN KEY (payment_id)
        REFERENCES public.payments(id),
    CONSTRAINT ref_account_fkey   FOREIGN KEY (account_id)
        REFERENCES public.accounts(id),
    CONSTRAINT ref_auth_by_fkey   FOREIGN KEY (authorized_by)
        REFERENCES public.users(id),
    CONSTRAINT pay_account_fkey FOREIGN KEY (account_id)
        REFERENCES public.accounts(id)
);

CREATE INDEX idx_ref_payment ON public.refunds (payment_id);
CREATE INDEX idx_ref_account ON public.refunds (account_id);


CREATE TABLE public.trials (
    id                      uuid          NOT NULL DEFAULT gen_random_uuid(),
    subscription_id         uuid          NOT NULL,
    organization_id         uuid          NOT NULL,

    -- 'free' = $0 por N días | 'paid' = precio reducido | 'extended' = extensión manual
    trial_type              text          NOT NULL DEFAULT 'free',

    trial_starts_at         timestamptz   NOT NULL DEFAULT now(),
    trial_ends_at           timestamptz   NOT NULL,

    trial_amount            numeric(10,2) NULL DEFAULT 0,   -- 0 = trial gratuito
    trial_currency          text          NULL DEFAULT 'MXN',

    requires_payment_method bool          NOT NULL DEFAULT false,

    -- Qué pasa al terminar el trial:
    -- 'convert' = cobrar automáticamente
    -- 'cancel'  = cancelar si no hay método de pago
    -- 'pause'   = pausar hasta que el cliente confirme
    end_behavior            text          NOT NULL DEFAULT 'convert',

    -- Extensiones manuales por soporte
    extension_count         int           NOT NULL DEFAULT 0,
    last_extended_by        uuid          NULL,
    last_extended_at        timestamptz   NULL,
    extension_reason        text          NULL,

    -- Recordatorios enviados
    reminder_3d_sent_at     timestamptz   NULL,
    reminder_1d_sent_at     timestamptz   NULL,

    converted_at            timestamptz   NULL,    -- timestamp de conversión exitosa a pago

    created_at              timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT tri_pkey       PRIMARY KEY (id),
    CONSTRAINT tri_sub_key    UNIQUE (subscription_id),
    CONSTRAINT tri_sub_fkey   FOREIGN KEY (subscription_id)
        REFERENCES public.subscriptions(id),
    CONSTRAINT tri_org_fkey   FOREIGN KEY (organization_id)
        REFERENCES public.organizations(id),
    CONSTRAINT tri_ext_fkey   FOREIGN KEY (last_extended_by)
        REFERENCES public.users(id)
);

CREATE INDEX idx_tri_org  ON public.trials (organization_id);
CREATE INDEX idx_tri_ends ON public.trials (trial_ends_at) WHERE converted_at IS NULL;


CREATE TABLE public.referral_codes (
    id          uuid        NOT NULL DEFAULT gen_random_uuid(),
    account_id  uuid        NOT NULL,
    code        text        NOT NULL,
    max_uses    int         NULL,                -- NULL = ilimitado
    total_uses  int         NOT NULL DEFAULT 0,
    is_active   bool        NOT NULL DEFAULT true,
    created_at  timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT rc_pkey       PRIMARY KEY (id),
    CONSTRAINT rc_account_key UNIQUE (account_id),
    CONSTRAINT rc_code_key    UNIQUE (code),
    CONSTRAINT rc_account_fkey FOREIGN KEY (account_id)
        REFERENCES public.accounts(id)
);

CREATE UNIQUE INDEX idx_rc_code_lower ON public.referral_codes (LOWER(code));


-- Recompensas generadas cuando un referido paga su primera factura
CREATE TABLE public.referral_rewards (
    id                    uuid          NOT NULL DEFAULT gen_random_uuid(),

    referrer_account_id   uuid          NOT NULL,
    referral_code_id      uuid          NOT NULL,
    referred_account_id   uuid          NOT NULL,

    -- Recompensa para quien refirió
    referrer_reward_type  text          NOT NULL,   -- 'credit' | 'discount' | 'free_month'
    referrer_reward_value numeric(10,2) NOT NULL,
    referrer_coupon_id    uuid          NULL,

    -- Recompensa para el nuevo cliente referido
    referred_reward_type  text          NOT NULL,
    referred_reward_value numeric(10,2) NOT NULL,
    referred_coupon_id    uuid          NULL,

    -- PENDING | EARNED | APPLIED | EXPIRED
    reward_status         text          NOT NULL DEFAULT 'PENDING',

    qualifying_payment_id uuid          NULL,       -- pago que desbloqueó la recompensa
    earned_at             timestamptz   NULL,
    applied_at            timestamptz   NULL,
    expires_at            timestamptz   NULL,

    created_at            timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT rr_pkey              PRIMARY KEY (id),
    CONSTRAINT rr_referrer_fkey     FOREIGN KEY (referrer_account_id)
        REFERENCES public.accounts(id),
    CONSTRAINT rr_code_fkey         FOREIGN KEY (referral_code_id)
        REFERENCES public.referral_codes(id),
    CONSTRAINT rr_referred_fkey     FOREIGN KEY (referred_account_id)
        REFERENCES public.accounts(id),
    CONSTRAINT rr_ref_coupon_fkey   FOREIGN KEY (referrer_coupon_id)
        REFERENCES public.coupons(id),
    CONSTRAINT rr_red_coupon_fkey   FOREIGN KEY (referred_coupon_id)
        REFERENCES public.coupons(id),
    CONSTRAINT rr_payment_fkey      FOREIGN KEY (qualifying_payment_id)
        REFERENCES public.payments(id)
);

CREATE INDEX idx_rr_referrer ON public.referral_rewards (referrer_account_id);
CREATE INDEX idx_rr_referred ON public.referral_rewards (referred_account_id);


CREATE TABLE public.volume_discounts (
    id            uuid                 NOT NULL DEFAULT gen_random_uuid(),
    plan_id       uuid                 NOT NULL,
    name          text                 NOT NULL,   -- "Flota mediana: 11-50 vehículos = 15% off"

    min_units     int                  NOT NULL,
    max_units     int                  NULL,        -- NULL = sin límite superior

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

CREATE INDEX idx_vd_plan ON public.volume_discounts (plan_id);


CREATE TABLE public.credits (
    id                  uuid          NOT NULL DEFAULT gen_random_uuid(),
    account_id          uuid          NOT NULL,

    -- 'referral_reward' | 'compensation' | 'adjustment' | 'overpayment' | 'promo'
    credit_source       text          NOT NULL,

    amount              numeric(10,2) NOT NULL,
    currency            text          NOT NULL DEFAULT 'MXN',
    remaining_amount    numeric(10,2) NOT NULL,   -- va disminuyendo al aplicarse

    expires_at          timestamptz   NULL,        -- NULL = no expira

    -- Origen del crédito (solo uno aplica)
    referral_reward_id  uuid          NULL,
    payment_id          uuid          NULL,        -- ej: overpayment

    notes               text          NULL,
    created_by          uuid          NULL,

    created_at          timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT cre_pkey          PRIMARY KEY (id),
    CONSTRAINT cre_amount_chk    CHECK (amount > 0),
    CONSTRAINT cre_remaining_chk CHECK (remaining_amount >= 0 AND remaining_amount <= amount),
    CONSTRAINT cre_account_fkey  FOREIGN KEY (account_id)
        REFERENCES public.accounts(id),
    CONSTRAINT cre_reward_fkey   FOREIGN KEY (referral_reward_id)
        REFERENCES public.referral_rewards(id),
    CONSTRAINT cre_payment_fkey  FOREIGN KEY (payment_id)
        REFERENCES public.payments(id),
    CONSTRAINT cre_by_fkey       FOREIGN KEY (created_by)
        REFERENCES public.users(id)
);

CREATE INDEX idx_cre_account ON public.credits (account_id);
CREATE INDEX idx_cre_active  ON public.credits (account_id, remaining_amount)
    WHERE remaining_amount > 0;


CREATE TABLE public.subscription_plan_changes (
    id                   uuid          NOT NULL DEFAULT gen_random_uuid(),
    subscription_id      uuid          NOT NULL,

    previous_plan_id     uuid          NOT NULL,
    new_plan_id          uuid          NOT NULL,

    -- 'upgrade' | 'downgrade' | 'reactivation' | 'initial'
    change_type          text          NOT NULL,

    -- Monto del prorateo: positivo = cargo extra, negativo = crédito al cliente
    proration_amount     numeric(10,2) NULL,
    proration_invoice_id uuid          NULL,

    effective_at         timestamptz   NOT NULL DEFAULT now(),
    changed_by           uuid          NULL,
    notes                text          NULL,

    created_at           timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT spc_pkey      PRIMARY KEY (id),
    CONSTRAINT spc_sub_fkey  FOREIGN KEY (subscription_id)
        REFERENCES public.subscriptions(id),
    CONSTRAINT spc_inv_fkey  FOREIGN KEY (proration_invoice_id)
        REFERENCES public.invoices(id),
    CONSTRAINT spc_by_fkey   FOREIGN KEY (changed_by)
        REFERENCES public.users(id)
);

CREATE INDEX idx_spc_sub ON public.subscription_plan_changes (subscription_id);


CREATE TABLE public.usage_events (
    id               uuid          NOT NULL DEFAULT gen_random_uuid(),
    organization_id  uuid          NOT NULL,
    subscription_id  uuid          NOT NULL,

    -- 'gps_unit' | 'api_call_orion' | 'sms_alert' | 'report_export'
    metric_name      text          NOT NULL,

    quantity         numeric(14,4) NOT NULL DEFAULT 1,
    unit_label       text          NULL,    -- "vehículos" | "llamadas" | "SMS"

    period_start     timestamptz   NOT NULL,
    period_end       timestamptz   NOT NULL,

    -- Recurso que generó el evento
    resource_id      uuid          NULL,
    resource_type    text          NULL,    -- "device" | "unit"

    idempotency_key  text          NULL,
    recorded_at      timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT ue_pkey           PRIMARY KEY (id),
    CONSTRAINT ue_idem_key       UNIQUE (idempotency_key),
    CONSTRAINT ue_org_fkey       FOREIGN KEY (organization_id)
        REFERENCES public.organizations(id),
    CONSTRAINT ue_sub_fkey       FOREIGN KEY (subscription_id)
        REFERENCES public.subscriptions(id)
);

CREATE INDEX idx_ue_org_metric ON public.usage_events (organization_id, metric_name, period_start);
CREATE INDEX idx_ue_sub        ON public.usage_events (subscription_id, period_start);


CREATE TABLE public.billing_notifications (
    id                  uuid        NOT NULL DEFAULT gen_random_uuid(),
    account_id          uuid        NOT NULL,
    organization_id     uuid        NULL,
    invoice_id          uuid        NULL,
    payment_id          uuid        NULL,

    -- Tipo de notificación
    -- 'dunning_attempt_1' | 'dunning_attempt_2' | 'dunning_attempt_3'
    -- 'trial_ending_3d'   | 'trial_ending_1d'   | 'trial_converted'
    -- 'payment_success'   | 'invoice_created'   | 'invoice_due_soon'
    -- 'subscription_paused' | 'dispute_opened'  | 'refund_processed'
    notification_type   text        NOT NULL,

    -- 'email' | 'sms' | 'in_app'
    channel             text        NOT NULL,
    recipient           text        NOT NULL,   -- email o número de teléfono

    -- PENDING | SENT | DELIVERED | FAILED | BOUNCED
    delivery_status     text        NOT NULL DEFAULT 'PENDING',

    sent_at             timestamptz NULL,
    delivered_at        timestamptz NULL,
    failed_at           timestamptz NULL,
    failure_reason      text        NULL,

    -- ID del proveedor (SES, SendGrid, Twilio) para trazabilidad externa
    provider_message_id text        NULL,

    created_at          timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT bn_pkey       PRIMARY KEY (id),
    CONSTRAINT bn_account_fkey FOREIGN KEY (account_id)
        REFERENCES public.accounts(id),
    CONSTRAINT bn_org_fkey   FOREIGN KEY (organization_id)
        REFERENCES public.organizations(id),
    CONSTRAINT bn_invoice_fkey FOREIGN KEY (invoice_id)
        REFERENCES public.invoices(id),
    CONSTRAINT bn_payment_fkey FOREIGN KEY (payment_id)
        REFERENCES public.payments(id)
);

CREATE INDEX idx_bn_account ON public.billing_notifications (account_id);
CREATE INDEX idx_bn_invoice ON public.billing_notifications (invoice_id);
CREATE INDEX idx_bn_type    ON public.billing_notifications (notification_type, sent_at);


CREATE TABLE public.support_billing_cases (
    id          uuid        NOT NULL DEFAULT gen_random_uuid(),
    account_id  uuid        NOT NULL,
    payment_id  uuid        NULL,
    invoice_id  uuid        NULL,

    -- 'incorrect_amount' | 'charge_not_recognized' | 'refund_not_received'
    -- 'subscription_not_cancelled' | 'trial_charged' | 'other'
    reason      text        NOT NULL,
    description text        NOT NULL,

    -- 'open' | 'under_review' | 'resolved' | 'closed_no_action'
    case_status text        NOT NULL DEFAULT 'open',

    assigned_to uuid        NULL,
    resolution  text        NULL,
    resolved_at timestamptz NULL,

    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT sbc_pkey          PRIMARY KEY (id),
    CONSTRAINT sbc_account_fkey  FOREIGN KEY (account_id)
        REFERENCES public.accounts(id),
    CONSTRAINT sbc_payment_fkey  FOREIGN KEY (payment_id)
        REFERENCES public.payments(id),
    CONSTRAINT sbc_invoice_fkey  FOREIGN KEY (invoice_id)
        REFERENCES public.invoices(id),
    CONSTRAINT sbc_assigned_fkey FOREIGN KEY (assigned_to)
        REFERENCES public.users(id)
);

CREATE INDEX idx_sbc_account ON public.support_billing_cases (account_id);
CREATE INDEX idx_sbc_status  ON public.support_billing_cases (case_status);



ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS dunning_attempt_count int         NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS dunning_last_attempt  timestamptz,
  ADD COLUMN IF NOT EXISTS dunning_next_attempt  timestamptz,
  ADD COLUMN IF NOT EXISTS active_units          int         NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS credit_balance        numeric(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS paused_at             timestamptz,
  ADD COLUMN IF NOT EXISTS resumes_at            timestamptz,
  ADD COLUMN IF NOT EXISTS pause_reason          text,
  ADD COLUMN IF NOT EXISTS external_id           text;

CREATE INDEX idx_sub_external ON public.subscriptions (external_id)
  WHERE external_id IS NOT NULL;


COMMIT;