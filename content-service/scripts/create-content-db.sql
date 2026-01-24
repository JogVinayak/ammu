DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'content_service') THEN
    CREATE ROLE content_service LOGIN PASSWORD 'content_service';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'content_service') THEN
    CREATE DATABASE content_service OWNER content_service;
  END IF;
END $$;

GRANT ALL PRIVILEGES ON DATABASE content_service TO content_service;
