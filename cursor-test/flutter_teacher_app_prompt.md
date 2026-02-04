# Flutter Mobile App - Subject Teacher Persona

## Prompt for Claude to Generate Flutter Screens

---

## PROJECT CONTEXT

You are building a **mobile app for Subject Teachers** in a multi-tenant e-learning platform. Teachers can browse a content repository, copy notes to their collection, create mindmaps, and release content to their students.

### Tech Stack
- **Framework**: Flutter 3.x (latest stable)
- **State Management**: Riverpod 2.x
- **Navigation**: GoRouter
- **HTTP Client**: Dio
- **Local Storage**: SharedPreferences (tokens), Hive (cache)
- **UI Components**: Material 3 Design

### Backend APIs
| Service | Base URL |
|---------|----------|
| Auth | `http://{{host}}:8081` |
| Tenant | `http://{{host}}:8082` |
| Role-Permission | `http://{{host}}:8080` |
| Notes | `http://{{host}}:8088` |
| Mindmap | `http://{{host}}:8087` |

---

## DESIGN SYSTEM

### Brand Colors
```dart
// Primary palette
static const Color primary = Color(0xFF6366F1);      // Indigo
static const Color primaryLight = Color(0xFF818CF8);
static const Color primaryDark = Color(0xFF4F46E5);

// Secondary palette
static const Color secondary = Color(0xFF10B981);    // Emerald (success)
static const Color accent = Color(0xFFF59E0B);       // Amber (warning)
static const Color error = Color(0xFFEF4444);        // Red

// Neutrals
static const Color background = Color(0xFFF8FAFC);
static const Color surface = Color(0xFFFFFFFF);
static const Color textPrimary = Color(0xFF1E293B);
static const Color textSecondary = Color(0xFF64748B);
static const Color border = Color(0xFFE2E8F0);
```

### Typography
```dart
// Font: Google Fonts - Inter
static const String fontFamily = 'Inter';

// Text Styles
headline1: 24sp, bold, textPrimary
headline2: 20sp, semibold, textPrimary
headline3: 18sp, semibold, textPrimary
bodyLarge: 16sp, regular, textPrimary
bodyMedium: 14sp, regular, textSecondary
caption: 12sp, regular, textSecondary
button: 14sp, semibold, white
```

### Spacing
```dart
static const double xs = 4.0;
static const double sm = 8.0;
static const double md = 16.0;
static const double lg = 24.0;
static const double xl = 32.0;
static const double xxl = 48.0;
```

### Border Radius
```dart
static const double radiusSm = 8.0;
static const double radiusMd = 12.0;
static const double radiusLg = 16.0;
static const double radiusXl = 24.0;
```

### Shadows
```dart
// Card shadow
BoxShadow(
  color: Colors.black.withOpacity(0.05),
  blurRadius: 10,
  offset: Offset(0, 4),
)
```

---

## FOLDER STRUCTURE

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   └── api_endpoints.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── network/
│   │   ├── dio_client.dart
│   │   ├── api_interceptor.dart
│   │   └── api_exceptions.dart
│   ├── storage/
│   │   └── secure_storage.dart
│   └── utils/
│       ├── validators.dart
│       └── date_formatter.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── login_request.dart
│   │   │   │   └── auth_response.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── forgot_password_screen.dart
│   │       └── widgets/
│   │           └── login_form.dart
│   │
│   ├── dashboard/
│   │   ├── providers/
│   │   │   └── dashboard_provider.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── teacher_dashboard_screen.dart
│   │       └── widgets/
│   │           ├── stats_card.dart
│   │           ├── recent_content_list.dart
│   │           └── quick_actions.dart
│   │
│   ├── repository/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── repository_note.dart
│   │   │   └── repositories/
│   │   │       └── repository_repository.dart
│   │   ├── providers/
│   │   │   └── repository_provider.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── repository_browser_screen.dart
│   │       │   └── content_preview_screen.dart
│   │       └── widgets/
│   │           ├── repository_filter_bar.dart
│   │           ├── content_card.dart
│   │           └── copy_bottom_sheet.dart
│   │
│   ├── notes/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── note.dart
│   │   │   │   └── note_version.dart
│   │   │   └── repositories/
│   │   │       └── notes_repository.dart
│   │   ├── providers/
│   │   │   └── notes_provider.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── my_notes_screen.dart
│   │       │   ├── note_editor_screen.dart
│   │       │   └── note_viewer_screen.dart
│   │       └── widgets/
│   │           ├── note_card.dart
│   │           ├── markdown_editor.dart
│   │           └── tag_chips.dart
│   │
│   ├── mindmaps/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── mindmap.dart
│   │   │   │   └── mindmap_node.dart
│   │   │   └── repositories/
│   │   │       └── mindmap_repository.dart
│   │   ├── providers/
│   │   │   └── mindmap_provider.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── my_mindmaps_screen.dart
│   │       │   ├── mindmap_editor_screen.dart
│   │       │   └── mindmap_viewer_screen.dart
│   │       └── widgets/
│   │           ├── mindmap_card.dart
│   │           ├── mindmap_canvas.dart
│   │           └── node_widget.dart
│   │
│   ├── classes/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── class_model.dart
│   │   │   │   └── student.dart
│   │   │   └── repositories/
│   │   │       └── class_repository.dart
│   │   ├── providers/
│   │   │   └── class_provider.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── my_classes_screen.dart
│   │       │   └── class_detail_screen.dart
│   │       └── widgets/
│   │           ├── class_card.dart
│   │           └── student_list_tile.dart
│   │
│   ├── release/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── release_record.dart
│   │   │   └── repositories/
│   │   │       └── release_repository.dart
│   │   ├── providers/
│   │   │   └── release_provider.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── release_content_screen.dart
│   │       │   └── release_history_screen.dart
│   │       └── widgets/
│   │           ├── class_selector.dart
│   │           └── release_confirmation_dialog.dart
│   │
│   └── profile/
│       ├── providers/
│       │   └── profile_provider.dart
│       └── presentation/
│           ├── screens/
│           │   ├── profile_screen.dart
│           │   └── settings_screen.dart
│           └── widgets/
│               └── profile_header.dart
│
├── shared/
│   └── widgets/
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── app_card.dart
│       ├── loading_indicator.dart
│       ├── error_widget.dart
│       ├── empty_state.dart
│       ├── app_bar_widget.dart
│       └── bottom_nav_bar.dart
│
└── router/
    └── app_router.dart
```

---

## SCREEN SPECIFICATIONS

### SCREEN 1: Login Screen
**File**: `lib/features/auth/presentation/screens/login_screen.dart`

**UI Elements**:
- App logo (centered, top 20%)
- Welcome text: "Welcome Back" (headline1)
- Subtitle: "Sign in to continue" (bodyMedium)
- Email/Phone text field with icon
- Password text field with show/hide toggle
- "Forgot Password?" link (right-aligned)
- "Sign In" primary button (full width)
- Loading state on button when submitting

**Behavior**:
- Validate email format / phone format
- Show inline errors below fields
- On success: Navigate to Dashboard
- On error: Show snackbar with message

**API**:
```
POST /auth/login
Headers: Content-Type: application/json
Body: {
  "tenantId": "{{tenantId}}",
  "identifier": "teacher@school.com",
  "password": "password123"
}
Response: {
  "accessToken": "...",
  "refreshToken": "...",
  "userId": "...",
  "tenantId": "..."
}
```

---

### SCREEN 2: Teacher Dashboard
**File**: `lib/features/dashboard/presentation/screens/teacher_dashboard_screen.dart`

**UI Elements**:
- AppBar with greeting: "Hello, {{teacherName}}" and profile avatar
- Stats Row (horizontal scroll):
  - Card 1: "My Notes" with count
  - Card 2: "My Mindmaps" with count
  - Card 3: "Classes" with count
  - Card 4: "Released" with count
- Quick Actions Section:
  - "Browse Repository" button with icon
  - "Create Note" button with icon
  - "Create Mindmap" button with icon
- Recent Content Section:
  - Section header: "Recent Content" with "See All" link
  - Horizontal list of recent note/mindmap cards
- Bottom Navigation Bar:
  - Home (selected), Repository, My Content, Classes, Profile

**Behavior**:
- Pull to refresh
- Tap stats card → navigate to respective list
- Tap quick action → navigate to respective screen

---

### SCREEN 3: Repository Browser
**File**: `lib/features/repository/presentation/screens/repository_browser_screen.dart`

**UI Elements**:
- AppBar with title "Repository" and search icon
- Search bar (expandable on tap)
- Filter chips row (horizontal scroll):
  - Subject: Science, Math, English, etc.
  - Grade: Grade 1-12
  - Type: Notes, Mindmaps
- Content grid/list toggle
- Content cards (list view default):
  - Thumbnail/icon
  - Title
  - Subject + Grade tags
  - Author name
  - "Copy" button
- Pagination: Load more on scroll

**API**:
```
GET /notes?scopeType=TENANT&status=PUBLISHED&tag={{subject}}&page=0&size=20
Headers:
  Authorization: Bearer {{token}}
  X-Tenant-Id: {{tenantId}}
```

**Behavior**:
- Search filters results in real-time (debounced 300ms)
- Tap card → Content Preview Screen
- Tap "Copy" → Copy Bottom Sheet

---

### SCREEN 4: Content Preview
**File**: `lib/features/repository/presentation/screens/content_preview_screen.dart`

**UI Elements**:
- AppBar with back button and "Copy" action
- Hero image/thumbnail (if available)
- Title (headline1)
- Meta info row: Author, Created date, Subject, Grade
- Tags as chips
- Divider
- Content body (rendered markdown)
- Floating Action Button: "Copy to My Notes"

**API**:
```
GET /notes/{{noteId}}
GET /notes/{{noteId}}/versions/{{versionId}}
```

---

### SCREEN 5: Copy Bottom Sheet
**File**: `lib/features/repository/presentation/widgets/copy_bottom_sheet.dart`

**UI Elements**:
- Handle bar
- Title: "Copy to My Collection"
- Note preview (title + summary)
- Destination selector:
  - Radio: "My Notes" (default)
  - Radio: "Link to Mindmap" → shows mindmap dropdown
- Optional: Add custom tags field
- "Cancel" and "Copy" buttons

**API**:
```
POST /notes
Body: {
  "tenantId": "...",
  "title": "{{originalTitle}} (Copy)",
  "contentMd": "{{originalContent}}",
  "tags": ["#copied", "#subject-science"],
  "scopeType": "USER",
  "sourceNoteId": "{{originalNoteId}}"
}
```

---

### SCREEN 6: My Notes List
**File**: `lib/features/notes/presentation/screens/my_notes_screen.dart`

**UI Elements**:
- AppBar: "My Notes" with search and filter icons
- Tabs: "All", "Draft", "Released"
- Search bar (collapsible)
- Filter bottom sheet trigger
- Notes list:
  - Note card with:
    - Title
    - Summary (2 lines max)
    - Tags
    - Status badge (Draft/Released)
    - Last modified date
    - 3-dot menu (Edit, Release, Delete)
- FAB: "+" to create new note
- Empty state when no notes

**API**:
```
GET /notes?createdBy={{userId}}&scopeType=USER&page=0&size=20
```

---

### SCREEN 7: Note Editor
**File**: `lib/features/notes/presentation/screens/note_editor_screen.dart`

**UI Elements**:
- AppBar: "Edit Note" / "New Note" with Save action
- Title text field (large, no border)
- Summary text field (smaller)
- Tags input (chip input with autocomplete)
- Markdown editor:
  - Toolbar: Bold, Italic, Heading, List, Link, Image, Code, LaTeX
  - Editor area (monospace font)
  - Preview toggle button
- Preview mode: Rendered markdown
- Auto-save indicator

**Behavior**:
- Auto-save draft every 30 seconds
- Unsaved changes warning on back
- Validate required fields before save

**API**:
```
POST /notes (create)
PATCH /notes/{{noteId}} (update)
POST /notes/{{noteId}}/versions (new version)
```

---

### SCREEN 8: Note Viewer
**File**: `lib/features/notes/presentation/screens/note_viewer_screen.dart`

**UI Elements**:
- AppBar with back, edit, and share actions
- Title (headline1)
- Meta: Author, Last updated, Version
- Tags as chips
- Rendered markdown content:
  - Support headings, lists, code blocks
  - Support LaTeX math rendering
  - Support images
- Bottom bar: "Release to Class" button (if not released)

---

### SCREEN 9: My Mindmaps List
**File**: `lib/features/mindmaps/presentation/screens/my_mindmaps_screen.dart`

**UI Elements**:
- AppBar: "My Mindmaps" with search
- Mindmap cards grid (2 columns):
  - Thumbnail preview
  - Title
  - Node count
  - Status badge
  - Last modified
- FAB: "+" to create new mindmap
- Empty state

**API**:
```
GET /mindmaps?ownerId={{userId}}&page=0&size=20
```

---

### SCREEN 10: Mindmap Editor
**File**: `lib/features/mindmaps/presentation/screens/mindmap_editor_screen.dart`

**UI Elements**:
- AppBar: "Edit Mindmap" with Save and Preview actions
- Canvas area (pannable, zoomable):
  - Central root node
  - Child nodes with connections
  - Tap node to select
  - Double tap to edit node text
  - Long press to show node menu (Add child, Link note, Delete)
- Bottom toolbar:
  - Add node
  - Link existing note
  - Change color
  - Undo/Redo
- Node properties panel (slide up):
  - Node title
  - Node description
  - Linked note selector
  - Color picker

**API**:
```
POST /mindmaps (create)
PATCH /mindmaps/{{mindmapId}} (update)
POST /mindmaps/{{mindmapId}}/nodes (add node)
```

---

### SCREEN 11: Mindmap Viewer
**File**: `lib/features/mindmaps/presentation/screens/mindmap_viewer_screen.dart`

**UI Elements**:
- AppBar with back, edit, fullscreen, share
- Interactive canvas:
  - Pan and zoom gestures
  - Tap node to see details
  - Tap linked note to open note viewer
- Node detail bottom sheet:
  - Node title
  - Description
  - "View Linked Note" button (if linked)
- Legend (collapsible)

---

### SCREEN 12: My Classes
**File**: `lib/features/classes/presentation/screens/my_classes_screen.dart`

**UI Elements**:
- AppBar: "My Classes"
- Class cards list:
  - Class name (e.g., "Grade 4 - Section A")
  - Subject taught
  - Student count
  - Recent release info
- Tap card → Class Detail

**API**:
```
GET /classes?teacherId={{userId}}
```

---

### SCREEN 13: Class Detail
**File**: `lib/features/classes/presentation/screens/class_detail_screen.dart`

**UI Elements**:
- AppBar: "{{className}}" with release action
- Header card:
  - Class name
  - Subject
  - Student count
  - School year
- Tabs: "Students", "Released Content"
- Students tab:
  - Student list with avatar, name, email
- Released Content tab:
  - List of released notes/mindmaps
  - Release date
  - Content type icon

---

### SCREEN 14: Release Content
**File**: `lib/features/release/presentation/screens/release_content_screen.dart`

**UI Elements**:
- AppBar: "Release Content"
- Step indicator (1. Select Content, 2. Select Class, 3. Confirm)
- Step 1 - Content Selection:
  - Tabs: "Notes", "Mindmaps"
  - Selectable list with checkboxes
  - Selected count indicator
- Step 2 - Class Selection:
  - Class list with checkboxes
  - "Select All" option
- Step 3 - Confirmation:
  - Summary of selected content
  - Summary of target classes
  - Release notes text field (optional)
  - "Release Now" button
- Success dialog with animation

**API**:
```
POST /notes/{{noteId}}/release
Body: {
  "classIds": ["class1", "class2"],
  "releaseNote": "Chapter 5 materials"
}
```

---

### SCREEN 15: Release History
**File**: `lib/features/release/presentation/screens/release_history_screen.dart`

**UI Elements**:
- AppBar: "Release History" with filter
- Filter chips: All, This Week, This Month
- Timeline list:
  - Date header
  - Release cards:
    - Content title + type icon
    - Target class(es)
    - Release timestamp
    - Student view count (if available)

---

### SCREEN 16: Profile
**File**: `lib/features/profile/presentation/screens/profile_screen.dart`

**UI Elements**:
- Profile header:
  - Avatar (editable)
  - Name
  - Email
  - Role badge: "Subject Teacher"
- Info section:
  - School/Tenant name
  - Subjects taught
  - Member since
- Actions list:
  - Edit Profile
  - Settings
  - Help & Support
  - Logout (with confirmation)

---

### SCREEN 17: Settings
**File**: `lib/features/profile/presentation/screens/settings_screen.dart`

**UI Elements**:
- AppBar: "Settings"
- Sections:
  - Appearance:
    - Theme toggle (Light/Dark/System)
  - Notifications:
    - Push notifications toggle
    - Email notifications toggle
  - Storage:
    - Clear cache button
    - Cache size display
  - About:
    - App version
    - Terms of Service link
    - Privacy Policy link

---

## SHARED WIDGETS SPECIFICATIONS

### AppButton
```dart
AppButton(
  label: "Sign In",
  onPressed: () {},
  isLoading: false,
  variant: ButtonVariant.primary, // primary, secondary, outline, text
  size: ButtonSize.large, // small, medium, large
  fullWidth: true,
  icon: Icons.login,
)
```

### AppTextField
```dart
AppTextField(
  label: "Email",
  hint: "Enter your email",
  controller: _emailController,
  keyboardType: TextInputType.email,
  prefixIcon: Icons.email,
  suffixIcon: Icons.clear,
  validator: Validators.email,
  obscureText: false,
  maxLines: 1,
  errorText: "Invalid email",
)
```

### AppCard
```dart
AppCard(
  child: content,
  padding: EdgeInsets.all(16),
  onTap: () {},
  elevation: 1,
  borderRadius: 12,
)
```

### LoadingIndicator
```dart
LoadingIndicator(
  size: 24,
  color: AppColors.primary,
  type: LoadingType.circular, // circular, dots, shimmer
)
```

### EmptyState
```dart
EmptyState(
  icon: Icons.note_outlined,
  title: "No Notes Yet",
  subtitle: "Create your first note or browse the repository",
  actionLabel: "Browse Repository",
  onAction: () {},
)
```

### ErrorWidget
```dart
AppErrorWidget(
  message: "Failed to load notes",
  onRetry: () {},
)
```

---

## STATE MANAGEMENT PATTERNS

### Provider Example (Riverpod)
```dart
// notes_provider.dart
final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<Note>>>((ref) {
  return NotesNotifier(ref.read(notesRepositoryProvider));
});

class NotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final NotesRepository _repository;

  NotesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _repository.getMyNotes();
      state = AsyncValue.data(notes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createNote(CreateNoteRequest request) async {
    // implementation
  }
}
```

### Usage in Widget
```dart
class MyNotesScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);

    return notesAsync.when(
      loading: () => LoadingIndicator(),
      error: (e, st) => AppErrorWidget(message: e.toString(), onRetry: () => ref.refresh(notesProvider)),
      data: (notes) => NotesList(notes: notes),
    );
  }
}
```

---

## NAVIGATION (GoRouter)

```dart
final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final isLoggedIn = // check auth state
    final isLoggingIn = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoggingIn) return '/login';
    if (isLoggedIn && isLoggingIn) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => ForgotPasswordScreen()),

    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => TeacherDashboardScreen()),
        GoRoute(path: '/repository', builder: (_, __) => RepositoryBrowserScreen()),
        GoRoute(path: '/repository/:noteId', builder: (_, state) => ContentPreviewScreen(noteId: state.pathParameters['noteId']!)),
        GoRoute(path: '/notes', builder: (_, __) => MyNotesScreen()),
        GoRoute(path: '/notes/new', builder: (_, __) => NoteEditorScreen()),
        GoRoute(path: '/notes/:noteId', builder: (_, state) => NoteViewerScreen(noteId: state.pathParameters['noteId']!)),
        GoRoute(path: '/notes/:noteId/edit', builder: (_, state) => NoteEditorScreen(noteId: state.pathParameters['noteId'])),
        GoRoute(path: '/mindmaps', builder: (_, __) => MyMindmapsScreen()),
        GoRoute(path: '/mindmaps/new', builder: (_, __) => MindmapEditorScreen()),
        GoRoute(path: '/mindmaps/:id', builder: (_, state) => MindmapViewerScreen(id: state.pathParameters['id']!)),
        GoRoute(path: '/mindmaps/:id/edit', builder: (_, state) => MindmapEditorScreen(id: state.pathParameters['id'])),
        GoRoute(path: '/classes', builder: (_, __) => MyClassesScreen()),
        GoRoute(path: '/classes/:classId', builder: (_, state) => ClassDetailScreen(classId: state.pathParameters['classId']!)),
        GoRoute(path: '/release', builder: (_, __) => ReleaseContentScreen()),
        GoRoute(path: '/release/history', builder: (_, __) => ReleaseHistoryScreen()),
        GoRoute(path: '/profile', builder: (_, __) => ProfileScreen()),
        GoRoute(path: '/settings', builder: (_, __) => SettingsScreen()),
      ],
    ),
  ],
);
```

---

## API INTERCEPTOR

```dart
class ApiInterceptor extends Interceptor {
  final SecureStorage _storage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    final tenantId = await _storage.getTenantId();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    if (tenantId != null) {
      options.headers['X-Tenant-Id'] = tenantId;
    }
    options.headers['Content-Type'] = 'application/json';

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try refresh token
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry request
        handler.resolve(await _retry(err.requestOptions));
        return;
      }
      // Logout user
    }
    handler.next(err);
  }
}
```

---

## ERROR HANDLING

```dart
// Wrap API calls
Future<T> safeApiCall<T>(Future<T> Function() apiCall) async {
  try {
    return await apiCall();
  } on DioException catch (e) {
    throw _mapDioError(e);
  } catch (e) {
    throw AppException('An unexpected error occurred');
  }
}

AppException _mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
      return AppException('Connection timeout. Please try again.');
    case DioExceptionType.badResponse:
      final message = e.response?.data['message'] ?? 'Server error';
      return AppException(message);
    default:
      return AppException('Network error. Check your connection.');
  }
}
```

---

## INSTRUCTIONS FOR CLAUDE

When generating Flutter code, follow these guidelines:

1. **One file at a time**: Generate complete, working code for each file
2. **Include imports**: Always include all necessary imports
3. **Follow naming conventions**: Use snake_case for files, PascalCase for classes
4. **Add documentation**: Add brief doc comments for public methods
5. **Handle loading/error states**: Every data-fetching widget should handle loading, error, and empty states
6. **Use const constructors**: Where possible for performance
7. **Responsive design**: Use MediaQuery and LayoutBuilder for responsive layouts
8. **Accessibility**: Include semantics labels for important widgets
9. **Test coverage**: Generate widget tests for each screen

---

## GENERATION ORDER

Generate files in this order:

### Phase 1: Core Setup
1. `lib/core/constants/app_colors.dart`
2. `lib/core/constants/app_typography.dart`
3. `lib/core/constants/app_spacing.dart`
4. `lib/core/constants/api_endpoints.dart`
5. `lib/core/theme/app_theme.dart`
6. `lib/core/network/dio_client.dart`
7. `lib/core/network/api_interceptor.dart`
8. `lib/core/storage/secure_storage.dart`

### Phase 2: Shared Widgets
9. `lib/shared/widgets/app_button.dart`
10. `lib/shared/widgets/app_text_field.dart`
11. `lib/shared/widgets/app_card.dart`
12. `lib/shared/widgets/loading_indicator.dart`
13. `lib/shared/widgets/empty_state.dart`
14. `lib/shared/widgets/error_widget.dart`
15. `lib/shared/widgets/bottom_nav_bar.dart`

### Phase 3: Auth Feature
16. `lib/features/auth/data/models/`
17. `lib/features/auth/data/repositories/`
18. `lib/features/auth/providers/`
19. `lib/features/auth/presentation/screens/login_screen.dart`

### Phase 4: Dashboard
20. `lib/features/dashboard/` (all files)

### Phase 5: Repository Feature
21. `lib/features/repository/` (all files)

### Phase 6: Notes Feature
22. `lib/features/notes/` (all files)

### Phase 7: Mindmaps Feature
23. `lib/features/mindmaps/` (all files)

### Phase 8: Classes Feature
24. `lib/features/classes/` (all files)

### Phase 9: Release Feature
25. `lib/features/release/` (all files)

### Phase 10: Profile Feature
26. `lib/features/profile/` (all files)

### Phase 11: Navigation & App
27. `lib/router/app_router.dart`
28. `lib/app.dart`
29. `lib/main.dart`

---

## SAMPLE PROMPT TO START

```
Using the specifications above, generate the complete Flutter code for:

File: lib/core/constants/app_colors.dart

Requirements:
- Define all colors from the design system
- Use static const for all values
- Include MaterialColor swatches for primary/secondary
- Add documentation comments
```

---

## END OF PROMPT DOCUMENT
