import 'package:flutter/material.dart';
import '../services/auth_service.dart';

import 'signup_screen.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatelessWidget {

  LoginScreen({super.key});

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final AuthService authService =
      AuthService();

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        width: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF081120),
              Color(0xFF0F172A),
              Color(0xFF1E3A8A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: SafeArea(

          child: SingleChildScrollView(

            child: Padding(

              padding: const EdgeInsets.all(25),

              child: Column(

                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(25),

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          Colors.white.withOpacity(0.1),
                    ),

                    child: const Icon(
                      Icons.security,
                      size: 90,
                      color: Colors.blueAccent,
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "DeepShield",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "AI-Powered Deepfake Detection",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 50),

                  Container(
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withOpacity(
                        0.08,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),

                    child: TextField(
                      controller:
                          emailController,

                      style: const TextStyle(
                        color: Colors.white,
                      ),

                      decoration:
                          const InputDecoration(
                        hintText: "Email",

                        hintStyle:
                            TextStyle(
                          color:
                              Colors.white54,
                        ),

                        prefixIcon: Icon(
                          Icons.email,
                          color:
                              Colors.blueAccent,
                        ),

                        border:
                            InputBorder.none,

                        contentPadding:
                            EdgeInsets.symmetric(
                          vertical: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withOpacity(
                        0.08,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),

                    child: TextField(
                      controller:
                          passwordController,

                      obscureText: true,

                      style: const TextStyle(
                        color: Colors.white,
                      ),

                      decoration:
                          const InputDecoration(
                        hintText: "Password",

                        hintStyle:
                            TextStyle(
                          color:
                              Colors.white54,
                        ),

                        prefixIcon: Icon(
                          Icons.lock,
                          color:
                              Colors.blueAccent,
                        ),

                        border:
                            InputBorder.none,

                        contentPadding:
                            EdgeInsets.symmetric(
                          vertical: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Align(
                    alignment:
                        Alignment.centerRight,

                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color:
                            Colors.blueAccent,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    height: 60,

                    child: ElevatedButton(

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xFF2563EB,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            18,
                          ),
                        ),
                      ),

                      onPressed: () async {

                        String? error =
                            await authService.login(
                          email:
                              emailController
                                  .text
                                  .trim(),

                          password:
                              passwordController
                                  .text
                                  .trim(),
                        );

                        if (error != null) {

                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                            SnackBar(
                              content:
                                  Text(error),
                            ),
                          );

                        } else {

                          Navigator.pushReplacement(
                            context,

                            MaterialPageRoute(
                              builder: (_) =>
                                  MainNavigationScreen(),
                            ),
                          );
                        }
                      },

                      child: const Text(
                        "LOGIN",

                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [

                      const Text(
                        "Don't have an account?",

                        style: TextStyle(
                          color:
                              Colors.white70,
                        ),
                      ),

                      const SizedBox(width: 5),

                      GestureDetector(

                        onTap: () {

                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (_) =>
                                  SignupScreen(),
                            ),
                          );
                        },

                        child: const Text(
                          "Sign Up",

                          style: TextStyle(
                            color:
                                Colors.blueAccent,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}