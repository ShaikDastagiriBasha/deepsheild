import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../theme/app_theme.dart';
import '../../services/web_helpers/web_interop.dart';

class Screen6Liveness extends StatefulWidget {
  final VoidCallback onComplete;

  const Screen6Liveness({
    super.key,
    required this.onComplete,
  });

  @override
  State<Screen6Liveness> createState() => _Screen6LivenessState();
}

class _Screen6LivenessState extends State<Screen6Liveness> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;
  bool _isEvaluatingFrame = false;
  Timer? _detectionTimer;
  Timer? _timeoutTimer;

  // Debug variables
  int _faceCount = 0;
  double _lastAngleY = 0.0;
  double _lastLeftEye = 0.0;
  double _lastRightEye = 0.0;
  double _lastSmile = 0.0;

  // Liveness Checklist state
  bool blinkDone = false;
  bool turnLeftDone = false;
  bool turnRightDone = false;
  bool smileDone = false;

  // Current step 0=Look, 1=Blink, 2=TurnLeft, 3=TurnRight, 4=Smile, 5=Done, -1=TimedOut
  int currentChallenge = 0;
  int secondsRemaining = 40;

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  void _evaluateFaceWeb({required double yaw, required double leftEye, required double rightEye, required double smile}) {
    if (!mounted) return;

    _lastAngleY = yaw;
    _lastLeftEye = leftEye;
    _lastRightEye = rightEye;
    _lastSmile = smile;

    _checkChallenge(yaw: yaw, leftEye: leftEye, rightEye: rightEye, smileProb: smile);
  }

  void _checkChallenge({
    required double yaw,
    required double leftEye,
    required double rightEye,
    required double smileProb,
  }) {
    // CHALLENGE 0: LOOK AT CAMERA
    if (currentChallenge == 0) {
      if (yaw > -15 && yaw < 15) {
        setState(() {
          currentChallenge = 1;
        });
      }
    }
    // CHALLENGE 1: BLINK
    else if (currentChallenge == 1) {
      if (leftEye < 0.2 && rightEye < 0.2) {
        setState(() {
          blinkDone = true;
          currentChallenge = 2;
        });
      }
    }
    // CHALLENGE 2: TURN LEFT
    else if (currentChallenge == 2) {
      if (yaw > 25) {
        setState(() {
          turnLeftDone = true;
          currentChallenge = 3;
        });
      }
    }
    // CHALLENGE 3: TURN RIGHT
    else if (currentChallenge == 3) {
      if (yaw < -25) {
        setState(() {
          turnRightDone = true;
          currentChallenge = 4;
        });
      }
    }
    // CHALLENGE 4: SMILE
    else if (currentChallenge == 4) {
      if (smileProb > 0.7) {
        setState(() {
          smileDone = true;
          currentChallenge = 5;
        });
        widget.onComplete();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _detectionTimer?.cancel();
      _timeoutTimer?.cancel();
      _controller?.dispose();
      if (mounted) {
        setState(() {
          _isCameraReady = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      CameraDescription frontCam = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        frontCam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: kIsWeb 
            ? ImageFormatGroup.jpeg 
            : (Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888),
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
        _startAutoDetection();
        _startTimeoutTimer();
      }
    } catch (e) {
      debugPrint("Liveness camera init error: $e");
    }
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (currentChallenge >= 5) {
        timer.cancel();
        return;
      }
      setState(() {
        secondsRemaining--;
        if (secondsRemaining <= 0) {
          currentChallenge = -1; // Timed out
          _detectionTimer?.cancel();
          timer.cancel();
        }
      });
    });
  }

  void _startAutoDetection() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      if (kIsWeb) {
        _startWebDetectionLoop();
      } else {
        _controller!.startImageStream((CameraImage image) {
          if (_isEvaluatingFrame || currentChallenge < 0 || currentChallenge > 4) return;
          _processCameraFrame(image);
        });
      }
    } catch (e) {
      debugPrint("startImageStream error: $e");
    }
  }

  void _startWebDetectionLoop() {
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) async {
      if (!mounted || _isEvaluatingFrame || currentChallenge < 0 || currentChallenge > 4) return;
      if (_controller == null || !_controller!.value.isInitialized) return;
      
      _isEvaluatingFrame = true;
      try {
        final xfile = await _controller!.takePicture();
        final bytes = await xfile.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        final resultJson = await evaluateLivenessFrameWeb(base64Image);
        final json = jsonDecode(resultJson);
        
        if (json['success'] == true) {
          if (mounted) {
            setState(() {
              _faceCount = 1;
            });
            _evaluateFaceWeb(
              yaw: (json['yaw'] as num?)?.toDouble() ?? 0.0,
              leftEye: (json['leftEyeOpen'] as num?)?.toDouble() ?? 1.0,
              rightEye: (json['rightEyeOpen'] as num?)?.toDouble() ?? 1.0,
              smile: (json['smileProb'] as num?)?.toDouble() ?? 0.0,
            );
          }
        } else {
           if (mounted) setState(() => _faceCount = 0);
        }
      } catch (e) {
        debugPrint("Web Liveness loop error: $e");
      } finally {
        _isEvaluatingFrame = false;
      }
    });
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    _isEvaluatingFrame = true;
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await _detector.processImage(inputImage);
      if (mounted) {
        setState(() {
          _faceCount = faces.length;
        });
      }
      if (faces.isNotEmpty) {
        _evaluateFace(faces.first);
      }
    } catch (e) {
      debugPrint("Liveness eval error: $e");
    } finally {
      // Removed throttling delay to make detection much faster and more responsive
      _isEvaluatingFrame = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null || _cameras.isEmpty) return null;
    final camera = _cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );
    
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final InputImageRotation imageRotation = 
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;

    final InputImageFormat inputImageFormat = Platform.isAndroid 
        ? InputImageFormat.nv21 
        : InputImageFormat.bgra8888;

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes.isNotEmpty ? image.planes.first.bytesPerRow : 0,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
  }

  void _evaluateFace(Face face) {
    if (!mounted) return;

    final angleY = face.headEulerAngleY ?? 0.0;
    final leftEye = face.leftEyeOpenProbability ?? 1.0;
    final rightEye = face.rightEyeOpenProbability ?? 1.0;
    final smileProb = face.smilingProbability ?? 0.0;

    setState(() {
      _lastAngleY = angleY;
      _lastLeftEye = leftEye;
      _lastRightEye = rightEye;
      _lastSmile = smileProb;
    });

    // CHALLENGE 0: LOOK AT CAMERA
    if (currentChallenge == 0) {
      if (angleY > -15 && angleY < 15) {
        setState(() {
          currentChallenge = 1;
        });
        return;
      }
    }

    // CHALLENGE 1: BLINK
    if (currentChallenge == 1) {
      // Both eyes should be mostly closed for a valid blink
      if (leftEye < 0.35 && rightEye < 0.35) { 
        setState(() {
          blinkDone = true;
          currentChallenge = 2;
        });
        return;
      }
    }

    // CHALLENGE 2: TURN HEAD LEFT
    if (currentChallenge == 2) {
      // ML Kit: angleY > 0 means the subject is turning to THEIR left
      if (angleY > 25.0) { 
        setState(() {
          turnLeftDone = true;
          currentChallenge = 3;
        });
        return;
      }
    }

    // CHALLENGE 3: TURN HEAD RIGHT
    if (currentChallenge == 3) {
      // ML Kit: angleY < 0 means the subject is turning to THEIR right
      if (angleY < -25.0) { 
        setState(() {
          turnRightDone = true;
          currentChallenge = 4;
        });
        return;
      }
    }

    // CHALLENGE 4: SMILE
    if (currentChallenge == 4) {
      // Require a clear smile while facing roughly forward
      if (smileProb > 0.60 && angleY > -15 && angleY < 15) { 
        setState(() {
          smileDone = true;
          currentChallenge = 5;
        });
        
        // Stop streaming instead of canceling a timer
        try {
          _controller?.stopImageStream();
        } catch (_) {}
        _timeoutTimer?.cancel();
        
        // Lock frame evaluation to safely dispose camera
        _isEvaluatingFrame = true;
        
        Future.delayed(const Duration(milliseconds: 600), () async {
          // Explicitly stop the camera before navigating to avoid BufferQueue abandoned errors
          if (_controller != null) {
            await _controller!.dispose();
            _controller = null;
          }
          if (mounted) {
            widget.onComplete();
          }
        });
      }
    }
  }

  void _retryLiveness() {
    setState(() {
      blinkDone = false;
      turnLeftDone = false;
      turnRightDone = false;
      smileDone = false;
      currentChallenge = 0;
      secondsRemaining = 40;
    });
    _startAutoDetection();
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      _controller?.stopImageStream();
    } catch (_) {}
    _detectionTimer?.cancel();
    _timeoutTimer?.cancel();
    _controller?.dispose();
    _detector.close();
    super.dispose();
  }

  String get _currentInstructionText {
    switch (currentChallenge) {
      case 0:
        return "Look at Camera";
      case 1:
        return "Blink Your Eyes";
      case 2:
        return "Turn Head Left";
      case 3:
        return "Turn Head Right";
      case 4:
        return "Smile!";
      case 5:
        return "Liveness Passed!";
      case -1:
        return "Liveness Timed Out";
      default:
        return "Verification Complete";
    }
  }

  IconData get _currentInstructionIcon {
    switch (currentChallenge) {
      case 0:
        return Icons.face;
      case 1:
        return Icons.remove_red_eye_outlined;
      case 2:
        return Icons.turn_left;
      case 3:
        return Icons.turn_right;
      case 4:
        return Icons.sentiment_satisfied_alt;
      case -1:
        return Icons.timer_off_outlined;
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TITLE & PROGRESS OVERVIEW
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Liveness Verification",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: secondsRemaining <= 10
                          ? Colors.redAccent.withValues(alpha: 0.2)
                          : AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: secondsRemaining <= 10 ? Colors.redAccent : AppTheme.primaryAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${secondsRemaining}s",
                          style: TextStyle(
                            color: secondsRemaining <= 10 ? Colors.redAccent : AppTheme.primaryAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Follow instructions one by one",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // LIVE CAMERA VIEW WITH INSTRUCTION OVERLAY
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isCameraReady && _controller != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    ),
                  ),

                // ACTIVE OVAL OVERLAY
                Container(
                  width: 250,
                  height: 310,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.elliptical(125, 155)),
                    border: Border.all(
                      color: currentChallenge == 5
                          ? Colors.greenAccent
                          : (currentChallenge == -1 ? Colors.redAccent : AppTheme.primaryColor),
                      width: 3.5,
                    ),
                  ),
                ),

                // INSTRUCTION CARD - SINGLE INSTRUCTION SHOWN AT A TIME
                Positioned(
                  bottom: 30,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: currentChallenge == 5
                            ? Colors.greenAccent
                            : (currentChallenge == -1 ? Colors.redAccent : AppTheme.primaryAccent),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentInstructionIcon,
                          color: currentChallenge == 5
                              ? Colors.greenAccent
                              : (currentChallenge == -1 ? Colors.redAccent : AppTheme.primaryAccent),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _currentInstructionText,
                          style: TextStyle(
                            color: currentChallenge == 5
                                ? Colors.greenAccent
                                : (currentChallenge == -1 ? Colors.redAccent : Colors.white),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 15),

        // PROGRESS STATUS LIST
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem("Blink", blinkDone, currentChallenge == 1),
                _buildStatusItem("Left", turnLeftDone, currentChallenge == 2),
                _buildStatusItem("Right", turnRightDone, currentChallenge == 3),
                _buildStatusItem("Smile", smileDone, currentChallenge == 4),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // TIMEOUT OR SIMULATION ACTIONS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: currentChallenge == -1
              ? ElevatedButton.icon(
                  onPressed: _retryLiveness,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Liveness Timed Out - Tap to Retry"),
                )
              : const Text(
                  "Follow on-screen instructions to verify liveness",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(String title, bool isDone, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? Colors.green
                : (isActive ? AppTheme.primaryColor : Colors.white10),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    isActive ? "..." : "-",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: isDone
                ? Colors.greenAccent
                : (isActive ? Colors.white : Colors.white54),
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
