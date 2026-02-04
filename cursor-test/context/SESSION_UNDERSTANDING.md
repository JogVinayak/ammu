# Session Understanding - MindMap & Notes Release Feature

> This file tracks ongoing understanding from conversations. Updated after each interaction.

---

## Current Scenario (2026-01-26)

### Users & Schools

| User | Role | School (Tenant) | Class/Section |
|------|------|-----------------|---------------|
| Amogh | Student | Euroschool | 4-C |
| Priya | Teacher (Science) | Euroschool | 4-C |
| Suresh | Content Creator | Euroschool | - |
| Admin | Tenant Admin | Euroschool | - |
| Daksh | Student | Ravishankar School | 4-C |
| Ravi | Teacher (Science) | Ravishankar School | 4-C |

### Notes to Create

**Euroschool (Priya creates):**
1. Photosynthesis - RELEASED to students
2. Animal Kingdom - NOT released (draft)

**Ravishankar School (Ravi creates):**
1. Photosynthesis - RELEASED to students
2. Animal Kingdom - NOT released (draft)

---

## Confirmed Design Decisions

| Question | Answer |
|----------|--------|
| Mind map ownership | **Per teacher** - each teacher owns their own mind maps |
| Release scope | **Class level** - releasing targets all students in a class |
| Notes per mind map | **N notes** - one mind map can group multiple related notes |
| Note reuse via tags | **Yes** - notes can belong to multiple mind maps via tags |
| Cross-school visibility | **Never** - strict tenant isolation, schools cannot see each other's content |
| Mind map hierarchy | **Via tags** - use hash-prefixed tags for hierarchy, not rigid FK relationships |
| Tag naming convention | **Hash-prefixed** - e.g., `#parent-biology`, `#topic-photosynthesis`, `#grade-4` |
| Note-mindmap linking | **Bidirectional** - mindmap nodes have `contentId`, notes have `#mindmap-{name}` tag |
| Content creation | **Content Creator** creates notes (shared library), **Teacher** curates mind maps and releases to class |
| Content Creator credits | **Monthly credit system** - limited number of notes/content per month |
| Content approval | **Admin approval required** - Content Creator → Admin approves → Teacher can use |
| Edit after publish | **Yes** - Teacher can edit published mind maps |
| Note release | **Automatic cascade** - releasing mind map auto-releases all linked notes to the target class |
| Content Repository | **Shared library** - Content Creators & Teachers publish notes; Teachers search & copy to their mind maps |
| Note sharing model | **Copy on use** - Teacher gets own copy when using a note from repository |

---

## Content Repository Model

```
┌─────────────────────────────────────────────────┐
│              CONTENT REPOSITORY                 │
│  (shared library within tenant)                 │
│                                                 │
│  Contributors:                                  │
│    - Content Creators (primary)                 │
│    - Teachers (can also contribute)             │
│                                                 │
│  Usage:                                         │
│    - Teachers search & copy to their mind maps  │
│    - Copy model = teacher gets own copy         │
└─────────────────────────────────────────────────┘
```

---

## Open Questions (To Clarify)

1. ~~Mind map per teacher or shared?~~ → Per teacher
2. ~~Release at class or student level?~~ → Class level
3. ~~One mind map = one note or many?~~ → Many notes per mind map
4. ~~Can notes belong to multiple mind maps?~~ → Yes, via tags
5. ~~Cross-school sharing?~~ → Never, strict tenant isolation
6. ~~Mind map hierarchy?~~ → Yes, via special tags (flexible, not rigid parent-child FK)
7. ~~Note release behavior?~~ → Automatic cascade - releasing mind map auto-releases linked notes
8. ~~Notebook execution?~~ → Call live services (not just design doc)

**All questions resolved - ready to build notebook.**

---

## Data Model Understanding

### Microservices

| Service | Port | What it does |
|---------|------|--------------|
| api-gateway | 8084 | Entry point - routes requests, validates JWT, resolves tenant |
| auth-service | 8081 | Signup, login, OTP, tokens (access + refresh) |
| tenant-service | 8082 | Schools as tenants - creation, policies, branding |
| user-profile-service | 8083 | User profiles, preferences, relationships |
| role-permission-service | 8080 | RBAC - roles, permissions, grants, scopes |
| content-service | 8085 | Content catalog metadata (topics, modules, registry) |
| content-workflow-service | 8086 | Git-like approval workflow (draft → review → publish) |
| notes-service | 8088 | Note content (markdown + LaTeX), versioning |
| mindmap-service | 8087 | Mind map graphs - nodes, edges, spaced repetition signals |
| graph-relations-service | 8087 | Learning graph edges, edge strength for revision |
| assessment-service | TBD | MCQs, flashcards linked to notes (planned) |

### Key Relationships

```
Tenant (School)
  └── Users (Teachers, Students)
        └── Teacher owns Mind Maps
              └── Mind Map has Nodes
                    └── Node can reference Note (via contentId)
              └── Mind Map has Edges (connections between nodes)
```

### Release Flow

1. Teacher creates Mind Map (status: DRAFT)
2. Teacher adds Nodes (can link to Notes)
3. Teacher publishes Mind Map to class: `POST /mindmaps/{id}/publish`
   - publishTargets: `{ scope: "CLASS", classIds: ["4-C"] }`
4. Students in that class can now see the mind map and linked notes

### Notes Model

- Notes have status: DRAFT → IN_REVIEW → PUBLISHED → ARCHIVED
- Notes have tags for categorization
- Notes can be linked to mind map nodes via `contentId`

### Mind Map Node Types

- CONCEPT
- TOPIC
- SUBTOPIC
- NOTE_REF (links to notes-service)
- QUESTION
- FORMULA

---

## Notebook Pattern (from existing code)

```python
# Service URLs
TENANT_URL = "http://localhost:8082"
AUTH_URL = "http://localhost:8081"
NOTES_URL = "http://localhost:8088"
MINDMAP_URL = "http://localhost:8087"

# Headers pattern
headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {token}",
    "X-Tenant-Id": str(tenant_id)
}
```

---

## Completed Work

### Notebook Created: `mindmap_notes_release_test.ipynb`

Implements full workflow:
1. Setup/verify tenants (Euroschool, Ravishankar)
2. Create users (Amogh, Priya, Daksh, Ravi)
3. Assign roles (STUDENT, SUBJECT_TEACHER) to class 4-C
4. Create notes (Photosynthesis, Animal Kingdom)
5. Create mind maps with nodes linking to notes
6. Release Photosynthesis (publish), keep Animal Kingdom as draft
7. Test scenarios:
   - Student sees published notes
   - Student cannot see draft notes
   - Teacher sees all notes (draft + published)
   - Tenant isolation between schools

### Test Scenarios Covered

| Test | Expected Result |
|------|-----------------|
| Amogh reads Photosynthesis notes | Can see (published) |
| Amogh reads Animal Kingdom notes | Cannot see (draft) |
| Amogh reads Ravishankar notes | Cannot see (tenant isolation) |
| Daksh reads Ravishankar notes | Can see (own school) |
| Priya reads all notes | Can see all (including drafts) |
| Amogh views published mind map | Can access graph |
| Amogh views draft mind map | Cannot access |

---

## Content Creator Workflow

### Flow Diagram

```
Content Creator (Suresh)
    |
    v
Creates Note (DRAFT)
    |
    v
Submits for Review -----> Admin (Reviewer)
    |                          |
    |                          v
    |                     Reviews & Approves
    |                          |
    v                          v
Note PUBLISHED to Repository <--
    |
    v
Teacher (Priya) Searches Repository
    |
    v
Copies Note (gets own copy)
    |
    v
Links to Mind Map (#mindmap-{name} tag)
```

### Workflow States

| State | Description |
|-------|-------------|
| DRAFT | Content Creator working on note |
| IN_REVIEW | Submitted to Admin for approval |
| APPROVED | Admin approved, ready to publish |
| PUBLISHED | Available in repository |
| ARCHIVED | Removed from active repository |

### Roles Involved

| Role | Permissions |
|------|-------------|
| CONTENT_CREATOR | Create notes, submit for review |
| TENANT_ADMIN | Review and approve content |
| SUBJECT_TEACHER | Search repository, copy notes |

### Notebook Created: `content_creator_workflow_test.ipynb`

Tests the full Content Creator workflow:
1. Create tenant and roles (CONTENT_CREATOR, TENANT_ADMIN, SUBJECT_TEACHER)
2. Create users (Suresh, Admin, Priya)
3. Assign roles to users
4. Suresh creates note with tags (#subject-science, #topic-photosynthesis, #repository)
5. Suresh submits workflow for review
6. Admin approves the review
7. Workflow published to repository
8. Priya searches repository
9. Priya copies note (gets own copy with #mindmap-{name} tag)

---

*Last updated: 2026-01-26*
