plugins {
    id 'java'
    id 'org.springframework.boot' version '4.0.1'
    id 'io.spring.dependency-management' version '1.1.7'
}

group = 'com.learning'
version = '0.0.1-SNAPSHOT'
description = 'tenant-service'

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(25)
    }
}

repositories {
    mavenCentral()
}

dependencies {
    // REST APIs
    implementation 'org.springframework.boot:spring-boot-starter-web'

    // Validation annotations like @NotBlank, @Valid
    implementation 'org.springframework.boot:spring-boot-starter-validation'

    // JPA + Hibernate
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'

    // Postgres driver
    runtimeOnly 'org.postgresql:postgresql'

    // DB migrations
    implementation 'org.flywaydb:flyway-core'

    // Observability / health
    implementation 'org.springframework.boot:spring-boot-starter-actuator'

    // Optional but common
    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'

    testImplementation 'org.springframework.boot:spring-boot-starter-test'
}

tasks.named('test') {
    useJUnitPlatform()
}
# tenant-service — Context File (Amogh Project) — Spring Boot + Postgres

## 0) Stack & Conventions
- Language/Framework: **Java 21+**, **Spring Boot 3.x**
- Persistence: **Spring Data JPA (Hibernate)** + **PostgreSQL**
- Migrations: **Flyway** (preferred) or Liquibase
- API Style: REST + JSON, versioned under `/v1`
- AuthN/AuthZ: via **api-gateway** JWT validation; tenant-service enforces admin-only mutations using roles/claims
- Multi-tenancy: **tenantId is mandatory in persisted data**; in dev you may default to `tenant_default` but DB must keep `tenant_id` columns where relevant.

---

## 1) Purpose
`tenant-service` is the **source of truth for tenants** (schools/tuition orgs) in Amogh.
It provides:
- Tenant creation and lifecycle management
- Tenant identification (tenantKey, hostname/domain mapping)
- Tenant-level policies (auth methods, approval requirements, signup rules)
- Branding (name/logo/theme tokens)
- Plan/limits (optional in MVP)

This enables tenant isolation across all other services.

---

## 2) Responsibilities
### Does
- Create/update/suspend/activate tenants
- Manage unique `tenantKey`
- Resolve tenant from `tenantKey` or `hostname`
- Store & serve tenant policies and branding
- Emit lifecycle events (optional: outbox pattern)

### Does NOT
- Authentication (auth-service)
- Authorization rules and assignments (role-permission-service)
- User profiles (user-profile-service)
- Learning content/maps/recall logic

---

## 3) Domain Model (POJOs / JPA Entities)

### 3.1 Tenant
**Table:** `tenants`
Fields:
- `UUID id` (PK)
- `String tenantKey` (unique, stable)
- `String name`
- `TenantStatus status` = `ACTIVE|SUSPENDED|DELETED`
- `Instant createdAt`, `String createdBy`
- `Instant updatedAt`, `String updatedBy`

Notes:
- `tenantKey` used in URLs/subdomains; must be immutable after creation (recommended).
- Use `@Version long version` for optimistic locking (recommended).

### 3.2 TenantPolicy
**Table:** `tenant_policies` (1:1 with tenant)
Fields:
- `UUID id` (PK)
- `UUID tenantId` (FK unique)
- `boolean allowSelfSignup`
- `boolean requireAdminApproval`
- `Set<AuthMethod> allowedAuthMethods` (PASSWORD, OTP_SMS, OTP_EMAIL)
- `String allowedSignupDomains` (nullable; CSV or JSON)
- `Integer sessionMaxDays` (nullable; default 30)
- `String quietHoursStart` (nullable "HH:mm")
- `String quietHoursEnd` (nullable "HH:mm")
- `jsonb extra` (nullable) for future expansion
- `Instant createdAt`, `Instant updatedAt`

JPA mapping guidance:
- For `allowedAuthMethods`, prefer a join table `tenant_policy_auth_methods`
  OR store as Postgres `text[]`. MVP easiest: join table.

### 3.3 TenantBranding
**Table:** `tenant_branding` (1:1 with tenant)
Fields:
- `UUID id` (PK)
- `UUID tenantId` (FK unique)
- `String displayName` (nullable)
- `String logoUrl` (nullable)
- `String primaryColor` (nullable, hex)
- `String accentColor` (nullable, hex)
- `Instant createdAt`, `Instant updatedAt`

### 3.4 TenantDomainMapping (Optional but recommended)
**Table:** `tenant_domain_mappings`
Fields:
- `UUID id` (PK)
- `UUID tenantId` (FK)
- `String hostname` (unique; lowercase)
- `DomainType type` = `SUBDOMAIN|CUSTOM_DOMAIN`
- `boolean verified`
- `Instant createdAt`, `Instant updatedAt`

### 3.5 TenantPlan (Optional for MVP)
**Table:** `tenant_plans`
Fields:
- `UUID id` (PK)
- `UUID tenantId` (FK unique)
- `String planCode` (FREE|TRIAL|BASIC|PRO)
- `Integer maxUsers` (nullable)
- `Integer maxStorageMb` (nullable)
- `Instant createdAt`, `Instant updatedAt`

---

## 4) DTOs (Request/Response)

### 4.1 CreateTenantRequest
- `String tenantKey`
- `String name`
- `TenantPolicyDTO policy` (optional)
- `TenantBrandingDTO branding` (optional)

### 4.2 UpdateTenantRequest
- `String name` (optional)
- `TenantStatus status` (optional) // prefer dedicated endpoints for suspend/activate

### 4.3 TenantPolicyDTO
- `boolean allowSelfSignup`
- `boolean requireAdminApproval`
- `List<String> allowedAuthMethods`
- `String allowedSignupDomains` (optional)
- `Integer sessionMaxDays` (optional)
- `String quietHoursStart` (optional)
- `String quietHoursEnd` (optional)
- `Map<String,Object> extra` (optional)

### 4.4 TenantBrandingDTO
- `String displayName`
- `String logoUrl`
- `String primaryColor`
- `String accentColor`

### 4.5 ResolveTenantResponse (for gateway/auth-service)
Minimal fields for quick checks:
- `UUID tenantId`
- `String tenantKey`
- `String name`
- `TenantStatus status`
- `PolicySnapshot policy` (subset)
Where `PolicySnapshot` includes:
- `boolean allowSelfSignup`
- `boolean requireAdminApproval`
- `List<String> allowedAuthMethods`
- `Integer sessionMaxDays`

---

## 5) REST APIs (Spring MVC) — `/v1`

### 5.1 Tenant CRUD (SUPER_ADMIN only)
- `POST   /v1/tenants`
- `GET    /v1/tenants`
- `GET    /v1/tenants/{tenantId}`
- `PUT    /v1/tenants/{tenantId}`
- `POST   /v1/tenants/{tenantId}/suspend`
- `POST   /v1/tenants/{tenantId}/activate`
- `DELETE /v1/tenants/{tenantId}` (soft delete -> status=DELETED)

### 5.2 Policy
- `GET /v1/tenants/{tenantId}/policy`
- `PUT /v1/tenants/{tenantId}/policy` (TENANT_ADMIN or SUPER_ADMIN)

### 5.3 Branding
- `GET /v1/tenants/{tenantId}/branding`
- `PUT /v1/tenants/{tenantId}/branding` (TENANT_ADMIN or SUPER_ADMIN)

### 5.4 Domain mappings (optional)
- `POST   /v1/tenants/{tenantId}/domains`
- `GET    /v1/tenants/{tenantId}/domains`
- `DELETE /v1/tenants/{tenantId}/domains/{domainId}`
- `POST   /v1/tenants/{tenantId}/domains/{domainId}/verify` (optional)

### 5.5 Resolve (internal/gateway)
- `GET /v1/resolve?tenantKey={tenantKey}`
- `GET /v1/resolve?hostname={hostname}`

Rules:
- If tenant status is SUSPENDED or DELETED, gateway should block requests.
- Response must be fast; enable caching (Caffeine/Redis) if needed.

---

## 6) Spring Security (Recommended Setup)
Assume gateway passes a verified JWT with claims:
- `sub` = userId
- `tenantId` (for tenant-scoped admin ops)
- `roles` or `authorities`

Tenant-service should enforce:
- SUPER_ADMIN can manage any tenant
- TENANT_ADMIN can manage policy/branding for their own tenant only

Implementation:
- Use `@PreAuthorize` with `hasAuthority('ROLE_SUPER_ADMIN')` etc.
- For tenant admin ownership checks, compare `{tenantId}` path variable with JWT claim `tenantId`
  or call role-permission-service if needed (MVP: claim check is okay).

---

## 7) Postgres Schema (Flyway) — Suggested DDL

### 7.1 Extensions
- `uuid-ossp` (optional) or generate UUIDs in app
- `pgcrypto` (optional)

### 7.2 Tables (high-level)
- `tenants (id uuid pk, tenant_key text unique, name text, status text, created_at, created_by, updated_at, updated_by, version bigint)`
- `tenant_policies (id uuid pk, tenant_id uuid unique fk, allow_self_signup bool, require_admin_approval bool, allowed_signup_domains text, session_max_days int, quiet_hours_start text, quiet_hours_end text, extra jsonb, created_at, updated_at)`
- `tenant_policy_auth_methods (tenant_policy_id uuid fk, auth_method text, primary key(tenant_policy_id, auth_method))`  // if using join table
- `tenant_branding (id uuid pk, tenant_id uuid unique fk, display_name text, logo_url text, primary_color text, accent_color text, created_at, updated_at)`
- `tenant_domain_mappings (id uuid pk, tenant_id uuid fk, hostname text unique, type text, verified bool, created_at, updated_at)` (optional)
- `tenant_plans (id uuid pk, tenant_id uuid unique fk, plan_code text, max_users int, max_storage_mb int, created_at, updated_at)` (optional)

Indexes:
- `tenants(status)`
- `tenant_domain_mappings(tenant_id)`
- `tenant_policies(tenant_id)`

---

## 8) Service Layer Rules (Business Logic)
- `tenantKey` validation: lowercase, `[a-z0-9-]{3,50}`, no leading/trailing `-`
- Prevent changing `tenantKey` after creation (recommended).
- On tenant creation:
  - create Tenant
  - create default TenantPolicy (see defaults)
  - create empty TenantBranding (optional)
- On suspend:
  - set status=SUSPENDED
  - emit event for gateway cache invalidation (optional)
- On delete:
  - set status=DELETED (soft delete)
  - keep tenantKey reserved unless you implement recycle flows

---

## 9) MVP Defaults (Recommended)
Default policy for newly created tenant:
- `allowSelfSignup = false` (invite/admin-only) OR true with approval required
- `requireAdminApproval = true`
- `allowedAuthMethods = [PASSWORD, OTP_SMS]`
- `sessionMaxDays = 30`

---

## 10) Observability & Ops
- Add `X-Request-Id` propagation (log it)
- Structured logs (JSON) recommended
- Health endpoints: `/actuator/health`, `/actuator/info`
- Metrics: `/actuator/prometheus` if using Micrometer/Prometheus

---

## 11) Project Structure (Suggested)
- `controller/` (REST controllers)
- `dto/` (requests/responses)
- `entity/` (JPA entities)
- `repository/` (Spring Data JPA)
- `service/` (business logic)
- `config/` (security, web, persistence)
- `exception/` (problem details)
- `mapper/` (MapStruct optional)

---

## 12) Integration Points
- api-gateway calls `/v1/resolve` and caches results
- auth-service reads tenant policy for signup/login mode and approval flow
- audit-log-service records all admin mutations (recommended)

END
