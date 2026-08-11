import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:drift/drift.dart' as drift;

import 'database.dart';
import 'database_provider.dart';
import 'user_profile_service.dart';
import 'wardrobe_repository.dart';
import 'weather_service.dart';
import '../models/enums.dart';

final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  final db = ref.watch(databaseProvider);
  final weather = ref.watch(weatherServiceProvider);
  final profile = ref.watch(userProfileServiceProvider);
  return RecommendationService(db, weather, profile);
});

class OutfitCandidate {
  final ClothingItem upper;
  final ClothingItem lower;
  final ClothingItem footwear;
  final ClothingItem? accessory;
  final double score;

  OutfitCandidate(this.upper, this.lower, this.footwear, this.accessory, this.score);
}

class RecommendedOutfit {
  final ClothingItem upper;
  final ClothingItem lower;
  final ClothingItem footwear;
  final ClothingItem? accessory;
  final String description;
  final bool isAiSuggested;

  RecommendedOutfit({
    required this.upper,
    required this.lower,
    required this.footwear,
    this.accessory,
    required this.description,
    this.isAiSuggested = false,
  });
}

/// Categories that meaningfully protect against rain/storm weather.
const _wetWeatherUppers = {
  ItemCategory.jacket,
  ItemCategory.hoodie,
  ItemCategory.sweater,
  ItemCategory.otherUpper,
};

class RecommendationService {
  final AppDatabase _db;
  final WeatherService _weather;
  final UserProfileService? _profile;

  RecommendationService(this._db, this._weather, [this._profile]);

  /// Stage 1: fetch, filter, and score every valid permutation.
  /// Shared by the daily recommendation and the outfit plan generator.
  Future<List<OutfitCandidate>> _buildCandidates({
    required bool isGoingOut,
    required WeatherData? weatherData,
  }) async {
    var targetWarmth = weatherData?.requiredWarmthLevel ?? 3;
    final condition = weatherData?.condition ?? WeatherCondition.clear;

    // Snow genuinely needs warmer layers — tighten the floor.
    if (condition == WeatherCondition.snow) {
      targetWarmth = (targetWarmth + 1).clamp(1, 5);
    }

    // 1. Fetch available items
    final allItems = await _db.select(_db.clothingItems).get();
    
    // 2. Fetch last logged outfit to exclude upper body repeats
    final lastLog = await (_db.select(_db.outfitLogs)
      ..orderBy([(t) => drift.OrderingTerm.desc(t.date)])
      ..limit(1))
      .getSingleOrNull();

    List<int> excludedUpperIds = [];
    if (lastLog != null) {
      if (lastLog.items.isNotEmpty) {
        final lastItemIds = lastLog.items.split(',').map((e) => int.tryParse(e) ?? -1).toList();
        final lastItems = allItems.where((i) => lastItemIds.contains(i.id)).toList();
        excludedUpperIds = lastItems.where((i) => i.bodyZone == BodyZone.upper).map((i) => i.id).toList();
      }
    }

    // Filter Items
    final uppers = allItems.where((i) => 
      i.bodyZone == BodyZone.upper && 
      !i.inLaundry && 
      (!isGoingOut || !i.homeOnly) &&
      !excludedUpperIds.contains(i.id) &&
      (i.warmthLevel >= targetWarmth - 1 && i.warmthLevel <= targetWarmth + 1)
    ).toList();

    final lowers = allItems.where((i) => 
      i.bodyZone == BodyZone.lower && 
      !i.inLaundry && 
      (!isGoingOut || !i.homeOnly)
    ).toList();

    final footwears = allItems.where((i) => 
      i.bodyZone == BodyZone.footwear && 
      !i.inLaundry && 
      (!isGoingOut || !i.homeOnly)
    ).toList();

    final accessories = allItems.where((i) => 
      i.bodyZone == BodyZone.accessory && 
      !i.inLaundry && 
      (!isGoingOut || !i.homeOnly)
    ).toList();

    if (uppers.isEmpty || lowers.isEmpty || footwears.isEmpty) {
      return []; // Caller handles empty state
    }

    final wet = condition == WeatherCondition.rain || condition == WeatherCondition.storm;

    // 3. Generate Permutations & Score
    List<OutfitCandidate> candidates = [];
    for (final u in uppers) {
      for (final l in lowers) {
        for (final f in footwears) {
          // Add a "no accessory" permutation
          final baseItems = [u, l, f];
          double baseScore = baseItems.fold(0.0, (s, i) => s + _daysSinceWornScore(i.lastWornDate) - (i.wearCount * 0.5));
          // In wet weather, prefer jackets/hoodies/sweaters over tees.
          if (wet && _wetWeatherUppers.contains(u.category)) {
            baseScore += 2.0;
          }
          candidates.add(OutfitCandidate(u, l, f, null, baseScore));
          
          // Add permutations with each available accessory
          for (final a in accessories) {
            double accScore = baseScore + _daysSinceWornScore(a.lastWornDate) - (a.wearCount * 0.5);
            candidates.add(OutfitCandidate(u, l, f, a, accScore));
          }
        }
      }
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates;
  }

  /// Daily recommendation: local pre-scoring → top 5 → Gemini stylist.
  Future<List<RecommendedOutfit>> generateRecommendations({
    required bool isGoingOut,
    required String location,
    String? vibe,
  }) async {
    // Only fetch weather when actually heading out — saves a network call
    // (and avoids a pointless geocode with an empty location) when staying home.
    final WeatherData? weatherData =
        isGoingOut ? await _weather.getWeather(location) : null;
    final condition = weatherData?.condition ?? WeatherCondition.clear;

    final candidates = await _buildCandidates(
      isGoingOut: isGoingOut,
      weatherData: weatherData,
    );
    if (candidates.isEmpty) return []; // Caller handles empty state

    // Take top 5 candidates
    final topCandidates = candidates.take(5).toList();

    List<RecommendedOutfit> fallbackRecs() {
      return topCandidates.take(3).map((c) => RecommendedOutfit(
        upper: c.upper,
        lower: c.lower,
        footwear: c.footwear,
        accessory: c.accessory,
        description: 'A solid combination generated from your local wardrobe based on recent wear and weather.',
        isAiSuggested: false,
      )).toList();
    }

    // 4. Send to Gemini
    final apiKey = dotenv.isInitialized ? dotenv.env['GEMINI_API_KEY'] : null;
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here' || apiKey == 'your_real_api_key') {
      return fallbackRecs();
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: Schema(
            SchemaType.array,
            items: Schema(
              SchemaType.object,
              properties: {
                'option_index': Schema(SchemaType.integer,
                    description: 'Index of the candidate option chosen (0-based).'),
                'description': Schema(SchemaType.string,
                    description: 'Short 1-2 sentence styling justification.'),
              },
              requiredProperties: ['option_index', 'description'],
            ),
          ),
        ),
      );

      final candidateText = topCandidates.mapIndexed((i, c) {
        final accText = c.accessory != null ? ', Accessory: ${c.accessory!.name} (${c.accessory!.color})' : '';
        return 'Option $i: Upper: ${c.upper.name} (${c.upper.color}, ${c.upper.fit.name}), Lower: ${c.lower.name} (${c.lower.color}), Footwear: ${c.footwear.name}$accText';
      }).join('\n');

      final styleNotes = _profile?.styleNotes ?? '';
      final weatherLine = weatherData != null
          ? '${weatherData.temperature}°C, ${condition.label}'
          : 'Unknown';

      final prompt = '''
You are a personal stylist. I need an outfit recommendation for today.
Context: ${isGoingOut ? 'Going out to $location' : 'Staying home'}.
Weather: $weatherLine.
Vibe: ${vibe ?? 'Casual'}.
${styleNotes.isNotEmpty ? 'My style preferences: $styleNotes' : ''}

Here are the top candidates from my wardrobe (already filtered for warmth, laundry, and weather):
$candidateText

Pick the best 2 to 3 combinations from these options. For each, give a short, punchy 1-2 sentence explanation of why it works well together based on color pairing, the weather, and the vibe${styleNotes.isNotEmpty ? ', and my style preferences' : ''}.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      final String? responseText = response.text;
      if (responseText == null) throw Exception("No response text");

      // Tolerate code fences some models wrap JSON in.
      final cleaned = responseText
          .trim()
          .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();

      final Object? decoded = jsonDecode(cleaned);
      if (decoded is! List) throw Exception("Expected a JSON array");

      List<RecommendedOutfit> results = [];
      for (final item in decoded) {
        if (item is! Map) continue;
        final rawIndex = item['option_index'];
        final rawDesc = item['description'];
        if (rawIndex is! int || rawDesc is! String) continue;

        if (rawIndex >= 0 && rawIndex < topCandidates.length) {
          final c = topCandidates[rawIndex];
          results.add(RecommendedOutfit(
            upper: c.upper, 
            lower: c.lower, 
            footwear: c.footwear, 
            accessory: c.accessory,
            description: rawDesc,
            isAiSuggested: true,
          ));
        }
      }
      
      if (results.isEmpty) return fallbackRecs();
      return results;

    } catch (e) {
      debugPrint('Gemini API Error: $e');
      return fallbackRecs();
    }
  }

  /// Trip / weekly plan: N outfits where no item is repeated across the plan.
  Future<List<RecommendedOutfit>> generateOutfitPlan({
    required int count,
    required bool isGoingOut,
    required String location,
    String? vibe,
  }) async {
    final WeatherData? weatherData =
        isGoingOut ? await _weather.getWeather(location) : null;
    final candidates = await _buildCandidates(
      isGoingOut: isGoingOut,
      weatherData: weatherData,
    );
    if (candidates.isEmpty) return [];

    final usedIds = <int>{};
    final plan = <RecommendedOutfit>[];
    for (final c in candidates) {
      if (plan.length >= count) break;
      final ids = {
        c.upper.id,
        c.lower.id,
        c.footwear.id,
        if (c.accessory != null) c.accessory!.id,
      };
      if (ids.any(usedIds.contains)) continue;
      usedIds.addAll(ids);
      plan.add(RecommendedOutfit(
        upper: c.upper,
        lower: c.lower,
        footwear: c.footwear,
        accessory: c.accessory,
        description: 'Plan outfit ${plan.length + 1} — every item appears only once across this plan.',
        isAiSuggested: false,
      ));
    }
    return plan;
  }

  /// Records that an outfit was worn: bumps wear stats on every item and
  /// appends an entry to outfit history. Shared by Home and Planner.
  Future<void> logWornOutfit(
    RecommendedOutfit outfit, {
    required String destination,
    String? vibe,
  }) async {
    final ids = [
      outfit.upper.id,
      outfit.lower.id,
      outfit.footwear.id,
      if (outfit.accessory != null) outfit.accessory!.id,
    ];

    await WardrobeRepository(_db).markWorn(ids);

    await _db.into(_db.outfitLogs).insert(
          OutfitLogsCompanion.insert(
            date: DateTime.now(),
            items: ids.join(','),
            wasAiSuggested: drift.Value(outfit.isAiSuggested),
            vibeTag: drift.Value(vibe ?? ''),
            destination: drift.Value(destination),
          ),
        );
  }

  double _daysSinceWornScore(DateTime? lastWorn) {
    if (lastWorn == null) return 10.0;
    final days = DateTime.now().difference(lastWorn).inDays;
    return days.clamp(0, 30).toDouble() * 0.3; 
  }
}

extension IterableExtension<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T element) convert) sync* {
    var index = 0;
    for (var element in this) {
      yield convert(index++, element);
    }
  }
}
