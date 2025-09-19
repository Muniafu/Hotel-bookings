import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == 'admin';

  AuthProvider() {
    _initUser();
  }

  Future<void> _initUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _user = await _authService.getUserProfile(firebaseUser.uid);
        // Update FCM token
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null && _user != null) {
          await _authService.updateUserProfile(_user!.uid, _user!.name, _user!.phone, fcmToken: fcmToken);
        }
      }
    } catch (e) {
      print('Error initializing user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({required String name, required String phone}) async {
    if (_user == null) return;
    try {
      await _authService.updateUserProfile(_user!.uid, name, phone);
      _user = UserModel(
        uid: _user!.uid,
        email: _user!.email,
        name: name,
        phone: phone,
        address: _user!.address,
        preferences: _user!.preferences,
        bookingHistory: _user!.bookingHistory,
        role: _user!.role,
        fcmToken: _user!.fcmToken,
      );
      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final firebaseUser = await _authService.signIn(email, password);
      if (firebaseUser != null) {
        _user = await _authService.getUserProfile(firebaseUser.uid);
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null && _user != null) {
          await _authService.updateUserProfile(_user!.uid, _user!.name, _user!.phone, fcmToken: fcmToken);
        }
        notifyListeners();
      }
    } catch (e) {
      print('Sign-in error: $e');
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      final firebaseUser = await _authService.signUp(email, password, name);
      if (firebaseUser != null) {
        _user = await _authService.getUserProfile(firebaseUser.uid);
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null && _user != null) {
          await _authService.updateUserProfile(_user!.uid, _user!.name, _user!.phone, fcmToken: fcmToken);
        }
        notifyListeners();
      }
    } catch (e) {
      print('Sign-up error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      print('Sign-out error: $e');
      rethrow;
    }
  }
}