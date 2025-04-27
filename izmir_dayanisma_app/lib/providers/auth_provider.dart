// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../services/local_db_service.dart';

class AuthProvider extends ChangeNotifier {
  final LocalDbService _dbService;
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _userName;
  String _userRole = 'user';

  AuthProvider(this._dbService);

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  bool get isAdmin => _userRole == 'admin';

  Future<bool> login(String email, String password) async {
    final result = await _dbService.db.rawQuery(
      'SELECT name, email, role FROM users WHERE email = ? AND password = ?',
      [email, password],
    );
    if (result.isNotEmpty) {
      _isAuthenticated = true;
      _userName = result.first['name'] as String?;
      _userEmail = result.first['email'] as String?;
      _userRole = result.first['role'] as String? ?? 'user';
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      await _dbService.db.insert('users', {
        'name': name,
        'email': email,
        'password': password,
        'role': 'user',
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    _userEmail = null;
    _userName = null;
    _userRole = 'user';
    notifyListeners();
  }
}
