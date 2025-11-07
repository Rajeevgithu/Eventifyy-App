import 'dart:io';
import 'dart:typed_data'; // Required for Uint8List
import 'package:flutter/foundation.dart'
    show kIsWeb; // Required for platform check

import 'package:event_booking_app/services/cloudinary_service.dart';
import 'package:event_booking_app/services/database.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:random_string/random_string.dart';

class UploadEvent extends StatefulWidget {
  const UploadEvent({super.key});

  @override
  State<UploadEvent> createState() => _UploadEventState();
}

class _UploadEventState extends State<UploadEvent> {
  // Controllers
  final TextEditingController namecontroller = TextEditingController();
  final TextEditingController pricecontroller = TextEditingController();
  final TextEditingController locationcontroller = TextEditingController();
  final TextEditingController detailcontroller = TextEditingController();

  // Categories
  final List<String> eventcategory = ["Music", "Food", "Clothing", "Festival"];
  String? value;

  // Image picker state
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  Uint8List? webImage; // Store image bytes for web display and upload

  bool isLoading = false; // <-- loading state

  @override
  void dispose() {
    namecontroller.dispose();
    pricecontroller.dispose();
    locationcontroller.dispose();
    detailcontroller.dispose();
    super.dispose();
  }

  // Unified Image Picker
  Future<void> getImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        // For web, read the image as bytes (Uint8List)
        final bytes = await image.readAsBytes();
        setState(() {
          webImage = bytes;
          selectedImage = null; // Ensure File is null for web
        });
      } else {
        // For mobile/desktop, use the File path
        setState(() {
          selectedImage = File(image.path);
          webImage = null; // Ensure bytes are null for mobile
        });
      }
    }
  }

  // Date and time pickers
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 00);

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) setState(() => selectedDate = pickedDate);
  }

  String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return DateFormat('hh:mm a').format(dateTime);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (pickedTime != null) setState(() => selectedTime = pickedTime);
  }

  Future<void> _uploadEvent() async {
    // 1. Validation check
    if ((selectedImage == null && webImage == null) ||
        namecontroller.text.isEmpty ||
        pricecontroller.text.isEmpty ||
        locationcontroller.text.isEmpty ||
        value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and select an image."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String? imageUrl;

      // 2. Upload image
      if (kIsWeb) {
        imageUrl = await CloudinaryService.uploadImageBytes(webImage!);
      } else {
        imageUrl = await CloudinaryService.uploadImageFile(selectedImage!);
      }

      if (imageUrl == null) {
        throw "Image upload failed. CloudinaryService returned null.";
      }

      // 3. Prepare data and upload to Firestore
      String id = randomAlphaNumeric(10);
      Map<String, dynamic> uploadevent = {
        "Image": imageUrl,
        "Name": namecontroller.text,
        "Price": pricecontroller.text,
        "Location": locationcontroller.text,
        "Category": value,
        "Detail": detailcontroller.text,
        "Date": DateFormat('yyyy-MM-dd').format(selectedDate),
        "Time": formatTimeOfDay(selectedTime),
      };

      await DatabaseMethods().addEvent(uploadevent, id);

      // 4. Success feedback and cleanup
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Event Uploaded Successfully!"),
        ),
      );

      // Clear fields on success
      setState(() {
        namecontroller.clear();
        pricecontroller.clear();
        locationcontroller.clear();
        detailcontroller.clear();
        selectedImage = null;
        webImage = null;
        value = null;
        selectedDate = DateTime.now();
        selectedTime = const TimeOfDay(hour: 10, minute: 00);
      });
    } catch (e) {
      // 5. Error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading event: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Upload New Event",
          style: TextStyle(
            color: Color(0xff6351ec),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Image Selector
            GestureDetector(
              onTap: getImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: (selectedImage != null && !kIsWeb)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(selectedImage!, fit: BoxFit.cover),
                      )
                    : (webImage != null && kIsWeb)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.memory(webImage!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            "Select Event Image",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // 📝 Event Name
            const Text(
              "Event Name",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextFormField(
              controller: namecontroller,
              decoration: _inputDecoration("Enter Event Name"),
            ),
            const SizedBox(height: 15),

            // 💰 Price
            const Text(
              "Price",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextFormField(
              controller: pricecontroller,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("Enter Price (e.g., 50.00)"),
            ),
            const SizedBox(height: 15),

            // 📍 Location
            const Text(
              "Location",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextFormField(
              controller: locationcontroller,
              decoration: _inputDecoration("Enter Location"),
            ),
            const SizedBox(height: 15),

            // 🏷️ Category Dropdown
            const Text(
              "Category",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  hint: const Text("Select Category"),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: eventcategory.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (String? newvalue) {
                    setState(() {
                      value = newvalue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 📅 Date & Time Picker
            Row(
              children: [
                Expanded(
                  child: _buildDateTimePicker(
                    Icons.calendar_month,
                    "Date",
                    DateFormat('dd MMM yyyy').format(selectedDate),
                    _pickDate,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildDateTimePicker(
                    Icons.access_time,
                    "Time",
                    formatTimeOfDay(selectedTime),
                    _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // 📝 Detail/Description
            const Text(
              "Detail",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextFormField(
              controller: detailcontroller,
              maxLines: 4,
              decoration: _inputDecoration("Enter Event Details/Description"),
            ),
            const SizedBox(height: 30),

            // ⬆️ Upload Button
            Center(
              child: Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xff6351ec),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: MaterialButton(
                    onPressed: isLoading ? null : _uploadEvent,
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Upload Event",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function for text input decoration
  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xff6351ec), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
    );
  }

  // Helper function for date/time display boxes
  Widget _buildDateTimePicker(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xff6351ec)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
