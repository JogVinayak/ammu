# Amogh Backend: How It Works

A technical guide explaining the core flows of the Amogh learning platform.

---

## System Overview

Amogh is a multi-tenant learning platform built on microservices. Each school/tuition center operates as an isolated tenant.

```
┌─────────────────────────────────────────────────────────────────────┐
│                           API GATEWAY                                │
│  JWT Validation → Tenant Resolution → Rate Limiting → Routing       │
└─────────────────────────────────────────────────────────────────────┘
                                  │
        ┌─────────────┬───────────┼───────────┬─────────────┐
        ▼             ▼           ▼           ▼             ▼
   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
   │  Auth   │  │ Content │  │  Notes  │  │Workflow │  │ MindMap │
   │ Service │  │ Service │  │ Service │  │ Service │  │ Service │
   └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘
        │             │           │           │             │
        └─────────────┴───────────┴─────┬─────┴─────────────┘
                                        ▼
                          ┌───────────────────────┐
                          │ Role Permission Svc   │
                          │ (Authorization Layer) │
                          └───────────────────────┘
```

---

## 1. Authentication & Tenant Resolution

Every request passes through the API Gateway which:

1. **Validates JWT** - Checks signature and expiry
2. **Resolves Tenant** - Maps hostname/subdomain to tenant ID
3. **Injects Headers** - Adds `X-Tenant-Id`, `X-User-Id`, `X-Request-Id`

```
Request: GET /notes
Host: dps.amogh.com
Authorization: Bearer <jwt>

Gateway extracts from JWT:
├── userId: u_student_123
├── tenantId: dps_delhi
├── roles: [STUDENT]
└── scopes: [{ type: CLASS, id: class_10A }]

Downstream services receive:
├── X-Tenant-Id: dps_delhi
├── X-User-Id: u_student_123
└── X-Request-Id: req_abc123
```

---

## 2. How Notes Are Created

Notes creation involves two services working together:

### Step 1: Create Content Metadata (content-service)

```
POST /v1/content
{
  "type": "NOTE",
  "title": "Kinematics - Laws of Motion",
  "visibility": "TENANT",
  "tags": ["physics", "class10"]
}

Response:
{
  "contentId": "cnt_001",
  "status": "DRAFT",
  "version": 1
}
```

### Step 2: Create Note Content (notes-service)

```
POST /notes
{
  "contentId": "cnt_001",
  "title": "Kinematics - Laws of Motion",
  "content_md": "# Newton's Laws\n\n$F = ma$\n\n..."
}

Response:
{
  "noteId": "note_001",
  "versionId": "v_1",
  "status": "DRAFT"
}
```

**Key Point:** Notes are stored as Markdown with LaTeX. Rendering happens client-side (KaTeX for web, Flutter math for mobile).

### Data Model

```
notes table:
├── id, tenant_id
├── status: DRAFT | IN_REVIEW | PUBLISHED | ARCHIVED
├── latest_version_id (current draft)
├── latest_published_version_id (what students see)
└── created_by, updated_by

note_versions table:
├── version_no (immutable, monotonically increasing)
├── content_md (Markdown + LaTeX)
├── content_hash (integrity check)
└── created_by, created_at
```

---

## 3. The Approval Workflow

Content must go through review before students can access it.

### State Machine

```
DRAFT ──submit──► IN_REVIEW ──approve──► APPROVED ──publish──► PUBLISHED
                      │                                            │
                      │ reject                                     ▼
                      ▼                                        ARCHIVED
                   REJECTED
                      │
                      ▼
                    DRAFT (revise and resubmit)
```

### Workflow Steps

**1. Create Workflow**
```
POST /workflow
{
  "contentId": "cnt_001",
  "contentVersionId": "v_1",
  "publishTargets": {
    "scope": "CLASS",
    "classIds": ["class_10A", "class_10B"]
  }
}
```

**2. Submit for Review**
```
POST /workflow/{id}/submit
{
  "reviewerUserIds": ["u_reviewer_001"],
  "requiredApprovals": 1
}

Result:
├── State → IN_REVIEW
├── ReviewTask created for each reviewer
└── Notification sent to reviewers
```

**3. Reviewer Approves**
```
POST /workflow/{id}/reviews/{taskId}/approve
{
  "comment": "Content looks good"
}

Result:
├── ReviewTask status → APPROVED
├── If all required approvals met → Workflow state → APPROVED
└── Event: ContentWorkflowApproved
```

**3a. Reviewer Rejects (Alternative)**
```
POST /workflow/{id}/reviews/{taskId}/reject
{
  "comment": "Formula error in section 2"
}

Result:
├── ReviewTask status → REJECTED
├── ChangeRequest created with feedback
├── Workflow state → REJECTED → DRAFT
└── Author notified to revise
```

**4. Publish**
```
POST /workflow/{id}/publish

Actions:
├── content-service: Mark content as PUBLISHED
├── notes-service: Set latest_published_version_id
├── Emit ContentPublished event
├── Search indexer updates
└── Students in target classes notified
```

---

## 4. How Notes Are Assigned to Students

Assignment happens through `publishTargets` at publish time.

### Scope Levels

| Scope | Meaning |
|-------|---------|
| `USER` | Specific user IDs |
| `CLASS` | All students in specified classes |
| `SECTION` | All students in specified sections |
| `TENANT` | All users in the tenant |

### Example: Publish to Specific Classes

```
POST /workflow/{id}/publish
{
  "publishTargets": {
    "scope": "CLASS",
    "classIds": ["class_10A", "class_10B"]
  }
}
```

This means:
- Students in Class 10A → Can see the note
- Students in Class 10B → Can see the note
- Students in Class 10C → Cannot see the note

### User-Class Binding

Students are bound to classes via `user_role_assignments`:

```
user_role_assignments:
├── userId: u_student_001
├── roleId: STUDENT
├── scopeType: CLASS
├── scopeId: class_10A
└── status: ACTIVE
```

---

## 5. Access Control: Why Students Only See Their Notes

Every data access request goes through authorization checks.

### Permission Check Flow

```
Student requests: GET /notes

notes-service calls role-permission-service:

POST /authorize/check
{
  "tenantId": "dps_delhi",
  "userId": "u_student_001",
  "resource": "NOTE",
  "action": "READ",
  "context": {
    "noteId": "note_001",
    "visibility": "TENANT",
    "contentStatus": "PUBLISHED",
    "publishedToClasses": ["class_10A", "class_10B"]
  }
}
```

### Evaluation Logic

```
1. Get user's role assignments
   └── STUDENT with scope CLASS:class_10A

2. Get permissions for STUDENT role
   └── NOTE:READ with scope PUBLISHED_ONLY, CLASS

3. Check scope constraints:
   ├── Is content PUBLISHED? ✓
   └── Is class_10A in publishedToClasses? ✓

4. Result: ALLOWED
```

### Filtering in Practice

When a student fetches notes, the service:

```sql
SELECT * FROM notes
WHERE tenant_id = :tenantId
  AND status = 'PUBLISHED'
  AND (
    visibility = 'TENANT'
    OR id IN (
      SELECT note_id FROM note_assignments
      WHERE scope_type = 'CLASS'
      AND scope_id IN (:userClassIds)
    )
  )
```

Students never see:
- `DRAFT` content (not published yet)
- `IN_REVIEW` content (under review)
- Content published to other classes

---

## 6. Mind Maps & Learning Paths

Mind maps organize content into visual learning graphs.

### Structure

```
Mind Map
├── Nodes (concepts, topics, note references)
│   ├── type: CONCEPT | TOPIC | NOTE_REF | QUESTION
│   ├── contentRef: { contentId, versionId }
│   └── position: { x, y }
│
└── Edges (relationships between nodes)
    ├── relation: PREREQ | EXPLAINS | PART_OF
    ├── strength: 0.0 - 1.0 (mastery level)
    └── ttl_seconds (spaced repetition timing)
```

### How Notes Connect to Mind Maps

```
POST /mindmaps/{mapId}/nodes
{
  "type": "NOTE_REF",
  "title": "Laws of Motion",
  "contentRef": {
    "contentId": "cnt_001",
    "contentVersionId": "v_1"
  }
}
```

When a student clicks a node:
1. System fetches the **published version** of the referenced note
2. Permission check ensures student has access
3. Content rendered with proper math formatting

### Mind Map Assignment

Same pattern as notes:

```
POST /mindmaps/{mapId}/publish
{
  "publishTargets": {
    "scope": "CLASS",
    "classIds": ["class_10A"]
  }
}
```

---

## 7. Key Security Guarantees

### Tenant Isolation
Every database row includes `tenant_id`. All queries filter by tenant. Schools cannot see each other's data.

### Draft Invisibility
Students only query for `status = 'PUBLISHED'`. Drafts, reviews, and rejected content are invisible.

### Scope Enforcement
Content is published to specific scopes (classes/users). Permission service validates access on every request.

### Version Immutability
Once created, versions cannot be modified. Edits create new versions. Students always see `latest_published_version_id`.

---

## 8. Complete Request Flow Example

**Scenario:** Student fetches their notes

```
┌──────────────────────────────────────────────────────────────────┐
│ 1. REQUEST                                                       │
│    GET /notes                                                    │
│    Authorization: Bearer <jwt>                                   │
│    Host: school.amogh.com                                        │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│ 2. API GATEWAY                                                   │
│    ├── Validate JWT signature & expiry                           │
│    ├── Resolve tenant from hostname → tenant_001                 │
│    ├── Extract userId, roles, scopes from token                  │
│    └── Forward with X-Tenant-Id, X-User-Id headers               │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│ 3. NOTES SERVICE                                                 │
│    ├── Query notes WHERE tenant_id = X-Tenant-Id                 │
│    │                  AND status = 'PUBLISHED'                   │
│    │                                                             │
│    ├── For each note, call role-permission-service:              │
│    │   POST /authorize/check                                     │
│    │   { resource: NOTE, action: READ, context: {...} }          │
│    │                                                             │
│    └── Filter to only notes where allowed = true                 │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│ 4. RESPONSE                                                      │
│    {                                                             │
│      "notes": [                                                  │
│        { "id": "note_001", "title": "Laws of Motion", ... },     │
│        { "id": "note_002", "title": "Thermodynamics", ... }      │
│      ]                                                           │
│    }                                                             │
│                                                                  │
│    Note: Only notes published to student's class are returned    │
└──────────────────────────────────────────────────────────────────┘
```

---

## Quick Reference

| Action | Endpoint | Who Can Do It |
|--------|----------|---------------|
| Create note | `POST /notes` | Teachers (CONTENT_AUTHOR) |
| Submit for review | `POST /workflow/{id}/submit` | Note author |
| Approve/Reject | `POST /workflow/{id}/reviews/{taskId}/approve` | Assigned reviewers |
| Publish | `POST /workflow/{id}/publish` | Authors, Admins |
| View notes | `GET /notes` | Students (published + assigned only) |

| Status | Visible To |
|--------|------------|
| DRAFT | Author only |
| IN_REVIEW | Author + Reviewers |
| APPROVED | Author + Admins |
| PUBLISHED | Author + Assigned Students |
| ARCHIVED | No one (soft deleted) |
