--
-- PostgreSQL database dump
--

-- Dumped from database version 10.5
-- Dumped by pg_dump version 11.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: signaturestore; Type: DATABASE; Schema: -; Owner: sigmaster
--

CREATE DATABASE signaturestore WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';


ALTER DATABASE signaturestore OWNER TO sigmaster;

\connect signaturestore

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: entities; Type: TABLE; Schema: public; Owner: sigmaster
--

CREATE TABLE public.entities (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    meta jsonb
);


ALTER TABLE public.entities OWNER TO sigmaster;

--
-- Name: entities_id_seq; Type: SEQUENCE; Schema: public; Owner: sigmaster
--

CREATE SEQUENCE public.entities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entities_id_seq OWNER TO sigmaster;

--
-- Name: entities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sigmaster
--

ALTER SEQUENCE public.entities_id_seq OWNED BY public.entities.id;


--
-- Name: libraries; Type: TABLE; Schema: public; Owner: sigmaster
--

CREATE TABLE public.libraries (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    meta jsonb,
    dataset character varying NOT NULL,
    "signature-keys" jsonb
);


ALTER TABLE public.libraries OWNER TO sigmaster;

--
-- Name: libraries_id_seq; Type: SEQUENCE; Schema: public; Owner: sigmaster
--

CREATE SEQUENCE public.libraries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.libraries_id_seq OWNER TO sigmaster;

--
-- Name: libraries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sigmaster
--

ALTER SEQUENCE public.libraries_id_seq OWNED BY public.libraries.id;


--
-- Name: signatures; Type: TABLE; Schema: public; Owner: sigmaster
--

CREATE TABLE public.signatures (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    libid uuid NOT NULL,
    meta jsonb,
    meta_tsvector tsvector
);


ALTER TABLE public.signatures OWNER TO sigmaster;

--
-- Name: signatures_id_seq; Type: SEQUENCE; Schema: public; Owner: sigmaster
--

CREATE SEQUENCE public.signatures_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.signatures_id_seq OWNER TO sigmaster;

--
-- Name: signatures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sigmaster
--

ALTER SEQUENCE public.signatures_id_seq OWNED BY public.signatures.id;


--
-- Name: entities id; Type: DEFAULT; Schema: public; Owner: sigmaster
--

ALTER TABLE ONLY public.entities ALTER COLUMN id SET DEFAULT nextval('public.entities_id_seq'::regclass);


--
-- Name: libraries id; Type: DEFAULT; Schema: public; Owner: sigmaster
--

ALTER TABLE ONLY public.libraries ALTER COLUMN id SET DEFAULT nextval('public.libraries_id_seq'::regclass);


--
-- Name: signatures id; Type: DEFAULT; Schema: public; Owner: sigmaster
--

ALTER TABLE ONLY public.signatures ALTER COLUMN id SET DEFAULT nextval('public.signatures_id_seq'::regclass);


--
-- Name: entities entities_pkey; Type: CONSTRAINT; Schema: public; Owner: sigmaster
--

ALTER TABLE ONLY public.entities
    ADD CONSTRAINT entities_pkey PRIMARY KEY (id);


--
-- Name: entities entities_uuid_key; Type: CONSTRAINT; Schema: public; Owner: sigmaster
--

ALTER TABLE ONLY public.entities
    ADD CONSTRAINT entities_uuid_key UNIQUE (uuid);


--
-- Name: libraries libraries_pkey; Type: CONSTRAINT; Schema: public; Owner: sigmaster
--

ALTER TABLE ONLY public.libraries
    ADD CONSTRAINT libraries_pkey PRIMARY KEY (id);


--
-- Name: libraries libraries_uuid_key; Type: CONSTRAINT; Schema: public; Owner: sigmaster
--

ALTER TABLE ONLY public.libraries
    ADD CONSTRAINT libraries_uuid_key UNIQUE (uuid);


--
-- Name: signatures signatures_pkey; Type: CONSTRAINT; Schema: public; Owner: sigmaster
--

ALTER TABLE ONLY public.signatures
    ADD CONSTRAINT signatures_pkey PRIMARY KEY (id);


--
-- Name: signatures signatures_uuid_key; Type: CONSTRAINT; Schema: public; Owner: sigmaster
--

ALTER TABLE ONLY public.signatures
    ADD CONSTRAINT signatures_uuid_key UNIQUE (uuid);


--
-- Name: library_resource; Type: INDEX; Schema: public; Owner: sigmaster
--

CREATE INDEX library_resource ON public.libraries USING btree (((meta ->> 'Primary Resource'::text)));


--
-- Name: meta_tsvector_idx; Type: INDEX; Schema: public; Owner: sigmaster
--

CREATE INDEX meta_tsvector_idx ON public.signatures USING gin (meta_tsvector);


--
-- Name: signature_assay; Type: INDEX; Schema: public; Owner: sigmaster
--

CREATE INDEX signature_assay ON public.signatures USING btree (((meta ->> 'Assay'::text)));


--
-- Name: signature_organism; Type: INDEX; Schema: public; Owner: sigmaster
--

CREATE INDEX signature_organism ON public.signatures USING btree (((meta ->> 'Organism'::text)));


--
-- Name: signature_perturbation; Type: INDEX; Schema: public; Owner: sigmaster
--

CREATE INDEX signature_perturbation ON public.signatures USING btree (((meta ->> 'Perturbation Type'::text)));


--
-- Name: signatures_fkey_library; Type: INDEX; Schema: public; Owner: sigmaster
--

CREATE INDEX signatures_fkey_library ON public.signatures USING btree (libid);


--
-- Name: signatures_to_tsvector_idx; Type: INDEX; Schema: public; Owner: sigmaster
--

CREATE INDEX signatures_to_tsvector_idx ON public.signatures USING gin (to_tsvector('english'::regconfig, (meta)::text));


--
-- Name: signatures_to_tsvector_idx1; Type: INDEX; Schema: public; Owner: sigmaster
--

CREATE INDEX signatures_to_tsvector_idx1 ON public.signatures USING gin (to_tsvector('english'::regconfig, meta));


--
-- Name: signatures_to_tsvector_idx2; Type: INDEX; Schema: public; Owner: sigmaster
--

CREATE INDEX signatures_to_tsvector_idx2 ON public.signatures USING gist (to_tsvector('english'::regconfig, (meta)::text));


--
-- Name: signatures signatures_libid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sigmaster
--

ALTER TABLE ONLY public.signatures
    ADD CONSTRAINT signatures_libid_fkey FOREIGN KEY (libid) REFERENCES public.libraries(uuid);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: sigmaster
--

GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

