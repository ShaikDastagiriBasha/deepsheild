import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';

class PaddleOCRBox {
  final Rect rect;
  final String text;
  final double confidence;

  PaddleOCRBox(this.rect, this.text, this.confidence);
}

class DocumentOCRModel {
  Future<void> loadModels() async {
    debugPrint('OCR:MODEL LOAD STUB ON WEB');
  }

  Future<List<PaddleOCRBox>> processImage(File imageFile) async {
    debugPrint('OCR:MODEL PROCESS IMAGE STUB ON WEB');
    return [];
  }

  Future<dynamic> extractText(File imageFile) async {
    debugPrint('OCR:MODEL EXTRACT TEXT STUB ON WEB');
    return [];
  }
}
