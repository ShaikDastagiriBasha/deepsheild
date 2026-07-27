import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // SIGN UP
  Future<String?> signUp({
    required String email,
    required String password,
  }) async {

    print("SIGNUP STARTED");
    print("EMAIL: $email");

    try {

      await _auth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("SIGNUP SUCCESS");

      return null;

    } on FirebaseAuthException catch (e) {

      print("FIREBASE SIGNUP ERROR");
      print("CODE: ${e.code}");
      print("MESSAGE: ${e.message}");

      return e.message;

    } catch (e) {

      print("UNKNOWN SIGNUP ERROR");
      print(e);

      return e.toString();
    }
  }

  // LOGIN
  Future<String?> login({
    required String email,
    required String password,
  }) async {

    print("LOGIN STARTED");

    try {

      await _auth
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("LOGIN SUCCESS");

      return null;

    } on FirebaseAuthException catch (e) {

      print("LOGIN ERROR");
      print("CODE: ${e.code}");
      print("MESSAGE: ${e.message}");

      return e.message;

    } catch (e) {

      print("UNKNOWN LOGIN ERROR");
      print(e);

      return e.toString();
    }
  }

  // LOGOUT
  Future<void> logout() async {

    await _auth.signOut();

    print("LOGOUT SUCCESS");
  }

  // RESET PASSWORD
  Future<String?> resetPassword(
      String email) async {

    try {

      await _auth
          .sendPasswordResetEmail(
        email: email,
      );

      print("RESET EMAIL SENT");

      return null;

    } on FirebaseAuthException catch (e) {

      print("RESET ERROR");
      print("CODE: ${e.code}");
      print("MESSAGE: ${e.message}");

      return e.message;
    }
  }

  // CURRENT USER
  User? get currentUser =>
      _auth.currentUser;
}