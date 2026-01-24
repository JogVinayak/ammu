DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'auth_user') THEN
    CREATE ROLE auth_user LOGIN PASSWORD 'auth_password';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'auth') THEN
    CREATE DATABASE auth OWNER auth_user;
  END IF;
END $$;

GRANT ALL PRIVILEGES ON DATABASE auth TO auth_user;
