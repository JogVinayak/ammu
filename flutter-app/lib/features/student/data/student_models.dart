import 'package:equatable/equatable.dart';

class StudentProfile extends Equatable {
  final String id;
  final String userId;
  final String tenantId;
  final String? grade;
  final String? section;
  final String? rollNumber;
  final String? classId;
  final String? className;
  final String? board;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentProfile({
    required this.id,
    required this.userId,
    required this.tenantId,
    this.grade,
    this.section,
    this.rollNumber,
    this.classId,
    this.className,
    this.board,
    this.createdAt,
    this.updatedAt,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      tenantId: json['tenantId'] ?? '',
      grade: json['grade'],
      section: json['section'],
      rollNumber: json['rollNumber'],
      classId: json['classId'],
      className: json['className'],
      board: json['board'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  @override
  List<Object?> get props => [id, userId, tenantId, grade, section, rollNumber, classId];
}

class ReleasedContentItem extends Equatable {
  final String id;
  final String contentId;
  final String contentType; // 'note' or 'mindmap'
  final String classId;
  final String? releasedBy;
  final DateTime releasedAt;

  // Populated after fetching actual content
  final String? title;
  final String? summary;

  const ReleasedContentItem({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.classId,
    this.releasedBy,
    required this.releasedAt,
    this.title,
    this.summary,
  });

  factory ReleasedContentItem.fromJson(Map<String, dynamic> json) {
    return ReleasedContentItem(
      id: json['id'] ?? '',
      contentId: json['contentId'] ?? '',
      contentType: json['contentType'] ?? 'note',
      classId: json['classId'] ?? '',
      releasedBy: json['releasedBy'],
      releasedAt: json['releasedAt'] != null
          ? DateTime.parse(json['releasedAt'])
          : DateTime.now(),
      title: json['title'],
      summary: json['summary'],
    );
  }

  ReleasedContentItem copyWith({
    String? title,
    String? summary,
  }) {
    return ReleasedContentItem(
      id: id,
      contentId: contentId,
      contentType: contentType,
      classId: classId,
      releasedBy: releasedBy,
      releasedAt: releasedAt,
      title: title ?? this.title,
      summary: summary ?? this.summary,
    );
  }

  @override
  List<Object?> get props => [id, contentId, contentType, classId, releasedAt];
}

class StudentDashboardStats {
  final int notesCount;
  final int mindmapsCount;
  final String? className;
  final String? grade;
  final String? section;

  const StudentDashboardStats({
    this.notesCount = 0,
    this.mindmapsCount = 0,
    this.className,
    this.grade,
    this.section,
  });
}
