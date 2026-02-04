# recall-service — Context & Build Instructions (Amogh Project)

> **Goal:** Compute and store **next-study timeouts** for each **student + topic** based on the option the student selects after a recall attempt.

---

## 1) Service Identity

- **Service name:** `recall-service`
- **Default port:** `8091` (configurable)
- **Tech:** Spring Boot (Java), Lombok, PostgreSQL, Liquibase, OpenAPI/Swagger
- **Auth:** JWT validated at API Gateway; service trusts gateway headers
- **Tenant-aware:** **Yes** (every record is scoped by `tenant_id`)

---

## 2) What this service owns

### Owns (Source of Truth)
- **Recall schedule** per user + topic
- **Recall history** (events) for analytics/audit
- **Timeout calculation rules** based on selected option

### Does NOT own
- Topic metadata → `content-service`
- User accounts/profiles → `auth-service` / `user-profile-service`
- Roles & permissions → `role-permission-service`
- Graph relations/edges → `graph-relations-service`

---

## 3) Core responsibilities

1. **Record recall attempt**
   - Accepts student option (e.g., AGAIN/HARD/GOOD/EASY)
   - Computes next review time (`nextReviewAt`) and interval (`timeoutSeconds`)
   - Saves schedule + audit event

2. **Serve recall queue**
   - List topics due for review
   - Return schedule status for a topic

3. **Integrate with notifications**
   - Emit events for “due” topics (optional in MVP)

---

## 4) Data model (proposed)

> PostgreSQL tables (Liquibase-managed). UUIDs recommended.

### 4.1 `recall_schedule`
- `id` (uuid, pk)
- `tenant_id` (uuid, indexed)
- `user_id` (uuid, indexed)
- `topic_id` (uuid, indexed) — maps to ContentType `TOPIC` in `content-service`
- `last_option` (enum: `AGAIN`, `HARD`, `GOOD`, `EASY`)
- `interval_seconds` (bigint)
- `next_review_at` (timestamp with tz)
- `last_reviewed_at` (timestamp with tz)
- `streak` (int, default 0)
- `ease_factor` (numeric, optional; default 2.5 for SM-2 style)
- `lapse_count` (int, default 0)
- `created_at`, `updated_at`

**Constraints**
- unique(`tenant_id`, `user_id`, `topic_id`)

### 4.2 `recall_events`
- `id` (uuid, pk)
- `tenant_id`, `user_id`, `topic_id`
- `option` (enum)
- `time_spent_seconds` (int, nullable)
- `occurred_at` (timestamp with tz)
- `calculated_interval_seconds` (bigint)
- `next_review_at` (timestamp with tz)
- `meta` (jsonb, nullable)

---

## 5) API surface (proposed)

Base path (behind gateway): `/recall/**`  
Headers: `X-Tenant-Id`, `X-User-Id`, `Authorization: Bearer <jwt>`

### 5.1 Record recall attempt
`POST /recall/attempts`

Request:
```json
{
  "topicId": "uuid",
  "option": "GOOD",
  "occurredAt": "2026-02-01T08:30:00Z",
  "timeSpentSeconds": 45
}
```

Response:
```json
{
  "topicId": "uuid",
  "option": "GOOD",
  "intervalSeconds": 259200,
  "nextReviewAt": "2026-02-04T08:30:00Z",
  "streak": 3,
  "easeFactor": 2.6
}
```

### 5.2 Get recall schedule for a topic
`GET /recall/schedule/{topicId}`

### 5.3 Get due topics
`GET /recall/due?userId={uuid}&asOf=2026-02-01T00:00:00Z&limit=50`

### 5.4 Reset schedule (teacher/admin only)
`POST /recall/schedule/{topicId}/reset`

---

## 6) Timeout calculation rules (MVP)

Use **deterministic rules** so mobile/web see predictable results.  
The “option chosen by student” directly controls the interval.

### 6.1 Options
- `AGAIN` — “I didn’t recall it”
- `HARD` — “Barely recalled”
- `GOOD` — “Normal recall”
- `EASY` — “Very easy”

### 6.2 First-time review (no schedule exists)
| Option | Interval |
|--------|----------|
| AGAIN  | 10 minutes |
| HARD   | 1 day |
| GOOD   | 3 days |
| EASY   | 7 days |

### 6.3 Subsequent reviews
Let `prev = intervalSeconds`.

Multipliers:
- AGAIN → `0.5`
- HARD → `1.2`
- GOOD → `2.0`
- EASY → `3.0`

```
newInterval = clamp(prev * multiplier, min=600, max=15552000)
```

Where:
- `min = 600` seconds (10 minutes)
- `max = 15552000` seconds (180 days)

If option = `AGAIN`:
- reset `streak = 0`, `lapse_count += 1`

Else:
- `streak += 1`

Set:
```
nextReviewAt = occurredAt + newInterval
```

> You can later upgrade to SM-2 using `ease_factor` without changing the API.

---

## 7) Integrations

### 7.1 Inbound callers
- Mobile/web apps via **api-gateway**
- (Optional) mindmap UI if a node maps to a topic

### 7.2 Outbound dependencies (optional)
- `content-service` to validate `topicId`
- `notification-service` or event bus for due reminders

### 7.3 Events (recommended)
- `RecallAttemptRecorded`
- `RecallDue` (batch job emits when `next_review_at <= now`)

---

## 8) Build steps (implementation plan)

1. **Create module**
   - `recall-service/` with Spring Boot app
   - Gradle dependencies:
     - `spring-boot-starter-web`
     - `spring-boot-starter-data-jpa`
     - `spring-boot-starter-validation`
     - `postgresql`
     - `liquibase-core`
     - `lombok`
     - `springdoc-openapi-starter-webmvc-ui`

2. **Database & migrations**
   - Add Liquibase changelog for `recall_schedule` and `recall_events`
   - Index: `(tenant_id, user_id, next_review_at)` for due queries

3. **Controller + Service**
   - `RecallController` with endpoints in section 5
   - `RecallService` encapsulating timeout logic
   - DTOs for request/response

4. **Gateway routing**
   - Add route in `api-gateway`:
     - `/v1/recall/** -> recall-service /recall/**`

5. **Security / headers**
   - Require `X-Tenant-Id`, `X-User-Id` in all endpoints
   - Use role-permission for admin-only reset

6. **Tests**
   - Unit tests for interval calculation
   - Integration tests for due query + schedule updates

---

## 9) Example flow (student review)

1. Student studies Topic A and selects **GOOD**
2. `POST /recall/attempts` → returns `nextReviewAt = now + 3 days`
3. After 3 days, Topic A appears in `/recall/due`
4. Student selects **EASY** → interval grows to 9 days (3 * 3)

---

## 10) Open questions (decide before implementation)

- Should `topic_id` be required, or allow other content types (NOTE/MODULE)?
- Do we need per-class schedules (scope = CLASS)?
- Should missed reviews decay or auto-mark as AGAIN?

