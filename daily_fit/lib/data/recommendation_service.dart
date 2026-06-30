import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:drift/drift.dart' as drift;

import 'database.dart';
import 'database_provider.dart';
import 'wardrobe_repository.dart';
import 'weather_service.dart';
import '../models/enums.dart';

final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  final db = ref.watch(databaseProvider);
  final weather = ref.watch(weatherServiceProvider);
  return RecommendationService(db, weather);
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

  RecommendedOutfit({
    required this.upper,
    required this.lower,
    required this.footwear,
    this.accessory,
    required this.description,
  });
}

class RecommendationService {
  final AppDatabase _db;
  final WeatherService _weather;

  RecommendationService(this._db, this._weather);

  Future<List<RecommendedOutfit>> generateRecommendations({
    required bool isGoingOut,
    required String location,
    String? vibe,
  }) async {
    final weatherData = await _weather.getWeather(location);
    final targetWarmth = weatherData?.requiredWarmthLevel ?? 3;

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

    // 3. Generate Permutations & Score
    List<OutfitCandidate> candidates = [];
    for (final u in uppers) {
      for (final l in lowers) {
        for (final f in footwears) {
          // Add a "no accessory" permutation
          final baseItems = [u, l, f];
          double baseScore = baseItems.fold(0.0, (s, i) => s + _daysSinceWornScore(i.lastWornDate) - (i.wearCount * 0.5));
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
    
    // Take top 5 candidates
    final topCandidates = candidates.take(5).toList();

    List<RecommendedOutfit> fallbackRecs() {
      return topCandidates.take(3).map((c) => RecommendedOutfit(
        upper: c.upper,
        lower: c.lower,
        footwear: c.footwear,
        accessory: c.accessory,
        description: 'A solid combination generated from your local wardrobe based on recent wear and weather.',
      )).toList();
    }

    // 4. Send to Gemini
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here' || apiKey == 'your_real_api_key') {
      return fallbackRecs();
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final candidateText = topCandidates.mapIndexed((i, c) {
        final accText = c.accessory != null ? ', Accessory: ${c.accessory!.name} (${c.accessory!.color})' : '';
        return 'Option ${i}: Upper: ${c.upper.name} (${c.upper.color}, ${c.upper.fit.name}), Lower: ${c.lower.name} (${c.lower.color}), Footwear: ${c.footwear.name}$accText';
      }).join('\n');

      final prompt = '''
You are a personal stylist. I need an outfit recommendation for today.
Context: ${isGoingOut ? 'Going out to $location' : 'Staying home'}.
Weather: ${weatherData != null ? '${weatherData.temperature}°C' : 'Unknown'}.
Vibe: ${vibe ?? 'Casual'}.

Here are the top candidates from my wardrobe (already filtered for warmth and laundry):
$candidateText

Pick the best 2 to 3 combinations from these options. For each, give a short, punchy 1-2 sentence explanation of why it works well together based on color pairing, the weather, and the vibe.

Output STRICT JSON matching this exact array structure:
[
  {
    "option_index": 0,
    "description": "Short explanation why Option 0 is great."
  }
]
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      final String? responseText = response.text;
      if (responseText == null) throw Exception("No response text");

      final List<dynamic> jsonList = jsonDecode(responseText);
      List<RecommendedOutfit> results = [];
      
      for (final item in jsonList) {
        final int index = item['option_index'] as int;
        final String desc = item['description'] as String;
        
        if (index >= 0 && index < topCandidates.length) {
          final c = topCandidates[index];
          results.add(RecommendedOutfit(
            upper: c.upper, 
            lower: c.lower, 
            footwear: c.footwear, 
            accessory: c.accessory,
            description: desc
          ));
        }
      }
      
      if (results.isEmpty) return fallbackRecs();
      return results;

    } catch (e) {
      print('Gemini API Error: $e');
      return fallbackRecs();
    }
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
