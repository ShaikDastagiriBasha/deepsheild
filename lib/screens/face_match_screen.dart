import 'dart:io';
import 'dart:math';
import '../services/face_recognition_service.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FaceMatchScreen extends StatefulWidget {
  final File documentImage;

  const FaceMatchScreen({
    super.key,
    required this.documentImage,
  });

  @override
  State<FaceMatchScreen> createState() =>
      _FaceMatchScreenState();
}

class _FaceMatchScreenState
    extends State<FaceMatchScreen> {

  final FaceRecognitionService faceService =
    FaceRecognitionService();

  CameraController? controller;

  bool loading = true;

  File? selfieImage;

  double similarity = 0;

  bool verified = false;

@override
void initState() {
  super.initState();

print("############################");
print("FACE MATCH SCREEN OPENED");
print("############################");

  initializeCamera();

  faceService.loadModel();
}

  Future<void> initializeCamera() async {

    final cameras =
        await availableCameras();

    final frontCamera =
        cameras.firstWhere(
      (camera) =>
          camera.lensDirection ==
          CameraLensDirection.front,
    );

    controller = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller!.initialize();

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> saveVerification() async {

    final doc =
        await FirebaseFirestore.instance
            .collection("scans")
            .add({

      "matchScore": similarity,

      "status":
          verified
              ? "Verified"
              : "Failed",

      "timestamp":
          FieldValue.serverTimestamp(),
    });

    debugPrint(
      "FIRESTORE SAVE SUCCESS: ${doc.id}",
    );
  }

  Future<void> captureSelfie() async {

    if (controller == null) {
      return;
    }

    try {

      final XFile image =
          await controller!
              .takePicture();

      setState(() {
        selfieImage =
            File(image.path);
      });

      performFaceMatch();

      await performFaceMatch();

      await saveVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Verification Saved Successfully",
          ),
        ),
      );

    } catch (e) {

      debugPrint(
        "Capture Error: $e",
      );
    }
  }

Future<void> performFaceMatch() async {

  try {

    final documentEmbedding =
        await faceService.getEmbedding(
      widget.documentImage,
    );

    final selfieEmbedding =
        await faceService.getEmbedding(
      selfieImage!,
    );

    print("DOCUMENT EMBEDDING:");
    print(documentEmbedding.take(10).toList());

    print("SELFIE EMBEDDING:");
    print(selfieEmbedding.take(10).toList());

    final score =
        faceService.compareFaces(
      documentEmbedding,
      selfieEmbedding,
    );

similarity = ((score + 1) / 2) * 100;

    verified =
        similarity > 50;

    setState(() {});

    print(
      "REAL AI MATCH SCORE: $similarity",
    );

  } catch (e) {

    print(
      "FACE MATCH ERROR: $e",
    );
  }
}

@override
void dispose() {

  controller?.dispose();

  faceService.dispose();

  super.dispose();
}

  @override
  Widget build(
      BuildContext context) {

    if (loading ||
        controller == null ||
        !controller!
            .value
            .isInitialized) {

      return const Scaffold(
        backgroundColor:
            Color(0xFF081120),
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(

      backgroundColor:
          const Color(0xFF081120),

      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        title: const Text(
          "Face Match Verification",
        ),
      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(
                20),

        child: Column(
          children: [

            const SizedBox(
                height: 10),

            const Text(
              "DeepShield AI Face Verification",
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.white,
                fontSize: 28,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
                height: 10),

            const Text(
              "Capture live selfie for identity matching",
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.white70,
                fontSize: 15,
              ),
            ),

            const SizedBox(
                height: 30),

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                      20),
              child: SizedBox(
                height: 350,
                child:
                    CameraPreview(
                  controller!,
                ),
              ),
            ),

            const SizedBox(
                height: 30),

            SizedBox(
              width:
                  double.infinity,
              height: 60,
              child:
                  ElevatedButton(
                onPressed:
                    captureSelfie,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.blueAccent,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                            18),
                  ),
                ),
                child:
                    const Text(
                  "Capture Selfie",
                  style:
                      TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(
                height: 30),

            if (selfieImage != null)
              Column(
                children: [

                  Row(
                    children: [

                      Expanded(
                        child: Column(
                          children: [

                            const Text(
                              "Document",
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                              ),
                            ),

                            const SizedBox(
                                height:
                                    10),

                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                      15),
                              child:
                                  Image.file(
                                widget
                                    .documentImage,
                                height:
                                    150,
                                fit: BoxFit
                                    .cover,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                          width: 15),

                      Expanded(
                        child: Column(
                          children: [

                            const Text(
                              "Live Selfie",
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                              ),
                            ),

                            const SizedBox(
                                height:
                                    10),

                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                      15),
                              child:
                                  Image.file(
                                selfieImage!,
                                height:
                                    150,
                                fit: BoxFit
                                    .cover,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 30),

                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets
                            .all(25),
                    decoration:
                        BoxDecoration(
                      color: verified
                          ? Colors.green
                              .withOpacity(
                                  0.2)
                          : Colors.red
                              .withOpacity(
                                  0.2),
                      borderRadius:
                          BorderRadius.circular(
                              22),
                      border:
                          Border.all(
                        color: verified
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    child: Column(
                      children: [

                        Icon(
                          verified
                              ? Icons
                                  .verified
                              : Icons
                                  .warning,
                          color: verified
                              ? Colors.green
                              : Colors.red,
                          size: 60,
                        ),

                        const SizedBox(
                            height:
                                20),

                        Text(
                          "${similarity.toStringAsFixed(1)}% Match",
                          style:
                              TextStyle(
                            color:
                                verified
                                    ? Colors.green
                                    : Colors.red,
                            fontSize:
                                34,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                            height:
                                10),

                        Text(
                          verified
                              ? "IDENTITY VERIFIED"
                              : "MATCH FAILED",
                          style:
                              TextStyle(
                            color:
                                verified
                                    ? Colors.green
                                    : Colors.red,
                            fontSize:
                                18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}