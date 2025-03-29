import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = true;

  // Constructor that listens to auth state changes
  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _isLoading = false;
      notifyListeners();
    });
  }

  // Getters
  bool get isLoading => _isLoading;

  User? get currentUser => _auth.currentUser;

  // Convert Firebase user to our app's user model
  UserModel? get userModel {
    final user = currentUser;
    if (user == null) return null;

    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
    );
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user canceled the sign-in flow
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);

      _isLoading = false;
      notifyListeners();
      return userCredential;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Sign in anonymously (Guest mode)
  Future<UserCredential?> signInAnonymously() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.signInAnonymously();

      _isLoading = false;
      notifyListeners();
      return userCredential;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _googleSignIn.signOut();
      await _auth.signOut();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
