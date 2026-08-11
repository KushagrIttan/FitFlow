import 'package:flutter_test/flutter_test.dart';

import 'package:daily_fit/data/weather_service.dart';

void main() {
  group('WeatherData.requiredWarmthLevel', () {
    test('freezing maps to 5 (very warm)', () {
      expect(WeatherData(temperature: -10, weatherCode: 0).requiredWarmthLevel, 5);
      expect(WeatherData(temperature: 4.9, weatherCode: 0).requiredWarmthLevel, 5);
    });

    test('chilly maps to 4', () {
      expect(WeatherData(temperature: 5, weatherCode: 0).requiredWarmthLevel, 4);
      expect(WeatherData(temperature: 14.9, weatherCode: 0).requiredWarmthLevel, 4);
    });

    test('mild maps to 3', () {
      expect(WeatherData(temperature: 15, weatherCode: 0).requiredWarmthLevel, 3);
      expect(WeatherData(temperature: 21.9, weatherCode: 0).requiredWarmthLevel, 3);
    });

    test('warm maps to 2', () {
      expect(WeatherData(temperature: 22, weatherCode: 0).requiredWarmthLevel, 2);
      expect(WeatherData(temperature: 27.9, weatherCode: 0).requiredWarmthLevel, 2);
    });

    test('hot maps to 1 (lightest)', () {
      expect(WeatherData(temperature: 28, weatherCode: 0).requiredWarmthLevel, 1);
      expect(WeatherData(temperature: 45, weatherCode: 0).requiredWarmthLevel, 1);
    });
  });

  group('WeatherData.condition', () {
    test('clear and partly cloudy', () {
      expect(WeatherData(temperature: 20, weatherCode: 0).condition, WeatherCondition.clear);
      expect(WeatherData(temperature: 20, weatherCode: 1).condition, WeatherCondition.clear);
      expect(WeatherData(temperature: 20, weatherCode: 2).condition, WeatherCondition.cloudy);
      expect(WeatherData(temperature: 20, weatherCode: 3).condition, WeatherCondition.cloudy);
      expect(WeatherData(temperature: 20, weatherCode: 45).condition, WeatherCondition.cloudy);
    });

    test('rain codes (drizzle, rain, showers)', () {
      for (final code in [51, 55, 61, 63, 65, 67, 80, 82]) {
        expect(WeatherData(temperature: 15, weatherCode: code).condition,
            WeatherCondition.rain,
            reason: 'code $code should be rain');
      }
    });

    test('snow codes', () {
      for (final code in [71, 73, 75, 77, 85, 86]) {
        expect(WeatherData(temperature: 0, weatherCode: code).condition,
            WeatherCondition.snow,
            reason: 'code $code should be snow');
      }
    });

    test('thunderstorm codes', () {
      expect(WeatherData(temperature: 20, weatherCode: 95).condition, WeatherCondition.storm);
      expect(WeatherData(temperature: 20, weatherCode: 99).condition, WeatherCondition.storm);
    });
  });
}
