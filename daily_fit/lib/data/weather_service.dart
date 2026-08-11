import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

/// High-level condition derived from the WMO weather_code.
enum WeatherCondition {
  clear,
  cloudy,
  rain,
  snow,
  storm;

  String get label => switch (this) {
        WeatherCondition.clear => 'clear skies',
        WeatherCondition.cloudy => 'overcast',
        WeatherCondition.rain => 'rain',
        WeatherCondition.snow => 'snow',
        WeatherCondition.storm => 'thunderstorms',
      };
}

class WeatherData {
  final double temperature;
  final int weatherCode;

  WeatherData({required this.temperature, required this.weatherCode});

  // A simple mapping of temperature to the app's 1-5 warmth level scale.
  // 1 = Lightest (hot weather), 5 = Very warm (freezing weather).
  // Matches the "Warmth Level (1: Cool, 5: Very Warm)" slider in Add Item.
  int get requiredWarmthLevel {
    if (temperature < 5) return 5; // Freezing, very warm clothing needed
    if (temperature < 15) return 4; // Chilly
    if (temperature < 22) return 3; // Mild
    if (temperature < 28) return 2; // Warm
    return 1; // Hot, minimal warmth needed
  }

  /// Maps the WMO weather code to a coarse condition the recommendation
  /// engine can act on (rain → prefer jackets, snow → warmer uppers).
  WeatherCondition get condition {
    // https://open-meteo.com/en/docs (WMO codes)
    if (weatherCode == 0 || weatherCode == 1) return WeatherCondition.clear;
    if (weatherCode == 2 || weatherCode == 3 || weatherCode == 45 || weatherCode == 48) {
      return WeatherCondition.cloudy;
    }
    // Drizzle / rain / freezing rain / showers.
    if ((weatherCode >= 51 && weatherCode <= 67) ||
        (weatherCode >= 80 && weatherCode <= 82)) {
      return WeatherCondition.rain;
    }
    // Snow / snow showers.
    if ((weatherCode >= 71 && weatherCode <= 77) ||
        (weatherCode >= 85 && weatherCode <= 86)) {
      return WeatherCondition.snow;
    }
    // Thunderstorms.
    if (weatherCode >= 95 && weatherCode <= 99) return WeatherCondition.storm;
    return WeatherCondition.cloudy;
  }
}

class WeatherService {
  Future<WeatherData?> getWeather(String locationQuery) async {
    try {
      // 1. Geocode the location
      final geoUrl = Uri.parse('https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(locationQuery)}&count=1&format=json');
      final geoRes = await http.get(geoUrl);
      
      if (geoRes.statusCode != 200) return null;
      
      final geoData = jsonDecode(geoRes.body);
      if (!geoData.containsKey('results') || (geoData['results'] as List).isEmpty) {
        return null; // Location not found
      }
      
      final lat = geoData['results'][0]['latitude'];
      final lon = geoData['results'][0]['longitude'];
      
      // 2. Fetch Weather
      final weatherUrl = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code');
      final weatherRes = await http.get(weatherUrl);
      
      if (weatherRes.statusCode != 200) return null;
      
      final weatherData = jsonDecode(weatherRes.body);
      final current = weatherData['current'];
      
      return WeatherData(
        temperature: (current['temperature_2m'] as num).toDouble(),
        weatherCode: current['weather_code'] as int,
      );
    } catch (e) {
      debugPrint('Weather fetch error: $e');
      return null;
    }
  }
}
