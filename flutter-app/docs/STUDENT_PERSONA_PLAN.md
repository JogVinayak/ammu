# Student Persona Screens - Implementation Plan

## Overview

This document outlines the plan for implementing student-facing screens in the Flutter Teacher App. Students have a fundamentally different experience - they consume content released by teachers rather than creating it.

---

## Current State

### User Type Detection (Already Exists)
```dart
// In auth_models.dart
class User {
  bool get isTeacher => userType == 'TEACHER' || userType == 'PRINCIPAL' || userType == 'ADMIN';
  bool get isStudent => userType == 'STUDENT';
}
```

### Existing Infrastructure
- SharedPreferences stores `userType` after login
- GoRouter supports redirect logic based on auth state
- Riverpod providers can be role-aware

---

## Student vs Teacher Feature Comparison

| Feature | Teacher | Student |
|---------|---------|---------|
| Dashboard | Stats + Quick Actions | Learning Progress |
| Notes | Create, Edit, Publish, Release | View Released Only |
| Mindmaps | Create, Edit | View Released Only |
| Classes | View Assigned Classes | View Enrolled Class |
| Release | Release Content | N/A |
| Repository | Browse All Content | N/A |
| Profile | Basic Profile | Student Profile (Grade, Section, Roll) |

---

## Proposed Navigation Structure

### Bottom Navigation (5 tabs)
```
Index  Route              Screen
─────  ─────              ──────
0      /student/home      StudentDashboardScreen
1      /student/notes     StudentNotesScreen
2      /student/mindmaps  StudentMindmapsScreen
3      /student/class     StudentClassScreen
4      /student/profile   StudentProfileScreen
```

### Full-Screen Routes
```
/student/notes/:id        StudentNoteViewerScreen
/student/mindmaps/:id     StudentMindmapViewerScreen
/student/settings         SettingsScreen (shared)
```

---

## Screen Specifications

### 1. Student Dashboard (`/student/home`)

**Purpose**: Overview of learning materials and class activity

**UI Components**:
```
┌─────────────────────────────────────┐
│  Good Morning, Alice!               │
│  Grade 10 - Division A              │
├─────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐          │
│  │ Notes   │  │ Mindmaps│          │
│  │   5     │  │    3    │          │
│  │Available│  │Available│          │
│  └─────────┘  └─────────┘          │
├─────────────────────────────────────┤
│  Recent Content                     │
│  ┌─────────────────────────────┐   │
│  │ Photosynthesis        Note  │   │
│  │ Released 2 hours ago        │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ First Amendment       Note  │   │
│  │ Released yesterday          │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

**Data Requirements**:
- Student's class info (grade, section)
- Count of released notes for their class
- Count of released mindmaps for their class
- Recent released content (last 5 items)

**API Endpoints Needed**:
```
GET /v1/classes/{classId}
GET /v1/released-content?classId={classId}&contentType=note
GET /v1/released-content?classId={classId}&contentType=mindmap
```

---

### 2. Student Notes List (`/student/notes`)

**Purpose**: Browse notes released to student's class

**UI Components**:
```
┌─────────────────────────────────────┐
│  My Notes                    🔍     │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │ 📄 Photosynthesis           │   │
│  │    The process by which...  │   │
│  │    Released: Feb 1, 2026    │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 📄 First Amendment          │   │
│  │    Understanding the five...│   │
│  │    Released: Feb 1, 2026    │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 📄 Introduction to Algebra  │   │
│  │    Basic algebraic concepts │   │
│  │    Released: Feb 1, 2026    │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

**Features**:
- Search by title
- Sort by: Recent, Title A-Z
- Pull-to-refresh
- Empty state: "No notes released yet"

**Data Flow**:
1. Get student's class_id from student_profile
2. Query released_content where class_id matches
3. Fetch actual note details from notes service

**API Endpoints Needed**:
```
GET /v1/student/profile                    → Get classId
GET /v1/released-content?classId={id}&contentType=note
GET /v1/notes/{noteId}                     → For each released note
```

---

### 3. Student Note Viewer (`/student/notes/:id`)

**Purpose**: Read a released note

**UI Components**:
```
┌─────────────────────────────────────┐
│  ← Photosynthesis                   │
├─────────────────────────────────────┤
│                                     │
│  # Photosynthesis                   │
│                                     │
│  ## What is Photosynthesis?         │
│                                     │
│  Photosynthesis is the process by   │
│  which green plants, algae, and     │
│  some bacteria convert light        │
│  energy...                          │
│                                     │
│  ## The Basic Equation              │
│                                     │
│  ```                                │
│  6CO₂ + 6H₂O + Light → C₆H₁₂O₆ + O₂│
│  ```                                │
│                                     │
└─────────────────────────────────────┘
```

**Features**:
- Markdown rendering (using flutter_markdown)
- Scroll through content
- Back navigation
- No edit/delete options

---

### 4. Student Mindmaps List (`/student/mindmaps`)

**Purpose**: Browse mindmaps released to student's class

**UI Layout**: Grid (2 columns) similar to teacher mindmaps

**Features**:
- Visual thumbnail/preview
- Node count display
- Tap to view full mindmap

---

### 5. Student Mindmap Viewer (`/student/mindmaps/:id`)

**Purpose**: Interactive mindmap viewing

**Features**:
- Pan and zoom
- Expand/collapse nodes
- Read-only (no editing)

---

### 6. Student Class Screen (`/student/class`)

**Purpose**: View class information and classmates

**UI Components**:
```
┌─────────────────────────────────────┐
│  My Class                           │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │ Grade 10 - Division A       │   │
│  │ Subject: General            │   │
│  │ Students: 25                │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  Classmates                         │
│  ┌─────────────────────────────┐   │
│  │ 👤 Alice Brown    (You)     │   │
│  │    Roll No: 10A001          │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 👤 Bob Wilson               │   │
│  │    Roll No: 10A002          │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

**API Endpoints Needed**:
```
GET /v1/classes/{classId}
GET /v1/classes/{classId}/students
```

---

### 7. Student Profile Screen (`/student/profile`)

**Purpose**: View student information

**UI Components**:
```
┌─────────────────────────────────────┐
│        ┌───────┐                    │
│        │  AB   │  (Avatar)          │
│        └───────┘                    │
│      Alice Brown                    │
│   alice.student@greenwood.edu       │
├─────────────────────────────────────┤
│  Student Information                │
│  ┌─────────────────────────────┐   │
│  │ Grade        10             │   │
│  │ Section      A              │   │
│  │ Roll Number  10A001         │   │
│  │ Class        Grade 10 - A   │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  ⚙️  Settings                       │
│  ❓  Help & Support                 │
│  ℹ️  About                          │
│  🚪  Logout                         │
└─────────────────────────────────────┘
```

---

## New Files to Create

### Feature Structure
```
lib/features/student/
├── data/
│   ├── student_models.dart           # StudentProfile, ReleasedContent models
│   └── student_repository.dart       # API calls for student data
├── providers/
│   ├── student_provider.dart         # Student profile state
│   ├── student_notes_provider.dart   # Released notes state
│   └── student_mindmaps_provider.dart# Released mindmaps state
└── screens/
    ├── student_dashboard_screen.dart
    ├── student_notes_screen.dart
    ├── student_note_viewer_screen.dart
    ├── student_mindmaps_screen.dart
    ├── student_mindmap_viewer_screen.dart
    ├── student_class_screen.dart
    └── student_profile_screen.dart
```

### Router Updates
```
lib/router/
├── app_router.dart                   # Add student routes
└── student_shell.dart                # New bottom nav for students
```

---

## Backend API Requirements

### New Endpoints Needed

#### 1. Get Student Profile
```
GET /v1/student/me
Headers: X-Tenant-Id, X-User-Id

Response:
{
  "id": "uuid",
  "userId": "uuid",
  "grade": "10",
  "section": "A",
  "rollNumber": "10A001",
  "classId": "uuid",
  "className": "Grade 10 - Division A"
}
```

#### 2. Get Released Content for Class
```
GET /v1/workflow/released?classId={uuid}&contentType={note|mindmap}
Headers: X-Tenant-Id

Response:
{
  "items": [
    {
      "id": "uuid",
      "contentId": "uuid",
      "contentType": "note",
      "classId": "uuid",
      "releasedBy": "uuid",
      "releasedAt": "2026-02-01T10:00:00Z"
    }
  ]
}
```

#### 3. Get Class Students
```
GET /v1/classes/{classId}/students
Headers: X-Tenant-Id

Response:
{
  "items": [
    {
      "userId": "uuid",
      "displayName": "Alice Brown",
      "rollNumber": "10A001",
      "grade": "10",
      "section": "A"
    }
  ]
}
```

---

## Implementation Phases

### Phase 1: Core Infrastructure
- [ ] Create student feature folder structure
- [ ] Add student routes to GoRouter
- [ ] Create StudentShell with bottom navigation
- [ ] Implement role-based routing (redirect students to /student/home)

### Phase 2: Student Dashboard
- [ ] Create StudentDashboardScreen
- [ ] Create student_provider for profile data
- [ ] Display class info and content counts
- [ ] Show recent released content

### Phase 3: Notes Experience
- [ ] Create StudentNotesScreen (list view)
- [ ] Create student_notes_provider
- [ ] Create StudentNoteViewerScreen
- [ ] Implement search functionality

### Phase 4: Mindmaps Experience
- [ ] Create StudentMindmapsScreen (grid view)
- [ ] Create student_mindmaps_provider
- [ ] Create StudentMindmapViewerScreen

### Phase 5: Class & Profile
- [ ] Create StudentClassScreen
- [ ] Create StudentProfileScreen
- [ ] Implement classmates list

### Phase 6: Polish
- [ ] Empty states for all screens
- [ ] Error handling
- [ ] Loading states
- [ ] Pull-to-refresh

---

## Data Models

### StudentProfile
```dart
class StudentProfile {
  final String id;
  final String userId;
  final String tenantId;
  final String grade;
  final String section;
  final String rollNumber;
  final String classId;
  final String? board;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

### ReleasedContentItem
```dart
class ReleasedContentItem {
  final String id;
  final String contentId;
  final String contentType; // 'note' or 'mindmap'
  final String classId;
  final String? releasedBy;
  final DateTime releasedAt;

  // Populated after fetching actual content
  final String? title;
  final String? summary;
}
```

---

## State Management

### StudentNotifier (student_provider.dart)
```dart
class StudentState {
  final StudentProfile? profile;
  final bool isLoading;
  final String? error;
}

class StudentNotifier extends StateNotifier<StudentState> {
  Future<void> loadProfile();
}
```

### StudentNotesNotifier (student_notes_provider.dart)
```dart
class StudentNotesState {
  final List<Note> notes;
  final bool isLoading;
  final String? error;
  final String searchQuery;
}

class StudentNotesNotifier extends StateNotifier<StudentNotesState> {
  Future<void> loadReleasedNotes();
  void search(String query);
}
```

---

## UI/UX Considerations

### Color Differentiation
Consider using a slightly different accent color for student UI to visually distinguish from teacher mode:
- Teacher: Indigo (#6366F1)
- Student: Teal (#14B8A6) or Blue (#3B82F6)

### Empty States
- "No notes have been released to your class yet"
- "No mindmaps available"
- "Ask your teacher to release content"

### Read-Only Indicators
- No FABs (FloatingActionButtons) for creating content
- No edit/delete options in menus
- View-only markdown rendering

---

## Testing Checklist

- [ ] Login as student redirects to student dashboard
- [ ] Student cannot access teacher routes
- [ ] Released notes appear in student's list
- [ ] Released mindmaps appear in student's list
- [ ] Note viewer renders markdown correctly
- [ ] Mindmap viewer allows pan/zoom
- [ ] Class screen shows classmates
- [ ] Profile shows student info (grade, section, roll)
- [ ] Logout works correctly
- [ ] Empty states display properly
- [ ] Search filters content correctly

---

## Test Credentials

| Role | Email | Password |
|------|-------|----------|
| Student | alice.student@greenwood.edu | Student@123 |
| Student | bob.student@greenwood.edu | Student@123 |
| Teacher | john.smith@greenwood.edu | Teacher@123 |

---

## Dependencies

No new dependencies required. Existing packages support all features:
- `flutter_riverpod` - State management
- `go_router` - Navigation
- `dio` - HTTP client
- `flutter_markdown` - Markdown rendering
- `shared_preferences` - Local storage

---

## Notes

1. **Reuse existing components**: AppCard, AppButton, LoadingIndicator, EmptyState
2. **Share settings screen**: Same implementation for both personas
3. **Consider offline**: Cache released content for offline viewing (future enhancement)
4. **Push notifications**: Notify students when new content is released (future enhancement)
