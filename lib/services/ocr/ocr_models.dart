import 'dart:ui';

/// Represents a unified block of text extracted from any OCR engine (ML Kit or PaddleOCR).
class OcrTextBlock {
  final Rect boundingBox;
  final String text;
  final double confidence;

  OcrTextBlock({
    required this.boundingBox,
    required this.text,
    this.confidence = 1.0,
  });

  @override
  String toString() => 'OcrTextBlock(text: "$text", box: $boundingBox, conf: $confidence)';
}

enum DocumentType {
  pan,
  aadhaar,
  voterId,
  passport,
  drivingLicence,
  unknown
}

/// A standard data class containing fields extracted from an Identity Document.
class ExtractedIdentity {
  final DocumentType documentType;
  final String documentTypeLabel;
  final String idNumber;
  final String name;
  final String? dateOfBirth;
  final String? gender;
  final String? fatherName;
  final String? extraField;
  final double confidenceScore;
  final String? rawText;
  
  ExtractedIdentity({
    required this.documentType,
    required this.documentTypeLabel,
    required this.idNumber,
    required this.name,
    this.dateOfBirth,
    this.gender,
    this.fatherName,
    this.extraField,
    this.confidenceScore = 1.0,
    this.rawText,
  });

  Map<String, dynamic> toMap() {
    return {
      'documentType': documentType.name,
      'documentTypeLabel': documentTypeLabel,
      'idNumber': idNumber,
      'name': name,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (fatherName != null) 'fatherName': fatherName,
    };
  }

  bool get isDocumentValid => idNumber.isNotEmpty && idNumber != 'Not detected';
}
