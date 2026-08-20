import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import '../../services/face_recognition_service.dart';
import '../../services/ocr_service.dart';
import '../../services/service_locator.dart';
import '../../theme/app_theme.dart';

class Screen5FaceRecognition extends StatefulWidget {
  final XFile panImage;
  final XFile selfieImage;
  final OCRResultData ocrData;
  final Function(double similarityScore) onSuccess;
  final VoidCallback onRetry;

  const Screen5FaceRecognition({
    super.key,
    required this.panImage,
    required this.selfieImage,
    required this.ocrData,
    required this.onSuccess,
    required this.onRetry,
  });

  @override
  State<Screen5FaceRecognition> createState() => _Screen5FaceRecognitionState();
}

class _Screen5FaceRecognitionState extends State<Screen5FaceRecognition> {
  bool isMatching = true;
  double? similarityScore;
  bool isSuccess = false;
  String? rejectionReason;
  String matchStatus = 'FAILED';
  String matchReason = 'UNAVAILABLE';

  final FaceRecognitionService faceService = ServiceLocator().faceRecognitionService;

  @override
  void initState() {
    super.initState();
    _performMatch();
  }

  Future<void> _performMatch() async {
    setState(() {
      isMatching = true;
      rejectionReason = null;
    });

    try {
      // await faceService.loadModel(); // Already loaded in locator

      // 1. QUALITY CHECK ON SELFIE
      final selfieQuality = await faceService.checkFaceQuality(widget.selfieImage);
      if (!selfieQuality.isValid) {
        if (mounted) {
          setState(() {
            isMatching = false;
            isSuccess = false;
            similarityScore = null;
            rejectionReason = selfieQuality.rejectionReason ?? "Selfie face quality failed.";
          });
        }
        return;
      }

      // 2. EMBEDDINGS COMPARISON
      double? calculatedScore;
      if (kIsWeb) {
        calculatedScore = await faceService.compareFacesWeb(widget.panImage, widget.selfieImage);
      } else {
        // Use the document type so Aadhaar does not inherit PAN layout rules.
        final panEmbed = await faceService.getEmbedding(
          widget.panImage,
          isDocument: true,
          documentType: widget.ocrData.documentType,
        );
        final selfieEmbed = await faceService.getEmbedding(
          widget.selfieImage,
          isDocument: false,
        );
        calculatedScore = faceService.compareFaces(panEmbed, selfieEmbed);
      }
      
      final decision = calculatedScore != null ? faceService.decisionForScore(calculatedScore) : const FaceMatchDecision(status: 'FAILED', reason: 'Match unavailable', isVerified: false, confidencePercentage: 0.0);

      if (mounted) {
        setState(() {
          // Display the mapped 0-100% score instead of raw cosine
          similarityScore = decision.confidencePercentage;
          matchStatus = decision.status;
          matchReason = decision.reason;
          isSuccess = decision.isVerified;
          isMatching = false;
          if (!isSuccess) {
            rejectionReason = 'Face similarity is below the required verification threshold.';
          }
        });
      }
    } on FaceQualityException catch (e) {
      debugPrint("FACE QUALITY REJECTED: $e");
      if (mounted) {
        setState(() {
          isMatching = false;
          isSuccess = false;
          similarityScore = null;
          matchStatus = 'QUALITY REJECTED';
          matchReason = 'RETRY REQUIRED';
          rejectionReason = e.message;
        });
      }
    } catch (e) {
      debugPrint("FACE MATCH AI ERROR: $e");
      if (mounted) {
        setState(() {
          isMatching = false;
          isSuccess = false;
          similarityScore = null;
          matchStatus = 'AI FAILURE';
          matchReason = 'EMBEDDING FAILED';
          rejectionReason = 'Unable to process the faces. Please retry.';
        });
      }
    }
  }

  @override
  void dispose() {
    // faceService.dispose(); // Don't dispose singleton
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          const Text(
            "Face Recognition",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMatching
                ? "Comparing ID document face with live selfie..."
                : "Facial similarity comparison completed.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 25),

          // SIDE BY SIDE IMAGE PREVIEWS
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      "ID Photo",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: kIsWeb
                          ? Image.network(
                              widget.panImage.path,
                              height: 130,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(widget.panImage.path),
                              height: 130,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Icon(Icons.sync_alt, color: AppTheme.primaryAccent, size: 28),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      "Live Selfie",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: kIsWeb
                          ? Image.network(
                              widget.selfieImage.path,
                              height: 130,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(widget.selfieImage.path),
                              height: 130,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // SIMILARITY DISPLAY CARD
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isMatching
                      ? Colors.white12
                      : (isSuccess
                          ? Colors.greenAccent.withValues(alpha: 0.5)
                          : Colors.redAccent.withValues(alpha: 0.5)),
                ),
              ),
              child: isMatching
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.primaryColor),
                        const SizedBox(height: 20),
                        const Text(
                          "Comparing Embeddings...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "${faceService.backendDisplayName} 192-D Vector",
                          style: const TextStyle(
                            color: AppTheme.primaryAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSuccess
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            isSuccess ? Icons.check_circle : Icons.cancel,
                            size: 60,
                            color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Confidence Score",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          similarityScore != null ? "${similarityScore!.toStringAsFixed(1)}%" : "--",
                          style: TextStyle(
                            color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSuccess
                                ? Colors.green.withValues(alpha: 0.2)
                                : (matchStatus == 'AI FAILURE' ? Colors.orange.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$matchStatus\n$matchReason',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSuccess
                                  ? Colors.greenAccent
                                  : (matchStatus == 'AI FAILURE' ? Colors.orangeAccent : Colors.redAccent),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (rejectionReason != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            rejectionReason!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSuccess ? Colors.white70 : Colors.redAccent.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // BOTTOM ACTIONS
          if (!isMatching)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: isSuccess
                  ? ElevatedButton(
                      onPressed: similarityScore != null ? () => widget.onSuccess(similarityScore!) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        "Continue to Liveness Check",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: widget.onRetry,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        "Retry Face Capture",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
