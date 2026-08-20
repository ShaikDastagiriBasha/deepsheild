import 'ocr_models.dart';
import 'document_parser.dart';

class PanParser implements DocumentParser {
  static final RegExp _panRegex = RegExp(r'[A-Z]{5}[0-9]{4}[A-Z]{1}');
  static final RegExp _dobRegex = RegExp(r'\b\d{2}[/-]\d{2}[/-]\d{4}\b');
  
  // Words to ignore when searching for a name
  static final List<String> _noisyWords = [
    'INCOME', 'TAX', 'DEPARTMENT', 'GOVT', 'INDIA', 'GOVERNMENT',
    'PERMANENT', 'ACCOUNT', 'NUMBER', 'CARD', 'SIGNATURE',
    'FATHER', 'NAME', 'DOB', 'DATE', 'BIRTH'
  ];

  @override
  ExtractedIdentity? parse(List<OcrTextBlock> blocks, {String? rawText}) {
    String? idNumber;
    String? dateOfBirth;
    String? name;
    String? fatherName;
    
    // Sort blocks top-to-bottom
    final sortedBlocks = List<OcrTextBlock>.from(blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    // 1. Extract PAN Number
    for (final block in sortedBlocks) {
      final match = _panRegex.firstMatch(block.text.toUpperCase());
      if (match != null) {
        idNumber = match.group(0);
        break;
      }
    }
    
    // 2. Extract DOB
    for (final block in sortedBlocks) {
      final match = _dobRegex.firstMatch(block.text);
      if (match != null) {
        dateOfBirth = match.group(0)!.replaceAll('-', '/');
        break;
      }
    }
    
    // 3. Extract Name & Father's Name using Labels
    // Modern PAN cards explicitly label "नाम / Name" and "पिता का नाम / Father's Name"
    for (int i = 0; i < sortedBlocks.length; i++) {
      final text = sortedBlocks[i].text.toUpperCase();
      
      // Look for Father's Name label
      if (text.contains('FATHER') || text.contains('पिता')) {
        // The actual name is usually the next block
        fatherName = _findValidNameInNextBlocks(sortedBlocks, i + 1);
      } 
      // Look for Name label (but ensure it's not Father's Name)
      else if ((text.contains('NAME') || text.contains('नाम')) && !text.contains('FATHER') && !text.contains('पिता')) {
        name = _findValidNameInNextBlocks(sortedBlocks, i + 1);
      }
    }
    
    // Fallback if labels weren't found (e.g. poor OCR on labels)
    if (name == null || fatherName == null) {
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
        if (!isNoise) {
          nameCandidates.add(text);
        }
      }
      
      if (name == null && nameCandidates.isNotEmpty) {
        name = nameCandidates[0];
      }
      if (fatherName == null && nameCandidates.length > 1) {
        fatherName = nameCandidates[1];
      }
    }

    // Require at least PAN number or Name to consider it a valid PAN card parsing
    if (idNumber == null && name == null) {
      return null;
    }

    return ExtractedIdentity(
      documentType: DocumentType.pan,
      documentTypeLabel: 'PAN Card',
      idNumber: idNumber ?? '',
      name: name ?? '',
      dateOfBirth: dateOfBirth,
      fatherName: fatherName,
      rawText: rawText,
    );
  }
  
  String? _findValidNameInNextBlocks(List<OcrTextBlock> blocks, int startIndex) {
    for (int i = startIndex; i < blocks.length; i++) {
      final text = blocks[i].text.toUpperCase().trim();
      // Skip empty or short blocks
      if (text.length < 3) continue;
      // Names shouldn't have numbers
      if (RegExp(r'[0-9]').hasMatch(text)) continue;
      // Names shouldn't be known noise words like 'DOB'
      bool isNoise = false;
      for (final noise in ['DOB', 'DATE', 'BIRTH', 'SIGNATURE', 'ACCOUNT', 'NUMBER']) {
        if (text.contains(noise)) {
          isNoise = true;
          break;
        }
      }
      if (!isNoise) return blocks[i].text;
    }
    return null;
  }
}
