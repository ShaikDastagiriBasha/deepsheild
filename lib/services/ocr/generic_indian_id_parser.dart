import 'ocr_models.dart';
import 'document_parser.dart';

class GenericIndianIdParser implements DocumentParser {
  final DocumentType? detectedType;

  GenericIndianIdParser({this.detectedType});

  // Common Date of Birth regex (dd/mm/yyyy or dd-mm-yyyy)
  // Removed strict word boundaries to allow for OCR noise (e.g. 01/01/1990-)
  static final RegExp _dobRegex = RegExp(r'\d{2}[/\- ]\d{2}[/\- ]\d{4}');
  
  // ID Number Regexes for various Indian IDs
  // Using negative lookbehind and lookahead to prevent partial matches in longer alphanumeric strings
  static final RegExp _panRegex = RegExp(r'(?<![A-Z0-9])[A-Z]{5}[0-9]{4}[A-Z]{1}(?![A-Z0-9])');
  // Aadhaar numbers can be formatted with spaces: 1234 5678 9012
  static final RegExp _aadhaarRegex = RegExp(r'(?<![0-9])(?:\d{4}[\s-]?){2}\d{4}(?![0-9])');
  static final RegExp _voterRegex = RegExp(r'(?<![A-Z0-9])[A-Z]{2,3}[0-9]{7}(?![A-Z0-9])');
  static final RegExp _passportRegex = RegExp(r'(?<![A-Z0-9])[A-Z]{1,2}[0-9]{6,7}(?![A-Z0-9])');
  static final RegExp _dlRegex = RegExp(r'(?<![A-Z0-9])[A-Z]{2}[0-9]{13}(?![A-Z0-9])');

  // Words that indicate the block is NOT the main person's name
  static final List<String> _noisyWords = [
    'INCOME', 'TAX', 'DEPARTMENT', 'GOVT', 'INDIA', 'GOVERNMENT',
    'PERMANENT', 'ACCOUNT', 'NUMBER', 'CARD', 'SIGNATURE',
    'FATHER', 'MOTHER', 'WIFE', 'HUSBAND', 'SPOUSE', 'ADDRESS',
    'DOB', 'DATE', 'BIRTH', 'YEAR', 'BLOOD', 'GROUP',
    'AADHAAR', 'UIDAI', 'ENROLLMENT', 'ELECTION', 'COMMISSION',
    'ELECTOR', 'PHOTO', 'IDENTITY', 'PASSPORT', 'REPUBLIC',
    'DRIVING', 'LICENCE', 'TRANSPORT', 'UNION', 'MALE', 'FEMALE', 'GENDER',
    'AUTHORITY', 'ISSUE', 'VALID', 'PIN', 'STATE', 'DISTRICT', 'MANDAL'
  ];

  @override
  ExtractedIdentity? parse(List<OcrTextBlock> blocks, {String? rawText}) {
    String? idNumber;
    String? dateOfBirth;
    String? name;
    DocumentType type = detectedType ?? DocumentType.unknown;
    
    // Sort blocks top-to-bottom
    final sortedBlocks = List<OcrTextBlock>.from(blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    // 1. Extract ID Number
    for (final block in sortedBlocks) {
      // Remove spaces and hyphens to normalize strings for robust regex matching
      final text = block.text.toUpperCase().replaceAll(' ', '').replaceAll('-', ''); 
      
      // Try DL (15 chars) - longest format first
      final dlMatch = _dlRegex.firstMatch(text);
      if (dlMatch != null) {
        idNumber = dlMatch.group(0);
        type = DocumentType.drivingLicence;
        break;
      }
      
      // Try Aadhaar (12 digits)
      final aadhaarMatch = _aadhaarRegex.firstMatch(text);
      if (aadhaarMatch != null) {
        idNumber = aadhaarMatch.group(0);
        type = DocumentType.aadhaar;
        break;
      }
      
      // Try PAN (10 chars)
      final panMatch = _panRegex.firstMatch(text);
      if (panMatch != null) {
        idNumber = panMatch.group(0);
        type = DocumentType.pan;
        break;
      }
      
      // Try Voter ID (9-10 chars)
      final voterMatch = _voterRegex.firstMatch(text);
      if (voterMatch != null) {
        idNumber = voterMatch.group(0);
        type = DocumentType.voterId;
        break;
      }
      
      // Try Passport (7-9 chars)
      final passportMatch = _passportRegex.firstMatch(text);
      if (passportMatch != null) {
        idNumber = passportMatch.group(0);
        type = DocumentType.passport;
        break;
      }
    }
    
    // Extract all lines from blocks
    List<String> allLines = [];
    for (final block in sortedBlocks) {
      final lines = block.text.split('\n');
      for (var l in lines) {
        final t = l.trim();
        if (t.isNotEmpty) allLines.add(t);
      }
    }

    // 2. Extract DOB
    final allDates = <DateTime>[];
    final dateMap = <DateTime, String>{};

    for (final line in allLines) {
      final matches = _dobRegex.allMatches(line);
      for (final match in matches) {
        final dateStr = match.group(0)!.replaceAll('-', '/');
        try {
          final parts = dateStr.split('/');
          final date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          // Basic validation for reasonable DOB
          if (date.year > 1900 && date.year <= DateTime.now().year) {
            allDates.add(date);
            dateMap[date] = dateStr;
          }
        } catch (_) {}
      }
    }

    if (allDates.isNotEmpty) {
      // The oldest date on an ID card is inherently the Date of Birth
      allDates.sort((a, b) => a.compareTo(b));
      dateOfBirth = dateMap[allDates.first];
    }

    // 3. Extract Name using Labels (Name/नाम/Elector's Name)
    for (int i = 0; i < allLines.length; i++) {
      final text = allLines[i].toUpperCase();
      
      // If we see Father/Mother/Address, we skip to avoid confusing it with Name
      if (text.contains('FATHER') || text.contains('MOTHER') || text.contains('ADDRESS') || text.contains('पिता')) {
        continue;
      } 
      // Look for Name label
      else if (text.contains('NAME') || text.contains('नाम')) {
        name = _findValidNameInNextLines(allLines, i + 1);
        if (name != null) break;
      }
    }
    
    // Fallback: If no explicit label was found, find the first line that looks like a name
    if (name == null) {
      for (final line in allLines) {
        final text = line.toUpperCase().trim();
        // Skip short words
        if (text.length < 3) continue;
        // Names generally don't contain numbers
        if (RegExp(r'[0-9]').hasMatch(text)) continue;
        
        // Skip if it contains noise words
        bool isNoise = false;
        for (final noise in _noisyWords) {
          if (text.contains(noise)) {
            isNoise = true;
            break;
          }
        }
        
        if (!isNoise) {
          // If the line is purely Telugu/Hindi chars without English, skip it so we get the English name below it
          if (!RegExp(r'[A-Za-z]').hasMatch(line)) continue;
          
          name = _cleanName(line);
          break;
        }
      }
    }

    String label = 'Indian ID';
    if (type == DocumentType.pan) {
      label = 'PAN Card';
    } else if (type == DocumentType.aadhaar) {
      label = 'Aadhaar Card';
    } else if (type == DocumentType.voterId) {
      label = 'Voter ID';
    } else if (type == DocumentType.passport) {
      label = 'Passport';
    } else if (type == DocumentType.drivingLicence) {
      label = 'Driving Licence';
    }

    return ExtractedIdentity(
      documentType: type,
      documentTypeLabel: label,
      idNumber: idNumber ?? 'Not detected',
      name: name ?? 'Not detected',
      dateOfBirth: dateOfBirth,
      rawText: rawText,
    );
  }
  String? _findValidNameInNextLines(List<String> lines, int startIndex) {
    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i];
      final text = line.toUpperCase().trim();
      if (text.length < 3) continue;
      if (RegExp(r'[0-9]').hasMatch(text)) continue;
      
      // Skip lines that have too many non-English alphabetical characters (likely regional language)
      int englishChars = RegExp(r'[A-Za-z]').allMatches(line).length;
      int otherChars = line.replaceAll(RegExp(r'[A-Za-z\s0-9]'), '').length;
      if (otherChars > englishChars) continue;
      
      bool isNoise = false;
      for (final noise in _noisyWords) {
        if (text.contains(noise)) {
          isNoise = true;
          break;
        }
      }
      if (!isNoise) {
         if (!RegExp(r'[A-Za-z]').hasMatch(line)) continue;
         String cleaned = _cleanName(line);
         if (cleaned.length > 3) return cleaned;
      }
    }
    return null;
  }

  String _cleanName(String rawName) {
    // Remove non-alphabetic/space characters first to clean up OCR noise
    String cleaned = rawName.replaceAll(RegExp(r'[^A-Za-z\s]'), ' ').trim();
    // Convert to uppercase
    cleaned = cleaned.toUpperCase();
    
    // Remove known noisy trailing artifacts common in Tesseract on Indian IDs
    // Remove isolated single or double characters at the end (often gender misreads or noise)
    cleaned = cleaned.replaceAll(RegExp(r'\s+[A-Z]{1,2}$'), '');
    
    // Sometimes OCR produces extra spaces between letters, or leaves dangling letters
    // E.g., "BASHA F" -> the previous regex will catch the " F".
    
    return cleaned.trim();
  }
}
