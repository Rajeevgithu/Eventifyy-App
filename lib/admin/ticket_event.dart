import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_booking_app/services/database.dart'; // Ensure this path is correct
import 'package:flutter/material.dart';

class TicketEvent extends StatefulWidget {
  const TicketEvent({super.key});

  @override
  State<TicketEvent> createState() => _TicketEventState();
}

class _TicketEventState extends State<TicketEvent> {
  // 💡 Explicitly define the Stream type for better safety
  Stream<QuerySnapshot>? ticketStream;

  @override
  void initState() {
    super.initState();
    onTheLoad();
  }

  Future<void> onTheLoad() async {
    // 📞 Call the database method to get the stream
    ticketStream = DatabaseMethods().getAllTickets();
    setState(() {}); // Triggers the StreamBuilder to start listening
  }

  // Helper method for consistent detail rows
  Widget _buildDetailRow(
    IconData icon,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Widget to build a single ticket item
  Widget _buildTicketItem(DocumentSnapshot ds) {
    // Safely extract data, providing default values
    final data =
        ds.data() as Map<String, dynamic>; // Use the map for cleaner access
    final location = data["Location"] ?? "No Location";
    final eventName = data["Event"] ?? "Unknown Event";
    final date = data["Date"] ?? "-";
    final name = data["Name"] ?? "-";
    final number = data["Number"] ?? "1";
    final total = data["Total"] ?? "0";
    final imageUrl = data["Image"] ?? ""; // The critical field

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black38, width: 1.5),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 🔹 Location Row (Centered)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xff6351ec),
                ), // Use primary color
                const SizedBox(width: 10),
                Text(
                  location,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // 🔹 Event Details Row
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        width: 120,
                        color: Colors.grey[
                            300], // Slightly lighter grey for broken image
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Event info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Name
                        Text(
                          eventName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Detail Rows (Date, Name, Number, Total)
                        _buildDetailRow(
                          Icons.calendar_month,
                          date,
                          Colors.blue,
                        ),
                        _buildDetailRow(Icons.person, name, Colors.blue),
                        _buildDetailRow(
                          Icons.confirmation_number,
                          number,
                          Colors.blue,
                        ),
                        _buildDetailRow(
                          Icons.currency_rupee,
                          "\$$total",
                          Colors.green,
                          isBold: true,
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
  }

  // Widget to handle the stream and build the list
  Widget allTickets() {
    if (ticketStream == null) {
      return const Center(
        child: Text("Loading ticket data...", style: TextStyle(fontSize: 16)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: ticketStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading tickets: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No tickets found.",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = docs[index];
            return _buildTicketItem(ds);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // 💡 Moved margin directly to SafeArea padding for cleaner structure
        child: Padding(
          padding: const EdgeInsets.only(left: 10, top: 10, right: 10),
          child: Column(
            children: [
              // 🔹 Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new_outlined),
                    ),
                    const Spacer(),
                    const Text(
                      "Event Tickets",
                      style: TextStyle(
                        color: Color(0xff6351ec),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 🔹 Ticket list
              Expanded(child: allTickets()),
            ],
          ),
        ),
      ),
    );
  }
}
