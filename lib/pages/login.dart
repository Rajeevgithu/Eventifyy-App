import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_booking_app/services/auth.dart';

import 'package:event_booking_app/services/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Converted to a StatefulWidget to manage hover states and loading state
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // State variables for hover effects (primarily for web/desktop)
  bool _isLoginHovered = false;
  bool _isSignupHovered = false;
  // New state for loading indicator
  bool _isLoading = false;

  // Helper to show SnackBar with custom color
  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter both email and password.",
          backgroundColor: Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final auth = AuthMethods();
      final user = await auth.signInWithEmail(
        email: email,
        password: password,
      );

      if (user != null) {
        // --- Successful Login Logic ---

        // Fetch user data from Firestore to get Name, which isn't always on the Auth object
        String userName = user.displayName ?? "";

        try {
          // Attempt to fetch name from Firestore if not available on Auth object
          if (userName.isEmpty) {
            final docSnapshot = await FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .get();
            if (docSnapshot.exists) {
              userName = docSnapshot.data()?['Name'] ?? user.email ?? "";
            }
          }
        } catch (e) {
          // Log Firestore error but don't block login
          print("Firestore fetch error after login: $e");
        }

        // Save user info locally
        // *** THE ERROR IS LIKELY TO OCCUR IN ONE OF THESE CALLS, OR IN A WRAPPER AROUND THEM. ***
        await SharedPreferenceHelper().saveUserId(user.uid);
        await SharedPreferenceHelper().saveUserEmail(
          user.email ?? "",
        );
        // Use the determined name for local storage
        await SharedPreferenceHelper().saveUserName(
          userName,
        );
        await SharedPreferenceHelper().saveUserImage(
          user.photoURL ?? "",
        );

        // Navigate to main app
        if (!context.mounted) return;
        _showSnackBar("Login successful!", backgroundColor: Colors.green);
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home', // This will be intercepted by AuthGate
          (_) => false,
        );
      } else {
        // Should only happen if Firebase Auth returned null without an exception (rare, but good practice)
        _showSnackBar("Login failed. User object is null.",
            backgroundColor: Colors.red);
      }
    } on FirebaseAuthException catch (e) {
      // --- Specific Firebase Error Handling ---
      String errorMessage;
      Color? bgColor = Colors.red;

      if (e.code == 'invalid-credential' ||
          e.code == 'user-not-found' ||
          e.code == 'wrong-password') {
        // Firebase often uses 'invalid-credential' for both bad email or bad password for security
        errorMessage =
            "Invalid login credentials. Please check your email and password.";
      } else if (e.code == 'network-request-failed') {
        errorMessage =
            "Connection failed. Please check your internet connection.";
        bgColor = Colors.orange;
      } else {
        // General Firebase error
        errorMessage =
            "Login failed: ${e.message ?? 'An unknown error occurred'}";
      }

      _showSnackBar(errorMessage, backgroundColor: bgColor);
    } catch (e) {
      // --- General Catch-all Error Handling (THIS IS WHERE YOUR TYPE CAST ERROR WAS PRINTED) ---
      _showSnackBar("An unexpected error occurred: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading regardless of success/failure
        });
      }
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
                        "assets/images/Login.jpg",
                        height: size.height * 0.35,
                        width: size.width * 0.8,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Title
                  Text(
                    "Welcome Back!",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Email field
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

                  // Password field
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

                  // Email/Password Login button with Hover effect and Loading
                  MouseRegion(
                    onEnter: (_) => setState(() => _isLoginHovered = true),
                    onExit: (_) => setState(() => _isLoginHovered = false),
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _loginUser, // Disable button when loading
                      style: ElevatedButton.styleFrom(
                        // Dynamic color change on hover
                        backgroundColor: _isLoginHovered
                            ? Colors.deepPurple[100]
                            : Colors.white,
                        foregroundColor: Colors.deepPurpleAccent,
                        minimumSize: const Size(double.infinity, 50),
                        // Dynamic elevation change on hover
                        elevation: _isLoginHovered ? 8 : 4,
                        shadowColor: Colors.black54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Color(0xff5a3efc),
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              "Login",
                              style: GoogleFonts.poppins(
                                color: const Color(0xff5a3efc),
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Sign-up redirect with Hover effect
                  MouseRegion(
                    onEnter: (_) => setState(() => _isSignupHovered = true),
                    onExit: (_) => setState(() => _isSignupHovered = false),
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              // Disable button when loading
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignupPage()),
                              );
                            },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        // Ensure the whole link area reacts
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
                            const TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: "Sign Up",
                              style: GoogleFonts.poppins(
                                // Dynamic color change on hover
                                color: _isSignupHovered
                                    ? Colors.yellowAccent
                                    : Colors.lightBlue.shade200,
                                fontWeight: FontWeight.bold,
                                // Underline effect on hover
                                decoration: _isSignupHovered
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                                decorationColor: _isSignupHovered
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
