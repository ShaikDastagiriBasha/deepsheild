import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import '../services/face_recognition_service.dart';
import '../services/service_locator.dart';
import '../theme/app_theme.dart';

class FaceMatchScreen extends StatefulWidget {
  final XFile documentImage;

  const FaceMatchScreen({
    super.key,
    required this.documentImage,
  });

  @override
  State<FaceMatchScreen> createState() => _FaceMatchScreenState();
}

class _FaceMatchScreenState extends State<FaceMatchScreen> {
  final FaceRecognitionService faceService = ServiceLocator().faceRecognitionService;
  CameraController? controller;
  bool loading = true;
  XFile? selfieImage;
  double? similarity;
  bool verified = false;
  bool isSaving = false;
  bool isCapturing = false;
  String matchStatus = 'FAILED';
  String matchReason = 'UNAVAILABLE';

  @override
  void initState() {
    super.initState();
    initializeCamera();
    // faceService.loadModel(); // Already loaded in locator
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller!.initialize();

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('Camera Error: $e');
    }
  }

  // ── Firestore Save ─────────────────────────────────────────────────────────
  // ROOT CAUSE FIX: The old saveVerification() saved to 'scans' but did NOT
  // include 'userUid'. History screen queries:
  //   .where('userUid', isEqualTo: userUid)
  // So every document saved here was invisible to History.
  //
  // FIX: Now includes userUid, username, email, verificationId, and all
  // required schema fields matching screen8_final_report.dart's payload.
  Future<void> saveVerification() async {
    if (isSaving) return;
    setState(() => isSaving = true);

    debugPrint('════════ FIRESTORE SAVE — FaceMatchScreen — START ════════');

    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('FIRESTORE ── currentUser: ${user?.uid}');

      final String userUid = user?.uid ?? 'guest_user';
      final String userEmail = user?.email ?? 'user@deepshield.ai';
      final String username = user?.displayName ??
          (userEmail.contains('@') ? userEmail.split('@').first : 'User');
      final String verificationId =
          'DS-${DateTime.now().millisecondsSinceEpoch}';

      // Sanitise doubles — Firestore rejects NaN/Infinity
      final double? safeSimilarity =
          (similarity?.isNaN == true || similarity?.isInfinite == true) ? 0.0 : similarity;

      final Map<String, dynamic> payload = {
        'verificationId': verificationId,
        'userUid': userUid, // CRITICAL: required for History query
        'username': username,
        'email': userEmail,
        'documentType': 'Identity Document',
        'documentNumber': 'N/A',
        'panNumber': 'N/A',
        'personName': username,
        'name': username,
        'dateOfBirth': 'N/A',
        'dob': 'N/A',
        'faceMatchScore': safeSimilarity,
        'faceComparisonStatus': safeSimilarity == null ? 'unavailable' : 'completed',
        'matchScore': safeSimilarity ?? 0.0,
        'ocrConfidence': 0.0,
        'livenessPassed': false,
        'deepfakeConfidence': 0.0,
        'deepfakeRiskLevel': 'LOW RISK',
        'riskLevel': 'LOW RISK',
        'textureScore': 0.0,
        'motionScore': 0.0,
        'landmarkScore': 0.0,
        'fftScore': 0.0,
        'overallConfidence': safeSimilarity,
        'status': verified ? 'VERIFIED' : 'FAILED',
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': 'Android Physical Device / Flutter Engine',
      };

      debugPrint('FIRESTORE ── Payload fields: ${payload.length}');
      debugPrint('FIRESTORE ── userUid      : $userUid');
      debugPrint('FIRESTORE ── faceMatchScore: $safeSimilarity');
      debugPrint('FIRESTORE ── status       : ${payload['status']}');
      debugPrint('FIRESTORE ── collection   : scans');

      final docRef =
          await FirebaseFirestore.instance.collection('scans').add(payload);

      debugPrint('FIRESTORE ── Document ID: ${docRef.id}');
      debugPrint('FIRESTORE ── Path: scans/${docRef.id}');
      debugPrint('════════ FIRESTORE SAVE — SUCCESS ════════');

      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification saved to cloud'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('════════ FIRESTORE SAVE — EXCEPTION ════════');
      debugPrint('FIRESTORE ── Exception: $e');
      debugPrint('FIRESTORE ── Stack:\n$stackTrace');
      debugPrint('════════ END EXCEPTION ════════');

      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save verification. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> captureSelfie() async {
    if (controller == null ||
        !controller!.value.isInitialized ||
        isSaving ||
        isCapturing) {
      return;
    }

    setState(() => isCapturing = true);
    try {
      final XFile image = await controller!.takePicture();
      setState(() {
        selfieImage = image;
      });

      final matchCompleted = await performFaceMatch();
      if (matchCompleted) {
        await saveVerification();
      }
    } catch (e) {
      debugPrint('Capture Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unable to capture the selfie. Please try again.'),
        ));
      }
    } finally {
      if (mounted) {
        setState(() => isCapturing = false);
      }
    }
  }

  Future<bool> performFaceMatch() async {
    if (selfieImage == null) return false;
    try {
      double? score;
      if (kIsWeb) {
        score = await faceService.compareFacesWeb(widget.documentImage, selfieImage!);
      } else {
        final documentEmbedding = await faceService
            .getEmbedding(widget.documentImage, isDocument: true);
        final selfieEmbedding = await faceService.getEmbedding(selfieImage!);
        score = faceService.compareFaces(documentEmbedding, selfieEmbedding);
      }

      final decision = score != null ? faceService.decisionForScore(score) : const FaceMatchDecision(status: 'FAILED', reason: 'Match unavailable', isVerified: false, confidencePercentage: 0.0);

      if (mounted) {
        setState(() {
          similarity = score;
          matchStatus = decision.status;
          matchReason = decision.reason;
          verified = decision.isVerified;
        });
      }
      return true;
    } catch (e) {
      debugPrint('FACE MATCH ERROR: $e');
      if (mounted) {
        setState(() {
          similarity = null;
          matchStatus = 'UNAVAILABLE';
          matchReason = 'UNAVAILABLE';
          verified = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to compare the faces. Face match unavailable.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return true; // Save the failure to history
    }
  }

  Color get _matchColor {
    if (verified) return Colors.greenAccent;
    return Colors.redAccent;
  }

  @override
  void dispose() {
    controller?.dispose();
    // faceService.dispose(); // Don't dispose singleton
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading || controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Face Match Verification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              'DeepShield AI Face Verification',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture a live selfie to compare with your document',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Camera preview
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 350,
                child: CameraPreview(controller!),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: isSaving || isCapturing ? null : captureSelfie,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 4,
                ),
                icon: isSaving || isCapturing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt_rounded),
                label: Text(
                  isSaving
                      ? 'Saving...'
                      : (isCapturing ? 'Comparing...' : 'Capture Selfie'),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Results section
            if (selfieImage != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Document',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: kIsWeb
                              ? Image.network(widget.documentImage.path, height: 140, fit: BoxFit.cover)
                              : Image.file(File(widget.documentImage.path), height: 140, fit: BoxFit.cover),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.compare_arrows_rounded,
                      color: AppTheme.primaryAccent,
                      size: 30,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Live Selfie',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: kIsWeb
                              ? Image.network(selfieImage!.path, height: 140, fit: BoxFit.cover)
                              : Image.file(File(selfieImage!.path), height: 140, fit: BoxFit.cover),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _matchColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _matchColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      verified ? Icons.verified_user : Icons.warning_rounded,
                      color: _matchColor,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      similarity != null ? similarity!.toStringAsFixed(4) : '--',
                      style: TextStyle(
                        color: _matchColor,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Match Score',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _matchColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            matchStatus,
                            style: TextStyle(
                              color: _matchColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            matchReason,
                            style: TextStyle(
                              color: _matchColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
