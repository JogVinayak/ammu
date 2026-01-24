DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'user_profile_user') THEN
    CREATE ROLE user_profile_user LOGIN PASSWORD 'user_profile_password';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'user_profile') THEN
    CREATE DATABASE user_profile OWNER user_profile_user;
  END IF;
END $$;

GRANT ALL PRIVILEGES ON DATABASE user_profile TO user_profile_user;
