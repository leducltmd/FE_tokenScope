# Ma Trận Truy Vết Thiết Kế (Design Traceability Matrix)
> **Dự án:** TokenScope — Giám sát & Quản lý Chi phí API AI  
> **Mã môn:** PRM393 - Lập trình Di động (Lab 3)  
> **Tài liệu tham chiếu:** Slide thuyết trình `13102026.pdf` (Group 5), Figma Design & Handout Lab 3  

---

## 1. Bảng Ánh Xạ 10 Màn Hình Thiết Kế Sang Flutter (Screens Mapping)

Toàn bộ 10 màn hình từ bản thiết kế Lab 2 (`13102026.pdf`, Slide 5) đã được hiện thực hóa đầy đủ trong mã nguồn Flutter:

| STT | Màn hình thiết kế Lab 2 | Tuyến đường / File Flutter | Widget chính | Nguồn dữ liệu (Data Source) | Trạng thái |
| :---: | :--- | :--- | :--- | :--- | :---: |
| **01** | **Dashboard** (Tổng quan) | `lib/screens/dashboard/dashboard_screen.dart` | `DashboardScreen` | `GET /api/usage/summary` qua `DashboardController` | ✅ Hoàn thành |
| **02** | **AI Providers** (Nhà cung cấp) | `lib/screens/providers/providers_screen.dart` | `ProvidersScreen` | `GET /api/providers` qua `ProvidersController` | ✅ Hoàn thành |
| **03** | **Projects** (Quản lý dự án) | `lib/screens/projects/projects_screen.dart` | `ProjectsScreen` | `GET /api/projects` qua `ProjectsController` | ✅ Hoàn thành |
| **04** | **Analytics** (Phân tích chi tiết) | `lib/screens/analysis/ai_analysis_screen.dart` | `AiAnalysisScreen` | `GET /api/usage/analysis` qua `AnalysisController` | ✅ Hoàn thành |
| **05** | **Alerts** (Trung tâm cảnh báo) | `lib/screens/alerts/alerts_screen.dart` | `AlertsScreen` | `FirebaseMessagingService` + `NotificationStore` | ✅ Hoàn thành |
| **06** | **Usage History** (Lịch sử gọi) | `lib/screens/usage_history/usage_history_screen.dart` | `UsageHistoryScreen` | `GET /api/usage/records` qua `UsageHistoryController` | ✅ Hoàn thành |
| **07** | **Usage Details** (Chi tiết lượt gọi) | `lib/screens/usage_details/usage_details_screen.dart` | `UsageDetailsScreen` | `UsageRecord` model truyền qua navigation | ✅ Hoàn thành |
| **08** | **Budget Overview** (Tổng quan ngân sách) | `lib/screens/budget/budget_screen.dart` | `BudgetScreen` | `GET /api/budgets` qua `BudgetController` | ✅ Hoàn thành |
| **09** | **Budget Settings** (Thiết lập ngân sách) | Tích hợp trong `lib/screens/budget/budget_screen.dart` | Form điều chỉnh ngân sách | `POST /api/budgets` qua `BudgetController` | ✅ Hoàn thành (Gộp UX) |
| **10** | **Profile & Settings** (Hồ sơ & cài đặt) | Tab thứ 4 trên `lib/screens/dashboard/dashboard_screen.dart` | `_buildSettings()` | `AuthController` + `FirebaseLab3Controller` | ✅ Hoàn thành (Gộp Tab) |

---

## 2. Các Màn Hình Bổ Sung Theo Yêu Cầu Lab 3 (Section 3 Handout)

Theo quy định mục 3 của tài liệu Lab 3: *"Nếu thiết kế chưa có màn hình đăng nhập hoặc hồ sơ, bổ sung chúng bằng cùng hệ thống thiết kế (Design System)"*:

| STT | Màn hình bổ sung | File Flutter | Widget chính | Mục đích kỹ thuật |
| :---: | :--- | :--- | :--- | :--- |
| **11** | **Login** (Đăng nhập) | `lib/screens/auth/login_screen.dart` | `LoginScreen` | Xác thực Email/Password & Google Sign-In |
| **12** | **Register** (Đăng ký) | `lib/screens/auth/register_screen.dart` | `RegisterScreen` | Đăng ký tài khoản, kiểm tra ngày sinh $\ge$ 13 tuổi |
| **13** | **Forgot Password** (Quên MK) | `lib/screens/auth/forgot_password_screen.dart` | `ForgotPasswordScreen` | Gửi link đặt lại mật khẩu |
| **14** | **Connect Provider** (Thêm API Key) | `lib/screens/providers/connect_provider_screen.dart` | `ConnectProviderScreen` | Kết nối và test API Key thật với OpenAI/Claude |

---

## 3. Ghi Nhận Mọi Điểm Khác Biệt So Với Figma & Lý Do Kỹ Thuật (Deviations with Reasons)

Tuân thủ nghiêm ngặt quy định: *"Record every change in docs/design-traceability.md with its reason, an unrecorded difference between Figma and the app is graded as a defect"*.

### Độ lệch 1: Hợp nhất Budget Settings vào Budget Overview
* **Hiện trạng Figma:** Màn hình số 8 (`Budget Overview`) và màn hình số 9 (`Budget Settings`) là 2 màn hình riêng biệt.
* **Hiện thực Flutter:** Tích hợp phần điều chỉnh hạn mức ngân sách và ngưỡng cảnh báo trực tiếp vào nửa dưới của `BudgetScreen`.
* **Lý do kỹ thuật & UX:** Giảm thiểu độ sâu điều hướng (Navigation Stack Depth), cho phép người dùng vừa quan sát biểu đồ thanh tiến độ tiêu dùng vừa nhập số tiền điều chỉnh ngay tại chỗ, nhận phản hồi thị giác tức thì mà không cần chuyển màn hình qua lại.

### Độ lệch 2: Đưa Profile & Firebase Demo vào Tab Điều Hướng Đáy
* **Hiện trạng Figma:** Màn hình số 10 (`Profile & Settings`) mở qua icon avatar góc phải.
* **Hiện thực Flutter:** Bố trí làm Tab thứ 4 cố định trên thanh `TsBottomNavigation` (`Cài đặt`).
* **Lý do kỹ thuật & UX:** Đáp ứng yêu cầu Slide 10 của Lab 3: *"Cung cấp khu vực trình diễn Firebase (Firebase Demo Area) trên màn hình Profile"*. Đưa vào thanh điều hướng đáy giúp người chấm thi và giảng viên có thể truy cập nhanh vào các tính năng kiểm thử Firebase (FCM, Storage PDF, Remote Config, Crashlytics) chỉ với một chạm.

---

## 4. Ánh Xạ 3 Luồng Người Dùng & Chuẩn Hóa Thành Workflow Nghiệp Vụ

### 4.1. Luồng A: Theo dõi & Kiểm toán Lượt gọi AI (Flow A $\rightarrow$ WF-01)
* **Luồng UI (Figma):** `Dashboard` $\rightarrow$ `Usage History` $\rightarrow$ `Usage Details` $\rightarrow$ `Analytics`.
* **Hiện thực Flutter:**
  * Từ `DashboardHeader` hoặc thanh điều hướng $\rightarrow$ mở `UsageHistoryScreen`.
  * Chạm vào 1 bản ghi bất kỳ $\rightarrow$ mở `UsageDetailsScreen` hiển thị trạng thái HTTP, độ trễ và mã cURL.
  * Nhấn nút chia sẻ hoặc quay lại mở `AiAnalysisScreen`.
* **Xử lý nhánh lỗi / ngoại lệ:** Khi bộ lọc không có dữ liệu $\rightarrow$ hiển thị `TsEmptyState` kèm nút bấm *"Xóa bộ lọc"* để phục hồi danh sách gốc.

### 4.2. Luồng B: Quản trị & Điều chỉnh Hạn mức Ngân sách (Flow B $\rightarrow$ WF-02)
* **Luồng UI (Figma):** `Budget Overview` $\rightarrow$ `Budget Settings` $\rightarrow$ `Save` $\rightarrow$ `Success`.
* **Hiện thực Flutter:**
  * Chạm thẻ "Cảnh báo ngân sách" trên Dashboard $\rightarrow$ mở `BudgetScreen`.
  * Cuộn xuống form điều chỉnh $\rightarrow$ nhập hạn mức mới và ngưỡng cảnh báo $\rightarrow$ bấm *"Lưu ngân sách"*.
  * Hộp thoại xác nhận `TsDialog.confirm` mở ra xác nhận thay đổi.
* **Xử lý nhánh lỗi / ngoại lệ:** Nhập hạn mức nhỏ hơn chi phí đã dùng hoặc số âm $\rightarrow$ hiển thị cảnh báo lỗi và chặn lưu (`BR-01`).

### 4.3. Luồng C: Tiếp nhận & Xử lý Cảnh báo Chi phí (Flow C $\rightarrow$ WF-03)
* **Luồng UI (Figma):** `Dashboard` $\rightarrow$ `Alerts` $\rightarrow$ `Analytics`.
* **Hiện thực Flutter:**
  * Bấm biểu tượng Chuông trên Dashboard hoặc chạm vào Push Notification FCM $\rightarrow$ mở `AlertsScreen`.
  * Chạm vào thông báo vượt ngân sách $\rightarrow$ tự động điều hướng sang `BudgetScreen` hoặc `AiAnalysisScreen`.
* **Xử lý nhánh lỗi / ngoại lệ:** Khi mất kết nối mạng $\rightarrow$ `AlertsScreen` hiển thị cache thông báo cục bộ và thanh thông báo lỗi offline.

---

## 5. Ánh Xạ Design System Tokens Sang Mã Nguồn Flutter

| Token Figma | Giá trị Hex / dp | Hằng số mã nguồn Flutter | Sử dụng cho |
|---|---|---|---|
| `Primary` | `#6366F1` | `AppColors.primary` | Nút chính, liên kết, tab active |
| `Navy Text` | `#111827` | `AppColors.navy` | Tiêu đề H1, H2, chữ quan trọng |
| `Background` | `#F8FAFC` | `AppColors.background` | Màu nền ứng dụng |
| `Surface` | `#FFFFFF` | `AppColors.surface` | Thẻ Card, Dialog, Bottom Sheet |
| `Font Family` | Inter | `AppTypography.fontFamily` | Nhúng tại `assets/fonts/Inter-*.ttf` |
| `Spacing 4–32` | 4, 8, 12, 16, 24, 32 dp | `AppSpacing.space4` ... `space32` | Padding và Margin chuẩn lưới |
| `Radius 8–24` | 8, 12, 16, 24 dp | `AppRadius.small` ... `extraLarge` | Bo góc Card, Button, Dialog |
| `Touch Target` | $\ge 48 \times 48$ dp | `kMinInteractiveDimension` | Toàn bộ các vùng chạm tương tác |
| `Typography` | $\ge 14$ sp (body) | `AppTypography.bodySmall` (14sp) | Tuân thủ chuẩn tiếp cận người dùng |
