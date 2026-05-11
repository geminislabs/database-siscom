-- ============================================================
-- 02_schema.sql
-- Schema principal de SISCOM
-- Incluye: enums, tablas de negocio, telemetría y alertas
-- ============================================================

-- ─────────────────────────────────────────────
-- ENUMS
-- ─────────────────────────────────────────────

DO $$ BEGIN
  CREATE TYPE public.event_type_enum AS ENUM (
    'HARSH_ACCEL', 'HARSH_BRKE', 'OVERSPEED_START', 'OVERSPEED_END',
    'IDLE_START', 'IDLE_END', 'JAMMING', 'DISCONNECT', 'CUSTOM'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ─────────────────────────────────────────────
-- ACCOUNTS / BILLING
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.accounts (
  id           uuid DEFAULT gen_random_uuid() NOT NULL,
  account_name text NOT NULL,
  status       text DEFAULT 'ACTIVE'::text NOT NULL,
  billing_email text NULL,
  created_at   timestamptz DEFAULT now() NOT NULL,
  updated_at   timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT accounts_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_accounts_billing_email
  ON public.accounts (billing_email) WHERE billing_email IS NOT NULL;

-- ─────────────────────────────────────────────
-- USERS
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.users (
  id              uuid DEFAULT gen_random_uuid() NOT NULL,
  cognito_sub     text NULL,
  email           text NOT NULL,
  full_name       text NULL,
  is_master       bool DEFAULT false NULL,
  last_login_at   timestamp NULL,
  created_at      timestamp DEFAULT now() NULL,
  updated_at      timestamp DEFAULT now() NULL,
  password_hash   text DEFAULT ''::text NULL,
  email_verified  bool DEFAULT false NOT NULL,
  organization_id uuid NULL,
  CONSTRAINT users_cognito_sub_key UNIQUE (cognito_sub),
  CONSTRAINT users_email_key UNIQUE (email),
  CONSTRAINT users_pkey PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS idx_users_cognito_sub ON public.users (cognito_sub);

-- ─────────────────────────────────────────────
-- CAPABILITIES / PLANS
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.capabilities (
  id          uuid DEFAULT gen_random_uuid() NOT NULL,
  code        text NOT NULL,
  description text NOT NULL,
  value_type  text NOT NULL,
  created_at  timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT capabilities_code_key UNIQUE (code),
  CONSTRAINT capabilities_pkey PRIMARY KEY (id),
  CONSTRAINT capabilities_value_type_check
    CHECK (value_type = ANY (ARRAY['int','bool','text']))
);

CREATE TABLE IF NOT EXISTS public.products (
  id          uuid DEFAULT gen_random_uuid() NOT NULL,
  code        text NOT NULL,
  name        text NOT NULL,
  description text NULL,
  is_active   bool DEFAULT true NULL,
  created_at  timestamptz DEFAULT now() NULL,
  CONSTRAINT products_code_key UNIQUE (code),
  CONSTRAINT products_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.plans (
  id              uuid DEFAULT gen_random_uuid() NOT NULL,
  name            text NOT NULL,
  description     text NULL,
  price_monthly   numeric(10,2) DEFAULT 0 NOT NULL,
  price_yearly    numeric(10,2) DEFAULT 0 NOT NULL,
  max_devices     int4 DEFAULT 1 NOT NULL,
  history_days    int4 DEFAULT 7 NOT NULL,
  ai_features     bool DEFAULT false NULL,
  analytics_tools bool DEFAULT false NULL,
  features        jsonb DEFAULT '{}'::jsonb NULL,
  created_at      timestamp DEFAULT now() NULL,
  updated_at      timestamp DEFAULT now() NULL,
  code            text NULL,
  is_active       bool DEFAULT true NOT NULL,
  CONSTRAINT plans_name_key UNIQUE (name),
  CONSTRAINT plans_pkey PRIMARY KEY (id),
  CONSTRAINT plans_unique UNIQUE (code)
);

CREATE TABLE IF NOT EXISTS public.plan_products (
  plan_id    uuid NOT NULL,
  product_id uuid NOT NULL,
  CONSTRAINT plan_products_pkey PRIMARY KEY (plan_id, product_id),
  CONSTRAINT plan_products_plan_id_fkey    FOREIGN KEY (plan_id)    REFERENCES public.plans(id)    ON DELETE CASCADE,
  CONSTRAINT plan_products_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.plan_capabilities (
  id            uuid DEFAULT gen_random_uuid() NOT NULL,
  plan_id       uuid NOT NULL,
  capability_id uuid NOT NULL,
  value_int     int4 NULL,
  value_bool    bool NULL,
  value_text    text NULL,
  created_at    timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT plan_capabilities_pkey PRIMARY KEY (id),
  CONSTRAINT plan_capabilities_plan_id_capability_id_key UNIQUE (plan_id, capability_id),
  CONSTRAINT plan_capabilities_capability_id_fkey FOREIGN KEY (capability_id) REFERENCES public.capabilities(id) ON DELETE CASCADE,
  CONSTRAINT plan_capabilities_plan_id_fkey        FOREIGN KEY (plan_id)       REFERENCES public.plans(id)       ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_plan_capabilities_plan ON public.plan_capabilities (plan_id);
CREATE INDEX IF NOT EXISTS idx_plan_capabilities_cap  ON public.plan_capabilities (capability_id);

-- ─────────────────────────────────────────────
-- ORGANIZATIONS / SUBSCRIPTIONS
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.subscriptions (
  id                   uuid DEFAULT gen_random_uuid() NOT NULL,
  plan_id              uuid NOT NULL,
  status               text NOT NULL,
  started_at           timestamp DEFAULT now() NOT NULL,
  expires_at           timestamp NOT NULL,
  cancelled_at         timestamp NULL,
  renewed_from         uuid NULL,
  auto_renew           bool DEFAULT true NULL,
  created_at           timestamp DEFAULT now() NULL,
  updated_at           timestamp DEFAULT now() NULL,
  organization_id      uuid NULL,
  external_id          text NULL,
  billing_cycle        text DEFAULT 'MONTHLY'::text NULL,
  current_period_start timestamptz NULL,
  current_period_end   timestamptz NULL,
  -- dunning / usage columns
  dunning_attempt_count int  NOT NULL DEFAULT 0,
  dunning_last_attempt  timestamptz,
  dunning_next_attempt  timestamptz,
  active_units          int  NOT NULL DEFAULT 1,
  credit_balance        numeric(10,2) NOT NULL DEFAULT 0,
  paused_at             timestamptz,
  resumes_at            timestamptz,
  pause_reason          text,
  CONSTRAINT subscriptions_pkey PRIMARY KEY (id),
  CONSTRAINT subscriptions_status_check
    CHECK (status = ANY (ARRAY['ACTIVE','CANCELLED','EXPIRED','TRIAL'])),
  CONSTRAINT subscriptions_plan_id_fkey     FOREIGN KEY (plan_id)      REFERENCES public.plans(id),
  CONSTRAINT subscriptions_renewed_from_fkey FOREIGN KEY (renewed_from) REFERENCES public.subscriptions(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_subscriptions_organization_id ON public.subscriptions (organization_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status         ON public.subscriptions (status);
CREATE UNIQUE INDEX IF NOT EXISTS idx_sub_external
  ON public.subscriptions (external_id) WHERE external_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.organizations (
  id                     uuid DEFAULT gen_random_uuid() NOT NULL,
  name                   text NOT NULL,
  status                 text DEFAULT 'ACTIVE'::text NULL,
  created_at             timestamp DEFAULT now() NULL,
  updated_at             timestamp DEFAULT now() NULL,
  active_subscription_id uuid NULL,
  billing_email          text NULL,
  country                text NULL,
  timezone               text DEFAULT 'UTC'::text NULL,
  metadata               jsonb DEFAULT '{}'::jsonb NULL,
  account_id             uuid NOT NULL,
  CONSTRAINT organizations_pkey PRIMARY KEY (id),
  CONSTRAINT organizations_status_check
    CHECK (status = ANY (ARRAY['PENDING','ACTIVE','SUSPENDED','DELETED'])),
  CONSTRAINT organizations_account_id_fkey
    FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE,
  CONSTRAINT organizations_active_subscription_id_fkey
    FOREIGN KEY (active_subscription_id) REFERENCES public.subscriptions(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_organizations_account_id ON public.organizations (account_id);
CREATE INDEX IF NOT EXISTS idx_org_account              ON public.organizations (account_id);

-- FK circular: subscriptions → organizations (añadida después)
ALTER TABLE public.subscriptions
  DROP CONSTRAINT IF EXISTS subscriptions_organization_id_fkey;
ALTER TABLE public.subscriptions
  ADD CONSTRAINT subscriptions_organization_id_fkey
    FOREIGN KEY (organization_id) REFERENCES public.organizations(id);

-- ─────────────────────────────────────────────
-- ACCOUNT USERS / EVENTS
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.account_users (
  id         uuid NOT NULL,
  account_id uuid NOT NULL,
  user_id    uuid NOT NULL,
  role       text NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT account_users_account_id_user_id_key UNIQUE (account_id, user_id),
  CONSTRAINT account_users_pkey       PRIMARY KEY (id),
  CONSTRAINT account_users_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id),
  CONSTRAINT account_users_user_id_fkey    FOREIGN KEY (user_id)    REFERENCES public.users(id)
);

CREATE TABLE IF NOT EXISTS public.account_events (
  id              uuid NOT NULL,
  account_id      uuid NOT NULL,
  organization_id uuid NULL,
  actor_user_id   uuid NULL,
  actor_type      text NOT NULL,
  event_type      text NOT NULL,
  target_type     text NOT NULL,
  target_id       uuid NULL,
  metadata        jsonb NULL,
  ip_address      inet NULL,
  user_agent      text NULL,
  created_at      timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT account_events_pkey PRIMARY KEY (id),
  CONSTRAINT account_events_account_id_fkey      FOREIGN KEY (account_id)      REFERENCES public.accounts(id),
  CONSTRAINT account_events_actor_user_id_fkey   FOREIGN KEY (actor_user_id)   REFERENCES public.users(id),
  CONSTRAINT account_events_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id)
);
CREATE INDEX IF NOT EXISTS idx_account_events_account ON public.account_events (account_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_account_events_org     ON public.account_events (organization_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_account_events_type    ON public.account_events (event_type);

-- ─────────────────────────────────────────────
-- ORGANIZATION USERS / CAPABILITIES
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.organization_users (
  id              uuid DEFAULT gen_random_uuid() NOT NULL,
  organization_id uuid NOT NULL,
  user_id         uuid NOT NULL,
  role            text DEFAULT 'member'::text NOT NULL,
  created_at      timestamptz DEFAULT now() NULL,
  CONSTRAINT org_user_role_check CHECK (role = ANY (ARRAY['owner','admin','billing','member'])),
  CONSTRAINT organization_users_pkey PRIMARY KEY (id),
  CONSTRAINT uq_org_user UNIQUE (organization_id, user_id),
  CONSTRAINT organization_users_organization_id_fkey
    FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE,
  CONSTRAINT organization_users_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.organization_capabilities (
  id              uuid NOT NULL,
  organization_id uuid NOT NULL,
  capability_id   uuid NOT NULL,
  value_int       int4 NULL,
  value_bool      bool NULL,
  value_text      text NULL,
  created_at      timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT organization_capabilities_organization_id_capability_id_key
    UNIQUE (organization_id, capability_id),
  CONSTRAINT organization_capabilities_pkey PRIMARY KEY (id),
  CONSTRAINT organization_capabilities_capability_id_fkey
    FOREIGN KEY (capability_id) REFERENCES public.capabilities(id),
  CONSTRAINT organization_capabilities_organization_id_fkey
    FOREIGN KEY (organization_id) REFERENCES public.organizations(id)
);

-- ─────────────────────────────────────────────
-- INVITATIONS / TOKENS
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.invitations (
  id               uuid DEFAULT gen_random_uuid() NOT NULL,
  invited_email    text NOT NULL,
  invited_by_user_id uuid NOT NULL,
  token            text NOT NULL,
  expires_at       timestamp NOT NULL,
  accepted         bool DEFAULT false NULL,
  created_at       timestamp DEFAULT now() NULL,
  organization_id  uuid NULL,
  CONSTRAINT invitations_pkey        PRIMARY KEY (id),
  CONSTRAINT invitations_token_key   UNIQUE (token),
  CONSTRAINT invitations_invited_by_user_id_fkey
    FOREIGN KEY (invited_by_user_id) REFERENCES public.users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_invitations_expires_at
  ON public.invitations (expires_at) WHERE accepted = false;
CREATE INDEX IF NOT EXISTS idx_invitations_organization_id ON public.invitations (organization_id);

CREATE TABLE IF NOT EXISTS public.tokens_confirmacion (
  id              uuid DEFAULT gen_random_uuid() NOT NULL,
  token           varchar NOT NULL,
  expires_at      timestamp DEFAULT (now() + '01:00:00'::interval) NOT NULL,
  used            bool DEFAULT false NOT NULL,
  type            varchar DEFAULT 'email_verification'::character varying NOT NULL,
  user_id         uuid NULL,
  created_at      timestamptz DEFAULT now() NOT NULL,
  email           varchar(255) NULL,
  full_name       varchar(255) NULL,
  password_temp   varchar(255) NULL,
  organization_id uuid NULL,
  CONSTRAINT tokens_confirmacion_pkey      PRIMARY KEY (id),
  CONSTRAINT tokens_confirmacion_token_key UNIQUE (token),
  CONSTRAINT tokens_confirmacion_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_tokens_confirmacion_token  ON public.tokens_confirmacion (token);
CREATE INDEX IF NOT EXISTS idx_tokens_confirmacion_org_id ON public.tokens_confirmacion (organization_id);

-- ─────────────────────────────────────────────
-- PAYMENTS / ORDERS
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.payments (
  id              uuid DEFAULT gen_random_uuid() NOT NULL,
  amount          numeric(10,2) NOT NULL,
  currency        text DEFAULT 'MXN'::text NULL,
  method          text NULL,
  paid_at         timestamp DEFAULT now() NULL,
  status          text NOT NULL,
  transaction_ref text NULL,
  invoice_url     text NULL,
  created_at      timestamp DEFAULT now() NULL,
  account_id      uuid NULL,
  CONSTRAINT payments_pkey PRIMARY KEY (id),
  CONSTRAINT payments_status_check
    CHECK (status = ANY (ARRAY['SUCCESS','FAILED','REFUNDED','PENDING']))
);
CREATE INDEX IF NOT EXISTS idx_payments_account_id ON public.payments (account_id);
CREATE INDEX IF NOT EXISTS idx_payments_status     ON public.payments (status);

CREATE TABLE IF NOT EXISTS public.orders (
  id              uuid DEFAULT gen_random_uuid() NOT NULL,
  total_amount    numeric(10,2) NOT NULL,
  status          text NOT NULL,
  payment_id      uuid NULL,
  shipped_at      timestamp NULL,
  created_at      timestamp DEFAULT now() NULL,
  organization_id uuid NULL,
  CONSTRAINT orders_pkey PRIMARY KEY (id),
  CONSTRAINT orders_status_check
    CHECK (status = ANY (ARRAY['PENDING','PAID','SHIPPED','CANCELLED','COMPLETED'])),
  CONSTRAINT orders_payment_id_fkey
    FOREIGN KEY (payment_id) REFERENCES public.payments(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_orders_organization_id ON public.orders (organization_id);
CREATE INDEX IF NOT EXISTS idx_orders_status          ON public.orders (status);

CREATE TABLE IF NOT EXISTS public.order_items (
  id          uuid DEFAULT gen_random_uuid() NOT NULL,
  order_id    uuid NOT NULL,
  device_id   text NULL,
  item_type   text NULL,
  description text NULL,
  quantity    int4 DEFAULT 1 NOT NULL,
  unit_price  numeric(10,2) NOT NULL,
  total_price numeric(10,2) GENERATED ALWAYS AS (quantity::numeric * unit_price) STORED NULL,
  CONSTRAINT order_items_item_type_check
    CHECK (item_type = ANY (ARRAY['DEVICE','ACCESSORY','SERVICE'])),
  CONSTRAINT order_items_pkey     PRIMARY KEY (id),
  CONSTRAINT order_items_order_id_fkey
    FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items (order_id);

-- ─────────────────────────────────────────────
-- DEVICES
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.devices (
  device_id          text NOT NULL,
  brand              text NULL,
  model              text NULL,
  firmware_version   text NULL,
  status             text DEFAULT 'nuevo'::text NOT NULL,
  last_comm_at       timestamptz NULL,
  created_at         timestamptz DEFAULT now() NULL,
  updated_at         timestamptz DEFAULT now() NULL,
  last_assignment_at timestamptz NULL,
  notes              text NULL,
  organization_id    uuid NULL,
  CONSTRAINT devices_pkey PRIMARY KEY (device_id),
  CONSTRAINT devices_status_check
    CHECK (status = ANY (ARRAY['nuevo','preparado','enviado','entregado','asignado','devuelto','inactivo'])),
  CONSTRAINT devices_organization_id_fkey
    FOREIGN KEY (organization_id) REFERENCES public.organizations(id)
);
CREATE INDEX IF NOT EXISTS idx_devices_status         ON public.devices (status);
CREATE INDEX IF NOT EXISTS idx_devices_brand_model    ON public.devices (brand, model);
CREATE INDEX IF NOT EXISTS idx_devices_organization_id ON public.devices (organization_id);

CREATE TABLE IF NOT EXISTS public.device_events (
  id           uuid DEFAULT gen_random_uuid() NOT NULL,
  device_id    text NOT NULL,
  event_type   text NOT NULL,
  old_status   text NULL,
  new_status   text NULL,
  performed_by uuid NULL,
  event_details text NULL,
  created_at   timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT check_event_type CHECK (
    event_type = ANY (ARRAY[
      'creado','preparado','enviado','entregado','asignado',
      'devuelto','firmware_actualizado','nota','estado_cambiado'
    ])
  ),
  CONSTRAINT device_events_pkey PRIMARY KEY (id),
  CONSTRAINT device_events_device_id_fkey
    FOREIGN KEY (device_id) REFERENCES public.devices(device_id) ON DELETE CASCADE,
  CONSTRAINT device_events_performed_by_fkey
    FOREIGN KEY (performed_by) REFERENCES public.users(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_device_events_device_id  ON public.device_events (device_id);
CREATE INDEX IF NOT EXISTS idx_device_events_event_type ON public.device_events (event_type);
CREATE INDEX IF NOT EXISTS idx_device_events_created_at ON public.device_events (created_at);

CREATE TABLE IF NOT EXISTS public.sim_cards (
  sim_id      uuid DEFAULT gen_random_uuid() NOT NULL,
  device_id   text NOT NULL,
  carrier     text DEFAULT 'KORE'::text NOT NULL,
  iccid       varchar NOT NULL,
  imsi        varchar NULL,
  msisdn      varchar NULL,
  status      text DEFAULT 'active'::text NOT NULL,
  metadata    jsonb NULL,
  created_at  timestamptz DEFAULT now() NOT NULL,
  updated_at  timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT sim_cards_pkey PRIMARY KEY (sim_id),
  CONSTRAINT unique_active_sim_per_device UNIQUE (device_id) DEFERRABLE,
  CONSTRAINT sim_cards_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(device_id)
);
CREATE INDEX IF NOT EXISTS idx_sim_cards_device ON public.sim_cards (device_id);
CREATE INDEX IF NOT EXISTS idx_sim_cards_iccid  ON public.sim_cards (iccid);

CREATE TABLE IF NOT EXISTS public.sim_kore_profiles (
  sim_id          uuid NOT NULL,
  kore_sim_id     text NOT NULL,
  kore_account_id text NULL,
  created_at      timestamptz DEFAULT now() NOT NULL,
  updated_at      timestamptz DEFAULT now() NULL,
  CONSTRAINT sim_kore_profiles_pkey PRIMARY KEY (sim_id),
  CONSTRAINT sim_kore_profiles_sim_id_fkey FOREIGN KEY (sim_id) REFERENCES public.sim_cards(sim_id)
);

CREATE TABLE IF NOT EXISTS public.command_templates (
  template_id uuid DEFAULT gen_random_uuid() NOT NULL,
  name        text NOT NULL,
  payload     text NOT NULL,
  description text NULL,
  created_at  timestamptz DEFAULT now() NULL,
  CONSTRAINT command_templates_pkey PRIMARY KEY (template_id)
);

CREATE TABLE IF NOT EXISTS public.commands (
  command_id         uuid DEFAULT gen_random_uuid() NOT NULL,
  template_id        uuid NULL,
  command            text NOT NULL,
  media              text NOT NULL,
  request_user_id    uuid NULL,
  request_user_email text NOT NULL,
  device_id          text NOT NULL,
  requested_at       timestamptz DEFAULT now() NULL,
  updated_at         timestamptz DEFAULT now() NULL,
  status             text DEFAULT 'pending'::text NOT NULL,
  metadata           jsonb NULL,
  CONSTRAINT commands_pkey PRIMARY KEY (command_id),
  CONSTRAINT commands_device_id_fkey   FOREIGN KEY (device_id)    REFERENCES public.devices(device_id),
  CONSTRAINT commands_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.command_templates(template_id)
);

-- ─────────────────────────────────────────────
-- UNITS (vehículos / activos)
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.units (
  id              uuid DEFAULT gen_random_uuid() NOT NULL,
  name            text NOT NULL,
  description     text NULL,
  deleted_at      timestamptz NULL,
  organization_id uuid NULL,
  CONSTRAINT units_pkey PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS idx_units_organization_id ON public.units (organization_id);
CREATE INDEX IF NOT EXISTS idx_units_deleted_at
  ON public.units (deleted_at) WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS public.unit_profile (
  profile_id  uuid DEFAULT gen_random_uuid() NOT NULL,
  unit_id     uuid NOT NULL,
  unit_type   text NOT NULL,
  icon_type   text NULL,
  description text NULL,
  brand       text NULL,
  model       text NULL,
  serial      text NULL,
  color       text NULL,
  year        int4 NULL,
  created_at  timestamptz DEFAULT now() NULL,
  updated_at  timestamptz DEFAULT now() NULL,
  CONSTRAINT unit_profile_pkey        PRIMARY KEY (profile_id),
  CONSTRAINT unit_profile_unit_id_key UNIQUE (unit_id),
  CONSTRAINT fk_unit_profile_unit     FOREIGN KEY (unit_id) REFERENCES public.units(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_unit_profile_type ON public.unit_profile (unit_type);

CREATE TABLE IF NOT EXISTS public.vehicle_profile (
  unit_id    uuid NOT NULL,
  plate      text NULL,
  vin        text NULL,
  fuel_type  text NULL,
  passengers int4 NULL,
  created_at timestamptz DEFAULT now() NULL,
  updated_at timestamptz DEFAULT now() NULL,
  CONSTRAINT vehicle_profile_pkey PRIMARY KEY (unit_id),
  CONSTRAINT fk_vehicle_unit FOREIGN KEY (unit_id) REFERENCES public.unit_profile(unit_id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_vehicle_plate ON public.vehicle_profile (plate);

CREATE TABLE IF NOT EXISTS public.unit_devices (
  id           uuid DEFAULT gen_random_uuid() NOT NULL,
  unit_id      uuid NOT NULL,
  device_id    text NOT NULL,
  assigned_at  timestamptz DEFAULT now() NULL,
  unassigned_at timestamptz NULL,
  is_active    bool GENERATED ALWAYS AS (unassigned_at IS NULL) STORED NULL,
  CONSTRAINT unit_devices_pkey PRIMARY KEY (id),
  CONSTRAINT uq_unit_devices_unit_device UNIQUE (unit_id, device_id),
  CONSTRAINT unit_devices_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(device_id) ON DELETE CASCADE,
  CONSTRAINT unit_devices_unit_id_fkey   FOREIGN KEY (unit_id)   REFERENCES public.units(id)          ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_unit_devices_unit_id   ON public.unit_devices (unit_id);
CREATE INDEX IF NOT EXISTS idx_unit_devices_device_id ON public.unit_devices (device_id);
CREATE INDEX IF NOT EXISTS idx_unit_devices_is_active ON public.unit_devices (is_active);

CREATE TABLE IF NOT EXISTS public.user_units (
  id         uuid DEFAULT gen_random_uuid() NOT NULL,
  user_id    uuid NOT NULL,
  unit_id    uuid NOT NULL,
  granted_by uuid NULL,
  granted_at timestamptz DEFAULT now() NULL,
  role       text DEFAULT 'viewer'::text NOT NULL,
  CONSTRAINT check_user_units_role CHECK (role = ANY (ARRAY['viewer','editor','admin'])),
  CONSTRAINT uq_user_units_user_unit UNIQUE (user_id, unit_id),
  CONSTRAINT user_units_pkey         PRIMARY KEY (id),
  CONSTRAINT user_units_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(id)  ON DELETE SET NULL,
  CONSTRAINT user_units_unit_id_fkey    FOREIGN KEY (unit_id)    REFERENCES public.units(id)   ON DELETE CASCADE,
  CONSTRAINT user_units_user_id_fkey    FOREIGN KEY (user_id)    REFERENCES public.users(id)   ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_user_units_user_id ON public.user_units (user_id);
CREATE INDEX IF NOT EXISTS idx_user_units_unit_id ON public.user_units (unit_id);
CREATE INDEX IF NOT EXISTS idx_user_units_role    ON public.user_units (role);

-- ─────────────────────────────────────────────
-- TELEMETRY (comunicaciones)
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.communications_current_state (
  device_id              varchar(100) NOT NULL,
  uuid                   varchar(255) NOT NULL,
  backup_battery_voltage numeric(5,2) NULL,
  cell_id                varchar(50) NULL,
  course                 numeric(6,2) NULL,
  delivery_type          varchar(20) NULL,
  engine_status          varchar(10) NULL,
  firmware               varchar(20) NULL,
  fix_status             varchar(5) NULL,
  gps_datetime           timestamp NULL,
  gps_epoch              int8 NULL,
  idle_time              int4 NULL,
  lac                    varchar(10) NULL,
  latitude               numeric(10,8) NULL,
  longitude              numeric(11,8) NULL,
  main_battery_voltage   numeric(5,2) NULL,
  mcc                    varchar(10) NULL,
  mnc                    varchar(10) NULL,
  model                  varchar(10) NULL,
  msg_class              varchar(20) NOT NULL,
  msg_counter            varchar NULL,
  network_status         varchar(50) NULL,
  odometer               int8 NULL,
  rx_lvl                 int4 NULL,
  satellites             int4 NULL,
  speed                  numeric(8,2) NULL,
  speed_time             int4 NULL,
  total_distance         int8 NULL,
  trip_distance          int8 NULL,
  trip_hourmeter         int4 NULL,
  bytes_count            int4 NULL,
  client_ip              text NULL,
  client_port            int4 NULL,
  decoded_epoch          int8 NULL,
  received_epoch         int8 NULL,
  raw_message            text NULL,
  received_at            timestamp DEFAULT CURRENT_TIMESTAMP NULL,
  created_at             timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  alert_type             varchar NULL,
  backup_battery_percent numeric NULL,
  CONSTRAINT communications_current_state_pkey PRIMARY KEY (device_id, msg_class),
  CONSTRAINT communications_current_state_uuid_key UNIQUE (uuid)
);
CREATE INDEX IF NOT EXISTS idx_comm_current_decoded_epoch ON public.communications_current_state (decoded_epoch DESC);
CREATE INDEX IF NOT EXISTS idx_comm_current_gps_datetime  ON public.communications_current_state (gps_datetime DESC);

CREATE TABLE IF NOT EXISTS public.communications_suntech (
  id                     bigserial NOT NULL,
  uuid                   varchar(255) NOT NULL,
  device_id              varchar(100) NOT NULL,
  backup_battery_voltage numeric(5,2) NULL,
  cell_id                varchar(50) NULL,
  course                 numeric(6,2) NULL,
  delivery_type          varchar(20) NULL,
  engine_status          varchar(10) NULL,
  firmware               varchar(20) NULL,
  fix_status             varchar(5) NULL,
  gps_datetime           timestamp NULL,
  gps_epoch              int8 NULL,
  idle_time              int4 NULL,
  lac                    varchar(10) NULL,
  latitude               numeric(10,8) NULL,
  longitude              numeric(11,8) NULL,
  main_battery_voltage   numeric(5,2) NULL,
  mcc                    varchar(10) NULL,
  mnc                    varchar(10) NULL,
  model                  varchar(10) NULL,
  msg_class              varchar(20) NULL,
  msg_counter            varchar NULL,
  network_status         varchar(50) NULL,
  odometer               int8 NULL,
  rx_lvl                 int4 NULL,
  satellites             int4 NULL,
  speed                  numeric(8,2) NULL,
  speed_time             int4 NULL,
  total_distance         int8 NULL,
  trip_distance          int8 NULL,
  trip_hourmeter         int4 NULL,
  bytes_count            int4 NULL,
  client_ip              text NULL,
  client_port            int4 NULL,
  decoded_epoch          int8 NULL,
  received_epoch         int8 NULL,
  raw_message            text NULL,
  received_at            timestamp DEFAULT CURRENT_TIMESTAMP NULL,
  created_at             timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  alert_type             varchar NULL,
  backup_battery_percent numeric NULL,
  CONSTRAINT communications_suntech_pkey     PRIMARY KEY (id),
  CONSTRAINT communications_suntech_uuid_key UNIQUE (uuid)
);
CREATE INDEX IF NOT EXISTS idx_comm_device_id      ON public.communications_suntech (device_id);
CREATE INDEX IF NOT EXISTS idx_comm_gps_datetime   ON public.communications_suntech (gps_datetime DESC);
CREATE INDEX IF NOT EXISTS idx_comm_decoded_epoch  ON public.communications_suntech (decoded_epoch DESC);
CREATE INDEX IF NOT EXISTS idx_comm_msg_class      ON public.communications_suntech (msg_class);
CREATE INDEX IF NOT EXISTS idx_comm_created_at     ON public.communications_suntech (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comm_received_at    ON public.communications_suntech (received_at DESC);
CREATE INDEX IF NOT EXISTS idx_comm_uuid           ON public.communications_suntech (uuid);
CREATE INDEX IF NOT EXISTS idx_comm_device_created ON public.communications_suntech (device_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.communications_queclink (
  id                     bigserial NOT NULL,
  uuid                   varchar(255) NOT NULL,
  device_id              varchar(100) NOT NULL,
  backup_battery_voltage numeric(5,2) NULL,
  cell_id                varchar(50) NULL,
  course                 numeric(6,2) NULL,
  delivery_type          varchar(20) NULL,
  engine_status          varchar(10) NULL,
  firmware               varchar(20) NULL,
  fix_status             varchar(5) NULL,
  gps_datetime           timestamp NULL,
  gps_epoch              int8 NULL,
  idle_time              int4 NULL,
  lac                    varchar(10) NULL,
  latitude               numeric(10,8) NULL,
  longitude              numeric(11,8) NULL,
  main_battery_voltage   numeric(5,2) NULL,
  mcc                    varchar(10) NULL,
  mnc                    varchar(10) NULL,
  model                  varchar(10) NULL,
  msg_class              varchar(20) NULL,
  msg_counter            varchar NULL,
  network_status         varchar(50) NULL,
  odometer               int8 NULL,
  rx_lvl                 int4 NULL,
  satellites             int4 NULL,
  speed                  numeric(8,2) NULL,
  speed_time             int4 NULL,
  total_distance         int8 NULL,
  trip_distance          int8 NULL,
  trip_hourmeter         int4 NULL,
  bytes_count            int4 NULL,
  client_ip              text NULL,
  client_port            int4 NULL,
  decoded_epoch          int8 NULL,
  received_epoch         int8 NULL,
  raw_message            text NULL,
  received_at            timestamp DEFAULT CURRENT_TIMESTAMP NULL,
  created_at             timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  alert_type             varchar NULL,
  backup_battery_percent numeric NULL,
  CONSTRAINT communications_queclink_pkey     PRIMARY KEY (id),
  CONSTRAINT communications_queclink_uuid_key UNIQUE (uuid)
);
CREATE INDEX IF NOT EXISTS idx_comm_device_id_q      ON public.communications_queclink (device_id);
CREATE INDEX IF NOT EXISTS idx_comm_gps_datetime_q   ON public.communications_queclink (gps_datetime DESC);
CREATE INDEX IF NOT EXISTS idx_comm_decoded_epoch_q  ON public.communications_queclink (decoded_epoch DESC);
CREATE INDEX IF NOT EXISTS idx_comm_msg_class_q      ON public.communications_queclink (msg_class);
CREATE INDEX IF NOT EXISTS idx_comm_created_at_q     ON public.communications_queclink (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comm_received_at_q    ON public.communications_queclink (received_at DESC);
CREATE INDEX IF NOT EXISTS idx_comm_uuid_q           ON public.communications_queclink (uuid);
CREATE INDEX IF NOT EXISTS idx_comm_device_created_q ON public.communications_queclink (device_id, created_at DESC);

-- ─────────────────────────────────────────────
-- TRIPS / TELEMETRY
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.trips (
  trip_id              uuid NOT NULL,
  device_id            varchar(20) NOT NULL,
  start_time           timestamptz NOT NULL,
  end_time             timestamptz NULL,
  start_lat            float8 NULL,
  start_lng            float8 NULL,
  end_lat              float8 NULL,
  end_lng              float8 NULL,
  distance_meters      int4 NULL,
  created_at           timestamptz DEFAULT now() NULL,
  start_odometer_meters int4 NULL,
  end_odometer_meters  int4 NULL,
  CONSTRAINT trips_pkey PRIMARY KEY (trip_id)
);
CREATE INDEX IF NOT EXISTS idx_trips_device_start ON public.trips (device_id, start_time);
CREATE INDEX IF NOT EXISTS idx_trips_start_ts     ON public.trips (start_time);

CREATE TABLE IF NOT EXISTS public.trip_stats (
  trip_id            uuid NOT NULL,
  point_count        int4 NULL,
  alert_count        int4 NULL,
  event_count        int4 NULL,
  avg_speed          float4 NULL,
  max_speed          float4 NULL,
  distance_meters    int4 NULL,
  driving_score      float4 NULL,
  harsh_accel_count  int4 NULL,
  harsh_brake_count  int4 NULL,
  idle_time_seconds  int4 NULL,
  overspeed_segments int4 NULL,
  created_at         timestamptz DEFAULT now() NULL,
  updated_at         timestamptz DEFAULT now() NULL,
  CONSTRAINT trip_stats_pkey      PRIMARY KEY (trip_id),
  CONSTRAINT trip_stats_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.trips(trip_id)
);

CREATE TABLE IF NOT EXISTS public.trip_current_state (
  device_id            varchar NOT NULL,
  current_trip_id      uuid NULL,
  ignition_on          bool DEFAULT false NOT NULL,
  last_point_at        timestamptz NULL,
  last_lat             float8 NULL,
  last_lng             float8 NULL,
  last_speed           float8 NULL,
  last_correlation_id  uuid NULL,
  last_updated_at      timestamptz DEFAULT now() NOT NULL,
  last_odometer_meters int4 NULL,
  CONSTRAINT trip_current_state_pkey PRIMARY KEY (device_id)
);

CREATE TABLE IF NOT EXISTS public.trip_points (
  point_id       bigserial NOT NULL,
  trip_id        uuid NOT NULL,
  device_id      varchar NOT NULL,
  timestamp      timestamptz NOT NULL,
  lat            float8 NOT NULL,
  lng            float8 NOT NULL,
  speed          float8 NULL,
  heading        float8 NULL,
  correlation_id uuid NOT NULL,
  odometer_meters int4 NULL,
  CONSTRAINT trip_points_pkey PRIMARY KEY (device_id, timestamp, correlation_id)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_trip_points_corr_unique
  ON public.trip_points (device_id, correlation_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_trip_points_device_time ON public.trip_points (device_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_trip_points_time        ON public.trip_points (timestamp DESC);

-- Partitioned tables (trip_alerts, trip_events)
CREATE TABLE IF NOT EXISTS public.trip_alerts (
  alert_id       uuid NOT NULL,
  trip_id        uuid NOT NULL,
  timestamp      timestamptz NOT NULL,
  lat            float8 NULL,
  lon            float8 NULL,
  alert_type     text NOT NULL,
  raw_code       int4 NULL,
  severity       int2 DEFAULT 1 NULL,
  metadata       jsonb NULL,
  created_at     timestamptz DEFAULT now() NULL,
  device_id      varchar NOT NULL,
  correlation_id uuid NULL
) PARTITION BY RANGE (timestamp);

CREATE TABLE IF NOT EXISTS public.trip_events (
  event_id   uuid NOT NULL,
  trip_id    uuid NOT NULL,
  timestamp  timestamptz NOT NULL,
  lat        float8 NULL,
  lon        float8 NULL,
  event_type public.event_type_enum NOT NULL,
  source     varchar(30) DEFAULT 'platform'::character varying NULL,
  rule_id    uuid NULL,
  metadata   jsonb NULL,
  created_at timestamptz DEFAULT now() NULL,
  device_id  varchar NOT NULL
) PARTITION BY RANGE (timestamp);

CREATE INDEX IF NOT EXISTS idx_trip_events_device_time
  ON public.trip_events (device_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_trip_alerts_device_time
  ON public.trip_alerts (device_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_trip_alerts_type
  ON public.trip_alerts (alert_type);
CREATE UNIQUE INDEX IF NOT EXISTS idx_trip_alerts_corr_unique
  ON public.trip_alerts (device_id, correlation_id, timestamp);

-- Particiones por defecto para desarrollo (cubre los próximos 2 años)
CREATE TABLE IF NOT EXISTS public.trip_alerts_2024
  PARTITION OF public.trip_alerts
  FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE IF NOT EXISTS public.trip_alerts_2025
  PARTITION OF public.trip_alerts
  FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE IF NOT EXISTS public.trip_alerts_2026
  PARTITION OF public.trip_alerts
  FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

CREATE TABLE IF NOT EXISTS public.trip_events_2024
  PARTITION OF public.trip_events
  FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE IF NOT EXISTS public.trip_events_2025
  PARTITION OF public.trip_events
  FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE IF NOT EXISTS public.trip_events_2026
  PARTITION OF public.trip_events
  FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

CREATE TABLE IF NOT EXISTS public.device_idle_activity (
  idle_id        uuid NOT NULL,
  device_id      varchar NOT NULL,
  timestamp      timestamptz NOT NULL,
  lat            float8 NULL,
  lon            float8 NULL,
  activity_type  text NOT NULL,
  raw_code       int4 NULL,
  severity       int2 DEFAULT 1 NULL,
  metadata       jsonb NULL,
  correlation_id uuid NOT NULL,
  created_at     timestamptz DEFAULT now() NULL,
  CONSTRAINT device_idle_activity_pkey PRIMARY KEY (device_id, timestamp, idle_id)
);
CREATE INDEX IF NOT EXISTS device_idle_activity_timestamp_idx
  ON public.device_idle_activity (timestamp DESC);

-- ─────────────────────────────────────────────
-- ALERT RULES
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.alert_rules (
  id              uuid DEFAULT gen_random_uuid() NOT NULL,
  organization_id uuid NOT NULL,
  created_by      uuid NOT NULL,
  name            text NOT NULL,
  type            text NOT NULL,   -- 'ignition' | 'geofence'
  config          jsonb NOT NULL,
  is_active       boolean DEFAULT true NOT NULL,
  created_at      timestamptz DEFAULT now() NOT NULL,
  updated_at      timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT alert_rules_pkey PRIMARY KEY (id),
  CONSTRAINT fk_alert_rules_org  FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE,
  CONSTRAINT fk_alert_rules_user FOREIGN KEY (created_by)      REFERENCES public.users(id)         ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_alert_rules_org_active
  ON public.alert_rules (organization_id, is_active);

CREATE TABLE IF NOT EXISTS public.alert_rule_units (
  id         uuid DEFAULT gen_random_uuid() NOT NULL,
  rule_id    uuid NOT NULL,
  unit_id    uuid NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT alert_rule_units_pkey PRIMARY KEY (id),
  CONSTRAINT fk_rule_units_rule FOREIGN KEY (rule_id) REFERENCES public.alert_rules(id) ON DELETE CASCADE,
  CONSTRAINT fk_rule_units_unit FOREIGN KEY (unit_id) REFERENCES public.units(id)       ON DELETE CASCADE,
  CONSTRAINT uq_rule_unit UNIQUE (rule_id, unit_id)
);
CREATE INDEX IF NOT EXISTS idx_rule_units_unit ON public.alert_rule_units (unit_id);

CREATE TABLE IF NOT EXISTS public.alerts (
  id              uuid DEFAULT gen_random_uuid() NOT NULL,
  organization_id uuid NOT NULL,
  rule_id         uuid NULL,
  unit_id         uuid NOT NULL,
  event_id        uuid NULL,
  type            text NOT NULL,
  payload         jsonb,
  occurred_at     timestamptz NOT NULL,
  created_at      timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT alerts_pkey    PRIMARY KEY (id),
  CONSTRAINT fk_alerts_org  FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE,
  CONSTRAINT fk_alerts_rule FOREIGN KEY (rule_id)         REFERENCES public.alert_rules(id)  ON DELETE SET NULL,
  CONSTRAINT fk_alerts_unit FOREIGN KEY (unit_id)         REFERENCES public.units(id)        ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_alerts_org_unit_time
  ON public.alerts (organization_id, unit_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_org_time
  ON public.alerts (organization_id, occurred_at DESC);