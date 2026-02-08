# Learner Microservices Platform — Architecture Context

## Overview

**Learner (Amogh)** is a multi-tenant learning management platform built with a microservices architecture. The platform supports schools, tuition centers, and educational organizations with features like content management, mind mapping, notes, spaced repetition (recall), and workflow management.

---

## Technology Stack

| Layer | Technology |
|-------|------------|
| Language | Java 25 (some services Java 17) |
| Framework | Spring Boot 4.0.1 (some 3.3.5) |
| Database | PostgreSQL 16 |
| Migrations | Liquibase |
| API Style | REST + JSON, versioned under `/v1` |
| Gateway | Spring WebFlux (Reactive) |
| Containerization | Docker, Docker Compose |
| Build Tool | Gradle |

---

## Architecture Diagram

```
                                    ┌─────────────────┐
                                    │   Clients       │
                                    │ (Web/Mobile)    │
                                    └────────┬────────┘
                                             │
                                             ▼
                              ┌──────────────────────────┐
                              │      API Gateway         │
                              │        (8084)            │
                              │  - Routing               │
                              │  - JWT Validation (TODO) │
                              │  - Rate Limiting (TODO)  │
                              └──────────────┬───────────┘
                                             │
            ┌────────────────────────────────┼────────────────────────────────┐
            │                                │                                │
            ▼                                ▼                                ▼
   ┌─────────────────┐            ┌─────────────────┐            ┌─────────────────┐
   │  Auth Service   │            │ Tenant Service  │            │ Role-Permission │
   │     (8081)      │            │     (8082)      │            │    Service      │
   │                 │            │                 │            │     (8080)      │
   │ - Login/Signup  │            │ - Tenant CRUD   │            │ - RBAC          │
   │ - JWT Tokens    │            │ - Policies      │            │ - Permissions   │
   │ - OTP/Password  │            │ - Branding      │            │ - Role Grants   │
   └─────────────────┘            └─────────────────┘            └─────────────────┘
            │                                │                                │
            └────────────────────────────────┼────────────────────────────────┘
                                             │
            ┌────────────────────────────────┼────────────────────────────────┐
            │                                │                                │
            ▼                                ▼                                ▼
   ┌─────────────────┐            ┌─────────────────┐            ┌─────────────────┐
   │ User Profile    │            │ Content Service │            │Content Workflow │
   │   Service       │            │     (8085)      │            │    Service      │
   │     (8083)      │            │                 │            │     (8086)      │
   │                 │            │ - Content CRUD  │            │ - Classes       │
   │ - User Profiles │            │ - Versioning    │            │ - Schedules     │
   │ - Relationships │            │                 │            │ - Workflows     │
   └─────────────────┘            └─────────────────┘            └─────────────────┘
            │                                │                                │
            └────────────────────────────────┼────────────────────────────────┘
                                             │
            ┌────────────────────────────────┼────────────────────────────────┐
            │                                │                                │
            ▼                                ▼                                ▼
   ┌─────────────────┐            ┌─────────────────┐            ┌─────────────────┐
   │ Mindmap Service │            │  Notes Service  │            │ Graph Relations │
   │     (8087)      │            │     (8088)      │            │    Service      │
   │                 │            │                 │            │     (8089)      │
   │ - Mind Maps     │            │ - Notes CRUD    │            │ - Relationships │
   │ - Nodes/Links   │            │ - Categories    │            │ - Graph Queries │
   └─────────────────┘            └─────────────────┘            └─────────────────┘
            │                                │                                │
            └────────────────────────────────┼────────────────────────────────┘
                                             │
                                             ▼
                              ┌──────────────────────────┐
                              │     Recall Service       │
                              │        (8091)            │
                              │                          │
                              │  - Spaced Repetition     │
                              │  - Reminders             │
                              │  - Learning Schedules    │
                              └──────────────────────────┘
                                             │
                                             ▼
                              ┌──────────────────────────┐
                              │       PostgreSQL         │
                              │        (5432)            │
                              │                          │
                              │  - 10 Databases          │
                              │  - Single Instance       │
                              └──────────────────────────┘
```

---

## Microservices Inventory

### Core Services

| Service | Port | Database | Purpose |
|---------|------|----------|---------|
| api-gateway | 8084 | - | Single entry point, routing, future JWT validation |
| auth-service | 8081 | auth_service | Identity, authentication, tokens, sessions |
| tenant-service | 8082 | tenant_service | Multi-tenancy, tenant policies, branding |
| role-permission-service | 8080 | role_permission_service | RBAC, permissions, role assignments |
| user-profile-service | 8083 | user_profile | User profiles, relationships |

### Domain Services

| Service | Port | Database | Purpose |
|---------|------|----------|---------|
| content-service | 8085 | content_service | Content management, versioning |
| content-workflow-service | 8086 | content_workflow_service | Classes, schedules, workflows |
| mindmap-service | 8087 | mindmap_service | Mind mapping, nodes, connections |
| notes-service | 8088 | notes_service | Notes, categories, organization |
| graph-relations-service | 8089 | graph_relations_service | Entity relationships, graph queries |
| recall-service | 8091 | recall_service | Spaced repetition, reminders |

---

## Service Details

### 1. API Gateway (8084)
**Purpose:** Single entry point for all client requests.

**Routes:**
| Route Pattern | Target Service | Rewrite |
|---------------|----------------|---------|
| `/v1/auth/**` | auth-service:8081 | `/v1/auth` → `/auth` |
| `/v1/tenants/**`, `/v1/resolve` | tenant-service:8082 | None |
| `/v1/permissions/**`, `/v1/authorize/**` | role-permission-service:8080 | `/v1` → `` |
| `/v1/tenants/{id}/profiles/**` | user-profile-service:8083 | None |
| `/v1/notes/**` | notes-service:8088 | `/v1` → `` |
| `/v1/mindmaps/**` | mindmap-service:8087 | `/v1` → `` |
| `/v1/workflow/**`, `/v1/classes/**` | content-workflow-service:8086 | `/v1` → `` |

**Implementation Status:**
- [x] Request routing
- [x] Path rewriting
- [ ] JWT authentication
- [ ] Tenant resolution
- [ ] Rate limiting
- [ ] CORS configuration

---

### 2. Auth Service (8081)
**Purpose:** Identity and authentication authority.

**Responsibilities:**
- User identity management (credentials, verification)
- Login, signup, invite acceptance
- JWT token issuance and validation
- Session management
- Password reset, OTP verification

**Key Entities:**
- `UserIdentity` - Core identity record
- `TenantMembership` - User-tenant association
- `VerificationChallenge` - OTP/email verification
- `Invite` - Admin-driven onboarding
- `Session` - Active login tracking

**APIs:**
- `POST /auth/signup` - User registration
- `POST /auth/login` - Authentication
- `POST /auth/token/refresh` - Token refresh
- `POST /auth/otp/send` - Send OTP
- `POST /auth/otp/verify` - Verify OTP
- `POST /auth/password/reset` - Password reset

---

### 3. Tenant Service (8082)
**Purpose:** Source of truth for tenants (schools/organizations).

**Responsibilities:**
- Tenant lifecycle management
- Tenant identification (tenantKey, hostname)
- Tenant policies (auth methods, approval rules)
- Branding (logo, colors)

**Key Entities:**
- `Tenant` - Core tenant record
- `TenantPolicy` - Auth and signup policies
- `TenantBranding` - Display customization
- `TenantDomainMapping` - Hostname resolution

**APIs:**
- `POST /v1/tenants` - Create tenant
- `GET /v1/tenants/{id}` - Get tenant
- `PUT /v1/tenants/{id}/policy` - Update policy
- `GET /v1/resolve?tenantKey=xxx` - Resolve tenant

---

### 4. Role-Permission Service (8080)
**Purpose:** Authorization and access control.

**Responsibilities:**
- Role management per tenant
- Permission definitions
- Role-permission grants
- User-role assignments
- Access decision evaluation

**Key Entities:**
- `Role` - Tenant-specific roles
- `Permission` - Action definitions (e.g., `NOTE:READ`)
- `RolePermissionGrant` - Role to permission mapping
- `UserRoleAssignment` - User to role mapping
- `AccessPolicy` - Complex ABAC rules (optional)

**APIs:**
- `POST /tenants/{tenantId}/roles` - Create role
- `POST /authorize/check` - Evaluate permission
- `POST /tenants/{tenantId}/users/{userId}/roles` - Assign role

**Default Roles:**
- SUPER_ADMIN, TENANT_ADMIN, CREATOR/TEACHER, MENTOR, STUDENT, PARENT, MODERATOR

---

### 5. User Profile Service (8083)
**Purpose:** User profile data management.

**Responsibilities:**
- User profile CRUD
- Student/teacher profiles
- Parent-student relationships
- Mentor assignments

**APIs:**
- `GET /v1/tenants/{id}/profiles/{userId}`
- `PUT /v1/tenants/{id}/profiles/{userId}`
- `GET /v1/tenants/{id}/relationships`

---

### 6. Content Service (8085)
**Purpose:** Learning content management.

**Responsibilities:**
- Content CRUD operations
- Content versioning
- Content categorization

---

### 7. Content Workflow Service (8086)
**Purpose:** Educational workflow management.

**Responsibilities:**
- Class management
- Schedule management
- Content delivery workflows

---

### 8. Mindmap Service (8087)
**Purpose:** Mind mapping functionality.

**Responsibilities:**
- Mind map CRUD
- Node management
- Connection/link management
- Collaborative editing

---

### 9. Notes Service (8088)
**Purpose:** Note-taking functionality.

**Responsibilities:**
- Notes CRUD
- Note categorization
- Search and organization

---

### 10. Graph Relations Service (8089)
**Purpose:** Entity relationship management.

**Responsibilities:**
- Relationship definitions
- Graph queries
- Connection analysis

---

### 11. Recall Service (8091)
**Purpose:** Spaced repetition learning.

**Responsibilities:**
- Learning item scheduling
- Reminder generation
- Progress tracking
- Spaced repetition algorithm

---

## Database Configuration

### Single PostgreSQL Instance
All services connect to a single PostgreSQL instance with separate databases.

**Connection:** `jdbc:postgresql://postgres:5432/{database_name}`

| Database | User | Service |
|----------|------|---------|
| auth_service | auth_service | auth-service |
| tenant_service | tenant_service | tenant-service |
| role_permission_service | role_permission_service | role-permission-service |
| user_profile | user_profile_user | user-profile-service |
| content_service | content_service | content-service |
| content_workflow_service | content_workflow_service | content-workflow-service |
| mindmap_service | mindmap_service | mindmap-service |
| notes_service | notes_service | notes-service |
| graph_relations_service | graph_relations_service | graph-relations-service |
| recall_service | recall_service | recall-service |

---

## Docker Deployment

### Deploy All Services
```bash
cd /Users/Vinayak/Learner-microservices
docker-compose up -d
```

### Deploy Individual Service (Standalone)
```bash
cd <service-folder>
docker-compose up -d
```

### Gradle Commands (per service)
```bash
./gradlew dockerBuild    # Build Docker image
./gradlew dockerDeploy   # Build and deploy
./gradlew dockerLogs     # View logs
./gradlew dockerStatus   # Check status
./gradlew dockerStop     # Stop container
```

### Port Summary

| Service | App Port | Standalone PG Port |
|---------|----------|-------------------|
| role-permission-service | 8080 | 5433 |
| auth-service | 8081 | 5432 |
| tenant-service | 8082 | 5434 |
| user-profile-service | 8083 | 5435 |
| api-gateway | 8084 | - |
| content-service | 8085 | 5438 |
| content-workflow-service | 8086 | 5439 |
| mindmap-service | 8087 | 5437 |
| notes-service | 8088 | 5436 |
| graph-relations-service | 8089 | 5440 |
| recall-service | 8091 | 5441 |

---

## Inter-Service Communication

### Service Dependencies

```
api-gateway
├── auth-service
├── tenant-service
├── role-permission-service
├── user-profile-service
├── content-service
├── content-workflow-service
│   └── user-profile-service
├── mindmap-service
├── notes-service
├── graph-relations-service
└── recall-service

auth-service
├── tenant-service (reads policies)
└── user-profile-service (creates profile on signup)

All services
└── role-permission-service (authorization checks)
```

### Communication Patterns
- **Synchronous:** REST calls between services
- **Future:** Event-driven for audit, notifications

---

## Multi-Tenancy

### Tenant Resolution Flow
1. Client request arrives at API Gateway
2. Gateway resolves tenant from:
   - `X-Tenant-Id` header (trusted callers)
   - Hostname/subdomain → `tenant-service /v1/resolve`
   - Path prefix `/t/{tenantKey}/...`
3. Gateway injects `X-Tenant-Id` header to downstream services
4. All services filter data by `tenantId`

### Tenant Status
- `ACTIVE` - Normal operation
- `SUSPENDED` - Blocked access
- `DELETED` - Soft deleted

---

## Security Model

### Authentication (auth-service)
- JWT access tokens (short-lived)
- Refresh tokens (longer-lived)
- Password + OTP support
- Session tracking

### Authorization (role-permission-service)
- Role-Based Access Control (RBAC)
- Scoped permissions (OWN, CLASS, TENANT)
- Optional ABAC policies

### API Gateway (TODO)
- JWT validation
- Tenant resolution
- Rate limiting
- CORS headers

---

## Development Guidelines

### Service Structure
```
service-name/
├── src/main/java/com/learning/{service}/
│   ├── controller/     # REST controllers
│   ├── dto/            # Request/response objects
│   ├── entity/         # JPA entities
│   ├── repository/     # Spring Data JPA
│   ├── service/        # Business logic
│   ├── config/         # Configuration
│   └── exception/      # Error handling
├── src/main/resources/
│   ├── application.properties
│   └── db/changelog/   # Liquibase migrations
├── build.gradle
├── Dockerfile
└── docker-compose.yml
```

### Conventions
- API versioning: `/v1/...`
- Database: Liquibase migrations, no `ddl-auto`
- Logging: DEBUG for development
- Health: `/actuator/health`

---

## Health Endpoints

All services expose:
- `GET /actuator/health` - Health check
- `GET /actuator/info` - Service info

Services with Swagger:
- `GET /swagger-ui` - API documentation

---

## Quick Reference

### Start Everything
```bash
docker-compose up -d
```

### Check All Services
```bash
docker-compose ps
```

### View Logs
```bash
docker-compose logs -f <service-name>
```

### Stop Everything
```bash
docker-compose down
```

### Rebuild Single Service
```bash
docker-compose build <service-name>
docker-compose up -d <service-name>
```

---

## Files Reference

| File | Purpose |
|------|---------|
| `/docker-compose.yml` | Main orchestration (all services) |
| `/init-databases.sql` | PostgreSQL initialization |
| `/<service>/docker-compose.yml` | Standalone service deployment |
| `/<service>/build.gradle` | Build config + Docker tasks |
| `/<service>/Dockerfile` | Container build |
| `/<service>/docs/` | Service-specific documentation |

---

## CRC Analysis - Service Boundary Decisions

This section documents the architectural decisions made through Class-Responsibility-Collaborator (CRC) analysis.

### Identity vs Profile Separation

| Aspect | auth-service | user-profile-service |
|--------|--------------|---------------------|
| Owns | UserIdentity, TenantMembership, Sessions | UserProfile, relationships |
| Purpose | Authentication, identity verification | Profile data, display info |
| Decision | TenantMembership stays in auth-service (tightly coupled with auth flow) |

**Profile Creation Flow:** Profile creation is a separate step after signup. Auth-service handles identity; user-profile-service handles profile enrichment.

### Relationship Ownership

| Relationship Type | Service | Examples |
|-------------------|---------|----------|
| People relationships | user-profile-service | Parent-student, mentor-mentee |
| Knowledge connections | graph-relations-service | Concept-to-concept, topic prerequisites |
| Content relationships | graph-relations-service | Note-to-mindmap, content dependencies |

### Content Services Separation

| Service | Responsibility | Analogy |
|---------|---------------|---------|
| content-service | Raw content CRUD, versioning | "Library/warehouse" |
| content-workflow-service | Delivery, scheduling, classes | "Classroom/delivery" |

**Decision:** Keep separate. content-service owns the material; content-workflow-service owns when/how it's delivered.

### Notes and Mindmap Services

**Decision:** Stay as separate services. Different data models, different UI interactions, different feature roadmaps. Both can link to each other via graph-relations-service.

### Recall Service Scope

**Coverage:** All learning artifacts
- Notes (spaced repetition for note review)
- Mindmaps (node-by-node recall)
- Content items (quiz questions, flashcards)

**Pattern:** recall-service references items by `entityType` + `entityId`, making it artifact-agnostic.

### Authorization Pattern (MVP)

**Decision:** Deferred for MVP. Current approach:
- role-permission-service provides authorization check endpoint
- Individual services call it when needed
- Future: Gateway-level JWT validation with embedded permissions

### Permission Seeding

**Decision:** Permissions are centrally seeded in role-permission-service via Liquibase migrations. Services don't self-register permissions.

### Future Services (Deferred)

| Service | Purpose | Status |
|---------|---------|--------|
| notification-service | Push, email, SMS notifications | MVP deferred |
| audit-log-service | Compliance, activity tracking | MVP deferred |

### Graph Relations Service Dual Purpose

**Decision:** graph-relations-service handles both:
1. **Knowledge graphs** - Concept relationships, topic hierarchies
2. **Content relationships** - Links between notes, mindmaps, content items

This consolidation avoids service proliferation while keeping relationship logic centralized.

---

*Last updated: February 2026*
