import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_booking_app/services/auth.dart';
import 'package:event_booking_app/services/database.dart';
import 'package:event_booking_app/services/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart'; // for navigation back to login page

// Converted to a StatefulWidget to manage hover states
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // State variables for hover effects (primarily for web/desktop)
  bool _isSignupButtonHovered = false;
  bool _isLoginLinkHovered = false;

  // Helper to show SnackBar
  void _showSnackBar(String message,
      {SnackBarAction? action, Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        backgroundColor: backgroundColor ?? Colors.red,
        duration:
            const Duration(seconds: 4), // Increase duration for action SnackBar
      ),
    );
  }

  void _signUpUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill all fields", backgroundColor: Colors.orange);
      return;
    }

    // Simple password check (can be expanded)
    if (password.length < 6) {
      _showSnackBar("Password must be at least 6 characters long",
          backgroundColor: Colors.orange);
      return;
    }

    try {
      final auth = AuthMethods();
      final user = await auth.signUpWithEmail(
        email: email,
        password: password,
      );

      if (user != null) {
        // --- Successful Sign-up Logic ---

        // Update user profile with name and reload
        await user.updateDisplayName(name);
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;

        if (updatedUser != null) {
          // Save to SharedPrefs (using updatedUser for data safety)
          await SharedPreferenceHelper().saveUserId(updatedUser.uid);
          await SharedPreferenceHelper().saveUserName(name);
          await SharedPreferenceHelper().saveUserEmail(updatedUser.email ?? "");
          await SharedPreferenceHelper()
              .saveUserImage(updatedUser.photoURL ?? "");

          // Save to Firestore
          final userInfoMap = {
            "Name": name,
            "Email": updatedUser.email,
            "Image": updatedUser.photoURL ?? "",
            "Id": updatedUser.uid,
            "CreatedAt": FieldValue.serverTimestamp(),
          };
          await DatabaseMethods().addUserDetail(userInfoMap, updatedUser.uid);
        }

        if (mounted) {
          _showSnackBar("Signup successful! Redirecting...",
              backgroundColor: Colors.green);
          // Navigate to main app or home page
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (_) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // --- Specific Firebase Error Handling ---
      String errorMessage;
      SnackBarAction? action;
      Color? bgColor = Colors.red;

      if (e.code == 'email-already-in-use') {
        errorMessage =
            "This email is already registered. Please log in instead.";
        bgColor = const Color(0xff5a3efc); // Distinct color for action prompt
        action = SnackBarAction(
          label: 'Login',
          textColor: Colors.yellowAccent,
          onPressed: () {
            // Navigate to the login page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
        );
      } else if (e.code == 'network-request-failed') {
        // Handle the new network error
        errorMessage =
            "Connection failed. Please check your internet connection.";
        bgColor = Colors.orange;
      } else if (e.code == 'weak-password') {
        errorMessage =
            "The password provided is too weak. Choose a stronger one.";
      } else {
        // General Firebase error
        errorMessage =
            "Signup failed: ${e.message ?? 'An unknown error occurred'}";
      }

      _showSnackBar(errorMessage, action: action, backgroundColor: bgColor);
    } catch (e) {
      // --- General Catch-all Error Handling (for non-Firebase exceptions) ---
      _showSnackBar("An unexpected error occurred: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff7f5eff), Color(0xff5a3efc)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Foreground UI
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image with smooth rounded border and subtle shadow
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        "assets/images/Signup.jpg",
                        height: size.height * 0.35,
                        width: size.width * 0.7,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Title
                  Text(
                    "Create Account",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Name
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.poppins(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Full Name",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.95),
                      prefixIcon:
                          const Icon(Icons.person, color: Color(0xff5a3efc)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Email
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.poppins(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Email",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.95),
                      prefixIcon:
                          const Icon(Icons.email, color: Color(0xff5a3efc)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Password
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: GoogleFonts.poppins(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Password",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.95),
                      prefixIcon:
                          const Icon(Icons.lock, color: Color(0xff5a3efc)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign Up button with Hover effect
                  MouseRegion(
                    onEnter: (_) =>
                        setState(() => _isSignupButtonHovered = true),
                    onExit: (_) =>
                        setState(() => _isSignupButtonHovered = false),
                    child: ElevatedButton(
                      onPressed: _signUpUser,
                      style: ElevatedButton.styleFrom(
                        // Dynamic color change on hover
                        backgroundColor: _isSignupButtonHovered
                            ? Colors.deepPurple[100]
                            : Colors.white,
                        foregroundColor: Colors.deepPurpleAccent,
                        minimumSize: const Size(double.infinity, 50),
                        // Dynamic elevation change on hover
                        elevation: _isSignupButtonHovered ? 8 : 4,
                        shadowColor: Colors.black54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Sign Up",
                        style: GoogleFonts.poppins(
                          color: const Color(0xff5a3efc),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Back to Login link with Hover effect
                  MouseRegion(
                    onEnter: (_) => setState(() => _isLoginLinkHovered = true),
                    onExit: (_) => setState(() => _isLoginLinkHovered = false),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        splashFactory: NoSplash.splashFactory,
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.normal,
                            fontSize: 15,
                          ),
                          children: [
                            const TextSpan(text: "Already have an account? "),
                            TextSpan(
                              text: "Login",
                              style: GoogleFonts.poppins(
                                // Dynamic color change on hover
                                color: _isLoginLinkHovered
                                    ? Colors.yellowAccent
                                    : Colors.lightBlue.shade200,
                                fontWeight: FontWeight.bold,
                                // Underline effect on hover
                                decoration: _isLoginLinkHovered
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                                decorationColor: _isLoginLinkHovered
                                    ? Colors.yellowAccent
                                    : Colors.lightBlue.shade200,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
