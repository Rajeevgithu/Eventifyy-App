// main.dart

import 'package:event_booking_app/admin/upload_event.dart';
import 'package:event_booking_app/pages/OnboardingWrapper.dart'; // ✅ Imported
import 'package:event_booking_app/pages/bottomnav.dart';
import 'package:event_booking_app/pages/login.dart';
import 'package:event_booking_app/pages/profile.dart';
import 'package:event_booking_app/pages/signup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe_mobile;

// ✅ Import your generated Firebase options file
import 'firebase_options.dart';

Future<void> main() async {
  // 1️⃣ Make sure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2️⃣ Load environment variables safely
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ .env file loaded successfully!");
  } catch (e) {
    debugPrint("❌ Failed to load .env file: $e");
  }

  // Retrieve Stripe publishable key after loading dotenv
  final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? "";

  // Optional sanity check for Cloudinary vars
  debugPrint(
      "🌩️ Cloudinary Cloud Name: ${dotenv.env['CLOUDINARY_CLOUD_NAME']}");
  debugPrint(
      "🌩️ Cloudinary Upload Preset: ${dotenv.env['CLOUDINARY_UPLOAD_PRESET']}");

  // 3️⃣ Initialize Firebase for the current platform
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("🔥 Firebase initialized successfully!");
  } catch (e) {
    debugPrint("❌ Firebase initialization failed: $e");
  }

  // 4️⃣ Initialize Stripe for mobile only
  if (!kIsWeb) {
    stripe_mobile.Stripe.publishableKey = publishableKey;
    await stripe_mobile.Stripe.instance.applySettings();
    debugPrint("💳 Stripe initialized for mobile.");
  } else {
    debugPrint("💻 Web build detected – skipping mobile Stripe setup.");
  }

  // 5️⃣ Launch the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Booking App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff6351ec)),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      // 🏁 This is correct: starts with the OnboardingWrapper
      initialRoute: '/onboarding',
      routes: {
        // This directs the app to start with the multi-page onboarding flow
        '/onboarding': (context) => const OnboardingWrapper(),
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const Bottomnav(),
        '/profile': (context) => const Profile(),
        '/upload_event': (context) => const UploadEvent(),
      },
    );
  }
}