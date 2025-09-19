import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signUp(String email, String password, String name) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = UserModel(uid: cred.user!.uid, email: email, name: name);
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      return cred.user;
    } catch (e) {
      print('Sign-up error: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile(String uid, String name, String phone, {String? fcmToken}) async {
    try {
      final updateData = {'name': name, 'phone': phone};
      if (fcmToken != null) {
        updateData['fcmToken'] = fcmToken;
      }
      await FirebaseFirestore.instance.collection('users').doc(uid).update(updateData);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw _authErrorToMessage(e);
    } catch (e) {
      throw 'An unknown error occurred';
    }
  }

  String _authErrorToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      default:
        return e.message ?? 'Authentication failed';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign-out error: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? UserModel.fromMap(doc.data()!) : null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}