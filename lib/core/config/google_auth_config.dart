/// Cấu hình OAuth dùng cho Google Sign-In.
///
/// Web client ID lấy tại Google Cloud Console → APIs & Services → Credentials
/// → OAuth 2.0 Client IDs → loại "Web application".
///
/// Truyền giá trị này khi build/run, ví dụ:
/// flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
///
/// Web client ID không phải là secret nên có thể đưa vào cấu hình build.
class GoogleAuthConfig {
  const GoogleAuthConfig._();

  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static bool get hasWebClientId => webClientId.trim().isNotEmpty;
}
