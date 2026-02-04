# Flutter App Prompt for Claude

## Task
Create a Flutter mobile application for **Subject Teacher** persona in an e-learning platform.

---

## Backend Services

| Service | URL | Purpose |
|---------|-----|---------|
| Auth | `http://localhost:8081` | Login, signup, tokens |
| Notes | `http://localhost:8088` | CRUD notes |
| Mindmap | `http://localhost:8087` | CRUD mindmaps |
| Workflow | `http://localhost:8086` | Content approval |

### API Headers (All requests)
```
Authorization: Bearer {{accessToken}}
X-Tenant-Id: {{tenantId}}
X-User-Id: {{userId}}
Content-Type: application/json
```

### Key APIs

**Login**
```
POST /auth/login
Body: { "tenantId": "...", "identifier": "email", "password": "..." }
Response: { "accessToken": "...", "refreshToken": "...", "userId": "...", "tenantId": "..." }
```

**Get Notes**
```
GET /notes?scopeType=TENANT&status=PUBLISHED&page=0&size=20
Response: { "items": [...], "page": 0, "size": 20, "total": 100 }
```

**Create Note**
```
POST /notes
Body: { "tenantId": "...", "title": "...", "summary": "...", "contentMd": "...", "tags": [...], "scopeType": "USER" }
```

**Get Mindmaps**
```
GET /mindmaps?ownerId={{userId}}
```

---

## Tech Stack

- Flutter 3.x
- State Management: Riverpod
- Navigation: GoRouter
- HTTP: Dio
- Storage: SharedPreferences

---

## Screens to Create (17 total)

### 1. Login Screen
- Email/phone field
- Password field with show/hide
- "Forgot Password" link
- "Sign In" button
- Validate inputs, show errors

### 2. Dashboard
- Greeting: "Hello, {{name}}"
- Stats cards: My Notes, My Mindmaps, Classes, Released
- Quick actions: Browse Repository, Create Note, Create Mindmap
- Recent content list
- Bottom navigation: Home, Repository, Content, Classes, Profile

### 3. Repository Browser
- Search bar
- Filter chips: Subject, Grade, Type
- List of published notes/mindmaps
- Each card: Title, tags, author, "Copy" button

### 4. Content Preview
- Title, author, date
- Tags
- Rendered markdown content
- "Copy to My Notes" FAB

### 5. My Notes List
- Tabs: All, Draft, Released
- Search and filter
- Note cards with title, summary, tags, status
- 3-dot menu: Edit, Release, Delete
- FAB to create new note

### 6. Note Editor
- Title field
- Summary field
- Tags input
- Markdown editor with toolbar (bold, italic, list, code)
- Preview toggle
- Save button

### 7. Note Viewer
- Title, meta info
- Rendered markdown
- "Release to Class" button

### 8. My Mindmaps List
- Grid of mindmap cards
- Each: thumbnail, title, node count
- FAB to create new

### 9. Mindmap Editor
- Canvas with nodes
- Add/edit/delete nodes
- Link notes to nodes
- Save button

### 10. Mindmap Viewer
- Interactive zoomable canvas
- Tap node to see details
- View linked notes

### 11. My Classes
- List of classes teacher teaches
- Class name, subject, student count

### 12. Class Detail
- Class info header
- Tabs: Students, Released Content
- Student list
- Released content list

### 13. Release Content
- Step 1: Select content (notes/mindmaps)
- Step 2: Select classes
- Step 3: Confirm and release

### 14. Release History
- Timeline of past releases
- Content title, class, date

### 15. Profile
- Avatar, name, email
- School info
- Edit Profile, Settings, Logout

### 16. Settings
- Theme toggle
- Notifications toggle
- Clear cache
- App version

### 17. Forgot Password
- Email input
- Send OTP button
- OTP verification

---

## Design Specs

### Colors
```dart
primary: Color(0xFF6366F1)      // Indigo
secondary: Color(0xFF10B981)    // Green
error: Color(0xFFEF4444)        // Red
background: Color(0xFFF8FAFC)   // Light gray
surface: Color(0xFFFFFFFF)      // White
textPrimary: Color(0xFF1E293B)  // Dark
textSecondary: Color(0xFF64748B) // Gray
```

### Typography
- Headlines: Inter Bold, 20-24sp
- Body: Inter Regular, 14-16sp
- Caption: Inter Regular, 12sp

### Spacing
- xs: 4, sm: 8, md: 16, lg: 24, xl: 32

### Border Radius
- Cards: 12
- Buttons: 8
- Chips: 16

---

## Folder Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── theme/app_theme.dart
│   ├── network/dio_client.dart
│   └── constants/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── providers/
│   │   └── screens/
│   ├── dashboard/
│   ├── repository/
│   ├── notes/
│   ├── mindmaps/
│   ├── classes/
│   ├── release/
│   └── profile/
├── shared/widgets/
└── router/app_router.dart
```

---

## Shared Widgets Needed

1. **AppButton** - Primary, secondary, outline variants
2. **AppTextField** - With label, icon, validation
3. **AppCard** - Elevated card with tap
4. **LoadingIndicator** - Circular spinner
5. **EmptyState** - Icon, title, subtitle, action
6. **ErrorWidget** - Error message with retry
7. **BottomNavBar** - 5 tabs

---

## Requirements

1. Use Material 3 design
2. Handle loading, error, empty states for all lists
3. Pull-to-refresh on list screens
4. Form validation with error messages
5. Snackbar for success/error feedback
6. Responsive layout
7. Clean, readable code with comments

---

## Generate Order

Start with:
1. `lib/core/theme/app_theme.dart`
2. `lib/core/network/dio_client.dart`
3. `lib/shared/widgets/` (all widgets)
4. `lib/features/auth/` (login screen)
5. `lib/features/dashboard/`
6. Continue with remaining features...

---

## Example: Generate Login Screen

Generate complete Flutter code for login screen with:
- Form validation
- Loading state on button
- Error handling
- Navigation to dashboard on success
- "Forgot password" link
- Clean UI matching design specs

Include:
- Screen file
- Provider/state management
- Repository for API calls
- Models for request/response

---

## Start Prompt

"Create the Flutter login screen for the teacher app. Include the screen widget, auth provider using Riverpod, auth repository with Dio, and request/response models. Follow the design specs and folder structure above."
