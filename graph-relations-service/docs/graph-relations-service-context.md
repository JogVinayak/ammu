# graph-relations-service — Context (Amogh Project)

> **Goal:** Maintain the **graph of learning**: nodes + edges (relations) with **edge strength/TTL**, user progress signals, and graph queries used by mind-map UI, revision engine, and access checks.

---

## 1) Service Identity

- **Service name:** `graph-relations-service`
- **Default port:** `8087` (configurable)
- **Tech:** Spring Boot (Java), Lombok, PostgreSQL, Liquibase, OpenAPI/Swagger
- **Auth:** JWT (validated at API Gateway); service performs authorization checks via role-permission-service (or embedded policy cache)
- **Tenant-aware:** **Yes** (every request resolved to a tenant; all data keyed by `tenant_id`)

---

## 2) What this service owns

### Owns (Source of Truth)
- **Graphs**: per-tenant, optionally per-class/per-user scopes
- **Nodes**: references to content entities (topic/module/note/flashcard/quiz/etc.) or abstract concept nodes
- **Edges / Relations**:
  - typed relation (e.g., `PREREQUISITE_OF`, `RELATED_TO`, `PART_OF`, `EXPLAINS`, `EXAMPLE_OF`)
  - **weight/strength** and **TTL (time-to-live)** fields
  - last interaction timestamps (reviewed/visited/answered)
  - optional directionality and confidence

### Does NOT own
- Actual content bodies (notes, questions, flashcards) → **content-service**
- User profile details → **user-profile-service**
- Roles/permissions definitions → **role-permission-service**
- Tenant creation and config → **tenant-service**

---

## 3) Key responsibilities

1. **Create/Update Graph Structure**
   - Create graphs (e.g., “Algebra Mind Map”, “Physics Class 10”)
   - Add/update/remove nodes and edges
   - Maintain graph integrity constraints (no cross-tenant links; optional cycle rules)

2. **Edge Strength + TTL Model**
   - Store & update `strength` and `ttl_hours` (or `ttl_days`)
   - Apply updates on learning signals (e.g., correct/incorrect, recall difficulty, time spent)
   - Provide “weak edges” / “due edges” queries for notifications & revision

3. **Graph Query APIs**
   - Fetch neighborhood (k-hop), subgraphs, paths
   - Search by node label / content reference
   - Provide lightweight graph payloads optimized for UI rendering

4. **Access Control Enforcement**
   - Ensure user can read/write graphs based on tenant and role
   - Optional: scope graphs to class/team/user

---

## 4) Data model (proposed)

> PostgreSQL tables (Liquibase-managed). UUIDs recommended.

### 4.1 `graphs`
- `id` (uuid, pk)
- `tenant_id` (uuid, indexed)
- `scope_type` (enum: `TENANT`, `CLASS`, `USER`, `COURSE`)
- `scope_id` (uuid, nullable) — class_id/user_id/course_id depending on scope
- `name` (text)
- `description` (text, nullable)
- `status` (enum: `DRAFT`, `PUBLISHED`, `ARCHIVED`) *(optional if workflow is separate)*
- `created_by` (uuid)
- `created_at`, `updated_at`

### 4.2 `nodes`
- `id` (uuid, pk)
- `tenant_id` (uuid, indexed)
- `graph_id` (uuid, fk -> graphs.id, indexed)
- `node_type` (enum: `CONTENT_REF`, `CONCEPT`, `TAG`, `CUSTOM`)
- `ref_service` (text, nullable) — e.g., `content-service`
- `ref_type` (text, nullable) — e.g., `NOTE`, `TOPIC`
- `ref_id` (uuid, nullable) — points to owning service entity
- `label` (text)
- `meta` (jsonb, nullable) — UI coords, color, extra attributes
- `created_at`, `updated_at`

**Constraints**
- unique(`tenant_id`, `graph_id`, `ref_service`, `ref_type`, `ref_id`) for `CONTENT_REF` nodes (optional)

### 4.3 `edges`
- `id` (uuid, pk)
- `tenant_id` (uuid, indexed)
- `graph_id` (uuid, fk -> graphs.id, indexed)
- `from_node_id` (uuid, fk -> nodes.id, indexed)
- `to_node_id` (uuid, fk -> nodes.id, indexed)
- `relation_type` (enum) — see section 5
- `directed` (boolean, default true)
- `strength` (numeric(6,3) or double precision) — 0.0..1.0 recommended
- `ttl_hours` (int) — decay horizon
- `last_reinforced_at` (timestamp, nullable)
- `last_reviewed_at` (timestamp, nullable)
- `meta` (jsonb, nullable) — evidence, notes, system flags
- `created_at`, `updated_at`

**Constraints**
- unique(`tenant_id`, `graph_id`, `from_node_id`, `to_node_id`, `relation_type`)

### 4.4 `edge_signals` (optional, event log)
- `id` (uuid, pk)
- `tenant_id`, `graph_id`, `edge_id`
- `user_id`
- `signal_type` (enum: `VIEW`, `RECALL_CORRECT`, `RECALL_WRONG`, `MARK_IMPORTANT`, `TIME_SPENT`)
- `signal_value` (numeric, nullable)
- `occurred_at` (timestamp)
- `meta` (jsonb)

---

## 5) Relation types (starter set)

- `PREREQUISITE_OF`
- `PART_OF`
- `RELATED_TO`
- `EXPLAINS`
- `EXAMPLE_OF`
- `DERIVED_FROM`
- `CONTRASTS_WITH`

> Keep relation types extensible (DB enum versioning via Liquibase or store as text).

---

## 6) API surface (proposed)

Base path (behind gateway): `/graph-relations/**`

### 6.1 Graphs
- `POST /graphs`
  - Create graph (tenant + scope + name)
- `GET /graphs/{graphId}`
- `GET /graphs?scopeType=&scopeId=&status=`
- `PATCH /graphs/{graphId}`
- `DELETE /graphs/{graphId}` *(soft-delete preferred)*

### 6.2 Nodes
- `POST /graphs/{graphId}/nodes`
- `GET /graphs/{graphId}/nodes?type=&refId=`
- `GET /graphs/{graphId}/nodes/{nodeId}`
- `PATCH /graphs/{graphId}/nodes/{nodeId}`
- `DELETE /graphs/{graphId}/nodes/{nodeId}`

### 6.3 Edges
- `POST /graphs/{graphId}/edges`
- `GET /graphs/{graphId}/edges?from=&to=&type=`
- `PATCH /graphs/{graphId}/edges/{edgeId}`
- `DELETE /graphs/{graphId}/edges/{edgeId}`

### 6.4 Graph queries
- `GET /graphs/{graphId}/subgraph?nodeId=&depth=2&limit=500`
- `GET /graphs/{graphId}/neighbors?nodeId=&depth=1`
- `GET /graphs/{graphId}/paths?fromNodeId=&toNodeId=&maxDepth=6`
- `GET /graphs/{graphId}/due-edges?userId=&asOf=2026-01-25T00:00:00Z&limit=200`
- `GET /graphs/{graphId}/weak-edges?threshold=0.35&limit=200`

### 6.5 Learning signals → edge reinforcement
- `POST /signals/edge-reinforcement`
  - Body: `{ graphId, edgeId, userId, signalType, signalValue, occurredAt }`
  - Effect: updates `strength`, `ttl_hours`, `last_reinforced_at`

> You can also accept signals by `fromRef/toRef` (content IDs) and resolve to edges internally.

---

## 7) Edge strength / TTL update rules (MVP)

Keep it simple and deterministic for MVP; evolve later.

### Inputs
- `signal_type` and `signal_value`
- last reinforced time
- current strength

### Example MVP rules
- `RECALL_CORRECT`: `strength = min(1.0, strength + 0.08)`
- `RECALL_WRONG`: `strength = max(0.0, strength - 0.12)`
- `TIME_SPENT`: boost capped by value, e.g. `+ min(0.05, minutes/600)`
- TTL policy:
  - If strength increases, set `ttl_hours = min(max_ttl, base_ttl * (1 + strength*2))`
  - If wrong, shrink TTL: `ttl_hours = max(min_ttl, ttl_hours * 0.75)`

### Due edge definition
An edge is **due** if:
- `last_reinforced_at` is null **OR**
- `now - last_reinforced_at >= ttl_hours`

---

## 8) Integrations (who calls whom)

### Inbound callers
- **Mind-map UI via api-gateway**: read/write graphs/nodes/edges, fetch subgraphs
- **content-service**: on content creation/update, create/update nodes or references
- **revision/notification components (future)**: query due/weak edges, submit reinforcement signals

### Outbound dependencies
- **tenant-service**: resolve tenant config (if not solely via gateway headers)
- **role-permission-service**: authorization checks (read/write graph)
- **content-service**: validate content references (optional at write time)
- **user-profile-service**: resolve user scope (optional; can rely on JWT claims)

---

## 9) Headers & tenant resolution

Standard headers (from gateway):
- `X-Tenant-Id: <uuid>`
- `X-User-Id: <uuid>`
- `Authorization: Bearer <jwt>`
- `X-Request-Id: <id>` *(recommended)*

Rule:
- Reject if `X-Tenant-Id` missing.
- Ensure all reads/writes filter by `tenant_id`.

---

## 10) Errors (standard)

- `400` validation failures (missing ids, depth too big, invalid enum)
- `401` missing/invalid token
- `403` insufficient role for operation
- `404` graph/node/edge not found in tenant scope
- `409` conflicts (duplicate node ref, duplicate edge, integrity constraint)
- `422` invalid graph operation (e.g., removing node with edges without cascade flag)

Error body (consistent):
```json
{
  "timestamp": "2026-01-25T12:00:00Z",
  "path": "/graph-relations/graphs/...",
  "errorCode": "GRAPH_EDGE_DUPLICATE",
  "message": "Edge already exists for the given nodes and relationType",
  "requestId": "..."
}
```

---

## 11) Observability

- **Health:** `/actuator/health`
- **Metrics:** `/actuator/metrics` (Prometheus optional)
- **Tracing:** include `X-Request-Id` and propagate; OpenTelemetry optional
- **Audit log:** record who changed graph structure (graph/node/edge mutations)

---

## 12) Suggested packages (Spring)

- `com.amogh.graphrelations.api` — controllers (REST)
- `com.amogh.graphrelations.domain` — entities, enums, domain rules
- `com.amogh.graphrelations.service` — use-cases
- `com.amogh.graphrelations.repo` — JPA repositories
- `com.amogh.graphrelations.security` — tenant + authorization helpers
- `com.amogh.graphrelations.config` — Spring config, OpenAPI, CORS
- `com.amogh.graphrelations.events` — event consumers/producers (optional)

---

## 13) Config (application.yml starter)

```yaml
server:
  port: 8087

spring:
  application:
    name: graph-relations-service
  datasource:
    url: jdbc:postgresql://localhost:5432/graph_relations
    username: graph_relations_user
    password: graph_relations_password
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
    maxDepth: 6
    maxNodesPerGraph: 20000
    maxEdgesPerGraph: 40000
```

---

## 14) MVP checklist

- [ ] CRUD for graphs/nodes/edges
- [ ] tenant scoping enforced everywhere
- [ ] unique constraints for node refs and edges
- [ ] subgraph query (k-hop) for UI
- [ ] due/weak edge queries
- [ ] reinforcement endpoint that updates `strength` + `ttl_hours`
- [ ] actuator health endpoint reachable through gateway
- [ ] OpenAPI docs enabled

---

## 15) Quick note on future expansions

- Class assignment integration (`scope_type=CLASS`) + roster checks
- Graph versioning (if workflow isn’t handled elsewhere)
- Materialized views for fast “due edges” queries at scale
- Recommendation engine: “next best edge to review”
