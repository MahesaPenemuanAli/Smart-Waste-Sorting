/// Smart Waste Sorting — Auth Provider
/// Manajemen autentikasi lokal: register, login, logout, session.
/// Password di-hash dengan SHA-256 + salt.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/database_service.dart';

/// Status autentikasi.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Provider autentikasi lokal.
class AuthProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  static const String _prefUserId = 'logged_in_user_id';

  /// Hash password dengan SHA-256 + email sebagai salt.
  String _hashPassword(String password, String email) {
    final bytes = utf8.encode('$email:$password:smart_waste_2026');
    return sha256.convert(bytes).toString();
  }

  /// Cek session saat app launch. Panggil di splash screen.
  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(_prefUserId);

      if (userId != null) {
        final user = await _db.getUserById(userId);
        if (user != null) {
          _currentUser = user;
          _status = AuthStatus.authenticated;
          notifyListeners();
          return;
        }
      }

      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (_) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Register user baru.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _errorMessage = null;

    try {
      // Cek apakah email sudah terdaftar
      final existing = await _db.getUserByEmail(email.trim().toLowerCase());
      if (existing != null) {
        _errorMessage = 'Email sudah terdaftar. Silakan login.';
        notifyListeners();
        return false;
      }

      // Hash password
      final hash = _hashPassword(password, email.trim().toLowerCase());

      // Buat user baru
      final user = AppUser(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        passwordHash: hash,
      );

      final id = await _db.insertUser(user);

      // Auto-login setelah register
      _currentUser = AppUser(
        id: id,
        name: user.name,
        email: user.email,
        passwordHash: user.passwordHash,
        createdAt: user.createdAt,
      );
      _status = AuthStatus.authenticated;

      // Simpan session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefUserId, id);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mendaftar: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Login user.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;

    try {
      final user = await _db.getUserByEmail(email.trim().toLowerCase());
      if (user == null) {
        _errorMessage = 'Email tidak ditemukan.';
        notifyListeners();
        return false;
      }

      // Verifikasi password
      final hash = _hashPassword(password, email.trim().toLowerCase());
      if (hash != user.passwordHash) {
        _errorMessage = 'Password salah.';
        notifyListeners();
        return false;
      }

      // Berhasil login
      _currentUser = user;
      _status = AuthStatus.authenticated;

      // Simpan session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefUserId, user.id!);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal login: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Logout.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefUserId);

    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
