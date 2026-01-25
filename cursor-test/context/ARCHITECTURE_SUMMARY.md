# Amogh Project - Architecture Summary

## Overview

**Amogh** is a multi-tenant learning platform designed for schools and tuition organizations in India. It provides learning content management, mind maps with spaced repetition, and comprehensive user management with role-based access control.

---

## Microservices Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENTS (Web/Mobile)                            │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              API GATEWAY                                     │
│  • JWT Validation  • Tenant Resolution  • Rate Limiting  • Routing          │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
        ┌──────────────┬───────────────┼───────────────┬──────────────┐
        ▼              ▼               ▼               ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ auth-service │ │tenant-service│ │role-permission│ │user-profile  │ │content-service│
│              │ │              │ │   -service   │ │   -service   │ │              │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
                                       │
        ┌──────────────┬───────────────┼───────────────┬──────────────┐
        ▼              ▼               ▼               ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│content-workflow│ │mindmap-service│ │graph-relations│ │notes-service │
│   -service   │ │              │ │   -service   │ │              │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
```

---

## Service Summary Table

| Service | Port | Purpose | Database |
|---------|------|---------|----------|
| **api-gateway** | - | Single entry point, JWT validation, tenant resolution, rate limiting | Optional (stateless) |
| **auth-service** | - | Identity management, authentication, tokens, sessions | PostgreSQL |
| **tenant-service** | - | Tenant lifecycle, policies, branding, domain mapping | PostgreSQL |
| **user-profile-service** | - | User profiles, preferences, relationships | PostgreSQL |
| **role-permission-service** | - | RBAC/ABAC authorization, role/permission management | PostgreSQL |
| **content-service** | 8085 | Content metadata catalog (notes/modules/topics) | PostgreSQL |
| **content-workflow-service** | 8086 | Git-like approval workflow (draft→review→publish) | PostgreSQL |
| **mindmap-service** | - | Mind maps, nodes, edges with strength/TTL | PostgreSQL |
| **graph-relations-service** | 8087 | Learning graph relations, edge reinforcement | PostgreSQL |
| **notes-service** | 8088 | Note content (Markdown + LaTeX), versioning | PostgreSQL |

---

## Core Concepts

### Multi-Tenancy
- Every record is scoped by `tenant_id`
- Tenant resolved via hostname/subdomain or path prefix
- Headers: `X-Tenant-Id`, `X-User-Id`, `X-Request-Id`

### Authentication Model
- JWT-based (Access token + Refresh token)
- Methods: Email+Password, Phone+OTP
- Sessions tracked for logout/device management

### Authorization Model
- RBAC with optional ABAC policies
- Scopes: OWN, ASSIGNED, CLASS, TENANT
- System roles: SUPER_ADMIN, TENANT_ADMIN, TEACHER/CREATOR, MENTOR, STUDENT, PARENT

### Content Lifecycle
- States: DRAFT → IN_REVIEW → APPROVED → PUBLISHED → ARCHIVED
- Versioning for notes and mind maps
- Approval workflow with reviewer assignments

### Learning Graph (Amogh Logic)
- Edge strength (0..1) represents mastery
- TTL (time-to-live) for spaced repetition
- Edges decay over time, strengthen after recall

---

## Sequence Diagrams

### Use Case 1: User Login Flow

```mermaid
sequenceDiagram
    participant Client
    participant Gateway as API Gateway
    participant Tenant as tenant-service
    participant Auth as auth-service
    participant RPS as role-permission-service

    Client->>Gateway: POST /v1/auth/login<br/>{email, password}
    Gateway->>Tenant: GET /v1/resolve?hostname=school.amogh.com
    Tenant-->>Gateway: {tenantId, tenantKey, status, policy}

    alt Tenant SUSPENDED/DELETED
        Gateway-->>Client: 403 Forbidden
    end

    Gateway->>Auth: POST /auth/login<br/>+ X-Tenant-Id header
    Auth->>Auth: Validate credentials<br/>(bcrypt/argon2)

    alt Invalid credentials
        Auth->>Auth: Increment failedLoginCount
        Auth-->>Gateway: 401 Unauthorized
        Gateway-->>Client: 401 Unauthorized
    end

    Auth->>Auth: Create Session<br/>Generate tokens
    Auth-->>Gateway: {accessToken, refreshToken, userId}
    Gateway-->>Client: {accessToken, refreshToken, expiresIn}

    Note over Client: Client stores tokens<br/>Uses accessToken for API calls
```

### Use Case 2: User Signup with Admin Approval

```mermaid
sequenceDiagram
    participant Client
    participant Gateway as API Gateway
    participant Tenant as tenant-service
    participant Auth as auth-service
    participant Notify as notification-service
    participant Admin as Admin User

    Client->>Gateway: POST /v1/auth/signup<br/>{email, phone, name}
    Gateway->>Tenant: GET /v1/resolve?tenantKey=xyz
    Tenant-->>Gateway: {tenantId, policy: {allowSelfSignup, requireAdminApproval}}

    alt Self-signup disabled
        Gateway-->>Client: 403 Signup not allowed
    end

    Gateway->>Auth: POST /auth/signup
    Auth->>Auth: Create UserIdentity (PENDING)<br/>Create TenantMembership (PENDING_VERIFICATION)
    Auth->>Notify: Send OTP/verification email
    Auth-->>Gateway: {userId, status: PENDING}
    Gateway-->>Client: 201 Created (verify email/phone)

    Client->>Gateway: POST /v1/auth/otp/verify<br/>{challengeId, otp}
    Gateway->>Auth: Verify OTP
    Auth->>Auth: Update membership → PENDING_APPROVAL
    Auth-->>Gateway: Verification successful
    Gateway-->>Client: 200 OK (awaiting admin approval)

    Note over Auth,Admin: Admin receives notification

    Admin->>Gateway: POST /tenants/{tenantId}/memberships/{id}/approve
    Gateway->>Auth: Approve membership
    Auth->>Auth: Update membership → ACTIVE
    Auth->>Notify: Send welcome notification
    Auth-->>Gateway: Approved
    Gateway-->>Admin: 200 OK

    Note over Client: User can now login
```

### Use Case 3: Content Creation and Publishing Workflow

```mermaid
sequenceDiagram
    participant Teacher
    participant Gateway as API Gateway
    participant Content as content-service
    participant Notes as notes-service
    participant Workflow as content-workflow-service
    participant RPS as role-permission-service
    participant Reviewer

    Teacher->>Gateway: POST /v1/content<br/>{type: NOTE, title, tags}
    Gateway->>RPS: Check CONTENT_WRITE permission
    RPS-->>Gateway: Allowed
    Gateway->>Content: Create content metadata
    Content->>Content: Insert Content (DRAFT)<br/>version=1
    Content-->>Gateway: {contentId, status: DRAFT}
    Gateway-->>Teacher: 201 Created

    Teacher->>Gateway: POST /v1/notes<br/>{contentId, markdown}
    Gateway->>Notes: Create note with version 1
    Notes-->>Gateway: {noteId, versionId}
    Gateway-->>Teacher: 201 Created

    Note over Teacher: Teacher edits content...

    Teacher->>Gateway: POST /workflow<br/>{contentId, contentVersionId}
    Gateway->>Workflow: Create workflow (DRAFT)
    Workflow-->>Gateway: {workflowId, state: DRAFT}

    Teacher->>Gateway: POST /workflow/{id}/submit<br/>{reviewerUserIds: [reviewer1]}
    Gateway->>Workflow: Submit for review
    Workflow->>Workflow: State → IN_REVIEW<br/>Create ReviewTask
    Workflow-->>Gateway: {state: IN_REVIEW}

    Note over Reviewer: Reviewer gets notification

    Reviewer->>Gateway: POST /workflow/{id}/reviews/{taskId}/approve<br/>{comment}
    Gateway->>RPS: Check CONTENT_REVIEWER permission
    RPS-->>Gateway: Allowed
    Gateway->>Workflow: Approve review
    Workflow->>Workflow: All reviewers approved?<br/>State → APPROVED
    Workflow-->>Gateway: {state: APPROVED}

    Teacher->>Gateway: POST /workflow/{id}/publish
    Gateway->>Workflow: Publish content
    Workflow->>Content: POST /content/{id}/status<br/>{status: PUBLISHED}
    Content->>Content: Update status, emit event
    Workflow->>Workflow: State → PUBLISHED
    Workflow-->>Gateway: {state: PUBLISHED}
    Gateway-->>Teacher: 200 Published

    Note over Content: Outbox event emitted<br/>for search indexing
```

### Use Case 4: Mind Map Access for Students

```mermaid
sequenceDiagram
    participant Student
    participant Gateway as API Gateway
    participant RPS as role-permission-service
    participant MindMap as mindmap-service
    participant Content as content-service
    participant Notes as notes-service

    Student->>Gateway: GET /mindmaps/{mindMapId}/graph?version=published
    Gateway->>Gateway: Validate JWT<br/>Extract userId, tenantId
    Gateway->>RPS: POST /authorize/check<br/>{resource: MINDMAP, action: READ, context}
    RPS->>RPS: Check role grants<br/>+ scope (ASSIGNED/CLASS)
    RPS-->>Gateway: {allowed: true, scopes: [CLASS]}

    Gateway->>MindMap: GET /mindmaps/{id}/graph
    MindMap->>MindMap: Fetch published version<br/>Load nodes + edges
    MindMap-->>Gateway: {nodes: [...], edges: [...]}
    Gateway-->>Student: Mind map graph data

    Note over Student: Student clicks on a note node

    Student->>Gateway: GET /v1/content/{contentId}
    Gateway->>Content: Get content metadata
    Content-->>Gateway: {contentId, type: NOTE, currentVersion}

    Student->>Gateway: GET /notes/{noteId}/render
    Gateway->>Notes: Get published version
    Notes->>Notes: Return latest_published_version
    Notes-->>Gateway: {title, content_md (Markdown+LaTeX)}
    Gateway-->>Student: Note content

    Note over Student: Client renders Markdown<br/>with KaTeX for LaTeX
```

### Use Case 5: Spaced Repetition - Edge Review and Decay

```mermaid
sequenceDiagram
    participant Student
    participant Gateway as API Gateway
    participant MindMap as mindmap-service
    participant Graph as graph-relations-service
    participant Notify as notification-service

    Note over Graph: Background: Edges decay over time<br/>expiresAt = lastReviewedAt + ttlSeconds

    Student->>Gateway: GET /mindmaps/revision/weak?userId=student1&limit=50
    Gateway->>MindMap: Get weak edges
    MindMap->>MindMap: Query edges WHERE<br/>expiresAt <= now OR strength < 0.3
    MindMap-->>Gateway: {weakEdges: [{edgeId, fromNode, toNode, strength}]}
    Gateway-->>Student: Edges due for revision

    Note over Student: Student reviews concept<br/>and answers recall question

    Student->>Gateway: POST /mindmaps/{id}/edges/{edgeId}/review<br/>{result: CORRECT, difficulty: 2, timeSpentSeconds: 45}
    Gateway->>MindMap: Record review
    MindMap->>MindMap: Update edge:<br/>strength += 0.08 (capped at 1.0)<br/>ttlSeconds = base * (1 + strength*2)<br/>lastReviewedAt = now
    MindMap-->>Gateway: {strength: 0.71, ttlSeconds: 172800, expiresAt: ...}
    Gateway-->>Student: Updated edge strength

    alt Student answers WRONG
        MindMap->>MindMap: strength -= 0.12<br/>ttlSeconds *= 0.75 (shorter decay)
    end

    Note over MindMap,Notify: Optional: Emit EdgeReviewed event<br/>for analytics

    rect rgb(240, 240, 240)
        Note over Graph,Notify: Notification Flow (async)
        Graph->>Graph: Periodic job checks<br/>edges becoming weak
        Graph->>Notify: EdgesBecameWeak event
        Notify->>Student: Push notification<br/>"Time to review: Quadratic Equations"
    end
```

### Use Case 6: Permission Check Flow (Authorization)

```mermaid
sequenceDiagram
    participant Service as Any Service
    participant RPS as role-permission-service
    participant DB as RPS Database

    Service->>RPS: POST /authorize/check<br/>{tenantId, userId, resource, action, context}

    RPS->>DB: Get UserRoleAssignments<br/>WHERE tenantId, userId, status=ACTIVE
    DB-->>RPS: [{roleId: TEACHER, scopeType: CLASS, scopeId: class10A}]

    RPS->>DB: Get RolePermissionGrants<br/>for each roleId
    DB-->>RPS: [{permissionCode: CONTENT:READ, scopeCode: CLASS},<br/>{permissionCode: CONTENT:WRITE, scopeCode: OWN}]

    RPS->>RPS: Match resource:action<br/>against permission grants

    alt Grant found with scope
        RPS->>RPS: Validate scope:<br/>• OWN → context.ownerId == userId<br/>• CLASS → context.classId in user scopes<br/>• ASSIGNED → userId in context.mentorIds
    end

    alt AccessPolicy enabled (ABAC)
        RPS->>DB: Get AccessPolicies<br/>ordered by priority
        RPS->>RPS: Evaluate DENY policies first<br/>Then ALLOW policies
    end

    RPS-->>Service: {allowed: true/false,<br/>matchedGrants: [...],<br/>appliedScopes: [...],<br/>denyReason: null}
```

### Use Case 7: Invite-Based Onboarding

```mermaid
sequenceDiagram
    participant Admin
    participant Gateway as API Gateway
    participant Auth as auth-service
    participant RPS as role-permission-service
    participant Notify as notification-service
    participant NewUser as Invited User

    Admin->>Gateway: POST /v1/auth/invite<br/>{email, roleHints: [TEACHER]}
    Gateway->>RPS: Check USER:INVITE permission
    RPS-->>Gateway: Allowed
    Gateway->>Auth: Create invite
    Auth->>Auth: Generate invite token<br/>Store hash + expiry
    Auth->>Notify: Send invite email with link
    Auth-->>Gateway: {inviteId, status: SENT}
    Gateway-->>Admin: 201 Invite sent

    Note over NewUser: User clicks invite link

    NewUser->>Gateway: POST /v1/auth/invite/accept<br/>{token, password}
    Gateway->>Auth: Validate invite token
    Auth->>Auth: Create UserIdentity (if new)<br/>Create TenantMembership
    Auth->>Auth: Mark invite ACCEPTED
    Auth-->>Gateway: {userId, status}

    alt Verification required
        Auth->>Notify: Send verification OTP
        NewUser->>Gateway: POST /v1/auth/otp/verify
        Gateway->>Auth: Verify OTP
        Auth->>Auth: Membership → ACTIVE
    end

    Note over Admin,RPS: Admin assigns final roles
    Admin->>Gateway: POST /tenants/{id}/users/{userId}/roles<br/>{roleId: TEACHER, scopeType: CLASS, scopeId: class10A}
    Gateway->>RPS: Assign role
    RPS-->>Gateway: Assignment created
    Gateway-->>Admin: 200 OK
```

---

## Data Flow Summary

### Headers Propagated Through System
```
Client Request
    │
    ▼
API Gateway
    │ Resolves tenant, validates JWT
    │ Injects: X-Tenant-Id, X-User-Id, X-Request-Id
    ▼
Downstream Services
    │ Use headers for:
    │ • Tenant isolation (filter all queries)
    │ • Audit logging
    │ • Request correlation
    ▼
Database (PostgreSQL)
    All tables have tenant_id column
```

### Event Flow (Outbox Pattern)
```
Service writes to DB
    │
    ▼ (same transaction)
Outbox table entry
    │
    ▼ (async poller or webhook)
Event consumers
    │
    ├── Search indexing
    ├── Notification triggers
    ├── Cache invalidation
    └── Analytics
```

---

## Key Integration Points

| From | To | Purpose |
|------|-----|---------|
| api-gateway | tenant-service | Resolve tenant from hostname/key |
| api-gateway | auth-service | Token introspection (optional) |
| auth-service | tenant-service | Read tenant policies |
| auth-service | notification-service | Send OTP/invite emails |
| content-workflow-service | content-service | Publish content version |
| content-workflow-service | role-permission-service | Check reviewer permissions |
| mindmap-service | content-service | Link nodes to content |
| notes-service | content-workflow-service | Publish note versions |
| All services | role-permission-service | Authorization checks |

---

## Technology Stack

- **Language**: Java 17/21+
- **Framework**: Spring Boot 3.x/4.x
- **Gateway**: Spring Cloud Gateway (Reactive)
- **Database**: PostgreSQL
- **Migrations**: Flyway / Liquibase
- **ORM**: Spring Data JPA (Hibernate)
- **Auth**: JWT (with JWKS)
- **API Style**: REST + JSON (versioned under `/v1`)
- **Observability**: Micrometer + Actuator + distributed tracing
- **Code Generation**: Lombok

---

## Security Highlights

1. **Password Hashing**: Argon2id or bcrypt
2. **OTP Policies**: 5-min expiry, max 5 attempts, resend cooldown
3. **Rate Limiting**: IP + identifier for auth routes
4. **Account Lockouts**: After repeated failures
5. **Token Rotation**: Refresh token reuse detection
6. **Tenant Isolation**: All queries filter by tenant_id
7. **Audit Trail**: All sensitive actions logged

---

## MVP System Roles

| Role | Capabilities |
|------|-------------|
| SUPER_ADMIN | Platform-wide access, manage all tenants |
| TENANT_ADMIN | Manage tenant settings, users, roles |
| TEACHER/CREATOR | Create/edit content, mind maps |
| MENTOR | View assigned student progress |
| STUDENT | Read published content, review edges |
| PARENT | View linked child's progress |

---

*Generated from context files in the Amogh Project*
