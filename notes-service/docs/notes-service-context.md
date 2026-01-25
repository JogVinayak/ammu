# notes-service — Context (Amogh Project)

> **Goal:** Provide the **Notes domain**: authoring, storage, versioned note content (Markdown + LaTeX), metadata, tags, and read-optimized retrieval for students.  
> Notes-service is the *content body source-of-truth* for notes (unlike content-service which holds higher-level content catalog metadata).

---

## 1) Service Identity

- **Service name:** `notes-service`
- **Default port:** `8088` (configurable)
- **Tech:** Spring Boot (Java), Lombok, PostgreSQL, Liquibase, OpenAPI/Swagger
- **Auth:** JWT (validated at API Gateway). Notes-service enforces authorization via role-permission-service (or policy cache).
- **Tenant-aware:** **Yes** (all data keyed by `tenant_id`)

---

## 2) Ownership boundaries

### Owns (Source of Truth)
- Note content (Markdown with embedded LaTeX)
- Note metadata: title, summary, status, author, timestamps
- Note versions (immutable revisions)
- Draft/publish flags *at the note level* (or delegated to content-workflow-service; see section 6)

### Does NOT own
- Tenant config → tenant-service
- User profiles → user-profile-service
- Role/permission definitions → role-permission-service
- Cross-content cataloging (topics/modules mapping, global content registry) → content-service
- Git-like approvals/review process (if enabled) → content-workflow-service
- Graph edges/TTL (relations) → graph-relations-service

---

## 3) Core responsibilities

1. **CRUD Notes (Tenant-scoped)**
   - Create, edit, delete (soft delete)
   - Read for author/editor and for student (read-only views)

2. **Versioning**
   - Every publish (and optionally every save) creates a new version
   - Support diff-friendly storage via separate version table

3. **Search & Read Optimization**
   - Fetch by id, by tag, by owner, by class scope (if stored)
   - Provide “compiled” note view (latest published version + metadata)

4. **Access control**
   - Enforce read/write permissions per tenant + role
   - Provide “is user allowed to read this note?” decision endpoints for other services (optional)

---

## 4) Data model (proposed)

> PostgreSQL tables (Liquibase-managed). UUIDs recommended.

### 4.1 `notes`
Represents the note entity and its latest pointers.

- `id` (uuid, pk)
- `tenant_id` (uuid, indexed)
- `title` (text)
- `summary` (text, nullable)
- `status` (enum: `DRAFT`, `IN_REVIEW`, `PUBLISHED`, `ARCHIVED`)  
  *(If workflow is fully handled by content-workflow-service, keep only `PUBLISHED` boolean + `workflow_ref_id`.)*
- `created_by` (uuid)
- `updated_by` (uuid)
- `created_at`, `updated_at`
- `published_at` (timestamp, nullable)
- `latest_version_id` (uuid, fk -> note_versions.id, nullable)
- `latest_published_version_id` (uuid, fk -> note_versions.id, nullable)
- `is_deleted` (boolean, default false)

Indexes:
- (`tenant_id`, `status`)
- (`tenant_id`, `created_by`)
- (`tenant_id`, `updated_at`)

### 4.2 `note_versions`
Immutable revisions (content is stored here).

- `id` (uuid, pk)
- `tenant_id` (uuid, indexed)
- `note_id` (uuid, fk -> notes.id, indexed)
- `version_no` (int) — monotonically increasing per note
- `content_md` (text) — Markdown with embedded LaTeX
- `content_hash` (text, nullable) — for dedupe/integrity
- `change_summary` (text, nullable)
- `created_by` (uuid)
- `created_at` (timestamp)

Constraints:
- unique(`tenant_id`, `note_id`, `version_no`)

### 4.3 `note_tags`
Many-to-many tags per note (tags stored as text for MVP).

- `tenant_id` (uuid, indexed)
- `note_id` (uuid, indexed)
- `tag` (text)
- `created_at` (timestamp)

Constraint:
- unique(`tenant_id`, `note_id`, `tag`)

### 4.4 `note_acl` (optional, if you need fine-grained assignment)
For MVP, you can keep access control via scope fields; ACL table is optional.

Option A: Scope fields on `notes`
- `scope_type` (enum: `TENANT`, `CLASS`, `USER`, `COURSE`)
- `scope_id` (uuid, nullable)

Option B: Dedicated ACL
- `tenant_id`
- `note_id`
- `principal_type` (enum: `USER`, `ROLE`, `CLASS`)
- `principal_id` (uuid)
- `permission` (enum: `READ`, `WRITE`)

---

## 5) Content format rules (non-negotiable)

- Store note content in **Markdown**
- Math stored as **embedded LaTeX** (never images or rendered HTML)
- Rendering happens in clients:
  - Web: KaTeX
  - Mobile: Flutter math renderer equivalent

---

## 6) Workflow & publishing (two workable patterns)

### Pattern A — Notes-service owns lightweight status
- Notes-service has `status` and transitions:
  - `DRAFT -> PUBLISHED`
  - Optional: `IN_REVIEW` if you want
- content-workflow-service is optional or later.

### Pattern B — content-workflow-service owns workflow (recommended for “Git-like”)
- Notes-service stores:
  - versions
  - a simple `published_version_id`
- Workflow service orchestrates:
  - draft/review/publish approvals
  - then calls Notes-service to set published version

> Either way: **students read only published versions**.

---

## 7) API surface (proposed)

Base path (behind gateway): `/notes/**`

### 7.1 Notes CRUD
- `POST /notes`
  - Create note (creates version 1 as draft)
- `GET /notes/{noteId}`
  - Default: returns latest published version for student role; latest for editors if allowed
- `PATCH /notes/{noteId}`
  - Updates note metadata (title/summary/tags/scope)
- `DELETE /notes/{noteId}`
  - Soft delete

### 7.2 Versions
- `POST /notes/{noteId}/versions`
  - Create new version (draft save)
- `GET /notes/{noteId}/versions`
- `GET /notes/{noteId}/versions/{versionId}`
- `POST /notes/{noteId}/publish`
  - Publish a version (body: `{ "versionId": "..." }`)
  - Sets `latest_published_version_id`, `published_at`, `status=PUBLISHED`

### 7.3 Queries
- `GET /notes?tag=&createdBy=&status=&scopeType=&scopeId=&q=`
- `GET /notes/{noteId}/render`
  - Returns: `{ title, content_md, ... }` (client renders Markdown + LaTeX)

### 7.4 Access check (optional helper endpoint)
- `GET /notes/{noteId}/access?userId=...`
  - Returns: `{ canRead: true/false, canWrite: true/false }`

---

## 8) Events & integrations

### Events produced (optional, via Kafka/RabbitMQ later)
- `NOTE_CREATED`
- `NOTE_VERSION_CREATED`
- `NOTE_PUBLISHED`
- `NOTE_DELETED`

### Events consumed (optional)
- From content-service:
  - `CONTENT_TOPIC_UPDATED` (to update tags/links if you store them)
- From workflow-service:
  - `WORKFLOW_PUBLISH_APPROVED` (then publish the version)

### Service-to-service calls
- role-permission-service for authorization decisions
- user-profile-service optional (resolve student/class membership if needed for scope checks)
- content-service optional (catalog linkage)

---

## 9) Security & tenant headers

Headers from gateway:
- `X-Tenant-Id: <uuid>`
- `X-User-Id: <uuid>`
- `Authorization: Bearer <jwt>`
- `X-Request-Id: <id>`

Rules:
- Reject missing tenant header
- Every query filters by `tenant_id`
- Students: only published versions
- Admin/Teacher/Creator: draft + history as permitted

---

## 10) Errors (standard)

- `400` validation failures (missing title, invalid scope, bad markdown length)
- `401` invalid token
- `403` insufficient permission
- `404` note/version not found for tenant
- `409` conflicts (publishing older version, duplicate tag)
- `422` invalid state transitions (e.g., publish deleted note)

Consistent error body:
```json
{
  "timestamp": "2026-01-25T12:00:00Z",
  "path": "/notes/...",
  "errorCode": "NOTE_PUBLISH_INVALID_STATE",
  "message": "Cannot publish a deleted note",
  "requestId": "..."
}
```

---

## 11) Observability

- Health: `/actuator/health`
- Metrics: `/actuator/metrics`
- Tracing: propagate `X-Request-Id`

---

## 12) Suggested packages (Spring)

- `com.amogh.notes.api`
- `com.amogh.notes.domain`
- `com.amogh.notes.service`
- `com.amogh.notes.repo`
- `com.amogh.notes.security`
- `com.amogh.notes.config`
- `com.amogh.notes.events` *(optional)*

---

## 13) Config (application.yml starter)

```yaml
server:
  port: 8088

spring:
  application:
    name: notes-service
  datasource:
    url: jdbc:postgresql://localhost:5432/notes
    username: notes_user
    password: notes_password
  jpa:
    hibernate:
      ddl-auto: none
  liquibase:
    change-log: classpath:db/changelog/db.changelog-master.yaml

amogh:
  tenancy:
    headerTenantId: X-Tenant-Id
  auth:
    permissionsServiceBaseUrl: http://localhost:8080
  limits:
    maxNoteSizeChars: 200000
    maxVersionsPerNote: 500
```

---

## 14) MVP checklist

- [ ] Create note + version 1
- [ ] Create new versions (draft saves)
- [ ] Publish version (students see only published)
- [ ] List notes with filters (tag, createdBy, status)
- [ ] Tenant enforcement everywhere
- [ ] Soft delete
- [ ] Actuator health works through gateway
- [ ] OpenAPI docs enabled

---

## 15) Notes on future expansion

- Full-text search (Postgres tsvector or OpenSearch) across published notes
- Rich tagging taxonomy (tag-service) vs plain text tags
- Attachments (pdf/images) handled by separate storage service (avoid stuffing DB)
- Student annotations as separate service/table (future feature)
