# TokenScope — Hệ thống thiết kế & Giao diện xác thực

Nền tảng giám sát API trí tuệ nhân tạo. Giao diện xây dựng theo 5 nhóm
quy chuẩn thiết kế: **Màu sắc · Kiểu chữ · Khoảng cách · Bo góc · Độ nổi**.

## 01 · Màu sắc (`lib/core/theme/app_colors.dart`)

| Token | Hex | Dùng cho |
|---|---|---|
| `color.primary` | `#6366F1` | Nút chính, liên kết, trạng thái chọn |
| `color.primaryDark` | `#4338CA` | Nút khi nhấn, điểm nhấn tương tác |
| `color.navy` | `#111827` | Tiêu đề, nội dung quan trọng |
| `color.background` | `#F8FAFC` | Nền trang, vùng dữ liệu tổng quan |
| `color.surface` | `#FFFFFF` | Thẻ dữ liệu, hộp thoại |
| `color.secondaryText` | `#475569` | Mô tả, chú thích, thời gian cập nhật |
| `color.border` | `#E5E7EB` | Viền thẻ, đường phân cách |
| `color.success` | `#16A34A` | API hoạt động, yêu cầu thành công |
| `color.warning` | `#D97706` | Sắp vượt hạn mức, độ trễ tăng |
| `color.error` | `#DC2626` | Kết nối thất bất, lỗi API |

Bảng màu mở rộng cho giao diện hiện đại:

| Token | Hex | Dùng cho |
|---|---|---|
| `color.softPurple` | `#F5F3FF` | Nền chip, huy hiệu mềm, mục điều hướng đang chọn |
| `color.violet` | `#8B5CF6` | Điểm nhấn tím trong thẻ nền tối |
| `color.azure` | `#3B82F6` | Biểu đồ, cột nổi bật, trạng thái "Live" |
| `color.cream` | `#FEF7E4` | Nền thẻ cảnh báo ngân sách |
| `color.creamBorder` | `#F6E4B4` | Viền thẻ cảnh báo |
| `color.live` | `#12B76A` | Trạng thái trực tiếp |
| `color.liveLight` | `#E7F8F0` | Nền huy hiệu "Live" |
| `color.emerald` | `#10B981` | Biểu đồ nhà cung cấp (OpenAI) |
| `color.tangerine` | `#F59E0B` | Biểu đồ nhà cung cấp (Anthropic) |

## 02 · Kiểu chữ (`lib/core/theme/app_typography.dart`)

Font **Inter** (nhúng tại `assets/fonts/`).

| Token | Cỡ chữ | Đậm |
|---|---|---|
| `type.h1` | 28 px | 700 |
| `type.h2` | 22 px | 600 |
| `type.h3` | 18 px | 600 |
| `type.body` | 16 px | 400 |
| `type.bodySmall` | 14 px | 400 |
| `type.label` | 14 px | 500 |

## 03 · Khoảng cách & 04 · Bo góc (`lib/core/theme/app_spacing.dart`)

Khoảng cách: `space.4` `space.8` `space.12` `space.16` `space.24` `space.32`
Bo góc: `radius.small` 8 · `radius.medium` 12 · `radius.large` 16 · `radius.extraLarge` 24

## 05 · Độ nổi (`lib/core/theme/app_elevation.dart`)

Độ lan luôn `0px`. Cấp 0 không bóng đổ · Cấp 1 `rgba(17,24,39,0.06)` ·
Cấp 2 `rgba(17,24,39,0.10)` · Cấp 3 `rgba(17,24,39,0.14)`.

## Cấu trúc màn hình
```
lib/
├── core/
│   ├── theme/          # Hệ thống thiết kế (màu, chữ, spacing, bo góc, độ nổi)
│   ├── utils/          # ts_motion.dart — tắt hiệu ứng lặp khi kiểm thử
│   └── widgets/        # PrimaryButton, TsTextField, TsCheckbox, TsLogo, ...
├── providers/
│   └── auth_controller.dart
├── screens/
│   ├── auth/           # Login · Register · ForgotPassword
│   ├── analysis/       # Phân tích sử dụng AI + biểu đồ
│   ├── budget/         # Quản lý ngân sách AI + thành phần ngân sách
│   └── dashboard/
│       ├── dashboard_screen.dart
│       └── widgets/    # Header · Alert · Hero · QuickActions · WeeklyChart ·
│                        # ProviderCard · ActivityFeed
└── services/
    ├── auth_service.dart        # Interface
    ├── mock_auth_service.dart   # Dữ liệu giả lập (mật khẩu demo: 123456)
    └── api_auth_service.dart    # Gọi backend thật
```

## Bảng điều khiển tổng quan

Màn hình `DashboardScreen` bố cục theo thứ tự:

1. **Đầu trang** — logo + "TokenScope" + huy hiệu "Live" nhấp nháy, chuông thông
   báo (có chấm báo), avatar người dùng, lời chào, mô tả, huy hiệu "Đồng bộ
   1m trước" kèm hiệu ứng sóng.
2. **Cảnh báo ngân sách** — thẻ nền kem, biểu tượng cảnh báo, thẻ "87% mức
   trần", chạm để điều chỉnh.
3. **Thẻ chỉ số nổi bật** — nền gradient tím–xanh dương có quầng sáng, tổng
   token, chi phí ước tính, thanh phân rã input/output, tiến trình chi tiêu
   tháng.
4. **Lưới hành động nhanh** — Phân tích · Đối tác · Dự án · Cảnh báo.
5. **Xu hướng sử dụng 7 ngày** — biểu đồ cột, cột T5 nổi bật kèm tooltip
   "450k", nút chọn khoảng thời gian.
6. **Phân bổ theo nhà cung cấp** — OpenAI 49% · Google Gemini 33% ·
   Anthropic Claude 18%, kèm thanh tiến trình và chi phí.
7. **Truy vấn gần nhất** — model, dự án, số token và chi phí.
8. **Thanh điều hướng dưới** — Tổng quan · Lịch sử · Ngân sách · Cài đặt.

Bấm vào mục **"Ngân sách"** ở thanh điều hướng dưới (hoặc thẻ "Cảnh báo
ngân sách" / ô "Cảnh báo" ở lưới hành động nhanh) sẽ mở trang **Quản lý
ngân sách AI**.

## Trang quản lý ngân sách AI

Màn hình `BudgetScreen` (`lib/screens/budget/`) bố cục theo thứ tự:

1. **Đầu trang** — logo + "TokenScope" + huy hiệu "Live", chip chu kỳ tính
   toán ("CHU KỲ: 01/10 - 31/10"), tiêu đề "Quản lý ngân sách AI".
2. **Thẻ hạn mức tổng** — chi phí đã dùng `$34.80 / $40.00`, thẻ tỷ lệ
   `87.0% HẠN MỨC`, số tiền còn lại.
3. **Dải cảnh báo đỏ** — đã vượt ngưỡng an toàn 80% ($32.00).
4. **Thanh tiêu trình** — có vạch đánh dấu ngưỡng cảnh báo, chú thích
   `$0.00 · Ngưỡng: $32.00 · Trần: $40.00`.
5. **Dự báo chi tiêu AI cuối tháng** — dự báo chạm mức `$41.20` ngày 31/10.
6. **Công tắc giới hạn rate-limit tự động** — bật/tắt.
7. **Phân bổ ngân sách** — chuyển đổi giữa *Theo nhà cung cấp* và *Theo dự
   án (3)*; mỗi khoản có thanh tiến trình, % hạn mức đã dùng, số tiền còn
   lại và huy hiệu trạng thái (Đang ổn định / Gần chạm hạn mức / Cần mở rộng
   ngay).
8. **Điều chỉnh ngân sách & ngưỡng cảnh báo** — nút "Lưu ngân sách".
9. **Lịch sử chu kỳ thanh toán trước**.

Thanh điều hướng dưới vẫn hiển thị với mục **"Ngân sách"** đang chọn; chọn
mục khác sẽ quay lại bảng điều khiển tổng quan.

## Kết nối backend

Backend TokenScope (Express + Prisma + SQL Server) đã được dựng sẵn tại
`BE_tokenScope/`. Cấu hình:

```dart
TokenScopeApp(authController: AuthController(service: ApiAuthService()));
```

`ApiAuthService` tự chọn URL phù hợp theo nền tảng:

| Nền tảng              | URL mặc định                |
| --------------------- | --------------------------- |
| Flutter Web / Desktop | `http://localhost:3000/api` |
| Android Emulator      | dò tự xem bảng bên dưới    |

**Các host loopback của Android Emulator** — mỗi loại emulator dùng một địa
chỉ khác nhau, `ApiAuthService` sẽ thử lần lượt cho tới khi kết nối được:

| Emulator                       | Host loopback |
| ------------------------------ | ------------- |
| Genymotion                     | `10.0.3.2`    |
| Android Studio Emulator        | `10.0.3.2`    |
| AVD dùng kernel QEMU cũ         | `10.0.2.2`    |
| `adb reverse tcp:3000 tcp:3000` | `127.0.0.1`   |

Trước khi gửi request thật, app gọi `/api/health` với timeout ngắn (4 giây)
để dò host nào đang chạy backend. Nhờ vậy một địa chỉ không phản hồi bị bỏ
qua nhanh thay vì làm người dùng chờ hết timeout của request.

Nếu vẫn không được, dùng `adb reverse` cho chắc:

```bash
adb reverse tcp:3000 tcp:3000
```

> **Lỗi "Không kết nối được tới máy chủ TokenScope"** nghĩa là app không gọi
> được backend. Hãy kiểm tra backend đã chạy chưa (`npm run dev` trong
> `BE_tokenScope`) và cổng `3000` có thông từ emulator hay không. Thông báo
> này khác với lỗi "Email hoặc mật khẩu không đúng" — lỗi sau nghĩa là kết
> nối đã thành công nhưng thông tin đăng nhập sai (email trong DB được lưu
> dạng chữ thường, kể cả khi bạn gõ hoa/thường khác nhau).

Khi chạy trên thiết bị vật lý hoặc muốn trỏ về host khác, dùng
`--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.9:3000/api
```

> Lưu ý khi chạy Flutter Web: dev server thường tự chọn cổng ngẫu nhiên
> (không phải `3000`). Backend đã được cấu hình để cho phép mọi origin
> `localhost`/`127.0.0.1` ở bất kỳ cổng nào trong môi trường development.

Để chạy giao diện độc lập không cần backend:

```dart
TokenScopeApp(useMockService: true);
```

Tài khoản demo: `demo@tokenscope.io / 123456`

## Đăng ký tài khoản

Form đăng ký gồm: **Họ và tên** · **Ngày sinh** · **Email** · **Mật khẩu** ·
**Xác nhận mật khẩu** · điều khoản sử dụng.

- Ngày sinh dùng widget `TsDateField` (`lib/core/widgets/ts_date_field.dart`),
  lưu ở định dạng `YYYY-MM-DD` và gửi lên API qua trường `birthDate`.
- Backend yêu cầu `birthDate` hợp lệ và người dùng từ 13 tuổi trở lên
  (`BE_tokenScope/src/modules/auth/auth.validation.ts`).
- Cột `birthDate` được thêm bằng migration
  `20261101140000_add_user_birth_date`.

Sau khi đăng ký thành công, dashboard hiển thị lời chào **`Xin chào, {tên đệm} {tên}`**
lấy từ trường "Họ và tên" vừa đăng ký (`AuthController.shortName`). Tên đệm +
tên là **hai từ cuối** của họ tên:

| Họ tên | Lời chào |
|---|---|
| Nguyễn Minh Anh | Xin chào, Minh Anh |
| Nguyễn Văn Minh Anh | Xin chào, Minh Anh |
| Minh Anh | Xin chào, Minh Anh |
| Minh | Xin chào, Minh |

## Chạy ứng dụng

```bash
flutter pub get
flutter run              # thiết bị đang kết nối
flutter run -d chrome    # web
```

## Kiểm thử

```bash
flutter test
flutter test --update-goldens   # cập nhật ảnh giao diện trong test/goldens
```

Bộ test gồm:
- `test/widget_test.dart` — luồng UI (dùng mock service)
- `test/auth_user_test.dart` — quy tắc hiển thị tên (tên đệm + tên)
- `test/dashboard_test.dart` — kiểm tra bố cục dashboard ở khung 390×844
- `test/budget_test.dart` — kiểm tra trang quản lý ngân sách AI
- `test/components_test.dart` — thư viện thành phần giao diện
- `test/golden_test.dart` — ảnh giao diện 4 màn hình ở khung 390×844
- `test/api_integration_test.dart` — tích hợp thật với backend (tự bỏ qua nếu
  backend không chạy tại `http://localhost:3000`)
