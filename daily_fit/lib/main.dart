import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/wardrobe_screen.dart';
import 'ui/screens/add_item_screen.dart';
import 'ui/screens/laundry_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/planner_screen.dart';
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
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/wardrobe',
            builder: (context, state) => const WardrobeScreen(),
          ),
          GoRoute(
            path: '/add',
            builder: (context, state) => const AddItemScreen(),
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
            builder: (context, state) => const LaundryScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
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

class AppShell extends ConsumerWidget {
  final Widget child;
  
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laundryCount = ref
        .watch(wardrobeItemsProvider)
        .maybeWhen(
          data: (items) => items.where((i) => i.inLaundry).length,
          orElse: () => 0,
        );

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.checkroom_outlined), activeIcon: Icon(Icons.checkroom), label: 'Wardrobe'),
          const BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), activeIcon: Icon(Icons.add_circle), label: 'Add'),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: laundryCount > 0,
              label: Text('$laundryCount'),
              child: const Icon(Icons.local_laundry_service_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: laundryCount > 0,
              label: Text('$laundryCount'),
              child: const Icon(Icons.local_laundry_service),
            ),
            label: 'Laundry',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
        ],
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
