import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:event_booking_app/services/shared_pref.dart';
import 'package:flutter/material.dart';

class Booking extends StatefulWidget {
  const Booking({super.key});

  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> {
  Stream? bookingStream;
  String? id;

  Future<void> getSharedPref() async {
    SharedPreferenceHelper helper =
        SharedPreferenceHelper(); // ✅ create instance
    id = await helper.getUserId(); // ✅ now call method
    setState(() {});
  }

  Future<void> onTheLoad() async {
    await getSharedPref();
  }

  @override
  void initState() {
    super.initState();
    onTheLoad();
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
              "No bookings found.",
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
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 20),
                        Text(
                          ds["Location"] ?? "Unknown Location",
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
                            child: Image.asset(
                              "images/event.jpg",
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
                                  ds["Event"] ?? "Event Name",
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
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      ds["Date"] ?? "-",
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
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      ds["Number"] ?? "-",
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
                                      color: Colors.blue,
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
          gradient: LinearGradient(
            colors: [Color(0xffe3e6ff), Color(0xfff1f3ff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Text(
              "Bookings",
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
