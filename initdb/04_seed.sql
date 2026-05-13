-- ============================================================
-- 04_seed.sql — SISCOM Dev Seed (combinado v4 + telemetría)
--
-- IDs fijos:
--   ACCOUNT : 005ae820-7b64-44c5-b9b3-03490cb994a2
--   ORG     : 7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1
--   PM_ID   : ddcfd36c-9485-45e4-bd8f-6aa6571fae95
--
-- Incluye:
--   • Planes reales (test_micro → elite) con capabilities
--   • Cuenta/org/usuarios demo
--   • 6 meses de invoices + payments (5 SUCCESS + 1 FAILED)
--   • Dispositivos GPS, SIM cards, unidades y telemetría
--   • Reglas de alerta de ejemplo
-- ============================================================

BEGIN;

-- ─────────────────────────────────────────────
-- PRODUCTS
-- ─────────────────────────────────────────────

INSERT INTO public.products (code, name, description, is_active) VALUES
  ('nexus', 'NEXUS', 'Plataforma de rastreo GPS, telemetría y control de flotas', true),
  ('orion', 'Orion', 'API de servicios de localización para integraciones',        true)
ON CONFLICT (code) DO UPDATE
  SET name=EXCLUDED.name, description=EXCLUDED.description, is_active=EXCLUDED.is_active;

-- ─────────────────────────────────────────────
-- CAPABILITIES
-- ─────────────────────────────────────────────

INSERT INTO public.capabilities (code, description, value_type) VALUES
  ('max_devices',      'Número máximo de dispositivos GPS',              'int'),
  ('max_units',        'Número máximo de unidades / vehículos',          'int'),
  ('max_geofences',    'Número máximo de geocercas activas',             'int'),
  ('max_users',        'Número máximo de usuarios de la organización',   'int'),
  ('history_days',     'Días de historial de ubicaciones',               'int'),
  ('ai_features',      'Acceso a análisis con Inteligencia Artificial',  'bool'),
  ('analytics_tools',  'Herramientas avanzadas de analytics y reportes', 'bool'),
  ('custom_reports',   'Reportes personalizados y exportaciones',        'bool'),
  ('api_access',       'Acceso a la API de integración (Orion)',         'bool'),
  ('priority_support', 'Soporte prioritario 24/7',                       'bool'),
  ('real_time_alerts', 'Alertas en tiempo real',                         'bool'),
  ('export_data',      'Exportación de datos (CSV, XLSX, PDF)',          'bool')
ON CONFLICT (code) DO UPDATE
  SET description=EXCLUDED.description, value_type=EXCLUDED.value_type;

-- ─────────────────────────────────────────────
-- PLANES
-- ─────────────────────────────────────────────

INSERT INTO public.plans
  (code, name, description, price_monthly, price_yearly,
   max_devices, history_days, ai_features, analytics_tools, features, is_active)
VALUES
  ('test_micro', 'Micro Test',
   '[TEST] Plan mínimo para pruebas de integración Stripe.',
   1.00, 10.00, 1, 7, false, false,
   '{"highlighted":["1 dispositivo","7 días historial"],"is_popular":false,"test_only":true}',
   true),

  ('basic', 'TrackGo',
   'Ideal para flotas pequeñas. GPS esencial con alertas en tiempo real.',
   10.00, 100.00, 10, 30, false, false,
   '{"highlighted":["Hasta 10 dispositivos GPS","5 geocercas activas","30 días de historial","Alertas en tiempo real"],"is_popular":false}',
   true),

  ('fleetguard', 'FleetGuard',
   'Control completo de flotas medianas con geofencing avanzado y analytics.',
   20.00, 200.00, 50, 90, false, true,
   '{"highlighted":["Hasta 50 dispositivos GPS","20 geocercas activas","90 días de historial","Analytics avanzado","Exportación de datos","Alertas en tiempo real"],"is_popular":true}',
   true),

  ('enterprise', 'Nexus Core',
   'Solución completa con IA, API propia y soporte prioritario 24/7.',
   30.00, 300.00, 200, 365, true, true,
   '{"highlighted":["Hasta 200 dispositivos GPS","100 geocercas activas","365 días de historial","Funciones de IA","Reportes personalizados","Acceso API (Orion)","Soporte 24/7"],"is_popular":false}',
   true),

  ('elite', 'Nexus Elite',
   'Tier máximo. Dispositivos ilimitados, retención extendida y SLA garantizado.',
   50.00, 500.00, 500, 730, true, true,
   '{"highlighted":["Hasta 500 dispositivos GPS","Geocercas ilimitadas","2 años de historial","IA avanzada","API Orion ilimitada","SLA 99.9%","Soporte dedicado"],"is_popular":false}',
   true)

ON CONFLICT (code) DO UPDATE
  SET name=EXCLUDED.name, description=EXCLUDED.description,
      price_monthly=EXCLUDED.price_monthly, price_yearly=EXCLUDED.price_yearly,
      max_devices=EXCLUDED.max_devices, history_days=EXCLUDED.history_days,
      ai_features=EXCLUDED.ai_features, analytics_tools=EXCLUDED.analytics_tools,
      features=EXCLUDED.features, is_active=EXCLUDED.is_active, updated_at=now();

-- ─────────────────────────────────────────────
-- PLAN → PRODUCTS
-- ─────────────────────────────────────────────

INSERT INTO public.plan_products (plan_id, product_id)
SELECT p.id, pr.id FROM public.plans p CROSS JOIN public.products pr
WHERE p.code IN ('test_micro','basic','fleetguard','enterprise','elite') AND pr.code='nexus'
ON CONFLICT DO NOTHING;

INSERT INTO public.plan_products (plan_id, product_id)
SELECT p.id, pr.id FROM public.plans p CROSS JOIN public.products pr
WHERE p.code IN ('enterprise','elite') AND pr.code='orion'
ON CONFLICT DO NOTHING;

-- ─────────────────────────────────────────────
-- PLAN CAPABILITIES
-- ─────────────────────────────────────────────

DELETE FROM public.plan_capabilities
WHERE plan_id IN (
  SELECT id FROM public.plans
  WHERE code IN ('test_micro','basic','fleetguard','enterprise','elite')
);

INSERT INTO public.plan_capabilities (plan_id, capability_id, value_int, value_bool, value_text)
SELECT p.id, c.id,
  CASE c.code
    WHEN 'max_devices'   THEN CASE p.code WHEN 'test_micro' THEN 1 WHEN 'basic' THEN 10 WHEN 'fleetguard' THEN 50  WHEN 'enterprise' THEN 200 ELSE 500 END
    WHEN 'max_units'     THEN CASE p.code WHEN 'test_micro' THEN 1 WHEN 'basic' THEN 10 WHEN 'fleetguard' THEN 50  WHEN 'enterprise' THEN 200 ELSE 500 END
    WHEN 'max_geofences' THEN CASE p.code WHEN 'test_micro' THEN 1 WHEN 'basic' THEN 5  WHEN 'fleetguard' THEN 20  WHEN 'enterprise' THEN 100 ELSE 999 END
    WHEN 'max_users'     THEN CASE p.code WHEN 'test_micro' THEN 1 WHEN 'basic' THEN 3  WHEN 'fleetguard' THEN 10  WHEN 'enterprise' THEN 50  ELSE 200 END
    WHEN 'history_days'  THEN CASE p.code WHEN 'test_micro' THEN 7 WHEN 'basic' THEN 30 WHEN 'fleetguard' THEN 90  WHEN 'enterprise' THEN 365 ELSE 730 END
    ELSE NULL
  END,
  CASE c.code
    WHEN 'real_time_alerts' THEN true
    WHEN 'analytics_tools'  THEN p.code IN ('fleetguard','enterprise','elite')
    WHEN 'export_data'      THEN p.code IN ('fleetguard','enterprise','elite')
    WHEN 'ai_features'      THEN p.code IN ('enterprise','elite')
    WHEN 'custom_reports'   THEN p.code IN ('enterprise','elite')
    WHEN 'api_access'       THEN p.code IN ('enterprise','elite')
    WHEN 'priority_support' THEN p.code IN ('enterprise','elite')
    ELSE NULL
  END,
  NULL
FROM public.plans p CROSS JOIN public.capabilities c
WHERE p.code IN ('test_micro','basic','fleetguard','enterprise','elite');

-- ─────────────────────────────────────────────
-- ACCOUNT
-- ─────────────────────────────────────────────

INSERT INTO public.accounts (id, account_name, status, billing_email)
VALUES ('005ae820-7b64-44c5-b9b3-03490cb994a2', 'Geminis Labs', 'ACTIVE', 'alan@geminislabs.com')
ON CONFLICT (id) DO NOTHING;

-- ─────────────────────────────────────────────
-- SUSCRIPCIÓN (antes de org por FK circular)
-- ─────────────────────────────────────────────

-- Suscripción sin organization_id (aún no existe la org)
INSERT INTO public.subscriptions (
  id, plan_id, status, started_at, expires_at, auto_renew,
  billing_cycle, current_period_start, current_period_end, active_units
)
SELECT
  'bbbbbbbb-0000-0000-0000-000000000001',
  id, 'ACTIVE',
  date_trunc('month', now()),
  date_trunc('month', now()) + interval '1 month',
  true,
  'MONTHLY',
  date_trunc('month', now()),
  date_trunc('month', now()) + interval '1 month',
  3
FROM public.plans WHERE code = 'fleetguard'
ON CONFLICT (id) DO NOTHING;

-- ─────────────────────────────────────────────
-- ORGANIZACIÓN
-- ─────────────────────────────────────────────

INSERT INTO public.organizations (
  id, name, status, account_id, active_subscription_id,
  billing_email, country, timezone
)
VALUES (
  '7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1',
  'Geminis Labs S.A. de C.V.',
  'ACTIVE',
  '005ae820-7b64-44c5-b9b3-03490cb994a2',
  'bbbbbbbb-0000-0000-0000-000000000001',
  'facturacion@geminislabs.com',
  'MX',
  'America/Mexico_City'
)
ON CONFLICT (id) DO UPDATE
  SET active_subscription_id = EXCLUDED.active_subscription_id,
      updated_at = now();

-- Ahora sí enlazamos la org a la suscripción
UPDATE public.subscriptions
   SET organization_id = '7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1'
 WHERE id = 'bbbbbbbb-0000-0000-0000-000000000001'
   AND organization_id IS NULL;

-- ─────────────────────────────────────────────
-- USUARIOS
-- ─────────────────────────────────────────────

INSERT INTO public.users (id, email, full_name, is_master, email_verified, organization_id)
VALUES
  ('dddddddd-0000-0000-0000-000000000001', 'admin@geminislabs.com',    'Admin Demo',    true,  true, '7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1'),
  ('dddddddd-0000-0000-0000-000000000002', 'operador@geminislabs.com', 'Operador Demo', false, true, '7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.organization_users (organization_id, user_id, role)
VALUES
  ('7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1', 'dddddddd-0000-0000-0000-000000000001', 'owner'),
  ('7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1', 'dddddddd-0000-0000-0000-000000000002', 'member')
ON CONFLICT ON CONSTRAINT uq_org_user DO NOTHING;

-- ─────────────────────────────────────────────
-- PAYMENT GATEWAY CUSTOMER + METHOD
-- ─────────────────────────────────────────────

INSERT INTO public.payment_gateway_customers (id, account_id, gateway, external_customer_id)
VALUES ('b0000001-0000-0000-0000-000000000001',
        '005ae820-7b64-44c5-b9b3-03490cb994a2', 'stripe', 'cus_seed_alan_test')
ON CONFLICT (account_id, gateway) DO NOTHING;

INSERT INTO public.payment_methods
  (id, account_id, gateway, method_type, external_token, brand, last4, exp_month, exp_year, is_default, is_active)
VALUES ('ddcfd36c-9485-45e4-bd8f-6aa6571fae95',
        '005ae820-7b64-44c5-b9b3-03490cb994a2',
        'stripe', 'card', 'pm_seed_visa_4242', 'visa', '4242', 12, 2027, true, true)
ON CONFLICT (gateway, external_token) DO NOTHING;

-- ─────────────────────────────────────────────
-- INVOICES + PAYMENTS (6 registros: 5 SUCCESS + 1 FAILED)
-- ─────────────────────────────────────────────

-- MES -5: $10 SUCCESS
INSERT INTO public.invoices (id,account_id,organization_id,invoice_number,invoice_status,subtotal,discount_amount,tax_amount,total_amount,currency,paid_at,created_at,updated_at)
VALUES ('c0000001-0000-0000-0000-000000000001','005ae820-7b64-44c5-b9b3-03490cb994a2','7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1',
        'INV-2026-0001','PAID',10.00,0.00,0.00,10.00,'MXN',
        date_trunc('month',now())-interval'5 months'+interval'3 days',
        date_trunc('month',now())-interval'5 months'+interval'3 days',now())
ON CONFLICT (invoice_number) DO NOTHING;
INSERT INTO public.payments (id,invoice_id,account_id,organization_id,gateway,gateway_payment_id,idempotency_key,payment_method_type,payment_method_id,payment_method_meta,amount,currency,refunded_amount,payment_status,succeeded_at,created_at,updated_at)
VALUES ('d0000001-0000-0000-0000-000000000001','c0000001-0000-0000-0000-000000000001',
        '005ae820-7b64-44c5-b9b3-03490cb994a2','7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1',
        'stripe','pi_seed_m5','seed_m5_ok','card','ddcfd36c-9485-45e4-bd8f-6aa6571fae95','{}',
        10.00,'MXN',0.00,'SUCCESS',
        date_trunc('month',now())-interval'5 months'+interval'3 days',
        date_trunc('month',now())-interval'5 months'+interval'3 days',now())
ON CONFLICT (id) DO NOTHING;

-- MES -4: $15 SUCCESS
INSERT INTO public.invoices (id,account_id,organization_id,invoice_number,invoice_status,subtotal,discount_amount,tax_amount,total_amount,currency,paid_at,created_at,updated_at)
VALUES ('c0000001-0000-0000-0000-000000000002','005ae820-7b64-44c5-b9b3-03490cb994a2','7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1',
        'INV-2026-0002','PAID',15.00,0.00,0.00,15.00,'MXN',
        date_trunc('month',now())-interval'4 months'+interval'2 days',
        date_trunc('month',now())-interval'4 months'+interval'2 days',now())
ON CONFLICT (invoice_number) DO NOTHING;
INSERT INTO public.payments (id,invoice_id,account_id,organization_id,gateway,gateway_payment_id,idempotency_key,payment_method_type,payment_method_id,payment_method_meta,amount,currency,refunded_amount,payment_status,succeeded_at,created_at,updated_at)
VALUES ('d0000001-0000-0000-0000-000000000002','c0000001-0000-0000-0000-000000000002',
        '005ae820-7b64-44c5-b9b3-03490cb994a2','7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1',
        'stripe','pi_seed_m4','seed_m4_ok','card','ddcfd36c-9485-45e4-bd8f-6aa6571fae95','{}',
        15.00,'MXN',0.00,'SUCCESS',
        date_trunc('month',now())-interval'4 months'+interval'2 days',
        date_trunc('month',now())-interval'4 months'+interval'2 days',now())
ON CONFLICT (id) DO NOTHING;

-- MES -3: $20 FAILED (invoice queda OPEN)
INSERT INTO public.invoices (id,account_id,organization_id,invoice_number,invoice_status,subtotal,discount_amount,tax_amount,total_amount,currency,created_at,updated_at)
VALUES ('c0000001-0000-0000-0000-000000000003','005ae820-7b64-44c5-b9b3-03490cb994a2','7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1',
        'INV-2026-0003','OPEN',20.00,0.00,0.00,20.00,'MXN',
        date_trunc('month',now())-interval'3 months'+interval'1 day',now())
ON CONFLICT (invoice_number) DO NOTHING;
INSERT INTO public.payments (id,invoice_id,account_id,organization_id,gateway,gateway_payment_id,idempotency_key,payment_method_type,payment_method_id,payment_method_meta,amount,currency,refunded_amount,payment_status,failed_at,failure_code,failure_message,created_at,updated_at)
VALUES ('d0000001-0000-0000-0000-000000000003','c0000001-0000-0000-0000-000000000003',
        '005ae820-7b64-44c5-b9b3-03490cb994a2','7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1',
        'stripe','pi_seed_m3_fail','seed_m3_fail','card','ddcfd36c-9485-45e4-bd8f-6aa6571fae95','{}',
        20.00,'MXN',0.00,'FAILED',
        date_trunc('month',now())-interval'3 months'+interval'1 day',
        'insufficient_funds','Your card has insufficient funds.',
        date_trunc('month',now())-interval'3 months'+interval'1 day',now())
ON CONFLICT (id) DO NOTHING;

-- MES -3: $20 SUCCESS (reintento con nueva invoice)
INSERT INTO public.invoices (id,account_id,organization_id,invoice_number,invoice_status,subtotal,discount_amount,tax_amount,total_amount,currency,paid_at,created_at,updated_at)
VALUES ('c0000001-0000-0000-0000-000000000004','005ae820-7b64-44c5-b9b3-03490cb994a2','7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1',
        'INV-2026-0004','PAID',20.00,0.00,0.00,20.00,'MXN',
        date_trunc('month',now())-interval'3 months'+interval'4 days',
        date_trunc('month',now())-interval'3 months'+interval'4 days',now())
ON CONFLICT (invoice_number) DO NOTHING;
INSERT INTO public.payments (id,invoice_id,account_id,organization_id,gateway,gateway_payment_id,idempotency_key,payment_method_type,payment_method_id,payment_method_meta,amount,currency,refunded_amount,payment_status,succeeded_at,created_at,updated_at)
VALUES ('d0000001-0000-0000-0000-000000000004','c0000001-0000-0000-0000-000000000004',
        '005ae820-7b64-44c5-b9b3-03490cb994a2','7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1',
        'stripe','pi_seed_m3','seed_m3_ok','card','ddcfd36c-9485-45e4-bd8f-6aa6571fae95','{}',
        20.00,'MXN',0.00,'SUCCESS',
        date_trunc('month',now())-interval'3 months'+interval'4 days',
        date_trunc('month',now())-interval'3 months'+interval'4 days',now())
ON CONFLICT (id) DO NOTHING;

-- MES -2: $25 SUCCESS
INSERT INTO public.invoices (id,account_id,organization_id,invoice_number,invoice_status,subtotal,discount_amount,tax_amount,total_amount,currency,paid_at,created_at,updated_at)
VALUES ('c0000001-0000-0000-0000-000000000005','005ae820-7b64-44c5-b9b3-03490cb994a2','7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1',
        'INV-2026-0005','PAID',25.00,0.00,0.00,25.00,'MXN',
        date_trunc('month',now())-interval'2 months'+interval'2 days',
        date_trunc('month',now())-interval'2 months'+interval'2 days',now())
ON CONFLICT (invoice_number) DO NOTHING;
INSERT INTO public.payments (id,invoice_id,account_id,organization_id,gateway,gateway_payment_id,idempotency_key,payment_method_type,payment_method_id,payment_method_meta,amount,currency,refunded_amount,payment_status,succeeded_at,created_at,updated_at)
VALUES ('d0000001-0000-0000-0000-000000000005','c0000001-0000-0000-0000-000000000005',
        '005ae820-7b64-44c5-b9b3-03490cb994a2','7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1',
        'stripe','pi_seed_m2','seed_m2_ok','card','ddcfd36c-9485-45e4-bd8f-6aa6571fae95','{}',
        25.00,'MXN',0.00,'SUCCESS',
        date_trunc('month',now())-interval'2 months'+interval'2 days',
        date_trunc('month',now())-interval'2 months'+interval'2 days',now())
ON CONFLICT (id) DO NOTHING;

-- MES -1: $30 SUCCESS
INSERT INTO public.invoices (id,account_id,organization_id,invoice_number,invoice_status,subtotal,discount_amount,tax_amount,total_amount,currency,paid_at,created_at,updated_at)
VALUES ('c0000001-0000-0000-0000-000000000006','005ae820-7b64-44c5-b9b3-03490cb994a2','7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1',
        'INV-2026-0006','PAID',30.00,0.00,0.00,30.00,'MXN',
        date_trunc('month',now())-interval'1 month'+interval'1 day',
        date_trunc('month',now())-interval'1 month'+interval'1 day',now())
ON CONFLICT (invoice_number) DO NOTHING;
INSERT INTO public.payments (id,invoice_id,account_id,organization_id,gateway,gateway_payment_id,idempotency_key,payment_method_type,payment_method_id,payment_method_meta,amount,currency,refunded_amount,payment_status,succeeded_at,created_at,updated_at)
VALUES ('d0000001-0000-0000-0000-000000000006','c0000001-0000-0000-0000-000000000006',
        '005ae820-7b64-44c5-b9b3-03490cb994a2','7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1',
        'stripe','pi_seed_m1','seed_m1_ok','card','ddcfd36c-9485-45e4-bd8f-6aa6571fae95','{}',
        30.00,'MXN',0.00,'SUCCESS',
        date_trunc('month',now())-interval'1 month'+interval'1 day',
        date_trunc('month',now())-interval'1 month'+interval'1 day',now())
ON CONFLICT (id) DO NOTHING;

-- ─────────────────────────────────────────────
-- DISPOSITIVOS GPS
-- ─────────────────────────────────────────────

INSERT INTO public.devices (device_id, brand, model, firmware_version, status, organization_id)
VALUES
  ('SUNTECH-001', 'Suntech',  'ST4900', '1.0.6', 'asignado',  '7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1'),
  ('SUNTECH-002', 'Suntech',  'ST4900', '1.0.6', 'asignado',  '7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1'),
  ('QUEC-001',    'Queclink', 'GV300W', '3.2.1', 'asignado',  '7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1'),
  ('QUEC-002',    'Queclink', 'GV300W', '3.2.1', 'preparado', '7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1')
ON CONFLICT (device_id) DO NOTHING;

INSERT INTO public.sim_cards (device_id, carrier, iccid, msisdn, status)
SELECT v.device_id, v.carrier, v.iccid, v.msisdn, v.status
FROM (VALUES
  ('SUNTECH-001', 'KORE', '8952140060100012341', '5215512340001', 'active'),
  ('SUNTECH-002', 'KORE', '8952140060100012342', '5215512340002', 'active'),
  ('QUEC-001',    'KORE', '8952140060100012343', '5215512340003', 'active')
) AS v(device_id, carrier, iccid, msisdn, status)
WHERE NOT EXISTS (
  SELECT 1 FROM public.sim_cards s WHERE s.device_id = v.device_id
);

-- ─────────────────────────────────────────────
-- UNIDADES (vehículos)
-- ─────────────────────────────────────────────

INSERT INTO public.units (id, name, description, organization_id)
VALUES
  ('eeeeeeee-0000-0000-0000-000000000001', 'Unidad 01 - Camioneta',   'Ford F-150 blanca',   '7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1'),
  ('eeeeeeee-0000-0000-0000-000000000002', 'Unidad 02 - Sedan',       'Toyota Corolla gris', '7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1'),
  ('eeeeeeee-0000-0000-0000-000000000003', 'Unidad 03 - Camión 3.5T', 'Isuzu NPR rojo',      '7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.unit_profile (unit_id, unit_type, brand, model, color, year, icon_type)
VALUES
  ('eeeeeeee-0000-0000-0000-000000000001', 'car',   'Ford',   'F-150',   'blanco', 2022, 'truck'),
  ('eeeeeeee-0000-0000-0000-000000000002', 'car',   'Toyota', 'Corolla', 'gris',   2021, 'car'),
  ('eeeeeeee-0000-0000-0000-000000000003', 'truck', 'Isuzu',  'NPR',     'rojo',   2020, 'delivery')
ON CONFLICT (unit_id) DO NOTHING;

INSERT INTO public.vehicle_profile (unit_id, plate, fuel_type, passengers)
VALUES
  ('eeeeeeee-0000-0000-0000-000000000001', 'AAA-00-01', 'gasolina', 5),
  ('eeeeeeee-0000-0000-0000-000000000002', 'BBB-00-02', 'gasolina', 5),
  ('eeeeeeee-0000-0000-0000-000000000003', 'CCC-00-03', 'diesel',   2)
ON CONFLICT (unit_id) DO NOTHING;

INSERT INTO public.unit_devices (unit_id, device_id)
VALUES
  ('eeeeeeee-0000-0000-0000-000000000001', 'SUNTECH-001'),
  ('eeeeeeee-0000-0000-0000-000000000002', 'SUNTECH-002'),
  ('eeeeeeee-0000-0000-0000-000000000003', 'QUEC-001')
ON CONFLICT ON CONSTRAINT uq_unit_devices_unit_device DO NOTHING;

INSERT INTO public.user_units (user_id, unit_id, role)
VALUES
  ('dddddddd-0000-0000-0000-000000000001', 'eeeeeeee-0000-0000-0000-000000000001', 'admin'),
  ('dddddddd-0000-0000-0000-000000000001', 'eeeeeeee-0000-0000-0000-000000000002', 'admin'),
  ('dddddddd-0000-0000-0000-000000000001', 'eeeeeeee-0000-0000-0000-000000000003', 'admin'),
  ('dddddddd-0000-0000-0000-000000000002', 'eeeeeeee-0000-0000-0000-000000000001', 'viewer'),
  ('dddddddd-0000-0000-0000-000000000002', 'eeeeeeee-0000-0000-0000-000000000002', 'viewer')
ON CONFLICT ON CONSTRAINT uq_user_units_user_unit DO NOTHING;

-- ─────────────────────────────────────────────
-- TELEMETRÍA (estado actual GPS)
-- Coordenadas: Guadalajara, Jalisco
-- ─────────────────────────────────────────────

INSERT INTO public.communications_current_state (
  device_id, uuid, latitude, longitude, speed, course,
  engine_status, fix_status, gps_datetime, msg_class, satellites, odometer
)
VALUES
  ('SUNTECH-001', gen_random_uuid()::text, 20.6736, -103.3445, 45.5,  92.0, 'ON',  '1', now() - interval '2 minutes', 'STT', 12, 1248300),
  ('SUNTECH-002', gen_random_uuid()::text, 20.6810, -103.3500,  0.0,   0.0, 'OFF', '1', now() - interval '5 minutes', 'STT', 11,  985100),
  ('QUEC-001',    gen_random_uuid()::text, 20.6690, -103.3390, 62.0, 180.0, 'ON',  '1', now() - interval '1 minute',  'STT', 14, 2104700)
ON CONFLICT (device_id, msg_class) DO UPDATE SET
  latitude      = EXCLUDED.latitude,
  longitude     = EXCLUDED.longitude,
  speed         = EXCLUDED.speed,
  engine_status = EXCLUDED.engine_status,
  gps_datetime  = EXCLUDED.gps_datetime;

-- ─────────────────────────────────────────────
-- REGLA DE ALERTA
-- ─────────────────────────────────────────────

INSERT INTO public.alert_rules (id, organization_id, created_by, name, type, config, is_active)
VALUES (
  'ffffffff-0000-0000-0000-000000000001',
  '7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1',
  'dddddddd-0000-0000-0000-000000000001',
  'Exceso de velocidad > 100 km/h',
  'overspeed',
  '{"threshold_kmh": 100, "notify": ["email", "push"], "cooldown_minutes": 15}'::jsonb,
  true
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.alert_rule_units (rule_id, unit_id)
VALUES
  ('ffffffff-0000-0000-0000-000000000001', 'eeeeeeee-0000-0000-0000-000000000001'),
  ('ffffffff-0000-0000-0000-000000000001', 'eeeeeeee-0000-0000-0000-000000000002'),
  ('ffffffff-0000-0000-0000-000000000001', 'eeeeeeee-0000-0000-0000-000000000003')
ON CONFLICT ON CONSTRAINT uq_rule_unit DO NOTHING;

-- ─────────────────────────────────────────────
-- VERIFICACIÓN
-- ─────────────────────────────────────────────

SELECT '═══ PLANES ═══' AS info, code, name,
       price_monthly::text || '/' || price_yearly::text || ' MXN' AS precios
FROM public.plans WHERE is_active = true ORDER BY price_monthly;

SELECT '═══ SUSCRIPCIÓN ═══' AS info, s.status, p.name AS plan,
       s.billing_cycle, to_char(s.expires_at, 'YYYY-MM-DD') AS vence
FROM public.subscriptions s
JOIN public.plans p ON p.id = s.plan_id
WHERE s.organization_id = '7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1';

SELECT '═══ PAYMENT METHOD ═══' AS info,
       gateway, method_type, brand, last4, is_default
FROM public.payment_methods
WHERE account_id = '005ae820-7b64-44c5-b9b3-03490cb994a2';

SELECT '═══ INVOICES ═══' AS info, invoice_number, invoice_status,
       total_amount::text || ' MXN' AS total,
       to_char(paid_at, 'YYYY-MM-DD') AS pagada
FROM public.invoices
WHERE account_id = '005ae820-7b64-44c5-b9b3-03490cb994a2'
ORDER BY created_at;

SELECT '═══ PAYMENTS ═══' AS info, payment_status,
       amount::text || ' MXN' AS monto,
       to_char(succeeded_at, 'YYYY-MM-DD') AS exitoso, failure_code
FROM public.payments
WHERE account_id = '005ae820-7b64-44c5-b9b3-03490cb994a2'
ORDER BY created_at;

SELECT '═══ DISPOSITIVOS ═══' AS info, device_id, brand, model, status
FROM public.devices
WHERE organization_id = '7909f2bc-3bb4-42de-a1a3-1a5a64b4c1b1';

SELECT '═══ TELEMETRÍA ═══' AS info, device_id, engine_status,
       speed::text || ' km/h' AS velocidad,
       to_char(gps_datetime, 'HH24:MI:SS') AS ultima_posicion
FROM public.communications_current_state
WHERE device_id IN ('SUNTECH-001','SUNTECH-002','QUEC-001');

COMMIT;