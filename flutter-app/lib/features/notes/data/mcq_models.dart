import 'dart:convert';
import 'package:equatable/equatable.dart';

enum McqDifficulty { LOW, MEDIUM, HIGH }

class McqOption {
  final String text;
  final bool isCorrect;

  const McqOption({
    required this.text,
    required this.isCorrect,
  });

  factory McqOption.fromJson(Map<String, dynamic> json) => McqOption(
        text: json['text'] ?? '',
        isCorrect: json['isCorrect'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'isCorrect': isCorrect,
      };
}

class Mcq extends Equatable {
  final String id;
  final String noteId;
  final String questionText;
  final List<McqOption> options;
  final String difficulty;
  final String? explanation;
  final int position;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Mcq({
    required this.id,
    required this.noteId,
    required this.questionText,
    required this.options,
    required this.difficulty,
    this.explanation,
    required this.position,
    this.createdAt,
    this.updatedAt,
  });

  factory Mcq.fromJson(Map<String, dynamic> json) {
    List<McqOption> options = [];
    if (json['optionsJson'] != null) {
      try {
        final optionsList = jsonDecode(json['optionsJson']) as List;
        options = optionsList
            .map((o) => McqOption.fromJson(o as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return Mcq(
      id: json['id'] ?? '',
      noteId: json['noteId'] ?? '',
      questionText: json['questionText'] ?? '',
      options: options,
      difficulty: json['difficulty'] ?? 'MEDIUM',
      explanation: json['explanation'],
      position: json['position'] ?? 0,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'noteId': noteId,
        'questionText': questionText,
        'optionsJson': jsonEncode(options.map((o) => o.toJson()).toList()),
        'difficulty': difficulty,
        'explanation': explanation,
        'position': position,
      };

  int? get correctIndex {
    for (int i = 0; i < options.length; i++) {
      if (options[i].isCorrect) return i;
    }
    return null;
  }

  Mcq copyWith({
    String? id,
    String? noteId,
    String? questionText,
    List<McqOption>? options,
    String? difficulty,
    String? explanation,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Mcq(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      difficulty: difficulty ?? this.difficulty,
      explanation: explanation ?? this.explanation,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, noteId, questionText, options, difficulty, position];
}

class CreateMcqRequest {
  final String questionText;
  final List<McqOption> options;
  final String difficulty;
  final String? explanation;
  final int? position;
  final String? createdBy;

  CreateMcqRequest({
    required this.questionText,
    required this.options,
    this.difficulty = 'MEDIUM',
    this.explanation,
    this.position,
    this.createdBy,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'questionText': questionText,
      'optionsJson': jsonEncode(options.map((o) => o.toJson()).toList()),
      'difficulty': difficulty,
    };
    if (explanation != null) map['explanation'] = explanation;
    if (position != null) map['position'] = position;
    if (createdBy != null) map['createdBy'] = createdBy;
    return map;
  }
}

class UpdateMcqRequest {
  final String? questionText;
  final List<McqOption>? options;
  final String? difficulty;
  final String? explanation;
  final int? position;

  UpdateMcqRequest({
    this.questionText,
    this.options,
    this.difficulty,
    this.explanation,
    this.position,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (questionText != null) map['questionText'] = questionText;
    if (options != null) {
      map['optionsJson'] = jsonEncode(options!.map((o) => o.toJson()).toList());
    }
    if (difficulty != null) map['difficulty'] = difficulty;
    if (explanation != null) map['explanation'] = explanation;
    if (position != null) map['position'] = position;
    return map;
  }
}

class BatchMcqsRequest {
  final List<McqItem> mcqs;
  final String? createdBy;
  final bool replaceAll;

  BatchMcqsRequest({
    required this.mcqs,
    this.createdBy,
    this.replaceAll = false,
  });

  Map<String, dynamic> toJson() => {
        'mcqs': mcqs.map((m) => m.toJson()).toList(),
        if (createdBy != null) 'createdBy': createdBy,
        'replaceAll': replaceAll,
      };
}

class McqItem {
  final String? id;
  final String questionText;
  final List<McqOption> options;
  final String difficulty;
  final String? explanation;
  final int? position;

  McqItem({
    this.id,
    required this.questionText,
    required this.options,
    this.difficulty = 'MEDIUM',
    this.explanation,
    this.position,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'questionText': questionText,
      'optionsJson': jsonEncode(options.map((o) => o.toJson()).toList()),
      'difficulty': difficulty,
    };
    if (id != null) map['id'] = id;
    if (explanation != null) map['explanation'] = explanation;
    if (position != null) map['position'] = position;
    return map;
  }
}
