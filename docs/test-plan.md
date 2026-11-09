# Kế Hoạch & Nhật Ký Kiểm Thử Tự Động Đầu Cuối (Google ARTEMIS Test Plan)
> **Môn học:** PRM393 - Lập trình Di động (Lab 3)  
> **Dự án:** TokenScope — AI Token & Cost Management Platform  
> **Công cụ kiểm thử:** Google ARTEMIS (AI Testing Agent, Python 3.12+, uv, ADB, Android Emulator Pixel 7 API 34)  
> **Mô hình AI kiểm thử:** Gemini 2.5 Flash (chạy hồi quy) & Gemini Pro (chạy phiên khám phá)  

---

## 1. Danh Sách Các Luồng Quan Trọng Của Ứng Dụng (Critical Flows)

| Mã Luồng | Tên Luồng Nghiệp Vụ | Các Màn Hình Sử Dụng | Mục Tiêu Kiểm Thử |
|:---:|---|---|---|
| **FLOW-01** | Xác thực & Đăng nhập Người dùng | `LoginScreen`, `DashboardScreen` | Đăng nhập tài khoản kiểm thử, hiển thị trang chủ và lời chào |
| **FLOW-02** | Khám phá & Lọc Lịch sử Gọi API (Flow A) | `DashboardScreen`, `UsageHistoryScreen`, `UsageDetailsScreen` | Tìm kiếm, lọc theo provider, xem chi tiết prompt/response và cURL |
| **FLOW-03** | Quản lý & Cập nhật Ngân sách AI (Flow B) | `DashboardScreen`, `BudgetScreen` | Thay đổi hạn mức chi tiêu, kiểm tra cập nhật thanh tiến độ |
| **FLOW-04** | Tiếp nhận & Điều hướng Cảnh báo (Flow C) | `DashboardScreen`, `AlertsScreen`, `BudgetScreen` | Mở trung tâm thông báo, chạm thông báo điều hướng sang Ngân sách |
| **FLOW-05** | Kết nối & Kiểm định Khóa Nhà cung cấp | `ProvidersScreen`, `ConnectProviderScreen` | Kiểm tra Secret Key & Admin Key độc lập |
| **FLOW-06** | Xuất & Tải lên Báo cáo PDF Đám mây | `DashboardScreen (Cài đặt)`, Firebase Cloud Storage | Bấm xuất PDF, theo dõi thanh tiến độ 0-100%, nhận URL tải về |
| **FLOW-07** | Cập nhật Cấu hình Động Từ xa | `DashboardScreen`, `FirebaseRemoteConfigService` | Làm mới Remote Config, quan sát Promo Banner cập nhật tức thì |
| **FLOW-08** | Đăng xuất & Dọn dẹp Phiên làm việc | `DashboardScreen (Cài đặt)`, `LoginScreen` | Thu hồi token, xóa dữ liệu cục bộ, trở về màn hình đăng nhập |

---

## 2. Danh Sách 10 Ca Kiểm Thử Tự Động ARTEMIS (Test Cases Specification)

| Mã ID | Luồng | Điều kiện đầu (Precondition) | Chỉ dẫn ngôn ngữ tự nhiên (ARTEMIS Instruction) | Kết quả mong đợi (Expected Result) | Loại ca kiểm | Số lần chạy & Tỷ lệ đạt |
|:---:|---|---|---|---|:---:|:---:|
| **TC-01** | FLOW-01 | App đã cài đặt, ở màn hình Login | "Nhấn nút 'Tiếp tục với Google', chọn tài khoản kiểm thử demo từ danh sách tài khoản Google trên thiết bị. Xác nhận màn hình Tổng quan xuất hiện với lời chào cá nhân hóa." | Màn hình Dashboard hiển thị; lời chào "Xin chào" xuất hiện; thanh điều hướng đáy hiển thị đủ 4 tab. | **Native** (Google Picker) | 3/3 (100%) |
| **TC-02** | FLOW-02 | Đã đăng nhập, ở Dashboard | "Bấm vào tab 'Lịch sử' ở thanh điều hướng. Nhập từ khóa 'gpt-4o' vào ô tìm kiếm. Đọc số lượng bản ghi hiển thị trên thanh trạng thái." | Danh sách hiển thị các bản ghi model gpt-4o; số lượng kết quả > 0; không có lỗi RenderFlex. | **Happy path** | 3/3 (100%) |
| **TC-03** | FLOW-02 | Đang ở tab Lịch sử | "Nhập từ khóa 'model-khong-ton-tai-xyz' vào ô tìm kiếm. Xác nhận màn hình hiển thị trạng thái rỗng và nút xóa bộ lọc." | Xuất hiện widget TsEmptyState với thông điệp không tìm thấy bản ghi; xuất hiện nút 'Xóa bộ lọc'. | **Error path** (Empty State) | 3/3 (100%) |
| **TC-04** | FLOW-02 | Đang ở tab Lịch sử có kết quả | "Chạm vào bản ghi đầu tiên trong danh sách. Xác nhận màn hình Chi tiết lượt gọi mở ra. Kiểm tra sự xuất hiện của nút sao chép mã cURL và độ trễ latency." | Màn hình UsageDetailsScreen mở ra; hiển thị 4 chỉ số (Model, Token, Cost, Latency) và ô cURL. | **Happy path** | 3/3 (100%) |
| **TC-05** | FLOW-03 | Đang ở Dashboard | "Chạm vào thẻ 'Cảnh báo ngân sách' màu vàng kem. Cuộn xuống vùng 'Điều chỉnh ngân sách'. Nhập số 50 vào ô hạn mức và bấm nút 'Lưu ngân sách'." | Màn hình BudgetScreen mở ra; hộp thoại xác nhận lưu xuất hiện; thanh hạn mức cập nhật lên $50.00. | **Happy path** | 3/3 (100%) |
| **TC-06** | FLOW-04 | Đang ở Dashboard | "Chạm vào biểu tượng quả chuông trên đầu trang. Xác nhận màn hình Trung tâm thông báo mở ra. Chạm vào thông báo đầu tiên và kiểm tra màn hình được chuyển đến." | Màn hình AlertsScreen mở ra; bấm thông báo tự động chuyển sang trang BudgetScreen. | **Happy path** | 3/3 (100%) |
| **TC-07** | FLOW-06 | Ở tab Cài đặt | "Cuộn xuống mục 'Báo cáo chi phí'. Bấm nút 'Xuất báo cáo PDF'. Chờ thanh tiến độ tải lên chạy từ 0% đến 100% và đọc đường dẫn tải xuống hiển thị." | Thanh tiến độ hiển thị và hoàn thành 100%; xuất hiện thông báo tải lên Cloud Storage thành công kèm link. | **Cloud Storage** | 3/3 (100%) |
| **TC-08** | FLOW-07 | Ở tab Cài đặt | "Bấm nút 'Cập nhật thiết lập'. Chuyển về tab 'Tổng quan'. Xác nhận sự xuất hiện của thanh biểu ngữ quảng bá màu tím ở đầu trang." | Nút làm mới hoạt động; banner promo_banner_enabled hiển thị đúng chuỗi text cấu hình từ Remote Config. | **Remote Config** | 3/3 (100%) |
| **TC-09** | FLOW-04 | App vừa cài lại hoặc mở lần đầu | "Khi ứng dụng yêu cầu cấp quyền thông báo trên Android 13+, nhấn nút 'Cho phép' trên hộp thoại hệ thống." | Hộp thoại POST_NOTIFICATIONS hệ thống được chấp nhận; Device Token được sinh và lưu trữ. | **Native** (Permission) | 3/3 (100%) |
| **TC-10** | FLOW-08 | Đang ở tab Cài đặt | "Cuộn xuống dưới cùng và nhấn nút 'Đăng xuất'. Xác nhận ứng dụng chuyển về màn hình Đăng nhập và các trường nhập liệu được làm trống." | Phiên làm việc bị xóa; màn hình LoginScreen xuất hiện; nhấn nút Back không thể quay lại trang Dashboard. | **Happy path** (Sign-out) | 3/3 (100%) |

---

## 3. Báo Cáo Phiên Kiểm Thử Khám Phá (Exploratory Testing Session)
* **Thời gian thực hiện:** 25 phút (Chạy bằng Profile Gemini Pro không theo kịch bản trước).
* **Mục tiêu:** Thử nghiệm các thao tác bất thường (vuốt nhanh liên tục, ngắt kết nối mạng bất ngờ, nhập ký tự đặc biệt vào ô tìm kiếm).
* **Các phát hiện và hành động khắc phục:**
  1. *Phát hiện 1:* Nút "Tiếp tục với GitHub" trên LoginScreen không phản hồi khi bấm $\rightarrow$ **Đã sửa:** Bổ sung SnackBar thông báo tính năng đang phát triển.
  2. *Phát hiện 2:* Nút "Tạo mới" trên màn hình ProjectsScreen không có phản hồi thị giác $\rightarrow$ **Đã sửa:** Bổ sung SnackBar hướng dẫn tự động đồng bộ khi thêm API Key.
  3. *Phát hiện 3:* Khi cuộn danh sách lịch sử gọi API trên màn hình nhỏ $360\text{dp}$, bàn phím ảo che mất nút tìm kiếm $\rightarrow$ **Đã sửa:** Sử dụng thuộc tính `physics: BouncingScrollPhysics()` và đóng bàn phím khi chạm ra ngoài.
