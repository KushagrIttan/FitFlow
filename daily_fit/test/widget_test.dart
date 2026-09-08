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

void main() {
  setUpAll(() {
    // Never attempt to fetch Google Fonts over the network in tests.
    GoogleFonts.config.allowRuntimeFetching = false;
    // Feedback f/x (sound + haptics) would hit platform channels in tests.
    Fx.enabled = false;
    // The shell's slowly-repeating gradient would make pumpAndSettle spin;
    // tell the app the OS prefers reduced motion so it renders the static
    // fallback background in tests.
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
  });

  testWidgets('first launch shows onboarding; completing it lands on Add Item',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
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

    // Onboarding screen, page 1.
    expect(find.text('Welcome to Daily Fit'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), '180cm');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Page 2: style notes.
    await tester.enterText(find.byType(TextField).at(0), 'Minimalist');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Page 3: location.
    await tester.enterText(find.byType(TextField).at(0), 'New York');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Page 4: finish.
    await tester.tap(find.text('Start Adding Items'));
    await tester.pumpAndSettle();

    // Redirect lands on the Add Item screen.
    expect(find.text('Add Item'), findsOneWidget);
  });

  testWidgets('onboarding is skipped once completed', (tester) async {
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

    expect(find.text('Welcome to Daily Fit'), findsNothing);
    expect(find.text("What's the vibe today?"), findsOneWidget);
  });
}
