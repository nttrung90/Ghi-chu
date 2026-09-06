import 'package:firebase_auth/firebase_auth.dart';

/// Quản lý xác thực người dùng qua Firebase Authentication
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy người dùng hiện tại
  User? get currentUser => _auth.currentUser;

  // Stream theo dõi thay đổi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Đăng nhập chế độ Khách (Anonymous)
  /// Cho phép người dùng ghi chú ngay lập tức mà không cần tài khoản
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      // Có thể Firebase chưa được cấu hình hoặc lỗi mạng
      return null;
    }
  }

  /// Đăng nhập bằng Email và Mật khẩu
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Đăng ký tài khoản mới bằng Email và Mật khẩu
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Đăng xuất khỏi thiết bị
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
