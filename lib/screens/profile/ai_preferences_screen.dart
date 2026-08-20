import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AiPreferencesScreen extends StatelessWidget {
  const AiPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("AI Engine Preferences"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Model & Engine Architecture",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Read-only specifications of the AI models running in DeepShield.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 25),

              _buildModelCard(
                title: "OCR Engine",
                modelName: "Google ML Kit Text Recognition",
                description: "On-device Latin script OCR parsing PAN cards with regex sanitation.",
                badge: "Latin Script v16.0",
              ),
              const SizedBox(height: 14),

              _buildModelCard(
                title: "Face Recognition",
                modelName: "MobileFaceNet TFLite",
                description: "112x112 input tensor scaling generating 192-D L2 normalized embeddings with 50% match threshold.",
                badge: "192-D Vector",
              ),
              const SizedBox(height: 14),

              _buildModelCard(
                title: "Liveness Detection",
                modelName: "Google ML Kit Face Detector",
                description: "Real-time active gesture tracking: eye blink (< 0.6), head Euler Y turn angles, and smile probability (> 0.4).",
                badge: "Active Gestures",
              ),
              const SizedBox(height: 14),

              _buildModelCard(
                title: "Deepfake Detection Engine",
                modelName: "Multi-Modal Spatial & FFT Analyzer",
                description: "Analyzes spatial edge noise variance, facial bounding box landmarks, optical motion gradients, and high-frequency spatial pixel differences.",
                badge: "Multi-Layer",
              ),
              const SizedBox(height: 14),

              _buildModelCard(
                title: "AI Decision Engine",
                modelName: "Weighted Decision Matrix",
                description: "Weights: 25% OCR + 30% Face Match + 25% Liveness + 20% Deepfake Confidence score.",
                badge: "Rule Engine",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelCard({
    required String title,
    required String modelName,
    required String description,
    required String badge,
  }) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.primaryAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            modelName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
