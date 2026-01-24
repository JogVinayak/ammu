Codex Context: Amogh content-service (Spring Boot, port 8085, Lombok)
Goal
Build content-service for the Amogh Project. This service is the source-of-truth metadata store for learning content (topics/modules/notes content records). It does NOT store the full note body Markdown (that is notes-service). Instead it stores canonical metadata: identity, tenant scope, ownership, tags, status, version pointers, relationships to topic/module, and basic lifecycle state.
Tech constraints
Java 17
Spring Boot 3.x
Maven
Port: 8085
Use Lombok to reduce verbosity (@Data, @Builder, @NoArgsConstructor, @AllArgsConstructor, @RequiredArgsConstructor, etc.)
Persistence: PostgreSQL via Spring Data JPA (Hibernate)
Validation: spring-boot-starter-validation
Security: assume requests come through api-gateway with JWT; content-service verifies token (simple) OR trusts gateway and enforces tenant/user headers. Implement both patterns safely:
Read X-Tenant-Id and X-User-Id headers (required)
Optionally accept Authorization: Bearer <jwt>; if present, validate signature via shared secret (config)
Observability: Actuator health endpoint
API docs: springdoc-openapi optional (nice-to-have)
Service responsibilities
Create and manage Content records (metadata for notes/modules/topics)
Tenant isolation: every record is scoped to tenantId
RBAC enforcement boundary: content-service checks role/permission via headers passed from gateway:
X-Role (or X-Permissions list). For now implement a simple check:
allow create/update if permission contains CONTENT_WRITE or role in {ADMIN, TEACHER, CREATOR}
allow read if CONTENT_READ or role in allowed roles
Version pointers:
currentVersion integer
latestDraftVersion integer (optional)
The “actual version content” lives in downstream services (notes-service / mindmap-service), referenced by contentId + version
Status/lifecycle (simple now, workflow later):
DRAFT, PUBLISHED, ARCHIVED
When content-workflow-service is introduced, it will control these transitions, but content-service must support them.
Search indexing hooks (no search-service dependency now):
Emit “content.changed” events to an outbox table (no Kafka required now). Provide an endpoint to fetch pending outbox events for later integration.
Non-responsibilities
Storing note body markdown/latex blocks
Handling approvals/review flows (content-workflow-service does)
Full-text search indexing itself
Data model (JPA Entities)
Content
Represents a canonical content object.
Fields:
UUID id
String tenantId (required)
ContentType type enum: NOTE, MODULE, TOPIC (expandable)
String title (required, 3..200)
String description (optional, up to 2000)
ContentStatus status enum: DRAFT, PUBLISHED, ARCHIVED
Integer currentVersion (default 1)
Integer latestDraftVersion (nullable)
String visibility enum/string: PRIVATE, TENANT, PUBLIC (for now: PRIVATE or TENANT)
UUID topicId (optional) — parent topic content id
UUID moduleId (optional) — parent module content id
UUID createdBy
UUID updatedBy
Instant createdAt
Instant updatedAt
boolean deleted (soft delete)
Indexes:
(tenantId, type, status)
(tenantId, topicId)
(tenantId, moduleId)
(tenantId, title) (for basic filtering)
ContentTag
UUID id
UUID contentId
String tenantId
String tag (lowercased, 1..50)
Unique constraint: (tenantId, contentId, tag)
OutboxEvent
UUID id
String tenantId
String aggregateType = "CONTENT"
UUID aggregateId = contentId
String eventType e.g. CONTENT_CREATED, CONTENT_UPDATED, CONTENT_STATUS_CHANGED, CONTENT_DELETED
String payloadJson (store compact JSON)
Instant createdAt
Instant publishedAt nullable
String status enum: PENDING, PUBLISHED
REST API (JSON), base path /v1/content
Headers required for all endpoints
X-Tenant-Id: <tenant-id> (string)
X-User-Id: <uuid>
X-Role: ADMIN|TEACHER|CREATOR|STUDENT|PARENT|MENTOR (string)
Optional: X-Permissions: CONTENT_READ,CONTENT_WRITE,... (comma-separated)
If headers missing -> 400 Bad Request.
If unauthorized -> 403 Forbidden.
1) Create content
POST /v1/content
Request:
{
  "type": "NOTE",
  "title": "Kinematics - Basics",
  "description": "Intro notes",
  "visibility": "TENANT",
  "topicId": "uuid-optional",
  "moduleId": "uuid-optional",
  "tags": ["physics", "motion"]
}
Response 201:
{
  "id": "uuid",
  "tenantId": "t1",
  "type": "NOTE",
  "title": "...",
  "description": "...",
  "status": "DRAFT",
  "currentVersion": 1,
  "latestDraftVersion": 1,
  "visibility": "TENANT",
  "topicId": null,
  "moduleId": null,
  "tags": ["physics","motion"],
  "createdAt": "...",
  "updatedAt": "..."
}
Rules:
default status DRAFT
set currentVersion=1, latestDraftVersion=1
2) Get by id
GET /v1/content/{id} → 200
3) List / search (basic filters)
GET /v1/content?type=NOTE&status=PUBLISHED&topicId=...&moduleId=...&q=kinematics&page=0&size=20&sort=updatedAt,desc
q does basic ILIKE on title/description only
Response 200 paged:
{
  "items": [ ... ],
  "page": 0,
  "size": 20,
  "total": 123
}
4) Update metadata
PATCH /v1/content/{id}
Request (partial):
{
  "title": "New title",
  "description": "Updated",
  "visibility": "PRIVATE",
  "topicId": "uuid-optional",
  "moduleId": "uuid-optional",
  "tags": ["new","tags"]
}
Response 200 updated DTO.
5) Change status
POST /v1/content/{id}/status
Request:
{ "status": "PUBLISHED" }
Rules:
allow transitions: DRAFT -> PUBLISHED, PUBLISHED -> ARCHIVED, DRAFT -> ARCHIVED
reject invalid transitions with 409 Conflict
6) Version bump (for downstream content updates)
POST /v1/content/{id}/versions/bump
Request:
{ "kind": "DRAFT" }
Rules:
If kind == DRAFT: increment latestDraftVersion (or set to currentVersion+1) and return it
If kind == PUBLISHED: set currentVersion = latestDraftVersion (if present) or currentVersion+1
Response:
{ "contentId":"uuid", "currentVersion":2, "latestDraftVersion":2 }
7) Soft delete
DELETE /v1/content/{id} sets deleted=true, status remains (or set ARCHIVED), emit outbox.
8) Outbox pull (for later integrations)
GET /v1/outbox?status=PENDING&limit=100
Returns events.
POST /v1/outbox/{eventId}/mark-published
Error handling (standard)
Return JSON:
{
  "error": "VALIDATION_ERROR",
  "message": "title must be between 3 and 200 chars",
  "traceId": "..."
}
Use @ControllerAdvice.
Code structure (packages)
com.amogh.contentservice
config (security, web)
controller
dto
entity
repository
service
util (tenant context, permission checks)
exception
Security / tenant rules
Every query must filter by tenantId from header.
Never allow cross-tenant access.
For now:
Read endpoints require role not empty; allow STUDENT read only if visibility == TENANT and not deleted.
Write endpoints require role in {ADMIN, TEACHER, CREATOR} OR permission contains CONTENT_WRITE.
Implement helper:
TenantContext resolved from headers in a OncePerRequestFilter and stored in ThreadLocal or request attribute.
AccessGuard with methods requireRead(), requireWrite().
application.yml defaults
server.port = 8085
datasource url/user/pass from env
JPA ddl-auto = update for dev
logging SQL off by default
actuator health enabled
Deliverables Codex should generate
Full Spring Boot project with Maven + Lombok configured
Entities, repositories, services, controllers as above
Validation annotations on DTOs
Pagination + filtering implementation
Outbox table + endpoints
Basic tests (optional): repository + controller smoke tests using H2
If you want, I can also give you a ready-to-run docker-compose.yml (Postgres + content-service) and a Postman collection to test Create → Bump Version → Publish → List.