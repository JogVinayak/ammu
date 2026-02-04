-- Create users for all microservices
CREATE USER auth_service WITH PASSWORD 'auth_service';
CREATE USER tenant_service WITH PASSWORD 'tenant_service';
CREATE USER user_profile_user WITH PASSWORD 'user_profile_password';
CREATE USER role_permission_service WITH PASSWORD 'role_permission_service';
CREATE USER content_service WITH PASSWORD 'content_service';
CREATE USER content_workflow_service WITH PASSWORD 'content_workflow_service';
CREATE USER graph_relations_service WITH PASSWORD 'graph_relations_service';
CREATE USER mindmap_service WITH PASSWORD 'mindmap_service';
CREATE USER notes_service WITH PASSWORD 'notes_service';
CREATE USER recall_service WITH PASSWORD 'recall_service';

-- Create databases for all microservices
CREATE DATABASE auth_service;
CREATE DATABASE tenant_service;
CREATE DATABASE user_profile;
CREATE DATABASE role_permission_service;
CREATE DATABASE content_service;
CREATE DATABASE content_workflow_service;
CREATE DATABASE graph_relations_service;
CREATE DATABASE mindmap_service;
CREATE DATABASE notes_service;
CREATE DATABASE recall_service;

-- Grant privileges to users on their respective databases
GRANT ALL PRIVILEGES ON DATABASE auth_service TO auth_service;
GRANT ALL PRIVILEGES ON DATABASE tenant_service TO tenant_service;
GRANT ALL PRIVILEGES ON DATABASE user_profile TO user_profile_user;
GRANT ALL PRIVILEGES ON DATABASE role_permission_service TO role_permission_service;
GRANT ALL PRIVILEGES ON DATABASE content_service TO content_service;
GRANT ALL PRIVILEGES ON DATABASE content_workflow_service TO content_workflow_service;
GRANT ALL PRIVILEGES ON DATABASE graph_relations_service TO graph_relations_service;
GRANT ALL PRIVILEGES ON DATABASE mindmap_service TO mindmap_service;
GRANT ALL PRIVILEGES ON DATABASE notes_service TO notes_service;
GRANT ALL PRIVILEGES ON DATABASE recall_service TO recall_service;

-- Connect to each database and grant schema privileges
\c auth_service
GRANT ALL ON SCHEMA public TO auth_service;

\c tenant_service
GRANT ALL ON SCHEMA public TO tenant_service;

\c user_profile
GRANT ALL ON SCHEMA public TO user_profile_user;

\c role_permission_service
GRANT ALL ON SCHEMA public TO role_permission_service;

\c content_service
GRANT ALL ON SCHEMA public TO content_service;

\c content_workflow_service
GRANT ALL ON SCHEMA public TO content_workflow_service;

\c graph_relations_service
GRANT ALL ON SCHEMA public TO graph_relations_service;

\c mindmap_service
GRANT ALL ON SCHEMA public TO mindmap_service;

\c notes_service
GRANT ALL ON SCHEMA public TO notes_service;

\c recall_service
GRANT ALL ON SCHEMA public TO recall_service;
