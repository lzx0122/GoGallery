import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:photo_manager/photo_manager.dart';
import 'sync_record.dart';
import '../../../core/providers/isar_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../home/presentation/providers/media_provider.dart';

class SyncStatus {
  final bool isSyncing;
  final int totalCount;
  final int currentCount;
  final String? lastError;
  final String? lastSuccessMessage;

  SyncStatus({
    this.isSyncing = false,
    this.totalCount = 0,
    this.currentCount = 0,
    this.lastError,
    this.lastSuccessMessage,
  });

  SyncStatus copyWith({
    bool? isSyncing,
    int? totalCount,
    int? currentCount,
    String? lastError,
    String? lastSuccessMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      totalCount: totalCount ?? this.totalCount,
      currentCount: currentCount ?? this.currentCount,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastSuccessMessage: clearSuccess
          ? null
          : (lastSuccessMessage ?? this.lastSuccessMessage),
    );
  }
}

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus());

final syncServiceProvider = Provider((ref) => SyncService(ref));

class SyncService {
  final Ref ref;
  SyncService(this.ref);

  Future<void> startSync() async {
    final statusNotifier = ref.read(syncStatusProvider.notifier);
    if (statusNotifier.state.isSyncing) return;

    statusNotifier.state = statusNotifier.state.copyWith(
      isSyncing: true,
      clearError: true,
      clearSuccess: true,
      currentCount: 0,
      totalCount: 0,
    );

    try {
      // 1. Request Permissions
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        throw Exception("Missing gallery permission");
      }

      // 2. Scan Gallery
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );
      debugPrint("Found ${albums.length} albums");
      List<AssetEntity> allAssets = [];
      for (var album in albums) {
        debugPrint(
          "Album: ${album.name}, isAll: ${album.isAll}, count: ${await album.assetCountAsync}",
        );
        if (album.isAll) {
          allAssets = await album.getAssetListRange(start: 0, end: 1000000);
          break;
        }
      }

      // Fallback: If no "isAll" album, combine all albums (removing duplicates)
      if (allAssets.isEmpty && albums.isNotEmpty) {
        debugPrint("No 'All' album found or empty, scanning all albums...");
        final Set<String> seenIds = {};
        for (var album in albums) {
          final assets = await album.getAssetListRange(start: 0, end: 1000000);
          for (var asset in assets) {
            if (seenIds.add(asset.id)) {
              allAssets.add(asset);
            }
          }
        }
      }

      debugPrint("Total assets to sync: ${allAssets.length}");

      if (allAssets.isEmpty) {
        statusNotifier.state = statusNotifier.state.copyWith(
          isSyncing: false,
          lastSuccessMessage: "相簿中沒有新照片需要同步",
        );
        return;
      }

      statusNotifier.state = statusNotifier.state.copyWith(
        totalCount: allAssets.length,
      );

      final isar = await ref.read(isarProvider.future);

      final user = ref.read(authProvider).valueOrNull;
      if (user == null) throw Exception("Not logged in");
      final token = user.token;
      if (token == null) throw Exception("Authentication token is missing");

      final repository = ref.read(mediaRepositoryProvider);

      debugPrint("Sync loop started with ${allAssets.length} assets");
      int syncedCount = 0;
      int skippedCount = 0;
      int errorCount = 0;

      for (var asset in allAssets) {
        if (!statusNotifier.state.isSyncing) break;

        try {
          // Check local DB
          final record = await isar.syncRecords
              .filter()
              .localIdEqualTo(asset.id)
              .findFirst();

          if (record != null && record.isSynced) {
            // Already synced in local DB, but let's verify if it's still on the server
            // We use the cached hash to avoid re-reading the file
            try {
              final stillOnServer = record.fileHash != null
                  ? await repository.checkHash(record.fileHash!, token)
                  : null;
              if (stillOnServer != null) {
                skippedCount++;
                statusNotifier.state = statusNotifier.state.copyWith(
                  currentCount: statusNotifier.state.currentCount + 1,
                );
                continue;
              }
              debugPrint(
                "Asset ${asset.id} marked as synced locally but missing on server. Re-syncing...",
              );
            } catch (e) {
              debugPrint("Failed to verify asset ${asset.id} on server: $e");
              // If verification fails, we fall through to the normal sync logic
            }
          }

          final file = await asset.file;
          if (file == null) {
            debugPrint("Asset ${asset.id} file is null");
            skippedCount++;
            continue;
          }

          // Hashing
          final hash = await _calculateHash(file);

          // Check Server
          final existingMedia = await repository.checkHash(hash, token);
          if (existingMedia != null) {
            // Already on server
            await isar.writeTxn(() async {
              await isar.syncRecords.put(
                SyncRecord()
                  ..localId = asset.id
                  ..fileHash = hash
                  ..isSynced = true
                  ..lastSyncTime = DateTime.now(),
              );
            });
            skippedCount++;
          } else {
            // Upload with Retry
            await _uploadWithRetry(file, token, takenAt: asset.createDateTime);
            await isar.writeTxn(() async {
              await isar.syncRecords.put(
                SyncRecord()
                  ..localId = asset.id
                  ..fileHash = hash
                  ..isSynced = true
                  ..lastSyncTime = DateTime.now(),
              );
            });
            syncedCount++;
          }
        } catch (e) {
          debugPrint("Failed to sync asset ${asset.id}: $e");
          errorCount++;
        }

        statusNotifier.state = statusNotifier.state.copyWith(
          currentCount: statusNotifier.state.currentCount + 1,
        );
      }

      debugPrint(
        "Sync finished. Synced: $syncedCount, Skipped: $skippedCount, Errors: $errorCount",
      );

      if (errorCount == 0) {
        String msg = "同步完成！";
        if (syncedCount > 0) {
          msg = "同步完成：成功上傳 $syncedCount 張照片";
        } else {
          msg = "同步完成：所有照片都已在雲端";
        }
        statusNotifier.state = statusNotifier.state.copyWith(
          lastSuccessMessage: msg,
        );
      } else {
        statusNotifier.state = statusNotifier.state.copyWith(
          lastError: "同步部分完成，但有 $errorCount 個錯誤",
        );
      }
    } catch (e) {
      debugPrint("Global sync error: $e");
      statusNotifier.state = statusNotifier.state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
      rethrow;
    } finally {
      statusNotifier.state = statusNotifier.state.copyWith(isSyncing: false);
      ref.invalidate(mediaListProvider);
    }
  }

  void stopSync() {
    final statusNotifier = ref.read(syncStatusProvider.notifier);
    statusNotifier.state = statusNotifier.state.copyWith(isSyncing: false);
  }

  Future<String> _calculateHash(File file) async {
    final size = await file.length();
    if (size <= 20 * 1024 * 1024) {
      // Small file: full hash
      final bytes = await file.readAsBytes();
      return sha256.convert(bytes).toString();
    } else {
      // Large file: partial hash (Start 1MB + End 1MB + Size)
      final randomAccessFile = await file.open();
      try {
        final startBytes = await randomAccessFile.read(1024 * 1024);
        await randomAccessFile.setPosition(size - 1024 * 1024);
        final endBytes = await randomAccessFile.read(1024 * 1024);
        final content = [
          ...startBytes,
          ...endBytes,
          ...size.toString().codeUnits,
        ];
        return sha256.convert(content).toString();
      } finally {
        await randomAccessFile.close();
      }
    }
  }

  Future<void> _uploadWithRetry(
    File file,
    String token, {
    int maxRetries = 3,
    DateTime? takenAt,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        final repository = ref.read(mediaRepositoryProvider);
        await repository.uploadMedia(file, token, takenAt: takenAt);
        return;
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) rethrow;
        // Exponential backoff
        await Future.delayed(Duration(seconds: pow(2, attempts).toInt()));
      }
    }
  }
}
