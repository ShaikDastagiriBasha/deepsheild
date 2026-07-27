import 'dart:io';
import 'ocr_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'ocr_result_screen.dart';

class DocumentUploadScreen
    extends StatefulWidget {

  const DocumentUploadScreen({
    super.key,
  });

  @override
  State<DocumentUploadScreen>
      createState() =>
          _DocumentUploadScreenState();
}

class _DocumentUploadScreenState
    extends State<DocumentUploadScreen> {

  File? selectedImage;

  final ImagePicker picker =
      ImagePicker();

  String selectedDocument =
      "Aadhaar Card";

  // PICK IMAGE
  Future<void> pickImage() async {

    final XFile? image =
        await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {

      setState(() {

        selectedImage =
            File(image.path);
      });
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
          "Upload Document",
        ),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          children: [

            const SizedBox(height: 20),

            // TITLE
            const Text(
              "Identity Verification",

              style: TextStyle(
                color: Colors.white,

                fontSize: 28,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Upload your government ID for verification",

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color:
                    Colors.white70,

                fontSize: 16,
              ),
            ),

            const SizedBox(height: 40),

            // DOCUMENT TYPE
            DropdownButtonFormField(
              dropdownColor:
                  const Color(
                      0xFF1E293B),

              value:
                  selectedDocument,

              style: const TextStyle(
                color: Colors.white,
              ),

              decoration:
                  InputDecoration(
                filled: true,

                fillColor:
                    Colors.white10,

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                          15),
                ),
              ),

              items: [

                "Aadhaar Card",

                "PAN Card",

                "Driving License",

                "Passport",
              ].map((item) {

                return DropdownMenuItem(
                  value: item,

                  child: Text(item),
                );
              }).toList(),

              onChanged: (value) {

                setState(() {

                  selectedDocument =
                      value!;
                });
              },
            ),

            const SizedBox(height: 30),

            // UPLOAD BOX
            GestureDetector(

              onTap: pickImage,

              child: Container(
                width: double.infinity,

                height: 300,

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white10,

                  borderRadius:
                      BorderRadius.circular(
                          20),

                  border: Border.all(
                    color:
                        Colors.blueAccent,

                    width: 2,
                  ),
                ),

                child: selectedImage ==
                        null
                    ? const Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,

                        children: [

                          Icon(
                            Icons.upload_file,

                            color:
                                Colors.blueAccent,

                            size: 80,
                          ),

                          SizedBox(
                              height: 20),

                          Text(
                            "Tap to Upload Document",

                            style:
                                TextStyle(
                              color:
                                  Colors.white,

                              fontSize:
                                  18,

                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                                18),

                        child: Image.file(
                          selectedImage!,

                          fit: BoxFit.cover,

                          width:
                              double.infinity,
                        ),
                      ),
              ),
            ),

            const Spacer(),

            // CONTINUE BUTTON
            SizedBox(
              width: double.infinity,

              height: 60,

              child: ElevatedButton(

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

onPressed: selectedImage == null
    ? null
    : () {

        Navigator.push(
          context,

          MaterialPageRoute(
            builder: (context) =>
                OCRResultScreen(
              imageFile:
                  selectedImage!,
            ),
          ),
        );
      },

                child: const Text(
                  "Continue",

                  style: TextStyle(
                    fontSize: 18,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}