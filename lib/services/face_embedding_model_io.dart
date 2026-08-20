import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime_v2/onnxruntime_v2.dart';

enum FaceModelBackend {
  arcfaceONNX,
}

class FaceEmbeddingModel {
  // Config
  FaceModelBackend backend = FaceModelBackend.arcfaceONNX; 
  
  OrtSession? _ortSession;
  OrtRunOptions? _runOptions;
  
  final int inputHeight = 112;
  final int inputWidth = 112;
  final int inputChannels = 3;
  
  int _embeddingLength = 512; // Default, updated on load
  int get embeddingLength => _embeddingLength;
  String get modelInputShape => '[1, $inputChannels, $inputHeight, $inputWidth]';
  String get modelOutputShape => '[1, $embeddingLength]';

  String get backendDisplayName => 'ArcFace (w600k_mbf)';

  Future<void> loadModel() async {
    if (_ortSession != null) return;
    
    final start = DateTime.now();
    debugPrint('PERF:FACE_MODEL_INIT_START');

    try {
      OrtEnv.instance.init();
      final sessionOptions = OrtSessionOptions();
      
      debugPrint('FACE:MODEL LOAD START: w600k_mbf.onnx');
      final rawAssetFile = await rootBundle.load('assets/models/w600k_mbf.onnx');
      final bytes = rawAssetFile.buffer.asUint8List(rawAssetFile.offsetInBytes, rawAssetFile.lengthInBytes);
      _ortSession = OrtSession.fromBuffer(bytes, sessionOptions);
      _runOptions = OrtRunOptions();
      
      // We can't dynamically get output shape easily with onnxruntime_v2 dart wrapper 
      // without running it, but w600k_mbf is typically 512-D.
      _embeddingLength = 512;
      
      debugPrint('FACE:MODEL LOAD SUCCESS: w600k_mbf.onnx');
    } catch (e, st) {
      debugPrint('FACE:MODEL LOAD FAILURE: $e\n$st');
      rethrow;
    }
    
    final ms = DateTime.now().difference(start).inMilliseconds;
    debugPrint('PERF:FACE_MODEL_INIT_END');
    debugPrint('PERF:FACE_MODEL_INIT_MS: $ms');
  }

  /// Converts a 112x112 image into the normalized Float32 tensor for ONNX (NCHW format).
  Float32List _imageToFloat32ListONNX(img.Image image) {
    final convertedBytes = Float32List(1 * inputChannels * inputHeight * inputWidth);
    var bufferIndex = 0;
    
    // NCHW format for InsightFace: Channels (B, G, R), Height, Width
    // Normalized to [-1, 1] using (pixel - 127.5) / 127.5
    for (var y = 0; y < inputHeight; y++) {
      for (var x = 0; x < inputWidth; x++) {
        convertedBytes[bufferIndex++] = (image.getPixel(x, y).b - 127.5) / 127.5; // BLUE
      }
    }
    for (var y = 0; y < inputHeight; y++) {
      for (var x = 0; x < inputWidth; x++) {
        convertedBytes[bufferIndex++] = (image.getPixel(x, y).g - 127.5) / 127.5; // GREEN
      }
    }
    for (var y = 0; y < inputHeight; y++) {
      for (var x = 0; x < inputWidth; x++) {
        convertedBytes[bufferIndex++] = (image.getPixel(x, y).r - 127.5) / 127.5; // RED
      }
    }
    return convertedBytes;
  }

  /// Runs inference on a perfectly cropped/aligned face and returns L2 normalized embedding.
  Future<List<double>> getEmbedding(img.Image alignedFace, {required String label}) async {
    final startTime = DateTime.now();
    try {
      final embedding = await _getEmbeddingInternal(alignedFace, label: label);
      debugPrint('FACE:ACTIVE BACKEND: ${backend.name.toUpperCase()}');
      final inferenceMs = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('FACE:INFERENCE TIME: ${inferenceMs}ms');
      debugPrint('PERF:FACE_INFERENCE_MS: $inferenceMs');
      return embedding;
    } catch (e, st) {
      debugPrint('FACE:INFERENCE FAILED: $e\n$st');
      rethrow;
    }
  }

  Future<List<double>> _getEmbeddingInternal(img.Image alignedFace, {required String label}) async {
    img.Image resizedImage = alignedFace;
    if (alignedFace.width != inputWidth || alignedFace.height != inputHeight) {
      resizedImage = img.copyResize(alignedFace, width: inputWidth, height: inputHeight);
    }

    if (_ortSession == null) throw StateError('ONNX model is not loaded.');
    
    final inputData = _imageToFloat32ListONNX(resizedImage);
    
    final inputOrtValue = OrtValueTensor.createTensorWithDataList(
      inputData,
      [1, inputChannels, inputHeight, inputWidth],
    );

    // Note: The input name in InsightFace models is typically "input.1" or "data".
    // Try passing a single input map with whatever the first input is called.
    // However, onnxruntime_v2 dart might just require knowing the exact name if there are multiple.
    // If it fails, you would need the exact input node name. Assuming 'input.1' or 'data'.
    // We can get the input name from the model if we had the API, but we'll try 'images' or 'data' or 'input.1'
    // Usually onnxruntime_v2 throws if the key is wrong.
    // For ArcFace, it's often 'images' or 'data'.
    // A trick is to use session.inputNames if available, but it's not exposed in this package version.
    
    // Instead of guessing, we use the session to run it.
    // Many models use "input.1". We will try it. If it fails we'll need to check the model.
    final inputs = {'input.1': inputOrtValue}; 
    
    List<OrtValue?>? outputs;
    try {
      outputs = _ortSession!.run(_runOptions!, inputs);
    } catch (e) {
      // Fallback input names if input.1 is wrong
      try {
         final inputs2 = {'data': inputOrtValue};
         outputs = _ortSession!.run(_runOptions!, inputs2);
      } catch (e2) {
         try {
           final inputs3 = {'images': inputOrtValue};
           outputs = _ortSession!.run(_runOptions!, inputs3);
         } catch (e3) {
           inputOrtValue.release();
           throw StateError('Failed to run model with input names input.1, data, or images. $e3');
         }
      }
    }
    
    final outputOrtValue = outputs[0];
    if (outputOrtValue == null) {
      inputOrtValue.release();
      throw StateError('ONNX model returned null output.');
    }
    
    // Output shape is [1, 512]
    final outputList = outputOrtValue.value as List;
    final rawEmbedding = outputList[0] as List<double>;
    _embeddingLength = rawEmbedding.length;
    
    inputOrtValue.release();
    outputOrtValue.release();

    // Validate output
    for (int i = 0; i < rawEmbedding.length; i++) {
      if (rawEmbedding[i].isNaN || rawEmbedding[i].isInfinite) {
        throw StateError('Model produced invalid embedding value at index $i: ${rawEmbedding[i]}');
      }
    }

    // Apply strict L2 Normalization
    double sumSquares = 0.0;
    for (final val in rawEmbedding) {
      sumSquares += val * val;
    }
    final norm = sqrt(sumSquares);
    if (norm == 0 || norm.isNaN) {
      throw StateError('Embedding norm is 0 or NaN.');
    }

    final normalizedEmbedding = rawEmbedding.map((e) => e / norm).toList();

    debugPrint('FACE:$label EMBEDDING VALID: TRUE');
    debugPrint('FACE:$label EMBEDDING DIMENSION: ${normalizedEmbedding.length}');
    debugPrint('FACE:$label EMBEDDING NORM: 1.0 (Approx)');

    return normalizedEmbedding;
  }

  void dispose() {
    _ortSession?.release();
    _ortSession = null;
    _runOptions?.release();
    _runOptions = null;
  }
}
