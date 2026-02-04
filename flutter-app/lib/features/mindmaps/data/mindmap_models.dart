import 'package:equatable/equatable.dart';

class MindmapNode extends Equatable {
  final String id;
  final String label;
  final String? noteId;
  final List<String> childIds;
  final double x;
  final double y;

  const MindmapNode({
    required this.id,
    required this.label,
    this.noteId,
    this.childIds = const [],
    this.x = 0,
    this.y = 0,
  });

  factory MindmapNode.fromJson(Map<String, dynamic> json) => MindmapNode(
        id: json['id'] ?? '',
        label: json['label'] ?? '',
        noteId: json['noteId'],
        childIds: List<String>.from(json['childIds'] ?? []),
        x: (json['x'] ?? 0).toDouble(),
        y: (json['y'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'noteId': noteId,
        'childIds': childIds,
        'x': x,
        'y': y,
      };

  MindmapNode copyWith({
    String? id,
    String? label,
    String? noteId,
    List<String>? childIds,
    double? x,
    double? y,
  }) {
    return MindmapNode(
      id: id ?? this.id,
      label: label ?? this.label,
      noteId: noteId ?? this.noteId,
      childIds: childIds ?? this.childIds,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  @override
  List<Object?> get props => [id, label, noteId, childIds, x, y];
}

class Mindmap extends Equatable {
  final String id;
  final String title;
  final String? description;
  final List<MindmapNode> nodes;
  final String tenantId;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Mindmap({
    required this.id,
    required this.title,
    this.description,
    this.nodes = const [],
    required this.tenantId,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Mindmap.fromJson(Map<String, dynamic> json) => Mindmap(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        nodes: (json['nodes'] as List?)
                ?.map((n) => MindmapNode.fromJson(n))
                .toList() ??
            [],
        tenantId: json['tenantId'] ?? '',
        ownerId: json['ownerId'] ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
      );

  int get nodeCount => nodes.length;

  @override
  List<Object?> get props =>
      [id, title, description, nodes, tenantId, ownerId, createdAt, updatedAt];
}
