# BRAIN SYSTEM — Product Specification & CRC Analysis

**Spaced Repetition Learning Platform | Version 1.0 | February 2026**

---

## 1. Product Overview

The Brain System is a spaced repetition-based learning platform represented as an interactive mind map. It enables teachers to create structured learning content, assign it to students, and track mastery through scientifically proven repetition cycles. The system features a visual knowledge decay model where mind map nodes glow or dim based on the student's retention level, following the Ebbinghaus forgetting curve.

**Platform:** Flutter mobile app (iOS + Android) with push notifications.

---

## 2. Mind Map Structure

Fixed hierarchical tree:

```
School
 └── Subject (Main Node)
      └── Topic (Sub Node)
           └── Concept (Child Node)
                └── Notes (File-system structure)
```

Notes are organized like a file system under each concept. Each note can contain multiple decks.

---

## 3. Content Structure

### 3.1 Deck Composition

| Component     | Quantity     | Distribution                    |
|---------------|--------------|----------------------------------|
| MCQ Questions | 40 per deck  | 30% Easy, 30% Medium, 40% Hard  |
| Flashcards    | 40 per deck  | Aligned to concept difficulty    |

- A single note can contain multiple decks.
- Both **teachers** and **admins** can create mind maps, notes, decks, flashcards, and MCQ batteries.

---

## 4. Assignment Flow

1. Teacher assigns a note to a **class**.
2. Assignment automatically propagates to **every student** in that class.
3. A **default spaced repetition cycle** is attached on assignment.
4. A **timer starts** and the **reminder suite activates**.
5. Teacher can **override** the repetition cycle for a single student or class-wide.

---

## 5. Spaced Repetition System

### 5.1 Repetition Cycles

Teacher selects a repetition cycle based on concept difficulty. Default cycles are auto-attached on assignment but can be modified at student or class level.

| Difficulty | Repetition Intervals (Days)  |
|------------|------------------------------|
| Easy       | 1 – 3 – 7 – 21 – 60 – 90   |
| Medium     | 1 – 3 – 7 – 14 – 30 – 60   |
| Hard       | 1 – 2 – 4 – 7 – 14 – 30    |
| Very Hard  | 1 – 1 – 3 – 5 – 10 – 21    |

### 5.2 Completion Criteria

- **First Repetition:** Student must read the concept, review flashcards, and take the MCQ exam.
- **Subsequent Repetitions:** Student may skip reading and go directly to flashcards, but must take the exam and score **≥80%**.
- **Failed Attempt:** Student retakes flashcards and MCQ only (no timer reset). Unlimited retake attempts allowed; all attempts are tracked.
- **Weak Area Handling:** Incorrect answers are flagged as weak areas. A **work request is raised for admin** to create new flashcards and MCQs focused on those weak areas and assign them to the struggling student.

### 5.3 Post-Mastery Maintenance Phase

After completing all repetition cycles with ≥80%, the concept enters a maintenance phase to prevent knowledge decay.

| Difficulty | Maintenance Intervals             |
|------------|-----------------------------------|
| Easy       | 3 months – 6 months – 12 months  |
| Medium     | 2 months – 4 months – 8 months   |
| Hard       | 1 month – 3 months – 6 months    |
| Very Hard  | 3 weeks – 2 months – 4 months    |

**Demotion Rule:** If a student scores <80% during a maintenance review, mastery is revoked and the concept re-enters an active repetition cycle at a mid-level interval.

---

## 6. Knowledge Decay Visualization

Mind map nodes visually represent the student's retention level using a **gradual glow/dim effect** that follows the Ebbinghaus forgetting curve.

**Formula:** `R = e^(-t/S)`

- `R` = Retention level (maps to node brightness/opacity)
- `t` = Time elapsed since last successful review
- `S` = Memory strength (increases with each successful review cycle)

**Behavior:**
- Freshly mastered concept → Node glows bright (full charge)
- As time passes without review → Node gradually dims (decaying)
- Missed maintenance review → Node goes dull (needs attention)
- After re-review with ≥80% → Node glows bright again
- A concept reviewed 6 times decays **much slower** than one reviewed twice (higher S value)
- Dimming is **smooth and continuous** (not step-based)

---

## 7. Gamification

### 7.1 Activity Rings (Apple Health Style)

Each concept node displays three rings around it:

| Ring  | Name           | Completion Criteria                          |
|-------|----------------|----------------------------------------------|
| 🔴 Red   | Reading Ring   | Student completed concept reading            |
| 🟢 Green | Flashcard Ring | Student reviewed all flashcards              |
| 🔵 Blue  | Exam Ring      | Student took MCQ and scored ≥80%             |

**Streak Rule:** All three rings must be closed to maintain a daily streak. Streak **resets to zero** on any missed day — no grace period.

### 7.2 Leaderboard

**Scope:** Division level, Class level, and School level (with toggle/filter).

**Composite Score (Default Weights):**

| Factor                              | Default Weight |
|-------------------------------------|----------------|
| Current Streak                      | 25%            |
| Mastery Percentage (Glowing Nodes)  | 30%            |
| Bonus Revisions                     | 15%            |
| Exam Scores                         | 30%            |

- Weights are **configurable by Principal only**.
- Extra revisions beyond the assigned cycle earn **bonus points** that contribute to leaderboard ranking and grade weighting.

---

## 8. School Structure

### 8.1 Hierarchy

```
School → Class (e.g., Grade 5) → Division (e.g., 5A, 5B, 5C) → Students
```

- Up to **26 divisions** per class (A through Z).
- Schools can **customize division naming** convention; default is letter-based (5A).
- A student belongs to **only one class/division**. Multiple institutions require separate accounts.
- A subject teacher can teach the same subject across **multiple divisions**.

### 8.2 Role Hierarchy & Permissions

| Role            | Access Scope                                                                                      |
|-----------------|---------------------------------------------------------------------------------------------------|
| Student         | Own enrolled subjects only                                                                        |
| Parent          | Read-only view of linked child's data, actionable tasks, reports                                  |
| Subject Teacher | Her class(es), her subject. Creates content, assigns notes, modifies cycles.                      |
| Class Teacher   | Her class, all subjects. Can motivate underperforming students.                                   |
| Principal       | All classes, all subjects, KPIs for students & teachers. Configures leaderboard weights.          |
| School Admin    | Onboarding students, teachers, principals. All school operations.                                 |
| Super Admin     | All schools. Read and manage.                                                                     |
| Boss Admin      | God mode. Full control over everything.                                                           |

---

## 9. Notification System

### 9.1 Delivery

- **Channel:** Flutter app push notifications (Firebase Cloud Messaging or equivalent).
- **Timing:** Real-time — sent immediately when triggered.
- **No daily consolidation** unless parent explicitly requests via a dedicated button.

### 9.2 Student Notification Triggers

- Scheduled review is due
- Node has decayed to a critical retention level
- Streak is at risk (end of day, rings not closed)

### 9.3 Parent Notification Triggers

- Student missed a scheduled review
- Streak broken
- Student scored below 80% on exam
- Node decayed to critical level
- Teacher manually flagged urgent attention

### 9.4 Parent Actionable Tasks

- **Auto-generated** from decaying nodes, missed reviews, low scores.
- **Manually created** by teacher (e.g., "ask student to read and repeat Concept A, B, and C").
- Parent can **acknowledge** the task, but it **recurs daily** until the student actually completes it in the system.

---

## 10. Reports & KPIs

### 10.1 Parent Reports

Detailed reports include: scores, weak areas, number of attempts per repetition, and time spent on each concept.

### 10.2 Teacher KPIs

- **Division benchmarking:** comparing student performance across divisions (e.g., 5A vs 5B)
- **Task bottleneck analysis:** understanding why students cannot finish tasks
- **Percentage of unclosed/incomplete tasks**
- **Student completion rates and continued streak data**

---

## 11. Technical Platform

- **Mobile App:** Flutter (iOS + Android)
- **Notifications:** Push notifications via Firebase Cloud Messaging (or equivalent)
- **Parent Account:** Auto-created and linked per child during onboarding. Separate login per child.

---

---

# 12. CRC (Class-Responsibility-Collaborator) Analysis

## 12.1 School

| **Class: School** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Store school information (name, address, config) | Class |
| Manage division naming convention | User (SchoolAdmin, Principal) |
| Hold list of classes | Division |
| Hold list of staff (teachers, principal, admin) | |
| Define school-level settings | |

## 12.2 Class

| **Class: Class** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Represent a grade level (e.g., Grade 5) | School |
| Hold list of divisions (up to 26) | Division |
| Aggregate student performance across divisions | Leaderboard |
| Support leaderboard at class level | Subject |

## 12.3 Division

| **Class: Division** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Represent a section within a class (e.g., 5A) | Class |
| Hold list of enrolled students | Student |
| Support customizable naming | Leaderboard |
| Support leaderboard at division level | |

## 12.4 User (Abstract Base)

| **Class: User** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Store authentication credentials | NotificationService |
| Store profile information (name, email, phone) | School |
| Define role-based access | |
| Manage notification preferences | |

## 12.5 Student

| **Class: Student** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Belong to one division in one school | Division |
| Hold assigned notes and active repetition cycles | MindMap |
| Track streak (current, ring status) | RepetitionCycle |
| Track mastery status per concept | Streak |
| Record exam attempts and scores | Leaderboard |
| Calculate composite leaderboard score | ExamAttempt |
| Receive push notifications | NotificationService |
| | Parent |

## 12.6 Parent

| **Class: Parent** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| View linked child's progress (read-only) | Student |
| Receive real-time notifications on triggers | ActionableTask |
| View and acknowledge actionable tasks | NotificationService |
| Request consolidated report on demand | Report |
| View mind map, streaks, leaderboard, weak areas, schedule | |

## 12.7 SubjectTeacher

| **Class: SubjectTeacher** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Create mind maps, notes, decks, flashcards, MCQs | MindMap, Note, Deck |
| Assign notes to class (auto-propagates to students) | Division |
| Modify repetition cycle per student or class-wide | Student |
| Send manual tasks/alerts to parents | RepetitionCycle |
| Flag students for urgent attention | ActionableTask |
| View student performance for her subject | NotificationService |

## 12.8 ClassTeacher

| **Class: ClassTeacher** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| View all subjects for her class | Division |
| Identify and motivate underperforming students | Student |
| View cross-subject performance dashboard | Subject, Report |

## 12.9 Principal

| **Class: Principal** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| View all classes, all subjects, all students | School |
| View KPIs for students and teachers | Class |
| Configure leaderboard weights | Leaderboard |
| Monitor division benchmarking | Report, KPIDashboard |

## 12.10 SchoolAdmin

| **Class: SchoolAdmin** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Onboard students, teachers, principals | School |
| Manage school operations and configuration | User |
| Create admin-level content (notes, decks, flashcards, MCQs) | WorkRequest |
| Process work requests for weak area content | Note, Deck |

## 12.11 SuperAdmin

| **Class: SuperAdmin** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| View and manage all schools | School |
| Cross-school analytics and reports | SchoolAdmin |
| Manage school admin accounts | Report |

## 12.12 BossAdmin

| **Class: BossAdmin** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Full control over entire system (God mode) | All Classes |
| Override any setting or data | |
| Manage super admins | |

## 12.13 MindMap

| **Class: MindMap** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Represent hierarchical tree: Subject > Topic > Concept > Notes | Subject |
| Render node glow/dim based on retention (forgetting curve) | Topic |
| Display activity rings per concept node | Concept |
| Maintain fixed structure | KnowledgeDecayEngine |

## 12.14 Subject

| **Class: Subject** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Represent main node in mind map | MindMap |
| Hold list of topics | Topic |
| Link to assigned subject teacher(s) | SubjectTeacher |

## 12.15 Topic

| **Class: Topic** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Represent sub-node under a subject | Subject |
| Hold list of concepts | Concept |

## 12.16 Concept

| **Class: Concept** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Represent child node under a topic | Topic |
| Hold notes in file-system structure | Note |
| Track mastery status per student | KnowledgeDecayEngine |
| Calculate and display retention level (glow/dim) | StudentConceptProgress |

## 12.17 Note

| **Class: Note** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Store learning content | Concept |
| Hold multiple decks | Deck |
| Be assignable to a class | Assignment |

## 12.18 Deck

| **Class: Deck** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Contain 40 MCQs (30% easy, 30% medium, 40% hard) | Note |
| Contain 40 flashcards | MCQ |
| Track difficulty distribution | Flashcard |

## 12.19 MCQ

| **Class: MCQ** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Store question, options, correct answer | Deck |
| Store difficulty level (easy/medium/hard) | ExamAttempt |
| Track per-student answer history | |

## 12.20 Flashcard

| **Class: Flashcard** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Store front (question/prompt) and back (answer) | Deck |
| Track review status per student | Student |

## 12.21 RepetitionCycle

| **Class: RepetitionCycle** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Define interval sequence based on difficulty | Student |
| Track current interval position per student-concept | Concept |
| Support teacher override at student or class level | SubjectTeacher |
| Transition to maintenance phase after mastery | KnowledgeDecayEngine |
| Demote back to active cycle on failed maintenance review | |

## 12.22 KnowledgeDecayEngine

| **Class: KnowledgeDecayEngine** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Calculate retention using R = e^(-t/S) | Concept |
| Track memory strength (S) per student-concept | RepetitionCycle |
| Increase S with each successful review | NotificationService |
| Map retention value to node brightness/opacity | MindMap |
| Trigger critical decay notifications | |

## 12.23 Streak

| **Class: Streak** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Track daily streak count per student | Student |
| Monitor three ring statuses (Read, Flashcard, Exam) | ActivityRing |
| Reset to zero on any missed day (no grace period) | Leaderboard |
| Feed into composite leaderboard score | |

## 12.24 ActivityRing

| **Class: ActivityRing** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Track completion of Reading (red ring) | Streak |
| Track completion of Flashcard review (green ring) | Student |
| Track completion of Exam with ≥80% (blue ring) | ExamAttempt |
| Report ring status to Streak | |

## 12.25 ExamAttempt

| **Class: ExamAttempt** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Record student answers per MCQ | Student |
| Calculate score and pass/fail status | Deck |
| Flag weak areas (incorrect answers) | MCQ |
| Track attempt count (unlimited, all logged) | WeakArea |
| Track time spent | |

## 12.26 WeakArea

| **Class: WeakArea** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Flag specific concepts/questions student struggles with | ExamAttempt |
| Raise work request for admin to create new flashcards/MCQs | WorkRequest |
| Focus next repetition on these areas | RepetitionCycle |

## 12.27 WorkRequest

| **Class: WorkRequest** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Request creation of new flashcards/MCQs for weak areas | WeakArea |
| Track request status (pending/completed) | SchoolAdmin |
| Assign to admin for fulfillment | Deck |
| Link new content back to student | Student |

## 12.28 Leaderboard

| **Class: Leaderboard** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Rank students at division, class, and school levels | Student |
| Calculate composite score from configurable weights | Streak |
| Display rankings with streaks, mastery %, bonus, exam scores | Principal |
| Support principal-only weight configuration | Division, Class, School |

## 12.29 ActionableTask

| **Class: ActionableTask** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Auto-generate from decaying nodes, missed reviews, low scores | Parent |
| Accept manual creation by teacher | Student |
| Allow parent acknowledgment (separate from student completion) | SubjectTeacher |
| Recur daily until student actually completes the task | NotificationService |

## 12.30 NotificationService

| **Class: NotificationService** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Send real-time push notifications (Flutter/FCM) | Student |
| Route notifications to correct recipient (student/parent) | Parent |
| Handle all trigger types (missed review, broken streak, low score, decay, teacher flag) | ActionableTask |
| Support on-demand consolidated report for parents | KnowledgeDecayEngine, Streak |

## 12.31 Report

| **Class: Report** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Generate detailed parent reports (scores, weak areas, attempts, time spent) | Student |
| Generate teacher KPI reports (division benchmarking, completion rates) | Parent |
| Generate principal-level dashboards | SubjectTeacher |
| Support on-demand consolidated view | Principal, KPIDashboard |

## 12.32 KPIDashboard

| **Class: KPIDashboard** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Show per-student and per-teacher KPIs | Principal |
| Division benchmarking comparisons | Report |
| Task completion and bottleneck analysis | Division |
| Streak and engagement analytics | Student, SubjectTeacher |

## 12.33 Assignment

| **Class: Assignment** | |
|---|---|
| **Responsibilities** | **Collaborators** |
| Link a note to a class | Note |
| Auto-propagate to all students in the class | Class |
| Attach default repetition cycle | Student |
| Start timer and activate reminder suite | RepetitionCycle, NotificationService |
