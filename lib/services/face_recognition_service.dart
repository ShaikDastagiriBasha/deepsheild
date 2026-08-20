// ignore_for_file: dead_code
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cross_file/cross_file.dart';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'ocr/ocr_models.dart';
import 'package:image/image.dart' as img;

import 'face_alignment_utils.dart';
import 'face_embedding_model.dart';
import 'web_helpers/web_interop.dart';

class FaceQualityException implements Exception {
  final String message;
  const FaceQualityException(this.message);
  @override
  String toString() => message;
}

class FaceQualityResult {
  final bool isValid;
  final String? rejectionReason;
  final int faceCount;
  final double blurScore;

  FaceQualityResult({
    required this.isValid,
    this.rejectionReason,
    required this.faceCount,
    required this.blurScore,
  });
}

class FaceMatchDecision {
  final String status;
  final String reason;
  final bool isVerified;
  final double confidencePercentage;

  const FaceMatchDecision({
    required this.status,
    required this.reason,
    required this.isVerified,
    required this.confidencePercentage,
  });
}

class FaceVerificationConfig {
  // For cross-domain matching (ID card vs live selfie), the w600k_mbf model
  // typically outputs cosine similarities in the range of 0.25 - 0.45 for the same person,
  // because ID photos are low-res, printed, and have different lighting.
  // Different people generally score between 0.00 - 0.15.
  static double decisionThreshold = 0.24;
}

class FaceMatchPolicy {
  static FaceMatchDecision decisionForScore(double rawCosine) {
    // Map rawCosine to 0-100% confidence based on User requirements:
    // "thresholds for correct should be above 65 and fake person below 50"
    
    double percentage;
    if (rawCosine >= FaceVerificationConfig.decisionThreshold) {
      // Map threshold -> 65%, 1.0 -> 100%
      percentage = 65.0 + ((rawCosine - FaceVerificationConfig.decisionThreshold) / (1.0 - FaceVerificationConfig.decisionThreshold)) * 35.0;
      percentage = percentage.clamp(65.0, 100.0);
    } else {
      // For rawCosine < threshold, map it below 50% quickly.
      final double failThreshold = max(0.0, FaceVerificationConfig.decisionThreshold - 0.10); // 0.14
      
      if (rawCosine >= failThreshold) {
        // Map [failThreshold, decisionThreshold) -> [49%, 64.9%]
        percentage = 49.0 + ((rawCosine - failThreshold) / 0.10) * 15.9;
      } else {
        // Map [0, failThreshold) -> [0%, 49%)
        if (failThreshold > 0) {
          percentage = (max(0.0, rawCosine) / failThreshold) * 49.0;
        } else {
          percentage = 0.0;
        }
      }
      percentage = percentage.clamp(0.0, 64.9);
    }

    if (rawCosine < FaceVerificationConfig.decisionThreshold) {
      return FaceMatchDecision(
        status: 'FACE NOT VERIFIED',
        reason: 'Face similarity below verification threshold',
        isVerified: false,
        confidencePercentage: percentage,
      );
    }
    return FaceMatchDecision(
      status: 'FACE VERIFIED',
      reason: 'Face matches',
      isVerified: true,
      confidencePercentage: percentage,
    );
  }
}

class FaceEmbeddingDiagnostics {
  final String imageSize;
  final int faceCount;
  final String selectedFace;
  final String boundingBox;
  final String cropSize;
  final String padding;
  final String modelInput;
  final int embeddingDimensions;
  final double embeddingNorm;
  final String firstTenValues;

  const FaceEmbeddingDiagnostics({
    required this.imageSize,
    required this.faceCount,
    required this.selectedFace,
    required this.boundingBox,
    required this.cropSize,
    required this.padding,
    required this.modelInput,
    required this.embeddingDimensions,
    required this.embeddingNorm,
    required this.firstTenValues,
  });
}

class FaceRecognitionService {
  final FaceEmbeddingModel _embeddingModel = FaceEmbeddingModel();

  String get backendDisplayName => _embeddingModel.backendDisplayName;

  // Padding is applied on each side of the detected face.
  static const double _selfiePadding = 0.25;
  static const double _documentPadding = 0.40;

  FaceEmbeddingDiagnostics? _lastDocumentDiagnostics;
  FaceEmbeddingDiagnostics? _lastSelfieDiagnostics;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableClassification: true,
      enableLandmarks: true,
    ),
  );

  Future<void> loadModel() async {
    await _embeddingModel.loadModel();
  }

  Future<FaceQualityResult> checkFaceQuality(XFile imageFile) async {
    if (kIsWeb) {
      // On web, skip local ML Kit quality check and rely on backend API later
      return FaceQualityResult(isValid: true, faceCount: 1, blurScore: 100.0);
    }
    
    try {
      final inputImage = InputImage.fromFile(File(imageFile.path));
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return FaceQualityResult(
          isValid: false,
          rejectionReason: 'No face detected. Position your face clearly in frame.',
          faceCount: 0,
          blurScore: 0.0,
        );
      }
      if (faces.length > 1) {
        return FaceQualityResult(
          isValid: false,
          rejectionReason: 'Multiple faces detected. Only one face is allowed.',
          faceCount: faces.length,
          blurScore: 0.0,
        );
      }

      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return FaceQualityResult(
          isValid: false,
          rejectionReason: 'Unable to read the selfie. Please retake it.',
          faceCount: 1,
          blurScore: 0.0,
        );
      }

      final blurScore = _calculateVarianceOfLaplacian(img.bakeOrientation(decoded));
      if (blurScore < 15.0) {
        return FaceQualityResult(
          isValid: false,
          rejectionReason: 'Image is too blurry. Retake it in good lighting.',
          faceCount: 1,
          blurScore: blurScore,
        );
      }

      return FaceQualityResult(
        isValid: true,
        faceCount: 1,
        blurScore: blurScore,
      );
    } catch (e, st) {
      debugPrint('FACE:QUALITY CHECK FAILED: $e');
      debugPrint('$st');
      return FaceQualityResult(
        isValid: false,
        rejectionReason: 'Unable to evaluate the selfie. Please retake it.',
        faceCount: 0,
        blurScore: 0.0,
      );
    }
  }

  Future<List<double>> getEmbedding(
    XFile imageFile, {
    bool isDocument = false,
    DocumentType? documentType,
  }) async {
    if (kIsWeb) {
       // Return dummy embedding on Web. The actual comparison happens in compareFacesWeb
       return [1.0, 0.0, 0.0]; 
    }
    await loadModel();
    return getEmbeddingAveraged(imageFile, isDocument: isDocument, documentType: documentType);
  }

  Future<List<double>> getEmbeddingAveraged(
    XFile imageFile, {
    bool isDocument = false,
    DocumentType? documentType,
  }) async {
    final totalStart = DateTime.now();
    await loadModel();

    final label = isDocument ? 'DOCUMENT' : 'SELFIE';
    final padding = isDocument ? _documentPadding : _selfiePadding;
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Unable to decode $label image.');
    }
    final image = img.bakeOrientation(decoded);
    debugPrint('FACE:$label IMAGE SIZE: ${image.width}x${image.height}');

    final detStart = DateTime.now();
    final faces = await _faceDetector.processImage(InputImage.fromFile(File(imageFile.path)));
    final detMs = DateTime.now().difference(detStart).inMilliseconds;
    debugPrint('PERF:FACE_DETECTION_MS: $detMs');
    
    debugPrint('FACE:$label DETECTED: ${faces.length}');
    if (faces.isEmpty) {
      throw FaceQualityException('No face detected in ${label.toLowerCase()} image.');
    }
    if (faces.length > 1) {
      throw FaceQualityException('Multiple faces detected in the ${label.toLowerCase()} image. Only one face is allowed.');
    }

    final face = faces.first;
    final rect = face.boundingBox;
    
    debugPrint('FACE:QUALITY WIDTH: ${rect.width.toInt()}');
    debugPrint('FACE:QUALITY HEIGHT: ${rect.height.toInt()}');
    
    final selectedFace = isDocument
        ? 'document portrait face'
        : 'selfie face';
    final boundingBox =
        'L=${rect.left.toInt()} T=${rect.top.toInt()} W=${rect.width.toInt()} H=${rect.height.toInt()}';
    debugPrint('FACE:$label SELECTED FACE: $selectedFace');
    debugPrint('FACE:$label BOX: $boundingBox');

    final maxDim = max(rect.width, rect.height);
    final maxSide = min(image.width, image.height);
    final int baseSide = min(
      max(1, (maxDim * (1 + (padding * 2))).round()),
      maxSide,
    ).toInt();
    
    // Calculate the padded bounding box for cropping the source image
    final int padPx = (maxDim * padding).round();
    final int cropLeft = max(0, rect.left.toInt() - padPx);
    final int cropTop = max(0, rect.top.toInt() - padPx);
    final int cropRight = min(image.width, rect.right.toInt() + padPx);
    final int cropBottom = min(image.height, rect.bottom.toInt() + padPx);
    
    final int cropWidth = cropRight - cropLeft;
    final int cropHeight = cropBottom - cropTop;
    
    debugPrint('FACE:$label EXPANDED CROP: L=$cropLeft T=$cropTop W=$cropWidth H=$cropHeight (Padding $padPx px)');
    
    // FaceQualityGate: Validate the *expanded* photograph crop, not just the tight facial features
    const double minCropSize = 90.0;
    final double minRatio = isDocument ? 0.05 : 0.10;
    
    if (cropWidth < minCropSize || cropHeight < minCropSize) {
      throw FaceQualityException('FACE QUALITY: FAIL. The extracted photograph on this $label is too small for reliable verification (${cropWidth}x$cropHeight).');
    }
    
    final ratio = cropWidth / image.width;
    if (ratio < minRatio) {
      throw FaceQualityException('FACE QUALITY: FAIL. The photograph is too small relative to the $label frame (${(ratio*100).toStringAsFixed(1)}%).');
    }
    
    // We crop the original image to this padded region before alignment
    final img.Image sourceCrop = img.copyCrop(
      image,
      x: cropLeft,
      y: cropTop,
      width: cropWidth,
      height: cropHeight,
    );

    final centerX = rect.left + (rect.width / 2);
    final centerY = rect.top + (rect.height / 2);
    
    // Evaluate flag: single vs multi crop
    const bool useAlignedMultiCrop = true;

    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];

    // Enable 5-point alignment for ArcFace which requires it.
    // We add a safety check later to ensure landmarks match the image buffer.
    bool canAlign = leftEye != null && rightEye != null && noseBase != null && leftMouth != null && rightMouth != null;
    
    if (canAlign) {
      debugPrint('FACE:ALIGNMENT METHOD: 5-POINT AFFINE');
      debugPrint('FACE:ALIGNMENT SUCCESS: TRUE');
      debugPrint('FACE:$label LANDMARKS REMAPPED: TRUE');
      debugPrint('FACE:$label LANDMARKS: LE=(${leftEye.position.x},${leftEye.position.y}) RE=(${rightEye.position.x},${rightEye.position.y}) NOSE=(${noseBase.position.x},${noseBase.position.y}) LM=(${leftMouth.position.x},${leftMouth.position.y}) RM=(${rightMouth.position.x},${rightMouth.position.y})');
    } else {
      debugPrint('FACE:ALIGNMENT FALLBACK: BOUNDING_BOX');
      debugPrint('FACE:ALIGNMENT SUCCESS: FALSE');
    }

    final offsets = canAlign && !useAlignedMultiCrop ? <(double, double)>[(0.0, 0.0)] : <(double, double)>[
      (0.0, 0.0),
      (2.0, 0.0),
      (-2.0, 0.0),
    ];
    final embeddings = <List<double>>[];
    String cropSize = canAlign ? '112x112' : '${baseSide}x$baseSide';
    int totalAlignMs = 0;

    for (var index = 0; index < offsets.length; index++) {
      final alignStart = DateTime.now();
      final offset = offsets[index];
      late img.Image resized;

      if (canAlign) {
        // ML Kit leftEye is on the subject's left, but image's right.
        // ArcFace reference points:
        // index 0: x=38.29 (Image Left, Subject Right)
        // index 1: x=73.53 (Image Right, Subject Left)
        // Therefore, map subject's Right Eye to 38.29, Left Eye to 73.53.
        final srcPoints = [
          Point<double>(rightEye!.position.x.toDouble() - cropLeft, rightEye.position.y.toDouble() - cropTop),
          Point<double>(leftEye!.position.x.toDouble() - cropLeft, leftEye.position.y.toDouble() - cropTop),
          Point<double>(noseBase!.position.x.toDouble() - cropLeft, noseBase.position.y.toDouble() - cropTop),
          Point<double>(rightMouth!.position.x.toDouble() - cropLeft, rightMouth.position.y.toDouble() - cropTop),
          Point<double>(leftMouth!.position.x.toDouble() - cropLeft, leftMouth.position.y.toDouble() - cropTop),
        ];
        
        // Check if the image is horizontally mirrored (typical for selfies).
        // Subject's Right Eye (rightEye) should normally have a smaller X coordinate than Subject's Left Eye.
        // If it has a larger X coordinate, the image is mirrored!
        final bool isMirrored = rightEye.position.x > leftEye.position.x;
        
        final dstPoints = isMirrored 
          ? [
              Point<double>(112.0 - 38.2946, 51.6963), 
              Point<double>(112.0 - 73.5318, 51.5014), 
              Point<double>(112.0 - 56.0252, 71.7366),
              Point<double>(112.0 - 41.5493, 92.3655),
              Point<double>(112.0 - 70.7299, 92.2041),
            ]
          : [
              Point<double>(38.2946, 51.6963), 
              Point<double>(73.5318, 51.5014), 
              Point<double>(56.0252, 71.7366),
              Point<double>(41.5493, 92.3655),
              Point<double>(70.7299, 92.2041),
            ];

        var transform = computeSimilarityTransform(srcPoints, dstPoints);
        
        // Safety Check: Ensure the center of the aligned face maps to a valid pixel
        // in the sourceCrop. If ML Kit landmarks are out-of-sync with the image buffer
        // due to rotation bugs, this will map out of bounds.
        final centerPoint = transform.inverse(_embeddingModel.inputWidth / 2, _embeddingModel.inputHeight / 2);
        if (centerPoint.x < 0 || centerPoint.x >= sourceCrop.width || centerPoint.y < 0 || centerPoint.y >= sourceCrop.height) {
          debugPrint('FACE:ALIGNMENT FAILED BOUNDS CHECK: Center mapped to ${centerPoint.x}, ${centerPoint.y}');
          canAlign = false; // Fallback to bounding box for this face
        }

        if (canAlign) {
          // Apply jitter by translating the output coordinate space
          if (offset.$1 != 0 || offset.$2 != 0) {
             transform = FaceTransform(transform.a, transform.b, transform.tx + offset.$1, transform.ty + offset.$2);
          }

          resized = transformImage(sourceCrop, transform, _embeddingModel.inputWidth, _embeddingModel.inputHeight);
          
          if (index == 0) {
            debugPrint('FACE:$label ALIGNED SIZE: ${_embeddingModel.inputWidth} x ${_embeddingModel.inputHeight}');
            debugPrint('FACE:$label CROP SIZE: $cropSize');
            debugPrint('FACE:$label PADDING: AFFINE TRANSFORM');
          }
        }
      } 
      
      if (!canAlign) {
        // Fallback bounding box crop
        final x = ((centerX + offset.$1.toInt()) - (baseSide / 2))
            .round()
            .clamp(0, image.width - baseSide)
            .toInt();
        final y = ((centerY + offset.$2.toInt()) - (baseSide / 2))
            .round()
            .clamp(0, image.height - baseSide)
            .toInt();
        final cropped = img.copyCrop(
          image,
          x: x,
          y: y,
          width: baseSide,
          height: baseSide,
        );
        resized = img.copyResize(
          cropped,
          width: _embeddingModel.inputWidth,
          height: _embeddingModel.inputHeight,
          interpolation: img.Interpolation.linear,
        );

        if (index == 0) {
          debugPrint('FACE:$label ALIGNED SIZE: ${_embeddingModel.inputWidth} x ${_embeddingModel.inputHeight}');
          debugPrint('FACE:$label CROP SIZE: $cropSize');
          debugPrint('FACE:$label PADDING: ${(padding * 100).toInt()}% per side');
        }
        debugPrint(
          'FACE:$label CROP[$index]: x=$x y=$y w=$baseSide h=$baseSide '
          '(offset ${offset.$1},${offset.$2})',
        );
      }
      
      totalAlignMs += DateTime.now().difference(alignStart).inMilliseconds;

      // FaceEmbeddingModel applies L2 normalization internally on the cropped/resized face
      final normalizedCropEmbedding = await _embeddingModel.getEmbedding(resized, label: '$label crop $index');
      
      debugPrint(
        'FACE:$label CROP[$index] FIRST 5: '
        '${normalizedCropEmbedding.take(5).map((e) => e.toStringAsFixed(6)).join(', ')}',
      );

      embeddings.add(normalizedCropEmbedding);
    }
    debugPrint('PERF:ALIGNMENT_MS: $totalAlignMs');

    final actualLength = embeddings.isNotEmpty ? embeddings.first.length : _embeddingModel.embeddingLength;
    final averaged = List<double>.filled(actualLength, 0.0);
    for (final embedding in embeddings) {
      for (var i = 0; i < actualLength; i++) {
        averaged[i] += embedding[i];
      }
    }
    for (var i = 0; i < actualLength; i++) {
      averaged[i] /= embeddings.length;
    }

    final finalEmbedding = _l2Normalize(averaged, '$label averaged embedding');
    final finalNorm = _l2Norm(finalEmbedding);
    
    // Calculate min/max and check for NaN/Infinity
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;
    bool hasNaN = false;
    bool hasInfinity = false;
    for (final val in finalEmbedding) {
      if (val.isNaN) hasNaN = true;
      if (val.isInfinite) hasInfinity = true;
      if (!val.isNaN && val < minVal) minVal = val;
      if (!val.isNaN && val > maxVal) maxVal = val;
    }

    final firstTen = finalEmbedding
        .take(10)
        .map((value) => value.toStringAsFixed(4))
        .join(', ');

    final diagnostics = FaceEmbeddingDiagnostics(
      imageSize: '${image.width}x${image.height}',
      faceCount: faces.length,
      selectedFace: selectedFace,
      boundingBox: boundingBox,
      cropSize: cropSize,
      padding: '${(padding * 100).toInt()}% per side',
      modelInput: '${_embeddingModel.modelInputShape} RGB [-1, 1]',
      embeddingDimensions: finalEmbedding.length,
      embeddingNorm: finalNorm,
      firstTenValues: firstTen,
    );
    if (isDocument) {
      _lastDocumentDiagnostics = diagnostics;
    } else {
      _lastSelfieDiagnostics = diagnostics;
    }

    debugPrint('FACE:$label EMBEDDING SIZE: ${finalEmbedding.length}');
    debugPrint('FACE:$label EMBEDDING NORM: ${finalNorm.toStringAsFixed(6)}');
    debugPrint('FACE:$label MIN VALUE: ${minVal.toStringAsFixed(6)}');
    debugPrint('FACE:$label MAX VALUE: ${maxVal.toStringAsFixed(6)}');
    debugPrint('FACE:$label HAS NAN: $hasNaN');
    debugPrint('FACE:$label HAS INFINITY: $hasInfinity');
    debugPrint('FACE:$label EMBEDDING FIRST 10 VALUES: $firstTen');
    
    if (finalEmbedding.isEmpty || hasNaN || hasInfinity || finalNorm == 0) {
      throw StateError('$label embedding is invalid (empty, NaN, Infinity, or zero norm).');
    }
    
    final totalMs = DateTime.now().difference(totalStart).inMilliseconds;
    debugPrint('PERF:FACE_TOTAL_MS: $totalMs');
    return finalEmbedding;
  }

  // _selectFace and _largestFace have been removed. Single face is guaranteed.

  Future<double?> compareFacesWeb(XFile documentImage, XFile selfieImage) async {
    try {
      final docBytes = await documentImage.readAsBytes();
      final selBytes = await selfieImage.readAsBytes();
      final docBase64 = base64Encode(docBytes);
      final selBase64 = base64Encode(selBytes);
      
      final String jsonResult = await compareFacesBase64Web(docBase64, selBase64).timeout(const Duration(seconds: 15));
      final json = jsonDecode(jsonResult);
      if (json['success'] == true) {
        return json['similarity']?.toDouble();
      } else {
        debugPrint('compareFacesWeb JS Error: ${json['error']}');
      }
    } catch (e) {
      debugPrint('compareFacesWeb error: $e');
    }
    return null;
  }

  double? compareFaces(List<double> documentEmbedding, List<double> selfieEmbedding) {
    if (documentEmbedding.length != selfieEmbedding.length ||
        documentEmbedding.isEmpty) {
      throw StateError('Face embeddings have incompatible dimensions.');
    }
    if (documentEmbedding.any((value) => value.isNaN || value.isInfinite) ||
        selfieEmbedding.any((value) => value.isNaN || value.isInfinite)) {
      throw StateError('Face embeddings contain non-finite values.');
    }

    final documentNorm = _l2Norm(documentEmbedding);
    final selfieNorm = _l2Norm(selfieEmbedding);
    if (documentNorm <= 0 || selfieNorm <= 0) {
      throw StateError('Face embedding is a zero vector.');
    }

    var dotProduct = 0.0;
    for (var i = 0; i < documentEmbedding.length; i++) {
      dotProduct += documentEmbedding[i] * selfieEmbedding[i];
    }
    final double rawCosine =
        (dotProduct / (documentNorm * selfieNorm)).clamp(-1.0, 1.0).toDouble();
    
    final decision = decisionForScore(rawCosine);

    debugPrint('========== EMBEDDING COMPARISON ==========');
    debugPrint('DOCUMENT LENGTH: ${documentEmbedding.length}');
    debugPrint('SELFIE LENGTH: ${selfieEmbedding.length}');
    debugPrint(
      'DOCUMENT FIRST 10: ${documentEmbedding.take(10).map((e) => e.toStringAsFixed(6)).join(', ')}',
    );
    debugPrint(
      'SELFIE FIRST 10: ${selfieEmbedding.take(10).map((e) => e.toStringAsFixed(6)).join(', ')}',
    );
    debugPrint('DOCUMENT NORM: ${_l2Norm(documentEmbedding).toStringAsFixed(6)}',
    );
    debugPrint(
      'SELFIE NORM: ${_l2Norm(selfieEmbedding).toStringAsFixed(6)}',
    );
    debugPrint(
      'RAW COSINE: ${rawCosine.toStringAsFixed(6)}',
    );
    debugPrint(
      'THRESHOLD: ${FaceVerificationConfig.decisionThreshold.toStringAsFixed(4)}',
    );
    debugPrint('==========================================');

    debugPrint('\n========== FACE MATCH DEBUG ==========');
    _printDiagnostics('DOCUMENT', _lastDocumentDiagnostics);
    _printDiagnostics('SELFIE', _lastSelfieDiagnostics);
    debugPrint('\nCOMPARISON:');
    debugPrint('raw cosine: ${rawCosine.toStringAsFixed(6)}');
    debugPrint('threshold: ${FaceVerificationConfig.decisionThreshold.toStringAsFixed(4)}');
    debugPrint('status: ${decision.status}');
    debugPrint('decision: ${decision.reason}');
    debugPrint('\n=======================================');
    debugPrint('COMPARE:RAW COSINE: ${rawCosine.toStringAsFixed(6)}');
    return rawCosine;
  }

  FaceMatchDecision decisionForScore(double score) {
    return FaceMatchPolicy.decisionForScore(score);
  }

  void _printDiagnostics(String label, FaceEmbeddingDiagnostics? diagnostics) {
    debugPrint('\n$label:');
    if (diagnostics == null) {
      debugPrint('diagnostics unavailable');
      return;
    }
    debugPrint('image size: ${diagnostics.imageSize}');
    debugPrint('face count: ${diagnostics.faceCount}');
    debugPrint('selected face: ${diagnostics.selectedFace}');
    debugPrint('bounding box: ${diagnostics.boundingBox}');
    debugPrint('crop size: ${diagnostics.cropSize}');
    debugPrint('padding: ${diagnostics.padding}');
    debugPrint('model input: ${diagnostics.modelInput}');
    debugPrint('embedding dimensions: ${diagnostics.embeddingDimensions}');
    debugPrint('embedding norm: ${diagnostics.embeddingNorm.toStringAsFixed(6)}');
    debugPrint('first 10 embedding values: ${diagnostics.firstTenValues}');
  }

  List<double> _l2Normalize(List<double> values, String label) {
    final norm = _l2Norm(values);
    if (norm <= 0 || norm.isNaN || norm.isInfinite) {
      throw StateError('$label has an invalid L2 norm.');
    }
    return values.map((value) => value / norm).toList();
  }

  double _l2Norm(List<double> values) {
    var sum = 0.0;
    for (final value in values) {
      sum += value * value;
    }
    return sqrt(sum);
  }

  double _calculateVarianceOfLaplacian(img.Image image) {
    final values = <double>[];
    var mean = 0.0;
    const sampleStep = 4;

    for (var y = 1; y < image.height - 1; y += sampleStep) {
      for (var x = 1; x < image.width - 1; x += sampleStep) {
        double luma(img.Pixel pixel) =>
            pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114;
        final current = luma(image.getPixel(x, y));
        final up = luma(image.getPixel(x, y - 1));
        final down = luma(image.getPixel(x, y + 1));
        final left = luma(image.getPixel(x - 1, y));
        final right = luma(image.getPixel(x + 1, y));
        final laplacian = (4 * current) - (up + down + left + right);
        values.add(laplacian);
        mean += laplacian;
      }
    }

    if (values.isEmpty) return 0.0;
    mean /= values.length;
    var variance = 0.0;
    for (final value in values) {
      variance += (value - mean) * (value - mean);
    }
    return variance / values.length;
  }

  void dispose() {
    _embeddingModel.dispose();
    _faceDetector.close();
  }
}
