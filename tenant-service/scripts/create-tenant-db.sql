DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'tenant_user') THEN
    CREATE ROLE tenant_user LOGIN PASSWORD 'tenant_password';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'tenant') THEN
    CREATE DATABASE tenant OWNER tenant_user;
  END IF;
END $$;

GRANT ALL PRIVILEGES ON DATABASE tenant TO tenant_user;
