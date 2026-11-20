# Kiểm tra cập nhật ứng dụng

T-Note dùng **Google Play In-App Updates API** (thư viện `in_app_update`) để kiểm tra và cập nhật phiên bản mới.

## Cách hoạt động

- Khi mở ứng dụng, T-Note tự kiểm tra một lần xem Google Play có bản cập nhật mới hay không.
- Nếu có bản mới, ứng dụng hiển thị hộp thoại thông báo với hai lựa chọn:
  - **Để sau**: ghi nhớ mã phiên bản đã bỏ qua, không hiển thị lại hộp thoại cho cùng phiên bản đó.
  - **Cập nhật ngay**: chuyển sang luồng cập nhật của Google Play (toàn màn hình hoặc tải nền tùy chính sách của Play).
- Người dùng cũng có thể kiểm tra thủ công tại **Cài đặt → Kiểm tra cập nhật** (ngay trên mục "Thông tin ứng dụng").

## Điều kiện hoạt động

Google Play In-App Updates chỉ hoạt động khi ứng dụng được cài đặt từ Google Play:

- Kênh thử nghiệm nội bộ (Internal testing).
- Kênh thử nghiệm đóng/mở (Closed/Open testing).
- Bản phát hành chính thức (Production).

APK cài trực tiếp bằng `adb install` hoặc tải từ nguồn ngoài sẽ không kiểm tra được; ứng dụng sẽ hiển thị thông báo hướng dẫn thay vì báo lỗi kỹ thuật.

## Quy trình phát hành bản mới

1. Cập nhật số phiên bản trong `pubspec.yaml`, ví dụ:

   ```yaml
   version: 0.2.0+2
   ```

   Trong đó `0.2.0` là `versionName`, `2` là `versionCode` (số này phải tăng dần).

2. Build App Bundle để tải lên Google Play:

   ```bash
   flutter build appbundle --release
   ```

3. Tải AAB lên Play Console và phát hành cho kênh mong muốn.

4. Khi người dùng mở ứng dụng, Google Play sẽ trả về thông tin bản cập nhật mới và T-Note hiển thị hộp thoại thông báo.

## Mã nguồn liên quan

- `lib/services/app_update_service.dart`: gọi Google Play In-App Updates API.
- `lib/providers/app_update_provider.dart`: quản lý trạng thái kiểm tra/cập nhật.
- `lib/views/settings/widgets/app_update_dialog.dart`: hộp thoại thông báo bản cập nhật.
- `lib/views/settings/settings_screen.dart`: mục "Kiểm tra cập nhật".
- `lib/views/home/home_screen.dart`: tự kiểm tra khi ứng dụng khởi động.
