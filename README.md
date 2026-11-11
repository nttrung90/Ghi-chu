# T-Note - Ứng dụng ghi chú đa nền tảng (Android, iOS, Windows & Firebase Sync)

Ứng dụng ghi chú hiện đại, tốc độ cao được thiết kế theo kiến trúc **Offline-First**, tự động đồng bộ hóa thời gian thực đa thiết bị thông qua **Google Firebase**.

---

## 🚀 Điểm nổi bật & Công nghệ

### 1. Tại sao chọn Flutter (ngôn ngữ Dart)?
- **Chung một mã nguồn (Single Codebase)**: Bạn chỉ cần viết code một lần duy nhất, mã nguồn này chạy trực tiếp trên **Android**, **iOS** và **Windows** mà không cần phải viết lại (rewrite) khi muốn port sang hệ điều hành khác.
- **Tích hợp Firebase chính chủ Google**: Cả Flutter và Firebase đều thuộc hệ sinh thái Google, bộ thư viện `FlutterFire` hỗ trợ đồng bộ dữ liệu ngoại tuyến (Offline cache) và luồng dữ liệu thời gian thực (Realtime Stream) cực kỳ mượt mà.
- **Giao diện thích ứng (Adaptive & Responsive UI)**:
  - Trên **Android / iOS**: Bố cục thẻ Staggered Grid trực quan, thao tác cảm ứng một chạm.
  - Trên **Windows Desktop**: Tự động mở rộng thanh Sidebar điều hướng bên trái, hỗ trợ đầy đủ phím tắt bàn phím máy tính (`Ctrl + N` tạo mới, `Ctrl + S` lưu nhanh, `Ctrl + F` tìm kiếm).

---

## 📱 Các tính năng chính của T-Note

1. **Ghi chú & Soạn thảo**:
   - Tiêu đề, nội dung không giới hạn độ dài.
   - Hỗ trợ **Danh sách việc cần làm (Checklists / To-Do)**: Tích chọn hoàn thành, tự gạch ngang thông minh.
   - Bảng màu thẻ phong phú (Pastel Palette): Đổi màu nền cho từng ghi chú để dễ phân loại.
   - Thẻ nhãn (**Tags / #hashtags**): Gắn nhãn linh hoạt để gom nhóm công việc.
2. **Quản lý & Sắp xếp**:
   - **Ghim ghi chú quan trọng (Pin)** luôn hiển thị ở đầu danh sách.
   - **Tìm kiếm tức thời (Instant Search)**: Lọc đồng thời theo tiêu đề, nội dung, đầu việc và nhãn.
   - **Thùng rác (Trash - Soft Delete)**: Khôi phục ghi chú đã xóa hoặc dọn sạch vĩnh viễn.
3. **Đồng bộ đám mây (Firebase Sync Engine)**:
   - **Offline-First**: Mở ứng dụng là dùng được ngay, ghi chú lưu vào bộ nhớ máy trong 0ms. Khi có kết nối Internet, dữ liệu tự động đẩy lên Firebase.
   - **Đồng bộ thời gian thực hai chiều (Cloud Firestore)**: Bất kỳ thay đổi nào trên Android sẽ lập tức xuất hiện trên iOS hoặc Windows Desktop trong tích tắc.
   - **Xác thực tài khoản (Firebase Auth)**: Hỗ trợ Đăng nhập Email/Password hoặc Dùng thử dạng Khách (Anonymous).

---

## 📂 Cấu trúc thư mục dự án

```
Ghi chu/
├── android/                   # Cấu hình dự án Android gốc (Manifest, Gradle)
├── firestore.rules            # Quy tắc bảo mật Cloud Firestore
├── pubspec.yaml               # Khai báo thư viện & cấu hình ứng dụng Flutter
├── setup_environment.ps1      # Script tự động kiểm tra/cài đặt môi trường
└── lib/
    ├── main.dart              # Điểm khởi chạy ứng dụng & nạp Provider
    ├── firebase_options.dart   # Cấu hình kết nối Firebase đa nền tảng
    ├── core/
    │   ├── constants/         # Bảng màu (AppColors), Chuỗi tiếng Việt (AppStrings)
    │   ├── theme/             # Cấu hình giao diện Sáng / Tối (Material 3)
    │   └── utils/             # Định dạng ngày giờ, Nhận diện Desktop/Mobile
    ├── models/
    │   ├── note_model.dart    # Model dữ liệu ghi chú
    │   └── checklist_item.dart# Model việc cần làm
    ├── services/
    │   ├── local_storage_service.dart # Lưu trữ cục bộ Offline-First
    │   ├── firebase_auth_service.dart # Đăng nhập, xác thực Firebase
    │   └── firestore_sync_service.dart# Luồng đồng bộ Firestore
    ├── providers/
    │   ├── notes_provider.dart # Quản lý trạng thái ghi chú, tìm kiếm, đồng bộ
    │   ├── auth_provider.dart  # Quản lý tài khoản
    │   └── theme_provider.dart # Quản lý Dark/Light mode
    └── views/
        ├── home/              # Màn hình chính (Responsive Grid & Sidebar)
        ├── editor/            # Màn hình soạn thảo ghi chú & checklist
        ├── trash/             # Thùng rác & khôi phục
        ├── settings/          # Cài đặt giao diện & tài khoản
        └── auth/              # Hộp thoại đăng nhập
```

---

## 🛠️ Hướng dẫn cài đặt & Chạy ứng dụng

### Bước 1: Cài đặt Flutter SDK (Nếu máy chưa có)
Chạy script PowerShell đã tạo sẵn:
```powershell
.\setup_environment.ps1
```
Hoặc tải trực tiếp từ trang chủ Flutter: [https://docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows).

### Bước 2: Tải các gói thư viện
Trong thư mục dự án, chạy lệnh:
```bash
flutter pub get
```

### Bước 3: Kết nối dự án Firebase của bạn
1. Truy cập [Firebase Console](https://console.firebase.google.com/) và tạo một dự án mới (ví dụ đặt tên: `note-ntt-app`).
2. Bật dịch vụ **Authentication** (chọn phương thức Email/Password và Anonymous).
3. Bật **Cloud Firestore Database** (chọn chế độ Test mode hoặc dán nội dung file `firestore.rules` vào tab Rules).
4. Cài đặt FlutterFire CLI và liên kết dự án:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   *Lệnh này sẽ tự động đăng ký App trên Android, iOS, Windows/Web và tạo file `lib/firebase_options.dart` chuẩn xác cho bạn.*

### Bước 4: Chạy ứng dụng

- **Chạy trên điện thoại / giả lập Android**:
  ```bash
  flutter run -d android
  ```
- **Chạy trực tiếp trên máy tính Windows (Desktop Native)**:
  ```bash
  flutter run -d windows
  ```
- **Port sang iOS**:
  Chỉ cần mở cùng thư mục này trên máy Mac (hoặc qua máy ảo macOS):
  ```bash
  flutter run -d ios
  ```

---

## 🔒 Quy tắc bảo mật Firestore (`firestore.rules`)
Toàn bộ dữ liệu ghi chú được bảo mật tuyệt đối: mỗi người dùng chỉ có quyền đọc/ghi trên bản ghi mang đúng `userId` của họ:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/notes/{noteId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
