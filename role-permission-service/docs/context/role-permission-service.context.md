# role-permission-service — Context File (Amogh Project)

## 1) Purpose
This service provides authorization for the Amogh platform in a multi-tenant environment.
It manages:
- Roles (per tenant)
- Permissions (action on resource)
- Role -> Permission grants (optionally scoped)
- User -> Role assignments (optionally scoped)
- Optional policy-based rules (ABAC-like) for complex cases (mentor/parent visibility)

Other services should NOT implement their own authorization logic beyond calling this service
(or validating gateway-issued claims). This service is the source of truth for access decisions.

---

## 2) Core Concepts
### 2.1 Tenant-aware authorization
All roles and assignments exist within a `tenantId`.
A user can have different roles in different tenants, and even within a tenant, roles can be scoped.

### 2.2 Permission naming scheme
Preferred permission code scheme:
`<RESOURCE>:<ACTION>` optionally with scope handled separately.
Examples:
- `NOTE:READ`
- `CONTENT:PUBLISH`
- `PROGRESS:READ`
- `USER:INVITE`

Scope is usually applied as a separate field (`OWN`, `CLASS`, `ASSIGNED`, `TENANT`, etc).

### 2.3 Scopes
Scopes restrict the boundary of a permission grant:
- `OWN` — only user-owned resources
- `ASSIGNED` — resources assigned to the user (mentor assigned students, etc.)
- `CLASS` / `GROUP` / `SCHOOL` — scoped to a specific entity
- `TENANT` — whole tenant
- `PUBLISHED_ONLY` — read-only to published content

Scopes can be implemented as:
- Enum values (recommended for MVP), or
- A `PermissionScope` table (if admin-configurable).

### 2.4 Policy-based rules (optional)
For mentor/parent rules that are hard with pure RBAC, use AccessPolicy (ABAC-lite):
- ALLOW/DENY policies
- Priority order
- Conditions expressed in a structured JSON form
Example: `ALLOW PROGRESS:READ if user.id IN student.mentorIds`

---

## 3) Data Model / POJOs (Java-style)

### 3.1 Role
Represents a role in a tenant.
Fields:
- id, tenantId, name, description
- isSystem (built-in role)
- status (ACTIVE|DISABLED)
- createdAt, createdBy, updatedAt, updatedBy

### 3.2 Permission
A permission definition (global or tenant-defined; usually global).
Fields:
- id
- code (e.g., NOTE:READ)
- resource (NOTE), action (READ)
- description
- isDeprecated
- createdAt

### 3.3 RolePermissionGrant
Role -> Permission mapping, optionally scoped + constrained.
Fields:
- id, tenantId
- roleId
- permissionCode (or permissionId)
- scopeCode (optional: OWN/CLASS/ASSIGNED/TENANT/...)
- constraints (optional JSON)
- createdAt, createdBy

### 3.4 UserRoleAssignment
Assigns roles to a user in a tenant, optionally bound to a scope entity.
Fields:
- id, tenantId
- userId
- roleId
- scopeType (TENANT|SCHOOL|CLASS|GROUP|SUBJECT)
- scopeId (nullable; if null and scopeType=TENANT => tenant-wide)
- status (ACTIVE|REVOKED)
- validFrom, validTo (optional)
- assignedBy, createdAt

### 3.5 AccessPolicy (optional)
Policy engine for complex rules.
Fields:
- id, tenantId, name
- effect (ALLOW|DENY)
- priority (int; higher wins)
- resource, action
- condition (JSON)
- status (ACTIVE|DISABLED)
- createdAt, createdBy

### 3.6 PermissionCheckRequest (DTO)
Input to permission evaluation.
Fields:
- tenantId
- userId
- resource, action
- resourceId (optional)
- context (map-like JSON: {classId, studentId, contentStatus, ownerId, mentorIds...})

### 3.7 PermissionCheckResult (DTO)
Decision output.
Fields:
- allowed (boolean)
- matchedGrants (list of permission codes)
- appliedScopes (list)
- denyReason (optional)
- debugTraceId (optional)

---

## 4) Responsibilities (What this service does)
- Create/update/delete roles per tenant (if not system roles)
- Maintain permission definitions (usually pre-seeded + versioned)
- Grant permissions to roles with optional scope constraints
- Assign roles to users with optional scope binding (class/group)
- Evaluate access decisions:
  - Collect user roles for tenant
  - Expand into role-permission grants
  - Apply scope logic (OWN/CLASS/ASSIGNED/TENANT/etc)
  - Optionally apply AccessPolicy rules (ABAC-lite)
  - Return allow/deny + reasons

---

## 5) Non-Responsibilities (What it must NOT do)
- User authentication (handled by auth-service)
- Tenant provisioning (handled by tenant-service)
- Content ownership logic beyond what’s passed in `context`
- Fetching domain entities from other services directly (avoid tight coupling)
  - Instead, other services pass relevant attributes in `context`.

---

## 6) APIs (Suggested)
### 6.1 Role management
- POST   /tenants/{tenantId}/roles
- GET    /tenants/{tenantId}/roles
- GET    /tenants/{tenantId}/roles/{roleId}
- PUT    /tenants/{tenantId}/roles/{roleId}
- DELETE /tenants/{tenantId}/roles/{roleId}

### 6.2 Permission catalog
- GET /permissions
- GET /permissions/{code}

### 6.3 Grants (Role -> Permission)
- POST /tenants/{tenantId}/roles/{roleId}/grants
- GET  /tenants/{tenantId}/roles/{roleId}/grants
- DELETE /tenants/{tenantId}/roles/{roleId}/grants/{grantId}

### 6.4 User role assignments
- POST /tenants/{tenantId}/users/{userId}/roles
- GET  /tenants/{tenantId}/users/{userId}/roles
- DELETE /tenants/{tenantId}/users/{userId}/roles/{assignmentId}

### 6.5 Permission check (main runtime API)
- POST /authorize/check
Request body: PermissionCheckRequest
Response: PermissionCheckResult

### 6.6 Optional: Batch check
- POST /authorize/check/batch

---

## 7) Authorization model inside the service
This service itself must be protected:
- Only tenant admins/super-admin can manage roles and grants.
- Users can read their own role assignments (optional).
- Permission check API is callable by trusted services (mTLS / service tokens).

---

## 8) Evaluation Rules (MVP)
1. Gather `UserRoleAssignment` by (tenantId, userId) where status=ACTIVE and within validFrom/validTo
2. For each role, fetch `RolePermissionGrant`
3. Match requested `resource+action` to `permissionCode`
4. If grant has `scopeCode`, validate using request.context:
   - OWN => context.ownerId == userId
   - CLASS/GROUP => context.scopeId in user assignments or request context
   - ASSIGNED => context.assignedUserIds contains userId (or context.mentorIds)
   - PUBLISHED_ONLY => context.contentStatus == PUBLISHED
5. If any matching grant passes scope checks => ALLOW
6. If AccessPolicy enabled:
   - Evaluate DENY policies first by priority
   - Then ALLOW policies
   - Policies can override RBAC outcome (keep this simple, optional)

---

## 9) Events (Optional but recommended)
Emit events for audit and cache invalidation:
- RoleCreated/Updated/Deleted
- RoleGrantedPermission / RoleRevokedPermission
- UserAssignedRole / UserRevokedRole
These events can be used by api-gateway / other services to refresh cached claims.

---

## 10) Storage Notes
Tables (suggested):
- roles
- permissions
- role_permission_grants
- user_role_assignments
- access_policies (optional)

All tables must include `tenant_id` where applicable.

Indexes:
- user_role_assignments: (tenant_id, user_id, status)
- role_permission_grants: (tenant_id, role_id)
- roles: (tenant_id, name)

---

## 11) Security & Audit
- All admin operations must write an audit trail (audit-log-service).
- Any “impersonate” or “override” permission must be highly restricted and logged.
- Prevent privilege escalation:
  - Users cannot grant permissions they do not already hold (or reserve to super admin only).
  - System roles are immutable unless super admin.

---

## 12) MVP Defaults (Typical Roles)
System roles that can be seeded per tenant:
- SUPER_ADMIN (platform)
- TENANT_ADMIN
- CREATOR/TEACHER
- MENTOR
- STUDENT
- PARENT
- MODERATOR

Each gets a curated set of grants; avoid tenant admins editing system role grants initially.

END
