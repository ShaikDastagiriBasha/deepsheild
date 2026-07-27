import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {

  @override
  _MainNavigationScreenState createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {

  int currentIndex = 0;

  final List<Widget> screens = [

    DashboardScreen(),

    ScanScreen(),

    HistoryScreen(),

    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: screens[currentIndex],

      bottomNavigationBar: Container(

        decoration: BoxDecoration(
          color: Color(0xFF0F172A),

          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
            ),
          ],
        ),

        child: BottomNavigationBar(

          currentIndex: currentIndex,

          onTap: (index) {

            setState(() {
              currentIndex = index;
            });
          },

          backgroundColor:
              Color(0xFF0F172A),

          selectedItemColor:
              Colors.blueAccent,

          unselectedItemColor:
              Colors.white54,

          type:
              BottomNavigationBarType.fixed,

          elevation: 0,

          items: [

            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: "Scan",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: "History",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}