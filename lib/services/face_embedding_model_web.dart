import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

enum FaceModelBackend {
  arcfaceTFLite,
  mobilefaceNet,
}

class FaceEmbeddingModel {
  FaceModelBackend backend = FaceModelBackend.mobilefaceNet;
  final int inputHeight = 112;
  final int inputWidth = 112;
  final int inputChannels = 3;

  int get embeddingLength => backend == FaceModelBackend.mobilefaceNet ? 192 : 512;
  String get modelInputShape => '';
  String get modelOutputShape => '';
  String get backendDisplayName => 'Web Stub';

  Future<void> loadModel() async {
    // Web: TFLite and ONNX inference are currently stubbed.
    debugPrint('FACE:MODEL LOAD STUB ON WEB');
  }

  Future<List<double>> getEmbedding(img.Image alignedFace, {required String label}) async {
    debugPrint('FACE:MODEL GET EMBEDDING STUB ON WEB');
    return List<double>.filled(embeddingLength, 0.0);
  }

  void dispose() {}
}
