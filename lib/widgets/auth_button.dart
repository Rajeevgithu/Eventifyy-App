import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthButton extends StatelessWidget {
  final String provider; // "google", "apple", "facebook"
  final VoidCallback onTap;

  const AuthButton({super.key, required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> providerData = {
      "google": {
        "text": "Continue with Google",
        "icon": "assets/images/google.png",
        "color": Colors.white,
        "textColor": const Color(0xff6351ec),
      },
      "apple": {
        "text": "Continue with Apple",
        "icon": "assets/images/apple.png",
        "color": Colors.black,
        "textColor": Colors.white,
      },
      "facebook": {
        "text": "Continue with Facebook",
        "icon": "assets/images/facebook.png",
        "color": const Color(0xff1877f2),
        "textColor": Colors.white,
      },
    };

    final data = providerData[provider]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: data["color"],
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(data["icon"], height: 28, width: 28),
            const SizedBox(width: 15),
            Text(
              data["text"],
              style: GoogleFonts.poppins(
                color: data["textColor"],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 1000.ms).slideY(begin: 0.3, end: 0);
  }
}
