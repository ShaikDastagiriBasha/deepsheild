import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ProfileImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Compress image to reduce upload size
      final bytes = await imageFile.readAsBytes();
      var decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) throw Exception('Failed to decode image');
      
      // Resize if too large, keeping aspect ratio
      if (decodedImage.width > 800 || decodedImage.height > 800) {
        decodedImage = img.copyResize(decodedImage, width: 800);
      }
      
      final compressedBytes = img.encodeJpg(decodedImage, quality: 75);
      
      // Save temporarily
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_profile.jpg');
      await tempFile.writeAsBytes(compressedBytes);

      // 2. Upload to Firebase Storage
      final ref = _storage.ref().child('profile_images/${user.uid}.jpg');
      
      // Set metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );
      
      debugPrint('PROFILE: Uploading image to ${ref.fullPath}...');
      final uploadTask = await ref.putFile(tempFile, metadata);
      
      // 3. Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('PROFILE: Upload successful. URL: $downloadUrl');
      
      // 4. Update Firestore user document
      await _firestore.collection('users').doc(user.uid).update({
        'profileImageUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('PROFILE: Firestore document updated.');
      
      return downloadUrl;
    } catch (e) {
      debugPrint('PROFILE: Error uploading image - $e');
      return null;
    }
  }
}
