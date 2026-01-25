DO $$
DECLARE
  role_name text := 'content-workflow-service';
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = role_name) THEN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', role_name, role_name);
  END IF;
END $$;

DO $$
DECLARE
  db_name text := 'content-workflow-service';
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = db_name) THEN
    EXECUTE format('CREATE DATABASE %I OWNER %I', db_name, db_name);
  END IF;
END $$;

DO $$
DECLARE
  db_name text := 'content-workflow-service';
BEGIN
  EXECUTE format('GRANT ALL PRIVILEGES ON DATABASE %I TO %I', db_name, db_name);
END $$;


