import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? controller;
  List<CameraDescription> cameras = [];
  int currentCamera = 0;
  bool isProcessing = false;
  bool completed = false;
  bool blinkDone = false;
  bool leftDone = false;
  bool rightDone = false;
  bool smileDone = false;
  double progress = 0.0;
  String instruction = "Blink Your Eyes";
  Timer? timer;

  final FaceDetector detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) return;

      currentCamera = cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      if (currentCamera == -1) {
        currentCamera = 0;
      }

      controller = CameraController(
        cameras[currentCamera],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller!.initialize();

      if (mounted) {
        setState(() {});
        startAutoDetection();
      }
    } catch (e) {
      debugPrint("Scan screen camera error: $e");
    }
  }

  void startAutoDetection() {
    timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        if (!isProcessing && !completed) {
          captureAndDetect();
        }
      },
    );
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) return;
    currentCamera = currentCamera == 0 ? 1 : 0;

    await controller?.dispose();

    controller = CameraController(
      cameras[currentCamera],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller!.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> captureAndDetect() async {
    if (controller == null || !controller!.value.isInitialized) return;
    isProcessing = true;

    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/face_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = await controller!.takePicture();
      final savedFile = await File(file.path).copy(path);
      final inputImage = InputImage.fromFile(savedFile);
      final faces = await detector.processImage(inputImage);

      if (faces.isNotEmpty) {
        detectLiveness(faces.first);
      }

      // Cleanup temporary file
      if (await savedFile.exists()) {
        await savedFile.delete();
      }
    } catch (e) {
      debugPrint("Capture Error: $e");
    }

    isProcessing = false;
  }

  void detectLiveness(Face face) {
    if (!blinkDone &&
        face.leftEyeOpenProbability != null &&
        face.rightEyeOpenProbability != null) {
      final left = face.leftEyeOpenProbability!;
      final right = face.rightEyeOpenProbability!;

      if (left < 0.6 && right < 0.6) {
        setState(() {
          blinkDone = true;
          progress = 0.25;
          instruction = "Turn Head Left";
        });
        return;
      }
    }

    if (blinkDone && !leftDone && face.headEulerAngleY != null) {
      final angle = face.headEulerAngleY!;
      if (currentCamera == 0 ? angle < -12 : angle > 12) {
        setState(() {
          leftDone = true;
          progress = 0.50;
          instruction = "Turn Head Right";
        });
        return;
      }
    }

    if (leftDone && !rightDone && face.headEulerAngleY != null) {
      final angle = face.headEulerAngleY!;
      if (currentCamera == 0 ? angle > 12 : angle < -12) {
        setState(() {
          rightDone = true;
          progress = 0.75;
          instruction = "Smile Please";
        });
        return;
      }
    }

    if (rightDone && !smileDone && face.smilingProbability != null) {
      final smile = face.smilingProbability!;
      if (smile > 0.4) {
        setState(() {
          smileDone = true;
          progress = 1.0;
          instruction = "Verification Complete";
          completed = true;
        });
        verificationComplete();
      }
    }
  }

  void verificationComplete() {
    timer?.cancel();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("KYC Verification Successful"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    controller?.dispose();
    detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(controller!),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DeepShield AI",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "KYC Verification",
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: switchCamera,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryAccent,
                  width: 4,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 180,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    instruction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    color: AppTheme.primaryColor,
                    backgroundColor: Colors.white12,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${(progress * 100).toInt()}% Completed",
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}