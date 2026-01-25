# The Amogh Backend Story: A Day in the Life

*A narrative journey through the Amogh learning platform architecture*

---

## The Cast of Characters

- **Mrs. Sharma** - Physics teacher at Delhi Public School (Tenant: `dps_delhi`)
- **Ravi** - Student in Class 10A
- **Priya** - Student in Class 10B
- **Mr. Gupta** - Content Reviewer (Senior Teacher)
- **The Gatekeeper** - API Gateway (our silent guardian)
- **The Permission Oracle** - Role Permission Service

---

## Act 1: The Morning Login

### Scene 1: Ravi Opens the App

```
🌅 7:30 AM - Ravi opens Amogh on his phone
```

Ravi taps the Amogh app icon. His request travels through the internet and arrives at **The Gatekeeper** (API Gateway).

**The Gatekeeper's Internal Monologue:**
> "Hmm, a login request from `dps.amogh.com`. Let me figure out which school this is..."

```
Step 1: Tenant Resolution
─────────────────────────
Hostname: dps.amogh.com
     │
     ▼
┌─────────────────────────────┐
│     TENANT SERVICE          │
│  "dps.amogh.com" → dps_delhi│
│  Status: ACTIVE ✓           │
└─────────────────────────────┘
```

The Gatekeeper now knows Ravi belongs to Delhi Public School. It forwards the login to **Auth Service**.

```
Step 2: Authentication
──────────────────────
POST /auth/login
{
  "email": "ravi@student.dps.edu",
  "password": "••••••••"
}
     │
     ▼
┌─────────────────────────────┐
│      AUTH SERVICE           │
│  ✓ Password verified        │
│  ✓ Account active           │
│  ✓ Generate JWT token       │
└─────────────────────────────┘
```

**The JWT Token** (Ravi's magical passport):
```json
{
  "userId": "u_ravi_123",
  "tenantId": "dps_delhi",
  "roles": ["STUDENT"],
  "scopes": [{ "type": "CLASS", "id": "class_10A" }],
  "exp": "2026-01-25T19:30:00Z"
}
```

Ravi is now logged in. Every request he makes will carry this token.

---

## Act 2: Mrs. Sharma Creates a Note

### Scene 2: The Teacher's Inspiration

```
🏫 9:00 AM - Mrs. Sharma has a brilliant idea for a physics lesson
```

Mrs. Sharma logs into the teacher portal and decides to create notes on "Kinematics - Laws of Motion".

**Step 1: Create Content Metadata**

Her request goes through The Gatekeeper, which validates her JWT and adds special headers:

```
Headers injected by Gatekeeper:
───────────────────────────────
X-Tenant-Id: dps_delhi
X-User-Id: u_sharma_456
X-Request-Id: req_abc123
```

```
POST /v1/content
{
  "type": "NOTE",
  "title": "Kinematics - Laws of Motion",
  "description": "Newton's three laws explained",
  "visibility": "TENANT",
  "tags": ["physics", "class10", "kinematics"]
}
```

**Content Service Response:**
```json
{
  "contentId": "cnt_physics_001",
  "status": "DRAFT",
  "version": 1,
  "createdBy": "u_sharma_456"
}
```

**Step 2: Write the Actual Note Content**

```
POST /notes
{
  "contentId": "cnt_physics_001",
  "title": "Kinematics - Laws of Motion",
  "content_md": "# Newton's Laws of Motion\n\n## First Law\n$F = 0 \\implies \\Delta v = 0$\n\nAn object at rest stays at rest..."
}
```

**Notes Service** stores this as version 1 in the `note_versions` table.

```
📝 Note Created!
────────────────
ID: note_motion_001
Status: DRAFT (invisible to students)
Version: 1
Stored as: Markdown + LaTeX
```

**Why can't Ravi see this yet?**

The note's status is `DRAFT`. When Ravi requests notes:

```
GET /notes?status=PUBLISHED

Notes Service thinks:
  "Ravi wants published notes..."
  "note_motion_001 is DRAFT..."
  "Nope, can't show this one!"
```

---

## Act 3: The Approval Journey

### Scene 3: Submitting for Review

```
📤 10:30 AM - Mrs. Sharma is satisfied with her notes
```

Mrs. Sharma clicks "Submit for Review". This triggers the **Content Workflow Service**.

```
POST /workflow
{
  "contentId": "cnt_physics_001",
  "contentVersionId": "v_1",
  "titleSnapshot": "Kinematics - Laws of Motion",
  "publishTargets": {
    "scope": "CLASS",
    "classIds": ["class_10A", "class_10B"]
  }
}
```

**Workflow Created:**
```
┌─────────────────────────────────────┐
│         WORKFLOW STATE              │
├─────────────────────────────────────┤
│  ID: workflow_001                   │
│  State: DRAFT                       │
│  Target: Class 10A, Class 10B       │
└─────────────────────────────────────┘
```

**Submit for Review:**

```
POST /workflow/workflow_001/submit
{
  "reviewerUserIds": ["u_gupta_789"],
  "requiredApprovals": 1,
  "note": "Please review for accuracy"
}
```

**The State Machine Moves:**

```
    ┌────────┐
    │ DRAFT  │
    └───┬────┘
        │ submit
        ▼
┌──────────────┐
│  IN_REVIEW   │  ← We are here!
└──────────────┘
```

**Behind the scenes:**
1. Create `ReviewTask` for Mr. Gupta
2. Send notification to Mr. Gupta
3. Emit `ContentWorkflowSubmitted` event

---

### Scene 4: Mr. Gupta Reviews

```
📱 11:00 AM - Mr. Gupta receives a notification
```

Mr. Gupta opens his reviewer dashboard and sees the pending task.

**Before he can review, The Permission Oracle is consulted:**

```
POST /authorize/check
{
  "tenantId": "dps_delhi",
  "userId": "u_gupta_789",
  "resource": "WORKFLOW",
  "action": "REVIEW",
  "context": {
    "workflowId": "workflow_001",
    "assigneeIds": ["u_gupta_789"]
  }
}
```

**Permission Oracle's Decision Tree:**

```
1. Is Mr. Gupta a CONTENT_REVIEWER? ✓
2. Is he in the assignee list? ✓
3. Is his scope CLASS or higher? ✓

VERDICT: ALLOWED ✓
```

**Mr. Gupta Approves:**

```
POST /workflow/workflow_001/reviews/task_001/approve
{
  "comment": "Excellent explanation! Newton would be proud."
}
```

**The State Machine Moves Again:**

```
┌──────────────┐
│  IN_REVIEW   │
└──────┬───────┘
       │ approve (all required)
       ▼
┌──────────────┐
│   APPROVED   │  ← We are here!
└──────────────┘
```

---

### Scene 5: Publishing to Students

```
🎉 11:15 AM - Mrs. Sharma sees "Approved" status
```

Mrs. Sharma clicks "Publish to Students":

```
POST /workflow/workflow_001/publish
{
  "publishTargets": {
    "scope": "CLASS",
    "classIds": ["class_10A", "class_10B"]
  }
}
```

**The Publishing Symphony:**

```
┌──────────────────────────────────────────────────────────────┐
│                    PUBLISH ORCHESTRATION                      │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Workflow Service                                         │
│     └→ Validate state == APPROVED ✓                          │
│                                                              │
│  2. Call Content Service                                     │
│     └→ POST /v1/content/cnt_physics_001/status               │
│        { "status": "PUBLISHED" }                             │
│                                                              │
│  3. Call Notes Service                                       │
│     └→ POST /notes/note_motion_001/publish                   │
│        { "versionId": "v_1" }                                │
│     └→ Set latest_published_version_id = v_1                 │
│                                                              │
│  4. Emit ContentPublished Event                              │
│     └→ Search indexer picks up                               │
│     └→ Notification service notifies Class 10A & 10B         │
│                                                              │
│  5. State → PUBLISHED                                        │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## Act 4: The Student Experience

### Scene 6: Ravi Sees the Note

```
📚 12:00 PM - Ravi's phone buzzes with a notification
```

"New Physics notes available: Kinematics - Laws of Motion"

Ravi taps to view. Here's what happens:

**Request Flow:**

```
┌─────────────┐
│   Ravi's    │
│   Phone     │
└──────┬──────┘
       │ GET /notes (with JWT)
       ▼
┌──────────────────────────────────────┐
│          API GATEWAY                 │
│  ✓ JWT valid                         │
│  ✓ Token not expired                 │
│  ✓ Tenant: dps_delhi                 │
│  + Add X-Tenant-Id header            │
│  + Add X-User-Id header              │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│          NOTES SERVICE               │
│                                      │
│  Query: SELECT * FROM notes          │
│  WHERE tenant_id = 'dps_delhi'       │
│  AND status = 'PUBLISHED'            │
│                                      │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│     ROLE PERMISSION SERVICE          │
│                                      │
│  For each note, check:               │
│  Can Ravi READ this note?            │
│                                      │
│  Ravi's roles: [STUDENT]             │
│  Ravi's scope: CLASS:class_10A       │
│                                      │
│  Note permissions:                   │
│  - visibility: TENANT ✓              │
│  - status: PUBLISHED ✓               │
│  - publishTargets includes 10A ✓     │
│                                      │
│  VERDICT: ALLOWED                    │
└──────────────────────────────────────┘
```

**Ravi sees:**
```
┌─────────────────────────────────────┐
│  📖 Kinematics - Laws of Motion     │
│                                     │
│  # Newton's Laws of Motion          │
│                                     │
│  ## First Law                       │
│  F = 0 ⟹ Δv = 0                     │
│                                     │
│  An object at rest stays at rest... │
└─────────────────────────────────────┘
```

---

### Scene 7: Priya Also Sees It

```
📱 12:05 PM - Priya in Class 10B opens the app
```

Priya is in Class 10B, which was also in the `publishTargets`. The same flow happens:

```
Permission Check for Priya:
───────────────────────────
Priya's scope: CLASS:class_10B
Note's targets: [class_10A, class_10B]
                           ↑
                    Match found!

VERDICT: ALLOWED ✓
```

Priya sees the same note!

---

### Scene 8: Amit (Class 10C) is Left Out

```
😕 Meanwhile, Amit from Class 10C...
```

Amit is curious and tries to access the notes:

```
Permission Check for Amit:
──────────────────────────
Amit's scope: CLASS:class_10C
Note's targets: [class_10A, class_10B]

No match found!

VERDICT: DENIED ✗
```

**Notes Service's Response to Amit:**

The note simply doesn't appear in his list. It's as if it doesn't exist for him.

```
GET /notes (Amit's view)

Response: {
  "notes": [
    // note_motion_001 is NOT here
    // Only notes published to class_10C appear
  ]
}
```

---

## Act 5: The Mind Map Connection

### Scene 9: Building the Learning Path

```
🧠 2:00 PM - Mrs. Sharma creates a Mind Map
```

Mrs. Sharma wants to organize all physics concepts into a visual learning path.

```
POST /mindmaps
{
  "title": "Physics - Motion Chapter",
  "tenantId": "dps_delhi"
}
```

**Adding Nodes that Reference Notes:**

```
POST /mindmaps/map_001/nodes
{
  "type": "NOTE_REF",
  "title": "Laws of Motion",
  "contentRef": {
    "contentId": "cnt_physics_001",
    "contentVersionId": "v_1"
  },
  "position": { "x": 100, "y": 50 }
}
```

**Creating Prerequisite Relationships:**

```
POST /mindmaps/map_001/edges
{
  "fromNodeId": "node_basics",
  "toNodeId": "node_laws_motion",
  "relation": "PREREQ",
  "strength": 0.0
}
```

**Publish Mind Map to Classes:**

```
POST /mindmaps/map_001/publish
{
  "publishTargets": {
    "scope": "CLASS",
    "classIds": ["class_10A"]
  }
}
```

---

### Scene 10: Ravi's Learning Journey

```
🎯 3:00 PM - Ravi explores the Mind Map
```

Ravi sees an interactive map:

```
┌─────────────────────────────────────────────────────────┐
│                    PHYSICS - MOTION                      │
│                                                         │
│   ┌──────────┐    PREREQ    ┌─────────────────┐        │
│   │ Basics   │─────────────→│ Laws of Motion  │        │
│   │(mastered)│              │   (click me!)   │        │
│   └──────────┘              └────────┬────────┘        │
│                                      │                  │
│                                      │ EXPLAINS        │
│                                      ▼                  │
│                             ┌─────────────────┐        │
│                             │  Applications   │        │
│                             │   (locked 🔒)   │        │
│                             └─────────────────┘        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

When Ravi clicks "Laws of Motion", the system:

1. Checks if he can access `cnt_physics_001`
2. Fetches the **published version** of the note
3. Displays it with LaTeX rendered beautifully

**Edge Reinforcement (Spaced Repetition):**

When Ravi completes a quiz on Laws of Motion:

```
POST /edges/edge_123/review
{
  "score": 0.85,
  "reviewedAt": "2026-01-25T15:30:00Z"
}
```

The edge strength updates:
```
Before: strength = 0.0
After:  strength = 0.85
Next review: TTL calculated based on score
```

---

## Act 6: The Rejection Scenario

### Scene 11: When Reviews Go Wrong

```
⚠️ Alternative Timeline - Mr. Gupta finds issues
```

Let's rewind. What if Mr. Gupta found problems?

```
POST /workflow/workflow_001/reviews/task_001/reject
{
  "comment": "Example 2 has an incorrect formula. F=ma not F=mv"
}
```

**The State Machine:**

```
┌──────────────┐
│  IN_REVIEW   │
└──────┬───────┘
       │ reject
       ▼
┌──────────────┐
│   REJECTED   │
└──────┬───────┘
       │ auto-transition
       ▼
┌──────────────┐
│    DRAFT     │  ← Back to editing!
└──────────────┘
```

**A Change Request is Created:**

```
{
  "changeRequestId": "cr_001",
  "workflowId": "workflow_001",
  "requestedBy": "u_gupta_789",
  "summary": "Incorrect formula in Example 2",
  "details": "F=ma not F=mv",
  "status": "OPEN"
}
```

Mrs. Sharma receives a notification and sees the feedback. She fixes the note, creating version 2, and resubmits.

---

## The Grand Architecture Diagram

```
                                    ┌─────────────────┐
                                    │   Student App   │
                                    │   Teacher App   │
                                    └────────┬────────┘
                                             │
                                             ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                              API GATEWAY                                    │
│  • JWT Validation    • Tenant Resolution    • Rate Limiting    • Routing   │
└────────────────────────────────────────────────────────────────────────────┘
         │              │              │              │              │
         ▼              ▼              ▼              ▼              ▼
   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐
   │   Auth   │  │ Content  │  │  Notes   │  │ Workflow │  │  Mind Map    │
   │ Service  │  │ Service  │  │ Service  │  │ Service  │  │   Service    │
   └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────────┘
         │              │              │              │              │
         └──────────────┴──────────────┴──────────────┴──────────────┘
                                       │
                                       ▼
                          ┌─────────────────────────┐
                          │  Role Permission Svc    │
                          │  (The Permission Oracle)│
                          └─────────────────────────┘
                                       │
                                       ▼
                          ┌─────────────────────────┐
                          │    PostgreSQL DBs       │
                          │  (Tenant-Isolated)      │
                          └─────────────────────────┘
```

---

## The Golden Rules

### 1. Tenant Isolation
Every piece of data has a `tenant_id`. Delhi Public School can NEVER see data from another school.

### 2. Draft Invisibility
Students can ONLY see `PUBLISHED` content. Drafts, reviews, rejected content - all invisible.

### 3. Class Scope Enforcement
Content is published to specific classes. If you're not in that class, the content doesn't exist for you.

### 4. Approval Before Publishing
```
DRAFT → IN_REVIEW → APPROVED → PUBLISHED
         ↓
      REJECTED → DRAFT (fix and retry)
```

### 5. Version Immutability
Once a version is created, it cannot be changed. New edits create new versions. Students always see `latest_published_version_id`.

---

## Summary: The Note's Journey

```
1. 📝 CREATION
   Teacher writes note in Markdown + LaTeX
   Status: DRAFT (invisible to students)

2. 📤 SUBMISSION
   Teacher submits for review
   Reviewers are assigned
   Status: IN_REVIEW

3. 👀 REVIEW
   Reviewers approve or reject
   If rejected → back to DRAFT with feedback
   If approved → Status: APPROVED

4. 🎉 PUBLISHING
   Teacher publishes to specific classes
   Status: PUBLISHED
   Events emitted for notifications & indexing

5. 📱 CONSUMPTION
   Students in target classes see the note
   Permission Oracle validates every access
   Other students: "What note?" 🤷

6. 🔄 UPDATES
   New version created (v2, v3...)
   Goes through same workflow
   Students see latest_published_version
```

---

*And so the Amogh platform keeps learning materials flowing securely from teachers to students, one approved note at a time.*

**THE END** 📚✨
