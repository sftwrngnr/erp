--
-- PostgreSQL database dump
--

\restrict kkXNkqnVdpPXrUAdSHURUhF1lN7jo4lVdacez07kJgt1m9D4z32LKaEFGbFzMza

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

\unrestrict kkXNkqnVdpPXrUAdSHURUhF1lN7jo4lVdacez07kJgt1m9D4z32LKaEFGbFzMza
\connect geri_erp
\restrict kkXNkqnVdpPXrUAdSHURUhF1lN7jo4lVdacez07kJgt1m9D4z32LKaEFGbFzMza

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
-- Name: proctool id; Type: DEFAULT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.proctool ALTER COLUMN id SET DEFAULT nextval('public.itemtool_id_seq'::regclass);


--
-- Data for Name: proctool; Type: TABLE DATA; Schema: public; Owner: geri_erp
--

COPY public.proctool (id, proc_step, tool_id) FROM stdin;
\.


--
-- Name: itemtool_id_seq; Type: SEQUENCE SET; Schema: public; Owner: geri_erp
--

SELECT pg_catalog.setval('public.itemtool_id_seq', 1, false);


--
-- Name: proctool itemtool_pk; Type: CONSTRAINT; Schema: public; Owner: geri_erp
--

ALTER TABLE ONLY public.proctool
    ADD CONSTRAINT itemtool_pk PRIMARY KEY (id);


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
-- PostgreSQL database dump complete
--

\unrestrict kkXNkqnVdpPXrUAdSHURUhF1lN7jo4lVdacez07kJgt1m9D4z32LKaEFGbFzMza

