import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database.dart';

/// JSON export of the whole wardrobe + outfit history.
/// Local-first apps have no cloud, so a backup is the only safety net
/// against reinstalls and device loss.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  Future<File> exportToJson() async {
    final items = await _db.select(_db.clothingItems).get();
    final logs = await _db.select(_db.outfitLogs).get();

    final payload = {
      'app': 'daily_fit',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'outfitLogs': logs.map((l) => l.toJson()).toList(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(dir.path, 'daily_fit_backup_$stamp.json'));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file;
  }
}
