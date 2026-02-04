import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'repository_models.dart';

class RepositoryApi {
  final DioClient _notesDioClient;
  final DioClient _mindmapDioClient;
  final DioClient _workflowDioClient;

  RepositoryApi(this._notesDioClient, this._mindmapDioClient, this._workflowDioClient);

  Future<List<RepositoryItem>> getPublishedContent({
    String? type,
    String? searchQuery,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final List<RepositoryItem> items = [];

      // Fetch published content from workflow service
      if (type == null || type == 'all' || type == 'note') {
        try {
          // Get published workflows
          final workflowResponse = await _workflowDioClient.get(
            ApiConstants.workflow,
            queryParameters: {
              'state': 'PUBLISHED',
              'page': page,
              'size': size,
            },
          );

          final workflowData = workflowResponse.data;
          List workflowList = [];
          if (workflowData is Map && workflowData['content'] != null) {
            workflowList = workflowData['content'] as List;
          } else if (workflowData is Map && workflowData['items'] != null) {
            workflowList = workflowData['items'] as List;
          } else if (workflowData is List) {
            workflowList = workflowData;
          }

          // Fetch full note details for each published workflow
          for (final wf in workflowList) {
            final contentId = wf['contentId'];
            if (contentId != null) {
              try {
                final noteResponse = await _notesDioClient.get('${ApiConstants.notes}/$contentId');
                final note = noteResponse.data;
                items.add(RepositoryItem(
                  id: note['id'] ?? contentId,
                  title: note['title'] ?? wf['titleSnapshot'] ?? '',
                  summary: note['summary'],
                  type: 'note',
                  tags: List<String>.from(note['tags'] ?? []),
                  authorName: note['authorName'] ?? 'Unknown',
                  authorId: note['createdBy'] ?? '',
                  createdAt: note['createdAt'] != null
                      ? DateTime.parse(note['createdAt'])
                      : DateTime.now(),
                  updatedAt: note['updatedAt'] != null
                      ? DateTime.parse(note['updatedAt'])
                      : DateTime.now(),
                ));
              } catch (e) {
                // If can't fetch note, use workflow data
                items.add(RepositoryItem(
                  id: contentId,
                  title: wf['titleSnapshot'] ?? '',
                  summary: null,
                  type: 'note',
                  tags: [],
                  authorName: 'Unknown',
                  authorId: wf['createdBy'] ?? '',
                  createdAt: wf['createdAt'] != null
                      ? DateTime.parse(wf['createdAt'])
                      : DateTime.now(),
                  updatedAt: wf['lastUpdatedAt'] != null
                      ? DateTime.parse(wf['lastUpdatedAt'])
                      : DateTime.now(),
                ));
              }
            }
          }
        } catch (e) {
          // Workflow service error, continue
        }
      }

      // Fetch mindmaps if type is null or 'mindmap'
      if (type == null || type == 'all' || type == 'mindmap') {
        try {
          final mindmapsResponse = await _mindmapDioClient.get(
            ApiConstants.mindmaps,
            queryParameters: {
              'scopeType': 'TENANT',
              'page': page,
              'size': size,
            },
          );

          final mindmapsData = mindmapsResponse.data;
          List mindmapsList = [];
          if (mindmapsData is Map && mindmapsData['items'] != null) {
            mindmapsList = mindmapsData['items'] as List;
          } else if (mindmapsData is List) {
            mindmapsList = mindmapsData;
          }

          for (final mindmap in mindmapsList) {
            items.add(RepositoryItem(
              id: mindmap['id'] ?? '',
              title: mindmap['title'] ?? '',
              summary: mindmap['description'],
              type: 'mindmap',
              tags: List<String>.from(mindmap['tags'] ?? []),
              authorName: mindmap['authorName'] ?? mindmap['author']?['name'] ?? 'Unknown',
              authorId: mindmap['ownerId'] ?? '',
              createdAt: mindmap['createdAt'] != null
                  ? DateTime.parse(mindmap['createdAt'])
                  : DateTime.now(),
              updatedAt: mindmap['updatedAt'] != null
                  ? DateTime.parse(mindmap['updatedAt'])
                  : DateTime.now(),
            ));
          }
        } catch (e) {
          // Mindmap service might not be available, continue with notes only
        }
      }

      // Apply search filter on client side if needed
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return items.where((item) {
          return item.title.toLowerCase().contains(query) ||
              (item.summary?.toLowerCase().contains(query) ?? false) ||
              item.tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();
      }

      // Sort by updated date
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return items;
    } on DioException catch (e) {
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

final repositoryApiProvider = Provider<RepositoryApi>((ref) {
  final notesDioClient = ref.watch(notesDioClientProvider);
  final mindmapDioClient = ref.watch(mindmapDioClientProvider);
  final workflowDioClient = ref.watch(workflowDioClientProvider);
  return RepositoryApi(notesDioClient, mindmapDioClient, workflowDioClient);
});
