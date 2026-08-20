import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ocr_service_paddle.dart';
import 'web_helpers/web_interop.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Supported government identity document types (auto-detected at runtime)
// ─────────────────────────────────────────────────────────────────────────────
import 'ocr/ocr_models.dart';
import 'ocr/document_classifier.dart';
import 'ocr/document_parser.dart';
import 'ocr/generic_indian_id_parser.dart';

// Legacy alias for UI compatibility
typedef OCRResultData = ExtractedIdentity;

extension OCRResultDataLegacy on ExtractedIdentity {
  String get documentNumber => idNumber;
  String get dob => dateOfBirth ?? '';
  String? get errorMessage => null;

  String get panNumber => documentType == DocumentType.pan ? idNumber : '';
  bool get isPanValid => documentType == DocumentType.pan && idNumber.length >= 10;
  bool get isDocumentValid => idNumber.isNotEmpty || name.isNotEmpty;

  String get documentNumberLabel {
    switch (documentType) {
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
}



// ─────────────────────────────────────────────────────────────────────────────
// OCR Service — single source of truth for all document parsing
//
// SPRINT 5 CRITICAL FIXES:
//
// FIX 1 — NAME extraction:
//   'NAME' was listed in _headerWords, which caused Strategy B to REJECT every
//   line that could be a valid name (because the name line often appears right
//   after the "NAME" label, and lines were matched against headerWords).
//   SOLUTION: 'NAME' is NOT in _headerWords. Header detection uses specific
//   government/document heading patterns instead.
//
// FIX 2 — DOB extraction:
//   The reject-label pattern included 'issue' at the line level, which caused
//   all dates near the word "Issue" to be skipped — even the DOB line itself
//   when it was on the same horizontal band as "Issue Date".
//   SOLUTION: reject ONLY the specific date matched on the SAME line that
//   contains a reject label. Scan all other lines freely.
//
// FIX 3 — PAN character noise:
//   OCR commonly substitutes digits for letters at letter positions in PAN.
//   SOLUTION: run a character-correction normaliser on the raw OCR text before
//   regex matching. Correction is conservative — only applied at known PAN
//   positions.
//
// FIX 4 — Label-to-value spatial matching:
//   When Strategy A2 finds a NAME label at line[i], line[i+1] may itself be
//   another sub-label (e.g. Hindi transliteration of "Name").
//   SOLUTION: check i+1 AND i+2 before falling through to Strategy B.
// ─────────────────────────────────────────────────────────────────────────────
class OCRService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);


  DocumentType _detectDocumentType(String text) {
    return DocumentClassifier.classify(text);
  }

  // ── Public entry point ─────────────────────────────────────────────────────
  Future<ExtractedIdentity> processPanDocument(XFile imageFile) async {
    try {
      debugPrint('PERF:OCR_PROCESS_START');
      final processStart = DateTime.now();

      if (kIsWeb) {
        debugPrint('OCR ── Web detected, using Browser ML...');
        try {
          final bytes = await imageFile.readAsBytes();
          final base64Img = base64Encode(bytes);
          final String jsonResult = await extractTextFromBase64Web(base64Img);
          final json = jsonDecode(jsonResult);
          if (json['success'] == true) {
            final rawText = json['text'] as String;
            final docType = _detectDocumentType(rawText);
            // Re-run the generic Indian ID parser on the extracted raw text
            // Create a single dummy block since Tesseract gives us raw text easily
            final dummyBlock = OcrTextBlock(boundingBox: const Rect.fromLTWH(0, 0, 100, 100), text: rawText, confidence: 1.0);
            DocumentParser parser = GenericIndianIdParser(detectedType: docType);
            ExtractedIdentity? identity = parser.parse([dummyBlock], rawText: rawText);
            if (identity != null) {
              return identity;
            } else {
              return _errorResult('Could not parse extracted text.');
            }
          } else {
            return _errorResult('JS OCR Error: ${json['error']}');
          }
        } catch (e) {
          debugPrint('OCR ── Browser ML failed: $e');
          return _errorResult('Failed to run Browser OCR');
        }
      }
      
      final ioFile = File(imageFile.path);
      
      String rawTextStr = '';
      List<OcrTextBlock> blocks = [];
      
      // 1. Try ML Kit FIRST for speed
      try {
        debugPrint('OCR ── Trying ML Kit (Primary, High Speed)...');
        final inputImage = InputImage.fromFile(ioFile);
        final recognized = await _textRecognizer.processImage(inputImage);
        rawTextStr = recognized.text;
        
        for (final block in recognized.blocks) {
          blocks.add(OcrTextBlock(
            boundingBox: block.boundingBox,
            text: block.text,
            confidence: 1.0,
          ));
        }
        
        if (blocks.isNotEmpty) {
          final docType = _detectDocumentType(rawTextStr);
          debugPrint('OCR ── ML Kit Classified Document Type: ${docType.name}');
          
          DocumentParser parser = GenericIndianIdParser(detectedType: docType);
          ExtractedIdentity? identity = parser.parse(blocks, rawText: rawTextStr);
          
          if (identity != null && identity.isDocumentValid) {
            final processMs = DateTime.now().difference(processStart).inMilliseconds;
            debugPrint('PERF:OCR_PROCESS_END (ML Kit)');
            debugPrint('PERF:OCR_PROCESS_MS: $processMs');
            return identity;
          } else {
             debugPrint('OCR ── ML Kit parsed but document is invalid/missing fields. Falling back to PaddleOCR...');
          }
        }
      } catch (e) {
        debugPrint('OCR ── ML Kit failed: $e');
      }

      // 2. Fallback to PaddleOCR (Higher accuracy but slower in Dart)
      blocks.clear();
      try {
        debugPrint('OCR ── Trying PaddleOCR (Secondary, High Accuracy)...');
        final paddleService = DocumentOCRModel();
        blocks = await paddleService.extractText(ioFile);
        
        // Assemble raw text from blocks
        final sorted = List<OcrTextBlock>.from(blocks)..sort((a,b) => a.boundingBox.top.compareTo(b.boundingBox.top));
        rawTextStr = sorted.map((b) => b.text).join('\n');
        
        debugPrint('OCR ── PaddleOCR extracted ${blocks.length} blocks.');
        
        final docType = _detectDocumentType(rawTextStr);
        debugPrint('OCR ── PaddleOCR Classified Document Type: ${docType.name}');
        
        DocumentParser parser = GenericIndianIdParser(detectedType: docType);
        ExtractedIdentity? identity = parser.parse(blocks, rawText: rawTextStr);
        
        if (identity != null) {
          final processMs = DateTime.now().difference(processStart).inMilliseconds;
          debugPrint('PERF:OCR_PROCESS_END (PaddleOCR)');
          debugPrint('PERF:OCR_PROCESS_MS: $processMs');
          return identity;
        }
      } catch (e) {
        debugPrint('OCR ── PaddleOCR failed: $e');
      }
      
      debugPrint('OCR ── All Parsers failed. Returning empty identity as fallback.');
      
      return ExtractedIdentity(
        documentType: DocumentType.unknown,
        documentTypeLabel: 'Unknown Document',
        idNumber: '',
        name: '',
        rawText: rawTextStr,
      );
    } catch (e, st) {
      debugPrint('OCR ERROR: $e\n$st');
      return _errorResult('OCR failed. Capture a clearer, well-lit image.');
    }
  }


  ExtractedIdentity _errorResult(String message) {
    return ExtractedIdentity(
      rawText: message, // put the error message here so the UI can log it if needed
      documentType: DocumentType.unknown,
      documentTypeLabel: 'Error',
      name: '',
      idNumber: '',
      dateOfBirth: '',
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
