import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../domain/media.dart';

class MediaRepository {
  final Dio _dio;

  MediaRepository({Dio? dio}) : _dio = dio ?? Dio();

  Future<Media?> uploadMedia(
    File file,
    String token, {
    bool force = false,
    DateTime? takenAt,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
        if (takenAt != null) "taken_at": takenAt.toUtc().toIso8601String(),
      });

      Response response = await _dio.post(
        '${AppConfig.apiUrl}/upload',
        queryParameters: {'force': force},
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        onSendProgress: onSendProgress,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // 201 Created, 200 Skipped (Exists)
        // If skipped, the backend returns {"status": "skipped"}, not the full media object usually?
        // Let's check backend handler.
        // Backend:
        // if skipped -> c.JSON(http.StatusOK, gin.H{"status": "skipped", "reason": "exists"})
        // if created -> c.JSON(http.StatusCreated, result.Media)

        if (response.data['status'] == 'skipped') {
          // Handle skipped case, maybe return null or throw specific exception
          // For now, let's just return null to indicate no new media created
          return null;
        }
        return Media.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final existingId = e.response?.data['existing_id'] as String?;
        throw DuplicateMediaException(existingId: existingId);
      }
      print('Upload error: $e');
      rethrow;
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  Future<List<Media>> fetchMediaList(
    String token, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      Response response = await _dio.get(
        '${AppConfig.apiUrl}/media',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        List<dynamic> list = response.data ?? [];
        return list.map((e) => Media.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Fetch list error: $e');
      rethrow;
    }
  }

  Future<Media?> checkHash(String hash, String token) async {
    try {
      Response response = await _dio.get(
        '${AppConfig.apiUrl}/media/check/$hash',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return Media.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    } catch (e) {
      print('Check hash error: $e');
      rethrow;
    }
  }

  Future<void> deleteMedia(
    String token,
    String mediaId, {
    bool permanent = false,
  }) async {
    try {
      await _dio.delete(
        '${AppConfig.apiUrl}/media/$mediaId',
        queryParameters: {'permanent': permanent},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      print('Delete error: $e');
      rethrow;
    }
  }

  Future<List<Media>> fetchTrashList(
    String token, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      Response response = await _dio.get(
        '${AppConfig.apiUrl}/media/trash',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        List<dynamic> list = response.data ?? [];
        return list.map((e) => Media.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Fetch trash list error: $e');
      rethrow;
    }
  }

  Future<void> restoreMedia(String token, String mediaId) async {
    try {
      await _dio.post(
        '${AppConfig.apiUrl}/media/$mediaId/restore',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      print('Restore error: $e');
      rethrow;
    }
  }
}

class DuplicateMediaException implements Exception {
  final String message;
  final String? existingId;
  DuplicateMediaException({
    this.message = "Duplicate media detected",
    this.existingId,
  });
  @override
  String toString() => "DuplicateMediaException: $message (ID: $existingId)";
}
