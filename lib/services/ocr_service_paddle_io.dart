import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime_v2/onnxruntime_v2.dart';
import 'ocr/ocr_models.dart';

class PaddleOCRBox {
  final Rect rect;
  final String text;
  final double confidence;

  PaddleOCRBox(this.rect, this.text, this.confidence);
}

class DocumentOCRModel {
  OrtSession? _detSession;
  OrtSession? _recSession;
  OrtRunOptions? _runOptions;
  List<String> _dictionary = [];

  Future<void> loadModels() async {
    if (_detSession != null && _recSession != null) return;
    
    try {
      debugPrint('MODEL: Loading PP-OCRv5 ONNX models...');
      OrtEnv.instance.init();
      final sessionOptions = OrtSessionOptions();

      // Load detection model
      final detRaw = await rootBundle.load('assets/models/ppocrv5_det.onnx');
      final detBytes = detRaw.buffer.asUint8List(detRaw.offsetInBytes, detRaw.lengthInBytes);
      _detSession = OrtSession.fromBuffer(detBytes, sessionOptions);

      // Load recognition model
      final recRaw = await rootBundle.load('assets/models/ppocrv5_rec.onnx');
      final recBytes = recRaw.buffer.asUint8List(recRaw.offsetInBytes, recRaw.lengthInBytes);
      _recSession = OrtSession.fromBuffer(recBytes, sessionOptions);

      _runOptions = OrtRunOptions();

      // Load dictionary
      final dictString = await rootBundle.loadString('assets/models/ppocrv5_dict.txt');
      _dictionary = dictString.split('\n');
      
      // Standard Paddle dict handling
      _dictionary.insert(0, '<blank>');
      _dictionary.add(' ');

      debugPrint('OCR:MODEL ONNX LOAD SUCCESS. Dictionary size: ${_dictionary.length}');
    } catch (e) {
      debugPrint('Error loading PP-OCRv5 models: $e');
      rethrow;
    }
  }

  Float32List _imageToFloat32List(img.Image image, {List<double> mean = const [0.485, 0.456, 0.406], List<double> std = const [0.229, 0.224, 0.225]}) {
    final convertedBytes = Float32List(1 * 3 * image.height * image.width);
    var bufferIndex = 0;
    
    // NCHW RGB
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        convertedBytes[bufferIndex++] = ((pixel.r / 255.0) - mean[0]) / std[0];
      }
    }
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        convertedBytes[bufferIndex++] = ((pixel.g / 255.0) - mean[1]) / std[1];
      }
    }
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        convertedBytes[bufferIndex++] = ((pixel.b / 255.0) - mean[2]) / std[2];
      }
    }
    return convertedBytes;
  }

  Future<List<PaddleOCRBox>> processImage(File imageFile) async {
    await loadModels();

    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw StateError('Unable to decode document image.');
    final image = img.bakeOrientation(decoded);

    // 1. Detection
    // Limit size for memory constraints on mobile. Multiple of 32.
    int detWidth = 640;
    int detHeight = 640;
    
    // Maintain aspect ratio
    final double ratio = image.width / image.height;
    if (ratio > 1.0) {
       detHeight = (detWidth / ratio).round();
       detHeight = detHeight - (detHeight % 32);
    } else {
       detWidth = (detHeight * ratio).round();
       detWidth = detWidth - (detWidth % 32);
    }
    
    detWidth = max(32, detWidth);
    detHeight = max(32, detHeight);

    final detImage = img.copyResize(image, width: detWidth, height: detHeight);
    final inputData = _imageToFloat32List(detImage);

    final inputOrtValue = OrtValueTensor.createTensorWithDataList(
      inputData,
      [1, 3, detHeight, detWidth],
    );

    final detInputs = {'x': inputOrtValue};
    final detOutputs = _detSession!.run(_runOptions!, detInputs);
    
    final outputOrtValue = detOutputs[0];
    if (outputOrtValue == null) throw StateError('PP-OCR Det output null.');
    
    final outputList = outputOrtValue.value as List; // Shape [1, 1, H, W]
    final probMap = outputList[0][0] as List<List<double>>;

    inputOrtValue.release();
    outputOrtValue.release();

    // Find bounding boxes from probability map (> 0.3 threshold)
    final boxes = _extractBoxesFromProbMap(probMap, detWidth, detHeight, image.width, image.height);
    
    // Sort boxes top to bottom
    boxes.sort((a, b) => a.top.compareTo(b.top));

    List<PaddleOCRBox> results = [];

    // 2. Recognition
    for (final box in boxes) {
      // Pad slightly
      final padX = (box.width * 0.05).toInt();
      final padY = (box.height * 0.1).toInt();
      final cropX = max(0, box.left.toInt() - padX);
      final cropY = max(0, box.top.toInt() - padY);
      final cropW = min(image.width - cropX, box.width.toInt() + padX * 2);
      final cropH = min(image.height - cropY, box.height.toInt() + padY * 2);
      
      if (cropW < 5 || cropH < 5) continue;

      final crop = img.copyCrop(image, x: cropX, y: cropY, width: cropW, height: cropH);
      
      // Rec expects height=48, variable width
      final int recH = 48;
      final int recW = max(48, (cropW * (48.0 / cropH)).round());
      final recImage = img.copyResize(crop, width: recW, height: recH);
      
      final recInputData = _imageToFloat32List(recImage, mean: [0.5, 0.5, 0.5], std: [0.5, 0.5, 0.5]);
      
      final recInputOrtValue = OrtValueTensor.createTensorWithDataList(
        recInputData,
        [1, 3, recH, recW],
      );

      final recInputs = {'x': recInputOrtValue};
      final recOutputs = _recSession!.run(_runOptions!, recInputs);
      
      final recOutValue = recOutputs[0];
      if (recOutValue == null) continue;
      
      final recList = recOutValue.value as List; // [1, W, 18385]
      final seq = recList[0] as List<List<double>>;
      
      recInputOrtValue.release();
      recOutValue.release();

      // CTC Decoding
      String text = '';
      double probSum = 0.0;
      int charCount = 0;
      int prevIndex = -1;
      
      for (final step in seq) {
        double maxProb = -1.0;
        int maxIndex = -1;
        for (int i = 0; i < step.length; i++) {
          if (step[i] > maxProb) {
            maxProb = step[i];
            maxIndex = i;
          }
        }
        
        if (maxIndex > 0 && maxIndex != prevIndex && maxIndex < _dictionary.length) {
          final char = _dictionary[maxIndex];
          if (char != '<blank>') {
             text += char;
             probSum += maxProb;
             charCount++;
          }
        }
        prevIndex = maxIndex;
      }
      
      if (text.isNotEmpty) {
        results.add(PaddleOCRBox(box, text, probSum / max(1, charCount)));
      }
    }

    return results;
  }

  Future<List<OcrTextBlock>> extractText(File imageFile) async {
    final paddleBoxes = await processImage(imageFile);
    return paddleBoxes.map((box) => OcrTextBlock(
      boundingBox: box.rect,
      text: box.text,
      confidence: box.confidence,
    )).toList();
  }

  List<Rect> _extractBoxesFromProbMap(List<List<double>> probMap, int mapW, int mapH, int origW, int origH) {
    final threshold = 0.3;
    final List<Rect> rects = [];
    final visited = List.generate(mapH, (_) => List.filled(mapW, false));

    for (int y = 0; y < mapH; y++) {
      for (int x = 0; x < mapW; x++) {
        if (probMap[y][x] > threshold && !visited[y][x]) {
          final queue = <Point<int>>[Point(x, y)];
          visited[y][x] = true;
          int minX = x, maxX = x, minY = y, maxY = y;
          
          int head = 0;
          while (head < queue.length) {
            final p = queue[head++];
            if (p.x < minX) minX = p.x;
            if (p.x > maxX) maxX = p.x;
            if (p.y < minY) minY = p.y;
            if (p.y > maxY) maxY = p.y;

            for (int dy = -1; dy <= 1; dy++) {
              for (int dx = -1; dx <= 1; dx++) {
                final nx = p.x + dx;
                final ny = p.y + dy;
                if (nx >= 0 && nx < mapW && ny >= 0 && ny < mapH) {
                  if (probMap[ny][nx] > threshold && !visited[ny][nx]) {
                    visited[ny][nx] = true;
                    queue.add(Point(nx, ny));
                  }
                }
              }
            }
          }
          
          if (maxX - minX > 2 && maxY - minY > 2) { 
            final origLeft = (minX / mapW) * origW;
            final origTop = (minY / mapH) * origH;
            final origRight = (maxX / mapW) * origW;
            final origBottom = (maxY / mapH) * origH;
            rects.add(Rect.fromLTRB(origLeft, origTop, origRight, origBottom));
          }
        }
      }
    }
    return rects;
  }

  void dispose() {
    _detSession?.release();
    _detSession = null;
    _recSession?.release();
    _recSession = null;
    _runOptions?.release();
    _runOptions = null;
  }
}
