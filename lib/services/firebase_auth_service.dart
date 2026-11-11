import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Quản lý xác thực người dùng qua Firebase Authentication & Google Sign-In
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  FirebaseAuth get auth => _auth;
  GoogleSignIn get googleSignIn => _googleSignIn;

  // Lấy người dùng hiện tại từ Firebase
  User? get currentUser => _auth.currentUser;

  // Lấy tài khoản Google hiện tại
  GoogleSignInAccount? get currentGoogleUser => _googleSignIn.currentUser;

  // Stream theo dõi thay đổi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Thử đăng nhập Google âm thầm (Silent Sign-In) nếu đã đăng nhập trước đó
  Future<GoogleSignInAccount?> signInGoogleSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (_) {
      return null;
    }
  }

  /// Đăng nhập bằng Google và đồng bộ tài khoản vào Firebase
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Người dùng hủy hộp thoại đăng nhập
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  /// Chỉ kết nối tài khoản Google để sao lưu Drive (không bắt buộc đổi tài khoản Firebase)
  Future<GoogleSignInAccount?> connectGoogleAccount() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      rethrow;
    }
  }

  /// Đăng xuất tài khoản Google
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

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

  /// Đăng xuất khỏi thiết bị (bao gồm Firebase và Google)
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
