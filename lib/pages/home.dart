import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_booking_app/pages/categories_event.dart';
import 'package:event_booking_app/pages/detail_page.dart';
import 'package:event_booking_app/services/database.dart';
import 'package:event_booking_app/services/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Stream<QuerySnapshot>? eventStream;
  String? userName;
  String? currentLocation;

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadEvents();
    _determinePosition();
  }

  // Load user's name from SharedPreferences
  Future<void> loadUserData() async {
    userName = await SharedPreferenceHelper().getUserName();
    setState(() {});
  }

  // Load events from Firestore
  Future<void> loadEvents() async {
    // You are using an async function to set a Stream, which is slightly unusual
    // but works if `DatabaseMethods().getAllEvents()` is correctly defined
    // to return a Stream<QuerySnapshot>.
    eventStream = DatabaseMethods().getAllEvents();
    if (mounted) setState(() {});
  }

  // Get user location (with permission)
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        currentLocation = "Location disabled";
      });
      return;
    }

    // Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          currentLocation = "Permission denied";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        currentLocation = "Permission denied forever";
      });
      return;
    }

    // Get position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Get placemark (address) from coordinates
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final Placemark place = placemarks.first;
      setState(() {
        currentLocation =
            "${place.locality ?? place.subAdministrativeArea ?? "Unknown"}, ${place.country ?? ""}";
      });
    }
  }

  // ------------------------- EVENT LIST -------------------------
  Widget _buildEventList() {
    return StreamBuilder<QuerySnapshot>(
      stream: eventStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No upcoming events found."));
        }

        final events = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final ds = events[index];

            // ⭐️ ERROR FIX: Safely retrieve the document data map.
            // This prevents the "Bad state: field 'X' does not exist" error.
            final data = ds.data() as Map<String, dynamic>?;

            if (data == null) {
              // Should not happen for valid documents, but safe check to skip invalid docs
              return const SizedBox();
            }

            // Safely access data using the 'data' map and providing default values.
            // If the key doesn't exist in the map, data["Key"] returns null,
            // and the ?? operator provides the default.
            final String name = data["Name"] as String? ?? "Untitled";
            final String location = data["Location"] as String? ?? "Unknown";
            final String image = data["Image"] as String? ?? "";
            final String detail = data["Detail"] as String? ?? "";
            final String date = data["Date"] as String? ?? "";
            final String price = data["Price"] as String? ?? "0";

            DateTime? parsedDate;
            try {
              // Note: date format must be ISO 8601 compatible for this to work
              parsedDate = DateTime.parse(date);
            } catch (_) {
              // Date parsing failed, possibly due to a missing/invalid 'Date' field.
            }

            if (parsedDate == null || DateTime.now().isAfter(parsedDate)) {
              return const SizedBox(); // Skip invalid or past events
            }

            String formattedDate = DateFormat("MMM dd").format(parsedDate);

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPage(
                      date: date,
                      detail: detail,
                      image: image,
                      location: location,
                      name: name,
                      price: price,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🖼 Event Image
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: image.isNotEmpty
                              ? Image.network(
                                  image,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  "images/event.jpg",
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              formattedDate,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 📄 Event Name + Price
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // ❌ FIX: Corrected String interpolation for price
                        Text(
                          "₹$price",
                          style: const TextStyle(
                            color: Color(0xff6351ec),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 📍 Location
                  Padding(
                    padding: const EdgeInsets.only(left: 25, bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 5),
                        Text(
                          location,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------- CATEGORY TILE -------------------------
  Widget _buildCategoryTile(String name, String image, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(image, height: 35, width: 35, fit: BoxFit.cover),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------- UI BUILD -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffe3e6ff), Color(0xfff1f3ff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📍 Location
              Row(
                children: [
                  const Icon(Icons.location_on_outlined),
                  const SizedBox(width: 5),
                  Text(
                    currentLocation ?? "Fetching location...",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 👋 Greeting
              Text(
                "Hello, ${userName ?? 'User'}!",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Here are some events near you 👇",
                style: TextStyle(
                  color: Colors.blue[900],
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // 🔍 Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.search_outlined),
                    border: InputBorder.none,
                    hintText: "Search for events...",
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 🎨 Categories
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryTile("Music", "assets/images/music.png", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CategoriesEvent(eventcategory: "Music"),
                        ),
                      );
                    }),
                    _buildCategoryTile("Clothing", "assets/images/tshirt.png",
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CategoriesEvent(eventcategory: "Clothing"),
                        ),
                      );
                    }),
                    _buildCategoryTile("Festival", "assets/images/confetti.png",
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CategoriesEvent(eventcategory: "Festival"),
                        ),
                      );
                    }),
                    _buildCategoryTile("Food", "assets/images/dish.png", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CategoriesEvent(eventcategory: "Food"),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 📅 Upcoming Events Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Upcoming Events",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "See all",
                    style: TextStyle(color: Colors.black54, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 🧾 Event List
              _buildEventList(),
            ],
          ),
        ),
      ),
    );
  }
}
