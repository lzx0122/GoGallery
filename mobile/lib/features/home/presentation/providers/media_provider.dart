import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/media_repository.dart';
import '../../domain/media.dart';

final mediaRepositoryProvider = Provider((ref) => MediaRepository());

final mediaListProvider = AsyncNotifierProvider<MediaListNotifier, List<Media>>(
  () {
    return MediaListNotifier();
  },
);

class MediaListNotifier extends AsyncNotifier<List<Media>> {
  @override
  Future<List<Media>> build() async {
    // 監聽 Auth 狀態，當使用者登入/登出時自動重新整理列表
    final user = ref.watch(authProvider);
    if (user.value == null) {
      return [];
    }
    return _fetchMedia();
  }

  Future<String?> _getToken() async {
    final googleSignIn = ref.read(googleSignInProvider);
    final currentUser = googleSignIn.currentUser;
    if (currentUser == null) return null;

    final auth = await currentUser.authentication;
    return auth.idToken;
  }

  Future<List<Media>> _fetchMedia() async {
    final token = await _getToken();
    if (token == null) return [];

    final repository = ref.read(mediaRepositoryProvider);
    return repository.fetchMediaList(token);
  }

  Future<void> uploadMedia(File file) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Not logged in");

      final repository = ref.read(mediaRepositoryProvider);
      await repository.uploadMedia(file, token);
      // Refresh the list
      ref.invalidateSelf();
      await future;
    } catch (e) {
      print("Upload failed: $e");
      rethrow; // 讓 UI 層可以捕捉錯誤
    }
  }
}
