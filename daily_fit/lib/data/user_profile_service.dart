import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main');
});

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserProfileService(prefs);
});

class UserProfileService {
  final SharedPreferences _prefs;
  
  UserProfileService(this._prefs);

  static const _keyOnboardingComplete = 'onboarding_complete';
  static const _keyHeight = 'user_height';
  static const _keyWeight = 'user_weight';
  static const _keyStyleNotes = 'user_style_notes';
  static const _keyDefaultLocation = 'user_default_location';
  static const _keyReminderEnabled = 'reminder_enabled';
  static const _keyReminderHour = 'reminder_hour';
  static const _keyReminderMinute = 'reminder_minute';

  bool get isOnboardingComplete => _prefs.getBool(_keyOnboardingComplete) ?? false;
  
  Future<void> completeOnboarding() async {
    await _prefs.setBool(_keyOnboardingComplete, true);
  }

  String get height => _prefs.getString(_keyHeight) ?? '';
  String get weight => _prefs.getString(_keyWeight) ?? '';
  String get styleNotes => _prefs.getString(_keyStyleNotes) ?? '';
  String get defaultLocation => _prefs.getString(_keyDefaultLocation) ?? '';

  Future<void> saveProfile({
    String? height,
    String? weight,
    String? styleNotes,
    String? defaultLocation,
  }) async {
    if (height != null) await _prefs.setString(_keyHeight, height);
    if (weight != null) await _prefs.setString(_keyWeight, weight);
    if (styleNotes != null) await _prefs.setString(_keyStyleNotes, styleNotes);
    if (defaultLocation != null) await _prefs.setString(_keyDefaultLocation, defaultLocation);
  }

  bool get reminderEnabled => _prefs.getBool(_keyReminderEnabled) ?? false;

  /// Stored reminder time, or null when never set.
  TimeOfDay? get reminderTime {
    final hour = _prefs.getInt(_keyReminderHour);
    final minute = _prefs.getInt(_keyReminderMinute);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setReminderEnabled(bool enabled) =>
      _prefs.setBool(_keyReminderEnabled, enabled);

  Future<void> setReminderTime(TimeOfDay time) async {
    await _prefs.setInt(_keyReminderHour, time.hour);
    await _prefs.setInt(_keyReminderMinute, time.minute);
  }
}
