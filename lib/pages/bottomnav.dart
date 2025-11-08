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
    _loadLastTab(); // 👈 Load saved tab index on startup
  }

  // Load saved tab index from SharedPreferences
  Future<void> _loadLastTab() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentTabIndex = prefs.getInt('last_tab_index') ?? 0;
    });
  }

  // Save tab index whenever user switches
  Future<void> _saveLastTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_tab_index', index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        index: currentTabIndex,
        height: 65,
        backgroundColor: Colors.white,
        color: Colors.black,
        animationDuration: const Duration(milliseconds: 500),
        onTap: (int index) async {
          setState(() {
            currentTabIndex = index;
          });
          await _saveLastTab(index); // 👈 Save the selected tab
        },
        items: const [
          Icon(Icons.home_outlined, color: Colors.white, size: 30),
          Icon(Icons.book, color: Colors.white, size: 30),
          Icon(Icons.percent_outlined, color: Colors.white, size: 30),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: currentTabIndex,
          children: pages,
        ),
      ),
    );
  }
}
