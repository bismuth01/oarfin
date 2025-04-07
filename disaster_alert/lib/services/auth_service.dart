import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  // Constructor that listens to auth state changes
  AuthService() {
    _auth.authStateChanges().listen((User? user) async {
      _isLoading = false;

      // Sync user data with server whenever auth state changes
      // and user is logged in
      if (user != null) {
        await _syncUserWithServer();
      }

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
      // Default values for other properties
      friendIds: const [],
      isAnonymous: user.isAnonymous,
    );
  }

  // Sync current user with server
  Future<void> _syncUserWithServer() async {
    final user = userModel;
    if (user == null) return;

    try {
      // Post user data to server
      await _apiService.post('/api/users/sync', data: {
        'userID': user.id,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'isAnonymous': user.isAnonymous,
      });

      print('User data synced with server: ${user.email}');
    } catch (e) {
      print('Failed to sync user data with server: $e');
    }
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

      // After successful sign-in, sync user data with server
      await _syncUserWithServer();

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

      // After successful sign-in, sync user data with server
      await _syncUserWithServer();

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
