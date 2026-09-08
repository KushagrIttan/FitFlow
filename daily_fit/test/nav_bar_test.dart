import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_fit/main.dart';
import 'package:daily_fit/data/database.dart';
import 'package:daily_fit/data/database_provider.dart';
import 'package:daily_fit/data/seed_data.dart';
import 'package:daily_fit/data/user_profile_service.dart';
import 'package:daily_fit/core/fx.dart';
import 'package:daily_fit/ui/screens/home_screen.dart';
import 'package:daily_fit/ui/screens/wardrobe_screen.dart';
import 'package:daily_fit/ui/screens/add_item_screen.dart';
import 'package:daily_fit/ui/screens/laundry_screen.dart';
import 'package:daily_fit/ui/screens/settings_screen.dart';
import 'package:daily_fit/ui/widgets/liquid_glass_nav_bar.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    Fx.enabled = false;
  });

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    await seedDatabase(db);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWith((ref) => db),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DailyFitApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  int navIndex(WidgetTester tester) =>
      tester.widget<LiquidGlassNavBar>(find.byType(LiquidGlassNavBar)).currentIndex;

  testWidgets('bottom nav switches every tab and keeps the selection in sync',
      (tester) async {
    await pumpApp(tester);

    // Home first.
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(navIndex(tester), 0);

    await tester.tap(find.byIcon(Icons.checkroom_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(WardrobeScreen), findsOneWidget);
    expect(navIndex(tester), 1);

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    expect(find.byType(AddItemScreen), findsOneWidget);
    expect(navIndex(tester), 2);

    await tester.tap(find.byIcon(Icons.local_laundry_service_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(LaundryScreen), findsOneWidget);
    expect(navIndex(tester), 3);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(navIndex(tester), 4);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(navIndex(tester), 0);
  });

  testWidgets('long-press lifts the bubble and dropping on a tab navigates',
      (tester) async {
    await pumpApp(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(navIndex(tester), 0);

    // Press the Add tab, hold past the lift delay, then glide to Laundry.
    final add = tester.getCenter(find.byIcon(Icons.add_circle_outline));
    final laundry = tester.getCenter(find.byIcon(Icons.local_laundry_service_outlined));
    final slot = laundry.dx - add.dx;

    final gesture = await tester.startGesture(add);
    await tester.pump(const Duration(milliseconds: 600)); // long-press
    await gesture.moveBy(Offset(slot, 0));
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byType(LaundryScreen), findsOneWidget);
    expect(navIndex(tester), 3);
  });

  testWidgets('long-press dropped on the same tab does not navigate',
      (tester) async {
    await pumpApp(tester);

    final home = tester.getCenter(find.byIcon(Icons.home));
    final gesture = await tester.startGesture(home);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(Offset(2, 0));
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(navIndex(tester), 0);
  });
}