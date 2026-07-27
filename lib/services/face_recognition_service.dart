import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {

  Interpreter? interpreter;

  Future<void> loadModel() async {

    print("LOAD MODEL CALLED");

    interpreter = await Interpreter.fromAsset(
      'assets/models/mobilefacenet.tflite',
    );

    print("MODEL LOADED SUCCESSFULLY");
  }

  Future<List<double>> getEmbedding(
    File imageFile,
  ) async {

    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(),
    );

    final inputImage =
        InputImage.fromFile(
      imageFile,
    );

    final faces =
        await faceDetector.processImage(
      inputImage,
    );

    if (faces.isEmpty) {
      throw Exception(
        "No face detected",
      );
    }

    final bytes =
        await imageFile.readAsBytes();

    img.Image? image =
        img.decodeImage(bytes);

    if (image == null) {
      throw Exception(
        "Unable to decode image",
      );
    }

    final face = faces.first;

    final rect =
        face.boundingBox;

final x =
    (rect.left - 20)
        .toInt()
        .clamp(
          0,
          image.width,
        );

final y =
    (rect.top - 20)
        .toInt()
        .clamp(
          0,
          image.height,
        );

final width =
    (rect.width + 40)
        .toInt()
        .clamp(
          1,
          image.width - x,
        );

final height =
    (rect.height + 40)
        .toInt()
        .clamp(
          1,
          image.height - y,
        );

final cropped =
    img.copyCrop(
  image,
  x: x,
  y: y,
  width: width,
  height: height,
);

    final resized =
        img.copyResize(
      cropped,
      width: 112,
      height: 112,
    );

    List input = List.generate(
      1,
      (_) => List.generate(
        112,
        (y) => List.generate(
          112,
          (x) {

            final pixel =
                resized.getPixel(
              x,
              y,
            );

return [
  (pixel.r - 127.5) / 127.5,
  (pixel.g - 127.5) / 127.5,
  (pixel.b - 127.5) / 127.5,
];
          },
        ),
      ),
    );

    var output =
        List.generate(
      1,
      (_) => List.filled(
        192,
        0.0,
      ),
    );

    interpreter!.run(
      input,
      output,
    );

    return List<double>.from(
      output[0],
    );
  }

  double compareFaces(
    List<double> emb1,
    List<double> emb2,
  ) {

    double dotProduct = 0;
    double norm1 = 0;
    double norm2 = 0;

    for (int i = 0; i < emb1.length; i++) {

      dotProduct +=
          emb1[i] * emb2[i];

      norm1 +=
          emb1[i] * emb1[i];

      norm2 +=
          emb2[i] * emb2[i];
    }

    return dotProduct /
        (sqrt(norm1) *
            sqrt(norm2));
  }

  void dispose() {
    interpreter?.close();
  }
}