-- Create users for all microservices (using the same credentials as individual docker-compose files)
CREATE USER auth_user WITH PASSWORD 'auth_password';
CREATE USER tenant_user WITH PASSWORD 'tenant_password';
CREATE USER user_profile_user WITH PASSWORD 'user_profile_password';
CREATE USER role_permission_user WITH PASSWORD 'role_permission_password';
CREATE USER content_service WITH PASSWORD 'content_service';
CREATE USER content_workflow_service WITH PASSWORD 'content_workflow_service';
CREATE USER graph_relations_user WITH PASSWORD 'graph_relations_password';
CREATE USER mindmap_user WITH PASSWORD 'mindmap_password';
CREATE USER notes_user WITH PASSWORD 'notes_password';
CREATE USER recall_service WITH PASSWORD 'recall_service';

-- Create databases for all microservices
CREATE DATABASE auth;
CREATE DATABASE tenant;
CREATE DATABASE user_profile;
CREATE DATABASE role_permission;
CREATE DATABASE content_service;
CREATE DATABASE content_workflow_service;
CREATE DATABASE graph_relations;
CREATE DATABASE mindmap;
CREATE DATABASE notes;
CREATE DATABASE recall_service;

-- Grant privileges to users on their respective databases
GRANT ALL PRIVILEGES ON DATABASE auth TO auth_user;
GRANT ALL PRIVILEGES ON DATABASE tenant TO tenant_user;
GRANT ALL PRIVILEGES ON DATABASE user_profile TO user_profile_user;
GRANT ALL PRIVILEGES ON DATABASE role_permission TO role_permission_user;
GRANT ALL PRIVILEGES ON DATABASE content_service TO content_service;
GRANT ALL PRIVILEGES ON DATABASE content_workflow_service TO content_workflow_service;
GRANT ALL PRIVILEGES ON DATABASE graph_relations TO graph_relations_user;
GRANT ALL PRIVILEGES ON DATABASE mindmap TO mindmap_user;
GRANT ALL PRIVILEGES ON DATABASE notes TO notes_user;
GRANT ALL PRIVILEGES ON DATABASE recall_service TO recall_service;

-- Connect to each database and grant schema privileges
\c auth
GRANT ALL ON SCHEMA public TO auth_user;

\c tenant
GRANT ALL ON SCHEMA public TO tenant_user;

\c user_profile
GRANT ALL ON SCHEMA public TO user_profile_user;

\c role_permission
GRANT ALL ON SCHEMA public TO role_permission_user;

\c content_service
GRANT ALL ON SCHEMA public TO content_service;

\c content_workflow_service
GRANT ALL ON SCHEMA public TO content_workflow_service;

\c graph_relations
GRANT ALL ON SCHEMA public TO graph_relations_user;

\c mindmap
GRANT ALL ON SCHEMA public TO mindmap_user;

\c notes
GRANT ALL ON SCHEMA public TO notes_user;

\c recall_service
GRANT ALL ON SCHEMA public TO recall_service;
