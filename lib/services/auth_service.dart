// lib/services/auth_service.dart
import 'dart:convert';
// import 'dart:io'; // KALDIRILDI: Dosya sistemi web'de çalışmaz
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:collection/collection.dart'; 
import 'package:uuid/uuid.dart'; // YENİ EKLENDİ
import '../models/models.dart';

class AuthService {
  // static const String _usersFileName = 'users.json'; // KALDIRILDI
  static const _usersKey = 'app_users_data'; // YENİ: SharedPreferences için anahtar
  static const _currentUserIdKey = 'currentUserId';
  
  // late Directory _appDocDir; // KALDIRILDI
  List<User> _users = [];
  final Uuid _uuid = const Uuid(); // YENİ
  
  Future<void> init() async {
    // _appDocDir = await getApplicationDocumentsDirectory(); // KALDIRILDI
    await _loadUsers(); 
    await _loadCurrentUser(); 
  }

  // File get _usersFile => File('${_appDocDir.path}/$_usersFileName'); // KALDIRILDI

  // GÜNCELLENDİ: Kullanıcıları SharedPreferences'tan yükler
  Future<void> _loadUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contents = prefs.getString(_usersKey);
      
      if (contents != null && contents.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(contents);
        _users = jsonList.map((json) => User.fromJson(json)).toList();
      } else {
        _users = [];
      }
    } catch (e) {
      print("AuthService HATA: Kullanıcı verileri yüklenemedi: $e");
      _users = [];
    }
  }

  // GÜNCELLENDİ: Kullanıcıları SharedPreferences'a kaydeder
  Future<void> _saveUsers() async {
    final jsonList = _users.map((user) => {
      'username': user.username,
      'passwordHash': user.passwordHash,
      'userId': user.userId, 
    }).toList();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(jsonList));
  }

  Future<User> signUp(String username, String password) async {
    if (_users.any((user) => user.username.toLowerCase() == username.toLowerCase())) {
      throw Exception("Bu kullanıcı adı zaten kayıtlı.");
    }
    
    // GÜNCELLENDİ: ID üretimi Uuid ile yapılıyor
    final newUser = User(username: username, passwordHash: password, userId: _uuid.v4()); 
    _users.add(newUser);
    await _saveUsers(); 
    return newUser;
  }

  Future<User?> signIn(String username, String password) async {
    final user = _users.firstWhereOrNull(
      (user) => user.username.toLowerCase() == username.toLowerCase(),
    );

    if (user == null) {
      throw Exception("Kullanıcı adı bulunamadı.");
    }

    if (user.passwordHash == password) {
      await _saveCurrentUser(user.userId);
      _currentUser = user;
      return user;
    } else {
      throw Exception("Hatalı şifre.");
    }
  }

  User? _currentUser;
  User? get currentUser => _currentUser;
  
  void setCurrentUser(User user) {
    _currentUser = user;
  }
  
  void signOut() async {
    _currentUser = null;
    await _saveCurrentUser(null); 
  }
  
  Future<void> _saveCurrentUser(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      await prefs.setString(_currentUserIdKey, userId);
    } else {
      await prefs.remove(_currentUserIdKey);
    }
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_currentUserIdKey);

    if (userId != null) {
      final user = _users.firstWhereOrNull((u) => u.userId == userId);
      
      if (user != null) {
        _currentUser = user;
        print("AuthService: Önceki kullanıcı '${user.username}' otomatik olarak yüklendi.");
      } else {
        await prefs.remove(_currentUserIdKey); 
      }
    }
  }
  
  // ÖNEMLİ METOT: Kullanıcı adına göre güvenli bir klasör adı oluşturur (Şimdi bu sadece key/etiket oluşturur)
  static String createSafeFolderName(String username) {
    // Geçersiz dosya adı karakterlerini kaldırır ve klasör adını oluşturur
    // Sadece etiket olarak kullanılacak
    return 'Diyetisyen_${username.replaceAll(RegExp(r'[\\/:*?"<>|.]'), '_')}';
  }
}