import 'package:flutter/material.dart';
import 'package:bookings/domain/services/admin.dart';

import '../domain/models/admin.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  AdminModel? _user;
  String? _errorMessage;
  AdminModel? get user => _user;
  String? get errorMessage => _errorMessage;
  Future setAdmin(admin) async {
    _adminService.setAdmin(admin);
  }

  Future signInWithEmailAndPassword(
      BuildContext context, String email, String password) async {
    AdminModel? createdUser = await _adminService.signInWithEmailAndPassword(
        context, AdminModel(email: email, password: password));
    //debugPrint('createdUser: $createdUser');
    _user = createdUser;
    _errorMessage = null;
    notifyListeners();
    }
}