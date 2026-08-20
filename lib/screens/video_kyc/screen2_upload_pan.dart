import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';
import '../../theme/app_theme.dart';

class Screen2UploadPan extends StatefulWidget {
  final XFile? initialImage;
  final Function(XFile image) onContinue;

  const Screen2UploadPan({
    super.key,
    this.initialImage,
    required this.onContinue,
  });

  @override
  State<Screen2UploadPan> createState() => _Screen2UploadPanState();
}

class _Screen2UploadPanState extends State<Screen2UploadPan> {
  XFile? selectedImage;
  final ImagePicker _picker = ImagePicker();
  String? errorMessage;
  bool _isPickingImage = false;
  ImageSource? _pickingSource;

  @override
  void initState() {
    super.initState();
    selectedImage = widget.initialImage;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;
    setState(() {
      _isPickingImage = true;
      _pickingSource = source;
      errorMessage = null;
    });
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          selectedImage = pickedFile;
          errorMessage = null;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('IMAGE:PICK FAILED: ${e.runtimeType}');
      debugPrint('IMAGE:PICK ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => errorMessage = source == ImageSource.camera
            ? 'Unable to capture the image. Please try again.'
            : 'Unable to select the image. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
          _pickingSource = null;
        });
      }
    }
  }

  void _validateAndContinue() {
    if (selectedImage == null) {
      setState(() {
        errorMessage = "Please capture or upload a Government ID image to proceed.";
      });
      return;
    }

    widget.onContinue(selectedImage!);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = selectedImage != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          const Text(
            "Upload Government ID",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Capture a clear photo of your government-issued ID or upload it from your gallery.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 25),

          // PREVIEW CONTAINER
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: hasImage
                      ? AppTheme.primaryColor
                      : Colors.white.withValues(alpha: 0.15),
                  width: hasImage ? 2 : 1,
                ),
              ),
              child: hasImage
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: kIsWeb
                              ? Image.network(
                                  selectedImage!.path,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.contain,
                                )
                              : Image.file(
                                  File(selectedImage!.path),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.contain,
                                ),
                        ),
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  "Document Loaded",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.badge,
                            size: 64,
                            color: AppTheme.primaryAccent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Select a Government ID",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "PAN Card, Aadhaar Card or other supported ID",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ACTIONS: CAMERA & GALLERY
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isPickingImage
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.8),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isPickingImage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.camera_alt_outlined,
                          color: AppTheme.primaryAccent),
                  label: Text(
                    _isPickingImage
                        ? (_pickingSource == ImageSource.camera
                            ? 'Opening camera...'
                            : 'Opening gallery...')
                        : 'Take Photo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isPickingImage
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.8),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library_outlined,
                      color: AppTheme.primaryAccent),
                  label: Text(
                    _isPickingImage
                        ? (_pickingSource == ImageSource.camera
                            ? 'Opening camera...'
                            : 'Opening gallery...')
                        : 'From Gallery',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // CONTINUE BUTTON
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  hasImage && !_isPickingImage ? _validateAndContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                "Continue to OCR",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
