import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  // Keys
  static const String userIdKey = "USERKEY";
  static const String userNameKey = "USERNAMEKEY";
  static const String userEmailKey = "USERMAILKEY";
  static const String userImageKey = "USERIMAGEKEY";
  static const String userRoleKey = "USERROLEKEY";

  // ===== SAVE USER DATA =====
  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userIdKey, userId);
  }

  Future<void> saveUserName(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userNameKey, userName);
  }

  Future<void> saveUserEmail(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userEmailKey, userEmail);
  }

  Future<void> saveUserImage(String userImage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userImageKey, userImage);
  }

  Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userRoleKey, role);
  }

  // ===== SAVE FULL PROFILE OR PARTIAL (OPTION 2) =====
  Future<void> saveUserProfile({
    String? id,
    String? name,
    String? email,
    String? image,
    String? role,
  }) async {
    if (id != null) await saveUserId(id);
    if (name != null) await saveUserName(name);
    if (email != null) await saveUserEmail(email);
    if (image != null) await saveUserImage(image);
    if (role != null) await saveUserRole(role);
  }

  // ===== GET USER DATA =====
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
    return prefs.getString(userRoleKey);
  }

  // ===== GET FULL PROFILE AS MAP =====
  Future<Map<String, String?>> getUserProfileMap() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "id": prefs.getString(userIdKey),
      "name": prefs.getString(userNameKey),
      "email": prefs.getString(userEmailKey),
      "image": prefs.getString(userImageKey),
      "role": prefs.getString(userRoleKey),
    };
  }

  // ===== DELETE USER PROFILE =====
  Future<void> deleteUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(userIdKey),
      prefs.remove(userNameKey),
      prefs.remove(userEmailKey),
      prefs.remove(userImageKey),
      prefs.remove(userRoleKey),
    ]);
  }

  // ===== CLEAR ALL USER DATA =====
  Future<void> clearUserData() async {
    await deleteUserProfile();
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
