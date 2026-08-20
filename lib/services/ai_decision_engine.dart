import 'deepfake_detection_service.dart';
import 'face_recognition_service.dart';
import 'ocr_service.dart';

class AIDecisionResult {
  final bool isVerified;
  final String statusText; // "VERIFIED" or "FAILED"
  final double overallConfidence;
  final String deepfakeRiskLevel;

  final bool ocrPassed;
  final bool faceMatchPassed;
  final bool livenessPassed;
  final bool deepfakePassed;

  final Map<String, dynamic> summaryChecklist;

  AIDecisionResult({
    required this.isVerified,
    required this.statusText,
    required this.overallConfidence,
    required this.deepfakeRiskLevel,
    required this.ocrPassed,
    required this.faceMatchPassed,
    required this.livenessPassed,
    required this.deepfakePassed,
    required this.summaryChecklist,
  });
}

class AIDecisionEngine {
  /// Aggregates all AI sub-system results into a final Video KYC verdict.
  ///
  /// ROOT CAUSE FIX: The old implementation used `ocrData.isPanValid` which
  /// returns true ONLY for PAN cards (requires 10-char PAN number).
  /// All other document types (Aadhaar, Passport, DL, Voter ID) always
  /// failed the OCR check regardless of extraction quality.
  ///
  /// FIX: Now uses `isDocumentValid` — any document with a detected number
  /// passes the OCR compliance check.
  static AIDecisionResult evaluateFinalDecision({
    required OCRResultData ocrData,
    required double? faceMatchScore,
    required bool livenessPassed,
    required DeepfakeAnalysisResult deepfakeResult,
  }) {
    // 1. OCR COMPLIANCE CHECK — any document with a detected number passes
    final bool ocrOk = ocrData.isDocumentValid;

    // 2. FACE MATCH CHECK uses the same policy as the face screen.
    final bool faceOk = faceMatchScore != null ? FaceMatchPolicy.decisionForScore(faceMatchScore).isVerified : false;

    // 3. LIVENESS CHECK
    final bool livenessOk = livenessPassed;

    // 4. DEEPFAKE COMPLIANCE CHECK
    final bool deepfakeOk = deepfakeResult.isAuthentic;

    // 5. OVERALL VERDICT
    final bool finalVerdict = ocrOk && faceOk && livenessOk && deepfakeOk;

    // 6. WEIGHTED OVERALL CONFIDENCE CALCULATION
    final double facePercentage = faceMatchScore != null ? FaceMatchPolicy.decisionForScore(faceMatchScore).confidencePercentage : 0.0;
    // Note: ocrData.confidenceScore is 0-1, so multiply by 100
    final double overallConfidence = (ocrData.confidenceScore * 100.0 * 0.20) +
        (facePercentage * 0.35) +
        (livenessOk ? 100.0 : 0.0) * 0.20 +
        (deepfakeResult.overallConfidence * 0.25);

    final double roundedConfidence = double.parse(
      overallConfidence.clamp(10.0, 98.5).toStringAsFixed(1),
    );

    final String docLabel = ocrData.documentTypeLabel;

    return AIDecisionResult(
      isVerified: finalVerdict,
      statusText: finalVerdict ? 'VERIFIED' : 'FAILED',
      overallConfidence: roundedConfidence,
      deepfakeRiskLevel: deepfakeResult.riskLevel,
      ocrPassed: ocrOk,
      faceMatchPassed: faceOk,
      livenessPassed: livenessOk,
      deepfakePassed: deepfakeOk,
      summaryChecklist: {
        '$docLabel Verified': ocrOk,
        'Face Matched': faceOk,
        'Liveness Passed': livenessOk,
        'Deepfake Not Detected': deepfakeOk,
      },
    );
  }
}
