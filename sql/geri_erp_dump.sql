--
-- PostgreSQL database dump
--

\restrict ItM1PAyAQ35BRNFMAV2C6dE6xL4ySSQBws4TQk7MuMKuImdclJxq2PkRZJaj57S

-- Dumped from database version 18.1 (Debian 18.1-1.pgdg13+2)
-- Dumped by pg_dump version 18.1 (Ubuntu 18.1-1.pgdg24.04+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE geri_erp;
--
-- Name: geri_erp; Type: DATABASE; Schema: -; Owner: geri_erp
--

CREATE DATABASE geri_erp WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE geri_erp OWNER TO geri_erp;

\unrestrict ItM1PAyAQ35BRNFMAV2C6dE6xL4ySSQBws4TQk7MuMKuImdclJxq2PkRZJaj57S
\connect geri_erp
\restrict ItM1PAyAQ35BRNFMAV2C6dE6xL4ySSQBws4TQk7MuMKuImdclJxq2PkRZJaj57S

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: BOM; Type: TABLE; Schema: public; Owner: geri_erp
--

CREATE TABLE public."BOM" (
    id bigint NOT NULL,
    name character varying,
    description character varying,
    securityid bigint DEFAULT 0 NOT NULL,
    revision bigint DEFAULT 1 NOT NULL,
    minor_rev bigint DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at date DEFAULT now() NOT NULL,
    updated_at date DEFAULT now() NOT NULL,
    deleted_at date
);


ALTER TABLE public."BOM" OWNER TO geri_erp;

--
-- Name: BOM_id_seq; Type: SEQUENCE; Schema: public; Owner: geri_erp
--

CREATE SEQUENCE public."BOM_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."BOM_id_seq" OWNER TO geri_erp;

--
-- Name: BOM_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geri_erp
--

ALTER SEQUENCE public."BOM_id_seq" OWNED BY public."BOM".id;


--
-- Name: cal_results; Type: TABLE; Schema: public; Owner: geri_erp
--

CREATE TABLE public.cal_results (
    id bigint NOT NULL,
    tool_id bigint,
    measurements character varying,
    tolerance character varying,
    pass boolean DEFAULT true NOT NULL,
    adjustments character varying,
    drift character varying,
    notes character varying
);


ALTER TABLE public.cal_results OWNER TO geri_erp;

--
-- Name: cal_results_id_seq; Type: SEQUENCE; Schema: public; Owner: geri_erp
--

CREATE SEQUENCE public.cal_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cal_results_id_seq OWNER TO geri_erp;

--
-- Name: cal_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geri_erp
--

ALTER SEQUENCE public.cal_results_id_seq OWNED BY public.cal_results.id;


--
-- Name: calibration_event; Type: TABLE; Schema: public; Owner: geri_erp
--

CREATE TABLE public.calibration_event (
    id bigint NOT NULL,
    event_ts timestamp with time zone DEFAULT now() NOT NULL,
    tech_id bigint NOT NULL,
    vendor_id bigint DEFAULT 0 NOT NULL,
    cal_cert_number character varying,
    cal_procedure bigint DEFAULT 0 NOT NULL,
    environment_cond bigint,
    cal_std_used bigint,
    tool bigint NOT NULL
);


ALTER TABLE public.calibration_event OWNER TO geri_erp;

--
-- Name: calibration_event_id_seq; Type: SEQUENCE; Schema: public; Owner: geri_erp
--

CREATE SEQUENCE public.calibration_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.calibration_event_id_seq OWNER TO geri_erp;

--
-- Name: calibration_event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geri_erp
--

ALTER SEQUENCE public.calibration_event_id_seq OWNED BY public.calibration_event.id;


--
-- Name: itemref; Type: TABLE; Schema: public; Owner: geri_erp
--

CREATE TABLE public.itemref (
    id bigint NOT NULL,
    parentid bigint NOT NULL,
    childid bigint,
    created_at date DEFAULT now() NOT NULL,
    updated_at date DEFAULT now() NOT NULL,
    deleted_at date
);


ALTER TABLE public.itemref OWNER TO geri_erp;

--
-- Name: itemref_id_seq; Type: SEQUENCE; Schema: public; Owner: geri_erp
--

CREATE SEQUENCE public.itemref_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.itemref_id_seq OWNER TO geri_erp;

--
-- Name: itemref_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geri_erp
--

ALTER SEQUENCE public.itemref_id_seq OWNED BY public.itemref.id;


--
-- Name: items; Type: TABLE; Schema: public; Owner: geri_erp
--

CREATE TABLE public.items (
    id bigint NOT NULL,
    bom_id bigint CONSTRAINT items_bom_not_null NOT NULL,
    type bigint NOT NULL,
    name character varying NOT NULL,
    description character varying NOT NULL,
    partnumber character varying NOT NULL,
    securityid bigint DEFAULT 0 NOT NULL,
    qty bigint DEFAULT 1 NOT NULL,
    drawingref character varying,
    gentag boolean DEFAULT false NOT NULL,
    units bigint NOT NULL,
    qtyreq numeric,
    waste numeric,
    wunits bigint,
    revision bigint DEFAULT 1 NOT NULL,
    minor_rev bigint DEFAULT 0 NOT NULL,
    created_at date DEFAULT now() NOT NULL,
    updated_at date DEFAULT now() NOT NULL,
    deleted_at date,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.items OWNER TO geri_erp;

--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: geri_erp
--

CREATE SEQUENCE public.items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.items_id_seq OWNER TO geri_erp;

--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geri_erp
--

ALTER SEQUENCE public.items_id_seq OWNED BY public.items.id;


--
-- Name: proctool; Type: TABLE; Schema: public; Owner: geri_erp
--

CREATE TABLE public.proctool (
    id bigint CONSTRAINT itemtool_id_not_null NOT NULL,
    proc_step bigint CONSTRAINT itemtool_item_id_not_null NOT NULL,
    tool_id bigint CONSTRAINT itemtool_tool_id_not_null NOT NULL
);


ALTER TABLE public.proctool OWNER TO geri_erp;

--
-- Name: itemtool_id_seq; Type: SEQUENCE; Schema: public; Owner: geri_erp
--

CREATE SEQUENCE public.itemtool_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.itemtool_id_seq OWNER TO geri_erp;

--
-- Name: itemtool_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geri_erp
--

ALTER SEQUENCE public.itemtool_id_seq OWNED BY public.proctool.id;


--
-- Name: itemtype; Type: TABLE; Schema: public; Owner: geri_erp
--

CREATE TABLE public.itemtype (
    id bigint NOT NULL,
    name character varying NOT NULL,
    description character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at date DEFAULT now() NOT NULL,
    updated_at date DEFAULT now() NOT NULL,
    delete_at date
);


ALTER TABLE public.itemtype OWNER TO geri_erp;

--
-- Name: itemtype_id_seq; Type: SEQUENCE; Schema: public; Owner: geri_erp
--

CREATE SEQUENCE public.itemtype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.itemtype_id_seq OWNER TO geri_erp;

--
-- Name: itemtype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geri_erp
--

ALTER SEQUENCE public.itemtype_id_seq OWNED BY public.itemtype.id;


--
-- Name: mfgprocess_hdr; Type: TABLE; Schema: public; Owner: geri_erp
--

CREATE TABLE public.mfgprocess_hdr (
    id bigint NOT NULL,
    name character varying,
    description character varying,
    primary_rev bigint DEFAULT 1 NOT NULL,
    minor_rev bigint DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at date DEFAULT now() NOT NULL,
    updated_at date DEFAULT now() NOT NULL,
    deleted_at date
);


ALTER TABLE public.mfgprocess_hdr OWNER TO geri_erp;

--
-- Name: mfgprocess_hdr_id_seq; Type: SEQUENCE; Schema: public; Owner: geri_erp
--

CREATE SEQUENCE public.mfgprocess_hdr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mfgprocess_hdr_id_seq OWNER TO geri_erp;

--
-- Name: mfgprocess_hdr_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geri_erp
--

ALTER SEQUENCE public.mfgprocess_hdr_id_seq OWNED BY public.mfgprocess_hdr.id;


--
-- Name: process_item; Type: TABLE; Schema: public; Owner: geri_erp
--

CREATE TABLE public.process_item (
    id bigint NOT NULL,
    description character varying NOT NULL,
    bom_item_ref bigint NOT NULL,
    est_hrs numeric DEFAULT 1.0 NOT NULL,
    avg_hrs numeric DEFAULT 1.0 NOT NULL,
    special_processing bigint,
    revision bigint DEFAULT 1 NOT NULL,
    minor_rev bigint DEFAULT 0 NOT NULL,
    created_at date DEFAULT now() NOT NULL,
    updated_at date DEFAULT now() NOT NULL,
    deleted_at date,
    standards_ref bigint,
    hdr_ref bigint NOT NULL,
    seq bigint
);


ALTER TABLE public.process_item OWNER TO geri_erp;

--
-- Name: process_item_id_seq; Type: SEQUENCE; Schema: public; Owner: geri_erp
--

CREATE SEQUENCE public.process_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.process_item_id_seq OWNER TO geri_erp;

--
-- Name: process_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geri_erp
--

ALTER SEQUENCE public.process_item_id_seq OWNED BY public.process_item.id;


--
-- Name: steps; Type: TABLE; Schema: public; Owner: geri_erp
--

CREATE TABLE public.steps (
    id bigint NOT NULL,
    item_ref bigint NOT NULL,
    step_seq bigint DEFAULT 1 NOT NULL
);


ALTER TABLE public.steps OWNER TO geri_erp;

--
-- Name: steps_id_seq; Type: SEQUENCE; Schema: public; Owner: geri_erp
--

CREATE SEQUENCE public.steps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.steps_id_seq OWNER TO geri_erp;

--
-- Name: steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geri_erp
--

ALTER SEQUENCE public.steps_id_seq OWNED BY public.steps.id;


--
-- Name: tool; Type: TABLE; Schema: public; Owner: geri_erp
--

CREATE TABLE public.tool (
    id bigint NOT NULL,
    name character varying,
    description character varying,
    calibration_req boolean DEFAULT false NOT NULL,
    created_at date DEFAULT now() NOT NULL,
    updated_at date DEFAULT now() NOT NULL,
    deleted_at date
);


ALTER TABLE public.tool OWNER TO geri_erp;

--
-- Name: tool_id_seq; Type: SEQUENCE; Schema: public; Owner: geri_erp
--

CREATE SEQUENCE public.tool_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tool_id_seq OWNER TO geri_erp;

--
-- Name: tool_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geri_erp
--

ALTER SEQUENCE public.tool_id_seq OWNED BY public.tool.id;


--
-- Name: tools; Type: TABLE; Schema: public; Owner: geri_erp
--

CREATE TABLE public.tools (
    id bigint NOT NULL,
    tool_ref bigint NOT NULL,
    asset_tag character varying,
    start_service date DEFAULT now() NOT NULL,
    serv_expire date,
    last_calibration date,
    active_use boolean DEFAULT false NOT NULL,
    checkout date,
    checkin date,
    created_at date DEFAULT now() NOT NULL,
    updated_at date DEFAULT now() NOT NULL,
    deleted_at date,
    service_removal bigint,
    mfg bigint NOT NULL,
    serial character varying,
    model character varying,
    location bigint NOT NULL,
    next_calibration date,
    cal_freq bigint,
    cal_freq_units bigint,
    last_cal bigint,
    cal_app bigint
);


ALTER TABLE public.tools OWNER TO geri_erp;

--
-- Name: tools_id_seq; Type: SEQUENCE; Schema: public; Owner: geri_erp
--

CREATE SEQUENCE public.tools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tools_id_seq OWNER TO geri_erp;

--
-- Name: tools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geri_erp
--

ALTER SEQUENCE public.tools_id_seq OWNED BY public.tools.id;


--
-- Name: vendor; Type: TABLE; Schema: public; Owner: geri_erp
--

CREATE TABLE public.vendor (
    id bigint NOT NULL,
    name character varying NOT NULL,
    address bigint NOT NULL,
    "primary" boolean DEFAULT false NOT NULL,
    preferred boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at date DEFAULT now() NOT NULL,
    updated_at date DEFAULT now() NOT NULL,
    deleted_at date
);


ALTER TABLE public.vendor OWNER TO geri_erp;

--
-- Name: vendor_id_seq; Type: SEQUENCE; Schema: public; Owner: geri_erp
--

CREATE SEQUENCE public.vendor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vendor_id_seq OWNER TO geri_erp;

--
-- Name: vendor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geri_erp
--

ALTER SEQUENCE public.vendor_id_seq OWNED BY public.vendor.id;


--
-- Name: vendorpart; Type: TABLE; Schema: public; Owner: geri_erp
--

CREATE TABLE public.vendorpart (
    id bigint NOT NULL,
    vendor bigint NOT NULL,
    partnum character varying NOT NULL,
    description character varying NOT NULL,
    preferred boolean DEFAULT false NOT NULL,
    refpart bigint NOT NULL,
    longlead boolean DEFAULT false NOT NULL,
    avglead numeric,
    minlead numeric,
    maxlead numeric,
    active boolean DEFAULT true NOT NULL,
    created_at date DEFAULT now() NOT NULL,
    updated_at date DEFAULT now() NOT NULL,
    deleted_at date
);


ALTER TABLE public.vendorpart OWNER TO geri_erp;

--
-- Name: vendorpart_id_seq; Type: SEQUENCE; Schema: public; Owner: geri_erp
--

CREATE SEQUENCE public.vendorpart_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vendorpart_id_seq OWNER TO geri_erp;

--
-- Name: vendorpart_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: geri_erp
--

ALTER SEQUENCE public.vendorpart_id_seq OWNED BY public.vendorpart.id;


--
-- Name: BOM id; Type: DEFAULT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public."BOM" ALTER COLUMN id SET DEFAULT nextval('public."BOM_id_seq"'::regclass);


--
-- Name: cal_results id; Type: DEFAULT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.cal_results ALTER COLUMN id SET DEFAULT nextval('public.cal_results_id_seq'::regclass);


--
-- Name: calibration_event id; Type: DEFAULT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.calibration_event ALTER COLUMN id SET DEFAULT nextval('public.calibration_event_id_seq'::regclass);


--
-- Name: itemref id; Type: DEFAULT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.itemref ALTER COLUMN id SET DEFAULT nextval('public.itemref_id_seq'::regclass);


--
-- Name: items id; Type: DEFAULT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.items ALTER COLUMN id SET DEFAULT nextval('public.items_id_seq'::regclass);


--
-- Name: itemtype id; Type: DEFAULT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.itemtype ALTER COLUMN id SET DEFAULT nextval('public.itemtype_id_seq'::regclass);


--
-- Name: mfgprocess_hdr id; Type: DEFAULT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.mfgprocess_hdr ALTER COLUMN id SET DEFAULT nextval('public.mfgprocess_hdr_id_seq'::regclass);


--
-- Name: process_item id; Type: DEFAULT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.process_item ALTER COLUMN id SET DEFAULT nextval('public.process_item_id_seq'::regclass);


--
-- Name: proctool id; Type: DEFAULT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.proctool ALTER COLUMN id SET DEFAULT nextval('public.itemtool_id_seq'::regclass);


--
-- Name: steps id; Type: DEFAULT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.steps ALTER COLUMN id SET DEFAULT nextval('public.steps_id_seq'::regclass);


--
-- Name: tool id; Type: DEFAULT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.tool ALTER COLUMN id SET DEFAULT nextval('public.tool_id_seq'::regclass);


--
-- Name: tools id; Type: DEFAULT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.tools ALTER COLUMN id SET DEFAULT nextval('public.tools_id_seq'::regclass);


--
-- Name: vendor id; Type: DEFAULT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.vendor ALTER COLUMN id SET DEFAULT nextval('public.vendor_id_seq'::regclass);


--
-- Name: vendorpart id; Type: DEFAULT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.vendorpart ALTER COLUMN id SET DEFAULT nextval('public.vendorpart_id_seq'::regclass);


--
-- Data for Name: BOM; Type: TABLE DATA; Schema: public; Owner: geri_erp
--

COPY public."BOM" (id, name, description, securityid, revision, minor_rev, active, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: cal_results; Type: TABLE DATA; Schema: public; Owner: geri_erp
--

COPY public.cal_results (id, tool_id, measurements, tolerance, pass, adjustments, drift, notes) FROM stdin;
\.


--
-- Data for Name: calibration_event; Type: TABLE DATA; Schema: public; Owner: geri_erp
--

COPY public.calibration_event (id, event_ts, tech_id, vendor_id, cal_cert_number, cal_procedure, environment_cond, cal_std_used, tool) FROM stdin;
\.


--
-- Data for Name: itemref; Type: TABLE DATA; Schema: public; Owner: geri_erp
--

COPY public.itemref (id, parentid, childid, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: geri_erp
--

COPY public.items (id, bom_id, type, name, description, partnumber, securityid, qty, drawingref, gentag, units, qtyreq, waste, wunits, revision, minor_rev, created_at, updated_at, deleted_at, active) FROM stdin;
\.


--
-- Data for Name: itemtype; Type: TABLE DATA; Schema: public; Owner: geri_erp
--

COPY public.itemtype (id, name, description, active, created_at, updated_at, delete_at) FROM stdin;
1	assembly	Top level assembly	t	2025-11-23	2025-11-23	\N
2	subassy	Sub assembly	t	2025-11-23	2025-11-23	\N
5	vassy	Vendor Assembly	t	2025-11-23	2025-11-23	\N
3	component	Component	t	2025-11-23	2025-11-23	\N
4	scomponent	Sub compnent	t	2025-11-23	2025-11-23	\N
6	3d	3D Printed part	t	2025-11-23	2025-11-23	\N
\.


--
-- Data for Name: mfgprocess_hdr; Type: TABLE DATA; Schema: public; Owner: geri_erp
--

COPY public.mfgprocess_hdr (id, name, description, primary_rev, minor_rev, active, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: process_item; Type: TABLE DATA; Schema: public; Owner: geri_erp
--

COPY public.process_item (id, description, bom_item_ref, est_hrs, avg_hrs, special_processing, revision, minor_rev, created_at, updated_at, deleted_at, standards_ref, hdr_ref, seq) FROM stdin;
\.


--
-- Data for Name: proctool; Type: TABLE DATA; Schema: public; Owner: geri_erp
--

COPY public.proctool (id, proc_step, tool_id) FROM stdin;
\.


--
-- Data for Name: steps; Type: TABLE DATA; Schema: public; Owner: geri_erp
--

COPY public.steps (id, item_ref, step_seq) FROM stdin;
\.


--
-- Data for Name: tool; Type: TABLE DATA; Schema: public; Owner: geri_erp
--

COPY public.tool (id, name, description, calibration_req, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: tools; Type: TABLE DATA; Schema: public; Owner: geri_erp
--

COPY public.tools (id, tool_ref, asset_tag, start_service, serv_expire, last_calibration, active_use, checkout, checkin, created_at, updated_at, deleted_at, service_removal, mfg, serial, model, location, next_calibration, cal_freq, cal_freq_units, last_cal, cal_app) FROM stdin;
\.


--
-- Data for Name: vendor; Type: TABLE DATA; Schema: public; Owner: geri_erp
--

COPY public.vendor (id, name, address, "primary", preferred, active, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: vendorpart; Type: TABLE DATA; Schema: public; Owner: geri_erp
--

COPY public.vendorpart (id, vendor, partnum, description, preferred, refpart, longlead, avglead, minlead, maxlead, active, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Name: BOM_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geri_erp
--

SELECT pg_catalog.setval('public."BOM_id_seq"', 1, false);


--
-- Name: cal_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geri_erp
--

SELECT pg_catalog.setval('public.cal_results_id_seq', 1, false);


--
-- Name: calibration_event_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geri_erp
--

SELECT pg_catalog.setval('public.calibration_event_id_seq', 1, false);


--
-- Name: itemref_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geri_erp
--

SELECT pg_catalog.setval('public.itemref_id_seq', 1, false);


--
-- Name: items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geri_erp
--

SELECT pg_catalog.setval('public.items_id_seq', 1, false);


--
-- Name: itemtool_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geri_erp
--

SELECT pg_catalog.setval('public.itemtool_id_seq', 1, false);


--
-- Name: itemtype_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geri_erp
--

SELECT pg_catalog.setval('public.itemtype_id_seq', 6, true);


--
-- Name: mfgprocess_hdr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geri_erp
--

SELECT pg_catalog.setval('public.mfgprocess_hdr_id_seq', 1, false);


--
-- Name: process_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geri_erp
--

SELECT pg_catalog.setval('public.process_item_id_seq', 1, false);


--
-- Name: steps_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geri_erp
--

SELECT pg_catalog.setval('public.steps_id_seq', 1, false);


--
-- Name: tool_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geri_erp
--

SELECT pg_catalog.setval('public.tool_id_seq', 1, false);


--
-- Name: tools_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geri_erp
--

SELECT pg_catalog.setval('public.tools_id_seq', 1, false);


--
-- Name: vendor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geri_erp
--

SELECT pg_catalog.setval('public.vendor_id_seq', 1, false);


--
-- Name: vendorpart_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geri_erp
--

SELECT pg_catalog.setval('public.vendorpart_id_seq', 1, false);


--
-- Name: cal_results cal_results_pk; Type: CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.cal_results
    ADD CONSTRAINT cal_results_pk PRIMARY KEY (id);


--
-- Name: calibration_event calibration_pk; Type: CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.calibration_event
    ADD CONSTRAINT calibration_pk PRIMARY KEY (id);


--
-- Name: itemref itemref_pk; Type: CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.itemref
    ADD CONSTRAINT itemref_pk PRIMARY KEY (id);


--
-- Name: items items_unique; Type: CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_unique UNIQUE (id);


--
-- Name: proctool itemtool_pk; Type: CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.proctool
    ADD CONSTRAINT itemtool_pk PRIMARY KEY (id);


--
-- Name: itemtype itemtype_pk; Type: CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.itemtype
    ADD CONSTRAINT itemtype_pk PRIMARY KEY (id);


--
-- Name: mfgprocess_hdr mfgprocess_hdr_pk; Type: CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.mfgprocess_hdr
    ADD CONSTRAINT mfgprocess_hdr_pk PRIMARY KEY (id);


--
-- Name: process_item process_item_pk; Type: CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.process_item
    ADD CONSTRAINT process_item_pk PRIMARY KEY (id);


--
-- Name: steps steps_pk; Type: CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.steps
    ADD CONSTRAINT steps_pk PRIMARY KEY (id);


--
-- Name: tool tool_pk; Type: CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.tool
    ADD CONSTRAINT tool_pk PRIMARY KEY (id);


--
-- Name: tools tools_pk; Type: CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.tools
    ADD CONSTRAINT tools_pk PRIMARY KEY (id);


--
-- Name: vendor vendor_pk; Type: CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.vendor
    ADD CONSTRAINT vendor_pk PRIMARY KEY (id);


--
-- Name: vendorpart vendorpart_pk; Type: CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.vendorpart
    ADD CONSTRAINT vendorpart_pk PRIMARY KEY (id);


--
-- Name: bom_id_idx; Type: INDEX; Schema: public; Owner: geri_erp
--

CREATE UNIQUE INDEX bom_id_idx ON public."BOM" USING btree (id);


--
-- Name: bom_name_idx; Type: INDEX; Schema: public; Owner: geri_erp
--

CREATE INDEX bom_name_idx ON public."BOM" USING btree (name);


--
-- Name: itemref_parentid_idx; Type: INDEX; Schema: public; Owner: geri_erp
--

CREATE INDEX itemref_parentid_idx ON public.itemref USING btree (parentid);


--
-- Name: items_id_idx; Type: INDEX; Schema: public; Owner: geri_erp
--

CREATE INDEX items_id_idx ON public.items USING btree (id);


--
-- Name: vendor_name_idx; Type: INDEX; Schema: public; Owner: geri_erp
--

CREATE INDEX vendor_name_idx ON public.vendor USING btree (name);


--
-- Name: cal_results cal_results_tools_fk; Type: FK CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.cal_results
    ADD CONSTRAINT cal_results_tools_fk FOREIGN KEY (tool_id) REFERENCES public.tools(id);


--
-- Name: calibration_event calibration_event_tools_fk; Type: FK CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.calibration_event
    ADD CONSTRAINT calibration_event_tools_fk FOREIGN KEY (tool) REFERENCES public.tools(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: itemref itemref_items_fk; Type: FK CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.itemref
    ADD CONSTRAINT itemref_items_fk FOREIGN KEY (parentid) REFERENCES public.items(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: itemref itemref_items_fk_1; Type: FK CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.itemref
    ADD CONSTRAINT itemref_items_fk_1 FOREIGN KEY (childid) REFERENCES public.items(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: items items_bom_fk; Type: FK CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_bom_fk FOREIGN KEY (bom_id) REFERENCES public."BOM"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: items items_itemtype_fk; Type: FK CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_itemtype_fk FOREIGN KEY (type) REFERENCES public.itemtype(id);


--
-- Name: process_item process_item_items_fk; Type: FK CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.process_item
    ADD CONSTRAINT process_item_items_fk FOREIGN KEY (bom_item_ref) REFERENCES public.items(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: process_item process_item_mfgprocess_hdr_fk; Type: FK CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.process_item
    ADD CONSTRAINT process_item_mfgprocess_hdr_fk FOREIGN KEY (hdr_ref) REFERENCES public.mfgprocess_hdr(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: proctool proctool_process_item_fk; Type: FK CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.proctool
    ADD CONSTRAINT proctool_process_item_fk FOREIGN KEY (proc_step) REFERENCES public.process_item(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: proctool proctool_tool_fk; Type: FK CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.proctool
    ADD CONSTRAINT proctool_tool_fk FOREIGN KEY (tool_id) REFERENCES public.tool(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tools tools_tool_fk; Type: FK CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.tools
    ADD CONSTRAINT tools_tool_fk FOREIGN KEY (tool_ref) REFERENCES public.tool(id);


--
-- Name: vendorpart vendorpart_items_fk; Type: FK CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.vendorpart
    ADD CONSTRAINT vendorpart_items_fk FOREIGN KEY (refpart) REFERENCES public.items(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: vendorpart vendorpart_vendor_fk; Type: FK CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.vendorpart
    ADD CONSTRAINT vendorpart_vendor_fk FOREIGN KEY (vendor) REFERENCES public.vendor(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict ItM1PAyAQ35BRNFMAV2C6dE6xL4ySSQBws4TQk7MuMKuImdclJxq2PkRZJaj57S

