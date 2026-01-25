# content-workflow-service — Context

> **Amogh Project** • Git-like content workflow: **draft → review → publish**  
> **Service Port:** `8086` • **Tech:** Spring Boot + Java • **Uses Lombok**

---

## 1) Purpose

`content-workflow-service` manages the **lifecycle of learning content** (notes/modules/topics) from creation to publication.  
It owns workflow state, approvals, change requests, reviewer assignments, and publishes workflow outcomes to downstream services.

### Why this service exists
- Keeps **workflow logic** out of `content-service` (which remains the “source of truth” for content metadata & versions).
- Enables **auditable approvals** and multi-step publishing for schools/tenants.
- Supports class/section assignments (optionally) via publication targets or integration events.

---

## 2) Core responsibilities

✅ Owns:
- **Workflow state machine**: `DRAFT → IN_REVIEW → APPROVED → PUBLISHED` (+ `REJECTED`, `ARCHIVED`)
- **Review tasks**: who must review, when, outcomes, comments
- **Change requests**: requested edits, re-review loops
- **Publish orchestration**: marks a content version as published (via `content-service`)
- **Audit trail** for every transition

🚫 Does **not** own:
- Content body/markdown/attachments storage (that’s `content-service`)
- User profile data (that’s `user-profile-service`)
- RBAC rules definition (that’s `role-permission-service`)
- Tenant configuration (that’s `tenant-service`)

---

## 3) Domain boundaries & entities

### Aggregate: `Workflow`
Represents the workflow for a **specific content version**.

- `workflowId` (UUID)
- `tenantId`
- `contentId` (from `content-service`)
- `contentVersionId` (immutable snapshot/version)
- `state` (enum)
- `createdBy`, `createdAt`
- `lastUpdatedBy`, `lastUpdatedAt`
- `currentStep` (optional)
- `publishTargets` (optional: class/grade/section/user scopes)
- `version` (optimistic lock)

### Entity: `ReviewTask`
- `taskId`, `workflowId`
- `assigneeUserId`
- `status`: `PENDING | APPROVED | REJECTED`
- `comment`, timestamps

### Entity: `ChangeRequest`
- `changeRequestId`, `workflowId`
- `requestedByUserId`
- `summary`, `details`
- `status`: `OPEN | RESOLVED | CANCELLED`

---

## 4) State machine

Typical flow:

1. **Create Draft** for a content version  
2. **Submit for Review** (assign reviewers)  
3. Reviewers **approve/reject**  
4. If rejected → back to `DRAFT` with change requests  
5. If approved → **publish** (calls `content-service` to mark version published)  
6. Publish emits events for read models / notifications

### Allowed transitions
| From | To | Trigger |
|---|---|---|
| DRAFT | IN_REVIEW | submitForReview |
| IN_REVIEW | APPROVED | all required reviewers approved |
| IN_REVIEW | REJECTED | any required reviewer rejects |
| REJECTED | DRAFT | author resumes edits |
| APPROVED | PUBLISHED | publish |
| PUBLISHED | ARCHIVED | archive |

> Use server-side validation to prevent illegal transitions.

---

## 5) REST API (internal)

**Base path:** `/workflow`  
All endpoints require: `X-Tenant-Id`, `Authorization: Bearer <jwt>`.

### 5.1 Create workflow for a content version
`POST /workflow`

Request:
```json
{
  "contentId": "cnt_123",
  "contentVersionId": "v_7",
  "titleSnapshot": "Quadratic Equations - Notes",
  "publishTargets": {
    "scope": "CLASS",
    "classIds": ["class_10A", "class_10B"]
  }
}
```

Response:
```json
{ "workflowId": "uuid", "state": "DRAFT" }
```

### 5.2 Get workflow
`GET /workflow/{workflowId}`

### 5.3 List workflows (filters)
`GET /workflow?contentId=&state=&createdBy=&page=&size=`

### 5.4 Submit for review
`POST /workflow/{workflowId}/submit`

Request:
```json
{
  "reviewerUserIds": ["u1","u2"],
  "requiredApprovals": 1,
  "note": "Please review for accuracy and syllabus alignment."
}
```

### 5.5 Review actions
Approve:
`POST /workflow/{workflowId}/reviews/{taskId}/approve`

Reject:
`POST /workflow/{workflowId}/reviews/{taskId}/reject`

Request:
```json
{ "comment": "Needs clearer explanation in example 2." }
```

### 5.6 Publish
`POST /workflow/{workflowId}/publish`

Request:
```json
{
  "publishAt": null,
  "publishTargets": {
    "scope": "CLASS",
    "classIds": ["class_10A"]
  }
}
```

### 5.7 Archive
`POST /workflow/{workflowId}/archive`

---

## 6) Events (recommended)

Publish domain events so other services can react without coupling.

### 6.1 Outgoing events
- `ContentWorkflowSubmitted`
- `ContentWorkflowApproved`
- `ContentWorkflowRejected`
- `ContentPublished` (load-bearing)
- `ContentArchived`

Example payload (`ContentPublished`):
```json
{
  "eventId": "uuid",
  "tenantId": "t_1",
  "workflowId": "w_1",
  "contentId": "cnt_123",
  "contentVersionId": "v_7",
  "publishTargets": {
    "scope": "CLASS",
    "classIds": ["class_10A"]
  },
  "publishedBy": "u_admin",
  "publishedAt": "2026-01-24T12:00:00Z"
}
```

### 6.2 Incoming events (optional)
- `ContentVersionCreated` (from `content-service`) to auto-create DRAFT workflow
- `UserDeactivated` (from auth/user-profile) to reassign review tasks

> Use an **outbox pattern** if you need strong delivery guarantees.

---

## 7) Data model (SQL)

### Table: `workflows`
- `workflow_id` (PK, UUID)
- `tenant_id` (indexed)
- `content_id` (indexed)
- `content_version_id` (indexed)
- `state`
- `publish_targets_json` (JSON)
- `created_by`, `created_at`
- `updated_by`, `updated_at`
- `lock_version` (BIGINT)

### Table: `review_tasks`
- `task_id` (PK, UUID)
- `workflow_id` (FK, indexed)
- `assignee_user_id` (indexed)
- `status`
- `comment`
- `created_at`, `updated_at`

### Table: `change_requests`
- `change_request_id` (PK, UUID)
- `workflow_id` (FK, indexed)
- `requested_by_user_id`
- `summary`, `details`
- `status`
- `created_at`, `updated_at`

---

## 8) Security & permissions

### Tenant isolation
- Require `X-Tenant-Id` on every request.
- Validate tenant membership via JWT claims or `auth-service` introspection.

### Authorization (examples)
- Create/submit draft: `CONTENT_AUTHOR` or `CONTENT_ADMIN`
- Review: `CONTENT_REVIEWER` (and must be assigned reviewer)
- Publish/archive: `CONTENT_PUBLISHER` or `CONTENT_ADMIN`

Integrate with:
- `role-permission-service` to validate permissions per tenant (RBAC/ABAC)
- `auth-service` for token validation/refresh

---

## 9) Integration with other services

### Depends on
- **content-service**: publish a specific `contentVersionId` (and optionally set visibility rules)
- **role-permission-service**: permission checks
- **tenant-service**: tenant policy (e.g., required approvals)
- **notification-service** (optional): notify reviewers / authors

### Suggested publish call to `content-service`
`POST /content/{contentId}/versions/{contentVersionId}/publish`
```json
{
  "tenantId": "t_1",
  "publishTargets": { "scope": "CLASS", "classIds": ["class_10A"] }
}
```

---

## 10) Observability & ops

- Health: `/actuator/health`
- Metrics: `/actuator/metrics`
- Tracing: OpenTelemetry (optional)
- Audit: store transition history and reviewer comments

---

## 11) Spring Boot configuration

### `application.yml`
```yaml
server:
  port: 8086

spring:
  application:
    name: content-workflow-service

  datasource:
    url: jdbc:postgresql://localhost:5432/amogh_workflow
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

Use Lombok to reduce boilerplate:

- `@Getter @Setter` (or `@Data` cautiously)
- `@Builder` for DTOs
- `@NoArgsConstructor @AllArgsConstructor`
- `@Slf4j` for logging
- Entities: avoid `@Data` to prevent equals/hashCode issues

Example DTO:
```java
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class SubmitWorkflowRequest {
  java.util.List<String> reviewerUserIds;
  Integer requiredApprovals;
  String note;
}
```

---

## 14) Open questions (for later)

- Do we allow **scheduled publish** (`publishAt`)?
- Should publishTargets support `USER`, `CLASS`, `SECTION`, `GRADE`, `TENANT` scopes?
- Do we need multi-step approval chains (e.g., Teacher → Moderator → Admin)?

---

**Owner:** Content Platform  
**Status:** Draft Context (v1)
