# Content Service - Amogh Project

## Overview

**Service Name:** content-service  
**Technology:** Spring Boot 3.x, Java 17  
**Port:** 8085  
**Database:** PostgreSQL

Content-service is the source-of-truth metadata store for learning content (topics/modules/notes) in the Amogh Project. It manages canonical metadata including identity, tenant scope, ownership, tags, status, version pointers, and relationships.

---

## Goal

Build a metadata management service for learning content that:
- Stores content metadata (NOT the full note body Markdown)
- Manages canonical metadata: identity, tenant scope, ownership, tags, status
- Tracks version pointers and relationships to topics/modules
- Maintains basic lifecycle state

---

## Tech Stack

- **Java:** 17
- **Framework:** Spring Boot 3.x
- **Build Tool:** Maven
- **Database:** PostgreSQL
- **ORM:** Spring Data JPA (Hibernate)
- **Port:** 8085
- **Libraries:**
  - Lombok (reduce verbosity)
  - spring-boot-starter-validation
  - springdoc-openapi (optional)
  - Spring Boot Actuator

---

## Service Responsibilities

### Core Functions
- Create and manage Content records (metadata for notes/modules/topics)
- Tenant isolation (every record scoped to tenantId)
- RBAC enforcement boundary
- Version pointer management
- Status/lifecycle management
- Search indexing hooks via outbox pattern

### Version Management
- **currentVersion:** Current published version (integer)
- **latestDraftVersion:** Latest draft version (optional, integer)
- Actual version content stored in downstream services (notes-service/mindmap-service)

### Status/Lifecycle
- **DRAFT:** Initial state
- **PUBLISHED:** Published content
- **ARCHIVED:** Archived content
- Workflow transitions managed by content-workflow-service (future)

### Outbox Pattern
- Emit "content.changed" events to outbox table
- No Kafka dependency required initially
- Endpoint provided to fetch pending outbox events

---

## Non-Responsibilities

❌ Storing note body markdown/latex blocks  
❌ Handling approvals/review flows (content-workflow-service)  
❌ Full-text search indexing itself

---

## Security Model

### Authentication & Authorization

**Header-Based Security:**
- Read `X-Tenant-Id` and `X-User-Id` headers (required)
- Optionally accept `Authorization: Bearer <jwt>`
- If JWT present, validate signature via shared secret

**Required Headers:**
- `X-Tenant-Id`: Tenant identifier (string)
- `X-User-Id`: User UUID
- `X-Role`: ADMIN|TEACHER|CREATOR|STUDENT|PARENT|MENTOR
- `X-Permissions`: Comma-separated permissions (optional)

**Permission Rules:**

**Write Operations:**
- Allowed if permission contains `CONTENT_WRITE`
- OR role in {ADMIN, TEACHER, CREATOR}

**Read Operations:**
- Allowed if permission contains `CONTENT_READ`
- OR role in allowed roles
- STUDENT can read only if visibility == TENANT and not deleted

**Tenant Isolation:**
- Every query MUST filter by tenantId from header
- NEVER allow cross-tenant access

---

## Data Model

### 1. Content Entity

Primary entity representing a canonical content object.

**Fields:**

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| tenantId | String | Required, Indexed | Tenant scope |
| type | ContentType | Required | NOTE, MODULE, TOPIC |
| title | String | Required, 3-200 chars | Content title |
| description | String | Optional, max 2000 | Content description |
| status | ContentStatus | Required | DRAFT, PUBLISHED, ARCHIVED |
| currentVersion | Integer | Default: 1 | Current published version |
| latestDraftVersion | Integer | Nullable | Latest draft version |
| visibility | String | Required | PRIVATE, TENANT, PUBLIC |
| topicId | UUID | Optional | Parent topic content id |
| moduleId | UUID | Optional | Parent module content id |
| createdBy | UUID | Required | Creator user id |
| updatedBy | UUID | Required | Last updater user id |
| createdAt | Instant | Auto | Creation timestamp |
| updatedAt | Instant | Auto | Last update timestamp |
| deleted | Boolean | Default: false | Soft delete flag |

**Enums:**

```
ContentType: NOTE, MODULE, TOPIC
ContentStatus: DRAFT, PUBLISHED, ARCHIVED
Visibility: PRIVATE, TENANT, PUBLIC
```

**Indexes:**
- (tenantId, type, status)
- (tenantId, topicId)
- (tenantId, moduleId)
- (tenantId, title)

---

### 2. ContentTag Entity

Manages tags associated with content.

**Fields:**

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| contentId | UUID | Required, FK | Reference to Content |
| tenantId | String | Required | Tenant scope |
| tag | String | Required, 1-50 chars | Tag name (lowercased) |

**Unique Constraint:** (tenantId, contentId, tag)

---

### 3. OutboxEvent Entity

Stores events for eventual consistency and downstream integrations.

**Fields:**

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| tenantId | String | Required | Tenant scope |
| aggregateType | String | Default: "CONTENT" | Aggregate type |
| aggregateId | UUID | Required | Content id |
| eventType | String | Required | Event type |
| payloadJson | String | Required | JSON payload |
| createdAt | Instant | Auto | Creation timestamp |
| publishedAt | Instant | Nullable | Publication timestamp |
| status | String | Required | PENDING, PUBLISHED |

**Event Types:**
- CONTENT_CREATED
- CONTENT_UPDATED
- CONTENT_STATUS_CHANGED
- CONTENT_DELETED

---

## REST API

**Base Path:** `/v1/content`  
**Format:** JSON

### Required Headers (All Endpoints)

```
X-Tenant-Id: <tenant-id>
X-User-Id: <uuid>
X-Role: ADMIN|TEACHER|CREATOR|STUDENT|PARENT|MENTOR
X-Permissions: CONTENT_READ,CONTENT_WRITE,... (optional)
```

**Error Responses:**
- Missing headers → 400 Bad Request
- Unauthorized → 403 Forbidden

---

### 1. Create Content

**Endpoint:** `POST /v1/content`

**Request Body:**
```json
{
  "type": "NOTE",
  "title": "Kinematics - Basics",
  "description": "Intro notes",
  "visibility": "TENANT",
  "topicId": "uuid-optional",
  "moduleId": "uuid-optional",
  "tags": ["physics", "motion"]
}
```

**Response:** 201 Created
```json
{
  "id": "uuid",
  "tenantId": "t1",
  "type": "NOTE",
  "title": "Kinematics - Basics",
  "description": "Intro notes",
  "status": "DRAFT",
  "currentVersion": 1,
  "latestDraftVersion": 1,
  "visibility": "TENANT",
  "topicId": null,
  "moduleId": null,
  "tags": ["physics", "motion"],
  "createdAt": "2025-01-24T10:30:00Z",
  "updatedAt": "2025-01-24T10:30:00Z"
}
```

**Rules:**
- Default status: DRAFT
- Set currentVersion=1, latestDraftVersion=1

---

### 2. Get Content by ID

**Endpoint:** `GET /v1/content/{id}`

**Response:** 200 OK (same structure as create response)

---

### 3. List/Search Content

**Endpoint:** `GET /v1/content`

**Query Parameters:**
- `type`: ContentType filter (NOTE, MODULE, TOPIC)
- `status`: ContentStatus filter
- `topicId`: Filter by parent topic
- `moduleId`: Filter by parent module
- `q`: Text search (ILIKE on title/description)
- `page`: Page number (default: 0)
- `size`: Page size (default: 20)
- `sort`: Sort field and direction (e.g., updatedAt,desc)

**Example:**
```
GET /v1/content?type=NOTE&status=PUBLISHED&q=kinematics&page=0&size=20&sort=updatedAt,desc
```

**Response:** 200 OK
```json
{
  "items": [
    {
      "id": "uuid",
      "tenantId": "t1",
      "type": "NOTE",
      "title": "Kinematics - Basics",
      "status": "PUBLISHED",
      ...
    }
  ],
  "page": 0,
  "size": 20,
  "total": 123
}
```

---

### 4. Update Content Metadata

**Endpoint:** `PATCH /v1/content/{id}`

**Request Body (Partial):**
```json
{
  "title": "New title",
  "description": "Updated description",
  "visibility": "PRIVATE",
  "topicId": "uuid-optional",
  "moduleId": "uuid-optional",
  "tags": ["new", "tags"]
}
```

**Response:** 200 OK (updated content DTO)

---

### 5. Change Content Status

**Endpoint:** `POST /v1/content/{id}/status`

**Request Body:**
```json
{
  "status": "PUBLISHED"
}
```

**Response:** 200 OK

**Allowed Transitions:**
- DRAFT → PUBLISHED
- PUBLISHED → ARCHIVED
- DRAFT → ARCHIVED

**Invalid transitions:** 409 Conflict

---

### 6. Version Bump

**Endpoint:** `POST /v1/content/{id}/versions/bump`

**Request Body:**
```json
{
  "kind": "DRAFT"
}
```

**Rules:**
- `kind == DRAFT`: Increment latestDraftVersion (or set to currentVersion+1)
- `kind == PUBLISHED`: Set currentVersion = latestDraftVersion (if present) or currentVersion+1

**Response:** 200 OK
```json
{
  "contentId": "uuid",
  "currentVersion": 2,
  "latestDraftVersion": 2
}
```

---

### 7. Soft Delete Content

**Endpoint:** `DELETE /v1/content/{id}`

**Response:** 204 No Content

**Behavior:**
- Sets deleted=true
- Status remains unchanged (or set to ARCHIVED)
- Emits outbox event

---

### 8. Outbox Pull (For Integrations)

**Get Pending Events:**  
`GET /v1/outbox?status=PENDING&limit=100`

**Response:** 200 OK
```json
{
  "events": [
    {
      "id": "uuid",
      "tenantId": "t1",
      "aggregateType": "CONTENT",
      "aggregateId": "content-uuid",
      "eventType": "CONTENT_CREATED",
      "payloadJson": "{...}",
      "createdAt": "2025-01-24T10:30:00Z",
      "status": "PENDING"
    }
  ]
}
```

**Mark Event as Published:**  
`POST /v1/outbox/{eventId}/mark-published`

**Response:** 200 OK

---

## Error Handling

### Standard Error Response

```json
{
  "error": "VALIDATION_ERROR",
  "message": "title must be between 3 and 200 chars",
  "traceId": "abc-123-def-456"
}
```

**Error Codes:**
- `VALIDATION_ERROR`: Input validation failed
- `NOT_FOUND`: Resource not found
- `UNAUTHORIZED`: Authentication failed
- `FORBIDDEN`: Insufficient permissions
- `CONFLICT`: Business rule violation
- `INTERNAL_ERROR`: Server error

**Implementation:** Use `@ControllerAdvice` for global exception handling

---

## Code Structure

```
com.amogh.contentservice/
├── config/
│   ├── SecurityConfig.java
│   ├── WebConfig.java
│   └── JpaConfig.java
├── controller/
│   ├── ContentController.java
│   └── OutboxController.java
├── dto/
│   ├── CreateContentRequest.java
│   ├── UpdateContentRequest.java
│   ├── ContentResponse.java
│   ├── PagedResponse.java
│   └── ErrorResponse.java
├── entity/
│   ├── Content.java
│   ├── ContentTag.java
│   └── OutboxEvent.java
├── repository/
│   ├── ContentRepository.java
│   ├── ContentTagRepository.java
│   └── OutboxEventRepository.java
├── service/
│   ├── ContentService.java
│   ├── OutboxService.java
│   └── VersionService.java
├── util/
│   ├── TenantContext.java
│   ├── AccessGuard.java
│   └── Constants.java
└── exception/
    ├── GlobalExceptionHandler.java
    ├── ResourceNotFoundException.java
    ├── UnauthorizedException.java
    └── BusinessRuleException.java
```

---

## Security Implementation

### TenantContext

Resolved from headers in `OncePerRequestFilter` and stored in ThreadLocal or request attribute.

```java
public class TenantContext {
    private static final ThreadLocal<String> tenantId = new ThreadLocal<>();
    private static final ThreadLocal<String> userId = new ThreadLocal<>();
    private static final ThreadLocal<String> role = new ThreadLocal<>();
    
    // getter/setter methods
}
```

### AccessGuard

Helper class with methods:
- `requireRead()`: Check read permissions
- `requireWrite()`: Check write permissions

```java
public class AccessGuard {
    public void requireWrite(String role, List<String> permissions) {
        // Check if role in {ADMIN, TEACHER, CREATOR}
        // OR permission contains CONTENT_WRITE
    }
    
    public void requireRead(String role, List<String> permissions) {
        // Check if role not empty
        // Allow STUDENT read only if visibility == TENANT
    }
}
```

---

## Configuration

### application.yml

```yaml
server:
  port: 8085

spring:
  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/contentdb}
    username: ${DB_USER:postgres}
    password: ${DB_PASSWORD:postgres}
    driver-class-name: org.postgresql.Driver
  
  jpa:
    hibernate:
      ddl-auto: update  # For dev environment
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: true

management:
  endpoints:
    web:
      exposure:
        include: health
  endpoint:
    health:
      enabled: true

logging:
  level:
    com.amogh.contentservice: INFO
    org.hibernate.SQL: OFF
```

---

## Deliverables

1. ✅ Full Spring Boot project with Maven + Lombok
2. ✅ JPA Entities (Content, ContentTag, OutboxEvent)
3. ✅ Repositories (Spring Data JPA)
4. ✅ Services (business logic)
5. ✅ Controllers (REST endpoints)
6. ✅ DTOs with validation annotations
7. ✅ Pagination + filtering implementation
8. ✅ Outbox table + endpoints
9. ✅ Security filters (tenant/permission checks)
10. ✅ Global exception handling
11. ✅ Basic tests (repository + controller smoke tests using H2)

---

## Optional Add-ons

### Docker Compose

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: contentdb
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  content-service:
    build: .
    ports:
      - "8085:8085"
    environment:
      DB_URL: jdbc:postgresql://postgres:5432/contentdb
      DB_USER: postgres
      DB_PASSWORD: postgres
    depends_on:
      - postgres

volumes:
  postgres_data:
```

### Testing Scenarios

1. **Create Content** → Verify DRAFT status, version=1
2. **Bump Version (DRAFT)** → Verify latestDraftVersion incremented
3. **Bump Version (PUBLISHED)** → Verify currentVersion updated
4. **Change Status** (DRAFT→PUBLISHED) → Verify transition
5. **List with Filters** → Verify pagination and filtering
6. **Soft Delete** → Verify deleted flag and outbox event
7. **Outbox Pull** → Verify pending events retrieval

---

## Future Enhancements

- Integration with content-workflow-service for approval flows
- Kafka integration for real-time event streaming
- Full-text search integration with search-service
- Advanced version diff/comparison
- Content analytics and usage tracking
- Multi-language support for content metadata

---

## Contact & Support

For questions or issues, contact the Amogh Project team.
