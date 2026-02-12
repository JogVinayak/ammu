import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'flashcard_models.dart';
import 'mcq_models.dart';
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
      print('DEBUG getNotes: Raw response data type=${data.runtimeType}');
      if (data is Map && data['items'] != null) {
        final items = data['items'] as List;
        print('DEBUG getNotes: Found ${items.length} items');
        for (var item in items) {
          print('DEBUG getNotes: Note id=${item['id']}, status=${item['status']}, title=${item['title']}');
        }
        return items.map((json) => Note.fromJson(json)).toList();
      } else if (data is List) {
        print('DEBUG getNotes: Found ${data.length} items (list format)');
        return data.map((json) => Note.fromJson(json)).toList();
      }
      print('DEBUG getNotes: No items found');
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Note> getNoteById(String id) async {
    try {
      // Get note metadata
      print('DEBUG getNoteById: Fetching note $id');
      final noteResponse = await _dioClient.get('${ApiConstants.notes}/$id');
      final noteData = Map<String, dynamic>.from(noteResponse.data);

      // Get the latest version to get the content
      final latestVersionId = noteData['latestVersionId'];
      print('DEBUG getNoteById: latestVersionId=$latestVersionId');

      if (latestVersionId != null) {
        try {
          final versionResponse = await _dioClient.get(
            '${ApiConstants.notes}/$id/versions/$latestVersionId',
          );
          // Merge content from version into note data
          noteData['contentMd'] = versionResponse.data['contentMd'] ?? '';
          noteData['contentGuidedJson'] = versionResponse.data['contentGuidedJson'];
          print('DEBUG getNoteById: Loaded content length=${noteData['contentMd']?.length ?? 0}');
        } catch (e) {
          // If version fetch fails, use empty content
          print('DEBUG getNoteById: Failed to fetch version - $e');
          noteData['contentMd'] = '';
        }
      } else {
        print('DEBUG getNoteById: No latestVersionId, using empty content');
        noteData['contentMd'] = '';
      }

      return Note.fromJson(noteData);
    } on DioException catch (e) {
      print('DEBUG getNoteById: Error - ${e.response?.statusCode}: ${e.response?.data}');
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

      print('DEBUG updateNote: Updating note $id');

      // Update note metadata
      await _dioClient.patch(
        '${ApiConstants.notes}/$id',
        data: data,
      );

      // If content was changed, create a new version
      if (contentMd != null && contentMd.toString().isNotEmpty) {
        print('DEBUG updateNote: Creating new version');
        await createNoteVersion(id, contentMd, userId);
        print('DEBUG updateNote: Version created successfully');
      }

      // Re-fetch the note to get updated data including new latestVersionId
      return await getNoteById(id);
    } on DioException catch (e) {
      print('DEBUG updateNote: Error - ${e.response?.statusCode}: ${e.response?.data}');
      throw _handleError(e);
    }
  }

  Future<void> createNoteVersion(String noteId, String contentMd, String? createdBy) async {
    try {
      print('DEBUG createNoteVersion: noteId=$noteId, createdBy=$createdBy, contentLength=${contentMd.length}');
      final response = await _dioClient.post(
        '${ApiConstants.notes}/$noteId/versions',
        data: {
          'contentMd': contentMd,
          'createdBy': createdBy,
          'changeSummary': 'Updated content',
        },
      );
      print('DEBUG createNoteVersion: Success - ${response.data}');
    } on DioException catch (e) {
      print('DEBUG createNoteVersion: Error - ${e.response?.statusCode}: ${e.response?.data}');
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

  Future<void> markReady(String id, String readyBy) async {
    try {
      await _dioClient.post(
        '${ApiConstants.notes}/$id/mark-ready',
        queryParameters: {'readyBy': readyBy},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> releaseNote(String id, {List<String>? classIds, String? releasedBy}) async {
    try {
      await _dioClient.post(
        '${ApiConstants.notes}/$id/release',
        data: {
          if (classIds != null) 'targetClassIds': classIds,
          if (releasedBy != null) 'releasedBy': releasedBy,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ========== IMAGE METHODS ==========

  Future<NoteImageResponse> uploadImage(String noteId, String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dioClient.post(
        '${ApiConstants.notes}/$noteId/images',
        data: formData,
      );
      return NoteImageResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ========== FLASHCARD METHODS ==========

  Future<List<Flashcard>> getFlashcards(String noteId, {String? difficulty}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (difficulty != null) {
        queryParams['difficulty'] = difficulty;
      }
      final response = await _dioClient.get(
        '${ApiConstants.notes}/$noteId/flashcards',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = response.data;
      if (data is Map && data['items'] != null) {
        final items = data['items'] as List;
        return items.map((json) => Flashcard.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Flashcard> createFlashcard(String noteId, CreateFlashcardRequest request) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.notes}/$noteId/flashcards',
        data: request.toJson(),
      );
      return Flashcard.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Flashcard> updateFlashcard(
    String noteId,
    String flashcardId,
    UpdateFlashcardRequest request,
  ) async {
    try {
      final response = await _dioClient.patch(
        '${ApiConstants.notes}/$noteId/flashcards/$flashcardId',
        data: request.toJson(),
      );
      return Flashcard.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteFlashcard(String noteId, String flashcardId) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.notes}/$noteId/flashcards/$flashcardId',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Flashcard>> batchUpsertFlashcards(
    String noteId,
    BatchFlashcardsRequest request,
  ) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.notes}/$noteId/flashcards/batch',
        data: request.toJson(),
      );
      final data = response.data;
      if (data is Map && data['items'] != null) {
        final items = data['items'] as List;
        return items.map((json) => Flashcard.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ========== MCQ METHODS ==========

  Future<List<Mcq>> getMcqs(String noteId, {String? difficulty}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (difficulty != null) {
        queryParams['difficulty'] = difficulty;
      }
      final response = await _dioClient.get(
        '${ApiConstants.notes}/$noteId/mcqs',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = response.data;
      if (data is Map && data['items'] != null) {
        final items = data['items'] as List;
        return items.map((json) => Mcq.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Mcq> createMcq(String noteId, CreateMcqRequest request) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.notes}/$noteId/mcqs',
        data: request.toJson(),
      );
      return Mcq.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Mcq> updateMcq(
    String noteId,
    String mcqId,
    UpdateMcqRequest request,
  ) async {
    try {
      final response = await _dioClient.patch(
        '${ApiConstants.notes}/$noteId/mcqs/$mcqId',
        data: request.toJson(),
      );
      return Mcq.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteMcq(String noteId, String mcqId) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.notes}/$noteId/mcqs/$mcqId',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Mcq>> batchUpsertMcqs(
    String noteId,
    BatchMcqsRequest request,
  ) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.notes}/$noteId/mcqs/batch',
        data: request.toJson(),
      );
      final data = response.data;
      if (data is Map && data['items'] != null) {
        final items = data['items'] as List;
        return items.map((json) => Mcq.fromJson(json)).toList();
      }
      return [];
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
