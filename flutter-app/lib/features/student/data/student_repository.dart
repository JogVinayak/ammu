import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../notes/data/note_models.dart';
import 'student_models.dart';

class StudentRepository {
  final DioClient _dioClient;

  StudentRepository(this._dioClient);

  /// Get student profile with class info
  Future<StudentProfile?> getStudentProfile(String tenantId, String userId) async {
    try {
      final response = await _dioClient.get(
        '/v1/tenants/$tenantId/users/$userId/student-profile',
      );
      return StudentProfile.fromJson(response.data);
    } on DioException catch (e) {
      // If endpoint doesn't exist yet, return null
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleError(e);
    }
  }

  /// Get released content for a specific class
  Future<List<ReleasedContentItem>> getReleasedContent({
    required String classId,
    String? contentType, // 'note' or 'mindmap'
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'classId': classId,
      };
      if (contentType != null) {
        queryParams['contentType'] = contentType;
      }

      final response = await _dioClient.get(
        '/v1/workflow/released',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map && data['items'] != null) {
        return (data['items'] as List)
            .map((json) => ReleasedContentItem.fromJson(json))
            .toList();
      } else if (data is List) {
        return data.map((json) => ReleasedContentItem.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      // If endpoint doesn't exist yet, return empty list
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw _handleError(e);
    }
  }

  /// Get released notes for student's class
  Future<List<Note>> getReleasedNotes(String classId) async {
    try {
      // First get released content items
      final releasedItems = await getReleasedContent(
        classId: classId,
        contentType: 'note',
      );

      // Then fetch actual note details for each
      final notes = <Note>[];
      for (final item in releasedItems) {
        try {
          final noteResponse = await _dioClient.get(
            '${ApiConstants.notes}/${item.contentId}',
          );
          final noteData = Map<String, dynamic>.from(noteResponse.data);

          // Get content from latest version
          final latestVersionId = noteData['latestVersionId'];
          if (latestVersionId != null) {
            try {
              final versionResponse = await _dioClient.get(
                '${ApiConstants.notes}/${item.contentId}/versions/$latestVersionId',
              );
              noteData['contentMd'] = versionResponse.data['contentMd'] ?? '';
              noteData['contentGuidedJson'] = versionResponse.data['contentGuidedJson'];
            } catch (_) {
              noteData['contentMd'] = '';
            }
          }

          notes.add(Note.fromJson(noteData));
        } catch (_) {
          // Skip notes that can't be fetched
        }
      }
      return notes;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get single note by ID (for viewing)
  Future<Note> getNoteById(String id) async {
    try {
      final noteResponse = await _dioClient.get('${ApiConstants.notes}/$id');
      final noteData = Map<String, dynamic>.from(noteResponse.data);

      final latestVersionId = noteData['latestVersionId'];
      if (latestVersionId != null) {
        try {
          final versionResponse = await _dioClient.get(
            '${ApiConstants.notes}/$id/versions/$latestVersionId',
          );
          noteData['contentMd'] = versionResponse.data['contentMd'] ?? '';
          noteData['contentGuidedJson'] = versionResponse.data['contentGuidedJson'];
        } catch (_) {
          noteData['contentMd'] = '';
        }
      } else {
        noteData['contentMd'] = '';
      }

      return Note.fromJson(noteData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get class details
  Future<Map<String, dynamic>?> getClassDetails(String classId) async {
    try {
      final response = await _dioClient.get('${ApiConstants.classes}/$classId');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleError(e);
    }
  }

  /// Get classmates (students in same class)
  Future<List<Map<String, dynamic>>> getClassmates(String classId) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.classes}/$classId/students',
      );
      final data = response.data;
      if (data is Map && data['items'] != null) {
        return List<Map<String, dynamic>>.from(data['items']);
      } else if (data is List) {
        return List<Map<String, dynamic>>.from(data);
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
      switch (e.response!.statusCode) {
        case 400:
          return 'Invalid request';
        case 401:
          return 'Unauthorized';
        case 403:
          return 'Access denied';
        case 404:
          return 'Not found';
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

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final dioClient = ref.watch(notesDioClientProvider);
  return StudentRepository(dioClient);
});
