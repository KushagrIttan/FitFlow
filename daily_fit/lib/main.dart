import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/liquid_glass_nav_bar.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/wardrobe_screen.dart';
import 'ui/screens/add_item_screen.dart';
import 'ui/screens/laundry_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/planner_screen.dart';
import 'ui/screens/analytics_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'data/user_profile_service.dart';
import 'data/notification_service.dart';
import 'data/database.dart';
import 'data/wardrobe_repository.dart';
import 'data/theme_mode_provider.dart';
import 'data/api_key_service.dart';

import 'data/database_provider.dart';
import 'data/seed_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  // Create provider container to seed DB before running app
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  final db = container.read(databaseProvider);
  await seedDatabase(db);
  // Load the Gemini API key stored in secure storage (if any) so
  // recommendations can use it from the very first frame.
  await container.read(geminiApiKeyProvider.notifier).loadFromStorage();
  // Local notification reminders (safe no-op if the platform rejects it).
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }
  
  runApp(UncontrolledProviderScope(
    container: container,
    child: const DailyFitApp(),
  ));
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Fade + soft-zoom page used for bottom-nav tab switches.
_FadeZoomPage<Object?> _fadeZoomPage(Widget child, GoRouterState state) =>
    _FadeZoomPage<Object?>(key: state.pageKey, child: child);

/// A [Page] whose route fades the child in while it zooms from 0.95 up to
/// 1.0 and the incoming surface de-blurs — a soft, glassy page swap.
class _FadeZoomPage<T> extends Page<T> {
  final Widget child;

  const _FadeZoomPage({
    super.key,
    super.name,
    super.arguments,
    required this.child,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (_, animation, __, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (context, c) {
            final t = curved.value;
            return Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.95 + 0.05 * t,
                alignment: Alignment.center,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: 6 * (1 - t),
                    sigmaY: 6 * (1 - t),
                  ),
                  child: c,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final userProfile = ref.watch(userProfileServiceProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isOnboarding = state.uri.toString() == '/onboarding';
      if (!userProfile.isOnboardingComplete && !isOnboarding) {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                _fadeZoomPage(const HomeScreen(), state),
          ),
          GoRoute(
            path: '/wardrobe',
            pageBuilder: (context, state) =>
                _fadeZoomPage(const WardrobeScreen(), state),
          ),
          GoRoute(
            path: '/add',
            pageBuilder: (context, state) =>
                _fadeZoomPage(const AddItemScreen(), state),
          ),
          GoRoute(
            path: '/edit',
            builder: (context, state) =>
                AddItemScreen(initialItem: state.extra as ClothingItem?),
          ),
          GoRoute(
            path: '/plan',
            builder: (context, state) => const PlannerScreen(),
          ),
          GoRoute(
            path: '/laundry',
            pageBuilder: (context, state) =>
                _fadeZoomPage(const LaundryScreen(), state),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                _fadeZoomPage(const SettingsScreen(), state),
          ),
        ],
      ),
    ],
  );
});

class DailyFitApp extends ConsumerWidget {
  const DailyFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'Daily Fit',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// The fixed set of bottom-nav "tab" routes. Back on these routes never
/// exits the app — it returns to the Home tab first (double-back to exit).
const _tabPaths = {'/', '/wardrobe', '/add', '/laundry', '/settings'};

/// Shell backdrop gradient, shared by the page background and the glass
/// bar's ambient tint (avg of the two bottom gradient stops, sampled where
/// the bar sits).
const _shellDarkGradient = [Color(0xFF0F0F0F), Color(0xFF15151A), Color(0xFF0B0B0E)];
const _shellLightGradient = [Color(0xFFF6F6F4), Color(0xFFEDEDE9), Color(0xFFF4F3EF)];
const _navTintDark = Color(0xFF101014);
const _navTintLight = Color(0xFFF0F0EC);

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isTab = _tabPaths.contains(location);
    // Detail pages (e.g. /edit) are pushed and may pop naturally.
    final canPopRoute = !isTab;

    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || isTab == false) return;
        if (location == '/') {
          _handleExitRequest();
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
        body: _ShellBackground(
          child: Padding(
            // Content slides right up to (and can drift behind) the floating
            // glass bar — no dead strip between bar and page.
            padding: const EdgeInsets.only(bottom: 12),
            child: widget.child,
          ),
        ),
        bottomNavigationBar: LiquidGlassNavBar(
          currentIndex: _calculateSelectedIndex(context),
          laundryCount: ref
              .watch(wardrobeItemsProvider)
              .maybeWhen(data: (items) => items.where((i) => i.inLaundry).length, orElse: () => 0),
          onDestinationSelected: (index) => _onItemTapped(index, context),
          tint: Theme.of(context).brightness == Brightness.dark
              ? _navTintDark
              : _navTintLight,
        ),
      ),
    );
  }

  void _handleExitRequest() {
    final now = DateTime.now();
    final recent = _lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2);

    if (recent) {
      SystemNavigator.pop();
      return;
    }
    _lastBackPress = now;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/wardrobe')) return 1;
    if (location.startsWith('/add')) return 2;
    if (location.startsWith('/laundry')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/wardrobe');
        break;
      case 2:
        context.go('/add');
        break;
      case 3:
        context.go('/laundry');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }
}

/// Animated ambient backdrop for the shell: a slowly drifting colour field
/// (base gradient + three soft moving light blobs) painted on its own layer
/// behind the page. Falls back to a static gradient when the OS has motion
/// disabled.
class _ShellBackground extends StatefulWidget {
  final Widget child;
  const _ShellBackground({required this.child});

  @override
  State<_ShellBackground> createState() => _ShellBackgroundState();
}

class _ShellBackgroundState extends State<_ShellBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _phase;
  bool _animated = true;

  @override
  void initState() {
    super.initState();
    _phase = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationState();
  }

  void _syncAnimationState() {
    final ok = !MediaQuery.disableAnimationsOf(context);
    if (!ok) {
      _phase.stop();
      _animated = false;
    } else if (!_animated || !_phase.isAnimating) {
      _animated = true;
      _phase.repeat();
    }
  }

  @override
  void dispose() {
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _LiveGradientPainter(
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  primary: scheme.primary,
                  tertiary: scheme.tertiary,
                  phase: _animated ? _phase : null,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

/// Paints the live background: static base gradient, two drifting colour
/// blobs and a warm glow anchored near the bottom nav bar.
class _LiveGradientPainter extends CustomPainter {
  final bool isDark;
  final Color primary;
  final Color tertiary;

  /// 0..1 loop position (null in the static fallback path).
  final Animation<double>? phase;

  _LiveGradientPainter({
    required this.isDark,
    required this.primary,
    required this.tertiary,
    required this.phase,
  }) : super(repaint: phase);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final t = phase?.value ?? 0.0;

    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? _shellDarkGradient
            : _shellLightGradient,
      ).createShader(rect);
    canvas.drawRect(rect, base);

    double wobble(double base, double amp, double speed, double ph) =>
        base + amp * math.sin(2 * math.pi * t * speed + ph);

    void blob(double cx, double cy, double radius, Color color) {
      final center = Offset(size.width * cx, size.height * cy);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: isDark ? 0.10 : 0.12),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawRect(rect, paint);
    }

    // Primary accent drifting upper-left.
    blob(
      wobble(0.18, 0.12, 0.5, 0.0),
      wobble(0.22, 0.10, 0.4, 1.2),
      size.width * 0.55,
      primary,
    );
    // Tertiary accent drifting lower-right.
    blob(
      wobble(0.86, 0.10, 0.35, 3.0),
      wobble(0.82, 0.12, 0.3, 4.5),
      size.width * 0.6,
      tertiary,
    );
    // Warm glow suspended just above the nav bar.
    blob(
      wobble(0.5, 0.10, 0.25, 1.8),
      1.04,
      size.width * 0.72,
      primary,
    );
  }

  @override
  bool shouldRepaint(covariant _LiveGradientPainter old) =>
      old.isDark != isDark ||
      old.primary != primary ||
      old.tertiary != tertiary;
}
