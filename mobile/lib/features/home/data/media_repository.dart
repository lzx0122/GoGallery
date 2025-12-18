import 'dart:io';
import 'package:dio/dio.dart';
import '../domain/media.dart';

class MediaRepository {
  final Dio _dio;
  // Android Emulator: 10.0.2.2, iOS Simulator: localhost
  // For now, hardcode localhost for iOS.
  static const String _baseUrl = 'http://localhost:8080/api';

  MediaRepository({Dio? dio}) : _dio = dio ?? Dio();

  Future<Media?> uploadMedia(File file, String token) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      Response response = await _dio.post(
        '$_baseUrl/upload',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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
        '$_baseUrl/media',
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
}
