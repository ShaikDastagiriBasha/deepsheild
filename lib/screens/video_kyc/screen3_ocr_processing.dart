import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import '../../services/ocr_service.dart';
import '../../services/ocr/ocr_models.dart';
import '../../theme/app_theme.dart';

class Screen3OcrProcessing extends StatefulWidget {
  final XFile panImage;
  // Sprint 5: callback now passes the full OCRResultData to preserve
  // documentType, gender, extraField etc. (was: 5 individual string args)
  final Function(OCRResultData ocrData) onConfirm;
  final VoidCallback onRetry;

  const Screen3OcrProcessing({
    super.key,
    required this.panImage,
    required this.onConfirm,
    required this.onRetry,
  });

  @override
  State<Screen3OcrProcessing> createState() => _Screen3OcrProcessingState();
}

class _Screen3OcrProcessingState extends State<Screen3OcrProcessing> {
  bool isLoading = true;
  double ocrConfidenceScore = 0.0;
  String detectedDocType = 'Identity Document';
  String docNumberLabel = 'Document Number';
  String? ocrErrorMessage;
  // Sprint 5: store full result to pass back via callback
  OCRResultData? _ocrResult;

  late TextEditingController nameController;
  late TextEditingController docNumberController;
  late TextEditingController dobController;

  final OCRService _ocrService = OCRService();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: 'Reading...');
    docNumberController = TextEditingController(text: 'Reading...');
    dobController = TextEditingController(text: 'Reading...');
    _processOcr();
  }

  @override
  void dispose() {
    nameController.dispose();
    docNumberController.dispose();
    dobController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _processOcr() async {
    setState(() {
      isLoading = true;
      ocrErrorMessage = null;
    });

    final OCRResultData result = await _ocrService.processPanDocument(widget.panImage);

    if (mounted) {
      setState(() {
        // Store the full result for passing back to the flow
        _ocrResult = result;
        nameController.text = result.name.isEmpty ? 'Not detected' : result.name;
        docNumberController.text =
            result.documentNumber.isEmpty ? 'Not detected' : result.documentNumber;
        dobController.text = result.dob.isEmpty ? 'Not detected' : result.dob;
        ocrConfidenceScore = result.confidenceScore * 100.0; // convert 0-1 to percentage
        detectedDocType = result.documentTypeLabel;
        docNumberLabel = _docNumberLabel(result.documentType);
        ocrErrorMessage = result.errorMessage;
        isLoading = false;
      });
    }
  }

  /// Returns a user-friendly label for the document number field.
  String _docNumberLabel(dynamic docType) {
    switch (docType.toString()) {
      case 'DocumentType.pan':
        return 'PAN Number';
      case 'DocumentType.aadhaar':
        return 'Aadhaar Number';
      case 'DocumentType.drivingLicence':
        return 'Licence Number';
      case 'DocumentType.passport':
        return 'Passport Number';
      case 'DocumentType.voterId':
        return 'EPIC Number';
      default:
        return 'Document Number';
    }
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
            "OCR Document Verification",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLoading
                ? 'Extracting document metadata using Google ML Kit OCR...'
                : 'Detected: $detectedDocType — verify the extracted details below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 25),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // PAN IMAGE THUMBNAIL PREVIEW
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: kIsWeb
                        ? Image.network(
                            widget.panImage.path,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(widget.panImage.path),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),

                  const SizedBox(height: 25),

                  if (isLoading)
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Reading ID Document...",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Extracting Identity Data via ML Kit",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CONFIDENCE BADGE
                        // Document type + confidence badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: ocrConfidenceScore >= 60
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ocrConfidenceScore >= 60
                                  ? Colors.greenAccent.withValues(alpha: 0.4)
                                  : Colors.amberAccent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    ocrConfidenceScore >= 60
                                        ? Icons.verified
                                        : Icons.warning_amber_rounded,
                                    color: ocrConfidenceScore >= 60
                                        ? Colors.greenAccent
                                        : Colors.amberAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$detectedDocType Confidence',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${ocrConfidenceScore.toInt()}%',
                                style: TextStyle(
                                  color: ocrConfidenceScore >= 60
                                      ? Colors.greenAccent
                                      : Colors.amberAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (ocrErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              ocrErrorMessage!,
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        _buildFieldInput(
                          label: 'Extracted Name',
                          controller: nameController,
                          icon: Icons.security,
                        ),
                        const SizedBox(height: 16),
                        _buildFieldInput(
                          label: docNumberLabel,
                          controller: docNumberController,
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildFieldInput(
                          label: 'Extracted DOB',
                          controller: dobController,
                          icon: Icons.cake_outlined,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (!isLoading)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onRetry,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Retry Upload",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_ocrResult != null) {
                        // Sprint 5: rebuild OCRResultData with user-confirmed
                        // text values (name/number/dob may have been edited)
                        // but preserve documentType, gender, extraField from parser.
                        final confirmedData = OCRResultData(
                          rawText: _ocrResult!.rawText,
                          documentType: _ocrResult!.documentType,
                          documentTypeLabel: _ocrResult!.documentTypeLabel,
                          name: nameController.text.trim(),
                          idNumber: docNumberController.text.trim(),
                          dateOfBirth: dobController.text.trim(),
                          gender: _ocrResult!.gender,
                          extraField: _ocrResult!.extraField,
                          confidenceScore: ocrConfidenceScore,
                        );
                        widget.onConfirm(confirmedData);
                      } else {
                        // Fallback: create a minimal OCRResultData from typed values
                        widget.onConfirm(OCRResultData(
                          rawText: '',
                          documentType: DocumentType.unknown,
                          documentTypeLabel: 'Unknown',
                          name: nameController.text.trim(),
                          idNumber: docNumberController.text.trim(),
                          dateOfBirth: dobController.text.trim(),
                          confidenceScore: ocrConfidenceScore,
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Confirm Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
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

  Widget _buildFieldInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool needsValidation = false,
  }) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final bool isNotEmpty = value.text.trim().isNotEmpty &&
            value.text.trim() != 'Not detected' &&
            value.text.trim() != 'Reading...';
        final bool showValid = isNotEmpty && !needsValidation;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryAccent, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    showValid ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    color: showValid ? Colors.greenAccent : Colors.amberAccent,
                    size: 20,
                  ),
                  if (isNotEmpty && needsValidation)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text('Needs validation', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  if (showValid)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text('Valid', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
