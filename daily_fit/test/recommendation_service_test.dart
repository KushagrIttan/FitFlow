import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';

import 'package:daily_fit/data/database.dart';
import 'package:daily_fit/data/recommendation_service.dart';
import 'package:daily_fit/data/wardrobe_repository.dart';
import 'package:daily_fit/data/weather_service.dart';
import 'package:daily_fit/models/enums.dart';

/// Returns fixed weather data instead of hitting open-meteo.
class _FakeWeatherService extends WeatherService {
  final WeatherData data;
  _FakeWeatherService(this.data);

  @override
  Future<WeatherData?> getWeather(String locationQuery) async => data;
}

/// Throws if called — used to prove weather is skipped when staying home.
class _ExplodingWeatherService extends WeatherService {
  @override
  Future<WeatherData?> getWeather(String locationQuery) async {
    throw StateError('weather must not be fetched when staying home');
  }
}

void main() {
  late AppDatabase db;

  setUp(() async {
    // Initialize dotenv with an empty key so tests deterministically take the
    // local fallback path and never call the Gemini API.
    dotenv.loadFromString(envString: 'GEMINI_API_KEY=');
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<ClothingItem> insertItem({
    required ItemCategory category,
    required BodyZone zone,
    int warmthLevel = 3,
    bool inLaundry = false,
    bool homeOnly = false,
    String name = 'Item',
  }) async {
    final id = await db.into(db.clothingItems).insert(
          ClothingItemsCompanion.insert(
            category: category,
            bodyZone: zone,
            name: drift.Value(name),
            color: const drift.Value('Black'),
            fit: Fit.regular,
            photo: '',
            warmthLevel: drift.Value(warmthLevel),
            inLaundry: drift.Value(inLaundry),
            homeOnly: drift.Value(homeOnly),
          ),
        );
    return await (db.select(db.clothingItems)
          ..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<void> seedBasicWardrobe() async {
    // Tee warmth 3 (matches real seed data: 'Black Essentials Tee').
    await insertItem(category: ItemCategory.tee, zone: BodyZone.upper, warmthLevel: 3, name: 'Tee');
    await insertItem(category: ItemCategory.jacket, zone: BodyZone.upper, warmthLevel: 5, name: 'Puffer');
    await insertItem(category: ItemCategory.jeans, zone: BodyZone.lower, name: 'Jeans');
    await insertItem(category: ItemCategory.trousers, zone: BodyZone.lower, name: 'Chinos');
    await insertItem(category: ItemCategory.shoes, zone: BodyZone.footwear, name: 'Sneakers');
    await insertItem(category: ItemCategory.shoes, zone: BodyZone.footwear, name: 'Boots');
    await insertItem(category: ItemCategory.cap, zone: BodyZone.accessory, name: 'Cap');
  }

  group('RecommendationService', () {
    test('returns 3 local fallback recs when no API key is configured', () async {
      await seedBasicWardrobe();
      final service = RecommendationService(
        db,
        _FakeWeatherService(WeatherData(temperature: 20, weatherCode: 0)),
      );

      final recs = await service.generateRecommendations(
        isGoingOut: true,
        location: 'New York',
      );

      expect(recs, hasLength(3));
      expect(recs.every((r) => r.isAiSuggested), isFalse);
    });

    test('excludes laundry and home-only items when going out', () async {
      await seedBasicWardrobe();
      final dirty = await insertItem(
        category: ItemCategory.tee,
        zone: BodyZone.upper,
        name: 'Dirty Tee',
        inLaundry: true,
      );
      final lounge = await insertItem(
        category: ItemCategory.tee,
        zone: BodyZone.upper,
        name: 'Lounge Tee',
        homeOnly: true,
      );

      final service = RecommendationService(
        db,
        _FakeWeatherService(WeatherData(temperature: 20, weatherCode: 0)),
      );
      final recs = await service.generateRecommendations(
        isGoingOut: true,
        location: 'New York',
      );

      final wornIds = recs.expand((r) => [r.upper.id, r.lower.id, r.footwear.id]);
      expect(wornIds, isNot(contains(dirty.id)));
      expect(wornIds, isNot(contains(lounge.id)));
    });

    test('filters uppers by weather warmth requirement', () async {
      // Wardrobe where only warmth separates the uppers: Tank (1) vs Puffer (5).
      await insertItem(category: ItemCategory.tee, zone: BodyZone.upper, warmthLevel: 1, name: 'Tank');
      await insertItem(category: ItemCategory.jacket, zone: BodyZone.upper, warmthLevel: 5, name: 'Puffer');
      await insertItem(category: ItemCategory.jeans, zone: BodyZone.lower, name: 'Jeans');
      await insertItem(category: ItemCategory.trousers, zone: BodyZone.lower, name: 'Chinos');
      await insertItem(category: ItemCategory.shoes, zone: BodyZone.footwear, name: 'Sneakers');
      await insertItem(category: ItemCategory.shoes, zone: BodyZone.footwear, name: 'Boots');
      await insertItem(category: ItemCategory.cap, zone: BodyZone.accessory, name: 'Cap');

      final service = RecommendationService(
        db,
        // 10°C → requiredWarmthLevel 4 → only warmth 3-5 uppers pass
        _FakeWeatherService(WeatherData(temperature: 10, weatherCode: 0)),
      );

      final recs = await service.generateRecommendations(
        isGoingOut: true,
        location: 'New York',
      );

      expect(recs, hasLength(3));
      final upperNames = recs.map((r) => r.upper.name).toSet();
      expect(upperNames, isNot(contains('Tank')));
      expect(upperNames, contains('Puffer'));
    });

    test('wet weather prefers jacket/hoodie uppers over tees', () async {
      // Two identical-warmth uppers: a tee and a jacket. In the rain the
      // jacket should win the top slots thanks to the wet-weather bonus.
      await insertItem(category: ItemCategory.tee, zone: BodyZone.upper, warmthLevel: 3, name: 'Tee');
      await insertItem(category: ItemCategory.jacket, zone: BodyZone.upper, warmthLevel: 3, name: 'Rain Jacket');
      await insertItem(category: ItemCategory.jeans, zone: BodyZone.lower, name: 'Jeans');
      await insertItem(category: ItemCategory.shoes, zone: BodyZone.footwear, name: 'Sneakers');

      final service = RecommendationService(
        db,
        // weather_code 61 = rain
        _FakeWeatherService(WeatherData(temperature: 18, weatherCode: 61)),
      );
      final recs = await service.generateRecommendations(
        isGoingOut: true,
        location: 'London',
      );

      expect(recs, isNotEmpty);
      final firstUpper = recs.first.upper.name;
      expect(firstUpper, 'Rain Jacket');
    });

    test('home-only items ARE allowed when staying home', () async {
      // Only a home-only upper in the wardrobe.
      await insertItem(category: ItemCategory.jeans, zone: BodyZone.lower, name: 'Jeans');
      await insertItem(category: ItemCategory.trousers, zone: BodyZone.lower, name: 'Chinos');
      await insertItem(category: ItemCategory.shoes, zone: BodyZone.footwear, name: 'Sneakers');
      await insertItem(category: ItemCategory.shoes, zone: BodyZone.footwear, name: 'Boots');
      await insertItem(category: ItemCategory.cap, zone: BodyZone.accessory, name: 'Cap');
      await insertItem(
        category: ItemCategory.tee,
        zone: BodyZone.upper,
        name: 'Lounge Tee',
        homeOnly: true,
      );

      final service = RecommendationService(db, _ExplodingWeatherService());
      // Staying home → weather must never be fetched (no location provided).
      final recs = await service.generateRecommendations(
        isGoingOut: false,
        location: '',
      );

      expect(recs, hasLength(3));
      final upperNames = recs.map((r) => r.upper.name).toSet();
      expect(upperNames, contains('Lounge Tee'));
    });

    test('excludes the previous day\u2019s upper from repeat recommendations',
        () async {
      await seedBasicWardrobe();
      // A second, valid home-worthy upper that isn't the logged Tee.
      await insertItem(
        category: ItemCategory.tee,
        zone: BodyZone.upper,
        name: 'Lounge Tee',
        homeOnly: true,
      );
      final tee = await (db.select(db.clothingItems)
            ..where((t) => t.name.equals('Tee')))
          .getSingle();

      // Log yesterday's outfit containing the Tee.
      await db.into(db.outfitLogs).insert(
            OutfitLogsCompanion.insert(
              date: DateTime.now().subtract(const Duration(days: 1)),
              items: '${tee.id}',
            ),
          );

      final service = RecommendationService(
        db,
        _FakeWeatherService(WeatherData(temperature: 30, weatherCode: 0)),
      );
      final recs = await service.generateRecommendations(
        isGoingOut: false,
        location: '',
      );

      // Staying home (target warmth 3): Puffer (5) fails warmth, Tee is
      // excluded by the repeat rule → only Lounge Tee remains.
      expect(recs, hasLength(3));
      final upperNames = recs.map((r) => r.upper.name).toSet();
      expect(upperNames, isNot(contains('Tee')));
      expect(upperNames, contains('Lounge Tee'));
    });

    test('generateOutfitPlan returns N outfits with no repeated items',
        () async {
      // Three of each zone, all warmth-valid for "home" (target 3).
      await insertItem(category: ItemCategory.tee, zone: BodyZone.upper, warmthLevel: 3, name: 'Tee A');
      await insertItem(category: ItemCategory.tee, zone: BodyZone.upper, warmthLevel: 3, name: 'Tee B');
      await insertItem(category: ItemCategory.hoodie, zone: BodyZone.upper, warmthLevel: 3, name: 'Hoodie');
      await insertItem(category: ItemCategory.jeans, zone: BodyZone.lower, name: 'Jeans');
      await insertItem(category: ItemCategory.trousers, zone: BodyZone.lower, name: 'Chinos');
      await insertItem(category: ItemCategory.shorts, zone: BodyZone.lower, name: 'Shorts');
      await insertItem(category: ItemCategory.shoes, zone: BodyZone.footwear, name: 'Sneakers');
      await insertItem(category: ItemCategory.shoes, zone: BodyZone.footwear, name: 'Boots');
      await insertItem(category: ItemCategory.otherFootwear, zone: BodyZone.footwear, name: 'Slides');

      final service = RecommendationService(
        db,
        _FakeWeatherService(WeatherData(temperature: 20, weatherCode: 0)),
      );
      final plan = await service.generateOutfitPlan(
        count: 3,
        isGoingOut: false,
        location: '',
      );

      expect(plan, hasLength(3));

      final allIds = <int>[];
      for (final outfit in plan) {
        allIds.addAll([
          outfit.upper.id,
          outfit.lower.id,
          outfit.footwear.id,
          if (outfit.accessory != null) outfit.accessory!.id,
        ]);
      }
      // No item appears twice across the whole plan.
      expect(allIds.toSet().length, allIds.length);
    });

    test('generateOutfitPlan caps at what the wardrobe can support', () async {
      await seedBasicWardrobe(); // 1 warmth-valid upper, 2 lowers, 2 footwear

      final service = RecommendationService(
        db,
        _FakeWeatherService(WeatherData(temperature: 20, weatherCode: 0)),
      );
      final plan = await service.generateOutfitPlan(
        count: 10,
        isGoingOut: false,
        location: '',
      );

      // Only one upper passes the staying-home warmth filter → max 1 outfit.
      expect(plan, hasLength(1));
    });

    test('logWornOutfit bumps wear stats and writes history', () async {
      final upper = await insertItem(
          category: ItemCategory.tee, zone: BodyZone.upper, name: 'Tee');
      final lower = await insertItem(
          category: ItemCategory.jeans, zone: BodyZone.lower, name: 'Jeans');
      final shoes = await insertItem(
          category: ItemCategory.shoes, zone: BodyZone.footwear, name: 'Sneakers');

      final outfit = RecommendedOutfit(
        upper: upper,
        lower: lower,
        footwear: shoes,
        description: 'test',
        isAiSuggested: false,
      );
      final service = RecommendationService(
        db,
        _FakeWeatherService(WeatherData(temperature: 20, weatherCode: 0)),
      );
      await service.logWornOutfit(outfit, destination: 'Office', vibe: 'Casual');

      final updated = await (db.select(db.clothingItems)
            ..where((t) => t.id.equals(upper.id)))
          .getSingle();
      expect(updated.wearCount, 1);
      expect(updated.lastWornDate, isNotNull);

      final logs = await db.select(db.outfitLogs).get();
      expect(logs, hasLength(1));
      expect(logs.first.destination, 'Office');
      expect(logs.first.vibeTag, 'Casual');
    });
  });

  group('WardrobeRepository', () {
    test('markWorn increments wearCount and sets lastWornDate', () async {
      final item = await insertItem(
        category: ItemCategory.tee,
        zone: BodyZone.upper,
        name: 'Tee',
      );
      expect(item.lastWornDate, isNull);

      final repo = WardrobeRepository(db);
      await repo.markWorn([item.id]);

      final updated = await (db.select(db.clothingItems)
            ..where((t) => t.id.equals(item.id)))
          .getSingle();
      expect(updated.wearCount, 1);
      expect(updated.lastWornDate, isNotNull);
    });

    test('markWorn is a no-op for unknown ids and empty lists', () async {
      final repo = WardrobeRepository(db);
      await repo.markWorn([]);
      await repo.markWorn([99999]);
      // No exceptions thrown; nothing to assert beyond that.
    });
  });
}
