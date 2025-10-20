// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleUser {
  final String email;
  final String password; // disimpan polos: hanya demo lokal tanpa DB
  final String displayName;
  final String? phone;
  final String? avatar; // URL atau path ke avatar
  final DateTime joinDate;
  
  const SimpleUser({
    required this.email,
    required this.password,
    required this.displayName,
    this.phone,
    this.avatar,
    required this.joinDate,
  });

  SimpleUser copyWith({
    String? email,
    String? password,
    String? displayName,
    String? phone,
    String? avatar,
    DateTime? joinDate,
  }) {
    return SimpleUser(
      email: email ?? this.email,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      joinDate: joinDate ?? this.joinDate,
    );
  }
}

class AuthService extends ChangeNotifier {
  // Seed user demo (opsional)
  final List<SimpleUser> _users = [
    SimpleUser(
      email: 'demo@demo.com',
      password: 'demo123',
      displayName: 'User Demo',
      phone: '+62 812-3456-7890',
      joinDate: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  String? _currentUserEmail;

  // === Getters ===
  bool get isLoggedIn => _currentUserEmail != null;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName {
    final u = _getCurrentUser();
    return u?.displayName;
  }
  
  SimpleUser? get currentUser => _getCurrentUser();
  
  List<SimpleUser> get allUsers => List.unmodifiable(_users);
  
  SimpleUser? _getCurrentUser() {
    if (_currentUserEmail == null) return null;
    return _users
        .where((e) => e.email == _currentUserEmail)
        .cast<SimpleUser?>()
        .firstOrNull;
  }

  // === Persistensi sederhana (SharedPreferences) ===
  static const _kLoggedKey = 'logged_in_user';

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserEmail = prefs.getString(_kLoggedKey);
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    // Validasi input
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw Exception('Email dan password harus diisi');
    }
    
    // Validasi format email
    if (!_isValidEmail(email)) {
      throw Exception('Format email tidak valid');
    }
    
    // Cari user dengan email yang sama (case insensitive)
    final user = _users.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => throw Exception('Email tidak terdaftar'),
    );
    
    // Validasi password
    if (user.password != password) {
      throw Exception('Password salah');
    }
    
    final prefs = await SharedPreferences.getInstance();
    _currentUserEmail = user.email;
    await prefs.setString(_kLoggedKey, user.email);
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // Validasi input
    if (email.trim().isEmpty || password.trim().isEmpty || displayName.trim().isEmpty) {
      throw Exception('Semua field harus diisi');
    }
    
    // Validasi format email
    if (!_isValidEmail(email)) {
      throw Exception('Format email tidak valid');
    }
    
    // Validasi password
    if (!_isValidPassword(password)) {
      throw Exception('Password minimal 6 karakter dan harus mengandung huruf dan angka');
    }
    
    // Validasi nama
    if (displayName.trim().length < 2) {
      throw Exception('Nama minimal 2 karakter');
    }
    
    // Cek email sudah terdaftar
    final exist = _users.any(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    if (exist) {
      throw Exception('Email sudah terdaftar');
    }
    
    _users.add(
      SimpleUser(
        email: email.trim(), 
        password: password, 
        displayName: displayName.trim(),
        joinDate: DateTime.now(),
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    _currentUserEmail = email.trim();
    await prefs.setString(_kLoggedKey, email.trim());
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedKey);
    _currentUserEmail = null;
    notifyListeners();
  }

  // === Profile Management ===
  Future<void> updateProfile({
    String? displayName,
    String? phone,
    String? avatar,
  }) async {
    if (_currentUserEmail == null) {
      throw Exception('User tidak login');
    }

    final userIndex = _users.indexWhere((u) => u.email == _currentUserEmail);
    if (userIndex == -1) {
      throw Exception('User tidak ditemukan');
    }

    final currentUser = _users[userIndex];
    _users[userIndex] = currentUser.copyWith(
      displayName: displayName?.trim(),
      phone: phone?.trim(),
      avatar: avatar,
    );

    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUserEmail == null) {
      throw Exception('User tidak login');
    }

    final userIndex = _users.indexWhere((u) => u.email == _currentUserEmail);
    if (userIndex == -1) {
      throw Exception('User tidak ditemukan');
    }

    final currentUser = _users[userIndex];
    
    // Validasi password lama
    if (currentUser.password != currentPassword) {
      throw Exception('Password lama salah');
    }

    // Validasi password baru
    if (!_isValidPassword(newPassword)) {
      throw Exception('Password baru minimal 6 karakter dan harus mengandung huruf dan angka');
    }

    _users[userIndex] = currentUser.copyWith(password: newPassword);
    notifyListeners();
  }

  Future<void> deleteAccount({required String password}) async {
    if (_currentUserEmail == null) {
      throw Exception('User tidak login');
    }

    final userIndex = _users.indexWhere((u) => u.email == _currentUserEmail);
    if (userIndex == -1) {
      throw Exception('User tidak ditemukan');
    }

    final currentUser = _users[userIndex];
    
    // Validasi password
    if (currentUser.password != password) {
      throw Exception('Password salah');
    }

    // Hapus user
    _users.removeAt(userIndex);
    
    // Logout
    await logout();
  }

  Future<void> resetPassword(String email) async {
    // Validasi input
    if (email.trim().isEmpty) {
      throw Exception('Email harus diisi');
    }
    
    // Validasi format email
    if (!_isValidEmail(email)) {
      throw Exception('Format email tidak valid');
    }
    
    // Cek email terdaftar
    final user = _users.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => throw Exception('Email tidak terdaftar'),
    );
    
    // Simulasi delay untuk mengirim email
    await Future.delayed(const Duration(seconds: 2));
    
    // Dalam implementasi nyata, di sini akan mengirim email reset password
    // Untuk demo, kita hanya menampilkan pesan sukses
    print('Reset password link sent to: ${user.email}');
  }

  // Helper methods untuk validasi
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    if (password.length < 6) return false;
    // Minimal harus ada huruf dan angka
    return RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(password);
  }
}

// util kecil untuk firstOrNull (biar tak perlu package tambahan)
extension _IterableX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
