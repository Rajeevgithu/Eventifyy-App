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

  // State and controller for the search functionality
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  // Theme colors for professionalism
  static const Color primaryColor = Color(0xff6351ec);
  static const Color lightBg = Color(0xFFF7F7F9);

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadEvents();
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load user's name from SharedPreferences
  Future<void> loadUserData() async {
    userName = await SharedPreferenceHelper().getUserName();
    setState(() {});
  }

  // Load events from Firestore
  void loadEvents() {
    eventStream = DatabaseMethods().getAllEvents();
    if (mounted) setState(() {});
  }

  // Get user location (with permission)
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        currentLocation = "Location disabled";
      });
      return;
    }

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

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final Placemark place = placemarks.first;
      setState(() {
        // Use city/locality name for nearby filtering logic
        currentLocation = "${place.locality ?? place.subAdministrativeArea ?? "Unknown City"}";
      });
    }
  }

  // 🔔 Notification Icon Action
  void _onNotificationPressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notifications"),
        content: const Text("This is where your event notifications would appear!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close", style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  // ------------------------- EVENT LIST with Filtering -------------------------
  Widget _buildEventList({bool nearbyOnly = false}) {
    // 💡 Logic for Nearby Events section
    String listTitle;
    if (searchQuery.isNotEmpty) {
      listTitle = "Search Results";
    } else if (nearbyOnly) {
      listTitle = "Nearby Events in $currentLocation";
    } else {
      listTitle = "Upcoming Events";
    }

    return StreamBuilder<QuerySnapshot>(
      stream: eventStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No $listTitle found."));
        }

        final allEvents = snapshot.data!.docs;

        // --- FILTERING LOGIC ---
        final filterQuery = searchQuery.toLowerCase();
        final currentCity = currentLocation?.toLowerCase() ?? "";

        final filteredEvents = allEvents.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) return false;

          final String name = (data["Name"] as String? ?? "").toLowerCase();
          final String location = (data["Location"] as String? ?? "").toLowerCase();
          final String date = (data["Date"] as String? ?? "");

          // 1. Skip invalid or past events
          DateTime? parsedDate;
          try {
            parsedDate = DateTime.parse(date);
          } catch (_) {}
          if (parsedDate == null || DateTime.now().isAfter(parsedDate)) {
            return false;
          }

          // 2. Apply NEARBY filter (if enabled)
          if (nearbyOnly) {
            // Basic check: Event location contains the fetched city name
            if (currentCity.isNotEmpty && !location.contains(currentCity)) {
              return false;
            }
          }

          // 3. Apply SEARCH filter
          if (searchQuery.isNotEmpty) {
            return name.contains(filterQuery) || location.contains(filterQuery);
          }

          return true; // Show all if no search query or nearby filter (depending on call)
        }).toList();
        // --- END FILTERING LOGIC ---


        if (filteredEvents.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: Text(
                searchQuery.isNotEmpty
                    ? "No events match '$searchQuery'."
                    : "No events found for $listTitle.",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredEvents.length,
          itemBuilder: (context, index) {
            final ds = filteredEvents[index];
            final data = ds.data() as Map<String, dynamic>?;

            if (data == null) return const SizedBox();

            final String name = data["Name"] as String? ?? "Untitled";
            final String location = data["Location"] as String? ?? "Unknown";
            final String image = data["Image"] as String? ?? "";
            final String detail = data["Detail"] as String? ?? "";
            final String date = data["Date"] as String? ?? "";
            final String price = data["Price"] as String? ?? "0";

            DateTime? parsedDate = DateTime.tryParse(date);
            String formattedDate = parsedDate != null ? DateFormat("MMM dd").format(parsedDate) : "TBD";


            return _buildEventCard(
              context: context,
              name: name,
              location: location,
              image: image,
              detail: detail,
              date: date,
              price: price,
              formattedDate: formattedDate,
            );
          },
        );
      },
    );
  }

  // 📄 Enhanced Event Card Widget
  Widget _buildEventCard({
    required BuildContext context,
    required String name,
    required String location,
    required String image,
    required String detail,
    required String date,
    required String price,
    required String formattedDate,
  }) {
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // Slightly larger radius
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        // 🖼 Event Image with Date Badge
        Stack(
        children: [
        ClipRRect(
        borderRadius: const BorderRadius.vertical(
        top: Radius.circular(16),
      ),
      child: image.isNotEmpty
          ? Image.network(
        image,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 180,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator(color: primaryColor)),
          );
        },
        errorBuilder: (context, error, stackTrace) => Image.asset(
          "images/event.jpg", // Placeholder
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      )
          : Image.asset(
    "images/event.jpg", // Placeholder
    height: 180,
    width: double.infinity,
    fit: BoxFit.cover,
    ),
    ),
    Positioned(
    top: 10,
    left: 10,
    child: Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
    ),
    decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.95),
    borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
    formattedDate,
    style: const TextStyle(
    color: primaryColor,
    fontSize: 15,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    ),
    ],
    ),

    // 📄 Details
    Padding(
    padding: const EdgeInsets.all(15),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
    // Event Name
    Flexible(
    child: Text(
    name,
    style: const TextStyle(
    color: Colors.black,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    ),
    ),
    // Price (styled more prominently)
    Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
    color: primaryColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
    price == "0" ? "Free" : "₹$price",
    style: const TextStyle(
    color: primaryColor,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    ],
    ),
    const SizedBox(height: 8),
    // Location
    Row(
    children: [
    const Icon(Icons.location_on, color: Colors.blueGrey, size: 18),
    const SizedBox(width: 5),
    Flexible(
    child: Text(
    location,
    style: const TextStyle(
    color: Colors.black54,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    ),
    overflow: TextOverflow.ellipsis,
    ),
    ),
    ],
    ),
    ],
    ),
    ),
    ],
    ),
    ),
    );
  }


  // ------------------------- CATEGORY TILE -------------------------
  Widget _buildCategoryTile(String name, String image, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(image, height: 40, width: 40, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------- UI BUILD -------------------------
  @override
  Widget build(BuildContext context) {
    // Check if location is fetched to conditionally show the Nearby Events section
    final isLocationReady = currentLocation != null && currentLocation != "Location disabled" && currentLocation != "Permission denied" && currentLocation != "Permission denied forever";

    return Scaffold(
      backgroundColor: lightBg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: 60, left: 25, right: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔝 Professional Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 👋 Greeting
                      Text(
                        "Hello, ${userName ?? 'User'}!",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 📍 Location
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 18),
                          const SizedBox(width: 5),
                          Text(
                            currentLocation ?? "Fetching location...",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // 🔔 Notification Icon (Now clickable)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none, color: primaryColor, size: 28),
                      onPressed: _onNotificationPressed,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 🔍 Search Bar (Pill Shape, now functional)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: primaryColor),
                    border: InputBorder.none,
                    hintText: "Search by event name or location...",
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.trim();
                    });
                  },
                ),
              ),

              const SizedBox(height: 30),

              // 🎨 Categories Section
              const Text(
                "Explore Categories",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // 🎨 Categories List
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildCategoryTile("Music", "assets/images/music.png", () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesEvent(eventcategory: "Music")));
                    }),
                    _buildCategoryTile("Clothing", "assets/images/tshirt.png", () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesEvent(eventcategory: "Clothing")));
                    }),
                    _buildCategoryTile("Festival", "assets/images/confetti.png", () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesEvent(eventcategory: "Festival")));
                    }),
                    _buildCategoryTile("Food", "assets/images/dish.png", () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesEvent(eventcategory: "Food")));
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 📍 Nearby Events Section (Conditional)
              if (isLocationReady && searchQuery.isEmpty) ...[ // Only show if location is ready and no search is active
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Events Near ${currentLocation!}",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Filter",
                      style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildEventList(nearbyOnly: true), // Use the nearby filter
                const SizedBox(height: 30),
              ],

              // 📅 Upcoming Events Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Global Upcoming Events",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "See all",
                    style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 🧾 Event List (Now filtered)
              _buildEventList(nearbyOnly: false), // Use the standard upcoming filter
              const SizedBox(height: 40), // Space for bottom navigation bar
            ],
          ),
        ),
      ),
    );
  }
}