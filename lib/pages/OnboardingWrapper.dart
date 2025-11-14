

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_booking_app/pages/bottomnav.dart';
import 'package:event_booking_app/admin/upload_event.dart';
import 'package:event_booking_app/pages/signup.dart';
import 'package:event_booking_app/pages/onboarding.dart'; // ✅ Corrected Import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// --- Onboarding Wrapper (Main Flow Controller) ---

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  int currentIndex = 0;
  final PageController _controller = PageController();
  static const Color primaryColor = Color(0xff6351ec);
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    checkAuthenticationStatus();
  }

  Future<void> checkAuthenticationStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await routeUserByRole(user);
    } else {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
  }

  Future<void> routeUserByRole(User user) async {
    if (!mounted) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      Widget nextPage;
      if (data != null && data['role'] == 'admin') {
        nextPage = const UploadEvent();
      } else {
        nextPage = const Bottomnav();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    } catch (e) {
      debugPrint("Error routing user: $e");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignupPage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        itemCount: contents.length,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        itemBuilder: (_, i) {
          return OnboardingPage(
            content: contents[i],
            isLastPage: i == contents.length - 1,
            onNext: () {
              if (i < contents.length - 1) {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupPage()),
                );
              }
            },
          );
        },
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            contents.length,
                (index) => buildDot(index, context),
          ),
        ),
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return Container(
      height: 10,
      width: currentIndex == index ? 25 : 10,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: currentIndex == index ? primaryColor : Colors.grey.shade300,
      ),
    );
  }
}

// Individual Page Widget
class OnboardingPage extends StatelessWidget {
  final OnboardingContent content;
  final bool isLastPage;
  final VoidCallback onNext;
  static const Color primaryColor = Color(0xff6351ec);

  const OnboardingPage({
    super.key,
    required this.content,
    required this.isLastPage,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Spacer(flex: 1),
          // 🖼️ Image
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                content.imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const Spacer(flex: 1),
          // 📝 Title
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 15),
          // 📖 Description
          Text(
            content.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const Spacer(flex: 2),
          // 🚀 Button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: Text(
                isLastPage ? "Get Started" : "Next",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                ),
              ),
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}