import 'face_recognition_service.dart';
import 'ocr_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final FaceRecognitionService faceRecognitionService;
  late final OCRService ocrService;

  Future<void> initialize() async {
    faceRecognitionService = FaceRecognitionService();
    ocrService = OCRService();
    
    // Pre-load the models in the background to avoid blocking the main UI thread during startup.
    faceRecognitionService.loadModel();
  }
}
