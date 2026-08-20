import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import '../services/ocr_service.dart';
import '../services/ocr/ocr_models.dart';
import '../theme/app_theme.dart';
import 'face_match_screen.dart';

/// OCR Result Screen — Document Upload path
///
/// ROOT CAUSE FIX: The old implementation had its own primitive
/// extractFields() method that took the first non-digit line as the name.
/// This caused "HHI NAME" to appear instead of the real name.
///
/// FIX: Now exclusively delegates to OCRService — the single source of truth
/// for all document parsing. No duplicate parsing logic in this screen.
class OCRResultScreen extends StatefulWidget {
  final XFile imageFile;

  const OCRResultScreen({
    super.key,
    required this.imageFile,
  });

  @override
  State<OCRResultScreen> createState() => _OCRResultScreenState();
}

class _OCRResultScreenState extends State<OCRResultScreen> {
  bool isLoading = true;
  OCRResultData? _result;
  final OCRService _ocrService = OCRService();

  @override
  void initState() {
    super.initState();
    _processOCR();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _processOCR() async {
    try {
      // Single source of truth: always use OCRService
      final result = await _ocrService.processPanDocument(widget.imageFile);
      if (mounted) {
        setState(() {
          _result = result;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('OCR Error: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'DeepShield OCR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  SizedBox(height: 20),
                  Text(
                    'Extracting document data...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : _buildResultBody(),
    );
  }

  Widget _buildResultBody() {
    final r = _result;
    if (r == null) {
      return const Center(
        child: Text(
          'Could not process document.',
          style: TextStyle(color: Colors.redAccent, fontSize: 16),
        ),
      );
    }

    final bool hasDocNum = r.documentNumber.isNotEmpty;
    final bool hasName = r.name.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document preview
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: kIsWeb
                ? Image.network(
                    widget.imageFile.path,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(widget.imageFile.path),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),

          const SizedBox(height: 24),

          // Document type + confidence badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: r.confidenceScore >= 60
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: r.confidenceScore >= 60
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
                      r.confidenceScore >= 60
                          ? Icons.verified_rounded
                          : Icons.warning_amber_rounded,
                      color: r.confidenceScore >= 60
                          ? Colors.greenAccent
                          : Colors.amberAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      r.documentTypeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${r.confidenceScore.toInt()}% confidence',
                  style: TextStyle(
                    color: r.confidenceScore >= 60
                        ? Colors.greenAccent
                        : Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Extracted Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _infoCard(
            icon: Icons.security,
            label: 'Name',
            value: hasName ? r.name : 'Not detected',
            isDetected: hasName,
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.badge_outlined,
            label: _docNumberLabel(r.documentType),
            value: hasDocNum ? r.documentNumber : 'Not detected',
            isDetected: hasDocNum,
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: r.dob.isNotEmpty ? r.dob : 'Not detected',
            isDetected: r.dob.isNotEmpty,
          ),
          if (r.gender != null && r.gender!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _infoCard(
              icon: Icons.wc_outlined,
              label: 'Gender',
              value: r.gender!,
              isDetected: true,
            ),
          ],

          if (r.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.amberAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.errorMessage!,
                      style: const TextStyle(
                          color: Colors.amberAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Raw text expandable
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Raw OCR Text',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            iconColor: Colors.white54,
            collapsedIconColor: Colors.white54,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  r.rawText?.isEmpty ?? true ? 'No text detected' : r.rawText!,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FaceMatchScreen(documentImage: widget.imageFile),
                  ),
                );
              },
              icon: const Icon(Icons.face_retouching_natural),
              label: const Text(
                'Continue to Face Match',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  String _docNumberLabel(DocumentType docType) {
    switch (docType) {
      case DocumentType.pan:
        return 'PAN Number';
      case DocumentType.aadhaar:
        return 'Aadhaar Number';
      case DocumentType.drivingLicence:
        return 'Licence Number';
      case DocumentType.passport:
        return 'Passport Number';
      case DocumentType.voterId:
        return 'EPIC Number';
      case DocumentType.unknown:
        return 'Document Number';
    }
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDetected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDetected
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryAccent, size: 22),
          ),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: isDetected ? Colors.white : Colors.white38,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isDetected ? Icons.check_circle_rounded : Icons.cancel_outlined,
            color: isDetected
                ? Colors.greenAccent
                : Colors.white24,
            size: 20,
          ),
        ],
      ),
    );
  }
}