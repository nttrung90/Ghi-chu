# Chính sách quyền riêng tư của T-Note

**Cập nhật lần cuối:** 11/11/2026  
**Có hiệu lực từ:** 11/11/2026

T-Note là ứng dụng ghi chú đa nền tảng (Android, iOS và Windows) hoạt động theo kiến trúc ưu tiên ngoại tuyến (Offline-First), có thể đồng bộ ghi chú qua Google Firebase và sao lưu vào Google Drive cá nhân của người dùng.

Chính sách này giải thích chúng tôi thu thập những dữ liệu gì, vì sao, lưu trữ ở đâu, chia sẻ với ai và bạn có những quyền gì. Bằng việc tải, cài đặt hoặc sử dụng T-Note, bạn xác nhận rằng bạn đã đọc và hiểu chính sách này.

> **Tóm tắt nhanh**
> - Ghi chú của bạn được lưu trên thiết bị và chỉ được đồng bộ lên Firebase khi bạn đăng nhập.
> - Bạn có thể chủ động sao lưu ghi chú vào thư mục riêng trong Google Drive của chính mình.
> - Ứng dụng **không bán**, **không cho thuê**, **không sử dụng dữ liệu để quảng cáo** và **không có SDK quảng cáo**.
> - Ứng dụng **không yêu cầu** quyền truy cập vị trí, danh bạ, camera, micro, tin nhắn hay toàn bộ bộ nhớ thiết bị.
> - Bạn có thể xóa ghi chú, xóa bản sao lưu và yêu cầu xóa tài khoản bất cứ lúc nào.

---

## 1. Đơn vị chịu trách nhiệm

T-Note ("ứng dụng") do nhà phát triển T-Note ("chúng tôi") phát triển và vận hành.

- **Tên ứng dụng:** T-Note
- **Mã ứng dụng (Android):** `com.ntt.notentt`
- **Email liên hệ về quyền riêng tư:** [firstntt90@gmail.com](mailto:firstntt90@gmail.com)

Chúng tôi là đơn vị kiểm soát dữ liệu cá nhân đối với dữ liệu được mô tả trong chính sách này, trừ trường hợp Google xử lý dữ liệu với tư cách là đơn vị cung cấp dịch vụ hạ tầng hoặc đơn vị kiểm soát độc lập theo chính sách riêng của Google.

---

## 2. Dữ liệu chúng tôi thu thập

### 2.1. Nội dung ghi chú do bạn tạo

Khi bạn sử dụng T-Note, ứng dụng xử lý các dữ liệu sau để cung cấp tính năng ghi chú:

- Tiêu đề và nội dung ghi chú.
- Danh sách việc cần làm (checklist), bao gồm nội dung công việc và trạng thái hoàn thành.
- Nhãn (tag/hashtag) bạn gắn cho ghi chú.
- Màu nền, trạng thái ghim, trạng thái lưu trữ và trạng thái trong thùng rác.
- Thời gian tạo và thời gian cập nhật ghi chú.

Nội dung ghi chú do bạn tự nhập. Bạn không bắt buộc phải cung cấp bất kỳ thông tin nào, nhưng nếu không nhập nội dung thì ứng dụng không thể thực hiện chức năng ghi chú.

### 2.2. Dữ liệu tài khoản

Khi bạn đăng nhập, Firebase Authentication có thể xử lý:

- Địa chỉ email.
- Tên hiển thị và URL ảnh đại diện (nếu bạn đăng nhập bằng Google).
- Mã định danh người dùng (UID) do Firebase tạo.
- Phương thức đăng nhập (Google, email/mật khẩu hoặc Khách/Anonymous).

Nếu bạn dùng chế độ Khách, Firebase tạo một UID ẩn danh và không yêu cầu email, tên hay ảnh đại diện. Nếu bạn đăng ký bằng email/mật khẩu, mật khẩu do Firebase Authentication xử lý; ứng dụng không lưu, không hiển thị và không có quyền đọc mật khẩu của bạn.

### 2.3. Dữ liệu đồng bộ và sao lưu

- **Đồng bộ Firebase:** Khi bạn đăng nhập, ghi chú được lưu trong Cloud Firestore tại đường dẫn `users/{UID}/notes/{noteId}`. Quy tắc bảo mật của Firestore chỉ cho phép chính chủ tài khoản đọc và ghi dữ liệu của mình.
- **Sao lưu Google Drive:** Khi bạn chủ động bấm sao lưu và cấp quyền, ứng dụng tạo tệp JSON chứa toàn bộ ghi chú và một số thông tin mô tả (tên tệp, thời gian tạo, số lượng ghi chú) trong thư mục `T-Note Backups` trên Google Drive của bạn.
- **Phạm vi quyền Drive:** Ứng dụng chỉ yêu cầu phạm vi `https://www.googleapis.com/auth/drive.file`. Phạm vi này chỉ cho phép ứng dụng tạo, đọc, sửa và xóa các tệp do chính ứng dụng tạo ra hoặc bạn chủ động mở bằng ứng dụng. T-Note **không thể** truy cập các tệp khác trong Google Drive của bạn.

### 2.4. Dữ liệu lưu cục bộ trên thiết bị

Ứng dụng lưu trong bộ nhớ riêng của ứng dụng (SharedPreferences):

- Danh sách ghi chú dưới dạng JSON, để bạn sử dụng ngay khi không có mạng.
- Danh sách mã ghi chú đang chờ đồng bộ lên Firebase.
- Tùy chọn giao diện Sáng/Tối/Hệ thống.

Dữ liệu cục bộ nằm trong vùng lưu trữ được hệ điều hành cách ly cho ứng dụng. Ứng dụng không yêu cầu quyền truy cập toàn bộ bộ nhớ thiết bị.

### 2.5. Dữ liệu kỹ thuật do dịch vụ của Google xử lý

Để vận hành dịch vụ, Google (Firebase Authentication, Cloud Firestore, Google Sign-In, Google Drive API và Google Fonts) có thể xử lý một số dữ liệu kỹ thuật như:

- Địa chỉ IP.
- Loại thiết bị, hệ điều hành và phiên bản ứng dụng.
- Mã thông báo xác thực (token) và thông tin phiên đăng nhập.
- Thời điểm truy cập, nhật ký lỗi và sự kiện bảo mật.

Ứng dụng có thể tải phông chữ Inter từ máy chủ Google Fonts khi chạy; yêu cầu này có thể gửi địa chỉ IP và thông tin thiết bị tối thiểu tới Google. Chúng tôi không dùng các dữ liệu kỹ thuật này để quảng cáo hoặc bán cho bên thứ ba.

### 2.6. Những dữ liệu chúng tôi KHÔNG thu thập

T-Note không yêu cầu và không cố ý thu thập:

- Vị trí chính xác hoặc vị trí gần đúng.
- Danh bạ, nhật ký cuộc gọi, tin nhắn SMS.
- Camera, micro, ảnh hoặc tệp trong bộ nhớ thiết bị.
- Dữ liệu sức khỏe, dữ liệu sinh trắc học.
- Mã quảng cáo (Advertising ID) hoặc dữ liệu dùng để theo dõi bạn giữa các ứng dụng.
- Thông tin thanh toán.

Ứng dụng không tích hợp SDK quảng cáo, không hiển thị quảng cáo và không bán dữ liệu cá nhân.

---

## 3. Mục đích sử dụng và cơ sở pháp lý

Chúng tôi sử dụng dữ liệu cho các mục đích sau:

| Mục đích | Dữ liệu sử dụng | Cơ sở pháp lý |
|---|---|---|
| Tạo, chỉnh sửa, tìm kiếm, ghim, gắn nhãn và quản lý ghi chú | Nội dung ghi chú, dữ liệu cục bộ | Thực hiện chức năng bạn yêu cầu |
| Đồng bộ ghi chú giữa các thiết bị | Nội dung ghi chú, UID, dữ liệu tài khoản | Sự đồng ý của bạn khi đăng nhập |
| Sao lưu và khôi phục ghi chú qua Google Drive | Nội dung ghi chú, dữ liệu tài khoản Google, quyền `drive.file` | Sự đồng ý của bạn khi cấp quyền OAuth |
| Xác thực và bảo vệ tài khoản | Email, UID, token, dữ liệu kỹ thuật | Thực hiện hợp đồng và lợi ích hợp pháp về bảo mật |
| Phát hiện, ngăn chặn và xử lý sự cố kỹ thuật | Nhật ký kỹ thuật do Google cung cấp | Lợi ích hợp pháp về vận hành và bảo mật |
| Tuân thủ nghĩa vụ pháp lý | Dữ liệu liên quan đến yêu cầu của cơ quan có thẩm quyền | Nghĩa vụ pháp lý |

Chúng tôi **không** sử dụng dữ liệu của bạn cho mục đích tiếp thị, bán hàng, quảng cáo hoặc huấn luyện mô hình trí tuệ nhân tạo.

---

## 4. Lưu trữ và bảo vệ dữ liệu

### 4.1. Nơi lưu trữ

- **Trên thiết bị:** ghi chú và tùy chọn giao diện được lưu cục bộ để ứng dụng hoạt động khi không có mạng.
- **Cloud Firestore:** khi đăng nhập, dữ liệu được lưu trên hạ tầng Google Cloud theo khu vực do cấu hình dự án Firebase quyết định.
- **Google Drive:** bản sao lưu được lưu trong chính tài khoản Google Drive của bạn; chúng tôi không có quyền truy cập vào Drive của bạn ngoài các tệp do ứng dụng tạo.

### 4.2. Biện pháp bảo vệ

- Dữ liệu truyền giữa ứng dụng và Google được bảo vệ bằng kết nối mã hóa TLS do các SDK chính thức của Google cung cấp.
- Firebase Authentication quản lý phiên đăng nhập và token.
- Quy tắc bảo mật Cloud Firestore giới hạn mỗi người dùng chỉ được đọc/ghi dữ liệu của chính mình:

```javascript
match /users/{userId}/notes/{noteId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

- Google Drive chỉ được truy cập qua phạm vi `drive.file`, không phải toàn bộ Drive.
- Dữ liệu cục bộ nằm trong vùng lưu trữ riêng của ứng dụng do hệ điều hành bảo vệ.

**Về mã hóa:** Ứng dụng không mã hóa riêng nội dung ghi chú ở cấp ứng dụng. Dữ liệu cục bộ dựa vào cơ chế cách ly và bảo vệ của hệ điều hành; dữ liệu trên Firebase và tệp sao lưu trên Google Drive được Google mã hóa khi truyền và khi lưu trữ theo hạ tầng của Google. Tệp sao lưu JSON không được ứng dụng mã hóa thêm, nên bạn cần bảo vệ tài khoản Google của mình.

Tuy nhiên, không có phương thức bảo mật nào an toàn tuyệt đối. Bạn nên khóa thiết bị bằng mã PIN/mật khẩu hoặc sinh trắc học, bảo vệ tài khoản Google và không chia sẻ thiết bị với người không tin cậy. Nếu ghi chú chứa thông tin nhạy cảm của người khác, bạn cần có sự đồng ý hoặc cơ sở pháp lý phù hợp trước khi nhập.

---

## 5. Chia sẻ dữ liệu

Chúng tôi không bán, không cho thuê và không trao đổi dữ liệu cá nhân của bạn. Dữ liệu chỉ được chia sẻ trong các trường hợp sau:

1. **Với Google/Firebase:** với tư cách nhà cung cấp hạ tầng xác thực, cơ sở dữ liệu đám mây, đăng nhập Google, Google Drive và Google Fonts. Google xử lý dữ liệu theo [Chính sách quyền riêng tư của Google](https://policies.google.com/privacy) và [Điều khoản dịch vụ của Google](https://policies.google.com/terms).
2. **Theo yêu cầu pháp luật:** khi có yêu cầu hợp lệ từ cơ quan có thẩm quyền, hoặc khi cần thiết để bảo vệ quyền, tài sản, sự an toàn của người dùng, chúng tôi hoặc cộng đồng.
3. **Trong trường hợp tái cấu trúc doanh nghiệp:** nếu ứng dụng được chuyển giao, sáp nhập hoặc bán, dữ liệu có thể được chuyển giao kèm theo, với điều kiện bên nhận tiếp tục tuân thủ chính sách này hoặc chính sách tương đương.
4. **Với sự đồng ý của bạn:** trong các trường hợp khác, chúng tôi sẽ xin phép bạn trước.

### Cam kết Sử dụng Hạn chế đối với Google API

Việc sử dụng và chuyển giao thông tin nhận được từ Google API của T-Note tuân thủ [Chính sách Dữ liệu Người dùng của Dịch vụ API Google](https://developers.google.com/terms/api-services-user-data-policy), bao gồm các yêu cầu Sử dụng Hạn chế (Limited Use). Cụ thể:

- Dữ liệu Google chỉ được dùng để cung cấp hoặc cải thiện các tính năng hiển thị rõ ràng cho người dùng.
- Dữ liệu Google không được bán cho bên thứ ba.
- Dữ liệu Google không được dùng cho quảng cáo, tiếp thị hoặc chấm điểm tín dụng.
- Con người không đọc dữ liệu Google của bạn, trừ khi bạn cấp quyền rõ ràng cho một trường hợp cụ thể, cần thiết vì lý do bảo mật hoặc pháp lý, hoặc để xử lý sự cố kỹ thuật.

---

## 6. Thời gian lưu trữ

| Loại dữ liệu | Thời gian lưu trữ |
|---|---|
| Ghi chú trên thiết bị | Cho đến khi bạn xóa ghi chú, xóa dữ liệu ứng dụng hoặc gỡ cài đặt ứng dụng |
| Ghi chú trong thùng rác | Cho đến khi bạn xóa vĩnh viễn hoặc dọn sạch thùng rác |
| Ghi chú trên Cloud Firestore | Cho đến khi bạn xóa ghi chú hoặc tài khoản; sau đó được xóa khỏi hệ thống đang hoạt động trong vòng tối đa 30 ngày, trừ khi pháp luật yêu cầu lưu lâu hơn |
| Bản sao lưu trên Google Drive | Cho đến khi bạn xóa bản sao lưu hoặc xóa tệp trong Drive; chúng tôi không tự động xóa |
| Thông tin tài khoản Firebase | Cho đến khi bạn yêu cầu xóa tài khoản; được xử lý trong vòng tối đa 30 ngày, trừ khi pháp luật yêu cầu khác |
| Nhật ký kỹ thuật của Google | Theo chính sách lưu trữ của Google/Firebase |

**Lưu ý:** Gỡ cài đặt ứng dụng hoặc xóa dữ liệu ứng dụng chỉ xóa dữ liệu cục bộ. Ghi chú đã đồng bộ vẫn có thể còn trên Cloud Firestore và sẽ được tải lại khi bạn đăng nhập lại. Để xóa hoàn toàn, bạn cần xóa ghi chú khi đang đăng nhập hoặc yêu cầu xóa tài khoản.

---

## 7. Xóa dữ liệu và tài khoản

### 7.1. Xóa ghi chú

- Chuyển ghi chú vào thùng rác trong ứng dụng.
- Mở Thùng rác và chọn xóa vĩnh viễn từng ghi chú hoặc dọn sạch toàn bộ thùng rác.
- Khi đang đăng nhập, thao tác xóa sẽ được đồng bộ lên Cloud Firestore.

### 7.2. Xóa bản sao lưu Google Drive

- Mở **Cài đặt → Sao lưu lên Google Drive**.
- Chọn bản sao lưu cần xóa và xác nhận xóa.
- Bạn cũng có thể xóa thư mục `T-Note Backups` trực tiếp trong Google Drive.

### 7.3. Xóa tài khoản

Hiện tại, để xóa toàn bộ tài khoản và dữ liệu liên quan, vui lòng gửi email đến [firstntt90@gmail.com](mailto:firstntt90@gmail.com) với tiêu đề **"Yêu cầu xóa tài khoản T-Note"**, từ địa chỉ email bạn đã dùng để đăng ký (nếu có). Bạn nên ghi kèm UID hiển thị trong phần Cài đặt tài khoản (nếu có) để việc xác minh nhanh hơn.

Chúng tôi sẽ:

1. Xác minh yêu cầu trong vòng 7 ngày làm việc.
2. Xóa tài khoản Firebase Authentication và dữ liệu ghi chú trên Cloud Firestore.
3. Thông báo cho bạn khi hoàn tất, trong vòng tối đa 30 ngày kể từ khi xác minh thành công.

Các bản sao lưu trên Google Drive nằm trong tài khoản của bạn nên bạn cần tự xóa; nếu không thể, hãy cho chúng tôi biết trong email yêu cầu để được hướng dẫn. Một số nhật ký kỹ thuật do Google lưu giữ có thể tồn tại thêm theo chính sách của Google và nghĩa vụ pháp lý.

---

## 8. Quyền của bạn

Tùy thuộc vào nơi bạn sinh sống, bạn có thể có các quyền sau:

- **Quyền được biết** dữ liệu nào đang được xử lý và mục đích xử lý.
- **Quyền truy cập và nhận bản sao** dữ liệu cá nhân của bạn.
- **Quyền chỉnh sửa** dữ liệu không chính xác.
- **Quyền xóa** dữ liệu và tài khoản.
- **Quyền rút lại sự đồng ý** bất cứ lúc nào, ví dụ ngắt kết nối Google Drive hoặc đăng xuất.
- **Quyền hạn chế hoặc phản đối** việc xử lý dữ liệu.
- **Quyền khiếu nại** với cơ quan bảo vệ dữ liệu cá nhân có thẩm quyền.
- **Quyền yêu cầu bồi thường thiệt hại** theo quy định pháp luật, nếu có.

Đối với người dùng tại Việt Nam, các quyền này được quy định tại Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15 và các văn bản hướng dẫn liên quan. Đối với người dùng tại Khu vực Kinh tế Châu Âu (EEA), Vương quốc Anh hoặc Thụy Sĩ, bạn có thêm các quyền theo Quy định Bảo vệ Dữ liệu Chung (GDPR), bao gồm quyền di chuyển dữ liệu và quyền khiếu nại với cơ quan giám sát tại quốc gia bạn cư trú. Đối với người dùng California, chúng tôi không bán dữ liệu cá nhân và bạn có quyền yêu cầu biết, xóa hoặc sửa dữ liệu mà không bị phân biệt đối xử.

Để thực hiện quyền của mình, hãy gửi email đến [firstntt90@gmail.com](mailto:firstntt90@gmail.com). Chúng tôi sẽ phản hồi trong vòng 30 ngày hoặc trong thời hạn pháp luật yêu cầu. Chúng tôi có thể cần xác minh danh tính trước khi xử lý yêu cầu để tránh tiết lộ dữ liệu cho người không có quyền.

---

## 9. Trẻ em

T-Note không hướng tới trẻ em dưới 13 tuổi và chúng tôi không cố ý thu thập dữ liệu cá nhân của trẻ em dưới 13 tuổi. Tại Việt Nam, việc xử lý dữ liệu của người dưới 16 tuổi cần có sự đồng ý của cha, mẹ hoặc người giám hộ hợp pháp. Nếu bạn là cha mẹ hoặc người giám hộ và phát hiện trẻ em đã cung cấp dữ liệu cho T-Note mà không có sự đồng ý hợp lệ, vui lòng liên hệ với chúng tôi để xóa dữ liệu.

---

## 10. Chuyển dữ liệu ra nước ngoài

Google là nhà cung cấp dịch vụ toàn cầu, nên dữ liệu có thể được lưu trữ và xử lý tại các quốc gia khác nơi Google đặt trung tâm dữ liệu, bao gồm ngoài Việt Nam. Trong phạm vi pháp luật yêu cầu, chúng tôi dựa vào các biện pháp bảo vệ phù hợp của Google, chẳng hạn như điều khoản hợp đồng tiêu chuẩn và các cam kết bảo mật trong sản phẩm của Google.

---

## 11. Cookie và công nghệ tương tự

T-Note là ứng dụng di động/desktop, không phải trang web quảng cáo và không sử dụng cookie để theo dõi bạn. Tuy nhiên, các SDK của Google có thể lưu token xác thực và bộ nhớ đệm cần thiết để duy trì đăng nhập, đồng bộ dữ liệu và hoạt động ngoại tuyến. Các token này được lưu trong vùng bảo vệ của ứng dụng hoặc do hệ điều hành quản lý.

---

## 12. Dịch vụ và liên kết bên thứ ba

Ứng dụng sử dụng các dịch vụ của Google. Khi bạn đăng nhập bằng Google hoặc cấp quyền Google Drive, bạn cũng chịu sự điều chỉnh của chính sách và điều khoản của Google:

- [Chính sách quyền riêng tư của Google](https://policies.google.com/privacy)
- [Điều khoản dịch vụ của Google](https://policies.google.com/terms)
- [Chính sách Dữ liệu Người dùng của Dịch vụ API Google](https://developers.google.com/terms/api-services-user-data-policy)
- [Chính sách quyền riêng tư của Firebase](https://firebase.google.com/support/privacy)

Chúng tôi không kiểm soát nội dung hoặc chính sách của các trang web bên thứ ba. Bạn nên đọc chính sách của họ trước khi sử dụng dịch vụ.

---

## 13. Thay đổi chính sách

Chúng tôi có thể cập nhật chính sách này khi thay đổi tính năng, cách xử lý dữ liệu hoặc yêu cầu pháp lý. Khi cập nhật, chúng tôi sẽ:

- Công bố phiên bản mới tại trang chính sách này và trong ứng dụng (nếu có).
- Cập nhật ngày "Cập nhật lần cuối" ở đầu trang.
- Thông báo rõ hơn (ví dụ qua ứng dụng hoặc trang cửa hàng ứng dụng) nếu thay đổi ảnh hưởng đáng kể đến quyền của bạn.
- Xin sự đồng ý mới nếu pháp luật yêu cầu.

Việc bạn tiếp tục sử dụng ứng dụng sau khi chính sách mới có hiệu lực đồng nghĩa với việc bạn chấp nhận chính sách đã cập nhật, trừ khi pháp luật yêu cầu sự đồng ý riêng.

---

## 14. Liên hệ

Mọi câu hỏi, yêu cầu hoặc khiếu nại về quyền riêng tư, vui lòng liên hệ:

- **Email:** [firstntt90@gmail.com](mailto:firstntt90@gmail.com)

Chúng tôi sẽ cố gắng phản hồi trong vòng 30 ngày kể từ khi nhận được yêu cầu hợp lệ.

---

## Phụ lục: Bảng tóm tắt dữ liệu

| Nhóm dữ liệu | Có thu thập? | Mục đích | Chia sẻ với bên thứ ba? |
|---|---|---|---|
| Nội dung ghi chú, checklist, nhãn, màu sắc | Có, do bạn nhập | Cung cấp tính năng ghi chú, tìm kiếm, đồng bộ, sao lưu | Chỉ Google (Firebase/Drive) theo yêu cầu của bạn |
| Email, tên, ảnh đại diện, UID | Có, khi đăng nhập | Xác thực, đồng bộ, hiển thị tài khoản | Google (Firebase Authentication) |
| Mật khẩu | Không (do Firebase xử lý) | Xác thực | Google (Firebase Authentication) |
| Vị trí, danh bạ, camera, micro, ảnh, SMS | Không | — | — |
| Mã quảng cáo, dữ liệu theo dõi | Không | — | — |
| Thông tin thanh toán | Không | — | — |
| Tùy chọn giao diện | Có, cục bộ | Ghi nhớ chế độ Sáng/Tối | Không |
| Nhật ký kỹ thuật | Do Google xử lý | Vận hành, bảo mật, xử lý sự cố | Google |

---

© 2026 T-Note. Chính sách này được viết bằng tiếng Việt. Nếu có bản dịch, bản tiếng Việt được ưu tiên áp dụng trong phạm vi pháp luật cho phép.
