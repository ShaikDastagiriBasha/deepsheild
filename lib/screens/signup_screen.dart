import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {

  @override
  _SignupScreenState createState() =>
      _SignupScreenState();
}

class _SignupScreenState
    extends State<SignupScreen> {

  final TextEditingController
      emailController =
      TextEditingController();

  final TextEditingController
      passwordController =
      TextEditingController();

  final TextEditingController
      confirmPasswordController =
      TextEditingController();

  bool loading = false;

  final AuthService authService =
      AuthService();

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        width: double.infinity,

        decoration: BoxDecoration(
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
              padding: EdgeInsets.all(25),

              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  SizedBox(height: 40),

                  // ICON
                  Container(
                    padding:
                        EdgeInsets.all(25),

                    decoration:
                        BoxDecoration(
                      shape:
                          BoxShape.circle,

                      color: Colors.white
                          .withOpacity(0.1),
                    ),

                    child: Icon(
                      Icons.person_add,

                      size: 90,

                      color:
                          Colors.blueAccent,
                    ),
                  ),

                  SizedBox(height: 25),

                  // TITLE
                  Text(
                    "Create Account",

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    "Secure AI Authentication",

                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                  SizedBox(height: 50),

                  // EMAIL
                  buildField(
                    controller:
                        emailController,
                    hint: "Email",
                    icon: Icons.email,
                  ),

                  SizedBox(height: 20),

                  // PASSWORD
                  buildField(
                    controller:
                        passwordController,
                    hint: "Password",
                    icon: Icons.lock,
                    obscure: true,
                  ),

                  SizedBox(height: 20),

                  // CONFIRM PASSWORD
                  buildField(
                    controller:
                        confirmPasswordController,
                    hint:
                        "Confirm Password",
                    icon:
                        Icons.lock_outline,
                    obscure: true,
                  ),

                  SizedBox(height: 35),

                  // BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 60,

                    child: ElevatedButton(

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Color(0xFF2563EB),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            18,
                          ),
                        ),
                      ),

                      onPressed:
                          loading
                              ? null
                              : signUp,

                      child:
                          loading
                              ? CircularProgressIndicator(
                                  color:
                                      Colors.white,
                                )
                              : Text(
                                  "SIGN UP",

                                  style:
                                      TextStyle(
                                    fontSize:
                                        18,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                    ),
                  ),

                  SizedBox(height: 25),

                  // LOGIN
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                    children: [

                      Text(
                        "Already have an account?",

                        style: TextStyle(
                          color:
                              Colors.white70,
                        ),
                      ),

                      SizedBox(width: 5),

                      GestureDetector(

                        onTap: () {

                          Navigator.pushReplacement(
                            context,

                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      LoginScreen(),
                            ),
                          );
                        },

                        child: Text(
                          "Login",

                          style: TextStyle(
                            color:
                                Colors.blueAccent,

                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // SIGNUP FUNCTION
  void signUp() async {

    String email =
        emailController.text.trim();

    String password =
        passwordController.text.trim();

    String confirmPassword =
        confirmPasswordController.text
            .trim();

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {

      showMessage(
        "Please fill all fields",
      );

      return;
    }

    if (password !=
        confirmPassword) {

      showMessage(
        "Passwords do not match",
      );

      return;
    }

    setState(() {
      loading = true;
    });

    String? error =
        await authService.signUp(
      email: email,
      password: password,
    );

    setState(() {
      loading = false;
    });

    if (error != null) {

      showMessage(error);

    } else {

      showMessage(
        "Account created successfully",
      );

      Navigator.pushReplacement(
        context,

        MaterialPageRoute(
          builder: (context) =>
              LoginScreen(),
        ),
      );
    }
  }

  // FIELD
  Widget buildField({
    required TextEditingController
        controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {

    return Container(

      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(0.08),

        borderRadius:
            BorderRadius.circular(18),
      ),

      child: TextField(
        controller: controller,

        obscureText: obscure,

        style:
            TextStyle(color: Colors.white),

        decoration: InputDecoration(
          hintText: hint,

          hintStyle: TextStyle(
            color: Colors.white54,
          ),

          prefixIcon: Icon(
            icon,
            color: Colors.blueAccent,
          ),

          border: InputBorder.none,

          contentPadding:
              EdgeInsets.symmetric(
            vertical: 20,
          ),
        ),
      ),
    );
  }

  // MESSAGE
  void showMessage(String message) {

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}