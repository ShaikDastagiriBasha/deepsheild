import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081120),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const Text(
                "Verification History",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "DeepShield AI Reports",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 30),

              Expanded(
                child: StreamBuilder<
                    QuerySnapshot>(
stream:
    FirebaseFirestore
        .instance
        .collection(
            'scans')
        .orderBy(
          'timestamp',
          descending: true,
        )
        .snapshots(),

                  builder: (
                    context,
                    snapshot,
                  ) {

                    if (snapshot
                            .connectionState ==
                        ConnectionState
                            .waiting) {

                      return const Center(
                        child:
                            CircularProgressIndicator(
                          color:
                              Colors.blueAccent,
                        ),
                      );
                    }

                    if (!snapshot
                            .hasData ||
                        snapshot
                            .data!
                            .docs
                            .isEmpty) {

                      return const Center(
                        child: Text(
                          "No Verification History",

                          style:
                              TextStyle(
                            color:
                                Colors.white70,

                            fontSize:
                                18,
                          ),
                        ),
                      );
                    }

                    final docs =
                        snapshot
                            .data!
                            .docs;

                    return ListView
                        .builder(

                      itemCount:
                          docs.length,

                      itemBuilder:
                          (context,
                              index) {

                        final data =
                            docs[index]
                                    .data()
                                as Map<
                                    String,
                                    dynamic>;

                        final double
                            score =
                            (data['matchScore']
                                        as num?)
                                    ?.toDouble() ??
                                0.0;

                        final String
                            status =
                            data['status'] ??
                                "Unknown";

                        final bool
                            verified =
                            status ==
                                "Verified";

                        Timestamp?
                            timestamp =
                            data['timestamp'];

                        String
                            dateText =
                            "Pending";

                        if (timestamp !=
                            null) {

                          final date =
                              timestamp
                                  .toDate();

                          dateText =
                              "${date.day}/${date.month}/${date.year}";
                        }

                        return Container(

                          margin:
                              const EdgeInsets.only(
                            bottom:
                                18,
                          ),

                          padding:
                              const EdgeInsets.all(
                            20,
                          ),

                          decoration:
                              BoxDecoration(
                            color: Colors
                                .white
                                .withOpacity(
                                    0.05),

                            borderRadius:
                                BorderRadius.circular(
                              24,
                            ),
                          ),

                          child:
                              Row(
                            children: [

                              Container(
                                padding:
                                    const EdgeInsets.all(
                                  16,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color: verified
                                      ? Colors.green.withOpacity(
                                          0.2)
                                      : Colors.red.withOpacity(
                                          0.2),

                                  shape:
                                      BoxShape.circle,
                                ),

                                child:
                                    Icon(
                                  verified
                                      ? Icons.verified
                                      : Icons.warning,

                                  color:
                                      verified
                                          ? Colors.greenAccent
                                          : Colors.redAccent,

                                  size:
                                      34,
                                ),
                              ),

                              const SizedBox(
                                width:
                                    18,
                              ),

                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,

                                  children: [

                                    Text(
                                      status,

                                      style:
                                          TextStyle(
                                        color: verified
                                            ? Colors.greenAccent
                                            : Colors.redAccent,

                                        fontSize:
                                            24,

                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(
                                      height:
                                          6,
                                    ),

                                    Text(
                                      "Match Score: ${score.toStringAsFixed(1)}%",

                                      style:
                                          const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                      ),
                                    ),

                                    const SizedBox(
                                      height:
                                          4,
                                    ),

                                    Text(
                                      dateText,

                                      style:
                                          const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Icon(
                                Icons
                                    .arrow_forward_ios,

                                color:
                                    Colors.white54,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}