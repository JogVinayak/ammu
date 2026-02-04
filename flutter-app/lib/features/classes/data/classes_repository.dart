import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'class_models.dart';

class ClassesRepository {
  final DioClient _dioClient;

  ClassesRepository(this._dioClient);

  Future<List<TeacherClass>> getClasses() async {
    try {
      final response = await _dioClient.get(ApiConstants.classes);

      final data = response.data;
      if (data is Map && data['items'] != null) {
        return (data['items'] as List)
            .map((json) => TeacherClass.fromJson(json))
            .toList();
      } else if (data is List) {
        return data.map((json) => TeacherClass.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      // If classes endpoint doesn't exist or errors, return empty list
      if (e.response?.statusCode == 404 || e.response?.statusCode == 500) {
        return [];
      }
      throw _handleError(e);
    }
  }

  Future<TeacherClass?> getClassById(String id) async {
    try {
      final response = await _dioClient.get('${ApiConstants.classes}/$id');
      return TeacherClass.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ReleasedContent>> getReleasedContent(String classId) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.workflow}/class/$classId/content',
      );

      final data = response.data;
      if (data is Map && data['items'] != null) {
        return (data['items'] as List)
            .map((json) => ReleasedContent.fromJson(json))
            .toList();
      } else if (data is List) {
        return data.map((json) => ReleasedContent.fromJson(json)).toList();
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

final classesRepositoryProvider = Provider<ClassesRepository>((ref) {
  final dioClient = ref.watch(workflowDioClientProvider);
  return ClassesRepository(dioClient);
});
