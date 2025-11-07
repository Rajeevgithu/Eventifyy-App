import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:event_booking_app/pages/booking.dart';
import 'package:event_booking_app/pages/home.dart';
import 'package:event_booking_app/pages/profile.dart';
import 'package:flutter/material.dart';

class Bottomnav extends StatefulWidget {
  const Bottomnav({super.key});

  @override
  State<Bottomnav> createState() => _BottomnavState();
}

class _BottomnavState extends State<Bottomnav> {
  late List<Widget> pages;
  late Home home;
  late Booking booking;
  late Profile profile;
  int currentTabIndex = 0;

  @override
  void initState() {
    home = Home();
    booking = Booking();
    profile = Profile();
    pages = [home, booking, profile];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        height: 65,
        backgroundColor: Colors.white,
        color: Colors.black,
        animationDuration: Duration(milliseconds: 500),
        onTap: (int index) {
          setState(() {
            currentTabIndex = index;
          });
        },
        items: [
          Icon(Icons.home_outlined, color: Colors.white, size: 30),
          Icon(Icons.book, color: Colors.white, size: 30),
          Icon(Icons.percent_outlined, color: Colors.white, size: 30),
        ],
      ),
      body: pages[currentTabIndex],
    );
  }
}
