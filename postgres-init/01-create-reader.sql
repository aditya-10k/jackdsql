-- PostgreSQL 15+ requires explicit ownership/grants on the public schema
ALTER SCHEMA public OWNER TO postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT CREATE ON SCHEMA public TO postgres;

-- Create the sandbox user for read-only query execution
CREATE USER jackdsql_reader WITH PASSWORD 'readonly_password123';
GRANT CONNECT ON DATABASE jackdsql_db TO jackdsql_reader;

-- Allow jackdsql_reader to create temporary schemas for sandboxed execution
GRANT CREATE ON DATABASE jackdsql_db TO jackdsql_reader;

GRANT USAGE ON SCHEMA public TO jackdsql_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO jackdsql_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO jackdsql_reader;