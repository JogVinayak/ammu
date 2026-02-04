import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/repository/screens/repository_screen.dart';
import '../features/repository/screens/content_preview_screen.dart';
import '../features/notes/screens/notes_list_screen.dart';
import '../features/notes/screens/note_editor_screen.dart';
import '../features/notes/screens/note_viewer_screen.dart';
import '../features/mindmaps/screens/mindmaps_list_screen.dart';
import '../features/mindmaps/screens/mindmap_editor_screen.dart';
import '../features/mindmaps/screens/mindmap_viewer_screen.dart';
import '../features/classes/screens/classes_list_screen.dart';
import '../features/classes/screens/class_detail_screen.dart';
import '../features/release/screens/release_content_screen.dart';
import '../features/release/screens/release_history_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/student/screens/screens.dart';
import 'main_shell.dart';
import 'student_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _studentShellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final user = ref.watch(currentUserProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/forgot-password';
      final isStudentRoute = state.matchedLocation.startsWith('/student');
      final isTeacherRoute = !isStudentRoute &&
          !isLoggingIn &&
          state.matchedLocation != '/settings';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        // Redirect based on user type
        if (user?.isStudent == true) {
          return '/student/home';
        }
        return '/dashboard';
      }

      // If student tries to access teacher routes, redirect to student home
      if (isLoggedIn && user?.isStudent == true && isTeacherRoute) {
        return '/student/home';
      }

      // If teacher tries to access student routes, redirect to teacher dashboard
      if (isLoggedIn && user?.isTeacher == true && isStudentRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          // Repository
          GoRoute(
            path: '/repository',
            builder: (context, state) => const RepositoryScreen(),
          ),
          // Content tab (Notes and Mindmaps)
          GoRoute(
            path: '/content',
            builder: (context, state) {
              final tab = state.uri.queryParameters['tab'];
              return ContentScreen(initialTab: tab);
            },
          ),
          // Classes
          GoRoute(
            path: '/classes',
            builder: (context, state) => const ClassesListScreen(),
          ),
          // Profile
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Student shell with bottom navigation
      ShellRoute(
        navigatorKey: _studentShellNavigatorKey,
        builder: (context, state, child) => StudentShell(child: child),
        routes: [
          GoRoute(
            path: '/student/home',
            builder: (context, state) => const StudentDashboardScreen(),
          ),
          GoRoute(
            path: '/student/notes',
            builder: (context, state) => const StudentNotesScreen(),
          ),
          GoRoute(
            path: '/student/mindmaps',
            builder: (context, state) => const StudentMindmapsScreen(),
          ),
          GoRoute(
            path: '/student/class',
            builder: (context, state) => const StudentClassScreen(),
          ),
          GoRoute(
            path: '/student/profile',
            builder: (context, state) => const StudentProfileScreen(),
          ),
        ],
      ),

      // Student full-screen routes (outside shell)
      GoRoute(
        path: '/student/notes/:id',
        builder: (context, state) => StudentNoteViewerScreen(
          noteId: state.pathParameters['id']!,
        ),
      ),

      // Full-screen routes (outside shell)
      GoRoute(
        path: '/repository/:id',
        builder: (context, state) => ContentPreviewScreen(
          contentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/notes/create',
        builder: (context, state) => const NoteEditorScreen(),
      ),
      GoRoute(
        path: '/notes/:id',
        builder: (context, state) => NoteViewerScreen(
          noteId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/notes/:id/edit',
        builder: (context, state) => NoteEditorScreen(
          noteId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/mindmaps/create',
        builder: (context, state) => const MindmapEditorScreen(),
      ),
      GoRoute(
        path: '/mindmaps/:id',
        builder: (context, state) => MindmapViewerScreen(
          mindmapId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/mindmaps/:id/edit',
        builder: (context, state) => MindmapEditorScreen(
          mindmapId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/classes/:id',
        builder: (context, state) => ClassDetailScreen(
          classId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/release',
        builder: (context, state) => ReleaseContentScreen(
          contentId: state.uri.queryParameters['contentId'],
          contentType: state.uri.queryParameters['contentType'],
          classId: state.uri.queryParameters['classId'],
        ),
      ),
      GoRoute(
        path: '/release-history',
        builder: (context, state) => const ReleaseHistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

// Content screen with tabs for Notes and Mindmaps
class ContentScreen extends StatefulWidget {
  final String? initialTab;

  const ContentScreen({super.key, this.initialTab});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialTab == 'mindmaps') {
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Content'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Notes'),
            Tab(text: 'Mindmaps'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          NotesListScreen(),
          MindmapsListScreen(),
        ],
      ),
    );
  }
}
