-- Brain System - Single PostgreSQL instance, multiple databases
-- Container: brain-postgres | Port: 5433 (host) → 5432 (container)

-- Create databases for all microservices
CREATE DATABASE brain_auth;
CREATE DATABASE brain_tenant;
CREATE DATABASE brain_profile;
CREATE DATABASE brain_permission;
CREATE DATABASE brain_content;
CREATE DATABASE brain_workflow;
CREATE DATABASE brain_graph;
CREATE DATABASE brain_mindmap;
CREATE DATABASE brain_notes;
CREATE DATABASE brain_recall;
