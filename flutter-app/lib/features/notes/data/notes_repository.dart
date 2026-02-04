import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'note_models.dart';

class NotesRepository {
  final DioClient _dioClient;

  NotesRepository(this._dioClient);

  Future<List<Note>> getNotes({
    String? status,
    String? createdBy,  // Pass user ID to get all notes by this user
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (status != null) {
        queryParams['status'] = status;
      }
      if (createdBy != null) {
        queryParams['createdBy'] = createdBy;
      }

      print('DEBUG: getNotes called with createdBy: $createdBy');
      print('DEBUG: queryParams: $queryParams');

      final response = await _dioClient.get(
        ApiConstants.notes,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map && data['items'] != null) {
        return (data['items'] as List)
            .map((json) => Note.fromJson(json))
            .toList();
      } else if (data is List) {
        return data.map((json) => Note.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Note> getNoteById(String id) async {
    try {
      // Get note metadata
      final noteResponse = await _dioClient.get('${ApiConstants.notes}/$id');
      final noteData = Map<String, dynamic>.from(noteResponse.data);

      // Get the latest version to get the content
      final latestVersionId = noteData['latestVersionId'];
      if (latestVersionId != null) {
        try {
          final versionResponse = await _dioClient.get(
            '${ApiConstants.notes}/$id/versions/$latestVersionId',
          );
          // Merge content from version into note data
          noteData['contentMd'] = versionResponse.data['contentMd'] ?? '';
        } catch (_) {
          // If version fetch fails, use empty content
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

  Future<Note> createNote(CreateNoteRequest request) async {
    try {
      final payload = request.toJson();
      print('DEBUG: Creating note with payload: $payload');

      final response = await _dioClient.post(
        ApiConstants.notes,
        data: payload,
      );
      print('DEBUG: Note created successfully: ${response.data}');
      return Note.fromJson(response.data);
    } on DioException catch (e) {
      print('DEBUG: Note creation failed: ${e.response?.statusCode} - ${e.response?.data}');
      throw _handleError(e);
    }
  }

  Future<Note> updateNote(String id, Map<String, dynamic> data) async {
    try {
      // Extract contentMd if present - it needs to go to a version, not the note
      final contentMd = data.remove('contentMd');
      final userId = data['updatedBy'];

      // Update note metadata
      final response = await _dioClient.patch(
        '${ApiConstants.notes}/$id',
        data: data,
      );

      // If content was changed, create a new version
      if (contentMd != null && contentMd.toString().isNotEmpty) {
        await createNoteVersion(id, contentMd, userId);
      }

      return Note.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> createNoteVersion(String noteId, String contentMd, String? createdBy) async {
    try {
      await _dioClient.post(
        '${ApiConstants.notes}/$noteId/versions',
        data: {
          'contentMd': contentMd,
          'createdBy': createdBy,
          'changeSummary': 'Updated content',
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _dioClient.delete('${ApiConstants.notes}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> publishNote(String id) async {
    try {
      await _dioClient.patch(
        '${ApiConstants.notes}/$id/publish',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> releaseNote(String id) async {
    try {
      await _dioClient.patch(
        '${ApiConstants.notes}/$id/release',
      );
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
          return 'Note not found';
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

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final dioClient = ref.watch(notesDioClientProvider);
  return NotesRepository(dioClient);
});
