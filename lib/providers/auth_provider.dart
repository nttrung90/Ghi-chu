import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/firebase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Lấy thông tin tài khoản Google hiện tại
  GoogleSignInAccount? get googleUser => _authService.currentGoogleUser;
  GoogleSignIn get googleSignIn => _authService.googleSignIn;
  bool get isGoogleSignedIn =>
      _authService.currentGoogleUser != null ||
      (_user != null && _user!.providerData.any((p) => p.providerId == 'google.com'));

  AuthProvider() {
    _init();
  }

  void _init() {
    // Lắng nghe thay đổi đăng nhập từ Firebase
    try {
      _authService.authStateChanges.listen((User? user) {
        _user = user;
        notifyListeners();
      });
      // Khôi phục phiên Google nếu có
      _authService.signInGoogleSilently().then((_) {
        notifyListeners();
      });
    } catch (_) {
      // Firebase chưa cấu hình options
    }
  }

  /// Đăng nhập bằng tài khoản Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final cred = await _authService.signInWithGoogle();
      if (cred == null) {
        _errorMessage = null;
        return false;
      }
      _user = cred.user;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Kết nối tài khoản Google để sử dụng Google Drive Backup
  Future<GoogleSignInAccount?> connectGoogleAccount() async {
    _setLoading(true);
    try {
      final account = await _authService.connectGoogleAccount();
      _errorMessage = null;
      notifyListeners();
      return account;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Hủy kết nối tài khoản Google
  Future<void> disconnectGoogleAccount() async {
    await _authService.signOutGoogle();
    notifyListeners();
  }

  Future<void> signInAnonymously() async {
    _setLoading(true);
    try {
      final credential = await _authService.signInAnonymously();
      _user = credential?.user;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      final cred = await _authService.signInWithEmail(email, password);
      _user = cred.user;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      final cred = await _authService.signUpWithEmail(email, password);
      _user = cred.user;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
