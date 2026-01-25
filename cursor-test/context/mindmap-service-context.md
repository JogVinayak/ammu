# mindmap-service — Context

> **Amogh Project** • Mind maps as the primary learning graph: nodes + edges + edge strength/TTL  
> **Tech:** Spring Boot + Java • **Uses Lombok**  
> **Note:** Port can be set per deployment; keep consistent with your service registry.

---

## 1) Purpose

`mindmap-service` stores and serves **mind maps** (graph of concepts) for learning and revision.  
It owns the **graph structure**, **versioning**, and **learning signals** such as **edge strength** and **TTL** that drive spaced revision notifications.

Mind maps are **tenant-aware** and can be:
- **Global** (tenant content) authored by admins/teachers/creators
- **Student-accessible** (read-only in MVP; annotations later)
- **Assigned** to classes/sections/users via integration events or targets

---

## 2) Core responsibilities

✅ Owns:
- Mind map graph structure: **Nodes**, **Edges**
- Map metadata: title, syllabus tags, subject, grade, visibility
- **Versioning**: draft/published versions (optionally integrated with `content-workflow-service`)
- Edge learning signals:
  - `strength` (0..1 or 0..100)
  - `ttlSeconds` or `expiresAt` (edge “decay”)
  - last reviewed timestamps
- Query APIs optimized for clients (fetch graph, fetch subtree, search nodes)
- Audit trail (optional)

🚫 Does **not** own:
- User accounts & profiles (`auth-service`, `user-profile-service`)
- RBAC rules (`role-permission-service`)
- Tenant policies/config (`tenant-service`)
- Note bodies/learning content store (`content-service`) — but nodes can link to content IDs

---

## 3) Conceptual model

### 3.1 MindMap
- `mindMapId` (UUID)
- `tenantId`
- `title`, `description`
- `subject`, `grade`, `tags[]`
- `status`: `DRAFT | PUBLISHED | ARCHIVED`
- `visibility`: `PRIVATE | TENANT | ASSIGNED`
- `createdBy`, timestamps
- `publishedVersionId` (optional pointer)
- `version` (optimistic lock)

### 3.2 MindMapVersion (optional but recommended)
- `mindMapVersionId` (UUID)
- `mindMapId`
- `versionNumber` (int)
- `status`: `DRAFT | PUBLISHED`
- `snapshotJson` (graph snapshot) OR normalized nodes/edges per version
- `createdBy`, timestamps

> If you expect heavy graph edits + need diffs, keep nodes/edges normalized and store a “published version marker”.
> If you want simplicity, store a snapshot JSON per version.

### 3.3 Node
- `nodeId` (UUID)
- `mindMapId` (or versionId)
- `type`: `CONCEPT | TOPIC | SUBTOPIC | NOTE_REF | QUESTION | FORMULA`
- `title` (short label)
- `bodyMarkdown` (optional; keep light)  
- `contentRef`: `{ contentId, contentVersionId }` (optional link to `content-service`)
- `position`: `{x,y}` (UI)
- `metaJson` (optional: difficulty, syllabus code, etc.)

### 3.4 Edge
- `edgeId` (UUID)
- `mindMapId` (or versionId)
- `fromNodeId`
- `toNodeId`
- `relation`: `PREREQ | EXPLAINS | PART_OF | RELATED`
- `weight` (base edge thickness)
- Learning signals:
  - `strength` (float)
  - `ttlSeconds` (long) OR `expiresAt`
  - `lastReviewedAt`
  - `nextReviewAt` (optional, derived)

---

## 4) Edge strength & TTL (Amogh logic)

The system gradually weakens edges over time and strengthens after active recall.

### Recommended fields
- `strength`: current mastery (0..1)
- `lastReviewedAt`
- `ttlSeconds`: how long before it becomes “weak”
- `expiresAt`: derived = lastReviewedAt + ttlSeconds

### Typical actions
- **Review edge** (after recall): increase `strength`, extend `ttlSeconds`, set `lastReviewedAt`
- **Decay job** (optional): compute weak edges by `expiresAt <= now`
- **Notification integration**: emit events when edges become weak

> In MVP, you can compute “weak edges” on read, without a background job, using `expiresAt` comparisons.

---

## 5) REST API (internal)

**Base path:** `/mindmaps`  
All endpoints require: `X-Tenant-Id`, `Authorization: Bearer <jwt>`.

### 5.1 Create mind map
`POST /mindmaps`

Request:
```json
{
  "title": "Quadratic Equations",
  "subject": "Math",
  "grade": "10",
  "tags": ["algebra"],
  "visibility": "TENANT"
}
```

Response:
```json
{ "mindMapId": "uuid", "status": "DRAFT" }
```

### 5.2 Get mind map metadata
`GET /mindmaps/{mindMapId}`

### 5.3 Fetch full graph
`GET /mindmaps/{mindMapId}/graph?version=published|draft|<versionId>`

Response:
```json
{
  "mindMapId": "uuid",
  "version": "published",
  "nodes": [ { "nodeId":"...", "title":"..." } ],
  "edges": [ { "edgeId":"...", "fromNodeId":"...", "toNodeId":"...", "strength":0.62, "expiresAt":"..." } ]
}
```

### 5.4 Upsert node
`PUT /mindmaps/{mindMapId}/nodes/{nodeId}`

### 5.5 Delete node
`DELETE /mindmaps/{mindMapId}/nodes/{nodeId}`

> Deleting a node should also delete incident edges (or reject if edges exist; choose one policy).

### 5.6 Upsert edge
`PUT /mindmaps/{mindMapId}/edges/{edgeId}`

### 5.7 Delete edge
`DELETE /mindmaps/{mindMapId}/edges/{edgeId}`

### 5.8 Publish
`POST /mindmaps/{mindMapId}/publish`

Request:
```json
{
  "publishTargets": { "scope": "CLASS", "classIds": ["class_10A"] }
}
```

### 5.9 Search nodes (autocomplete)
`GET /mindmaps/{mindMapId}/nodes/search?q=quadratic&limit=20`

### 5.10 Record recall/review on edges
`POST /mindmaps/{mindMapId}/edges/{edgeId}/review`

Request:
```json
{
  "userId": "u_student_1",
  "result": "CORRECT",
  "difficulty": 2,
  "timeSpentSeconds": 45
}
```

Response:
```json
{
  "edgeId": "uuid",
  "strength": 0.71,
  "ttlSeconds": 172800,
  "expiresAt": "2026-01-26T12:00:00Z"
}
```

### 5.11 Get weak edges for a user (revision queue)
`GET /mindmaps/revision/weak?userId=u1&limit=50`

Returns edges where `expiresAt <= now` or `strength < threshold`.

---

## 6) Events (recommended)

### 6.1 Outgoing events
- `MindMapPublished` (load-bearing)
- `MindMapUpdated` (optional)
- `EdgeReviewed` (for analytics)
- `EdgesBecameWeak` (for notification system)

Example payload (`MindMapPublished`):
```json
{
  "eventId": "uuid",
  "tenantId": "t_1",
  "mindMapId": "m_1",
  "publishedVersionId": "mv_3",
  "publishTargets": { "scope": "CLASS", "classIds": ["class_10A"] },
  "publishedBy": "u_admin",
  "publishedAt": "2026-01-24T12:00:00Z"
}
```

### 6.2 Incoming events (optional)
- `ContentPublished` (from content-workflow/content-service) to link notes to nodes or update references
- `ClassRosterChanged` (from roster/class service if you have it) to recompute assignments
- `UserDeactivated` to revoke access or remove reviewer/assignee refs

---

## 7) Data model (SQL) — normalized graph

### Table: `mind_maps`
- `mind_map_id` (PK, UUID)
- `tenant_id` (indexed)
- `title`, `description`
- `subject`, `grade`
- `tags_json` (JSON)
- `status`
- `visibility`
- `created_by`, `created_at`
- `updated_by`, `updated_at`
- `published_version_id` (nullable)
- `lock_version` (BIGINT)

### Table: `mind_map_versions`
- `mind_map_version_id` (PK, UUID)
- `mind_map_id` (FK, indexed)
- `version_number` (int)
- `status`
- `created_by`, `created_at`

> Alternative: skip versions and keep only `mind_maps` + nodes/edges, with an audit table.  
> If you need “draft vs published”, versions are worth it.

### Table: `nodes`
- `node_id` (PK, UUID)
- `tenant_id` (indexed)
- `mind_map_id` (FK, indexed) OR `mind_map_version_id` (FK)
- `type`
- `title`
- `body_markdown` (TEXT, optional)
- `content_id` (nullable)
- `content_version_id` (nullable)
- `pos_x`, `pos_y`
- `meta_json` (JSON)
- `created_at`, `updated_at`

### Table: `edges`
- `edge_id` (PK, UUID)
- `tenant_id` (indexed)
- `mind_map_id` (FK, indexed) OR `mind_map_version_id` (FK)
- `from_node_id` (indexed)
- `to_node_id` (indexed)
- `relation`
- `weight` (float/int)
- `strength` (float)
- `ttl_seconds` (bigint)
- `last_reviewed_at` (timestamp)
- `expires_at` (timestamp, indexed)
- `created_at`, `updated_at`

### Table: `map_assignments` (optional)
- `assignment_id` (PK)
- `tenant_id` (indexed)
- `mind_map_id`
- `scope`: `CLASS | SECTION | USER | TENANT`
- `class_id` / `section_id` / `user_id` (nullable)
- `created_at`

---

## 8) Security & permissions

### Tenant isolation
- Require `X-Tenant-Id` on every request.
- Validate tenant membership via JWT claims or auth introspection.

### Authorization (examples)
- Create/edit mind maps: `MAP_AUTHOR` or `CONTENT_ADMIN`
- Publish: `MAP_PUBLISHER` or `CONTENT_ADMIN`
- Students: `MAP_VIEWER` with assignment checks (or ABAC: enrolled-in-class)
- Review edge: student must have read access to the map and edge

Integrate with:
- `role-permission-service` for tenant RBAC/ABAC
- `user-profile-service` (optional) for student/class metadata
- A roster service if you build one later

---

## 9) Integration patterns

### Links from mind maps to content
- Nodes can reference:
  - `contentId`
  - `contentVersionId` (published)
- Frontend fetches node graph from `mindmap-service`, then fetches note bodies from `content-service`.

### Assignment model
Two viable options:
1. Store `publishTargets` / `map_assignments` in `mindmap-service`
2. Let `content-workflow-service` be the “assignment authority” and emit events like `MindMapAssigned`

---

## 10) Performance considerations

- Return compressed graph payloads (gzip) for large maps.
- Support “subgraph” endpoints (future):
  - `/graph/subtree?rootNodeId=...&depth=...`
- Add indexes on:
  - `tenant_id`, `mind_map_id`, `expires_at`, `from_node_id`, `to_node_id`

---

## 11) Spring Boot configuration

### `application.yml`
```yaml
server:
  port: 8080  # set in deployment (example)

spring:
  application:
    name: mindmap-service

  datasource:
    url: jdbc:postgresql://localhost:5432/amogh_mindmaps
    username: amogh
    password: amogh
  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        format_sql: true

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics
```

---

## 12) Build dependencies (Maven)

> Lombok enabled.

```xml
<dependencies>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
  </dependency>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
  </dependency>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
  </dependency>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
  </dependency>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
  </dependency>

  <dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
  </dependency>

  <dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
  </dependency>

  <!-- Optional: OpenAPI -->
  <dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.6.0</version>
  </dependency>
</dependencies>
```

---

## 13) Lombok conventions (recommended)

- DTOs: `@Value`, `@Builder`
- Services: `@Slf4j`, constructor injection with `@RequiredArgsConstructor`
- Entities: avoid `@Data`; prefer `@Getter @Setter` + explicit equals/hashCode if needed

Example DTO:
```java
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class ReviewEdgeRequest {
  String userId;
  String result; // CORRECT/WRONG/PARTIAL
  Integer difficulty;
  Integer timeSpentSeconds;
}
```

---

## 14) Open questions (for later)

- Do we store student-specific edge strength **per user** or globally per map?
  - MVP: global for map (simple)
  - Next: per-user strengths in `edge_user_state` table
- Do we allow student annotations in MVP?
  - Current decision: read-only for students; annotations later.

---

**Owner:** Learning Graph Platform  
**Status:** Draft Context (v1)
