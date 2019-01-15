--
-- PostgreSQL database dump
--

-- Dumped from database version 10.5
-- Dumped by pg_dump version 10.3

SET statement_timeout
= 0;
SET lock_timeout
= 0;
SET idle_in_transaction_session_timeout
= 0;
SET client_encoding
= 'UTF8';
SET standard_conforming_strings
= on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies
= false;
SET client_min_messages
= warning;
SET row_security
= off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION
IF NOT EXISTS plpgsql
WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET default_tablespace
= '';

SET default_with_oids
= false;


--
-- Name: entities; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.entities
(
    id integer NOT NULL,
    uuid uuid NOT NULL,
    meta jsonb
);


ALTER TABLE public.entities OWNER TO root;

--
-- Name: entities_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.entities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entities_id_seq OWNER TO root;

--
-- Name: entities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.entities_id_seq
OWNED BY public.entities.id;


--
-- Name: libraries; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.libraries
(
    id integer NOT NULL,
    uuid uuid NOT NULL,
    meta jsonb
);


ALTER TABLE public.libraries OWNER TO root;

--
-- Name: libraries_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.libraries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.libraries_id_seq OWNER TO root;

--
-- Name: libraries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.libraries_id_seq
OWNED BY public.libraries.id;


--
-- Name: signatures; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.signatures
(
    id integer NOT NULL,
    uuid uuid NOT NULL,
    libid uuid NOT NULL,
    meta jsonb
);


ALTER TABLE public.signatures OWNER TO root;

--
-- Name: signatures_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.signatures_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.signatures_id_seq OWNER TO root;

--
-- Name: signatures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.signatures_id_seq
OWNED BY public.signatures.id;


--
-- Name: entities id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.entities
ALTER COLUMN id
SET
DEFAULT nextval
('public.entities_id_seq'::regclass);


--
-- Name: libraries id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.libraries
ALTER COLUMN id
SET
DEFAULT nextval
('public.libraries_id_seq'::regclass);


--
-- Name: signatures id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.signatures
ALTER COLUMN id
SET
DEFAULT nextval
('public.signatures_id_seq'::regclass);


--
-- Name: entities entities_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.entities
ADD CONSTRAINT entities_pkey PRIMARY KEY
(id);


--
-- Name: entities entities_uuid_key; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.entities
ADD CONSTRAINT entities_uuid_key UNIQUE
(uuid);


--
-- Name: libraries libraries_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.libraries
ADD CONSTRAINT libraries_pkey PRIMARY KEY
(id);


--
-- Name: libraries libraries_uuid_key; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.libraries
ADD CONSTRAINT libraries_uuid_key UNIQUE
(uuid);


--
-- Name: signatures signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.signatures
ADD CONSTRAINT signatures_pkey PRIMARY KEY
(id);


--
-- Name: signatures signatures_uuid_key; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.signatures
ADD CONSTRAINT signatures_uuid_key UNIQUE
(uuid);


--
-- Name: signatures signatures_libid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.signatures
ADD CONSTRAINT signatures_libid_fkey FOREIGN KEY
(libid) REFERENCES public.libraries
(uuid);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: root
--

GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

