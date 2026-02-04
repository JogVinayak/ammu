import 'package:equatable/equatable.dart';

class TeacherClass extends Equatable {
  final String id;
  final String name;
  final String subject;
  final String grade;
  final int studentCount;
  final List<Student> students;
  final List<ReleasedContent> releasedContent;

  const TeacherClass({
    required this.id,
    required this.name,
    required this.subject,
    required this.grade,
    this.studentCount = 0,
    this.students = const [],
    this.releasedContent = const [],
  });

  factory TeacherClass.fromJson(Map<String, dynamic> json) => TeacherClass(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        subject: json['subject'] ?? '',
        grade: json['grade'] ?? '',
        studentCount: json['studentCount'] ?? 0,
        students: (json['students'] as List?)
                ?.map((s) => Student.fromJson(s))
                .toList() ??
            [],
        releasedContent: (json['releasedContent'] as List?)
                ?.map((c) => ReleasedContent.fromJson(c))
                .toList() ??
            [],
      );

  @override
  List<Object?> get props =>
      [id, name, subject, grade, studentCount, students, releasedContent];
}

class Student extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? avatar;

  const Student({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'],
        avatar: json['avatar'],
      );

  @override
  List<Object?> get props => [id, name, email, avatar];
}

class ReleasedContent extends Equatable {
  final String id;
  final String title;
  final String type;
  final DateTime releasedAt;

  const ReleasedContent({
    required this.id,
    required this.title,
    required this.type,
    required this.releasedAt,
  });

  factory ReleasedContent.fromJson(Map<String, dynamic> json) => ReleasedContent(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        type: json['type'] ?? 'note',
        releasedAt: json['releasedAt'] != null
            ? DateTime.parse(json['releasedAt'])
            : DateTime.now(),
      );

  @override
  List<Object?> get props => [id, title, type, releasedAt];
}
