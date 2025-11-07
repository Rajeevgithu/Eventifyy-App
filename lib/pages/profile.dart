import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:event_booking_app/services/auth.dart';
import 'package:event_booking_app/services/shared_pref.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? profileUrl, name, email;
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  bool isLoading = false;
  String? userId;

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
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => isLoading = true);
    selectedImage = File(image.path);
    await _uploadImage();
  }

  Future<void> _uploadImage() async {
    if (selectedImage == null) return;
    try {
      final id = randomAlphaNumeric(10);
      final ref = FirebaseStorage.instance
          .ref()
          .child('profileImages')
          .child(id);
      final snapshot = await ref.putFile(selectedImage!);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await SharedPreferenceHelper().saveUserProfile(image: downloadUrl);
      setState(() {
        profileUrl = downloadUrl;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Upload Error: $e');
      setState(() => isLoading = false);
    }
  }

  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Change Photo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final newName = nameCtrl.text.trim();
              setState(() => name = newName);
              await SharedPreferenceHelper().saveUserName(newName);
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(10),
        elevation: 3,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.deepPurple),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (name == null || email == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurpleAccent, Colors.indigo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: _avatarImage(),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(5),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 22,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
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
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _showEditDialog,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurpleAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildInfoTile(Icons.person, 'Full Name', name!),
            _buildInfoTile(Icons.email, 'Email Address', email!),
            _buildInfoTile(
              Icons.description,
              'Terms & Conditions',
              'View details',
            ),

            const SizedBox(height: 20),

            // Delete Account
            GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete Account?'),
                    content: const Text('This action cannot be undone.'),
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
              },
              child: _buildInfoTile(
                Icons.delete,
                'Delete Account',
                'Remove permanently',
              ),
            ),

            // Log Out
            GestureDetector(
              onTap: () async {
                await AuthMethods().signOut();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (_) => false,
                );
              },
              child: _buildInfoTile(
                Icons.logout,
                'Log Out',
                'Sign out of your account',
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  ImageProvider _avatarImage() {
    if (selectedImage != null) return FileImage(selectedImage!);
    if (profileUrl != null && profileUrl!.isNotEmpty)
      return NetworkImage(profileUrl!);
    return const AssetImage('images/boy.jpg');
  }
}
