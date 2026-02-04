import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'mindmap_models.dart';

class MindmapsRepository {
  final DioClient _dioClient;

  MindmapsRepository(this._dioClient);

  Future<List<Mindmap>> getMindmaps({int page = 0, int size = 20}) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.mindmaps,
        queryParameters: {'page': page, 'size': size},
      );

      final data = response.data;
      if (data is Map && data['items'] != null) {
        return (data['items'] as List)
            .map((json) => Mindmap.fromJson(json))
            .toList();
      } else if (data is List) {
        return data.map((json) => Mindmap.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      // Return empty list if listing not supported (405) or server error
      if (e.response?.statusCode == 405 || e.response?.statusCode == 500) {
        return [];
      }
      throw _handleError(e);
    }
  }

  Future<Mindmap> getMindmapById(String id) async {
    try {
      final response = await _dioClient.get('${ApiConstants.mindmaps}/$id');
      return Mindmap.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Mindmap> createMindmap(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.mindmaps,
        data: data,
      );
      return Mindmap.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Mindmap> updateMindmap(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.put(
        '${ApiConstants.mindmaps}/$id',
        data: data,
      );
      return Mindmap.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteMindmap(String id) async {
    try {
      await _dioClient.delete('${ApiConstants.mindmaps}/$id');
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
      switch (e.response!.statusCode) {
        case 400:
          return 'Invalid request';
        case 401:
          return 'Unauthorized';
        case 403:
          return 'Access denied';
        case 404:
          return 'Mindmap not found';
        case 500:
          return 'Server error';
        default:
          return 'Something went wrong';
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server';
    }
    return 'Network error';
  }
}

final mindmapsRepositoryProvider = Provider<MindmapsRepository>((ref) {
  final dioClient = ref.watch(mindmapDioClientProvider);
  return MindmapsRepository(dioClient);
});
