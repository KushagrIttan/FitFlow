import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'dart:io';

import 'database.dart';
import 'database_provider.dart';

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((ref) {
  return WardrobeRepository(ref.watch(databaseProvider));
});

final wardrobeItemsProvider = StreamProvider<List<ClothingItem>>((ref) {
  return ref.watch(wardrobeRepositoryProvider).watchAllItems();
});

class WardrobeRepository {
  final AppDatabase _db;
  WardrobeRepository(this._db);

  Stream<List<ClothingItem>> watchAllItems() {
    return _db.select(_db.clothingItems).watch();
  }

  Future<int> addItem(ClothingItemsCompanion item) {
    return _db.into(_db.clothingItems).insert(item);
  }

  Future<bool> updateItem(ClothingItem item) {
    return _db.update(_db.clothingItems).replace(item);
  }

  Future<int> deleteItem(int id) async {
    // Remove the stored photo from disk so deletions don't leak files.
    final item = await (_db.select(_db.clothingItems)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (item != null && item.photo.isNotEmpty) {
      try {
        final file = File(item.photo);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Photo cleanup is best-effort; a missing/unreadable file
        // must never block the deletion.
      }
    }
    return (_db.delete(_db.clothingItems)..where((t) => t.id.equals(id))).go();
  }

  Future<int> toggleLaundry(int id, bool inLaundry) {
    return (_db.update(_db.clothingItems)..where((t) => t.id.equals(id)))
        .write(ClothingItemsCompanion(inLaundry: Value(inLaundry)));
  }

  /// Bumps wear stats for items worn today so recency/rotation scoring
  /// actually cycles the wardrobe instead of staying frozen at zero.
  Future<void> markWorn(Iterable<int> ids) async {
    final idList = ids.toList();
    if (idList.isEmpty) return;

    final now = DateTime.now();
    final items = await (_db.select(_db.clothingItems)
          ..where((t) => t.id.isIn(idList)))
        .get();

    for (final item in items) {
      await (_db.update(_db.clothingItems)..where((t) => t.id.equals(item.id)))
          .write(ClothingItemsCompanion(
        wearCount: Value(item.wearCount + 1),
        lastWornDate: Value(now),
      ));
    }
  }
}
