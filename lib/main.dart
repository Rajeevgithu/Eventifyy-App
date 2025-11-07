import 'package:event_booking_app/admin/upload_event.dart';
import 'package:event_booking_app/pages/home.dart';
import 'package:event_booking_app/pages/login.dart';
import 'package:event_booking_app/pages/profile.dart';
import 'package:event_booking_app/pages/signup.dart';
import 'package:event_booking_app/pages/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe_mobile;

Future<void> main() async {
  // 1. Must be the first call in main
  WidgetsFlutterBinding.ensureInitialized();

  // 🧩 Load environment variables with error handling
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ .env file loaded successfully!");
  } catch (e) {
    debugPrint("❌ CRITICAL ERROR: Failed to load .env file: $e");
  }

  // Retrieve keys only AFTER loading dotenv
  final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? "";

  // Quick check for Cloudinary keys to aid debugging
  debugPrint("Cloudinary Cloud Name: ${dotenv.env['CLOUDINARY_CLOUD_NAME']}");
  debugPrint(
      "Cloudinary Upload Preset: ${dotenv.env['CLOUDINARY_UPLOAD_PRESET']}");

  // 🔥 Initialize Firebase and Stripe
  if (kIsWeb) {
    // NOTE: Replace these with actual non-public keys from your Firebase project config
    // This block is only for web builds.
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyABCUjsHya7Gsav4inFCRz7RITyiRuQKnI",
        authDomain: "event-booking-app-1fa34.firebaseapp.com",
        projectId: "event-booking-app-1fa34",
        storageBucket: "event-booking-app-1fa34.firebasestorage.app",
        messagingSenderId: "288536620731",
        appId: "1:288536620731:web:0c9b24cc91e788ea64039e",
        measurementId: "G-X0EBVM16S2",
      ),
    );

    debugPrint("✅ Firebase initialized for Web (Stripe web init skipped)");
  } else {
    // This block runs for Android/iOS (the emulator)
    await Firebase.initializeApp();

    // Initialize Stripe for Mobile
    stripe_mobile.Stripe.publishableKey = publishableKey;
    await stripe_mobile.Stripe.instance.applySettings();
    debugPrint("✅ Firebase + Stripe initialized for Mobile");
  }

  runApp(const MyApp());
}

// NOTE: The previous AuthGate widget was removed. The authentication check
// must now happen inside the SplashScreen to follow the required sequence:
// SplashScreen -> SignupPage (if not logged in) -> Home (if logged in or after signup)

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
      // Set the initial route to the splash screen
      initialRoute: '/splash',
      routes: {
        // The first screen
        '/splash': (context) => const SplashScreen(),

        // The authentication flow starts here:
        // After the splash screen delay is complete, the logic in SplashScreen
        // should check for the current user and:
        // 1. If user is logged in: Navigate to '/home'.
        // 2. If user is NOT logged in: Navigate to '/signup' (as requested).

        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),

        // Main App Content (only accessible after successful authentication)
        '/home': (context) => const Home(),
        '/profile': (context) => const Profile(),
        '/upload_event': (context) => const UploadEvent(),
      },
    );
  }
}
