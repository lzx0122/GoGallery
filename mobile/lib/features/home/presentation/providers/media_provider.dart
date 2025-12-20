import 'dart:io';
import 'dart:math';
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

enum UploadStatus { success, duplicate, error }

class UploadResult {
  final UploadStatus status;
  final String? existingId;
  UploadResult(this.status, {this.existingId});
}

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

  Future<void> clearHighlight(String id) async {
    await clearHighlights([id]);
  }

  Future<void> clearHighlights(List<String> ids) async {
    final currentList = state.value;
    if (currentList != null) {
      state = AsyncValue.data(
        currentList.map((m) {
          if (ids.contains(m.id)) {
            return m.copyWith(isHighlighted: false);
          }
          return m;
        }).toList(),
      );
    }
  }

  Future<void> setHighlight(String id) async {
    final currentList = state.value;
    if (currentList != null) {
      state = AsyncValue.data(
        currentList.map((m) {
          if (m.id == id) {
            return m.copyWith(isHighlighted: true);
          }
          return m;
        }).toList(),
      );
    }
  }

  Future<UploadResult> uploadMedia(
    File file, {
    bool force = false,
    bool highlightDuplicate = true,
  }) async {
    final tempId =
        'temp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';

    // Only add optimistic item if NOT forcing (first attempt)
    // If forcing, we assume we are updating/replacing or just adding a duplicate,
    // but for now let's keep it simple: always add optimistic item, remove if duplicate found.
    if (!force) {
      final tempMedia = Media(
        id: tempId,
        userId: '', // Placeholder
        originalFilename: file.path.split('/').last,
        fileHash: '',
        sizeBytes: await file.length(),
        width: 0,
        height: 0,
        duration: 0,
        mimeType: '',
        cameraMake: '',
        cameraModel: '',
        exposureTime: '',
        aperture: 0,
        iso: 0,
        blurHash: '',
        dominantColor: '',
        uploadedAt: DateTime.now(),
        isUploading: true,
        isDuplicate: false,
        uploadProgress: 0.0,
        localFile: file,
      );

      // Optimistic update: Add to list
      final currentList = state.value ?? [];
      state = AsyncValue.data([tempMedia, ...currentList]);
    }

    try {
      final token = await _getToken();
      if (token == null) throw Exception("Not logged in");

      final repository = ref.read(mediaRepositoryProvider);
      final result = await repository.uploadMedia(
        file,
        token,
        force: force,
        onSendProgress: (sent, total) {
          if (total <= 0) return;
          final progress = sent / total;

          // Update progress
          final currentList = state.value;
          if (currentList != null) {
            // If forcing, we might not have a tempId in the list if we didn't add it?
            // Actually, if force=true, we probably want to show progress too.
            // But for simplicity, let's just handle the non-force progress for now
            // or assume the caller handles UI for force upload.
            if (!force) {
              state = AsyncValue.data(
                currentList.map((m) {
                  if (m.id == tempId) {
                    return m.copyWith(uploadProgress: progress);
                  }
                  return m;
                }).toList(),
              );
            }
          }
        },
      );

      // Success
      if (!force) {
        // Replace temp with real result
        final currentListAfterUpload = state.value;
        if (currentListAfterUpload != null && result != null) {
          state = AsyncValue.data(
            currentListAfterUpload.map((m) {
              if (m.id == tempId) {
                return result;
              }
              return m;
            }).toList(),
          );
        }
      } else {
        // Force upload success: Add the new result to the list
        // (It might be a duplicate in content but new ID)
        final currentList = state.value ?? [];
        if (result != null) {
          // Remove temp item first (if any)
          final listWithoutTemp = currentList.where((m) => m.id != tempId).toList();
          state = AsyncValue.data([result, ...listWithoutTemp]);
        }
      }
      return UploadResult(UploadStatus.success);
    } on DuplicateMediaException catch (e) {
      // Remove the optimistic item AND highlight existing one in a single update
      final currentList = state.value;
      if (currentList != null) {
        print("Duplicate detected. Existing ID: ${e.existingId}");

        final newList = currentList
            .where((m) => m.id != tempId) // Remove temp
            .map((m) {
              if (highlightDuplicate &&
                  e.existingId != null &&
                  m.id == e.existingId) {
                print("Highlighting media: ${m.id}");
                return m.copyWith(isHighlighted: true);
              }
              return m;
            })
            .toList();

        state = AsyncValue.data(newList);
      }

      return UploadResult(UploadStatus.duplicate, existingId: e.existingId);
    } catch (e) {
      print("Upload failed: $e");
      // Remove temp on error
      if (!force) {
        final currentListOnError = state.value;
        if (currentListOnError != null) {
          state = AsyncValue.data(
            currentListOnError.where((m) => m.id != tempId).toList(),
          );
        }
      }
      return UploadResult(UploadStatus.error);
    }
  }

  Future<void> deleteMedias(List<String> mediaIds) async {
    print("Deleting medias: $mediaIds");

    // Optimistic update: Remove from list
    final currentList = state.value ?? [];
    final previousList = [...currentList];
    state = AsyncValue.data(
      currentList.where((m) => !mediaIds.contains(m.id)).toList(),
    );

    final token = await _getToken();
    if (token == null) {
      state = AsyncValue.data(previousList);
      return;
    }

    final repository = ref.read(mediaRepositoryProvider);

    try {
      await Future.wait(
        mediaIds.map((id) => repository.deleteMedia(token, id)),
      );
    } catch (e) {
      // Revert if failed
      state = AsyncValue.data(previousList);
      print("Delete failed: $e");
      rethrow;
    }
  }

  Future<void> deleteMedia(String mediaId) async {
    print("Deleting media: $mediaId");

    // Optimistic update: Remove from list
    final currentList = state.value ?? [];
    final previousList = [...currentList];
    state = AsyncValue.data(currentList.where((m) => m.id != mediaId).toList());

    // If it's a temporary item, don't call API
    if (mediaId.startsWith('temp_')) {
      return;
    }

    final token = await _getToken();
    if (token == null) {
      // Revert if no token (shouldn't happen if logged in)
      state = AsyncValue.data(previousList);
      return;
    }

    final repository = ref.read(mediaRepositoryProvider);

    try {
      await repository.deleteMedia(token, mediaId);
    } catch (e) {
      // Revert if failed
      state = AsyncValue.data(previousList);
      print("Delete failed: $e");
      rethrow;
    }
  }
}

// Trash Provider
final trashListProvider =
    AsyncNotifierProvider<TrashListNotifier, List<Media>>(() {
  return TrashListNotifier();
});

class TrashListNotifier extends AsyncNotifier<List<Media>> {
  @override
  Future<List<Media>> build() async {
    return _fetchTrash();
  }

  Future<String?> _getToken() async {
    final authState = ref.read(authProvider);
    return authState.value?.token;
  }

  Future<List<Media>> _fetchTrash() async {
    final token = await _getToken();
    if (token == null) {
      return [];
    }

    try {
      final repository = ref.read(mediaRepositoryProvider);
      return await repository.fetchTrashList(token);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchTrash() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTrash());
  }

  Future<void> restoreMedia(String mediaId) async {
    final token = await _getToken();
    if (token == null) return;

    // Optimistic update
    final currentList = state.value ?? [];
    final previousList = [...currentList];
    state = AsyncValue.data(currentList.where((m) => m.id != mediaId).toList());

    try {
      final repository = ref.read(mediaRepositoryProvider);
      await repository.restoreMedia(token, mediaId);
      // Refresh main media list to show restored item
      ref.refresh(mediaListProvider);
    } catch (e) {
      state = AsyncValue.data(previousList);
      rethrow;
    }
  }

  Future<void> deletePermanently(String mediaId) async {
    final token = await _getToken();
    if (token == null) return;

    // Optimistic update
    final currentList = state.value ?? [];
    final previousList = [...currentList];
    state = AsyncValue.data(currentList.where((m) => m.id != mediaId).toList());

    try {
      final repository = ref.read(mediaRepositoryProvider);
      await repository.deleteMedia(token, mediaId, permanent: true);
    } catch (e) {
      state = AsyncValue.data(previousList);
      rethrow;
    }
  }
}
