import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_booking_app/services/shared_pref.dart';
import 'package:event_booking_app/services/database.dart'; // ✅ Import DatabaseMethods
import 'package:flutter/material.dart';

class Booking extends StatefulWidget {
  const Booking({super.key});

  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> {
  Stream? bookingStream;
  String? id;

  // 1. Fetch User ID
  Future<void> getSharedPref() async {
    SharedPreferenceHelper helper = SharedPreferenceHelper();
    id = await helper.getUserId();
    if (mounted) {
      setState(() {});
    }
  }

  // 2. Initialize Stream using User ID
  void getBookingStream() {
    if (id != null) {
      // 🚨 ACTION: You must implement this method in your DatabaseMethods file!
      bookingStream = DatabaseMethods().getUserBookings(id!);
    }
  }

  Future<void> onTheLoad() async {
    await getSharedPref();
    // 3. Call stream initialization after ID is fetched
    getBookingStream();
  }

  @override
  void initState() {
    super.initState();
    onTheLoad();
  }

  Widget allBookings() {
    // Check if the stream is initialized before building the StreamBuilder
    if (bookingStream == null) {
      return const Center(
        child: Text("Loading user data...", style: TextStyle(fontSize: 16, color: Colors.black54)),
      );
    }

    return StreamBuilder(
      stream: bookingStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
          return const Center(
            child: Text(
              "No tickets booked yet.", // Updated message
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];

            // Safely cast data fields
            final String eventImage = ds["EventImage"] as String? ?? "";
            final String location = ds["Location"] as String? ?? "Unknown Location";
            final String eventName = ds["Event"] as String? ?? "Event Name";
            final String date = ds["Date"] as String? ?? "-";
            final String number = ds["Number"] as String? ?? "-";
            final String total = ds["Total"] as String? ?? "0";

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black38, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xff6351ec), // Use primary color
                        ),
                        const SizedBox(width: 20),
                        Text(
                          location,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.only(left: 10, bottom: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: eventImage.isNotEmpty
                                ? Image.network( // ✅ Use Image.network for the URL
                              eventImage,
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                "images/event.jpg", // Fallback placeholder
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                                : Image.asset(
                              "images/event.jpg", // Default placeholder
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eventName,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month,
                                      color: Color(0xff6351ec),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      color: Color(0xff6351ec),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      number,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.currency_rupee,
                                      color: Color(0xff6351ec),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "₹$total", // Changed \$ to ₹ for consistency
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(top: 50, left: 10),
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          // Using your primary color for a cleaner look
          gradient: LinearGradient(
            colors: [Color(0xfff1f3ff), Color(0xffe3e6ff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Text(
              "My Bookings", // Slightly better title
              style: TextStyle(
                color: Colors.black,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: allBookings(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}