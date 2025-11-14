import 'dart:convert';
import 'package:event_booking_app/services/database.dart';
import 'package:event_booking_app/services/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

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
  late int basePrice;
  int total = 0;

  String? userName, userImage, userId;
  final SharedPreferenceHelper _prefs = SharedPreferenceHelper();

  bool isProcessing = false;

  // Theme Colors
  static const Color primaryColor = Color(0xff6351ec);
  static const Color accentColor = Color(0xFF1E3A8A); // A dark blue for contrast

  @override
  void initState() {
    super.initState();
    // Parse the price safely
    basePrice = int.tryParse(widget.price) ?? 0;
    total = basePrice;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    userName = await _prefs.getUserName();
    userImage = await _prefs.getUserImage();
    userId = await _prefs.getUserId();
    if (mounted) setState(() {});
  }

  // Helper to format date
  String get _formattedDate {
    try {
      final dateTime = DateTime.parse(widget.date);
      return DateFormat('EEEE, MMM d, yyyy').format(dateTime);
    } catch (_) {
      return widget.date;
    }
  }

  // --- UI Building Blocks ---

  // 🖼 Header with image & Collapsing AppBar (SliverAppBar)
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 350.0,
      floating: false,
      pinned: true,
      backgroundColor: primaryColor,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10, top: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1), blurRadius: 5),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_outlined,
                color: Colors.black54, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(bottom: 16, left: 60, right: 60),
        title: Text(
          widget.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: widget.image.isNotEmpty
            ? Image.network(
          widget.image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Image.asset("images/event.jpg", fit: BoxFit.cover),
        )
            : Image.asset("images/event.jpg", fit: BoxFit.cover),
      ),
    );
  }

  // ℹ️ General Information Card
  Widget _buildGeneralInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const Divider(height: 25),
            _buildInfoRow(
              Icons.calendar_month,
              _formattedDate,
              Colors.redAccent,
            ),
            const SizedBox(height: 15),
            _buildInfoRow(
              Icons.location_on_outlined,
              widget.location,
              Colors.blueAccent,
            ),
            const SizedBox(height: 15),
            _buildInfoRow(
              Icons.attach_money,
              basePrice == 0
                  ? "Free Event"
                  : "Starts from ₹${widget.price}",
              primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for information rows
  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // 📄 About event section
  Widget _buildEventDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "About Event",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.detail,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  // 🎟 Modern Ticket selector
  Widget _buildTicketCounter() {
    if (basePrice == 0) return const SizedBox.shrink(); // Hide if free

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Tickets",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Ticket Price: ₹${widget.price}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    _buildCounterButton(Icons.remove, () {
                      if (ticket > 1) {
                        setState(() {
                          ticket--;
                          total = ticket * basePrice;
                        });
                      }
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        "$ticket",
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildCounterButton(Icons.add, () {
                      setState(() {
                        ticket++;
                        total = ticket * basePrice;
                      });
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: primaryColor),
      ),
    );
  }

  // 💰 Sticky Footer Bar
  Widget _buildStickyFooterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Total Amount",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  basePrice == 0 ? "FREE" : "₹$total",
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(180, 55),
                elevation: 5,
              ),
              onPressed: basePrice == 0
                  ? (isProcessing ? null : () => _handleFreeBooking())
                  : (isProcessing ? null : () => makePayment(total.toString())),
              child: isProcessing
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
                  : Text(
                basePrice == 0 ? "Register Now" : "Book Now",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Booking Logic (Updated for Free Events) ---
  Future<void> _handleFreeBooking() async {
    if (userId == null) {
      _showDialog("Error", "User not logged in.");
      return;
    }
    setState(() => isProcessing = true);
    try {
      Map<String, dynamic> bookingData = {
        "Number": ticket.toString(),
        "Total": "0", // Total is always 0 for free events
        "Event": widget.name,
        "Location": widget.location,
        "Date": widget.date,
        "Name": userName,
        "Image": userImage,
        "EventImage": widget.image,
        "BookingDate": DateTime.now().toIso8601String(),
      };
      await DatabaseMethods().addUserBooking(bookingData, userId!);
      await DatabaseMethods().addAdminBooking(bookingData);
      _showDialog("Registration Successful",
          "Your ticket(s) have been successfully reserved!");
    } catch (e) {
      _showDialog("Registration Failed", "An error occurred: $e");
    } finally {
      setState(() => isProcessing = false);
    }
  }

  /// 💳 Stripe Payment Flow
  Future<void> makePayment(String amount) async {
    setState(() => isProcessing = true);
    try {
      // Logic for Stripe payment intent remains the same
      paymentIntent = await _createPaymentIntent(amount, 'INR');
      if (paymentIntent == null)
        throw Exception("Failed to create payment intent");

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent!['client_secret'],
          style: ThemeMode.light, // Use light theme for better integration
          merchantDisplayName: 'Event Booking App',
        ),
      );

      await _displayPaymentSheet();
    } catch (e) {
      _showDialog("Payment Failed", e.toString());
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _displayPaymentSheet() async {
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

  // 🧮 Create Stripe Payment Intent (No changes needed)
  Future<Map<String, dynamic>?> _createPaymentIntent(
      String amount, String currency) async {
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
            child: const Text("OK", style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Light background for contrast
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(), // Collapsing header
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _buildGeneralInfoCard(), // Event Info
                    _buildEventDescription(), // About Event
                    const SizedBox(height: 20),
                    _buildTicketCounter(), // Ticket Selector
                    const SizedBox(height: 100), // Space for the floating bar
                  ],
                ),
              ),
            ],
          ),

          // Sticky Footer (Booking Bar)
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildStickyFooterBar(context),
          ),

          // Loading Overlay
          if (isProcessing)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}