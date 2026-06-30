import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

class WeatherData {
  final double temperature;
  final int weatherCode;
  
  WeatherData({required this.temperature, required this.weatherCode});
  
  // A simple mapping of temperature to the app's 1-5 warmth level scale
  // 1 = Cool (needs high warmth), 5 = Hot (needs low warmth)
  int get requiredWarmthLevel {
    if (temperature < 5) return 5; // Freezing, very warm clothing needed
    if (temperature < 15) return 4; // Chilly
    if (temperature < 22) return 3; // Mild
    if (temperature < 28) return 2; // Warm
    return 1; // Hot, minimal warmth needed
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
      print('Weather fetch error: $e');
      return null;
    }
  }
}
