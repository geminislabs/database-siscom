--
-- PostgreSQL database dump
--

\restrict Ypb1UDYxNrWRN2am94IikJNfuH10iiOfYvHru2H2UinkeHfUx7DCFLXp81EoCNV

-- Dumped from database version 14.19 (Ubuntu 14.19-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.19 (Ubuntu 14.19-0ubuntu0.22.04.1)

-- Started on 2025-09-28 21:15:45 CST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 3687 (class 1262 OID 16385)
-- Name: test-ana; Type: DATABASE; Schema: -; Owner: test
--

-- Database siscom-test already exists, created by docker-compose

\unrestrict Ypb1UDYxNrWRN2am94IikJNfuH10iiOfYvHru2H2UinkeHfUx7DCFLXp81EoCNV
\encoding SQL_ASCII
\connect -reuse-previous=on "dbname='siscom-test'"
\restrict Ypb1UDYxNrWRN2am94IikJNfuH10iiOfYvHru2H2UinkeHfUx7DCFLXp81EoCNV

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 24576)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 3688 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 240 (class 1255 OID 24706)
-- Name: update_poi_state_timestamp(); Type: FUNCTION; Schema: public; Owner: test
--

CREATE FUNCTION public.update_poi_state_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.last_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_poi_state_timestamp() OWNER TO pgadmin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 210 (class 1259 OID 16386)
-- Name: clients; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE IF NOT EXISTS public.clients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    subscription_plan text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT clients_subscription_plan_check CHECK ((subscription_plan = ANY (ARRAY['FREE'::text, 'FAMILY'::text, 'BUSINESS'::text])))
);


ALTER TABLE public.clients OWNER TO pgadmin;

--
-- TOC entry 229 (class 1259 OID 32851)
-- Name: communications_current_state; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE IF NOT EXISTS public.communications_current_state (
    device_id character varying(100) NOT NULL,
    uuid character varying(255) NOT NULL,
    backup_battery_voltage numeric(5,2),
    cell_id character varying(50),
    course numeric(6,2),
    delivery_type character varying(20),
    engine_status character varying(10),
    firmware character varying(20),
    fix_status character varying(5),
    gps_datetime timestamp without time zone,
    gps_epoch bigint,
    idle_time integer,
    lac character varying(10),
    latitude numeric(10,8),
    longitude numeric(11,8),
    main_battery_voltage numeric(5,2),
    mcc character varying(10),
    mnc character varying(10),
    model character varying(10),
    msg_class character varying(20),
    msg_counter integer,
    network_status character varying(50),
    odometer bigint,
    rx_lvl integer,
    satellites integer,
    speed numeric(8,2),
    speed_time integer,
    total_distance bigint,
    trip_distance bigint,
    trip_hourmeter integer,
    bytes_count integer,
    client_ip text,
    client_port integer,
    decoded_epoch bigint,
    received_epoch bigint,
    raw_message text,
    received_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.communications_current_state OWNER TO pgadmin;

--
-- TOC entry 228 (class 1259 OID 24766)
-- Name: communications_suntech; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE IF NOT EXISTS public.communications_suntech (
    id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    device_id character varying(100) NOT NULL,
    backup_battery_voltage numeric(5,2),
    cell_id character varying(50),
    course numeric(6,2),
    delivery_type character varying(20),
    engine_status character varying(10),
    firmware character varying(20),
    fix_status character varying(5),
    gps_datetime timestamp without time zone,
    gps_epoch bigint,
    idle_time integer,
    lac character varying(10),
    latitude numeric(10,8),
    longitude numeric(11,8),
    main_battery_voltage numeric(5,2),
    mcc character varying(10),
    mnc character varying(10),
    model character varying(10),
    msg_class character varying(20),
    msg_counter integer,
    network_status character varying(50),
    odometer bigint,
    rx_lvl integer,
    satellites integer,
    speed numeric(8,2),
    speed_time integer,
    total_distance bigint,
    trip_distance bigint,
    trip_hourmeter integer,
    bytes_count integer,
    client_ip text,
    client_port integer,
    decoded_epoch bigint,
    received_epoch bigint,
    raw_message text,
    received_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.communications_suntech OWNER TO pgadmin;

--
-- TOC entry 227 (class 1259 OID 24765)
-- Name: communications_suntech_id_seq; Type: SEQUENCE; Schema: public; Owner: test
--

CREATE SEQUENCE public.communications_suntech_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.communications_suntech_id_seq OWNER TO pgadmin;

--
-- TOC entry 3689 (class 0 OID 0)
-- Dependencies: 227
-- Name: communications_suntech_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: test
--

ALTER SEQUENCE public.communications_suntech_id_seq OWNED BY public.communications_suntech.id;


--
-- TOC entry 226 (class 1259 OID 24755)
-- Name: devices; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE IF NOT EXISTS public.devices (
    device_id character varying(100) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    firmware character varying(50),
    provider character varying(50) DEFAULT 'suntech'::character varying
);


ALTER TABLE public.devices OWNER TO pgadmin;

--
-- TOC entry 222 (class 1259 OID 24657)
-- Name: geofence_states; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE IF NOT EXISTS public.geofence_states (
    id integer NOT NULL,
    device_id character varying(100) NOT NULL,
    geofence_id character varying(100) NOT NULL,
    is_inside boolean DEFAULT false,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.geofence_states OWNER TO pgadmin;

--
-- TOC entry 221 (class 1259 OID 24656)
-- Name: geofence_states_id_seq; Type: SEQUENCE; Schema: public; Owner: test
--

CREATE SEQUENCE public.geofence_states_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.geofence_states_id_seq OWNER TO pgadmin;

--
-- TOC entry 3690 (class 0 OID 0)
-- Dependencies: 221
-- Name: geofence_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: test
--

ALTER SEQUENCE public.geofence_states_id_seq OWNED BY public.geofence_states.id;


--
-- TOC entry 218 (class 1259 OID 24624)
-- Name: geofences; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE IF NOT EXISTS public.geofences (
    id integer NOT NULL,
    geofence_id character varying(100) NOT NULL,
    device_id character varying(100) NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(20) DEFAULT 'inside'::character varying,
    latitude numeric(10,8) NOT NULL,
    longitude numeric(11,8) NOT NULL,
    radius numeric(10,2) NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT geofences_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying])::text[]))),
    CONSTRAINT geofences_type_check CHECK (((type)::text = ANY ((ARRAY['inside'::character varying, 'outside'::character varying])::text[])))
);


ALTER TABLE public.geofences OWNER TO pgadmin;

--
-- TOC entry 217 (class 1259 OID 24623)
-- Name: geofences_id_seq; Type: SEQUENCE; Schema: public; Owner: test
--

CREATE SEQUENCE public.geofences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.geofences_id_seq OWNER TO pgadmin;

--
-- TOC entry 3691 (class 0 OID 0)
-- Dependencies: 217
-- Name: geofences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: test
--

ALTER SEQUENCE public.geofences_id_seq OWNED BY public.geofences.id;


--
-- TOC entry 214 (class 1259 OID 16443)
-- Name: invitations; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE IF NOT EXISTS public.invitations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_id uuid NOT NULL,
    invited_email text NOT NULL,
    invited_by_user_id uuid NOT NULL,
    token text NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    accepted boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.invitations OWNER TO pgadmin;

--
-- TOC entry 224 (class 1259 OID 24683)
-- Name: notifications; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE IF NOT EXISTS public.notifications (
    id bigint NOT NULL,
    notification_id character varying(255) NOT NULL,
    device_id character varying(100) NOT NULL,
    event character varying(100) NOT NULL,
    message text NOT NULL,
    status character varying(20) DEFAULT 'info'::character varying,
    read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT notifications_status_check CHECK (((status)::text = ANY ((ARRAY['info'::character varying, 'warning'::character varying, 'error'::character varying, 'success'::character varying])::text[])))
);


ALTER TABLE public.notifications OWNER TO pgadmin;

--
-- TOC entry 223 (class 1259 OID 24682)
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: test
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notifications_id_seq OWNER TO pgadmin;

--
-- TOC entry 3692 (class 0 OID 0)
-- Dependencies: 223
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: test
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- TOC entry 220 (class 1259 OID 24645)
-- Name: poi_states; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE IF NOT EXISTS public.poi_states (
    id integer NOT NULL,
    device_id character varying(100) NOT NULL,
    poi_id character varying(100) NOT NULL,
    is_inside boolean DEFAULT false,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.poi_states OWNER TO pgadmin;

--
-- TOC entry 219 (class 1259 OID 24644)
-- Name: poi_states_id_seq; Type: SEQUENCE; Schema: public; Owner: test
--

CREATE SEQUENCE public.poi_states_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.poi_states_id_seq OWNER TO pgadmin;

--
-- TOC entry 3693 (class 0 OID 0)
-- Dependencies: 219
-- Name: poi_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: test
--

ALTER SEQUENCE public.poi_states_id_seq OWNED BY public.poi_states.id;


--
-- TOC entry 216 (class 1259 OID 24605)
-- Name: pois; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE IF NOT EXISTS public.pois (
    id integer NOT NULL,
    poi_id character varying(100) NOT NULL,
    device_id character varying(100) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    latitude numeric(10,8) NOT NULL,
    longitude numeric(11,8) NOT NULL,
    radius numeric(10,2) DEFAULT 100.0,
    status character varying(20) DEFAULT 'active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pois_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying])::text[])))
);


ALTER TABLE public.pois OWNER TO pgadmin;

--
-- TOC entry 215 (class 1259 OID 24604)
-- Name: pois_id_seq; Type: SEQUENCE; Schema: public; Owner: test
--

CREATE SEQUENCE public.pois_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pois_id_seq OWNER TO pgadmin;

--
-- TOC entry 3694 (class 0 OID 0)
-- Dependencies: 215
-- Name: pois_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: test
--

ALTER SEQUENCE public.pois_id_seq OWNED BY public.pois.id;


--
-- TOC entry 212 (class 1259 OID 16413)
-- Name: units; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE IF NOT EXISTS public.units (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.units OWNER TO pgadmin;

--
-- TOC entry 225 (class 1259 OID 24714)
-- Name: unread_notifications; Type: VIEW; Schema: public; Owner: test
--

CREATE VIEW public.unread_notifications AS
 SELECT notifications.notification_id,
    notifications.device_id,
    notifications.event,
    notifications.message,
    notifications.status,
    notifications.created_at
   FROM public.notifications
  WHERE (notifications.read = false)
  ORDER BY notifications.created_at DESC;


ALTER TABLE public.unread_notifications OWNER TO pgadmin;

--
-- TOC entry 213 (class 1259 OID 16427)
-- Name: user_units; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE IF NOT EXISTS public.user_units (
    user_id uuid NOT NULL,
    unit_id uuid NOT NULL,
    can_edit boolean DEFAULT false
);


ALTER TABLE public.user_units OWNER TO pgadmin;

--
-- TOC entry 211 (class 1259 OID 16396)
-- Name: users; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE IF NOT EXISTS public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_id uuid NOT NULL,
    cognito_sub text NOT NULL,
    email text,
    full_name text,
    is_master boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.users OWNER TO pgadmin;

--
-- TOC entry 3438 (class 2604 OID 24769)
-- Name: communications_suntech id; Type: DEFAULT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.communications_suntech ALTER COLUMN id SET DEFAULT nextval('public.communications_suntech_id_seq'::regclass);


--
-- TOC entry 3428 (class 2604 OID 24660)
-- Name: geofence_states id; Type: DEFAULT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.geofence_states ALTER COLUMN id SET DEFAULT nextval('public.geofence_states_id_seq'::regclass);


--
-- TOC entry 3418 (class 2604 OID 24627)
-- Name: geofences id; Type: DEFAULT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.geofences ALTER COLUMN id SET DEFAULT nextval('public.geofences_id_seq'::regclass);


--
-- TOC entry 3431 (class 2604 OID 24686)
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- TOC entry 3425 (class 2604 OID 24648)
-- Name: poi_states id; Type: DEFAULT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.poi_states ALTER COLUMN id SET DEFAULT nextval('public.poi_states_id_seq'::regclass);


--
-- TOC entry 3412 (class 2604 OID 24608)
-- Name: pois id; Type: DEFAULT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.pois ALTER COLUMN id SET DEFAULT nextval('public.pois_id_seq'::regclass);


--
-- TOC entry 3663 (class 0 OID 16386)
-- Dependencies: 210
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: test
--



--
-- TOC entry 3681 (class 0 OID 32851)
-- Dependencies: 229
-- Data for Name: communications_current_state; Type: TABLE DATA; Schema: public; Owner: test
--



--
-- TOC entry 3680 (class 0 OID 24766)
-- Dependencies: 228
-- Data for Name: communications_suntech; Type: TABLE DATA; Schema: public; Owner: test
--

INSERT INTO public.communications_suntech VALUES (1, '7b8aa4d9-a5c8-51d2-bf38-f74e87723280', '0848063597', 0.00, '03675103', 0.00, 'BUFFER', 'OFF', '1.0.6', '1', '2024-04-09 16:22:26', 1712679746, 0, '5B12', 20.57460500, -100.35982600, 11.43, '334', '20', '84', 'ALERT', 5196, 'SERVER DISCONNECTED', 730327, 33, 15, 0.00, 0, 0, 0, 1754, 190, NULL, 44539, 1755473074321, 1755473074321, 'STT;0848063597;BFFFFF;84;1.0.6;1;20240409;16:22:26;03675103;334;20;5B12;33;+20.574605;-100.359826;0.00;0.00;15;1;0000000;00000000;0;1;5196;001F803F;0.0;11.43;2;23;-253;2;730327;0;0;0;0;1754
', '2025-08-17 23:24:34.425712', '2025-08-17 23:24:34.425712') ON CONFLICT DO NOTHING;
INSERT INTO public.communications_suntech VALUES (4, '72f9ec98-deac-555e-8b3d-39438c773dd5', '0848063597', 0.00, '03675103', 0.00, 'BUFFER', 'OFF', '1.0.6', '1', '2024-04-09 16:22:26', 1712679746, 0, '5B12', 20.57460500, -100.35982600, 11.43, '334', '20', '84', 'ALERT', 5196, 'SERVER DISCONNECTED', 730327, 33, 15, 0.00, 0, 0, 0, 1753, 190, NULL, 55503, 1755473111125, 1755473111125, 'STT;0848063597;BFFFFF;84;1.0.6;1;20240409;16:22:26;03675103;334;20;5B12;33;+20.574605;-100.359826;0.00;0.00;15;1;0000000;00000000;0;1;5196;001F803F;0.0;11.43;2;23;-253;2;730327;0;0;0;0;1753
', '2025-08-17 23:25:11.225721', '2025-08-17 23:25:11.225721') ON CONFLICT DO NOTHING;


--
-- TOC entry 3678 (class 0 OID 24755)
-- Dependencies: 226
-- Data for Name: devices; Type: TABLE DATA; Schema: public; Owner: test
--



--
-- TOC entry 3667 (class 0 OID 16443)
-- Dependencies: 214
-- Data for Name: invitations; Type: TABLE DATA; Schema: public; Owner: test
--



--
-- TOC entry 3677 (class 0 OID 24683)
-- Dependencies: 224
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: test
--

INSERT INTO public.notifications VALUES (1, 'NOTIF001', 'DEVICE001', 'poi_entered', 'Dispositivo entró al Centro Histórico', 'info', false, '2025-08-17 12:00:44.039485');
INSERT INTO public.notifications VALUES (2, 'NOTIF002', 'DEVICE001', 'geofence_entered', 'Dispositivo entró en Zona Autorizada Centro', 'info', true, '2025-08-17 13:00:44.039485');
INSERT INTO public.notifications VALUES (3, 'NOTIF003', 'DEVICE002', 'geofence_exited', 'ALERTA: Dispositivo salió de Ruta Permitida Este', 'warning', false, '2025-08-17 13:30:44.039485');
INSERT INTO public.notifications VALUES (4, 'NOTIF004', 'DEVICE001', 'poi_entered', 'Dispositivo cerca de Universidad UAQ', 'info', false, '2025-08-17 13:45:44.039485');


--
-- TOC entry 3673 (class 0 OID 24645)
-- Dependencies: 220
-- Data for Name: poi_states; Type: TABLE DATA; Schema: public; Owner: test
--

INSERT INTO public.poi_states VALUES (1, 'DEVICE001', 'POI001', false, '2025-08-17 14:00:44.015885');
INSERT INTO public.poi_states VALUES (2, 'DEVICE001', 'POI002', false, '2025-08-17 14:00:44.015885');
INSERT INTO public.poi_states VALUES (3, 'DEVICE001', 'POI003', false, '2025-08-17 14:00:44.015885');
INSERT INTO public.poi_states VALUES (4, 'DEVICE002', 'POI004', false, '2025-08-17 14:00:44.015885');
INSERT INTO public.poi_states VALUES (5, 'DEVICE002', 'POI005', false, '2025-08-17 14:00:44.015885');


--
-- TOC entry 3669 (class 0 OID 24605)
-- Dependencies: 216
-- Data for Name: pois; Type: TABLE DATA; Schema: public; Owner: test
--

INSERT INTO public.pois VALUES (1, 'POI001', 'DEVICE001', 'Centro Histórico', 'Plaza de Armas Querétaro', 20.58880000, -100.38990000, 200.00, 'active', '2025-08-17 14:00:44.003958', '2025-08-17 14:00:44.003958');
INSERT INTO public.pois VALUES (2, 'POI002', 'DEVICE001', 'Universidad UAQ', 'Universidad Autónoma de Querétaro', 20.57350000, -100.38700000, 150.00, 'active', '2025-08-17 14:00:44.003958', '2025-08-17 14:00:44.003958');
INSERT INTO public.pois VALUES (3, 'POI003', 'DEVICE001', 'Antea LifeStyle', 'Centro Comercial Antea', 20.55130000, -100.46380000, 300.00, 'active', '2025-08-17 14:00:44.003958', '2025-08-17 14:00:44.003958');
INSERT INTO public.pois VALUES (4, 'POI004', 'DEVICE002', 'Aeropuerto QRO', 'Aeropuerto Internacional de Querétaro', 20.61730000, -100.18570000, 500.00, 'active', '2025-08-17 14:00:44.003958', '2025-08-17 14:00:44.003958');
INSERT INTO public.pois VALUES (5, 'POI005', 'DEVICE002', 'CEDIS Walmart', 'Centro de Distribución', 20.52340000, -100.41230000, 200.00, 'active', '2025-08-17 14:00:44.003958', '2025-08-17 14:00:44.003958');


--
-- TOC entry 3665 (class 0 OID 16413)
-- Dependencies: 212
-- Data for Name: units; Type: TABLE DATA; Schema: public; Owner: test
--



--
-- TOC entry 3666 (class 0 OID 16427)
-- Dependencies: 213
-- Data for Name: user_units; Type: TABLE DATA; Schema: public; Owner: test
--



--
-- TOC entry 3664 (class 0 OID 16396)
-- Dependencies: 211
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: test
--



--
-- TOC entry 3695 (class 0 OID 0)
-- Dependencies: 227
-- Name: communications_suntech_id_seq; Type: SEQUENCE SET; Schema: public; Owner: test
--

SELECT pg_catalog.setval('public.communications_suntech_id_seq', 4, true);


--
-- TOC entry 3696 (class 0 OID 0)
-- Dependencies: 221
-- Name: geofence_states_id_seq; Type: SEQUENCE SET; Schema: public; Owner: test
--

SELECT pg_catalog.setval('public.geofence_states_id_seq', 5, true);


--
-- TOC entry 3697 (class 0 OID 0)
-- Dependencies: 217
-- Name: geofences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: test
--

SELECT pg_catalog.setval('public.geofences_id_seq', 5, true);


--
-- TOC entry 3698 (class 0 OID 0)
-- Dependencies: 223
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: test
--

SELECT pg_catalog.setval('public.notifications_id_seq', 4, true);


--
-- TOC entry 3699 (class 0 OID 0)
-- Dependencies: 219
-- Name: poi_states_id_seq; Type: SEQUENCE SET; Schema: public; Owner: test
--

SELECT pg_catalog.setval('public.poi_states_id_seq', 5, true);


--
-- TOC entry 3700 (class 0 OID 0)
-- Dependencies: 215
-- Name: pois_id_seq; Type: SEQUENCE SET; Schema: public; Owner: test
--

SELECT pg_catalog.setval('public.pois_id_seq', 5, true);


--
-- TOC entry 3444 (class 2606 OID 16395)
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- TOC entry 3510 (class 2606 OID 32859)
-- Name: communications_current_state communications_current_state_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.communications_current_state
    ADD CONSTRAINT communications_current_state_pkey PRIMARY KEY (device_id);


--
-- TOC entry 3512 (class 2606 OID 32861)
-- Name: communications_current_state communications_current_state_uuid_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.communications_current_state
    ADD CONSTRAINT communications_current_state_uuid_key UNIQUE (uuid);


--
-- TOC entry 3498 (class 2606 OID 24774)
-- Name: communications_suntech communications_suntech_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.communications_suntech
    ADD CONSTRAINT communications_suntech_pkey PRIMARY KEY (id);


--
-- TOC entry 3500 (class 2606 OID 24776)
-- Name: communications_suntech communications_suntech_uuid_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.communications_suntech
    ADD CONSTRAINT communications_suntech_uuid_key UNIQUE (uuid);


--
-- TOC entry 3493 (class 2606 OID 24761)
-- Name: devices devices_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (device_id);


--
-- TOC entry 3479 (class 2606 OID 24666)
-- Name: geofence_states geofence_states_device_id_geofence_id_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.geofence_states
    ADD CONSTRAINT geofence_states_device_id_geofence_id_key UNIQUE (device_id, geofence_id);


--
-- TOC entry 3481 (class 2606 OID 24664)
-- Name: geofence_states geofence_states_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.geofence_states
    ADD CONSTRAINT geofence_states_pkey PRIMARY KEY (id);


--
-- TOC entry 3466 (class 2606 OID 24639)
-- Name: geofences geofences_device_id_geofence_id_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.geofences
    ADD CONSTRAINT geofences_device_id_geofence_id_key UNIQUE (device_id, geofence_id);


--
-- TOC entry 3468 (class 2606 OID 24637)
-- Name: geofences geofences_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.geofences
    ADD CONSTRAINT geofences_pkey PRIMARY KEY (id);


--
-- TOC entry 3455 (class 2606 OID 16452)
-- Name: invitations invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_pkey PRIMARY KEY (id);


--
-- TOC entry 3457 (class 2606 OID 16454)
-- Name: invitations invitations_token_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_token_key UNIQUE (token);


--
-- TOC entry 3489 (class 2606 OID 24696)
-- Name: notifications notifications_notification_id_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_notification_id_key UNIQUE (notification_id);


--
-- TOC entry 3491 (class 2606 OID 24694)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 3475 (class 2606 OID 24654)
-- Name: poi_states poi_states_device_id_poi_id_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.poi_states
    ADD CONSTRAINT poi_states_device_id_poi_id_key UNIQUE (device_id, poi_id);


--
-- TOC entry 3477 (class 2606 OID 24652)
-- Name: poi_states poi_states_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.poi_states
    ADD CONSTRAINT poi_states_pkey PRIMARY KEY (id);


--
-- TOC entry 3462 (class 2606 OID 24619)
-- Name: pois pois_device_id_poi_id_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.pois
    ADD CONSTRAINT pois_device_id_poi_id_key UNIQUE (device_id, poi_id);


--
-- TOC entry 3464 (class 2606 OID 24617)
-- Name: pois pois_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.pois
    ADD CONSTRAINT pois_pkey PRIMARY KEY (id);


--
-- TOC entry 3451 (class 2606 OID 16421)
-- Name: units units_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_pkey PRIMARY KEY (id);


--
-- TOC entry 3453 (class 2606 OID 16432)
-- Name: user_units user_units_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.user_units
    ADD CONSTRAINT user_units_pkey PRIMARY KEY (user_id, unit_id);


--
-- TOC entry 3447 (class 2606 OID 16407)
-- Name: users users_cognito_sub_key; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_cognito_sub_key UNIQUE (cognito_sub);


--
-- TOC entry 3449 (class 2606 OID 16405)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3501 (class 1259 OID 24785)
-- Name: idx_comm_created_at; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_comm_created_at ON public.communications_suntech USING btree (created_at DESC);


--
-- TOC entry 3513 (class 1259 OID 32863)
-- Name: idx_comm_current_decoded_epoch; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_comm_current_decoded_epoch ON public.communications_current_state USING btree (decoded_epoch DESC);


--
-- TOC entry 3514 (class 1259 OID 32862)
-- Name: idx_comm_current_gps_datetime; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_comm_current_gps_datetime ON public.communications_current_state USING btree (gps_datetime DESC);


--
-- TOC entry 3502 (class 1259 OID 24783)
-- Name: idx_comm_decoded_epoch; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_comm_decoded_epoch ON public.communications_suntech USING btree (decoded_epoch DESC);


--
-- TOC entry 3503 (class 1259 OID 24786)
-- Name: idx_comm_device_created; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_comm_device_created ON public.communications_suntech USING btree (device_id, created_at DESC);


--
-- TOC entry 3504 (class 1259 OID 24778)
-- Name: idx_comm_device_id; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_comm_device_id ON public.communications_suntech USING btree (device_id);


--
-- TOC entry 3505 (class 1259 OID 24781)
-- Name: idx_comm_gps_datetime; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_comm_gps_datetime ON public.communications_suntech USING btree (gps_datetime DESC);


--
-- TOC entry 3506 (class 1259 OID 24782)
-- Name: idx_comm_msg_class; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_comm_msg_class ON public.communications_suntech USING btree (msg_class);


--
-- TOC entry 3507 (class 1259 OID 24780)
-- Name: idx_comm_received_at; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_comm_received_at ON public.communications_suntech USING btree (received_at DESC);


--
-- TOC entry 3508 (class 1259 OID 24779)
-- Name: idx_comm_uuid; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_comm_uuid ON public.communications_suntech USING btree (uuid);


--
-- TOC entry 3494 (class 1259 OID 24763)
-- Name: idx_devices_created; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_devices_created ON public.devices USING btree (created_at);


--
-- TOC entry 3495 (class 1259 OID 24764)
-- Name: idx_devices_firmware; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_devices_firmware ON public.devices USING btree (firmware);


--
-- TOC entry 3496 (class 1259 OID 24762)
-- Name: idx_devices_provider; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_devices_provider ON public.devices USING btree (provider);


--
-- TOC entry 3482 (class 1259 OID 24667)
-- Name: idx_geofence_states_device_geo; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_geofence_states_device_geo ON public.geofence_states USING btree (device_id, geofence_id);


--
-- TOC entry 3469 (class 1259 OID 24640)
-- Name: idx_geofences_device_id; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_geofences_device_id ON public.geofences USING btree (device_id);


--
-- TOC entry 3470 (class 1259 OID 24643)
-- Name: idx_geofences_location; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_geofences_location ON public.geofences USING btree (latitude, longitude);


--
-- TOC entry 3471 (class 1259 OID 24641)
-- Name: idx_geofences_status; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_geofences_status ON public.geofences USING btree (status);


--
-- TOC entry 3472 (class 1259 OID 24642)
-- Name: idx_geofences_type; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_geofences_type ON public.geofences USING btree (type);


--
-- TOC entry 3483 (class 1259 OID 24701)
-- Name: idx_notifications_created; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_notifications_created ON public.notifications USING btree (created_at DESC);


--
-- TOC entry 3484 (class 1259 OID 24697)
-- Name: idx_notifications_device; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_notifications_device ON public.notifications USING btree (device_id);


--
-- TOC entry 3485 (class 1259 OID 24698)
-- Name: idx_notifications_event; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_notifications_event ON public.notifications USING btree (event);


--
-- TOC entry 3486 (class 1259 OID 24700)
-- Name: idx_notifications_read; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_notifications_read ON public.notifications USING btree (read);


--
-- TOC entry 3487 (class 1259 OID 24699)
-- Name: idx_notifications_status; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_notifications_status ON public.notifications USING btree (status);


--
-- TOC entry 3473 (class 1259 OID 24655)
-- Name: idx_poi_states_device_poi; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_poi_states_device_poi ON public.poi_states USING btree (device_id, poi_id);


--
-- TOC entry 3458 (class 1259 OID 24620)
-- Name: idx_pois_device_id; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_pois_device_id ON public.pois USING btree (device_id);


--
-- TOC entry 3459 (class 1259 OID 24622)
-- Name: idx_pois_location; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_pois_location ON public.pois USING btree (latitude, longitude);


--
-- TOC entry 3460 (class 1259 OID 24621)
-- Name: idx_pois_status; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_pois_status ON public.pois USING btree (status);


--
-- TOC entry 3445 (class 1259 OID 16465)
-- Name: idx_users_cognito_sub; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX idx_users_cognito_sub ON public.users USING btree (cognito_sub);


--
-- TOC entry 3522 (class 2620 OID 24708)
-- Name: geofence_states update_geofence_states_timestamp; Type: TRIGGER; Schema: public; Owner: test
--

CREATE TRIGGER update_geofence_states_timestamp BEFORE UPDATE ON public.geofence_states FOR EACH ROW EXECUTE FUNCTION public.update_poi_state_timestamp();


--
-- TOC entry 3521 (class 2620 OID 24707)
-- Name: poi_states update_poi_states_timestamp; Type: TRIGGER; Schema: public; Owner: test
--

CREATE TRIGGER update_poi_states_timestamp BEFORE UPDATE ON public.poi_states FOR EACH ROW EXECUTE FUNCTION public.update_poi_state_timestamp();


--
-- TOC entry 3519 (class 2606 OID 16455)
-- Name: invitations invitations_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- TOC entry 3520 (class 2606 OID 16460)
-- Name: invitations invitations_invited_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_invited_by_user_id_fkey FOREIGN KEY (invited_by_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3516 (class 2606 OID 16422)
-- Name: units units_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- TOC entry 3518 (class 2606 OID 16438)
-- Name: user_units user_units_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.user_units
    ADD CONSTRAINT user_units_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id) ON DELETE CASCADE;


--
-- TOC entry 3517 (class 2606 OID 16433)
-- Name: user_units user_units_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.user_units
    ADD CONSTRAINT user_units_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3515 (class 2606 OID 16408)
-- Name: users users_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


-- Completed on 2025-09-28 21:15:46 CST

--
-- PostgreSQL database dump complete
--

\unrestrict Ypb1UDYxNrWRN2am94IikJNfuH10iiOfYvHru2H2UinkeHfUx7DCFLXp81EoCNV

