import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'video_kyc/video_kyc_flow_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final fallbackName = user?.displayName ??
        (user?.email != null && user!.email!.contains('@')
            ? user.email!.split('@').first
            : "Analyst");
    final userUid = user?.uid ?? "";

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // WELCOME HEADER WITH FIRESTORE USER PROFILE SYNC
                StreamBuilder<DocumentSnapshot>(
                  stream: user != null
                      ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots()
                      : null,
                  builder: (context, userSnapshot) {
                    String displayName = fallbackName;
                    String? photoPath;

                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>?;
                      if (userData != null) {
                        if ((userData['username'] ?? "")
                            .toString()
                            .isNotEmpty) {
                          displayName = userData['username'];
                        }
                        if ((userData['profileImageUrl'] ?? "")
                            .toString()
                            .isNotEmpty) {
                          photoPath = userData['profileImageUrl'];
                        } else if ((userData['photoUrl'] ?? "")
                            .toString()
                            .isNotEmpty) {
                          photoPath = userData['photoUrl'];
                        }
                      }
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome Back 👋",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ProfileScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryAccent,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.primaryColor,
                              backgroundImage: photoPath != null
                                  ? (photoPath.startsWith('http')
                                      ? NetworkImage(photoPath) as ImageProvider
                                      : (File(photoPath).existsSync()
                                          ? FileImage(File(photoPath))
                                          : null))
                                  : null,
                              child: photoPath == null
                                  ? const Icon(
                                      Icons.security,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // SUMMARY METRIC CARDS STREAM FROM FIRESTORE
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('scans')
                      .where('userUid', isEqualTo: userUid)
                      .snapshots(),
                  builder: (context, statsSnapshot) {
                    int totalScans = 0;
                    int successScans = 0;
                    double avgScore = 0.0;

                    if (statsSnapshot.hasData &&
                        statsSnapshot.data!.docs.isNotEmpty) {
                      final docs = statsSnapshot.data!.docs;
                      totalScans = docs.length;
                      double scoreSum = 0.0;

                      for (var doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status =
                            (data['status'] ?? "").toString().toUpperCase();
                        if (status == "VERIFIED") {
                          successScans++;
                        }
                        scoreSum +=
                            (data['matchScore'] as num?)?.toDouble() ?? 0.0;
                      }
                      if (totalScans > 0) {
                        avgScore = scoreSum / totalScans;
                      }
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            label: "Total Verifications",
                            value: "$totalScans",
                            icon: Icons.shield_outlined,
                            color: AppTheme.primaryAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricTile(
                            label: "Successful",
                            value: "$successScans",
                            icon: Icons.check_circle_outline,
                            color: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricTile(
                            label: "Avg Confidence",
                            value: "${avgScore.toInt()}%",
                            icon: Icons.analytics_outlined,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 25),

                // PRIMARY HERO CARD — START VIDEO KYC
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2563EB),
                        Color(0xFF1D4ED8),
                        Color(0xFF1E40AF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.video_camera_front_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.flash_on,
                                    color: Colors.amberAccent, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  "AI Instant KYC",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Start Video KYC",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Complete document upload, live selfie, liveness, and AI deepfake detection in 8 simple steps.",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const VideoKYCFlowScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E40AF),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Begin Verification Now",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // RECENT VERIFICATIONS HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Recent Verifications",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HistoryScreen()),
                        );
                      },
                      child: const Text(
                        "View History",
                        style: TextStyle(
                          color: AppTheme.primaryAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // RECENT VERIFICATIONS LIST STREAM (FILTERED BY CURRENT USER UID)
                // NOTE: No server-side orderBy to avoid requiring a composite
                // Firestore index. Docs are sorted client-side by timestamp.
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('scans')
                      .where('userUid', isEqualTo: userUid)
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryColor),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.fact_check_outlined,
                              size: 44,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Start your first AI Video KYC verification.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Tap 'Begin Verification Now' above to start.",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Sort client-side by timestamp descending, take 3 most recent
                    final allDocs = snapshot.data!.docs.toList();
                    allDocs.sort((a, b) {
                      final aTs =
                          (a.data() as Map<String, dynamic>)['timestamp'];
                      final bTs =
                          (b.data() as Map<String, dynamic>)['timestamp'];
                      if (aTs == null && bTs == null) return 0;
                      if (aTs == null) return 1;
                      if (bTs == null) return -1;
                      return bTs.compareTo(aTs);
                    });
                    final docs = allDocs.take(3).toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final double score = (data['matchScore'] ??
                                    data['faceMatchScore'] as num?)
                                ?.toDouble() ??
                            0.0;
                        final String status = (data['status'] ?? 'FAILED')
                            .toString()
                            .toUpperCase();
                        final bool verified = status == 'VERIFIED';
                        final String verId =
                            data['verificationId'] ?? 'DS-${index + 1}';
                        final String name =
                            data['personName'] ?? data['name'] ?? 'N/A';
                        final String docType =
                            data['documentType'] ?? 'Document';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: verified
                                  ? [
                                      Colors.green.withValues(alpha: 0.08),
                                      Colors.transparent
                                    ]
                                  : [
                                      Colors.red.withValues(alpha: 0.06),
                                      Colors.transparent
                                    ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: verified
                                  ? Colors.greenAccent.withValues(alpha: 0.2)
                                  : Colors.redAccent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: verified
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.2),
                                ),
                                child: Icon(
                                  verified
                                      ? Icons.verified_user_rounded
                                      : Icons.warning_rounded,
                                  color: verified
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      verId,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$name  •  $docType  •  ${score.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.6),
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: verified
                                      ? Colors.greenAccent
                                          .withValues(alpha: 0.15)
                                      : Colors.redAccent
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: verified
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 25),

                // QUICK LINKS ROW
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickLinkCard(
                        context: context,
                        title: "History",
                        subtitle: "View all logs",
                        icon: Icons.history,
                        color: const Color(0xFF0F766E),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HistoryScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildQuickLinkCard(
                        context: context,
                        title: "Profile",
                        subtitle: "Account info",
                        icon: Icons.security,
                        color: const Color(0xFF7C3AED),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfileScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinkCard({
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
