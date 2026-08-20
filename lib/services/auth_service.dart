import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // SIGN UP
  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Signup Error: [${e.code}] ${e.message}");
      return _mapAuthErrorCode(e.code, e.message);
    } catch (e) {
      debugPrint("Unknown Signup Error: $e");
      return "An unexpected error occurred during signup. Please try again.";
    }
  }

  // LOGIN
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Login Error: [${e.code}] ${e.message}");
      return _mapAuthErrorCode(e.code, e.message);
    } catch (e) {
      debugPrint("Unknown Login Error: $e");
      return "An unexpected error occurred during login. Please try again.";
    }
  }

  // GOOGLE SIGN IN
  Future<String?> signInWithGoogle() async {
    try {
      debugPrint('AUTH:GOOGLE SIGN-IN START');

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({'prompt': 'select_account'});

        final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        final User? user = userCredential.user;

        if (user != null) {
          debugPrint('AUTH:FIREBASE AUTH SUCCESS (WEB)');
          debugPrint('AUTH:GOOGLE UID: ${user.uid}');
          debugPrint('AUTH:CURRENT USER: ${_auth.currentUser?.uid ?? user.uid}');
          // Sync user profile data to Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoUrl': user.photoURL,
            'lastSignInTime': FieldValue.serverTimestamp(),
            'authProvider': 'Google',
          }, SetOptions(merge: true));
        }

        debugPrint('AUTH:GOOGLE SIGN-IN COMPLETE (WEB)');
        return null;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
        clientId: '383611394485-i6l6ha4imrqmlkfee121pk0ieobsq4bb.apps.googleusercontent.com',
        serverClientId: '383611394485-i6l6ha4imrqmlkfee121pk0ieobsq4bb.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('AUTH:GOOGLE SIGN-IN CANCELLED');
        return 'Google sign-in cancelled.';
      }

      debugPrint('AUTH:GOOGLE ACCOUNT SELECTED');
      debugPrint('AUTH:GOOGLE EMAIL: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        debugPrint('AUTH:GOOGLE ID TOKEN MISSING');
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'Google did not return an ID token.',
        );
      }
      debugPrint('AUTH:GOOGLE ID TOKEN RECEIVED');
      if (googleAuth.accessToken != null) {
        debugPrint('AUTH:GOOGLE ACCESS TOKEN RECEIVED');
      } else {
        debugPrint('AUTH:GOOGLE ACCESS TOKEN NOT AVAILABLE');
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      debugPrint('AUTH:FIREBASE CREDENTIAL CREATED');

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        debugPrint('AUTH:FIREBASE AUTH SUCCESS');
        debugPrint('AUTH:GOOGLE UID: ${user.uid}');
        debugPrint('AUTH:CURRENT USER: ${_auth.currentUser?.uid ?? user.uid}');
        // Sync user profile data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? googleUser.displayName,
          'photoUrl': user.photoURL ?? googleUser.photoUrl,
          'lastSignInTime': FieldValue.serverTimestamp(),
          'authProvider': 'Google',
        }, SetOptions(merge: true));
      }

      debugPrint('AUTH:GOOGLE SIGN-IN COMPLETE');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('AUTH:GOOGLE SIGN-IN FAILED');
      debugPrint('AUTH:GOOGLE ERROR TYPE: FirebaseAuthException');
      debugPrint('AUTH:GOOGLE ERROR CODE: ${e.code}');
      debugPrint('AUTH:GOOGLE ERROR MESSAGE: ${e.message}');
      return 'Google sign-in failed. Please try again.';
    } catch (e) {
      debugPrint('AUTH:GOOGLE SIGN-IN FAILED');
      debugPrint('AUTH:GOOGLE ERROR TYPE: ${e.runtimeType}');
      debugPrint('AUTH:GOOGLE ERROR CODE: UNKNOWN');
      debugPrint('AUTH:GOOGLE ERROR MESSAGE: $e');
      return 'Google sign-in error: $e';
    }
  }

  // LOGOUT
  Future<String?> logout() async {
    String? googleSignOutError;
    try {
      debugPrint('AUTH:GOOGLE SIGN-OUT START');
      await GoogleSignIn().signOut();
      debugPrint('AUTH:GOOGLE SIGN-OUT COMPLETE');
    } catch (e) {
      debugPrint('AUTH:GOOGLE SIGN-OUT ERROR: $e');
      googleSignOutError = 'Signed out, but the Google session could not be cleared.';
    }

    try {
      await FirebaseAuth.instance.signOut();
      debugPrint('AUTH:FIREBASE SIGN-OUT COMPLETE');
      return googleSignOutError;
    } on FirebaseAuthException catch (e) {
      debugPrint('AUTH:FIREBASE SIGN-OUT FAILED: [${e.code}] ${e.message}');
      return 'Unable to sign out. Please try again.';
    } catch (e) {
      debugPrint('AUTH:FIREBASE SIGN-OUT FAILED: $e');
      return 'Unable to sign out. Please try again.';
    }
  }

  // RESET PASSWORD
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("Reset Password Error: [${e.code}] ${e.message}");
      return _mapAuthErrorCode(e.code, e.message);
    } catch (e) {
      debugPrint("Unknown Reset Password Error: $e");
      return "An unexpected error occurred sending reset email.";
    }
  }

  // Helper method for clean user-facing auth error messages
  String _mapAuthErrorCode(String code, String? defaultMessage) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please check your credentials.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'invalid-email':
        return 'Please provide a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters long.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      default:
        return defaultMessage ?? 'Authentication failed. Please try again.';
    }
  }

  // CURRENT USER
  User? get currentUser => _auth.currentUser;
}
