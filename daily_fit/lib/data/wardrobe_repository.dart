import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'dart:convert';
import 'dart:io';

import 'database.dart';
import 'database_provider.dart';

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((ref) {
  return WardrobeRepository(ref.watch(databaseProvider));
});

final wardrobeItemsProvider = StreamProvider<List<ClothingItem>>((ref) {
  return ref.watch(wardrobeRepositoryProvider).watchAllItems();
});

final outfitLogsProvider = StreamProvider<List<OutfitLog>>((ref) {
  return ref.watch(wardrobeRepositoryProvider).watchOutfitLogs();
});

class WardrobeRepository {
  final AppDatabase _db;
  WardrobeRepository(this._db);

  Stream<List<ClothingItem>> watchAllItems() {
    return _db.select(_db.clothingItems).watch();
  }

  Stream<List<OutfitLog>> watchOutfitLogs() {
    return _db.select(_db.outfitLogs).watch();
  }

  Future<int> addItem(ClothingItemsCompanion item) {
    return _db.into(_db.clothingItems).insert(item);
  }

  Future<bool> updateItem(ClothingItem item) {
    return _db.update(_db.clothingItems).replace(item);
  }

  /// Photo paths attached to an item (falling back to the legacy single
  /// [ClothingItem.photo] column).
  List<String> itemPhotoPaths(ClothingItem item) {
    if (item.photos != null && item.photos!.isNotEmpty) {
      try {
        final decoded = jsonDecode(item.photos!) as List;
        final paths = decoded.whereType<String>().toList();
        if (paths.isNotEmpty) return paths;
      } catch (_) {
        // Malformed JSON — fall through to the cover photo.
      }
    }
    return item.photo.isNotEmpty ? [item.photo] : [];
  }

  Future<int> deleteItem(int id) async {
    // Remove every stored photo from disk so deletions don't leak files.
    final item = await (_db.select(_db.clothingItems)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (item != null) {
      for (final path in itemPhotoPaths(item)) {
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (_) {
          // Photo cleanup is best-effort; a missing/unreadable file
          // must never block the deletion.
        }
      }
    }
    return (_db.delete(_db.clothingItems)..where((t) => t.id.equals(id))).go();
  }

  Future<int> toggleLaundry(int id, bool inLaundry) {
    return (_db.update(_db.clothingItems)..where((t) => t.id.equals(id)))
        .write(ClothingItemsCompanion(inLaundry: Value(inLaundry)));
  }

  /// Sets (or clears, when [rating] is null) a user's rating on an outfit log.
  Future<void> setOutfitRating(int logId, int? rating) {
    return (_db.update(_db.outfitLogs)..where((t) => t.id.equals(logId)))
        .write(OutfitLogsCompanion(rating: Value(rating)));
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
