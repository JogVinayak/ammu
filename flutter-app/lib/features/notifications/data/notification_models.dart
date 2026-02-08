import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? referenceId;
  final String? referenceType;
  final bool read;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.referenceId,
    this.referenceType,
    required this.read,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      type: json['type'] ?? 'SYSTEM_ANNOUNCEMENT',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      referenceId: json['referenceId'],
      referenceType: json['referenceType'],
      read: json['read'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  IconData get icon {
    switch (type) {
      case 'CONTENT_RELEASED':
        return Icons.article_outlined;
      case 'RECALL_REMINDER':
        return Icons.schedule;
      case 'ASSIGNMENT_DUE':
        return Icons.assignment_outlined;
      case 'SYSTEM_ANNOUNCEMENT':
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'CONTENT_RELEASED':
        return const Color(0xFF14B8A6); // Teal
      case 'RECALL_REMINDER':
        return const Color(0xFFF59E0B); // Amber
      case 'ASSIGNMENT_DUE':
        return const Color(0xFFEF4444); // Red
      case 'SYSTEM_ANNOUNCEMENT':
      default:
        return const Color(0xFF6366F1); // Indigo
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
