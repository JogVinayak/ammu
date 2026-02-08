-- ============================================
-- Database Initialization Script
-- Learner Microservices Platform
-- ============================================

-- 1. Auth Service
CREATE ROLE auth_user LOGIN PASSWORD 'auth_password';
CREATE DATABASE auth OWNER auth_user;
GRANT ALL PRIVILEGES ON DATABASE auth TO auth_user;

-- 2. Tenant Service
CREATE ROLE tenant_user LOGIN PASSWORD 'tenant_password';
CREATE DATABASE tenant OWNER tenant_user;
GRANT ALL PRIVILEGES ON DATABASE tenant TO tenant_user;

-- 3. User Profile Service
CREATE ROLE user_profile_user LOGIN PASSWORD 'user_profile_password';
CREATE DATABASE user_profile OWNER user_profile_user;
GRANT ALL PRIVILEGES ON DATABASE user_profile TO user_profile_user;

-- 4. Role Permission Service
CREATE ROLE role_permission_user LOGIN PASSWORD 'role_permission_password';
CREATE DATABASE role_permission OWNER role_permission_user;
GRANT ALL PRIVILEGES ON DATABASE role_permission TO role_permission_user;

-- 5. Content Service
CREATE ROLE content_service LOGIN PASSWORD 'content_service';
CREATE DATABASE content_service OWNER content_service;
GRANT ALL PRIVILEGES ON DATABASE content_service TO content_service;

-- 6. Content Workflow Service
CREATE ROLE content_workflow_service LOGIN PASSWORD 'content_workflow_service';
CREATE DATABASE content_workflow_service OWNER content_workflow_service;
GRANT ALL PRIVILEGES ON DATABASE content_workflow_service TO content_workflow_service;

-- 7. Notes Service
CREATE ROLE notes_user LOGIN PASSWORD 'notes_password';
CREATE DATABASE notes OWNER notes_user;
GRANT ALL PRIVILEGES ON DATABASE notes TO notes_user;

-- 8. Mindmap Service
CREATE ROLE mindmap_user LOGIN PASSWORD 'mindmap_password';
CREATE DATABASE mindmap OWNER mindmap_user;
GRANT ALL PRIVILEGES ON DATABASE mindmap TO mindmap_user;

-- 9. Graph Relations Service
CREATE ROLE graph_relations_user LOGIN PASSWORD 'graph_relations_password';
CREATE DATABASE graph_relations OWNER graph_relations_user;
GRANT ALL PRIVILEGES ON DATABASE graph_relations TO graph_relations_user;

-- 10. Recall Service
CREATE ROLE recall_user LOGIN PASSWORD 'recall_password';
CREATE DATABASE recall OWNER recall_user;
GRANT ALL PRIVILEGES ON DATABASE recall TO recall_user;