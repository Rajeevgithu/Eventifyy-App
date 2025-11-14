import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:event_booking_app/pages/booking.dart';
import 'package:event_booking_app/pages/home.dart';
import 'package:event_booking_app/pages/profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Bottomnav extends StatefulWidget {
  const Bottomnav({super.key});

  @override
  State<Bottomnav> createState() => _BottomnavState();
}

class _BottomnavState extends State<Bottomnav> {
  late final List<Widget> pages;
  int currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    pages = const [
      Home(),
      Booking(),
      Profile(),
    ];
    _loadLastTab();
  }

  Future<void> _loadLastTab() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentTabIndex = prefs.getInt('last_tab_index') ?? 0;
    });
  }

  Future<void> _saveLastTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_tab_index', index);
  }

  @override
  Widget build(BuildContext context) {
    // 💡 FIX 1: Set the Scaffold's background to white or a color that contrasts with the curve color.
    // If Home() uses a different background color, the 'cutout' area might be showing that color.
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // Use the background color the CurvedNavBar expects for the 'cutout' effect
      backgroundColor: Colors.white,

      bottomNavigationBar: CurvedNavigationBar(
        index: currentTabIndex,
        height: 65,
        // 💡 FIX 2: Set the backgroundColor to match the Scaffold's body background.
        // If your Home page background is white, set this to white.
        // Assuming your main screen body color is white for a clean blend.
        backgroundColor: Colors.white,

        color: const Color(0xff5a3efc), // The color of the bar itself
        animationDuration: const Duration(milliseconds: 500),
        onTap: (int index) async {
          setState(() => currentTabIndex = index);
          await _saveLastTab(index);
        },
        items: const [
          Icon(Icons.home_outlined, color: Colors.white, size: 30),
          Icon(Icons.book, color: Colors.white, size: 30),
          Icon(Icons.person_outline, color: Colors.white, size: 30),
        ],
      ),
      // 💡 FIX 3: Ensure the body content is wrapped in the necessary stack structure.
      // IndexedStack is correct for managing the tab pages.
      body: IndexedStack(
        index: currentTabIndex,
        children: pages,
      ),
    );
  }
}