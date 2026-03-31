CREATE TYPE public.event_type_enum AS ENUM (
    'HARSH_ACCEL',
    'HARSH_BRKE',
    'OVERSPEED_START',
    'OVERSPEED_END',
    'IDLE_START',
    'IDLE_END',
    'JAMMING',
    'DISCONNECT',
    'CUSTOM'
);


-- public.accounts definition

-- Drop table

-- DROP TABLE public.accounts;

CREATE TABLE public.accounts (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	account_name text NOT NULL,
	status text DEFAULT 'ACTIVE'::text NOT NULL,
	billing_email text NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	updated_at timestamptz DEFAULT now() NOT NULL,
	CONSTRAINT accounts_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX uq_accounts_billing_email ON public.accounts USING btree (billing_email) WHERE (billing_email IS NOT NULL);


-- public.capabilities definition

-- Drop table

-- DROP TABLE public.capabilities;

CREATE TABLE public.capabilities (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	code text NOT NULL,
	description text NOT NULL,
	value_type text NOT NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	CONSTRAINT capabilities_code_key UNIQUE (code),
	CONSTRAINT capabilities_pkey PRIMARY KEY (id),
	CONSTRAINT capabilities_value_type_check CHECK ((value_type = ANY (ARRAY['int'::text, 'bool'::text, 'text'::text])))
);


-- public.command_templates definition

-- Drop table

-- DROP TABLE public.command_templates;

CREATE TABLE public.command_templates (
	template_id uuid DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	payload text NOT NULL,
	description text NULL,
	created_at timestamptz DEFAULT now() NULL,
	CONSTRAINT command_templates_pkey PRIMARY KEY (template_id)
);


-- public.communications_current_state definition

-- Drop table

-- DROP TABLE public.communications_current_state;

CREATE TABLE public.communications_current_state (
	device_id varchar(100) NOT NULL,
	"uuid" varchar(255) NOT NULL,
	backup_battery_voltage numeric(5, 2) NULL,
	cell_id varchar(50) NULL,
	course numeric(6, 2) NULL,
	delivery_type varchar(20) NULL,
	engine_status varchar(10) NULL,
	firmware varchar(20) NULL,
	fix_status varchar(5) NULL,
	gps_datetime timestamp NULL,
	gps_epoch int8 NULL,
	idle_time int4 NULL,
	lac varchar(10) NULL,
	latitude numeric(10, 8) NULL,
	longitude numeric(11, 8) NULL,
	main_battery_voltage numeric(5, 2) NULL,
	mcc varchar(10) NULL,
	mnc varchar(10) NULL,
	model varchar(10) NULL,
	msg_class varchar(20) NOT NULL,
	msg_counter varchar NULL,
	network_status varchar(50) NULL,
	odometer int8 NULL,
	rx_lvl int4 NULL,
	satellites int4 NULL,
	speed numeric(8, 2) NULL,
	speed_time int4 NULL,
	total_distance int8 NULL,
	trip_distance int8 NULL,
	trip_hourmeter int4 NULL,
	bytes_count int4 NULL,
	client_ip text NULL,
	client_port int4 NULL,
	decoded_epoch int8 NULL,
	received_epoch int8 NULL,
	raw_message text NULL,
	received_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	alert_type varchar NULL,
	backup_battery_percent numeric NULL,
	CONSTRAINT communications_current_state_pkey PRIMARY KEY (device_id, msg_class),
	CONSTRAINT communications_current_state_uuid_key UNIQUE (uuid)
);
CREATE INDEX idx_comm_current_decoded_epoch ON public.communications_current_state USING btree (decoded_epoch DESC);
CREATE INDEX idx_comm_current_gps_datetime ON public.communications_current_state USING btree (gps_datetime DESC);


-- public.communications_queclink definition

-- Drop table

-- DROP TABLE public.communications_queclink;

CREATE TABLE public.communications_queclink (
	id bigserial NOT NULL,
	"uuid" varchar(255) NOT NULL,
	device_id varchar(100) NOT NULL,
	backup_battery_voltage numeric(5, 2) NULL,
	cell_id varchar(50) NULL,
	course numeric(6, 2) NULL,
	delivery_type varchar(20) NULL,
	engine_status varchar(10) NULL,
	firmware varchar(20) NULL,
	fix_status varchar(5) NULL,
	gps_datetime timestamp NULL,
	gps_epoch int8 NULL,
	idle_time int4 NULL,
	lac varchar(10) NULL,
	latitude numeric(10, 8) NULL,
	longitude numeric(11, 8) NULL,
	main_battery_voltage numeric(5, 2) NULL,
	mcc varchar(10) NULL,
	mnc varchar(10) NULL,
	model varchar(10) NULL,
	msg_class varchar(20) NULL,
	msg_counter varchar NULL,
	network_status varchar(50) NULL,
	odometer int8 NULL,
	rx_lvl int4 NULL,
	satellites int4 NULL,
	speed numeric(8, 2) NULL,
	speed_time int4 NULL,
	total_distance int8 NULL,
	trip_distance int8 NULL,
	trip_hourmeter int4 NULL,
	bytes_count int4 NULL,
	client_ip text NULL,
	client_port int4 NULL,
	decoded_epoch int8 NULL,
	received_epoch int8 NULL,
	raw_message text NULL,
	received_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	alert_type varchar NULL,
	backup_battery_percent numeric NULL,
	CONSTRAINT communications_queclink_pkey PRIMARY KEY (id),
	CONSTRAINT communications_queclink_uuid_key UNIQUE (uuid)
);
CREATE INDEX idx_comm_created_at_q ON public.communications_queclink USING btree (created_at DESC);
CREATE INDEX idx_comm_decoded_epoch_q ON public.communications_queclink USING btree (decoded_epoch DESC);
CREATE INDEX idx_comm_device_created_q ON public.communications_queclink USING btree (device_id, created_at DESC);
CREATE INDEX idx_comm_device_id_q ON public.communications_queclink USING btree (device_id);
CREATE INDEX idx_comm_gps_datetime_q ON public.communications_queclink USING btree (gps_datetime DESC);
CREATE INDEX idx_comm_msg_class_q ON public.communications_queclink USING btree (msg_class);
CREATE INDEX idx_comm_received_at_q ON public.communications_queclink USING btree (received_at DESC);
CREATE INDEX idx_comm_uuid_q ON public.communications_queclink USING btree (uuid);


-- public.communications_suntech definition

-- Drop table

-- DROP TABLE public.communications_suntech;

CREATE TABLE public.communications_suntech (
	id bigserial NOT NULL,
	"uuid" varchar(255) NOT NULL,
	device_id varchar(100) NOT NULL,
	backup_battery_voltage numeric(5, 2) NULL,
	cell_id varchar(50) NULL,
	course numeric(6, 2) NULL,
	delivery_type varchar(20) NULL,
	engine_status varchar(10) NULL,
	firmware varchar(20) NULL,
	fix_status varchar(5) NULL,
	gps_datetime timestamp NULL,
	gps_epoch int8 NULL,
	idle_time int4 NULL,
	lac varchar(10) NULL,
	latitude numeric(10, 8) NULL,
	longitude numeric(11, 8) NULL,
	main_battery_voltage numeric(5, 2) NULL,
	mcc varchar(10) NULL,
	mnc varchar(10) NULL,
	model varchar(10) NULL,
	msg_class varchar(20) NULL,
	msg_counter varchar NULL,
	network_status varchar(50) NULL,
	odometer int8 NULL,
	rx_lvl int4 NULL,
	satellites int4 NULL,
	speed numeric(8, 2) NULL,
	speed_time int4 NULL,
	total_distance int8 NULL,
	trip_distance int8 NULL,
	trip_hourmeter int4 NULL,
	bytes_count int4 NULL,
	client_ip text NULL,
	client_port int4 NULL,
	decoded_epoch int8 NULL,
	received_epoch int8 NULL,
	raw_message text NULL,
	received_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	alert_type varchar NULL,
	backup_battery_percent numeric NULL,
	CONSTRAINT communications_suntech_pkey PRIMARY KEY (id),
	CONSTRAINT communications_suntech_uuid_key UNIQUE (uuid)
);
CREATE INDEX idx_comm_created_at ON public.communications_suntech USING btree (created_at DESC);
CREATE INDEX idx_comm_decoded_epoch ON public.communications_suntech USING btree (decoded_epoch DESC);
CREATE INDEX idx_comm_device_created ON public.communications_suntech USING btree (device_id, created_at DESC);
CREATE INDEX idx_comm_device_id ON public.communications_suntech USING btree (device_id);
CREATE INDEX idx_comm_gps_datetime ON public.communications_suntech USING btree (gps_datetime DESC);
CREATE INDEX idx_comm_msg_class ON public.communications_suntech USING btree (msg_class);
CREATE INDEX idx_comm_received_at ON public.communications_suntech USING btree (received_at DESC);
CREATE INDEX idx_comm_uuid ON public.communications_suntech USING btree (uuid);


-- public.device_idle_activity definition

-- Drop table

-- DROP TABLE public.device_idle_activity;

CREATE TABLE public.device_idle_activity (
	idle_id uuid NOT NULL,
	device_id varchar NOT NULL,
	"timestamp" timestamptz NOT NULL,
	lat float8 NULL,
	lon float8 NULL,
	activity_type text NOT NULL,
	raw_code int4 NULL,
	severity int2 DEFAULT 1 NULL,
	metadata jsonb NULL,
	correlation_id uuid NOT NULL,
	created_at timestamptz DEFAULT now() NULL,
	CONSTRAINT device_idle_activity_pkey PRIMARY KEY (device_id, "timestamp", idle_id)
);
CREATE INDEX device_idle_activity_timestamp_idx ON public.device_idle_activity USING btree ("timestamp" DESC);



-- public.payments definition

-- Drop table

-- DROP TABLE public.payments;

CREATE TABLE public.payments (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	amount numeric(10, 2) NOT NULL,
	currency text DEFAULT 'MXN'::text NULL,
	"method" text NULL,
	paid_at timestamp DEFAULT now() NULL,
	status text NOT NULL,
	transaction_ref text NULL,
	invoice_url text NULL,
	created_at timestamp DEFAULT now() NULL,
	account_id uuid NULL,
	CONSTRAINT payments_pkey PRIMARY KEY (id),
	CONSTRAINT payments_status_check CHECK ((status = ANY (ARRAY['SUCCESS'::text, 'FAILED'::text, 'REFUNDED'::text, 'PENDING'::text])))
);
CREATE INDEX idx_payments_account_id ON public.payments USING btree (account_id);
CREATE INDEX idx_payments_status ON public.payments USING btree (status);


-- public."plans" definition

-- Drop table

-- DROP TABLE public."plans";

CREATE TABLE public."plans" (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	description text NULL,
	price_monthly numeric(10, 2) DEFAULT 0 NOT NULL,
	price_yearly numeric(10, 2) DEFAULT 0 NOT NULL,
	max_devices int4 DEFAULT 1 NOT NULL,
	history_days int4 DEFAULT 7 NOT NULL,
	ai_features bool DEFAULT false NULL,
	analytics_tools bool DEFAULT false NULL,
	features jsonb DEFAULT '{}'::jsonb NULL,
	created_at timestamp DEFAULT now() NULL,
	updated_at timestamp DEFAULT now() NULL,
	code text NULL,
	is_active bool DEFAULT true NOT NULL,
	CONSTRAINT plans_name_key UNIQUE (name),
	CONSTRAINT plans_pkey PRIMARY KEY (id),
	CONSTRAINT plans_unique UNIQUE (code)
);


-- public.products definition

-- Drop table

-- DROP TABLE public.products;

CREATE TABLE public.products (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	code text NOT NULL,
	"name" text NOT NULL,
	description text NULL,
	is_active bool DEFAULT true NULL,
	created_at timestamptz DEFAULT now() NULL,
	CONSTRAINT products_code_key UNIQUE (code),
	CONSTRAINT products_pkey PRIMARY KEY (id)
);


-- public.tokens definition

-- Drop table

-- DROP TABLE public.tokens;

CREATE TABLE public.tokens (
	id uuid NOT NULL,
	"token" varchar NULL,
	revocado bool NULL,
	user_id varchar NULL,
	CONSTRAINT tokens_pkey PRIMARY KEY (id)
);


-- public.trip_alerts definition

-- Drop table

-- DROP TABLE public.trip_alerts;

CREATE TABLE public.trip_alerts (
	alert_id uuid NOT NULL,
	trip_id uuid NOT NULL,
	"timestamp" timestamptz NOT NULL,
	lat float8 NULL,
	lon float8 NULL,
	alert_type text NOT NULL,
	raw_code int4 NULL,
	severity int2 DEFAULT 1 NULL,
	metadata jsonb NULL,
	created_at timestamptz DEFAULT now() NULL,
	device_id varchar NOT NULL,
	correlation_id uuid NULL
)
PARTITION BY RANGE ("timestamp");
CREATE INDEX idx_trip_alert_device ON ONLY public.trip_alerts USING btree (device_id);
CREATE INDEX idx_trip_alert_trip ON ONLY public.trip_alerts USING btree (trip_id);
CREATE UNIQUE INDEX idx_trip_alerts_corr_unique ON ONLY public.trip_alerts USING btree (device_id, correlation_id, "timestamp");
CREATE INDEX idx_trip_alerts_device_time ON ONLY public.trip_alerts USING btree (device_id, "timestamp" DESC);
CREATE INDEX idx_trip_alerts_type ON ONLY public.trip_alerts USING btree (alert_type);


-- public.trip_current_state definition

-- Drop table

-- DROP TABLE public.trip_current_state;

CREATE TABLE public.trip_current_state (
	device_id varchar NOT NULL,
	current_trip_id uuid NULL,
	ignition_on bool DEFAULT false NOT NULL,
	last_point_at timestamptz NULL,
	last_lat float8 NULL,
	last_lng float8 NULL,
	last_speed float8 NULL,
	last_correlation_id uuid NULL,
	last_updated_at timestamptz DEFAULT now() NOT NULL,
	last_odometer_meters int4 NULL,
	CONSTRAINT trip_current_state_pkey PRIMARY KEY (device_id)
);


-- public.trip_events definition

-- Drop table

-- DROP TABLE public.trip_events;

CREATE TABLE public.trip_events (
	event_id uuid NOT NULL,
	trip_id uuid NOT NULL,
	"timestamp" timestamptz NOT NULL,
	lat float8 NULL,
	lon float8 NULL,
	event_type public.event_type_enum NOT NULL,
	"source" varchar(30) DEFAULT 'platform'::character varying NULL,
	rule_id uuid NULL,
	metadata jsonb NULL,
	created_at timestamptz DEFAULT now() NULL,
	device_id varchar NOT NULL
)
PARTITION BY RANGE ("timestamp");
CREATE INDEX idx_trip_events_device_time ON ONLY public.trip_events USING btree (device_id, "timestamp" DESC);


-- public.trip_points definition

-- Drop table

-- DROP TABLE public.trip_points;

CREATE TABLE public.trip_points (
	point_id bigserial NOT NULL,
	trip_id uuid NOT NULL,
	device_id varchar NOT NULL,
	"timestamp" timestamptz NOT NULL,
	lat float8 NOT NULL,
	lng float8 NOT NULL,
	speed float8 NULL,
	heading float8 NULL,
	correlation_id uuid NOT NULL,
	odometer_meters int4 NULL,
	CONSTRAINT trip_points_pkey PRIMARY KEY (device_id, "timestamp", correlation_id)
);
CREATE UNIQUE INDEX idx_trip_points_corr_unique ON public.trip_points USING btree (device_id, correlation_id, "timestamp");
CREATE INDEX idx_trip_points_device_time ON public.trip_points USING btree (device_id, "timestamp" DESC);
CREATE INDEX idx_trip_points_time ON public.trip_points USING btree ("timestamp" DESC);


-- public.trips definition

-- Drop table

-- DROP TABLE public.trips;

CREATE TABLE public.trips (
	trip_id uuid NOT NULL,
	device_id varchar(20) NOT NULL,
	start_time timestamptz NOT NULL,
	end_time timestamptz NULL,
	start_lat float8 NULL,
	start_lng float8 NULL,
	end_lat float8 NULL,
	end_lng float8 NULL,
	distance_meters int4 NULL,
	created_at timestamptz DEFAULT now() NULL,
	start_odometer_meters int4 NULL,
	end_odometer_meters int4 NULL,
	CONSTRAINT trips_pkey PRIMARY KEY (trip_id)
);
CREATE INDEX idx_trips_device_start ON public.trips USING btree (device_id, start_time);
CREATE INDEX idx_trips_start_ts ON public.trips USING btree (start_time);


-- public.units definition

-- Drop table

-- DROP TABLE public.units;

CREATE TABLE public.units (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	description text NULL,
	deleted_at timestamptz NULL,
	organization_id uuid NULL,
	CONSTRAINT units_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_units_deleted_at ON public.units USING btree (deleted_at) WHERE (deleted_at IS NULL);
CREATE INDEX idx_units_organization_id ON public.units USING btree (organization_id);


-- public.users definition

-- Drop table

-- DROP TABLE public.users;

CREATE TABLE public.users (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	cognito_sub text NULL,
	email text NOT NULL,
	full_name text NULL,
	is_master bool DEFAULT false NULL,
	last_login_at timestamp NULL,
	created_at timestamp DEFAULT now() NULL,
	updated_at timestamp DEFAULT now() NULL,
	password_hash text DEFAULT ''::text NULL,
	email_verified bool DEFAULT false NOT NULL,
	organization_id uuid NULL,
	CONSTRAINT users_cognito_sub_key UNIQUE (cognito_sub),
	CONSTRAINT users_email_key UNIQUE (email),
	CONSTRAINT users_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_users_cognito_sub ON public.users USING btree (cognito_sub);
CREATE INDEX idx_users_org_master ON public.users USING btree (organization_id, is_master);


-- public.account_users definition

-- Drop table

-- DROP TABLE public.account_users;

CREATE TABLE public.account_users (
	id uuid NOT NULL,
	account_id uuid NOT NULL,
	user_id uuid NOT NULL,
	"role" text NOT NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	CONSTRAINT account_users_account_id_user_id_key UNIQUE (account_id, user_id),
	CONSTRAINT account_users_pkey PRIMARY KEY (id),
	CONSTRAINT account_users_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id),
	CONSTRAINT account_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);


-- public.invitations definition

-- Drop table

-- DROP TABLE public.invitations;

CREATE TABLE public.invitations (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	invited_email text NOT NULL,
	invited_by_user_id uuid NOT NULL,
	"token" text NOT NULL,
	expires_at timestamp NOT NULL,
	accepted bool DEFAULT false NULL,
	created_at timestamp DEFAULT now() NULL,
	organization_id uuid NULL,
	CONSTRAINT invitations_pkey PRIMARY KEY (id),
	CONSTRAINT invitations_token_key UNIQUE (token),
	CONSTRAINT invitations_invited_by_user_id_fkey FOREIGN KEY (invited_by_user_id) REFERENCES public.users(id) ON DELETE CASCADE
);
CREATE INDEX idx_invitations_expires_at ON public.invitations USING btree (expires_at) WHERE (accepted = false);
CREATE INDEX idx_invitations_organization_id ON public.invitations USING btree (organization_id);


-- public.orders definition

-- Drop table

-- DROP TABLE public.orders;

CREATE TABLE public.orders (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	total_amount numeric(10, 2) NOT NULL,
	status text NOT NULL,
	payment_id uuid NULL,
	shipped_at timestamp NULL,
	created_at timestamp DEFAULT now() NULL,
	organization_id uuid NULL,
	CONSTRAINT orders_pkey PRIMARY KEY (id),
	CONSTRAINT orders_status_check CHECK ((status = ANY (ARRAY['PENDING'::text, 'PAID'::text, 'SHIPPED'::text, 'CANCELLED'::text, 'COMPLETED'::text]))),
	CONSTRAINT orders_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payments(id) ON DELETE SET NULL
);
CREATE INDEX idx_orders_organization_id ON public.orders USING btree (organization_id);
CREATE INDEX idx_orders_status ON public.orders USING btree (status);


-- public.plan_capabilities definition

-- Drop table

-- DROP TABLE public.plan_capabilities;

CREATE TABLE public.plan_capabilities (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	plan_id uuid NOT NULL,
	capability_id uuid NOT NULL,
	value_int int4 NULL,
	value_bool bool NULL,
	value_text text NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	CONSTRAINT plan_capabilities_pkey PRIMARY KEY (id),
	CONSTRAINT plan_capabilities_plan_id_capability_id_key UNIQUE (plan_id, capability_id),
	CONSTRAINT plan_capabilities_capability_id_fkey FOREIGN KEY (capability_id) REFERENCES public.capabilities(id) ON DELETE CASCADE,
	CONSTRAINT plan_capabilities_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public."plans"(id) ON DELETE CASCADE
);
CREATE INDEX idx_plan_capabilities_cap ON public.plan_capabilities USING btree (capability_id);
CREATE INDEX idx_plan_capabilities_plan ON public.plan_capabilities USING btree (plan_id);


-- public.plan_products definition

-- Drop table

-- DROP TABLE public.plan_products;

CREATE TABLE public.plan_products (
	plan_id uuid NOT NULL,
	product_id uuid NOT NULL,
	CONSTRAINT plan_products_pkey PRIMARY KEY (plan_id, product_id),
	CONSTRAINT plan_products_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public."plans"(id) ON DELETE CASCADE,
	CONSTRAINT plan_products_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE
);


-- public.subscriptions definition

-- Drop table

-- DROP TABLE public.subscriptions;

CREATE TABLE public.subscriptions (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	plan_id uuid NOT NULL,
	status text NOT NULL,
	started_at timestamp DEFAULT now() NOT NULL,
	expires_at timestamp NOT NULL,
	cancelled_at timestamp NULL,
	renewed_from uuid NULL,
	auto_renew bool DEFAULT true NULL,
	created_at timestamp DEFAULT now() NULL,
	updated_at timestamp DEFAULT now() NULL,
	organization_id uuid NULL,
	external_id text NULL,
	billing_cycle text DEFAULT 'MONTHLY'::text NULL,
	current_period_start timestamptz NULL,
	current_period_end timestamptz NULL,
	CONSTRAINT subscriptions_pkey PRIMARY KEY (id),
	CONSTRAINT subscriptions_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'CANCELLED'::text, 'EXPIRED'::text, 'TRIAL'::text]))),
	CONSTRAINT subscriptions_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public."plans"(id),
	CONSTRAINT subscriptions_renewed_from_fkey FOREIGN KEY (renewed_from) REFERENCES public.subscriptions(id) ON DELETE SET NULL
);
CREATE INDEX idx_subscriptions_organization_id ON public.subscriptions USING btree (organization_id);
CREATE INDEX idx_subscriptions_status ON public.subscriptions USING btree (status);


-- public.tokens_confirmacion definition

-- Drop table

-- DROP TABLE public.tokens_confirmacion;

CREATE TABLE public.tokens_confirmacion (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	"token" varchar NOT NULL,
	expires_at timestamp DEFAULT (now() + '01:00:00'::interval) NOT NULL,
	used bool DEFAULT false NOT NULL,
	"type" varchar DEFAULT 'email_verification'::character varying NOT NULL,
	user_id uuid NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	email varchar(255) NULL,
	full_name varchar(255) NULL,
	password_temp varchar(255) NULL,
	organization_id uuid NULL,
	CONSTRAINT tokens_confirmacion_pkey PRIMARY KEY (id),
	CONSTRAINT tokens_confirmacion_token_key UNIQUE (token),
	CONSTRAINT tokens_confirmacion_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);
CREATE INDEX idx_tokens_confirmacion_org_id ON public.tokens_confirmacion USING btree (organization_id);
CREATE INDEX idx_tokens_confirmacion_token ON public.tokens_confirmacion USING btree (token);


-- public.trip_stats definition

-- Drop table

-- DROP TABLE public.trip_stats;

CREATE TABLE public.trip_stats (
	trip_id uuid NOT NULL,
	point_count int4 NULL,
	alert_count int4 NULL,
	event_count int4 NULL,
	avg_speed float4 NULL,
	max_speed float4 NULL,
	distance_meters int4 NULL,
	driving_score float4 NULL,
	harsh_accel_count int4 NULL,
	harsh_brake_count int4 NULL,
	idle_time_seconds int4 NULL,
	overspeed_segments int4 NULL,
	created_at timestamptz DEFAULT now() NULL,
	updated_at timestamptz DEFAULT now() NULL,
	CONSTRAINT trip_stats_pkey PRIMARY KEY (trip_id),
	CONSTRAINT trip_stats_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.trips(trip_id)
);


-- public.unit_profile definition

-- Drop table

-- DROP TABLE public.unit_profile;

CREATE TABLE public.unit_profile (
	profile_id uuid DEFAULT gen_random_uuid() NOT NULL,
	unit_id uuid NOT NULL,
	unit_type text NOT NULL,
	icon_type text NULL,
	description text NULL,
	brand text NULL,
	model text NULL,
	serial text NULL,
	color text NULL,
	"year" int4 NULL,
	created_at timestamptz DEFAULT now() NULL,
	updated_at timestamptz DEFAULT now() NULL,
	CONSTRAINT unit_profile_pkey PRIMARY KEY (profile_id),
	CONSTRAINT unit_profile_unit_id_key UNIQUE (unit_id),
	CONSTRAINT fk_unit_profile_unit FOREIGN KEY (unit_id) REFERENCES public.units(id) ON DELETE CASCADE
);
CREATE INDEX idx_unit_profile_type ON public.unit_profile USING btree (unit_type);


-- public.user_units definition

-- Drop table

-- DROP TABLE public.user_units;

CREATE TABLE public.user_units (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	user_id uuid NOT NULL,
	unit_id uuid NOT NULL,
	granted_by uuid NULL,
	granted_at timestamptz DEFAULT now() NULL,
	"role" text DEFAULT 'viewer'::text NOT NULL,
	CONSTRAINT check_user_units_role CHECK ((role = ANY (ARRAY['viewer'::text, 'editor'::text, 'admin'::text]))),
	CONSTRAINT uq_user_units_user_unit UNIQUE (user_id, unit_id),
	CONSTRAINT user_units_pkey PRIMARY KEY (id),
	CONSTRAINT user_units_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(id) ON DELETE SET NULL,
	CONSTRAINT user_units_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id) ON DELETE CASCADE,
	CONSTRAINT user_units_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);
CREATE INDEX idx_user_units_role ON public.user_units USING btree (role);
CREATE INDEX idx_user_units_unit_id ON public.user_units USING btree (unit_id);
CREATE INDEX idx_user_units_user_id ON public.user_units USING btree (user_id);


-- public.vehicle_profile definition

-- Drop table

-- DROP TABLE public.vehicle_profile;

CREATE TABLE public.vehicle_profile (
	unit_id uuid NOT NULL,
	plate text NULL,
	vin text NULL,
	fuel_type text NULL,
	passengers int4 NULL,
	created_at timestamptz DEFAULT now() NULL,
	updated_at timestamptz DEFAULT now() NULL,
	CONSTRAINT vehicle_profile_pkey PRIMARY KEY (unit_id),
	CONSTRAINT fk_vehicle_unit FOREIGN KEY (unit_id) REFERENCES public.unit_profile(unit_id) ON DELETE CASCADE
);
CREATE INDEX idx_vehicle_plate ON public.vehicle_profile USING btree (plate);


-- public.organizations definition

-- Drop table

-- DROP TABLE public.organizations;

CREATE TABLE public.organizations (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	status text DEFAULT 'ACTIVE'::text NULL,
	created_at timestamp DEFAULT now() NULL,
	updated_at timestamp DEFAULT now() NULL,
	active_subscription_id uuid NULL,
	billing_email text NULL,
	country text NULL,
	timezone text DEFAULT 'UTC'::text NULL,
	metadata jsonb DEFAULT '{}'::jsonb NULL,
	account_id uuid NOT NULL,
	CONSTRAINT organizations_pkey PRIMARY KEY (id),
	CONSTRAINT organizations_status_check CHECK ((status = ANY (ARRAY['PENDING'::text, 'ACTIVE'::text, 'SUSPENDED'::text, 'DELETED'::text]))),
	CONSTRAINT organizations_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE,
	CONSTRAINT organizations_active_subscription_id_fkey FOREIGN KEY (active_subscription_id) REFERENCES public.subscriptions(id) ON DELETE SET NULL
);
CREATE INDEX idx_organizations_account_id ON public.organizations USING btree (account_id);


-- public.account_events definition

-- Drop table

-- DROP TABLE public.account_events;

CREATE TABLE public.account_events (
	id uuid NOT NULL,
	account_id uuid NOT NULL,
	organization_id uuid NULL,
	actor_user_id uuid NULL,
	actor_type text NOT NULL,
	event_type text NOT NULL,
	target_type text NOT NULL,
	target_id uuid NULL,
	metadata jsonb NULL,
	ip_address inet NULL,
	user_agent text NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	CONSTRAINT account_events_pkey PRIMARY KEY (id),
	CONSTRAINT account_events_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id),
	CONSTRAINT account_events_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES public.users(id),
	CONSTRAINT account_events_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id)
);
CREATE INDEX idx_account_events_account ON public.account_events USING btree (account_id, created_at DESC);
CREATE INDEX idx_account_events_org ON public.account_events USING btree (organization_id, created_at DESC);
CREATE INDEX idx_account_events_type ON public.account_events USING btree (event_type);


-- public.devices definition

-- Drop table

-- DROP TABLE public.devices;

CREATE TABLE public.devices (
	device_id text NOT NULL,
	brand text NULL,
	model text NULL,
	firmware_version text NULL,
	status text DEFAULT 'nuevo'::text NOT NULL,
	last_comm_at timestamptz NULL,
	created_at timestamptz DEFAULT now() NULL,
	updated_at timestamptz DEFAULT now() NULL,
	last_assignment_at timestamptz NULL,
	notes text NULL,
	organization_id uuid NULL,
	CONSTRAINT devices_pkey PRIMARY KEY (device_id),
	CONSTRAINT devices_status_check CHECK ((status = ANY (ARRAY['nuevo'::text, 'preparado'::text, 'enviado'::text, 'entregado'::text, 'asignado'::text, 'devuelto'::text, 'inactivo'::text]))),
	CONSTRAINT devices_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id)
);
CREATE INDEX idx_devices_brand_model ON public.devices USING btree (brand, model);
CREATE INDEX idx_devices_organization_id ON public.devices USING btree (organization_id);
CREATE INDEX idx_devices_status ON public.devices USING btree (status);


-- public.order_items definition

-- Drop table

-- DROP TABLE public.order_items;

CREATE TABLE public.order_items (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	order_id uuid NOT NULL,
	device_id text NULL,
	item_type text NULL,
	description text NULL,
	quantity int4 DEFAULT 1 NOT NULL,
	unit_price numeric(10, 2) NOT NULL,
	total_price numeric(10, 2) GENERATED ALWAYS AS ((quantity::numeric * unit_price)) STORED NULL,
	CONSTRAINT order_items_item_type_check CHECK ((item_type = ANY (ARRAY['DEVICE'::text, 'ACCESSORY'::text, 'SERVICE'::text]))),
	CONSTRAINT order_items_pkey PRIMARY KEY (id),
	CONSTRAINT order_items_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(device_id) ON DELETE SET NULL,
	CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE
);
CREATE INDEX idx_order_items_order ON public.order_items USING btree (order_id);


-- public.organization_capabilities definition

-- Drop table

-- DROP TABLE public.organization_capabilities;

CREATE TABLE public.organization_capabilities (
	id uuid NOT NULL,
	organization_id uuid NOT NULL,
	capability_id uuid NOT NULL,
	value_int int4 NULL,
	value_bool bool NULL,
	value_text text NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	CONSTRAINT organization_capabilities_organization_id_capability_id_key UNIQUE (organization_id, capability_id),
	CONSTRAINT organization_capabilities_pkey PRIMARY KEY (id),
	CONSTRAINT organization_capabilities_capability_id_fkey FOREIGN KEY (capability_id) REFERENCES public.capabilities(id),
	CONSTRAINT organization_capabilities_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id)
);


-- public.organization_users definition

-- Drop table

-- DROP TABLE public.organization_users;

CREATE TABLE public.organization_users (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	organization_id uuid NOT NULL,
	user_id uuid NOT NULL,
	"role" text DEFAULT 'member'::text NOT NULL,
	created_at timestamptz DEFAULT now() NULL,
	CONSTRAINT org_user_role_check CHECK ((role = ANY (ARRAY['owner'::text, 'admin'::text, 'billing'::text, 'member'::text]))),
	CONSTRAINT organization_users_pkey PRIMARY KEY (id),
	CONSTRAINT uq_org_user UNIQUE (organization_id, user_id),
	CONSTRAINT organization_users_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE,
	CONSTRAINT organization_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);


-- public.sim_cards definition

-- Drop table

-- DROP TABLE public.sim_cards;

CREATE TABLE public.sim_cards (
	sim_id uuid DEFAULT gen_random_uuid() NOT NULL,
	device_id text NOT NULL,
	carrier text DEFAULT 'KORE'::text NOT NULL,
	iccid varchar NOT NULL,
	imsi varchar NULL,
	msisdn varchar NULL,
	status text DEFAULT 'active'::text NOT NULL,
	metadata jsonb NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	updated_at timestamptz DEFAULT now() NOT NULL,
	CONSTRAINT sim_cards_pkey PRIMARY KEY (sim_id),
	CONSTRAINT unique_active_sim_per_device UNIQUE (device_id) DEFERRABLE,
	CONSTRAINT sim_cards_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(device_id)
);
CREATE INDEX idx_sim_cards_device ON public.sim_cards USING btree (device_id);
CREATE INDEX idx_sim_cards_iccid ON public.sim_cards USING btree (iccid);


-- public.sim_kore_profiles definition

-- Drop table

-- DROP TABLE public.sim_kore_profiles;

CREATE TABLE public.sim_kore_profiles (
	sim_id uuid NOT NULL,
	kore_sim_id text NOT NULL,
	kore_account_id text NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	updated_at timestamptz DEFAULT now() NULL,
	CONSTRAINT sim_kore_profiles_pkey PRIMARY KEY (sim_id),
	CONSTRAINT sim_kore_profiles_sim_id_fkey FOREIGN KEY (sim_id) REFERENCES public.sim_cards(sim_id)
);


-- public.unit_devices definition

-- Drop table

-- DROP TABLE public.unit_devices;

CREATE TABLE public.unit_devices (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	unit_id uuid NOT NULL,
	device_id text NOT NULL,
	assigned_at timestamptz DEFAULT now() NULL,
	unassigned_at timestamptz NULL,
	is_active bool GENERATED ALWAYS AS (unassigned_at IS NULL) STORED NULL,
	CONSTRAINT unit_devices_pkey PRIMARY KEY (id),
	CONSTRAINT uq_unit_devices_unit_device UNIQUE (unit_id, device_id),
	CONSTRAINT unit_devices_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(device_id) ON DELETE CASCADE,
	CONSTRAINT unit_devices_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id) ON DELETE CASCADE
);
CREATE INDEX idx_unit_devices_device_id ON public.unit_devices USING btree (device_id);
CREATE INDEX idx_unit_devices_is_active ON public.unit_devices USING btree (is_active);
CREATE INDEX idx_unit_devices_unit_id ON public.unit_devices USING btree (unit_id);


-- public.commands definition

-- Drop table

-- DROP TABLE public.commands;

CREATE TABLE public.commands (
	command_id uuid DEFAULT gen_random_uuid() NOT NULL,
	template_id uuid NULL,
	command text NOT NULL,
	media text NOT NULL,
	request_user_id uuid NULL,
	request_user_email text NOT NULL,
	device_id text NOT NULL,
	requested_at timestamptz DEFAULT now() NULL,
	updated_at timestamptz DEFAULT now() NULL,
	status text DEFAULT 'pending'::text NOT NULL,
	metadata jsonb NULL,
	CONSTRAINT commands_pkey PRIMARY KEY (command_id),
	CONSTRAINT commands_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(device_id),
	CONSTRAINT commands_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.command_templates(template_id)
);


-- public.device_events definition

-- Drop table

-- DROP TABLE public.device_events;

CREATE TABLE public.device_events (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	device_id text NOT NULL,
	event_type text NOT NULL,
	old_status text NULL,
	new_status text NULL,
	performed_by uuid NULL,
	event_details text NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	CONSTRAINT check_event_type CHECK ((event_type = ANY (ARRAY['creado'::text, 'preparado'::text, 'enviado'::text, 'entregado'::text, 'asignado'::text, 'devuelto'::text, 'firmware_actualizado'::text, 'nota'::text, 'estado_cambiado'::text]))),
	CONSTRAINT device_events_pkey PRIMARY KEY (id),
	CONSTRAINT device_events_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(device_id) ON DELETE CASCADE,
	CONSTRAINT device_events_performed_by_fkey FOREIGN KEY (performed_by) REFERENCES public.users(id) ON DELETE SET NULL
);
CREATE INDEX idx_device_events_created_at ON public.device_events USING btree (created_at);
CREATE INDEX idx_device_events_device_id ON public.device_events USING btree (device_id);
CREATE INDEX idx_device_events_event_type ON public.device_events USING btree (event_type);






ALTER TYPE public.event_type_enum OWNER TO pgadmin;
