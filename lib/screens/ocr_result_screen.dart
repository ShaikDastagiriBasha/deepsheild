import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'face_match_screen.dart';

class OCRResultScreen extends StatefulWidget {

  final File imageFile;

  const OCRResultScreen({
    super.key,
    required this.imageFile,
  });

  @override
  State<OCRResultScreen> createState() =>
      _OCRResultScreenState();
}

class _OCRResultScreenState
    extends State<OCRResultScreen> {

  bool isLoading = true;

  String extractedText = "";

  String documentNumber = "";

  String detectedName = "";

  String documentType = "Unknown";

  @override
  void initState() {
    super.initState();

    processOCR();
  }

  // OCR PROCESS
  Future<void> processOCR() async {

    try {

      final textRecognizer =
          TextRecognizer();

      final inputImage =
          InputImage.fromFile(
        widget.imageFile,
      );

      final RecognizedText
          recognizedText =
          await textRecognizer
              .processImage(
        inputImage,
      );

      extractedText =
          recognizedText.text;

      extractFields();

      await textRecognizer.close();

    } catch (e) {

      print("OCR Error: $e");
    }

    setState(() {

      isLoading = false;
    });
  }

  // EXTRACT DOCUMENT DETAILS
  void extractFields() {

    // AADHAAR
    final aadhaarRegex =
        RegExp(r'\d{4}\s\d{4}\s\d{4}');

    final aadhaarMatch =
        aadhaarRegex.firstMatch(
      extractedText,
    );

    if (aadhaarMatch != null) {

      documentType =
          "Aadhaar Card";

      documentNumber =
          aadhaarMatch.group(0)!;
    }

    // PAN
    final panRegex =
        RegExp(
      r'[A-Z]{5}[0-9]{4}[A-Z]{1}',
    );

    final panMatch =
        panRegex.firstMatch(
      extractedText,
    );

    if (panMatch != null) {

      documentType =
          "PAN Card";

      documentNumber =
          panMatch.group(0)!;
    }

    // NAME EXTRACTION
    final lines =
        extractedText
            .split('\n');

    for (String line in lines) {

      line = line.trim();

      if (line.length > 3 &&
          !line.contains(
              RegExp(r'\d'))) {

        detectedName = line;

        break;
      }
    }
  }

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFF081120),

      appBar: AppBar(

        backgroundColor:
            Colors.transparent,

        elevation: 0,

        title: const Text(
          "DeepShield OCR",
        ),
      ),

      body: isLoading

          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Colors.blueAccent,
              ),
            )

          : Padding(
              padding:
                  const EdgeInsets
                      .all(20),

              child:
                  SingleChildScrollView(

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [

                    // IMAGE PREVIEW
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                              20),

                      child: Image.file(
                        widget.imageFile,

                        height: 220,

                        width:
                            double.infinity,

                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(
                        height: 30),

                    // TITLE
                    const Text(
                      "DeepShield AI Analysis",

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
                      "OCR document extraction completed successfully",

                      style: TextStyle(
                        color:
                            Colors.white70,

                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(
                        height: 30),

                    // DOCUMENT TYPE
                    infoCard(
                      "Document Type",
                      documentType,
                    ),

                    const SizedBox(
                        height: 20),

                    // NAME
                    infoCard(
                      "Detected Name",
                      detectedName.isEmpty
                          ? "Not Found"
                          : detectedName,
                    ),

                    const SizedBox(
                        height: 20),

                    // NUMBER
                    infoCard(
                      "Document Number",
                      documentNumber
                              .isEmpty
                          ? "Not Found"
                          : documentNumber,
                    ),

                    const SizedBox(
                        height: 30),

                    // EXTRACTED TEXT
                    const Text(
                      "Extracted Text",

                      style: TextStyle(
                        color:
                            Colors.white,

                        fontSize: 22,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                        height: 20),

                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets
                              .all(20),

                      decoration:
                          BoxDecoration(
                        color: Colors
                            .white
                            .withOpacity(
                                0.06),

                        borderRadius:
                            BorderRadius.circular(
                                20),
                      ),

                      child: Text(
                        extractedText
                                .isEmpty
                            ? "No text detected"
                            : extractedText,

                        style:
                            const TextStyle(
                          color:
                              Colors.white70,

                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 35),

                    // FACE MATCH BUTTON
                    SizedBox(
                      width:
                          double.infinity,

                      height: 60,

                      child:
                          ElevatedButton(

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

                        onPressed: () {

                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      FaceMatchScreen(
                                documentImage:
                                    widget.imageFile,
                              ),
                            ),
                          );
                        },

                        child: const Text(
                          "Continue to Face Match",

                          style: TextStyle(
                            fontSize: 18,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // INFO CARD
  Widget infoCard(
    String title,
    String value,
  ) {

    return Container(

      width: double.infinity,

      padding:
          const EdgeInsets.all(
              20),

      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(
                0.06),

        borderRadius:
            BorderRadius.circular(
                20),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [

          Text(
            title,

            style: const TextStyle(
              color:
                  Colors.white70,

              fontSize: 15,
            ),
          ),

          const SizedBox(
              height: 10),

          Text(
            value,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 22,

              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}