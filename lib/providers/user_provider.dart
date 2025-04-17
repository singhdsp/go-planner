import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;

  UserProvider() {
    _initUser();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  // Initialize user on app start
  Future<void> _initUser() async {
    _isLoading = true;
    notifyListeners();
    
    // Get current user
    _user = _authService.currentUser;
    _isLoading = false;
    notifyListeners();
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Sign up with email and password
  Future<void> createUserWithEmailAndPassword(
    String email, 
    String password, 
    String displayName
  ) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final credential = await _authService.createUserWithEmailAndPassword(email, password);
      if (credential.user != null) {
        await _authService.updateUserProfile(displayName: displayName);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.signOut();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      
      // Refresh user data
      _user = _authService.currentUser;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    
    _isLoading = false;
    notifyListeners();
  }
}