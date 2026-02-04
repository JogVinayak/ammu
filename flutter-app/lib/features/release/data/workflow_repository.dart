import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class ReleaseRequest {
  final List<String> contentIds;
  final List<String> classIds;
  final String contentType;

  ReleaseRequest({
    required this.contentIds,
    required this.classIds,
    required this.contentType,
  });

  Map<String, dynamic> toJson() => {
        'contentIds': contentIds,
        'classIds': classIds,
        'contentType': contentType,
      };
}

class ReleaseHistoryItem {
  final String id;
  final String contentId;
  final String contentTitle;
  final String contentType;
  final String classId;
  final String className;
  final DateTime releasedAt;

  ReleaseHistoryItem({
    required this.id,
    required this.contentId,
    required this.contentTitle,
    required this.contentType,
    required this.classId,
    required this.className,
    required this.releasedAt,
  });

  factory ReleaseHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReleaseHistoryItem(
      id: json['id'] ?? '',
      contentId: json['contentId'] ?? '',
      contentTitle: json['contentTitle'] ?? json['title'] ?? '',
      contentType: json['contentType'] ?? json['type'] ?? 'note',
      classId: json['classId'] ?? '',
      className: json['className'] ?? json['class']?['name'] ?? '',
      releasedAt: json['releasedAt'] != null
          ? DateTime.parse(json['releasedAt'])
          : DateTime.now(),
    );
  }
}

class WorkflowRepository {
  final DioClient _dioClient;

  WorkflowRepository(this._dioClient);

  Future<void> releaseContent(ReleaseRequest request) async {
    try {
      await _dioClient.post(
        ApiConstants.release,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ReleaseHistoryItem>> getReleaseHistory({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.workflow}/history',
        queryParameters: {'page': page, 'size': size},
      );

      final data = response.data;
      if (data is Map && data['items'] != null) {
        return (data['items'] as List)
            .map((json) => ReleaseHistoryItem.fromJson(json))
            .toList();
      } else if (data is List) {
        return data.map((json) => ReleaseHistoryItem.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        return data['message'];
      }
      return 'Server error: ${e.response!.statusCode}';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server';
    }
    return 'Network error';
  }
}

final workflowRepositoryProvider = Provider<WorkflowRepository>((ref) {
  final dioClient = ref.watch(workflowDioClientProvider);
  return WorkflowRepository(dioClient);
});
