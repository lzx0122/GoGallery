import 'package:isar/isar.dart';

part 'sync_record.g.dart';

@collection
class SyncRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? localId; // 手機端 ID (AssetEntity.id)

  @Index()
  String? fileHash;

  DateTime? lastSyncTime;

  bool isSynced = false;
}
