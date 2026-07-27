import 'package:flutter/material.dart';

import 'document_upload_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatelessWidget {

  const DashboardScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFF081120),

      body: SafeArea(

        child: Padding(
          padding:
              const EdgeInsets.all(20),

          child: SingleChildScrollView(

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // HEADER
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [

                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: const [

                        Text(
                          "Welcome Back 👋",

                          style: TextStyle(
                            color:
                                Colors.white70,

                            fontSize: 16,
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          "DeepShield",

                          style: TextStyle(
                            color:
                                Colors.white,

                            fontSize: 30,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const CircleAvatar(
                      radius: 28,

                      backgroundColor:
                          Colors.blueAccent,

                      child: Icon(
                        Icons.person,

                        color:
                            Colors.white,

                        size: 30,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                // SECURITY STATUS
                Container(
                  width: double.infinity,

                  padding:
                      const EdgeInsets.all(
                          22),

                  decoration: BoxDecoration(

                    gradient:
                        const LinearGradient(
                      colors: [

                        Color(0xFF2563EB),

                        Color(0xFF1E40AF),
                      ],
                    ),

                    borderRadius:
                        BorderRadius.circular(
                            24),
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      const Text(
                        "Security Status",

                        style: TextStyle(
                          color:
                              Colors.white70,

                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(
                          height: 15),

                      Row(
                        children: [

                          const Icon(
                            Icons.verified_user,

                            color:
                                Colors.white,

                            size: 50,
                          ),

                          const SizedBox(
                              width: 20),

                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: const [

                              Text(
                                "Protected",

                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,

                                  fontSize:
                                      28,

                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              Text(
                                "AI Monitoring Active",

                                style:
                                    TextStyle(
                                  color:
                                      Colors.white70,

                                  fontSize:
                                      15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ANALYTICS
                Row(
                  children: [

                    Expanded(
                      child:
                          dashboardCard(
                        title:
                            "Total Scans",

                        value: "128",

                        icon: Icons
                            .analytics,
                      ),
                    ),

                    const SizedBox(
                        width: 15),

                    Expanded(
                      child:
                          dashboardCard(
                        title:
                            "Accuracy",

                        value: "97.6%",

                        icon:
                            Icons.shield,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // QUICK ACTIONS
                const Text(
                  "Quick Actions",

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 24,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // START VERIFICATION
                actionCard(

                  context: context,

                  title:
                      "Start KYC Verification",

                  subtitle:
                      "Upload Aadhaar/PAN and begin AI verification",

                  icon:
                      Icons.document_scanner,

                  color:
                      const Color(0xFF2563EB),

                  onTap: () {

                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const DocumentUploadScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // HISTORY
                actionCard(

                  context: context,

                  title:
                      "Verification History",

                  subtitle:
                      "View previous AI verification reports",

                  icon: Icons.history,

                  color:
                      const Color(0xFF0F766E),

                  onTap: () {

                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder:
                            (context) =>
                                HistoryScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // AI ENGINE
                Container(

                  padding:
                      const EdgeInsets.all(
                          20),

                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withOpacity(
                            0.05),

                    borderRadius:
                        BorderRadius.circular(
                            22),
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      const Text(
                        "AI Detection Engine",

                        style: TextStyle(
                          color:
                              Colors.white,

                          fontSize: 22,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                          height: 15),

                      featureTile(
                        "ML Kit Face Detection",
                      ),

                      featureTile(
                        "Real-Time Liveness AI",
                      ),

                      featureTile(
                        "OCR Document Verification",
                      ),

                      featureTile(
                        "Deepfake Detection Engine",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // DASHBOARD CARD
  Widget dashboardCard({
    required String title,
    required String value,
    required IconData icon,
  }) {

    return Container(

      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(
                0.06),

        borderRadius:
            BorderRadius.circular(
                22),
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Icon(
            icon,

            color:
                Colors.blueAccent,

            size: 35,
          ),

          const SizedBox(
              height: 15),

          Text(
            value,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 28,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
              height: 5),

          Text(
            title,

            style: const TextStyle(
              color:
                  Colors.white70,

              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ACTION CARD
  Widget actionCard({

    required BuildContext context,

    required String title,

    required String subtitle,

    required IconData icon,

    required Color color,

    required VoidCallback onTap,
  }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        padding:
            const EdgeInsets.all(
                22),

        decoration: BoxDecoration(
          color: Colors.white
              .withOpacity(0.06),

          borderRadius:
              BorderRadius.circular(
                  22),
        ),

        child: Row(

          children: [

            Container(
              padding:
                  const EdgeInsets.all(
                      16),

              decoration:
                  BoxDecoration(
                color: color,

                borderRadius:
                    BorderRadius.circular(
                        18),
              ),

              child: Icon(
                icon,

                color: Colors.white,

                size: 32,
              ),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  Text(
                    title,

                    style:
                        const TextStyle(
                      color:
                          Colors.white,

                      fontSize: 20,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                      height: 5),

                  Text(
                    subtitle,

                    style:
                        const TextStyle(
                      color:
                          Colors.white70,

                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,

              color:
                  Colors.white54,
            ),
          ],
        ),
      ),
    );
  }

  // FEATURE TILE
  Widget featureTile(
      String text) {

    return Padding(
      padding:
          const EdgeInsets.only(
              bottom: 12),

      child: Row(
        children: [

          const Icon(
            Icons.check_circle,

            color:
                Colors.greenAccent,

            size: 22,
          ),

          const SizedBox(
              width: 10),

          Text(
            text,

            style:
                const TextStyle(
              color:
                  Colors.white70,

              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}