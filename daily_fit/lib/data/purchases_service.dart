import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Entitlement id created in the RevenueCat dashboard.
const proEntitlementId = 'pro';

const _placeholderKey = 'goog_placeholder_put_your_key_here';

/// RevenueCat *public* SDK key for Android.
///
/// Resolution order:
/// 1. `--dart-define=REVENUECAT_ANDROID_KEY=goog_...` (CI / release builds)
/// 2. `.env` file (`REVENUECAT_ANDROID_KEY=...`, see `.env.example`)
/// 3. empty string (not configured → app runs in free/local mode).
String revenueCatAndroidKey() {
  const fromDefine = String.fromEnvironment('REVENUECAT_ANDROID_KEY');
  if (fromDefine.isNotEmpty) return fromDefine;
  try {
    final fromEnv = dotenv.env['REVENUECAT_ANDROID_KEY'] ?? '';
    if (fromEnv.isNotEmpty) return fromEnv;
  } catch (_) {
    // dotenv not loaded (e.g. unit tests) — fall through to unconfigured.
  }
  return '';
}

/// True when a real publishable key is present (not empty/placeholder).
bool isRevenueCatConfigured() {
  final key = revenueCatAndroidKey();
  return key.isNotEmpty && key != _placeholderKey && key.startsWith('goog_');
}

/// Thin, defensive wrapper around the RevenueCat SDK.
///
/// Every method is safe to call when unconfigured or when the native
/// platform channel is unavailable (unit/widget tests): it logs and
/// returns a free-mode default instead of throwing.
class PurchasesService {
  bool _initialized = false;

  bool get isInitialized => _initialized;
  bool get isConfigured => isRevenueCatConfigured();

  /// Call once at startup (after `dotenv.load()`). Never throws.
  Future<void> init() async {
    if (_initialized) return;
    if (!isConfigured) {
      debugPrint('RevenueCat: no key configured — running in free mode. '
          'Copy .env.example to .env to enable Pro.');
      return;
    }
    try {
      await Purchases.setLogLevel(LogLevel.warn);
      await Purchases.configure(
        PurchasesConfiguration(revenueCatAndroidKey()),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('RevenueCat init skipped: $e');
    }
  }

  /// True when the `pro` entitlement is active. False when unconfigured.
  /// Never throws.
  Future<bool> isPro() async {
    if (!isConfigured || !_initialized) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.all[proEntitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('RevenueCat isPro check failed: $e');
      return false;
    }
  }

  /// Current offerings, or null when unavailable. Never throws.
  Future<Offerings?> offerings() async {
    if (!isConfigured || !_initialized) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('RevenueCat offerings failed: $e');
      return null;
    }
  }

  /// Purchases [package], then returns the resulting Pro status.
  /// Returns false on cancel/error. Never throws.
  Future<bool> purchasePackage(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      return await isPro();
    } catch (e) {
      debugPrint('RevenueCat purchase failed/cancelled: $e');
      return false;
    }
  }

  /// Restores past purchases, returns resulting Pro status. Never throws.
  Future<bool> restore() async {
    if (!isConfigured || !_initialized) return false;
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.all[proEntitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('RevenueCat restore failed: $e');
      return false;
    }
  }
}

final purchasesServiceProvider =
    Provider<PurchasesService>((ref) => PurchasesService());

/// Current Pro status (false in free mode / tests). Refresh with
/// `ref.invalidate(isProProvider)` after purchase/restore.
final isProProvider = FutureProvider<bool>((ref) async {
  return ref.watch(purchasesServiceProvider).isPro();
});

/// Current RevenueCat offerings (null when unconfigured/offline).
final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  return ref.watch(purchasesServiceProvider).offerings();
});
