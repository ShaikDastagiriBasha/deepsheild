import 'package:flutter/material.dart';

import 'scan_screen.dart';
import 'history_screen.dart';

class ResultScreen extends StatelessWidget {

  final String result;
  final double confidence;

  ResultScreen({
    required this.result,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {

    bool isReal = result == "REAL";

    return Scaffold(

      backgroundColor: Color(0xFF081120),

      body: SafeArea(

        child: Padding(
          padding: EdgeInsets.all(20),

          child: SingleChildScrollView(

            child: Column(
              children: [

                SizedBox(height: 20),

                // TITLE
                Text(
                  "AI Detection Result",

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(height: 40),

                // RESULT ICON
                Container(
                  padding: EdgeInsets.all(35),

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    color: isReal
                        ? Colors.green
                            .withOpacity(0.15)
                        : Colors.red
                            .withOpacity(0.15),
                  ),

                  child: Icon(
                    isReal
                        ? Icons.verified_user
                        : Icons.warning_rounded,

                    size: 120,

                    color: isReal
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                ),

                SizedBox(height: 30),

                // RESULT TEXT
                Text(
                  result,

                  style: TextStyle(
                    color: isReal
                        ? Colors.greenAccent
                        : Colors.redAccent,

                    fontSize: 42,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                SizedBox(height: 12),

                Text(
                  isReal
                      ? "Live Human Detected"
                      : "Deepfake Content Detected",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),

                SizedBox(height: 40),

                // ANALYTICS CARD
                Container(

                  padding: EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    color:
                        Colors.white.withOpacity(0.05),

                    borderRadius:
                        BorderRadius.circular(24),
                  ),

                  child: Column(
                    children: [

                      analyticsTile(
                        icon: Icons.analytics,
                        title: "Confidence Score",
                        value:
                            "${confidence.toStringAsFixed(2)}%",
                      ),

                      Divider(
                        color: Colors.white24,
                        height: 30,
                      ),

                      analyticsTile(
                        icon: Icons.security,
                        title: "Risk Level",
                        value: isReal
                            ? "LOW"
                            : "HIGH",
                      ),

                      Divider(
                        color: Colors.white24,
                        height: 30,
                      ),

                      analyticsTile(
                        icon: Icons.timer,
                        title: "Detection Time",
                        value: "3.2 Seconds",
                      ),

                      Divider(
                        color: Colors.white24,
                        height: 30,
                      ),

                      analyticsTile(
                        icon: Icons.verified,
                        title: "Verification",
                        value: "Completed",
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                // AI SUMMARY CARD
                Container(

                  width: double.infinity,

                  padding: EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    color:
                        Colors.white.withOpacity(0.05),

                    borderRadius:
                        BorderRadius.circular(24),
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        "AI Security Summary",

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 18),

                      summaryPoint(
                        isReal
                            ? "Authentic facial characteristics detected"
                            : "Synthetic facial artifacts detected",
                      ),

                      summaryPoint(
                        "Liveness verification successfully completed",
                      ),

                      summaryPoint(
                        isReal
                            ? "No spoofing attempt identified"
                            : "Potential AI manipulation identified",
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),

                // BUTTONS
                SizedBox(
                  width: double.infinity,
                  height: 58,

                  child: ElevatedButton(

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Color(0xFF2563EB),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),
                    ),

                    onPressed: () {

                      Navigator.pushReplacement(
                        context,

                        MaterialPageRoute(
                          builder: (context) =>
                              ScanScreen(),
                        ),
                      );
                    },

                    child: Text(
                      "SCAN AGAIN",

                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 58,

                  child: OutlinedButton(

                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.blueAccent,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),
                    ),

                    onPressed: () {

                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (context) =>
                              HistoryScreen(),
                        ),
                      );
                    },

                    child: Text(
                      "VIEW HISTORY",

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ANALYTICS TILE
  Widget analyticsTile({
    required IconData icon,
    required String title,
    required String value,
  }) {

    return Row(
      children: [

        Container(
          padding: EdgeInsets.all(12),

          decoration: BoxDecoration(
            color:
                Colors.blueAccent.withOpacity(0.2),

            borderRadius:
                BorderRadius.circular(14),
          ),

          child: Icon(
            icon,
            color: Colors.blueAccent,
          ),
        ),

        SizedBox(width: 18),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(
                title,

                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),

              SizedBox(height: 5),

              Text(
                value,

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // SUMMARY POINT
  Widget summaryPoint(String text) {

    return Padding(
      padding: EdgeInsets.only(bottom: 14),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Icon(
            Icons.check_circle,
            color: Colors.greenAccent,
            size: 22,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              text,

              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}