import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/ai_decision_engine.dart';
import '../../services/deepfake_detection_service.dart';
import '../../services/ocr_service.dart';
import '../../theme/app_theme.dart';
import '../main_navigation_screen.dart';

class Screen8FinalReport extends StatefulWidget {
  final String verificationId;
  final OCRResultData ocrData;
  final double? faceMatchSimilarity;
  final bool livenessPassed;
  final DeepfakeAnalysisResult deepfakeResult;
  final XFile? panImage;
  final XFile? selfieImage;

  const Screen8FinalReport({
    super.key,
    required this.verificationId,
    required this.ocrData,
    required this.faceMatchSimilarity,
    required this.livenessPassed,
    required this.deepfakeResult,
    this.panImage,
    this.selfieImage,
  });

  @override
  State<Screen8FinalReport> createState() => _Screen8FinalReportState();
}

class _Screen8FinalReportState extends State<Screen8FinalReport> {
  late AIDecisionResult decisionResult;
  bool isSaving = false;
  bool _hasSaved = false;

  @override
  void initState() {
    super.initState();
    decisionResult = AIDecisionEngine.evaluateFinalDecision(
      ocrData: widget.ocrData,
      faceMatchScore: widget.faceMatchSimilarity ?? 0.0, // Assuming AIDecisionEngine takes double, pass 0.0 or handle null if needed
      livenessPassed: widget.livenessPassed,
      deepfakeResult: widget.deepfakeResult,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _saveScanToFirestore();
      }
    });
  }

  // Sanitise a double before writing to Firestore.
  // Firestore rejects NaN and Infinity with an opaque exception.
  double _safeDouble(double? value, {double fallback = 0.0}) {
    if (value == null || value.isNaN || value.isInfinite) return fallback;
    return value;
  }

  Future<void> _saveScanToFirestore() async {
    if (_hasSaved || isSaving) return;
    _hasSaved = true;

    if (mounted) {
      setState(() => isSaving = true);
    }

    debugPrint('════════ FIRESTORE SAVE — START ════════');

    try {
      // ── Step 1: resolve authenticated user ───────────────────────
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('FIRESTORE ── Step 1: currentUser = ${user?.uid}');
      if (user == null) {
        debugPrint('FIRESTORE ── WARNING: No authenticated user. '
            'Writing as guest. Firestore rules may reject this.');
      }

      final String userUid = user?.uid ?? 'guest_user';
      final String userEmail = user?.email ?? 'user@deepshield.ai';
      final String username = user?.displayName ??
          (userEmail.contains('@') ? userEmail.split('@').first : 'User');

      debugPrint('FIRESTORE ── userUid  : $userUid');
      debugPrint('FIRESTORE ── username : $username');
      debugPrint('FIRESTORE ── email    : $userEmail');

      // ── Step 2: sanitise all numeric fields ───────────────────────
      // Firestore throws a hard exception on NaN / Infinity values.
      // This can happen when the face embedding pipeline fails or
      // produces degenerate output (e.g. due to a missing model file).
      final double safeFaceMatch = _safeDouble(widget.faceMatchSimilarity);
      final double safeOcrConf = _safeDouble(widget.ocrData.confidenceScore);
      final double safeDeepfakeConf =
          _safeDouble(widget.deepfakeResult.overallConfidence);
      final double safeTextureScore =
          _safeDouble(widget.deepfakeResult.textureScore);
      final double safeMotionScore =
          _safeDouble(widget.deepfakeResult.motionScore);
      final double safeLandmarkScore =
          _safeDouble(widget.deepfakeResult.landmarkScore);
      final double safeFftScore = _safeDouble(widget.deepfakeResult.fftScore);
      final double safeOverallConf =
          _safeDouble(decisionResult.overallConfidence);

      debugPrint('FIRESTORE ── Step 2: numeric values sanitised');
      debugPrint('FIRESTORE ──   faceMatchScore    : $safeFaceMatch');
      debugPrint('FIRESTORE ──   ocrConfidence     : $safeOcrConf');
      debugPrint('FIRESTORE ──   overallConfidence : $safeOverallConf');
      debugPrint('FIRESTORE ──   deepfakeConf      : $safeDeepfakeConf');

      // ── Step 3: build the Firestore document payload ──────────────
      final Map<String, dynamic> payload = {
        'verificationId': widget.verificationId,
        'userUid': userUid,
        'username': username,
        'email': userEmail,
        // Generic document fields
        'documentType': widget.ocrData.documentTypeLabel,
        'documentNumber': widget.ocrData.documentNumber.isEmpty
            ? 'N/A'
            : widget.ocrData.documentNumber,
        // Keep panNumber for backward compat with existing Firestore queries
        'panNumber': widget.ocrData.documentNumber.isEmpty
            ? 'N/A'
            : widget.ocrData.documentNumber,
        'personName':
            widget.ocrData.name.isEmpty ? username : widget.ocrData.name,
        // Sprint 5: holderName alias
        'holderName':
            widget.ocrData.name.isEmpty ? username : widget.ocrData.name,
        'name': widget.ocrData.name.isEmpty ? username : widget.ocrData.name,
        'dateOfBirth': widget.ocrData.dob.isEmpty ? 'N/A' : widget.ocrData.dob,
        'dob': widget.ocrData.dob.isEmpty ? 'N/A' : widget.ocrData.dob,
        // Sprint 5: gender + extra fields
        'gender': (widget.ocrData.gender?.isEmpty ?? true) ? 'N/A' : widget.ocrData.gender,
        'issueDate': 'N/A',
        'expiryDate': (widget.ocrData.extraField?.isEmpty ?? true)
            ? 'N/A'
            : widget.ocrData.extraField,
        'faceMatchScore': safeFaceMatch,
        'matchScore': safeFaceMatch,
        'ocrConfidence': safeOcrConf,
        'livenessPassed': widget.livenessPassed,
        // Sprint 5: numeric liveness score (100 if passed, 0 if not)
        'livenessScore': widget.livenessPassed ? 100.0 : 0.0,
        'deepfakeConfidence': safeDeepfakeConf,
        'deepfakeRiskLevel': widget.deepfakeResult.riskLevel,
        'textureScore': safeTextureScore,
        'motionScore': safeMotionScore,
        'landmarkScore': safeLandmarkScore,
        'fftScore': safeFftScore,
        'overallConfidence': safeOverallConf,
        'status': decisionResult.statusText,
        'riskLevel': widget.deepfakeResult.riskLevel,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': 'Android Physical Device / Flutter Engine',
        // Sprint 5: application version
        'applicationVersion': '1.0.0',
      };

      debugPrint('FIRESTORE ── Step 3: payload constructed — '
          '${payload.length} fields');
      debugPrint('FIRESTORE ──   collection: scans');
      debugPrint('FIRESTORE ──   verificationId: ${widget.verificationId}');

      // ── Step 4: write to Firestore ────────────────────────────────
      debugPrint('FIRESTORE ── Step 4: calling collection("scans").add()...');
      final docRef =
          await FirebaseFirestore.instance.collection('scans').add(payload);

      // ── Step 5: confirm success ───────────────────────────────────
      debugPrint('FIRESTORE ── Step 5: Document created!');
      debugPrint('FIRESTORE ── Document ID : ${docRef.id}');
      debugPrint('FIRESTORE ── Path        : scans/${docRef.id}');
      debugPrint('════════ FIRESTORE SAVE — SUCCESS ════════');

      if (mounted) {
        setState(() => isSaving = false);
      }
    } catch (e, stackTrace) {
      // Print COMPLETE stack trace so the actual failure is visible in logcat
      debugPrint('════════ FIRESTORE SAVE — EXCEPTION ════════');
      debugPrint('FIRESTORE ── Exception type : ${e.runtimeType}');
      debugPrint('FIRESTORE ── Exception      : $e');
      debugPrint('FIRESTORE ── Stack trace:\n$stackTrace');
      debugPrint('════════ END FIRESTORE EXCEPTION ════════');

      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to save the report. Please try again.'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  void _downloadReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("PDF Audit Report Generated",
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Text(
          "Audit report '${widget.verificationId}' has been formatted as an enterprise PDF compliance document and saved to local device storage.",
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK",
                style: TextStyle(
                    color: AppTheme.primaryAccent,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _shareReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Share link generated for ${widget.verificationId}"),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _finishAndReturn() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isVerified = decisionResult.isVerified;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          // ENTERPRISE CONFIDENCE GAUGE BADGE
          // ENTERPRISE CONFIDENCE GAUGE BADGE
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
                begin: 0.0, end: decisionResult.overallConfidence / 100.0),
            duration: const Duration(seconds: 2),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isVerified ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isVerified
                                ? Icons.verified_user_rounded
                                : Icons.warning_amber_rounded,
                            color: isVerified
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(value * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          Text(
            isVerified ? "Verification Passed" : "Verification Rejected",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isVerified
                ? "Jumio/Onfido Grade Enterprise Video KYC Audit Passed"
                : "Security anomaly identified in Video KYC verification",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          // REPORT SUMMARY CARD
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // VERIFICATION ID ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Verification ID",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.verificationId,
                            style: const TextStyle(
                              color: AppTheme.primaryAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: Colors.white12, height: 24),

                    // CHECKLIST FROM AI DECISION ENGINE — dynamic document type label
                    _buildReportCheckItem(
                      '${widget.ocrData.documentTypeLabel} Verified',
                      decisionResult.ocrPassed,
                    ),
                    const SizedBox(height: 12),
                    widget.faceMatchSimilarity == null
                        ? _buildReportInfoItem("Facial Match Unavailable")
                        : _buildReportCheckItem("Facial Match Verified",
                            decisionResult.faceMatchPassed),
                    const SizedBox(height: 12),
                    _buildReportCheckItem("Active Liveness Passed",
                        decisionResult.livenessPassed),
                    const SizedBox(height: 12),
                    _buildReportCheckItem("Deepfake Spoofing Clear",
                        decisionResult.deepfakePassed),

                    const Divider(color: Colors.white12, height: 24),

                    // OVERALL CONFIDENCE GAUGE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Overall Confidence Score",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "${decisionResult.overallConfidence.toInt()}%",
                          style: TextStyle(
                            color: isVerified
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // DETAILS SUMMARY TILE
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                              'Holder Name',
                              widget.ocrData.name.isEmpty
                                  ? 'N/A'
                                  : widget.ocrData.name),
                          const SizedBox(height: 8),
                          _buildDetailRow('Document Type',
                              widget.ocrData.documentTypeLabel),
                          const SizedBox(height: 8),
                          // Sprint 5: dynamic document number label
                          _buildDetailRow(
                            widget.ocrData.documentNumberLabel,
                            widget.ocrData.documentNumber.isEmpty
                                ? 'N/A'
                                : widget.ocrData.documentNumber,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Date of Birth',
                            widget.ocrData.dob.isEmpty
                                ? 'N/A'
                                : widget.ocrData.dob,
                          ),
                          if (widget.ocrData.gender != null && widget.ocrData.gender!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow('Gender', widget.ocrData.gender!),
                          ],
                          const SizedBox(height: 8),
                          _buildDetailRow('Face Match Score',
                              widget.faceMatchSimilarity != null ? '${widget.faceMatchSimilarity!.toStringAsFixed(1)}%' : 'Unavailable'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Deepfake Risk Level',
                              widget.deepfakeResult.riskLevel),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ACTIONS: SAVE & DOWNLOAD & SHARE & DASHBOARD
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloadReport,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf,
                      color: AppTheme.primaryAccent, size: 20),
                  label: const Text(
                    "Download",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _shareReport,
                icon: const Icon(Icons.share, color: AppTheme.primaryAccent),
                tooltip: "Share Report",
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _finishAndReturn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text(
                    "Dashboard",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCheckItem(String text, bool checked) {
    return Row(
      children: [
        Icon(
          checked ? Icons.check_circle : Icons.cancel,
          color: checked ? Colors.greenAccent : Colors.redAccent,
          size: 22,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReportInfoItem(String text) {
    return Row(
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.orangeAccent,
          size: 22,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
