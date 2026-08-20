import 'ocr_models.dart';
import 'document_parser.dart';

class AadhaarParser implements DocumentParser {
  static final RegExp _aadhaarRegex = RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b');
  static final RegExp _dobRegex = RegExp(r'\b\d{2}[/-]\d{2}[/-]\d{4}\b');
  static final RegExp _yobRegex = RegExp(r'\b(?:19|20)\d{2}\b');
  
  static final List<String> _noisyWords = [
    'GOVERNMENT', 'INDIA', 'AADHAAR', 'DOB', 'YEAR', 'BIRTH', 'MALE', 'FEMALE',
    'FATHER', 'HUSBAND', 'WIFE', 'CARE', 'OF', 'ADDRESS', 'VID', 'ENROLLMENT', 'ISSUED'
  ];

  @override
  ExtractedIdentity? parse(List<OcrTextBlock> blocks, {String? rawText}) {
    String? idNumber;
    String? dateOfBirth;
    String? name;
    String? gender;

    // Sort blocks top-to-bottom
    final sortedBlocks = List<OcrTextBlock>.from(blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    // 1. Extract Aadhaar Number
    for (final block in sortedBlocks) {
      final match = _aadhaarRegex.firstMatch(block.text);
      if (match != null) {
        idNumber = match.group(0)!.replaceAll(' ', '');
        break;
      }
    }
    
    // 2. Extract DOB or YOB
    for (final block in sortedBlocks) {
      final text = block.text.toUpperCase();
      final dobMatch = _dobRegex.firstMatch(text);
      if (dobMatch != null) {
        dateOfBirth = dobMatch.group(0)!.replaceAll('-', '/');
        break;
      }
      
      if (text.contains('YOB') || text.contains('YEAR OF BIRTH')) {
        final yobMatch = _yobRegex.firstMatch(text);
        if (yobMatch != null) {
          dateOfBirth = yobMatch.group(0);
          break;
        }
      }
    }
    
    // 3. Extract Gender
    for (final block in sortedBlocks) {
      final text = block.text.toUpperCase();
      if (text.contains('MALE') && !text.contains('FEMALE')) {
        gender = 'Male';
        break;
      } else if (text.contains('FEMALE')) {
        gender = 'Female';
        break;
      } else if (text.contains('TRANSGENDER')) {
        gender = 'Transgender';
        break;
      }
    }

    // 4. Extract Name
    // Usually, Name is the first line after "Government of India" (in local language and English)
    // We'll skip noise words and pick the most likely candidate
    List<String> nameCandidates = [];
    for (final block in sortedBlocks) {
      final text = block.text.toUpperCase().trim();
      
      if (text.length < 3) continue;
      if (RegExp(r'[0-9]').hasMatch(text)) continue;
      
      bool isNoise = false;
      for (final noise in _noisyWords) {
        if (text.contains(noise)) {
          isNoise = true;
          break;
        }
      }
      
      // Also ignore local language scripts by checking if there's any English character
      if (!RegExp(r'[A-Za-z]').hasMatch(text)) {
         isNoise = true;
      }
      
      if (!isNoise) {
        nameCandidates.add(text);
      }
    }
    
    if (nameCandidates.isNotEmpty) {
      // Very often, Aadhaar has the local language name first, then English name.
      // So we pick the last candidate before DOB or gender, or just the first clean English string.
      name = nameCandidates[0]; 
      
      // To improve, we can pick the candidate closest in vertical space above the DOB line.
      // For now, simple selection.
    }

    if (idNumber == null && name == null) {
      return null;
    }

    return ExtractedIdentity(
      documentType: DocumentType.aadhaar,
      documentTypeLabel: 'Aadhaar Card',
      idNumber: idNumber ?? '',
      name: name ?? '',
      dateOfBirth: dateOfBirth,
      gender: gender,
      rawText: rawText,
    );
  }
}
