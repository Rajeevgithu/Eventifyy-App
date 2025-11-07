// services/cloudinary_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? "";
  static String get _uploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? "";

  /// Helper to decode and print the failure details
  static void _logFailure(http.Response response, String type) {
    String errorMessage = "Unknown error format.";
    try {
      final data = json.decode(response.body);
      errorMessage = data['error']['message'] ?? response.body;
    } catch (_) {
      errorMessage = response.body;
    }
    print("--- CLOUDINARY $type UPLOAD FAILED ---");
    print("Status Code: ${response.statusCode}");
    print("Cloud Name: $_cloudName, Preset: $_uploadPreset");
    print("Cloudinary Error Message: $errorMessage");
    print("---------------------------------------");
  }

  /// **For Mobile/Desktop (dart:io.File)**: Upload an image file to Cloudinary.
  static Future<String?> uploadImageFile(File imageFile) async {
    try {
      if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
        print("Cloudinary Error: Configuration missing in .env");
        return null;
      }

      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
      );

      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath("file", imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['secure_url'];
      } else {
        _logFailure(response, "FILE");
        return null;
      }
    } catch (e) {
      print("Cloudinary FILE upload error (Exception): $e");
      return null;
    }
  }

  /// **For Flutter Web (Uint8List)**: Upload image bytes to Cloudinary.
  static Future<String?> uploadImageBytes(Uint8List imageBytes) async {
    try {
      if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
        print("Cloudinary Error: Configuration missing in .env");
        return null;
      }

      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
      );

      final base64Image = base64Encode(imageBytes);
      final response = await http.post(
        url,
        body: {
          "file": "data:image/png;base64,$base64Image",
          "upload_preset": _uploadPreset,
          // 🛑 FIX REVERSAL: The 'display_name' parameter is NOT allowed with your unsigned preset ('flutter_upload').
          // It was the source of the previous error (slashes), but now it's the source of this new 400 error.
          // Removed: "display_name": "event_image",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['secure_url'];
      } else {
        _logFailure(response, "BYTES");
        return null;
      }
    } catch (e) {
      print("Cloudinary BYTES upload error (Exception): $e");
      return null;
    }
  }
}
