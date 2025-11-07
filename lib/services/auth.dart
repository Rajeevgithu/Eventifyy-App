import 'package:event_booking_app/pages/bottomnav.dart';
import 'package:event_booking_app/services/database.dart';
import 'package:event_booking_app/services/shared_pref.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthMethods {
  // -------------------- Firebase --------------------
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // -------------------- Current User --------------------
  User? get currentUser => _auth.currentUser;
  Future<User?> getCurrentUser() async => _auth.currentUser;

  // -------------------- Google Sign-In (Firebase only) --------------------
  /// Use this when you have the user's Google ID token & access token
  Future<void> signInWithGoogleIdToken({
    required String idToken,
    required String accessToken,
    required BuildContext context,
  }) async {
    try {
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return;

      // Save locally
      await SharedPreferenceHelper().saveUserId(user.uid);
      await SharedPreferenceHelper().saveUserName(user.displayName ?? "User");
      await SharedPreferenceHelper().saveUserEmail(user.email ?? "");
      await SharedPreferenceHelper().saveUserImage(user.photoURL ?? "");

      // Save to Firestore
      final userInfoMap = {
        "Name": user.displayName,
        "Email": user.email,
        "Image": user.photoURL,
        "Id": user.uid,
        "CreatedAt": FieldValue.serverTimestamp(),
      };
      await DatabaseMethods().addUserDetail(userInfoMap, user.uid);

      // Navigate
      if (context.mounted) {
        // *** POTENTIAL FIX: Assuming the widget in bottomnav.dart is named BottomNav ***
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  const BottomAppBar()), // Changed BottomAppBar to BottomNav
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              "Logged in successfully!",
              style: TextStyle(fontSize: 18),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Firebase Google Sign-In Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Sign-In failed: ${e.toString()}"),
          ),
        );
      }
    }
  }

  // -------------------- Email/Password Sign-In --------------------
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint("Email Sign-In Error: $e");
      rethrow;
    }
  }

  // -------------------- Email/Password Sign-Up --------------------
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint("Email Sign-Up Error: $e");
      rethrow;
    }
  }

  // -------------------- Sign Out --------------------
  Future<void> signOut() async {
    await _auth.signOut();
    await SharedPreferenceHelper().clearAll();
  }

  // -------------------- Delete User --------------------
  Future<void> deleteUser(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await DatabaseMethods().deleteUser(user.uid); // Firestore doc
      await user.delete(); // Firebase Auth
      await SharedPreferenceHelper().clearAll();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Account deleted successfully."),
          ),
        );
      }
    } catch (e) {
      debugPrint("Delete Account Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Failed to delete account: ${e.toString()}"),
          ),
        );
      }
    }
  }
}
