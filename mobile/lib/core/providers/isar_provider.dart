import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/domain/sync_record.dart';

final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open([SyncRecordSchema], directory: dir.path);
});
