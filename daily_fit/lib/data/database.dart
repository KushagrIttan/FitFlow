import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import '../models/enums.dart';

part 'database.g.dart';

@DataClassName('ClothingItem')
class ClothingItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get category => intEnum<ItemCategory>()();
  IntColumn get bodyZone => intEnum<BodyZone>()();
  TextColumn get name => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get fit => intEnum<Fit>()();
  TextColumn get photo => text()();
  /// JSON array of all photo paths; index 0 equals [photo] (the cover).
  /// Null for legacy items with a single photo.
  TextColumn get photos => text().nullable()();
  BoolColumn get homeOnly => boolean().withDefault(const Constant(false))();
  IntColumn get warmthLevel => integer().withDefault(const Constant(3))();
  BoolColumn get inLaundry => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastWornDate => dateTime().nullable()();
  IntColumn get wearCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('OutfitLog')
class OutfitLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get items => text()(); // Store as comma separated IDs or JSON
  TextColumn get destination => text().nullable()();
  TextColumn get vibeTag => text().nullable()();
  TextColumn get weatherSnapshot => text().nullable()();
  BoolColumn get wasAiSuggested => boolean().withDefault(const Constant(false))();
  /// Optional user rating (1-5). Used by the recommendation engine to learn
  /// which items appear in outfits the user actually liked.
  IntColumn get rating => integer().nullable()();
}

@DriftDatabase(tables: [ClothingItems, OutfitLogs])
class AppDatabase extends _$AppDatabase {
  /// Pass an executor (e.g. `NativeDatabase.memory()`) in tests;
  /// production uses the on-device SQLite file.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(clothingItems, clothingItems.photos);
            await m.addColumn(outfitLogs, outfitLogs.rating);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'daily_fit.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
