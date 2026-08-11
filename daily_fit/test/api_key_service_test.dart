import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_fit/data/api_key_service.dart';

/// In-memory fake so tests never touch the platform Keystore.
class _MemoryApiKeyService extends ApiKeyService {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String key) async => _value = key;

  @override
  Future<void> delete() async => _value = null;
}

void main() {
  test('notifier starts null and round-trips set/clear', () async {
    final container = ProviderContainer(
      overrides: [
        apiKeyServiceProvider.overrideWithValue(_MemoryApiKeyService()),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(geminiApiKeyProvider), isNull);

    await container.read(geminiApiKeyProvider.notifier).setKey('test-key-123');
    expect(container.read(geminiApiKeyProvider), 'test-key-123');

    await container.read(geminiApiKeyProvider.notifier).clear();
    expect(container.read(geminiApiKeyProvider), isNull);
  });

  test('loadFromStorage restores a persisted key', () async {
    final fake = _MemoryApiKeyService();
    await fake.write('persisted-key');
    final container = ProviderContainer(
      overrides: [apiKeyServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    expect(container.read(geminiApiKeyProvider), isNull);
    await container.read(geminiApiKeyProvider.notifier).loadFromStorage();
    expect(container.read(geminiApiKeyProvider), 'persisted-key');
  });

  test('setKey trims whitespace and ignores empty input', () async {
    final container = ProviderContainer(
      overrides: [
        apiKeyServiceProvider.overrideWithValue(_MemoryApiKeyService()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(geminiApiKeyProvider.notifier).setKey('  abc  ');
    expect(container.read(geminiApiKeyProvider), 'abc');

    await container.read(geminiApiKeyProvider.notifier).setKey('   ');
    expect(container.read(geminiApiKeyProvider), 'abc');
  });
}
