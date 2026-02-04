import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notes/providers/notes_provider.dart';
import '../../notes/data/note_models.dart';
import '../../mindmaps/providers/mindmaps_provider.dart';
import '../../classes/providers/classes_provider.dart';

class DashboardStats {
  final int myNotes;
  final int myMindmaps;
  final int classes;
  final int released;

  const DashboardStats({
    this.myNotes = 0,
    this.myMindmaps = 0,
    this.classes = 0,
    this.released = 0,
  });

  DashboardStats copyWith({
    int? myNotes,
    int? myMindmaps,
    int? classes,
    int? released,
  }) {
    return DashboardStats(
      myNotes: myNotes ?? this.myNotes,
      myMindmaps: myMindmaps ?? this.myMindmaps,
      classes: classes ?? this.classes,
      released: released ?? this.released,
    );
  }
}

class RecentContent {
  final String id;
  final String title;
  final String type;
  final String status;
  final DateTime updatedAt;

  const RecentContent({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.updatedAt,
  });
}

// Dashboard stats provider - aggregates data from other providers
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final notesState = ref.watch(notesProvider);
  final mindmapsState = ref.watch(mindmapsProvider);
  final classesState = ref.watch(classesProvider);

  final releasedNotes = notesState.notes
      .where((n) => n.status == NoteStatus.released)
      .length;

  return DashboardStats(
    myNotes: notesState.notes.length,
    myMindmaps: mindmapsState.mindmaps.length,
    classes: classesState.classes.length,
    released: releasedNotes,
  );
});

// Recent content provider - combines notes and mindmaps sorted by updated date
final recentContentProvider = Provider<List<RecentContent>>((ref) {
  final notesState = ref.watch(notesProvider);
  final mindmapsState = ref.watch(mindmapsProvider);

  final List<RecentContent> allContent = [];

  // Add notes
  for (final note in notesState.notes) {
    allContent.add(RecentContent(
      id: note.id,
      title: note.title,
      type: 'note',
      status: note.status.name.toUpperCase(),
      updatedAt: note.updatedAt,
    ));
  }

  // Add mindmaps
  for (final mindmap in mindmapsState.mindmaps) {
    allContent.add(RecentContent(
      id: mindmap.id,
      title: mindmap.title,
      type: 'mindmap',
      status: 'DRAFT', // Mindmaps don't have status in current model
      updatedAt: mindmap.updatedAt,
    ));
  }

  // Sort by updated date (newest first)
  allContent.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  // Return top 5 recent items
  return allContent.take(5).toList();
});

// Dashboard loading state
final dashboardLoadingProvider = Provider<bool>((ref) {
  final notesState = ref.watch(notesProvider);
  final mindmapsState = ref.watch(mindmapsProvider);
  final classesState = ref.watch(classesProvider);

  return notesState.isLoading ||
         mindmapsState.isLoading ||
         classesState.isLoading;
});

// Dashboard error provider
final dashboardErrorProvider = Provider<String?>((ref) {
  final notesState = ref.watch(notesProvider);
  final mindmapsState = ref.watch(mindmapsProvider);
  final classesState = ref.watch(classesProvider);

  return notesState.error ?? mindmapsState.error ?? classesState.error;
});

// Refresh all dashboard data
final dashboardRefreshProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await Future.wait([
      ref.read(notesProvider.notifier).refresh(),
      ref.read(mindmapsProvider.notifier).refresh(),
      ref.read(classesProvider.notifier).refresh(),
    ]);
  };
});

final userNameProvider = Provider<String>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user?.name ?? 'Teacher';
});
