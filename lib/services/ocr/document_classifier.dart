import 'ocr_models.dart';

class DocumentClassifier {
  /// Analyzes the raw text to determine the type of document.
  static DocumentType classify(String rawText) {
    final text = rawText.toUpperCase();
    
    // PAN Card Keywords
    if (text.contains('INCOME TAX DEPARTMENT') || 
        text.contains('GOVT. OF INDIA') || 
        text.contains('PERMANENT ACCOUNT NUMBER')) {
      return DocumentType.pan;
    }
    
    // Aadhaar Card Keywords
    if (text.contains('GOVERNMENT OF INDIA') && 
        (text.contains('AADHAAR') || text.contains('UIDAI') || text.contains('ENROLLMENT NO'))) {
      return DocumentType.aadhaar;
    }
    
    // Driving License Keywords
    if (text.contains('DRIVING LICENCE') || 
        text.contains('TRANSPORT DEPARTMENT') || 
        text.contains('UNION OF INDIA') && text.contains('DL NO')) {
      return DocumentType.drivingLicence;
    }
    
    // Voter ID Keywords
    if (text.contains('ELECTION COMMISSION OF INDIA') || 
        text.contains('ELECTOR PHOTO IDENTITY CARD')) {
      return DocumentType.voterId;
    }
    
    // Passport Keywords
    if (text.contains('REPUBLIC OF INDIA') && 
        text.contains('PASSPORT')) {
      return DocumentType.passport;
    }
    
    return DocumentType.unknown;
  }
}
