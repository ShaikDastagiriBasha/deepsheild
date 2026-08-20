import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("About DeepShield"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // LOGO ICON
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  border: Border.all(color: AppTheme.primaryAccent, width: 2),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 70,
                  color: AppTheme.primaryAccent,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "DeepShield",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "v1.0.0 • AI Video KYC Module",
                style: TextStyle(
                  color: AppTheme.primaryAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 25),

              // PROJECT INFO CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Project Title",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "DeepShield – AI-Based Deepfake Detection System for Secure Video KYC Verification",
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    _buildAboutItem("Academic Year", "2025–2026"),
                    _buildAboutItem("Department", "Computer Science & Engineering"),
                    _buildAboutItem("Project Scope", "Final Year B.Tech Engineering Major Project"),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // TECHNOLOGIES CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Technologies Used",
                      style: TextStyle(color: AppTheme.primaryAccent, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text("Flutter 3.27+"), backgroundColor: Colors.white10, labelStyle: TextStyle(color: Colors.white)),
                        Chip(label: Text("Firebase Auth & Firestore"), backgroundColor: Colors.white10, labelStyle: TextStyle(color: Colors.white)),
                        Chip(label: Text("Google ML Kit"), backgroundColor: Colors.white10, labelStyle: TextStyle(color: Colors.white)),
                        Chip(label: Text("TensorFlow Lite"), backgroundColor: Colors.white10, labelStyle: TextStyle(color: Colors.white)),
                        Chip(label: Text("MobileFaceNet 192-D"), backgroundColor: Colors.white10, labelStyle: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Text(
                "© 2026 DeepShield AI. All Rights Reserved.",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
