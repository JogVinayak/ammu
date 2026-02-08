# auth-service — Context File (Amogh Project)

## 1) Purpose
This service is the **identity + authentication** authority for Amogh.
It is responsible for:
- Creating and managing **user identities** (credentials + verification state)
- Handling **login**, **signup**, **invite acceptance**, **password reset**
- Issuing and validating **tokens** (JWT / opaque tokens) and managing **sessions**
- Enforcing account security policies (lockouts, OTP limits, device/session control)

It is **NOT** responsible for storing rich user profile data (that’s `user-profile-service`)
and is **NOT** the source of truth for authorization (that’s `role-permission-service`).

---

## 2) Core Concepts
### 2.1 Identity vs Profile
- **Identity (auth-service):** email/phone, password hash / OTP capability, verification flags, account status.
- **Profile (user-profile-service):** name, grade/class, preferences, parent/mentor links, etc.

### 2.2 Multi-tenant
Users exist in a multi-tenant world. Typical approach:
- A global `userId` (unique across platform)
- A **tenant membership** record per tenant: status (PENDING/ACTIVE), join method (INVITE/SELF_SIGNUP), verification per tenant if needed.

### 2.3 Authentication methods (MVP)
- Email + password OR phone + OTP (India-friendly)
- Invite-based onboarding (admin invites user, user completes verification)
Future:
- SSO (SAML/OIDC), passkeys (WebAuthn), social login

### 2.4 Tokens & Sessions
- Access token (short-lived) + Refresh token (longer-lived)
- Track sessions for logout/all-devices logout and risk controls
- Tokens contain `userId`, `tenantId`, plus minimal claims (do NOT embed large permissions)

---

## 3) Responsibilities (What this service does)
- Create identities (self-signup, invite, admin-created identity)
- Verify email/phone (OTP/email link)
- Authenticate credentials (password/OTP)
- Issue/refresh/revoke tokens
- Manage sessions/devices
- Password reset and credential updates
- Rate limit auth endpoints + lockout policy
- Emit auth-related audit/security events

---

## 4) Non-Responsibilities (What it must NOT do)
- Role assignment / permission evaluation (role-permission-service)
- Storing user profile fields (user-profile-service)
- Tenant provisioning and tenant configuration (tenant-service)
- Domain-specific relationships (parent/mentor mapping lives outside; only store minimal links if needed for security)

---

## 5) Data Model / POJOs (Java-style)

### 5.1 UserIdentity
Core identity record (global).
Fields:
- id (userId)
- primaryEmail (nullable), primaryPhone (nullable)
- emailVerified (bool), phoneVerified (bool)
- passwordHash (nullable if OTP-only)
- status (ACTIVE|PENDING|DISABLED|LOCKED)
- createdAt, updatedAt
- lastLoginAt
- failedLoginCount
- lockUntil (nullable)

### 5.2 TenantMembership
Links a user to a tenant.
Fields:
- id
- tenantId
- userId
- status (PENDING_APPROVAL|PENDING_VERIFICATION|ACTIVE|SUSPENDED|LEFT)
- joinMethod (INVITE|SELF_SIGNUP|ADMIN_CREATE)
- createdAt, createdBy
- approvedAt, approvedBy (optional)

### 5.3 Credential (optional normalized model)
If you want multiple credentials per user.
Fields:
- id
- userId
- type (PASSWORD|TOTP|OTP_PHONE|OTP_EMAIL|PASSKEY|OIDC)
- secretRef / hashRef
- status (ACTIVE|DISABLED)
- createdAt, updatedAt

### 5.4 VerificationChallenge
OTP/email-link challenges for verification and login.
Fields:
- id
- userId (nullable for pre-user flows), tenantId (optional)
- channel (SMS|EMAIL)
- purpose (SIGNUP_VERIFY|LOGIN_OTP|RESET_PASSWORD|INVITE_ACCEPT)
- target (phone/email)
- otpHash (or tokenHash)
- expiresAt
- maxAttempts, attemptsUsed
- consumedAt (nullable)
- createdAt

### 5.5 Invite
Admin-driven onboarding token.
Fields:
- id
- tenantId
- emailOrPhone
- invitedRoleHints (optional; final roles assigned in role-permission-service)
- status (SENT|ACCEPTED|EXPIRED|REVOKED)
- tokenHash
- expiresAt
- invitedBy
- createdAt, acceptedAt

### 5.6 Session
Tracks active logins.
Fields:
- id
- userId
- tenantId
- refreshTokenHash
- deviceId (nullable)
- userAgent (nullable)
- ipHash (nullable)
- createdAt
- lastUsedAt
- expiresAt
- revokedAt (nullable)
- revokeReason (nullable)

### 5.7 AccessTokenClaims (DTO)
Minimal claims included in access token.
Fields:
- userId
- tenantId
- sessionId
- issuedAt, expiresAt
- authLevel (PASSWORD|OTP|SSO) (optional)
- version (token schema version)

### 5.8 Auth Requests/Responses (DTOs)
- SignupRequest: tenantId, email/phone, password (optional), name(optional), joinMethod
- LoginRequest: tenantId, identifier(email/phone), password or otp
- RefreshRequest: refreshToken
- VerifyOtpRequest: challengeId, otp
- ResetPasswordRequest: identifier, challengeId, newPassword
- AuthResponse: accessToken, refreshToken, expiresIn, userId, tenantId

---

## 6) APIs (Suggested)

### 6.1 Signup / Onboarding
- POST /auth/signup
  - Creates UserIdentity (PENDING) + TenantMembership (PENDING_APPROVAL or PENDING_VERIFICATION)
- POST /auth/invite
  - Admin-only: create Invite and send email/SMS (via notification-service)
- POST /auth/invite/accept
  - Accept invite token, create/attach identity, start verification if needed

### 6.2 Verification / OTP
- POST /auth/otp/send
  - purpose: LOGIN_OTP | SIGNUP_VERIFY | RESET_PASSWORD
- POST /auth/otp/verify
  - verify challenge (returns partial auth or completes flow)

### 6.3 Login / Tokens
- POST /auth/login
  - password login or triggers OTP flow depending on tenant policy
- POST /auth/token/refresh
- POST /auth/logout
- POST /auth/logout/all

### 6.4 Password / Credential Management
- POST /auth/password/forgot
- POST /auth/password/reset
- POST /auth/password/change

### 6.5 Introspection (service-to-service)
- POST /auth/token/introspect
  - Used by api-gateway/internal services if needed (or rely on JWT verification)

### 6.6 Tenant membership approval (if required)
- POST /tenants/{tenantId}/memberships/{membershipId}/approve
- POST /tenants/{tenantId}/memberships/{membershipId}/suspend

---

## 7) Typical Flows

### 7.1 Self-signup (with approval)
1) POST /auth/signup -> create identity + membership (PENDING_APPROVAL)
2) Send verification challenge (email/OTP)
3) Verify -> membership stays PENDING_APPROVAL until tenant admin approves
4) Admin approves -> membership ACTIVE
5) User can login -> tokens issued

### 7.2 Invite onboarding
1) Admin creates invite -> /auth/invite
2) User accepts invite -> /auth/invite/accept
3) Verify email/phone -> membership ACTIVE (or PENDING_APPROVAL based on tenant policy)
4) Roles assigned separately via role-permission-service (orchestrated by admin-console-service)

### 7.3 Login with refresh
1) POST /auth/login -> create Session + return tokens
2) Access token expires -> POST /auth/token/refresh -> rotate refresh token, update session

---

## 8) Security Policies (MVP)
- Password hashing: Argon2id or bcrypt (strong parameters)
- OTP:
  - short expiry (e.g., 5 min), max attempts (e.g., 5)
  - resend cooldown (e.g., 30–60 sec)
- Rate limiting by IP + identifier + tenant
- Account lockouts after repeated failures (with unlock window)
- Refresh token rotation and reuse detection
- Audit all sensitive actions (invite, reset, role-admin actions via other service)

---

## 9) Events (Recommended)
Publish to an event bus (or call audit-log-service):
- UserIdentityCreated
- TenantMembershipCreated / Approved / Suspended
- InviteCreated / Accepted / Revoked
- LoginSucceeded / LoginFailed
- SessionCreated / SessionRevoked
- PasswordChanged / PasswordReset
These events help notification-service, analytics-service, and audit-log-service.

---

## 10) Storage Notes
Suggested tables:
- user_identities
- tenant_memberships
- verification_challenges
- invites
- sessions

Indexes:
- user_identities: (primary_email), (primary_phone)
- tenant_memberships: (tenant_id, user_id), (tenant_id, status)
- sessions: (user_id), (tenant_id), (refresh_token_hash)
- verification_challenges: (target, purpose), (expires_at)

All PII fields should be encrypted at rest when possible (or at least protected by strict access policies).

---

## 11) Integration Points
- notification-service: send OTP/invite messages (SMS/Email/WhatsApp later)
- tenant-service: read tenant auth policies (OTP-only? approval required? allowed domains?)
- role-permission-service: roles assigned after identity exists (or via orchestration)
- api-gateway: validates access tokens, enforces rate limits, forwards user context

---

## 12) Docker Deployment

### Docker Compose
The service includes `docker-compose.yml` with PostgreSQL database:
- **Service Port**: 8081
- **PostgreSQL Port**: 5432
- **Network**: `learner-network` (bridge)
- **Health checks**: PostgreSQL readiness + service actuator

**Quick start:**
```bash
docker-compose up -d
```

### Gradle Docker Tasks
Build and deploy using Gradle:

| Task | Description |
|------|-------------|
| `./gradlew dockerBuild` | Build Docker image |
| `./gradlew dockerStop` | Stop and remove container |
| `./gradlew dockerRun` | Build and run container (requires PostgreSQL) |
| `./gradlew dockerDeploy` | Full build + deploy with status |
| `./gradlew dockerLogs` | View container logs |
| `./gradlew dockerStatus` | Check container status |

**Note:** `dockerRun` assumes PostgreSQL is running (via docker-compose or separately).

### Environment Variables
```yaml
SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/auth
SPRING_DATASOURCE_USERNAME=auth_user
SPRING_DATASOURCE_PASSWORD=auth_password
SERVICES_PROFILE_URL=http://host.docker.internal:8083
SERVICES_TENANT_URL=http://host.docker.internal:8082
```

END
