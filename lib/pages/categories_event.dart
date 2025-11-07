import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_booking_app/pages/detail_page.dart';
import 'package:event_booking_app/services/database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CategoriesEvent extends StatefulWidget {
  final String eventcategory;
  const CategoriesEvent({super.key, required this.eventcategory});

  @override
  State<CategoriesEvent> createState() => _CategoriesEventState();
}

class _CategoriesEventState extends State<CategoriesEvent> {
  Stream<QuerySnapshot>? eventStream;
  String searchQuery = "";
  String sortOption = "Date"; // Default sort option

  void loadEvents() {
    eventStream = DatabaseMethods().getEventsByCategory(widget.eventcategory);
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  // --- SAFE DATA ACCESS UTILITY ---
  // Helper to safely get data from a DocumentSnapshot
  Map<String, dynamic>? _safeGetData(DocumentSnapshot doc) {
    return doc.data() as Map<String, dynamic>?;
  }

  // --- SAFE FILTER AND SORT LOGIC ---
  List<QueryDocumentSnapshot> _filterAndSortEvents(
      List<QueryDocumentSnapshot> docs) {
    List<QueryDocumentSnapshot> filtered = docs.where((doc) {
      final data = _safeGetData(doc);
      if (data == null) return false;

      // ✅ SAFE ACCESS: Use safe map access
      final name = (data["Name"] as String? ?? "").toLowerCase();
      final location = (data["Location"] as String? ?? "").toLowerCase();

      final query = searchQuery.toLowerCase();

      // Filter out past events early (based on logic in buildEventList)
      final dateStr = data["Date"] as String? ?? "";
      try {
        final parsedDate = DateTime.parse(dateStr);
        if (DateTime.now().isAfter(parsedDate)) return false;
      } catch (_) {
        // If date is invalid, it's also filtered out
        return false;
      }

      return name.contains(query) || location.contains(query);
    }).toList();

    if (sortOption == "Date") {
      filtered.sort((a, b) {
        try {
          // ✅ SAFE ACCESS: Use safe map access
          final dateAStr = _safeGetData(a)?["Date"] as String? ?? "";
          final dateBStr = _safeGetData(b)?["Date"] as String? ?? "";

          final dateA = DateTime.parse(dateAStr);
          final dateB = DateTime.parse(dateBStr);
          return dateA.compareTo(dateB);
        } catch (_) {
          return 0; // Treat unparseable dates equally
        }
      });
    } else if (sortOption == "Price") {
      filtered.sort((a, b) {
        // ✅ SAFE ACCESS: Use safe map access
        final priceA =
            double.tryParse(_safeGetData(a)?["Price"].toString() ?? "0") ?? 0;
        final priceB =
            double.tryParse(_safeGetData(b)?["Price"].toString() ?? "0") ?? 0;
        return priceA.compareTo(priceB);
      });
    }

    return filtered;
  }

  // --- WIDGET BUILDER ---
  Widget buildEventList() {
    return StreamBuilder<QuerySnapshot>(
      stream: eventStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xff6351ec)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No events found.",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          );
        }

        final docs = _filterAndSortEvents(snapshot.data!.docs);

        if (docs.isEmpty) {
          return const Center(child: Text("No matching events found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final ds = docs[index];

            // 🚨 CRITICAL FIX: Get the data map safely
            final data = _safeGetData(ds);

            // Skip if data is unexpectedly null (e.g., deleted during query)
            if (data == null) return const SizedBox();

            // ✅ SAFE ACCESS: Retrieve fields using the safe map and null coalescing
            final name = data["Name"] as String? ?? "Untitled Event";
            final location = data["Location"] as String? ?? "Unknown";
            final imageUrl = data["Image"] as String? ?? "";
            final detail = data["Detail"] as String? ?? "";
            final dateStr = data["Date"] as String? ?? "";
            // Ensure price is treated as a string, defaulting to "0"
            final price = data["Price"]?.toString() ?? "0";

            DateTime? parsedDate;
            try {
              parsedDate = DateTime.parse(dateStr);
            } catch (_) {
              // Date is invalid, but we already filtered these out in _filterAndSortEvents
            }

            // Should have been filtered, but as an extra safety check:
            if (parsedDate == null) return const SizedBox();

            final formattedDate = DateFormat("MMM dd").format(parsedDate);

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailPage(
                    date: dateStr,
                    detail: detail,
                    image: imageUrl,
                    location: location,
                    name: name,
                    price: price,
                  ),
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.07),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                          ),
                          child: imageUrl.isNotEmpty
                              ? FadeInImage.assetNetwork(
                                  placeholder: "images/event.jpg",
                                  image: imageUrl,
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
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              formattedDate,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            // ❌ FIX: Corrected price display (removed redundant \$)
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
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.blueAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ... (rest of the code is unchanged and included below for completeness) ...

  Widget _buildSearchAndSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: "Search events...",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: sortOption,
                items: const [
                  DropdownMenuItem(value: "Date", child: Text("Sort by Date")),
                  DropdownMenuItem(
                    value: "Price",
                    child: Text("Sort by Price"),
                  ),
                ],
                onChanged: (value) => setState(() => sortOption = value!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffe3e6ff), Color(0xfff1f3ff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        widget.eventcategory,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              _buildSearchAndSortBar(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: buildEventList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
