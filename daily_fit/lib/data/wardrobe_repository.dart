import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
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

  Future<int> deleteItem(int id) {
    return (_db.delete(_db.clothingItems)..where((t) => t.id.equals(id))).go();
  }

  Future<int> toggleLaundry(int id, bool inLaundry) {
    return (_db.update(_db.clothingItems)..where((t) => t.id.equals(id)))
        .write(ClothingItemsCompanion(inLaundry: Value(inLaundry)));
  }
}
