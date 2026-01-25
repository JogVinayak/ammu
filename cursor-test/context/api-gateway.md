# api-gateway — Context File (Amogh Project) — Spring Boot + Postgres (optional) + Spring Cloud Gateway

## 0) Stack & Conventions
- Framework: **Spring Boot 4.x**
- Gateway tech: **Spring Cloud Gateway (MVC or Reactive)**  
  - Recommended for gateway: **Spring Cloud Gateway (Reactive)** for high concurrency and filters.
- Auth: JWT validation at gateway (resource server)
- Multi-tenancy: gateway resolves tenant and injects `X-Tenant-Id` (and optionally `X-Tenant-Key`)
- DB: **Not required** for MVP gateway (prefer stateless). Postgres optional only if you store route config / audit.
- Observability: Micrometer + Actuator, distributed tracing headers propagated

---

## 1) Purpose
`api-gateway` is the **single entry point** for all clients (web/mobile) into Amogh backend.
It handles cross-cutting concerns:
- Routing to microservices
- Authentication enforcement (JWT validation)
- Tenant resolution (hostname/subdomain/path/header)
- Coarse authorization gating (optional)
- Rate limiting and abuse protection
- Request/response normalization (correlation id, consistent errors)
- Central logging/metrics/tracing

The gateway must remain **thin**: no domain/business logic.

---

## 2) Responsibilities
### Does
- Reverse-proxy requests to internal services based on path rules
- Validate access tokens (JWT) and reject unauthorized requests
- Resolve tenant from request and inject tenant headers
- Enforce CORS and security headers
- Rate limit sensitive routes (OTP/login, signup) and expensive endpoints
- Apply timeouts, retries (carefully), and circuit breaker (optional)
- Standardize error responses and propagate request IDs

### Does NOT
- Store or own user/content/permission data
- Replace role-permission-service for fine-grained authorization
- Implement learning logic

---

## 3) Tenant Resolution Rules
Gateway should derive tenant context in this priority order (MVP):
1) If `X-Tenant-Id` provided by trusted internal callers -> accept (optional)
2) Else derive using:
   - `hostname` (subdomain/custom domain) -> call `tenant-service /v1/resolve?hostname=...`
   - OR `tenantKey` path prefix `/t/{tenantKey}/...` -> call `tenant-service /v1/resolve?tenantKey=...`
3) If still not found:
   - In local dev, default to `tenant_default` (config flag)

After resolving:
- Inject headers to downstream services:
  - `X-Tenant-Id: <UUID>`
  - `X-Tenant-Key: <tenantKey>` (optional)
  - `X-User-Id: <sub>` (optional convenience; downstream can parse JWT too)
- If tenant status is `SUSPENDED` or `DELETED`, return `403` with clear error.

Caching:
- Cache `/resolve` results with a short TTL (5–15 min) to avoid calling tenant-service per request.
- Invalidate cache on TenantUpdated/TenantSuspended events (optional; can just rely on TTL for MVP).

---

## 4) Authentication Model (JWT)
Gateway acts as a Resource Server:
- Public endpoints (no auth):
  - `/v1/auth/login`
  - `/v1/auth/signup` (if enabled)
  - `/v1/auth/otp/*`
  - `/v1/resolve` (internal-only recommended)
- Protected endpoints:
  - Everything else requires a valid access token

JWT validation:
- Use `issuer` and `jwks-uri` from auth-service (or shared JWKS)
- Validate signature + expiry + audience (if used)
- Extract claims:
  - `sub` = userId
  - `tenantId` (optional)
  - `roles/authorities` (optional; coarse gating only)

---

## 5) Coarse Authorization (Optional)
Gateway may block obviously forbidden paths to reduce load:
- `/v1/admin/**` requires `TENANT_ADMIN` or `SUPER_ADMIN`
- `/v1/tenants/**` management endpoints require `SUPER_ADMIN`

Fine-grained checks belong to services + role-permission-service.

---

## 6) Rate Limiting (Important for MVP)
Apply per-route rate limiting for:
- OTP send/verify endpoints
- Login attempts
- Signup
- Password reset

Keys:
- Prefer `IP + identifier` (email/phone) for auth routes
- For authenticated routes, `tenantId + userId` or `tenantId + IP`

Implementation options:
- In-memory (Caffeine) for dev
- Redis-backed rate limiter for production (recommended)

---

## 7) Routing Map (MVP)
Example routing prefixes (versioned):
- `/v1/auth/**` -> `auth-service`
- `/v1/tenants/**` + `/v1/resolve` -> `tenant-service`
- `/v1/permissions/**` + `/v1/authorize/**` -> `role-permission-service`
- `/v1/profiles/**` -> `user-profile-service`
- Later:
  - `/v1/content/**` -> content-service
  - `/v1/maps/**` -> mindmap-service
  - `/v1/revision/**` -> revision-scheduler-service
  - `/v1/notify/**` -> notification-service

Preferred approach: keep service paths stable; gateway owns public API layout.

---

## 8) Request/Response Normalization
### 8.1 Correlation ID
- If client provides `X-Request-Id`, keep it
- Else generate a UUID
- Propagate to downstream services
- Include in logs and error responses

### 8.2 Standard error format
Return consistent JSON errors:
```json
{
  "timestamp": "2026-01-24T10:00:00Z",
  "requestId": "uuid",
  "status": 401,
  "error": "UNAUTHORIZED",
  "message": "Missing or invalid token"
}
