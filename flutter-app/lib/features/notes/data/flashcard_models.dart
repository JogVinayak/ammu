import 'package:equatable/equatable.dart';

class Flashcard extends Equatable {
  final String id;
  final String noteId;
  final String frontText;
  final String backText;
  final String difficulty;
  final int position;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Flashcard({
    required this.id,
    required this.noteId,
    required this.frontText,
    required this.backText,
    this.difficulty = 'MEDIUM',
    required this.position,
    this.createdAt,
    this.updatedAt,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        id: json['id'] ?? '',
        noteId: json['noteId'] ?? '',
        frontText: json['frontText'] ?? '',
        backText: json['backText'] ?? '',
        difficulty: json['difficulty'] ?? 'MEDIUM',
        position: json['position'] ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'noteId': noteId,
        'frontText': frontText,
        'backText': backText,
        'difficulty': difficulty,
        'position': position,
      };

  Flashcard copyWith({
    String? id,
    String? noteId,
    String? frontText,
    String? backText,
    String? difficulty,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      frontText: frontText ?? this.frontText,
      backText: backText ?? this.backText,
      difficulty: difficulty ?? this.difficulty,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, noteId, frontText, backText, difficulty, position];
}

class CreateFlashcardRequest {
  final String frontText;
  final String backText;
  final String difficulty;
  final int? position;
  final String? createdBy;

  CreateFlashcardRequest({
    required this.frontText,
    required this.backText,
    this.difficulty = 'MEDIUM',
    this.position,
    this.createdBy,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'frontText': frontText,
      'backText': backText,
      'difficulty': difficulty,
    };
    if (position != null) map['position'] = position;
    if (createdBy != null) map['createdBy'] = createdBy;
    return map;
  }
}

class UpdateFlashcardRequest {
  final String? frontText;
  final String? backText;
  final String? difficulty;
  final int? position;

  UpdateFlashcardRequest({
    this.frontText,
    this.backText,
    this.difficulty,
    this.position,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (frontText != null) map['frontText'] = frontText;
    if (backText != null) map['backText'] = backText;
    if (difficulty != null) map['difficulty'] = difficulty;
    if (position != null) map['position'] = position;
    return map;
  }
}

class BatchFlashcardsRequest {
  final List<FlashcardItem> flashcards;
  final String? createdBy;
  final bool replaceAll;

  BatchFlashcardsRequest({
    required this.flashcards,
    this.createdBy,
    this.replaceAll = false,
  });

  Map<String, dynamic> toJson() => {
        'flashcards': flashcards.map((f) => f.toJson()).toList(),
        if (createdBy != null) 'createdBy': createdBy,
        'replaceAll': replaceAll,
      };
}

class FlashcardItem {
  final String? id;
  final String frontText;
  final String backText;
  final String difficulty;
  final int? position;

  FlashcardItem({
    this.id,
    required this.frontText,
    required this.backText,
    this.difficulty = 'MEDIUM',
    this.position,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'frontText': frontText,
      'backText': backText,
      'difficulty': difficulty,
    };
    if (id != null) map['id'] = id;
    if (position != null) map['position'] = position;
    return map;
  }
}
