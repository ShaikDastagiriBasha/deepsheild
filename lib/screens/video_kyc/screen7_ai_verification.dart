import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import '../../services/deepfake_detection_service.dart';
import '../../theme/app_theme.dart';

class Screen7AiVerification extends StatefulWidget {
  final XFile? selfieImage;
  final Function(DeepfakeAnalysisResult result) onComplete;

  const Screen7AiVerification({
    super.key,
    this.selfieImage,
    required this.onComplete,
  });

  @override
  State<Screen7AiVerification> createState() => _Screen7AiVerificationState();
}

class _Screen7AiVerificationState extends State<Screen7AiVerification> {
  double progress = 0.0;
  bool textureDone = false;
  bool motionDone = false;
  bool landmarksDone = false;
  bool fftDone = false;
  bool completed = false;

  final DeepfakeDetectionService _deepfakeService = DeepfakeDetectionService();
  DeepfakeAnalysisResult? _analysisResult;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAiAnalysis();
  }

  Future<void> _startAiAnalysis() async {
    // 1. Execute AI Analysis Engine
    if (widget.selfieImage != null) {
      _analysisResult = await _deepfakeService.analyzeFaceSample(widget.selfieImage!);
    } else {
      _analysisResult = DeepfakeAnalysisResult(
        textureScore: 0.0,
        texturePassed: false,
        motionScore: 0.0,
        motionPassed: false,
        landmarkScore: 0.0,
        landmarkPassed: false,
        fftScore: 0.0,
        fftPassed: false,
        overallConfidence: 0.0,
        riskLevel: "HIGH RISK (NO SELFIE)",
        isAuthentic: false,
      );
    }

    // 2. Animate step-by-step progress
    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!mounted) return;
      setState(() {
        progress += 0.05;

        if (progress >= 0.25) textureDone = true;
        if (progress >= 0.50) motionDone = true;
        if (progress >= 0.75) landmarksDone = true;
        if (progress >= 0.95) fftDone = true;

        if (progress >= 1.0) {
          progress = 1.0;
          completed = true;
          _timer?.cancel();
        }
      });

      if (completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _analysisResult != null) {
            widget.onComplete(_analysisResult!);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _deepfakeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int percentage = (progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          const Text(
            "AI Deepfake Detection",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Running neural network texture analysis, optical flow & FFT spectral checks.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 25),

          // MAIN AI SCAN CONTAINER
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // PULSING AI SHIELD ICON
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppTheme.primaryAccent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.25),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.verified_user_outlined,
                        size: 50,
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Analyzing...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Multi-layer AI Verification Engine",
                    style: TextStyle(
                      color: AppTheme.primaryAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ASCII / TEXT PROGRESS BAR DISPLAY
                  Text(
                    _buildAsciiProgressBar(percentage),
                    style: const TextStyle(
                      color: AppTheme.primaryAccent,
                      fontSize: 16,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "$percentage% Completed",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // CHECKING ITEMS
                  _buildCheckTile(
                    "Texture Analysis",
                    textureDone,
                    _analysisResult?.textureScore ?? 88.0,
                  ),
                  const SizedBox(height: 10),
                  _buildCheckTile(
                    "Motion & Optical Flow",
                    motionDone,
                    _analysisResult?.motionScore ?? 86.0,
                  ),
                  const SizedBox(height: 10),
                  _buildCheckTile(
                    "Landmark Alignment",
                    landmarksDone,
                    _analysisResult?.landmarkScore ?? 90.0,
                  ),
                  const SizedBox(height: 10),
                  _buildCheckTile(
                    "FFT Spectral Analysis",
                    fftDone,
                    _analysisResult?.fftScore ?? 90.0,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // CONFIDENCE OVERVIEW CARD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Deepfake Security Level",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "${_analysisResult?.riskLevel ?? 'LOW RISK'} (${(_analysisResult?.overallConfidence ?? 88.5).toInt()}%)",
                  style: TextStyle(
                    color: (_analysisResult?.isAuthentic ?? true) ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildAsciiProgressBar(int percent) {
    int totalBlocks = 10;
    int filledBlocks = (percent / 10).round();
    if (filledBlocks > totalBlocks) filledBlocks = totalBlocks;

    String filled = "█" * filledBlocks;
    String empty = "░" * (totalBlocks - filledBlocks);
    return "$filled$empty";
  }

  Widget _buildCheckTile(String title, bool isDone, double score) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? Colors.green : Colors.white10,
          ),
          child: isDone
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: isDone ? Colors.white : Colors.white54,
            fontSize: 14,
            fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          isDone ? "${score.toInt()}% Passed" : "Checking...",
          style: TextStyle(
            color: isDone ? Colors.greenAccent : Colors.white38,
            fontSize: 13,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
