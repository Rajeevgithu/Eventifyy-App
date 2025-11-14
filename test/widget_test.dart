import 'package:event_booking_app/main.dart';
import 'package:event_booking_app/pages/bottomnav.dart';
import 'package:event_booking_app/pages/OnboardingWrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  //--- Test 1: App Launch and Onboarding Check ---
  testWidgets('App launches and shows Onboarding Page 1 content', (WidgetTester tester) async {
    // 1. Pump the main application widget
    await tester.pumpWidget(const MyApp());
    // Wait for initial routing/auth check to complete (and land on onboarding)
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // 2. Verify the Onboarding Wrapper is the entry point
    expect(find.byType(OnboardingWrapper), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);

    // 3. Verify content of the first onboarding page (Page 1: "Welcome to EventFlow")
    // This confirms the PageView is on the first slide.
    expect(find.text("Welcome to EventFlow"), findsOneWidget);
    expect(find.text("Experience moments of culture and celebration, effortlessly."), findsOneWidget);

    // 4. Verify the "Next" button on Page 1 (assuming it's not the last page)
    expect(find.widgetWithText(ElevatedButton, "Next"), findsOneWidget);
  });

  //--- Test 2: Bottom Navigation Check (Fixed to test Bottomnav) ---
  testWidgets('Bottom navigation bar structure check', (WidgetTester tester) async {
    // 1. Directly test Bottomnav widget structure
    await tester.pumpWidget(
      const MaterialApp(
        // FIX: The home widget should be Bottomnav for this test.
        home: Bottomnav(),
      ),
    );
    await tester.pumpAndSettle();

    // 2. Check for the main screen container
    expect(find.byType(Scaffold), findsOneWidget);

    // 3. Assuming one of the navigation icons is Icons.book
    final bookIconFinder = find.byIcon(Icons.book);
    expect(bookIconFinder, findsOneWidget, reason: "Expected to find the 'book' icon in Bottomnav.");

    // 4. Test interaction (tapping the icon)
    await tester.tap(bookIconFinder);
    await tester.pumpAndSettle();

    expect(bookIconFinder, findsOneWidget);
  });
}