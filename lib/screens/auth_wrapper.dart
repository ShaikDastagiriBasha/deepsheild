import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
import 'main_navigation_screen.dart';

class AuthWrapper extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {

        // LOADING
        if (snapshot.connectionState ==
            ConnectionState.waiting) {

          return Scaffold(

            backgroundColor:
                Color(0xFF081120),

            body: Center(
              child:
                  CircularProgressIndicator(
                color: Colors.blueAccent,
              ),
            ),
          );
        }

        // USER LOGGED IN
        if (snapshot.hasData) {

          return MainNavigationScreen();
        }

        // USER NOT LOGGED IN
        return LoginScreen();
      },
    );
  }
}