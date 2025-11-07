import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_booking_app/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingHistory extends StatefulWidget {
  const BookingHistory({super.key});

  @override
  State<BookingHistory> createState() => _BookingHistoryState();
}

class _BookingHistoryState extends State<BookingHistory> {
  Stream? bookingStream;

  @override
  void initState() {
    super.initState();
    String userId = FirebaseAuth.instance.currentUser!.uid;
    loadBookings(userId);
  }

  void loadBookings(String userId) {
    bookingStream = DatabaseMethods().getUserBookings(userId);
    setState(() {});
  }

  Widget allBookings() {
    return StreamBuilder(
      stream: bookingStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
          return const Center(
            child: Text(
              "No booking history found.",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black12, width: 1.5),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // 🔹 Event image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        ds["Image"] ?? "",
                        height: 90,
                        width: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 90,
                          width: 90,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),

                    // 🔹 Booking Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ds["Event"] ?? "Unknown Event",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                color: Colors.blue,
                                size: 18,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                ds["Date"] ?? "-",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.confirmation_number,
                                color: Colors.blue,
                                size: 18,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "${ds["Number"] ?? "1"} tickets",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.currency_rupee,
                                color: Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "\$${ds["Total"] ?? "0"}",
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

                    // 🔹 Date of booking
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          color: Color(0xff6351ec),
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ds["BookingDate"] != null
                              ? DateFormat('MMM d, yyyy').format(
                                  (ds["BookingDate"] as Timestamp).toDate(),
                                )
                              : "",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
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
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            children: [
              // 🔹 Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_outlined),
                  ),
                  const Spacer(),
                  const Text(
                    "Booking History",
                    style: TextStyle(
                      color: Color(0xff6351ec),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
              const SizedBox(height: 10),

              // 🔹 Booking list
              Expanded(child: allBookings()),
            ],
          ),
        ),
      ),
    );
  }
}
