import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import '../../services/deepfake_detection_service.dart';
import '../../services/face_recognition_service.dart';
import '../../services/ocr_service.dart';
import '../../services/ocr/ocr_models.dart';
import '../../theme/app_theme.dart';

import 'screen1_start.dart';
import 'screen2_upload_pan.dart';
import 'screen3_ocr_processing.dart';
import 'screen4_live_verification.dart';
import 'screen5_face_recognition.dart';
import 'screen6_liveness.dart';
import 'screen7_ai_verification.dart';
import 'screen8_final_report.dart';

class VideoKYCFlowScreen extends StatefulWidget {
  final int initialStep;

  const VideoKYCFlowScreen({
    super.key,
    this.initialStep = 1,
  });

  @override
  State<VideoKYCFlowScreen> createState() => _VideoKYCFlowScreenState();
}

class _VideoKYCFlowScreenState extends State<VideoKYCFlowScreen> {
  int currentStep = 1;

  // Flow Data State
  XFile? panImage;
  late OCRResultData ocrData;
  String detectedDocType = 'Identity Document';

  XFile? selfieImage;
  double faceMatchSimilarity = 0.0;
  bool faceMatched = false;

  bool livenessPassed = false;
  late DeepfakeAnalysisResult deepfakeResult;
  String verificationId = "";

  @override
  void initState() {
    super.initState();
    currentStep = widget.initialStep;
    _generateVerificationId();
    ocrData = OCRResultData(
      rawText: '',
      documentType: DocumentType.unknown,
      documentTypeLabel: 'Unknown',
      name: '',
      idNumber: '',
      dateOfBirth: '',
      confidenceScore: 0.0,
    );
    deepfakeResult = DeepfakeAnalysisResult(
      textureScore: 0.0,
      texturePassed: false,
      motionScore: 0.0,
      motionPassed: false,
      landmarkScore: 0.0,
      landmarkPassed: false,
      fftScore: 0.0,
      fftPassed: false,
      overallConfidence: 0.0,
      riskLevel: "PENDING",
      isAuthentic: false,
    );
  }

  void _generateVerificationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    verificationId = "DS-2026-$timestamp";
  }

  void goToStep(int step) {
    setState(() {
      currentStep = step.clamp(1, 8);
    });
  }

  void previousStep() {
    if (currentStep > 1) {
      setState(() {
        currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: currentStep == 1 || currentStep == 8,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentStep > 1 && currentStep < 8) {
          previousStep();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: currentStep < 8
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: previousStep,
                )
              : null,
          title: Text(
            "Video KYC ($currentStep/8)",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            if (currentStep < 8)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Step $currentStep",
                      style: const TextStyle(
                        color: AppTheme.primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              )
          ],
        ),
        body: SafeArea(
          child: _buildCurrentScreen(),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (currentStep) {
      case 1:
        return Screen1Start(
          onStart: () => goToStep(2),
        );
      case 2:
        return Screen2UploadPan(
          initialImage: panImage,
          onContinue: (XFile image) {
            setState(() {
              panImage = image;
            });
            goToStep(3);
          },
        );
      case 3:
        return Screen3OcrProcessing(
          panImage: panImage!,
          onConfirm: (
            OCRResultData confirmedOcrData,
          ) {
            // Sprint 5 fix: store the real OCRResultData (preserves DocumentType,
            // documentNumber, name, dob, gender, extraField — not recreated with unknown)
            setState(() {
              detectedDocType = confirmedOcrData.documentTypeLabel;
              ocrData = confirmedOcrData;
            });
            goToStep(4);
          },
          onRetry: () => goToStep(2),
        );
      case 4:
        return Screen4LiveVerification(
          onCapture: (XFile selfie) {
            setState(() {
              selfieImage = selfie;
            });
            goToStep(5);
          },
        );
      case 5:
        return Screen5FaceRecognition(
          panImage: panImage!,
          selfieImage: selfieImage!,
          ocrData: ocrData,
          onSuccess: (double similarityScore) {
            setState(() {
              faceMatchSimilarity = similarityScore;
              faceMatched = FaceMatchPolicy.decisionForScore(similarityScore).isVerified;
            });
            goToStep(6);
          },
          onRetry: () => goToStep(4),
        );
      case 6:
        return Screen6Liveness(
          onComplete: () {
            setState(() {
              livenessPassed = true;
            });
            goToStep(7);
          },
        );
      case 7:
        return Screen7AiVerification(
          selfieImage: selfieImage,
          onComplete: (DeepfakeAnalysisResult result) {
            setState(() {
              deepfakeResult = result;
            });
            goToStep(8);
          },
        );
      case 8:
        return Screen8FinalReport(
          verificationId: verificationId,
          ocrData: ocrData,
          faceMatchSimilarity: faceMatchSimilarity,
          livenessPassed: livenessPassed,
          deepfakeResult: deepfakeResult,
          panImage: panImage,
          selfieImage: selfieImage,
        );
      default:
        return Screen1Start(onStart: () => goToStep(2));
    }
  }
}
