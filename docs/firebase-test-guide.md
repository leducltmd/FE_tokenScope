# Hướng dẫn kiểm thử Firebase trên Android và Web

Project: `TokenScope`  
Firebase project: `tokenscope-5116d`  
Thư mục chạy lệnh: `F:\PRM\FE_tokenScope`

## 1. Ma trận hỗ trợ

| Dịch vụ | Android | Web | Ghi chú |
| --- | --- | --- | --- |
| Firebase Authentication | Có | Có | Web cần Firebase Web config và popup/redirect auth |
| Cloud Storage | Có | Có | Rules phải giới hạn theo UID |
| Cloud Messaging | Có | Có | Web cần Service Worker + VAPID key |
| Analytics | Có | Có | Kiểm tra bằng DebugView |
| Crashlytics | Có | Không | Flutter Crashlytics không dùng để test Web |
| Remote Config | Có | Có | Phải chứng minh thay đổi hành vi thật |

## 2. Chuẩn bị chung

### 2.1. Firebase Console

Kiểm tra project:

```text
Firebase Console → Project settings
Project ID: tokenscope-5116d
```

Bật các dịch vụ:

```text
Authentication
Storage
Cloud Messaging
Google Analytics
Crashlytics
Remote Config
```

Không đưa API key bí mật, backend secret hoặc private key vào GitHub.

### 2.2. Cài công cụ

```powershell
firebase login
dart pub global activate flutterfire_cli
flutter pub get
```

### 2.3. Android device

```powershell
adb devices
flutter devices
```

Phải thấy Android Emulator hoặc điện thoại thật ở trạng thái `device`.

### 2.4. Web config

Project hiện cần được cấu hình thêm Firebase Web:

```powershell
flutterfire configure
```

Chọn project `tokenscope-5116d`, chọn cả `android` và `web`, rồi cập nhật
`lib/firebase_options.dart`.

Trong `main.dart`, Firebase phải được khởi tạo cho cả hai platform:

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
await FirebaseLab3Controller.instance.initialize();
runApp(const TokenScopeApp());
```

Các service dùng chung cho Android/Web không được chặn bằng `!kIsWeb`.
Riêng Crashlytics vẫn phải bỏ qua Web.

## 3. Chạy project

### Android

```powershell
flutter run -d <android-device-id>
```

Ví dụ:

```powershell
flutter run -d emulator-5554
```

### Web

```powershell
flutter run -d chrome
```

FCM Web cần `localhost` hoặc HTTPS. Khi test production build:

```powershell
flutter build web --release
firebase serve --only hosting
```

## 4. Authentication

### Firebase Console

Vào:

```text
Authentication → Sign-in method
```

Bật:

- Email/Password
- Google

Thêm các domain Web:

```text
localhost
127.0.0.1
```

### Android test

1. Mở app khi chưa đăng nhập.
2. Đăng nhập bằng Google.
3. Kiểm tra app chuyển đến Dashboard.
4. Vào Firebase Console → Authentication → Users.
5. Kiểm tra user mới và Firebase UID.
6. Đăng xuất.
7. Đóng/mở lại app để kiểm tra session.
8. Hủy hộp thoại chọn tài khoản Google.
9. Tắt mạng rồi thử đăng nhập.

Expected result:

- Hủy đăng nhập không làm app crash.
- Logout xóa session và quay về Login.
- Mất mạng hiển thị thông báo rõ ràng.
- `authStateChanges()` chuyển đúng giữa Login và Dashboard.

### Web test

Flow `google_sign_in` hiện tại của project dành cho Android. Trên Web cần
dùng Firebase Auth Web popup hoặc redirect với `GoogleAuthProvider`.

Sau khi cấu hình Web auth:

1. Mở Chrome tại `http://localhost`.
2. Đăng nhập Google bằng popup/redirect.
3. Reload trình duyệt.
4. Kiểm tra session vẫn tồn tại.
5. Đăng xuất và kiểm tra IndexedDB/Local Storage không còn session hợp lệ.
6. Từ chối popup hoặc đóng popup.

## 5. Cloud Storage

### Cấu hình rules

Deploy rules:

```powershell
firebase deploy --only storage
```

Path hợp lệ:

```text
reports/{uid}/{fileName}
```

### Android test

1. Đăng nhập Firebase.
2. Vào Dashboard → Settings.
3. Nhấn `Xuất PDF & Tải lên Cloud Storage`.
4. Kiểm tra progress từ 0% đến 100%.
5. Vào Firebase Console → Storage → `reports/{uid}`.
6. Kiểm tra PDF tồn tại và URL là URL thật.
7. Đăng xuất rồi thử upload.
8. Dùng user khác thử đọc file của user đầu tiên.
9. Tắt mạng rồi thử upload.

Expected result:

- Upload thành công chỉ khi có Firebase user.
- File xuất hiện thật trong Firebase Storage.
- User khác bị từ chối.
- Lỗi mạng/phân quyền trả về failure, không trả success giả.

### Web test

1. Đăng nhập trong Chrome.
2. Lặp lại flow upload PDF như Android.
3. Mở Chrome DevTools → Network.
4. Kiểm tra request đến Firebase Storage trả HTTP success.
5. Kiểm tra file trong Storage Console.
6. Thử upload khi logout và khi tắt mạng.

## 6. Cloud Messaging / FCM

### Android chuẩn bị

Android 13+ cần permission:

```text
POST_NOTIFICATIONS
```

Trong màn hình Alerts, lấy FCM Device Token.

### Android test

1. Mở app ở foreground.
2. Gửi test message từ Firebase Console → Cloud Messaging.
3. Kiểm tra thông báo foreground và notification center.
4. Đưa app xuống background rồi gửi lại.
5. Chạm notification để kiểm tra điều hướng.
6. Tắt app hoàn toàn rồi gửi lại.
7. Mở notification để kiểm tra `getInitialMessage()`.
8. Từ chối quyền notification.
9. Kiểm tra notification vẫn được lưu sau khi mở lại app.

Các route cần kiểm tra:

```text
budget    → BudgetScreen
providers → ProvidersScreen
alerts    → AlertsScreen
```

### Web chuẩn bị

Tạo `web/firebase-messaging-sw.js`:

```javascript
importScripts(
  'https://www.gstatic.com/firebasejs/13.0.0/firebase-app-compat.js'
);
importScripts(
  'https://www.gstatic.com/firebasejs/13.0.0/firebase-messaging-compat.js'
);

firebase.initializeApp({
  apiKey: 'WEB_API_KEY',
  authDomain: 'tokenscope-5116d.firebaseapp.com',
  projectId: 'tokenscope-5116d',
  storageBucket: 'tokenscope-5116d.firebasestorage.app',
  messagingSenderId: '282372790467',
  appId: 'WEB_APP_ID',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[FCM Web] Background message', payload);
});
```

Trong Firebase Console:

```text
Project settings → Cloud Messaging → Web Push certificates
```

Lấy VAPID key và truyền vào Web implementation khi gọi `getToken()`.

### Web test

1. Chạy app bằng Chrome trên `localhost` hoặc HTTPS.
2. Mở DevTools → Application → Service Workers.
3. Xác nhận `firebase-messaging-sw.js` đã active.
4. Cấp quyền notification.
5. Kiểm tra token hiển thị trong Alerts.
6. Gửi test message khi tab đang mở.
7. Gửi test message khi tab chạy nền.
8. Chạm notification và kiểm tra route.
9. Từ chối quyền rồi kiểm tra trạng thái lỗi.

## 7. Firebase Analytics

### Android chuẩn bị DebugView

```powershell
adb shell setprop debug.firebase.analytics.app com.tokenscope.tokenscope
```

Mở:

```text
Firebase Console → Analytics → DebugView
```

### Android và Web test

Thực hiện các thao tác sau:

```text
login
logout
connect_provider
view_usage_history
view_usage_detail
export_report
update_budget
```

Kiểm tra:

- Event xuất hiện trong DebugView.
- Parameters đúng tên và kiểu dữ liệu.
- Không có email, tên thật hoặc API key trong parameters.
- `userId` được gắn sau khi login.

Trên Web, nếu DebugView không hiện event, kiểm tra Chrome DevTools → Console
và xác nhận Analytics Web đã được khởi tạo.

## 8. Firebase Crashlytics

Crashlytics chỉ kiểm thử trên Android trong workflow này.

### Android test

1. Mở app trên Android Emulator hoặc thiết bị thật.
2. Đăng nhập.
3. Nhấn `Gửi lỗi Non-Fatal`.
4. Chờ vài phút rồi mở Firebase Console → Crashlytics.
5. Kiểm tra non-fatal error.
6. Kiểm tra Firebase user ID.
7. Kiểm tra custom keys như `screen` và `test_environment`.
8. Nhấn `Crash thử nghiệm` trong khu vực demo.
9. Mở lại app để Crashlytics gửi crash report.

### Web

Không đánh dấu Crashlytics Web là PASS. Khi chạy Web, nút crash thử nghiệm phải
bị ẩn hoặc trả về thông báo không hỗ trợ Web.

## 9. Firebase Remote Config

### Cấu hình Console

Tạo hoặc cập nhật các parameter:

```text
promo_banner_enabled = true
promo_banner_text = Firebase Web Test
max_history_items = 3
enable_pdf_export = false
```

### Android và Web test

1. Mở app và ghi nhận trạng thái ban đầu.
2. Publish giá trị mới trong Remote Config Console.
3. Nhấn `Làm mới cấu hình Cloud`.
4. Kiểm tra banner đổi nội dung.
5. Kiểm tra lịch sử chỉ hiển thị tối đa 3 record.
6. Kiểm tra xuất PDF bị khóa khi `enable_pdf_export = false`.
7. Đổi lại `enable_pdf_export = true`.
8. Tắt mạng rồi reload app.
9. Kiểm tra app dùng default values và không crash.

## 10. Checklist kết quả

| Dịch vụ | Android | Web | Ghi chú |
| --- | --- | --- | --- |
| Authentication | TODO | TODO | |
| Cloud Storage | TODO | TODO | |
| Cloud Messaging | TODO | TODO | Service Worker/VAPID trên Web |
| Analytics | TODO | TODO | DebugView |
| Crashlytics | TODO | N/A | Chỉ Android |
| Remote Config | TODO | TODO | Kiểm tra thay đổi behavior |

## 11. Lỗi thường gặp

| Lỗi | Cách xử lý |
| --- | --- |
| `FirebaseOptions have not been configured for web` | Chạy lại `flutterfire configure` và chọn Web |
| Google Sign-In Web không mở popup | Dùng Firebase Auth Web popup/redirect, không dùng Android `google_sign_in` flow |
| Storage bị `permission-denied` | Kiểm tra user UID và deploy lại `storage.rules` |
| FCM Web không có token | Kiểm tra HTTPS/localhost, Service Worker và VAPID key |
| FCM background không chạy | Kiểm tra `firebase-messaging-sw.js` trong DevTools → Service Workers |
| Analytics không thấy event | Kiểm tra Firebase initialization và DebugView |
| Remote Config không đổi | Gọi `fetchAndActivate()` và kiểm tra minimum fetch interval |
| Crashlytics không có report trên Web | Đây là giới hạn platform; chuyển sang Android |

## 12. Tài liệu chính thức

- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/auth/flutter/start
- https://firebase.google.com/docs/storage/web/start
- https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
- https://firebase.google.com/docs/analytics/flutter/get-started
- https://firebase.google.com/docs/remote-config/flutter/get-started
- https://firebase.google.com/docs/crashlytics/flutter/get-started
