# Brain System - Pending Tasks

> Last updated: 2026-02-08

## Completed Features
1. ~~Notes + Versioning + Approval Workflow (notes-service)~~
2. ~~MCQs + Flashcards + Batch Operations (notes-service)~~
3. ~~Deck Composition & Validation (notes-service)~~
4. ~~Exam Attempt Tracking & Scoring (notes-service)~~
5. ~~Mind Map + Knowledge Graph (mindmap-service + graph-relations-service)~~
6. ~~Spaced Repetition Engine (recall-service)~~
7. ~~Role Hierarchy & RBAC (role-permission-service)~~
8. ~~Auth: Signup, Login, OTP, Invite, Password Reset (auth-service)~~
9. ~~Tenant + School Configuration (tenant-service)~~
10. ~~User Profiles + Preferences + Relationships (user-profile-service)~~
11. ~~Student-Concept Progress & Mastery (user-profile-service)~~
12. ~~Activity Rings & Streaks (user-profile-service)~~
13. ~~Basic Notifications (recall-service)~~
14. ~~Content Progress Tracking (user-profile-service)~~
15. ~~API Gateway with routing (api-gateway)~~
16. ~~All services built & deployed to Docker~~
17. ~~Postman collections updated for all services~~
18. ~~Assignment Workflow (content-workflow-service)~~

---

## Tier 1 - Core Missing (High Priority)

### ~~1. Assignment Workflow~~ DONE
~~**Service:** content-workflow-service~~
~~**Implemented:** 7 endpoints (POST/GET/PATCH/DELETE /assignments, GET /assignments/users/{userId}, GET /assignments/{id}/progress), 2 tables (assignments, student_assignments), auto-propagation to students via UserProfileClient, notifications via NotificationClient, duplicate prevention, Postman collection updated.~~

### 2. Weak Areas Detection & Work Requests
**Service:** notes-service + new workflow in content-workflow-service
**Description:** When a student scores <80% on specific MCQs repeatedly, flag those concepts as weak areas. Raise a work request for the admin/teacher to create targeted flashcards/MCQs. Allow focused content assignment to struggling students.
**Endpoints needed:**
- `GET /v1/tenants/{tenantId}/users/{userId}/weak-areas` — List weak areas for a student
- `POST /v1/tenants/{tenantId}/work-requests` — Create work request (weak area → admin)
- `GET /v1/tenants/{tenantId}/work-requests` — List work requests (filter by status, assignee)
- `PATCH /v1/tenants/{tenantId}/work-requests/{requestId}` — Update status (IN_PROGRESS, RESOLVED)
- `POST /v1/tenants/{tenantId}/users/{userId}/focused-assignments` — Assign focused content to a student
**Logic:**
- Track incorrect MCQ answers per student per concept
- Flag when error rate > threshold (e.g., same MCQ wrong 2+ times)
- Auto-generate work request or teacher manually creates one

---

## Tier 2 - Engagement & Reporting (Medium Priority)

### 3. Leaderboard System
**Service:** user-profile-service (new controller)
**Description:** Apple-style leaderboard with Division, Class, and School rankings. Composite score = 25% streak + 30% mastery + 15% bonus revision points + 30% exam scores. Principal can configure weights.
**Endpoints needed:**
- `GET /v1/tenants/{tenantId}/leaderboard/class/{classId}` — Class leaderboard
- `GET /v1/tenants/{tenantId}/leaderboard/division/{divisionId}` — Division leaderboard
- `GET /v1/tenants/{tenantId}/leaderboard/school` — School-wide leaderboard
- `GET /v1/tenants/{tenantId}/leaderboard/user/{userId}` — User's rank and score breakdown
- `PUT /v1/tenants/{tenantId}/leaderboard/config` — Configure weights (principal only)
- `GET /v1/tenants/{tenantId}/leaderboard/config` — Get current weight config
**Tables:** `leaderboard_config`, `leaderboard_score` (materialized/cached scores)
**Logic:**
- Composite score calculated from: activity streak, mastery percentage, bonus points, exam average
- Recalculate periodically (scheduled job) or on-demand
- Support time period filtering (weekly, monthly, all-time)

### 4. Advanced Notifications
**Service:** recall-service (extend NotificationController)
**Description:** Full notification system with Firebase Cloud Messaging push, parent-specific triggers, actionable tasks, and quiet hours respect.
**Endpoints needed:**
- `PUT /v1/tenants/{tenantId}/users/{userId}/notification-preferences` — Set FCM token, quiet hours, channels
- `GET /v1/tenants/{tenantId}/users/{userId}/notification-preferences` — Get preferences
- `GET /v1/tenants/{tenantId}/users/{userId}/actionable-tasks` — Parent's auto-generated tasks
- `POST /v1/tenants/{tenantId}/users/{userId}/actionable-tasks/{taskId}/acknowledge` — Mark task done
**Triggers to implement:**
- Student: due review reminder, critical decay alert, streak at risk (missed today)
- Parent: child missed review, child broke streak, child scored low, decay alert, teacher flag
- Teacher: assignment completion summary, class weak areas report
**Integration:** Firebase Admin SDK for push delivery

### 5. Reports & KPIs
**Service:** new reports-service or extend user-profile-service
**Description:** Analytics dashboards for Parent, Teacher, and Principal roles.
**Endpoints needed:**
- **Parent Reports:**
  - `GET /v1/tenants/{tenantId}/reports/student/{userId}/overview` — Scores, streaks, mastery %
  - `GET /v1/tenants/{tenantId}/reports/student/{userId}/weak-areas` — Weak concepts list
  - `GET /v1/tenants/{tenantId}/reports/student/{userId}/time-spent` — Daily/weekly time breakdown
  - `GET /v1/tenants/{tenantId}/reports/student/{userId}/attempts` — Attempts per repetition cycle
- **Teacher KPIs:**
  - `GET /v1/tenants/{tenantId}/reports/class/{classId}/overview` — Class completion rates, avg scores
  - `GET /v1/tenants/{tenantId}/reports/class/{classId}/bottlenecks` — Tasks stuck in review, slow completions
  - `GET /v1/tenants/{tenantId}/reports/class/{classId}/streaks` — Streak data for all students
  - `GET /v1/tenants/{tenantId}/reports/division-benchmark` — Compare divisions
- **Principal Dashboard:**
  - `GET /v1/tenants/{tenantId}/reports/school/overview` — All KPIs aggregated
  - `GET /v1/tenants/{tenantId}/reports/school/division-comparison` — Side-by-side division stats

---

## Tier 3 - Polish & Enhancement (Lower Priority)

### 6. Knowledge Decay Visualization Backend
**Service:** user-profile-service
**Description:** Enhance the existing retention calculation with continuous Ebbinghaus decay (R = e^(-t/S)), background refresh jobs, and critical decay notifications.
**Endpoints needed:**
- `GET /v1/tenants/{tenantId}/users/{userId}/progress/concepts/retention-map` — All concepts with current retention values
- `GET /v1/tenants/{tenantId}/users/{userId}/progress/concepts/decay-forecast` — Predicted retention in N days
**Logic:**
- Background scheduled job recalculates retention for all active concepts periodically
- When retention drops below critical threshold, auto-create notification
- Memory strength (S) increases with each successful review cycle

### 7. Division Management
**Service:** tenant-service or content-workflow-service
**Description:** Up to 26 divisions per class (A-Z), customizable naming, division-level grouping.
**Endpoints needed:**
- `POST /v1/tenants/{tenantId}/classes/{classId}/divisions` — Create division
- `GET /v1/tenants/{tenantId}/classes/{classId}/divisions` — List divisions
- `PUT /v1/tenants/{tenantId}/classes/{classId}/divisions/{divisionId}` — Update division name
- `DELETE /v1/tenants/{tenantId}/classes/{classId}/divisions/{divisionId}` — Delete division
- `POST /v1/tenants/{tenantId}/classes/{classId}/divisions/{divisionId}/students` — Add student to division
- `GET /v1/tenants/{tenantId}/classes/{classId}/divisions/{divisionId}/students` — List students in division

### 8. Parent-Specific Features
**Service:** user-profile-service + api-gateway
**Description:** Read-only child dashboard, actionable task management, consolidated report requests.
**Endpoints needed:**
- `GET /v1/tenants/{tenantId}/parents/{parentId}/children` — List linked children
- `GET /v1/tenants/{tenantId}/parents/{parentId}/children/{childId}/dashboard` — Child's progress summary
- `GET /v1/tenants/{tenantId}/parents/{parentId}/tasks` — Auto-generated + manual tasks
- `POST /v1/tenants/{tenantId}/parents/{parentId}/tasks/{taskId}/complete` — Mark task complete
- `POST /v1/tenants/{tenantId}/parents/{parentId}/report-request` — Request consolidated report

---

## Implementation Order Recommendation
1. **Assignment Workflow** — Core to the learning flow (teacher → student pipeline)
2. **Weak Areas Detection** — Improves learning outcomes, depends on exam data already collected
3. **Leaderboard System** — High engagement value, builds on existing progress data
4. **Advanced Notifications** — Ties everything together with push delivery
5. **Reports & KPIs** — Analytics layer on top of existing data
6. **Knowledge Decay Visualization** — Enhancement to existing retention system
7. **Division Management** — Organizational structure enhancement
8. **Parent Features** — Depends on notifications and reports being in place
