import 'package:flutter/material.dart';
import '../services/auth_service.dart';

import 'login_screen.dart';
class ProfileScreen extends StatelessWidget {

final AuthService authService = 
      AuthService();

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Color(0xFF081120),

      body: SafeArea(

        child: Padding(
          padding: EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // TITLE
              Text(
                "Profile",

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              SizedBox(height: 30),

              // PROFILE CARD
              Container(

                padding: EdgeInsets.all(24),

                decoration: BoxDecoration(
                  color:
                      Colors.white.withOpacity(0.05),

                  borderRadius:
                      BorderRadius.circular(24),
                ),

                child: Row(
                  children: [

                    CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          Colors.blueAccent,

                      child: Icon(
                        Icons.person,
                        size: 45,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(width: 20),

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Text(
                          "DeepShield User",

                          style: TextStyle(
                            color:
                                Colors.white,
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          "AI Security Analyst",

                          style: TextStyle(
                            color:
                                Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 35),

              // SETTINGS TITLE
              Text(
                "Settings",

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              SizedBox(height: 20),

              profileTile(
                icon: Icons.lock,
                title: "Privacy & Security",
              ),

              profileTile(
                icon: Icons.dark_mode,
                title: "Dark Mode",
              ),

              profileTile(
                icon: Icons.info,
                title: "About DeepShield",
              ),

GestureDetector(

  onTap: () async {

    await authService.logout();

    Navigator.pushAndRemoveUntil(
      context,

      MaterialPageRoute(
        builder: (context) =>
            LoginScreen(),
      ),

      (route) => false,
    );
  },

  child: profileTile(
    icon: Icons.logout,
    title: "Logout",
  ),
),
            ],
          ),
        ),
      ),
    );
  }

  Widget profileTile({
    required IconData icon,
    required String title,
  }) {

    return Container(

      margin: EdgeInsets.only(bottom: 18),

      padding: EdgeInsets.all(20),

      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(0.05),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Row(
        children: [

          Icon(
            icon,
            color: Colors.blueAccent,
            size: 30,
          ),

          SizedBox(width: 18),

          Expanded(
            child: Text(
              title,

              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),

          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white54,
          ),
        ],
      ),
    );
  }
}