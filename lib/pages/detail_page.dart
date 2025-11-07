import 'dart:convert';
import 'package:event_booking_app/services/database.dart';
import 'package:event_booking_app/services/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DetailPage extends StatefulWidget {
  final String image, name, location, date, detail, price;

  const DetailPage({
    Key? key,
    required this.date,
    required this.detail,
    required this.image,
    required this.location,
    required this.name,
    required this.price,
  }) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Map<String, dynamic>? paymentIntent;
  int ticket = 1;
  int total = 0;

  String? userName, userImage, userId;
  final SharedPreferenceHelper _prefs = SharedPreferenceHelper();

  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    total = int.tryParse(widget.price) ?? 0;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    userName = await _prefs.getUserName();
    userImage = await _prefs.getUserImage();
    userId = await _prefs.getUserId();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventImage(context),
                const SizedBox(height: 20),
                _buildEventDescription(),
                const SizedBox(height: 30),
                _buildTicketCounter(),
                const SizedBox(height: 30),
                _buildBookingBar(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (isProcessing)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xff6351ec)),
              ),
            ),
        ],
      ),
    );
  }

  // 🖼 Header with image & details
  Widget _buildEventImage(BuildContext context) {
    return Stack(
      children: [
        widget.image.isNotEmpty
            ? Image.network(
                widget.image,
                height: MediaQuery.of(context).size.height / 2,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            : Image.asset(
                "images/event.jpg",
                height: MediaQuery.of(context).size.height / 2,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
        Positioned(
          top: 40,
          left: 20,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.arrow_back_ios_new_outlined),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black.withOpacity(0.55),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.date,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(width: 20),
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.location,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 📄 About event section
  Widget _buildEventDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "About Event",
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            widget.detail,
            style: const TextStyle(
              fontSize: 17,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // 🎟 Ticket selector
  Widget _buildTicketCounter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Number of Tickets",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Container(
            width: 70,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black45, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () {
                    setState(() {
                      ticket++;
                      total = ticket * (int.tryParse(widget.price) ?? 0);
                    });
                  },
                ),
                Text(
                  "$ticket",
                  style: const TextStyle(
                    color: Color(0xff6351ec),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  onPressed: () {
                    if (ticket > 1) {
                      setState(() {
                        ticket--;
                        total = ticket * (int.tryParse(widget.price) ?? 0);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 💰 Amount + Book Button
  Widget _buildBookingBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            "Amount: ₹total",
            style: const TextStyle(
              color: Color(0xff6351ec),
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff6351ec),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(180, 50),
            ),
            onPressed:
                isProcessing ? null : () => makePayment(total.toString()),
            child: const Text(
              "Book Now",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// 💳 Stripe Payment Flow
  Future<void> makePayment(String amount) async {
    setState(() => isProcessing = true);
    try {
      paymentIntent = await _createPaymentIntent(amount, 'INR');
      if (paymentIntent == null)
        throw Exception("Failed to create payment intent");

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent!['client_secret'],
          style: ThemeMode.dark,
          merchantDisplayName: 'Event Booking App',
        ),
      );

      await _displayPaymentSheet(amount);
    } catch (e) {
      _showDialog("Payment Failed", e.toString());
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _displayPaymentSheet(String amount) async {
    try {
      await Stripe.instance.presentPaymentSheet();

      Map<String, dynamic> bookingData = {
        "Number": ticket.toString(),
        "Total": total.toString(),
        "Event": widget.name,
        "Location": widget.location,
        "Date": widget.date,
        "Name": userName,
        "Image": userImage,
        "EventImage": widget.image,
        "BookingDate": DateTime.now().toIso8601String(),
      };

      if (userId != null) {
        await DatabaseMethods().addUserBooking(bookingData, userId!);
        await DatabaseMethods().addAdminBooking(bookingData);
      }

      _showDialog("Payment Successful", "Your booking has been confirmed!");
      paymentIntent = null;
    } on StripeException {
      _showDialog("Payment Cancelled", "You cancelled the payment.");
    } catch (e) {
      _showDialog("Error", "Something went wrong: $e");
    }
  }

  /// 🧮 Create Stripe Payment Intent
  Future<Map<String, dynamic>?> _createPaymentIntent(
    String amount,
    String currency,
  ) async {
    try {
      final String? secretKey = dotenv.env['STRIPE_SECRET_KEY'];
      if (secretKey == null)
        throw Exception("Stripe secret key not found in .env");

      final body = {
        'amount': (int.parse(amount) * 100).toString(),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      return jsonDecode(response.body);
    } catch (err) {
      debugPrint('Error creating payment intent: $err');
      return null;
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
