import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  // Keys
  static const String userIdKey = "USERKEY";
  static const String userNameKey = "USERNAMEKEY";
  static const String userEmailKey = "USERMAILKEY";
  static const String userImageKey = "USERIMAGEKEY";
  static const String userRoleKey = "USERROLEKEY"; // Assuming a default role

  // --- Save Methods ---

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userIdKey, userId);
  }

  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userNameKey, name);
  }

  Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userEmailKey, email);
  }

  Future<void> saveUserImage(String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userImageKey, imageUrl);
  }

  // NOTE: This generalized method now only accepts simple strings for update.
  Future<void> saveUserProfile(
      {String? name, String? image, String? role}) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString(userNameKey, name);
    if (image != null) await prefs.setString(userImageKey, image);
    if (role != null) await prefs.setString(userRoleKey, role);
  }

  // --- Get Methods ---

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userNameKey);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userEmailKey);
  }

  Future<String?> getUserImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userImageKey);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    // Provide a default role if not found to prevent null errors
    return prefs.getString(userRoleKey) ?? "user";
  }

  // --- Clear Method ---
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    // Only remove user-specific keys, keep others if they exist
    await prefs.remove(userIdKey);
    await prefs.remove(userNameKey);
    await prefs.remove(userEmailKey);
    await prefs.remove(userImageKey);
    await prefs.remove(userRoleKey);
  }
}
