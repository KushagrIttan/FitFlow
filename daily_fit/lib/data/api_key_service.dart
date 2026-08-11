import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keyGemini = 'gemini_api_key';

/// Stores the Gemini API key encrypted on-device (Android Keystore /
/// iOS Keychain). Never plaintext, never in the app bundle.
class ApiKeyService {
  ApiKeyService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _keyGemini);
  Future<void> write(String key) => _storage.write(key: _keyGemini, value: key);
  Future<void> delete() => _storage.delete(key: _keyGemini);
}

final apiKeyServiceProvider = Provider<ApiKeyService>((ref) => ApiKeyService());

/// Current Gemini API key (null = not configured → local-only mode).
/// Initial state is null; main() loads the persisted value before runApp.
final geminiApiKeyProvider =
    NotifierProvider<GeminiApiKeyNotifier, String?>(GeminiApiKeyNotifier.new);

class GeminiApiKeyNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  Future<void> loadFromStorage() async {
    final stored = await ref.read(apiKeyServiceProvider).read();
    if (stored != null && stored.isNotEmpty) state = stored;
  }

  Future<void> setKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return;
    await ref.read(apiKeyServiceProvider).write(trimmed);
    state = trimmed;
  }

  Future<void> clear() async {
    await ref.read(apiKeyServiceProvider).delete();
    state = null;
  }
}
