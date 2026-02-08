-- Learner Microservices - Database Seed Script
-- This script creates all users and databases for the microservices platform
-- Run with: docker exec -i <postgres-container> psql -U <superuser> -d postgres -f seed.sql

-- ============================================================================
-- USERS
-- ============================================================================

-- Auth Service
DO $$ BEGIN
    CREATE USER auth_user WITH PASSWORD 'auth_password';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Tenant Service
DO $$ BEGIN
    CREATE USER tenant_user WITH PASSWORD 'tenant_password';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Role Permission Service
DO $$ BEGIN
    CREATE USER role_permission_user WITH PASSWORD 'role_permission_password';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- User Profile Service
DO $$ BEGIN
    CREATE USER user_profile_user WITH PASSWORD 'user_profile_password';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Content Service
DO $$ BEGIN
    CREATE USER content_service WITH PASSWORD 'content_service';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Content Workflow Service
DO $$ BEGIN
    CREATE USER content_workflow_service WITH PASSWORD 'content_workflow_service';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Mindmap Service
DO $$ BEGIN
    CREATE USER mindmap_user WITH PASSWORD 'mindmap_password';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Notes Service
DO $$ BEGIN
    CREATE USER notes_user WITH PASSWORD 'notes_password';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Graph Relations Service
DO $$ BEGIN
    CREATE USER graph_relations_user WITH PASSWORD 'graph_relations_password';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Recall Service
DO $$ BEGIN
    CREATE USER recall_user WITH PASSWORD 'recall_password';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- DATABASES
-- ============================================================================

-- Check and create databases (run separately or use IF NOT EXISTS in PG 9.1+)
SELECT 'CREATE DATABASE auth OWNER auth_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'auth')\gexec

SELECT 'CREATE DATABASE tenant OWNER tenant_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'tenant')\gexec

SELECT 'CREATE DATABASE role_permission OWNER role_permission_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'role_permission')\gexec

SELECT 'CREATE DATABASE user_profile OWNER user_profile_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'user_profile')\gexec

SELECT 'CREATE DATABASE content_service OWNER content_service'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'content_service')\gexec

SELECT 'CREATE DATABASE content_workflow_service OWNER content_workflow_service'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'content_workflow_service')\gexec

SELECT 'CREATE DATABASE mindmap OWNER mindmap_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'mindmap')\gexec

SELECT 'CREATE DATABASE notes OWNER notes_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'notes')\gexec

SELECT 'CREATE DATABASE graph_relations OWNER graph_relations_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'graph_relations')\gexec

SELECT 'CREATE DATABASE recall OWNER recall_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'recall')\gexec

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT ALL PRIVILEGES ON DATABASE auth TO auth_user;
GRANT ALL PRIVILEGES ON DATABASE tenant TO tenant_user;
GRANT ALL PRIVILEGES ON DATABASE role_permission TO role_permission_user;
GRANT ALL PRIVILEGES ON DATABASE user_profile TO user_profile_user;
GRANT ALL PRIVILEGES ON DATABASE content_service TO content_service;
GRANT ALL PRIVILEGES ON DATABASE content_workflow_service TO content_workflow_service;
GRANT ALL PRIVILEGES ON DATABASE mindmap TO mindmap_user;
GRANT ALL PRIVILEGES ON DATABASE notes TO notes_user;
GRANT ALL PRIVILEGES ON DATABASE graph_relations TO graph_relations_user;
GRANT ALL PRIVILEGES ON DATABASE recall TO recall_user;

-- ============================================================================
-- SERVICE CREDENTIALS SUMMARY
-- ============================================================================
--
-- | Service                   | Database                  | User                     | Password                  |
-- |---------------------------|---------------------------|--------------------------|---------------------------|
-- | auth-service              | auth                      | auth_user                | auth_password             |
-- | tenant-service            | tenant                    | tenant_user              | tenant_password           |
-- | role-permission-service   | role_permission           | role_permission_user     | role_permission_password  |
-- | user-profile-service      | user_profile              | user_profile_user        | user_profile_password     |
-- | content-service           | content_service           | content_service          | content_service           |
-- | content-workflow-service  | content_workflow_service  | content_workflow_service | content_workflow_service  |
-- | mindmap-service           | mindmap                   | mindmap_user             | mindmap_password          |
-- | notes-service             | notes                     | notes_user               | notes_password            |
-- | graph-relations-service   | graph_relations           | graph_relations_user     | graph_relations_password  |
-- | recall-service            | recall                    | recall_user              | recall_password           |
--
-- ============================================================================
