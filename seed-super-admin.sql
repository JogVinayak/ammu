-- Learner Microservices - Super Admin Seed Script
-- This script creates the SYSTEM tenant and initial Super Admin user
-- Run this AFTER the services have created their tables via Liquibase migrations

-- ============================================================================
-- FIXED UUIDs (for consistency across services)
-- ============================================================================
-- System Tenant ID: 00000000-0000-0000-0000-000000000001
-- Super Admin User ID: 00000000-0000-0000-0000-000000000100

-- ============================================================================
-- 1. CREATE SYSTEM TENANT (run against tenant database)
-- ============================================================================
-- Connect to tenant database first: \c tenant

INSERT INTO tenants (id, tenant_key, name, status, created_at, updated_at, version)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'system',
    'System Administration',
    'ACTIVE',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    0
) ON CONFLICT (id) DO NOTHING;

INSERT INTO tenant_policies (id, tenant_id, allow_self_signup, require_admin_approval, allowed_auth_methods, session_max_days, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000001',
    false,
    false,
    '["PASSWORD"]',
    30,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (tenant_id) DO NOTHING;

-- ============================================================================
-- 2. CREATE SUPER ADMIN USER IDENTITY (run against auth database)
-- ============================================================================
-- Connect to auth database: \c auth
-- Password: SuperAdmin@123 (BCrypt hash below)

INSERT INTO user_identities (id, primary_email, email_verified, phone_verified, password_hash, status, created_at, updated_at, failed_login_count)
VALUES (
    '00000000-0000-0000-0000-000000000100',
    'superadmin@learner.platform',
    true,
    false,
    '$2a$10$N9qo8uLOickgx2ZMRZoMy.MqrO0xFFJgFm2.D.QLBqzqzBz3g1g6e', -- SuperAdmin@123
    'ACTIVE',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    0
) ON CONFLICT (id) DO NOTHING;

INSERT INTO tenant_memberships (id, tenant_id, user_id, status, join_method, created_at)
VALUES (
    '00000000-0000-0000-0000-000000000101',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000100',
    'ACTIVE',
    'DIRECT',
    CURRENT_TIMESTAMP
) ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 3. CREATE SUPER ADMIN USER PROFILE (run against user_profile database)
-- ============================================================================
-- Connect to user_profile database: \c user_profile

INSERT INTO user_profiles (id, tenant_id, user_id, display_name, first_name, last_name, email, user_type, status, created_at, updated_at, version)
VALUES (
    '00000000-0000-0000-0000-000000000102',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000100',
    'Super Admin',
    'Super',
    'Admin',
    'superadmin@learner.platform',
    'SUPER_ADMIN',
    'ACTIVE',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    0
) ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- SUPER ADMIN CREDENTIALS
-- ============================================================================
--
-- Email: superadmin@learner.platform
-- Password: SuperAdmin@123
--
-- IMPORTANT: Change this password after first login!
-- ============================================================================
