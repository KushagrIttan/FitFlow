import 'package:drift/drift.dart';
import 'database.dart';
import '../models/enums.dart';

Future<void> seedDatabase(AppDatabase db) async {
  final count = await db.select(db.clothingItems).get().then((value) => value.length);
  if (count > 0) return; // Already seeded

  final items = [
    ClothingItemsCompanion.insert(
      category: ItemCategory.tee,
      bodyZone: BodyZone.upper,
      name: const Value('Black Essentials Tee'),
      color: const Value('Black'),
      fit: Fit.regular,
      photo: '',
      warmthLevel: const Value(3),
    ),
    ClothingItemsCompanion.insert(
      category: ItemCategory.jeans,
      bodyZone: BodyZone.lower,
      name: const Value('Blue Levi\'s 501'),
      color: const Value('Blue'),
      fit: Fit.regular,
      photo: '',
    ),
    ClothingItemsCompanion.insert(
      category: ItemCategory.shoes,
      bodyZone: BodyZone.footwear,
      name: const Value('White Sneakers'),
      color: const Value('White'),
      fit: Fit.regular,
      photo: '',
    ),
  ];

  for (final item in items) {
    await db.into(db.clothingItems).insert(item);
  }
}
