import 'package:equatable/equatable.dart';

class RepositoryItem extends Equatable {
  final String id;
  final String title;
  final String? summary;
  final String type; // 'note' or 'mindmap'
  final List<String> tags;
  final String authorName;
  final String authorId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RepositoryItem({
    required this.id,
    required this.title,
    this.summary,
    required this.type,
    required this.tags,
    required this.authorName,
    required this.authorId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RepositoryItem.fromJson(Map<String, dynamic> json) => RepositoryItem(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        summary: json['summary'],
        type: json['type'] ?? 'note',
        tags: List<String>.from(json['tags'] ?? []),
        authorName: json['authorName'] ?? json['author']?['name'] ?? 'Unknown',
        authorId: json['authorId'] ?? json['ownerId'] ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
      );

  @override
  List<Object?> get props =>
      [id, title, summary, type, tags, authorName, authorId, createdAt, updatedAt];
}

class RepositoryFilter {
  final String? subject;
  final String? grade;
  final String? type;
  final String? searchQuery;

  const RepositoryFilter({
    this.subject,
    this.grade,
    this.type,
    this.searchQuery,
  });

  RepositoryFilter copyWith({
    String? subject,
    String? grade,
    String? type,
    String? searchQuery,
  }) {
    return RepositoryFilter(
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      type: type ?? this.type,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasFilters =>
      subject != null || grade != null || type != null || searchQuery != null;

  void clear() {}
}
