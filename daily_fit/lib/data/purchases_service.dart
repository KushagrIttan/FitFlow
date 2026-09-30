import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// Entitlement id created in the RevenueCat dashboard.
/// Attach your Lifetime / Yearly / Monthly products to this entitlement.
const proEntitlementId = 'fitflow_pro';

const _placeholderKey = 'goog_placeholder_put_your_key_here';

/// RevenueCat SDK key.
///
/// Resolution order:
/// 1. `--dart-define=REVENUECAT_ANDROID_KEY=...` (CI / release builds)
/// 2. `.env` file (`REVENUECAT_ANDROID_KEY=...`, see `.env.example`)
/// 3. empty string (not configured → app runs in free/local mode).
///
/// Two key flavours exist: `test_...` (Test Store, debug only — the SDK
/// intentionally crashes in release builds with a test key) and `goog_...`
/// (Google Play, required for release builds).
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

/// True for Test Store keys (`test_...`), which only work in debug builds.
bool get isTestStoreKey => revenueCatAndroidKey().startsWith('test_');

/// True when a real key is present (not empty/placeholder).
/// Test keys count as configured — [PurchasesService.init] refuses them in
/// release builds to avoid the SDK's intentional release-mode crash.
bool isRevenueCatConfigured() {
  final key = revenueCatAndroidKey();
  return key.isNotEmpty && key != _placeholderKey;
}

/// Thin, defensive wrapper around the RevenueCat SDK.
///
/// Every method is safe to call when unconfigured or when the native
/// platform channel is unavailable (unit/widget tests): it logs and
/// returns a free-mode default instead of throwing.
///
/// Purchase UI goes through RevenueCat Paywalls
/// ([presentPaywall]/[presentCustomerCenter]) so pricing, trials and promo
/// offers stay remotely configurable in the dashboard.
class PurchasesService {
  bool _initialized = false;

  /// Called whenever CustomerInfo changes (purchase, restore, renewal).
  /// main() wires this to `ref.invalidate(isProProvider)`.
  void Function()? onCustomerInfoChanged;

  bool get isInitialized => _initialized;
  bool get isConfigured => isRevenueCatConfigured();

  void _notify() {
    try {
      onCustomerInfoChanged?.call();
    } catch (e) {
      debugPrint('RevenueCat notify failed: $e');
    }
  }

  /// Call once at startup (after `dotenv.load()`). Never throws.
  Future<void> init() async {
    if (_initialized) return;
    if (!isConfigured) {
      debugPrint('RevenueCat: no key configured — running in free mode. '
          'Copy .env.example to .env to enable Pro.');
      return;
    }
    if (kReleaseMode && isTestStoreKey) {
      debugPrint('RevenueCat: Test Store key in a release build — skipping '
          'configure (the SDK crashes on purpose with test keys in release). '
          'Pass a goog_... key via --dart-define=REVENUECAT_ANDROID_KEY=...');
      return;
    }
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
      await Purchases.configure(
        PurchasesConfiguration(revenueCatAndroidKey()),
      );
      // Live Pro-status updates (purchase / restore / renewal / expiry).
      // Fires only on CustomerInfo updates from SDK calls on this device.
      try {
        Purchases.addCustomerInfoUpdateListener((_) => _notify());
      } catch (e) {
        debugPrint('RevenueCat listener skipped: $e');
      }
      _initialized = true;
    } catch (e) {
      debugPrint('RevenueCat init skipped: $e');
    }
  }

  /// True when the `fitflow_pro` entitlement is active.
  /// False when unconfigured. Never throws.
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

  /// Latest CustomerInfo, or null when unavailable. Never throws.
  Future<CustomerInfo?> customerInfo() async {
    if (!isConfigured || !_initialized) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('RevenueCat customerInfo failed: $e');
      return null;
    }
  }

  /// Current offerings (Current = Lifetime + Yearly + Monthly packages).
  /// Null when unconfigured/offline. Never throws.
  Future<Offerings?> offerings() async {
    if (!isConfigured || !_initialized) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('RevenueCat offerings failed: $e');
      return null;
    }
  }

  /// Presents the RevenueCat Paywall for the current offering.
  /// Returns the resulting Pro status. Handles purchase, restore and
  /// dismiss internally — callers just refresh UI. Never throws.
  ///
  /// Requires a paywall + offering configured in the dashboard; with a
  /// Test Store key, test products work out of the box.
  Future<bool> presentPaywall() async {
    if (!isConfigured || !_initialized) return false;
    try {
      final result =
          await RevenueCatUI.presentPaywallIfNeeded(proEntitlementId);
      debugPrint('RevenueCat paywall result: $result');
    } catch (e) {
      debugPrint('RevenueCat paywall failed: $e');
      return false;
    }
    _notify();
    return isPro();
  }

  /// Presents Customer Center (manage subscription, restore, support,
  /// promo offers). Requires a Customer Center configured in the dashboard
  /// (RevenueCar Pro/Enterprise plan). Never throws.
  Future<void> presentCustomerCenter() async {
    if (!isConfigured || !_initialized) return;
    try {
      await RevenueCatUI.presentCustomerCenter(
        onRestoreCompleted: (_) => _notify(),
      );
    } catch (e) {
      debugPrint('RevenueCat customer center failed: $e');
    }
    _notify();
  }

  /// Restores past purchases, returns resulting Pro status. Never throws.
  Future<bool> restore() async {
    if (!isConfigured || !_initialized) return false;
    try {
      final info = await Purchases.restorePurchases();
      final ok =
          info.entitlements.all[proEntitlementId]?.isActive ?? false;
      _notify();
      return ok;
    } catch (e) {
      debugPrint('RevenueCat restore failed: $e');
      return false;
    }
  }

  /// Best practice: identify the user once you have a stable id so Pro
  /// follows them across devices. Optional — anonymous ids work otherwise.
  /// Never throws.
  Future<void> logIn(String appUserId) async {
    if (!isConfigured || !_initialized) return;
    try {
      await Purchases.logIn(appUserId);
      _notify();
    } catch (e) {
      debugPrint('RevenueCat logIn failed: $e');
    }
  }

  /// Clears the current identity (e.g. on account logout). Never throws.
  Future<void> logOut() async {
    if (!isConfigured || !_initialized) return;
    try {
      await Purchases.logOut();
      _notify();
    } catch (e) {
      debugPrint('RevenueCat logOut failed: $e');
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
