import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_booking_app/admin/upload_event.dart';
import 'package:event_booking_app/pages/home.dart';
import 'package:event_booking_app/pages/signup.dart';
import 'package:event_booking_app/services/auth.dart';
import 'package:event_booking_app/services/shared_pref.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  // SharedPreferenceHelper is not strictly needed here for auth checks, but keeping for reference
  final SharedPreferenceHelper _prefs = SharedPreferenceHelper();
  final AuthMethods _auth = AuthMethods();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    // Start checking user status after the splash screen animation completes
    Timer(const Duration(seconds: 3), checkUserStatus);
  }

  Future<void> checkUserStatus() async {
    final user = _auth.currentUser;

    // --- Core Logic Change for Correct Flow: Splash -> Signup -> Home ---

    // Case 1: No user is logged in at all. Go directly to Signup.
    if (user == null) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignupPage()),
        );
      }
      return;
    }

    // Case 2: A user IS logged in (Auth is complete), but we need to check if
    // the Firestore profile (signup/onboarding) was successfully completed.
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // IMPORTANT FIX: If the user is authenticated but the document is missing,
      // the signup process was incomplete. Send them back to Signup.
      if (!doc.exists) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SignupPage()),
          );
        }
        return;
      }

      // Case 3: User is logged in AND profile exists. Check role for final routing.
      final data = doc.data();

      if (data != null && data['role'] == 'admin') {
        // Admin user
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UploadEvent()),
          );
        }
      } else {
        // Regular user
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Home()),
          );
        }
      }
    } catch (e) {
      // If there's a Firebase/Firestore error while checking the profile,
      // assume failure and route to Signup to restart the process.
      debugPrint("Firestore check failed: $e");
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignupPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// Background Image (full screen, scaled properly)
          Image.asset(
            "assets/images/Event.jpg",
            width: size.width,
            height: size.height,
            fit: BoxFit.cover, // maintains aspect ratio and fills screen
          ),

          /// Dark Gradient Overlay for better text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),

          /// Main content with fade-in animation
          FadeTransition(
            opacity: _animation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Title
                  const Text(
                    "Event Booking",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.4,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 2),
                          blurRadius: 6,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  const Text(
                    "Experience Moments, Effortlessly",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Loading indicator
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
