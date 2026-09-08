import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// A detected physical place, reverse-geocoded to a display name the weather
/// service can forward-geocode (e.g. "Kolkata, West Bengal, India").
class DetectedPlace {
  final String name;
  final double latitude;
  final double longitude;

  const DetectedPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

/// Thrown with a user-facing message when location cannot be resolved
/// (services off, permission denied, geocoder failure).
class LocationUnavailableException implements Exception {
  final String message;
  const LocationUnavailableException(this.message);

  @override
  String toString() => message;
}

/// Resolves the user's current position (GPS/network) into a place name.
/// Permission is requested on first use if it has not been granted yet.
class LocationService {
  /// Returns the nearest city/region name, or throws
  /// [LocationUnavailableException] with a message safe to show to the user.
  Future<DetectedPlace> detectCurrentPlace() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationUnavailableException(
          'Location services are turned off — enable them in your phone '
          'settings, then tap the pin to detect your city.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationUnavailableException(
          'Location permission was denied — allow location access (or just '
          'type your city below) and tap the pin to detect it.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );

    final place = await _placeName(position.latitude, position.longitude);
    return DetectedPlace(
      name: place,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<String> _placeName(double latitude, double longitude) async {
    try {
      final marks = await placemarkFromCoordinates(latitude, longitude);
      if (marks.isNotEmpty) {
        final m = marks.first;
        final city = _firstNonEmpty([
          m.locality,
          m.subAdministrativeArea,
          m.administrativeArea,
        ]);
        final region = _firstNonEmpty([m.administrativeArea, m.country]);
        final name = [city, if (region != null && region != city) region]
            .whereType<String>()
            .join(', ');
        if (name.isNotEmpty) return name;
      }
    } catch (e) {
      debugPrint('Reverse geocode failed: $e');
    }
    // Coordinates are fine for the weather API even without a pretty name.
    return '${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}