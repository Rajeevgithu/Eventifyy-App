import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // REQUIRED for updatePhotoURL
import 'package:flutter/material.dart';
import 'package:event_booking_app/services/auth.dart';
import 'package:event_booking_app/services/shared_pref.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; // New import for byte handling

// REMOVED: import 'dart:io';
// REMOVED: import 'package:random_string/random_string.dart';
// REMOVED: import 'package:firebase_storage/firebase_storage.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? profileUrl, name, email;
  final ImagePicker _picker = ImagePicker();
  Uint8List? selectedImageBytes; // Changed type to handle bytes
  String? selectedImagePath; // To hold the path temporarily for the FileImage preview
  bool isLoading = false;
  String? userId;

  final Color _primaryColor = const Color(0xff6351ec); // Deep Purple Accent

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    profileUrl = await SharedPreferenceHelper().getUserImage();
    name = await SharedPreferenceHelper().getUserName();
    email = await SharedPreferenceHelper().getUserEmail();
    userId = await SharedPreferenceHelper().getUserId();
    setState(() {});
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      isLoading = true;
      selectedImagePath = image.path; // Save path for preview
    });

    // Read the file as bytes, avoiding the dart:io File class in the State
    selectedImageBytes = await image.readAsBytes();

    await _uploadImage(image.name); // Pass the image name for the mime type
  }

  // 🔄 UPDATED FUNCTION: Uploads image to Cloudinary using BYTES
  Future<void> _uploadImage(String fileName) async {
    if (selectedImageBytes == null || userId == null) {
      setState(() => isLoading = false);
      return;
    }

    final String? cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final String? uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

    if (cloudName == null || uploadPreset == null) {
      debugPrint('Upload Error: Cloudinary environment variables not set!');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cloudinary setup failed. Check .env file.')),
        );
      }
      return;
    }

    final String uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'event_booking_profiles';

      // 🛑 KEY CHANGE: Using fromBytes instead of fromPath
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          selectedImageBytes!,
          filename: fileName, // Use the actual file name
          // Mime type can be inferred, but specifying is safer
          // contentType: MediaType('image', 'jpeg'),
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final result = json.decode(responseData);
        final downloadUrl = result['secure_url'] as String;

        // Update Firebase Authentication profile
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(downloadUrl);

        // Update Firestore user document
        await FirebaseFirestore.instance.collection("users").doc(userId).update({
          'ProfilePic': downloadUrl,
        });

        // Update shared preferences (Assumes saveUserImage method exists)
        await SharedPreferenceHelper().saveUserImage(downloadUrl);

        if (mounted) {
          setState(() {
            profileUrl = downloadUrl;
            isLoading = false;
            selectedImageBytes = null; // Clear bytes after successful upload
            selectedImagePath = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!'), backgroundColor: Colors.green),
          );
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        debugPrint('Cloudinary Upload Failed with Status ${response.statusCode}: $errorBody');
        throw Exception('Cloudinary upload failed.');
      }
    } catch (e) {
      debugPrint('Upload Error: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update picture: ${e.toString()}')),
        );
      }
    }
  }

  // New function to handle name update via dialog
  Future<void> _showNameEditDialog() async {
    final nameCtrl = TextEditingController(text: name);

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, nameCtrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != name) {
      await SharedPreferenceHelper().saveUserName(newName);
      // Update Firestore
      await FirebaseFirestore.instance.collection("users").doc(userId).update({
        'Name': newName,
      });

      setState(() => name = newName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle, {VoidCallback? onTap, bool isLogout = false}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isLogout ? Colors.redAccent : _primaryColor,
        size: 28,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isLogout ? Colors.redAccent : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
      trailing: onTap != null && !isLogout
          ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (name == null || email == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xff6351ec))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for contrast
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 👤 Modern Header Section
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, Colors.indigo.shade600],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Profile Picture
                      GestureDetector(
                        onTap: isLoading ? null : _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: _avatarImage(),
                        ),
                      ),
                      // Loading Indicator
                      if (isLoading)
                        const Positioned.fill(
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          ),
                        ),
                      // Camera Icon
                      if (!isLoading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: _primaryColor, width: 2),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Name and Email
                  Text(
                    name!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Edit Button
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _showNameEditDialog,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Name'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ⚙️ Account Settings Section
            _buildSectionHeader('Account Information'),
            _buildInfoTile(
              Icons.person_outline,
              'Full Name',
              name!,
            ),
            const Divider(height: 0, indent: 20, endIndent: 20),
            _buildInfoTile(
              Icons.email_outlined,
              'Email Address',
              email!,
            ),

            const SizedBox(height: 20),

            // 🔒 Legal & General Section
            _buildSectionHeader('General'),
            _buildInfoTile(
              Icons.policy_outlined,
              'Terms & Conditions',
              'Review legal agreements',
              onTap: () {
                // TODO: Implement navigation to Terms & Conditions page
              },
            ),
            const Divider(height: 0, indent: 20, endIndent: 20),
            _buildInfoTile(
              Icons.help_outline,
              'Help Center',
              'Find answers to your questions',
              onTap: () {
                // TODO: Implement navigation to Help Center
              },
            ),

            const SizedBox(height: 30),

            // 🚪 Actions Section
            _buildInfoTile(
              Icons.logout,
              'Log Out',
              'Sign out of your account',
              isLogout: true,
              onTap: () async {
                await AuthMethods().signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                        (_) => false,
                  );
                }
              },
            ),
            const Divider(height: 0, indent: 20, endIndent: 20),
            _buildInfoTile(
              Icons.delete_forever,
              'Delete Account',
              'Remove your account permanently',
              isLogout: true,
              onTap: _showDeleteConfirmation,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Helper to determine the image source for the CircleAvatar
  ImageProvider _avatarImage() {
    if (selectedImageBytes != null) {
      // 🛑 KEY CHANGE: Use MemoryImage for temporary preview from bytes
      return MemoryImage(selectedImageBytes!);
    }
    if (profileUrl != null && profileUrl!.isNotEmpty)
      return NetworkImage(profileUrl!);
    // 💡 IMPROVEMENT: Use a placeholder image from assets if possible
    return const AssetImage('images/boy.jpg');
  }

  // Helper function for delete confirmation logic
  Future<void> _showDeleteConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'Are you sure you want to delete your account? This action is irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthMethods().deleteUser(context);
    }
  }
}