import 'package:equatable/equatable.dart';

enum NoteStatus { draft, inReview, ready, released, archived }

class Note extends Equatable {
  final String id;
  final String title;
  final String? summary;
  final String contentMd;
  final String? contentGuidedJson;
  final List<String> tags;
  final NoteStatus status;
  final String tenantId;
  final String ownerId;
  final String? scopeType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.title,
    this.summary,
    required this.contentMd,
    this.contentGuidedJson,
    required this.tags,
    required this.status,
    required this.tenantId,
    required this.ownerId,
    this.scopeType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        summary: json['summary'],
        contentMd: json['contentMd'] ?? json['content'] ?? '',
        contentGuidedJson: json['contentGuidedJson'],
        tags: List<String>.from(json['tags'] ?? []),
        status: _parseStatus(json['status']),
        tenantId: json['tenantId'] ?? '',
        ownerId: json['ownerId'] ?? '',
        scopeType: json['scopeType'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'contentMd': contentMd,
        'contentGuidedJson': contentGuidedJson,
        'tags': tags,
        'status': _statusToString(status),
        'tenantId': tenantId,
        'ownerId': ownerId,
        'scopeType': scopeType,
      };

  static String _statusToString(NoteStatus status) {
    switch (status) {
      case NoteStatus.draft:
        return 'DRAFT';
      case NoteStatus.inReview:
        return 'IN_REVIEW';
      case NoteStatus.ready:
        return 'READY';
      case NoteStatus.released:
        return 'RELEASED';
      case NoteStatus.archived:
        return 'ARCHIVED';
    }
  }

  static NoteStatus _parseStatus(String? status) {
    print('DEBUG _parseStatus: parsing status=$status');
    switch (status?.toUpperCase()) {
      case 'IN_REVIEW':
        return NoteStatus.inReview;
      case 'READY':
        return NoteStatus.ready;
      case 'RELEASED':
        return NoteStatus.released;
      case 'ARCHIVED':
        return NoteStatus.archived;
      default:
        return NoteStatus.draft;
    }
  }

  Note copyWith({
    String? id,
    String? title,
    String? summary,
    String? contentMd,
    String? contentGuidedJson,
    List<String>? tags,
    NoteStatus? status,
    String? tenantId,
    String? ownerId,
    String? scopeType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      contentMd: contentMd ?? this.contentMd,
      contentGuidedJson: contentGuidedJson ?? this.contentGuidedJson,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      tenantId: tenantId ?? this.tenantId,
      ownerId: ownerId ?? this.ownerId,
      scopeType: scopeType ?? this.scopeType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        summary,
        contentMd,
        contentGuidedJson,
        tags,
        status,
        tenantId,
        ownerId,
        scopeType,
        createdAt,
        updatedAt,
      ];
}

class NoteImageResponse {
  final String id;
  final String noteId;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final String imageUrl;
  final String? createdBy;
  final DateTime? createdAt;

  NoteImageResponse({
    required this.id,
    required this.noteId,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.imageUrl,
    this.createdBy,
    this.createdAt,
  });

  factory NoteImageResponse.fromJson(Map<String, dynamic> json) =>
      NoteImageResponse(
        id: json['id'] ?? '',
        noteId: json['noteId'] ?? '',
        fileName: json['fileName'] ?? '',
        contentType: json['contentType'] ?? '',
        sizeBytes: json['sizeBytes'] ?? 0,
        imageUrl: json['imageUrl'] ?? '',
        createdBy: json['createdBy'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
      );
}

class CreateNoteRequest {
  final String title;
  final String? summary;
  final String contentMd;
  final List<String> tags;
  final String scopeType;
  final String tenantId;
  final String createdBy;
  final String? changeSummary;

  CreateNoteRequest({
    required this.title,
    this.summary,
    required this.contentMd,
    required this.tags,
    this.scopeType = 'TENANT',  // Match the list filter
    required this.tenantId,
    required this.createdBy,
    this.changeSummary,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'tenantId': tenantId,
      'title': title,
      'summary': summary,
      'contentMd': contentMd,
      'tags': tags,
      'scopeType': scopeType,
      'createdBy': createdBy,
      'changeSummary': changeSummary,
    };
    map.removeWhere((_, value) => value == null);
    return map;
  }
}
