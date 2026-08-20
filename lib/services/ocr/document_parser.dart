import 'ocr_models.dart';

/// Abstract base class for all identity document parsers.
abstract class DocumentParser {
  /// Parses a list of text blocks and attempts to extract identity information.
  /// Returns null if the document does not match this parser's format or if
  /// required fields cannot be found.
  ExtractedIdentity? parse(List<OcrTextBlock> blocks, {String? rawText});
}
