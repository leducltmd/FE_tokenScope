# Biên Bản Rà Soát Mã Nguồn Bằng Trí Tuệ Nhân Tạo (AI Code Review Record)
> **Môn học:** PRM393 - Lập trình Di động (Lab 3)  
> **Dự án:** TokenScope — AI Token & Cost Management Platform  
> **Công cụ rà soát:** CodeRabbit & GitHub Copilot Code Review  
> **Phạm vi rà soát:** Toàn bộ Pull Request tính năng tích hợp Firebase Cloud & Kiến trúc MVVM  

---

## 1. Bảng Ghi Nhận 5 Phát Hiện Của AI (Findings & Decision Matrix)

| Mã ID | Công cụ AI | Tệp & Dòng mã (File:Line) | Nhóm vấn đề (Kind) | Tóm tắt phát hiện (Finding Summary) | Quyết định (Decision) | Lý do kỹ thuật (Technical Reason) | Commit khắc phục |
|:---:|---|---|:---:|---|:---:|---|:---:|
| **CR-01** | CodeRabbit | `lib/screens/auth/login_screen.dart:206` | **Bug / Usability** | Nút "Tiếp tục với GitHub" có hàm `onPressed: () {}` rỗng, gây hiểu nhầm ứng dụng bị đơ/treo khi người dùng bấm vào. | **Accepted** | Cần đảm bảo mọi nút bấm đều có phản hồi thị giác rõ ràng cho người dùng theo nguyên tắc Nielsen Heuristic #1. | `fix(auth): add snackbar feedback for github login button (CR-01)` |
| **CR-02** | SonarQube | `lib/screens/projects/projects_screen.dart:247` | **Bug / Usability** | Nút "Tạo mới" dự án sử dụng hàm `onTap: _noop` không có hành động cụ thể. | **Accepted** | Đảm bảo tính nhất quán của giao diện; thông báo cho người dùng biết dự án sẽ được tự động đồng bộ khi thêm API Key mới. | `fix(projects): handle create and filter buttons in projects screen (CR-02)` |
| **CR-03** | CodeRabbit | `lib/services/firebase_storage_service.dart:45` | **Security** | Cần kiểm tra kỹ đường dẫn tải lên tệp PDF để đảm bảo luôn nằm dưới thư mục `reports/{uid}/...` tránh ghi đè dữ liệu người dùng khác. | **Accepted** | Tuân thủ nghiêm ngặt quy tắc bảo mật phân quyền trong `firebase/storage.rules` (chỉ cho phép user đọc/ghi thư mục của chính mình). | `fix(storage): enforce per-user path security for pdf reports (CR-03)` |
| **CR-04** | Copilot | `lib/services/api_usage_history_service.dart:32` | **Performance** | Đề xuất cache toàn bộ dữ liệu lịch sử gọi API vào bộ nhớ RAM cục bộ trong 10 phút để giảm tải số lần gọi mạng HTTP. | **Rejected** | Số liệu token và chi phí AI là dữ liệu thời gian thực (Realtime Stream). Nếu cache 10 phút, người dùng sẽ không quan sát được các lượt gọi API mới phát sinh. | — *(Bảo lưu cơ chế live)* |
| **CR-05** | SonarQube | `lib/screens/dashboard/widgets/hero_metric_card.dart:28` | **Maintainability** | Khối widget HeroMetricCard có kích thước lớn, nên tách nhỏ các thành phần con thành các sub-widgets riêng biệt. | **Modified** | Đã tách thanh phân bổ Input/Output token thành sub-widget tái sử dụng nhưng giữ nguyên cấu trúc container tổng thể để tránh rebuild phân mảnh. | `refactor(dashboard): modularize hero metric card components (CR-05)` |

---

## 2. Minh Chứng Sửa Lỗi Trong Commit (Traceable Commits)

Toàn bộ 3 phát hiện được chấp nhận (`CR-01`, `CR-02`, `CR-03`) đã được xử lý độc lập và kiểm chứng không ảnh hưởng đến giao diện gốc:
1. **CR-01 (LoginScreen):** Bổ sung hiển thị SnackBar thông báo *"Tính năng đăng nhập với GitHub đang được phát triển"* thay vì để hàm trống.
2. **CR-02 (ProjectsScreen):** Thay thế hàm `_noop` bằng `_handleCreateProject` và `_handleFilterProvider('OpenAI')` giúp người dùng nhận được phản hồi tức thì.
3. **CR-03 (StorageService):** Khẳng định tính an toàn của định dạng đường dẫn `reports/${uid}/tokenscope_cost_report_${timestamp}.pdf` khớp với `storage.rules`.

---

## 3. Bản Tuyên Bố Sử Dụng Công Cụ Trí Tuệ Nhân Tạo (AI Disclosure Statement)

Tuân thủ quy định liêm chính học thuật (Academic Integrity), nhóm công khai danh sách các công cụ AI được sử dụng trong quá trình thực hiện Lab 3:

| Tên công cụ AI | Nhà phát triển | Mục đích sử dụng cụ thể trong dự án |
|---|---|---|
| **Google Stitch & Figma AI** | Google / Figma | Hỗ trợ tạo layout giao diện ban đầu và chuẩn hóa Design Tokens ở giai đoạn Lab 2. |
| **CodeRabbit** | CodeRabbit AI | Rà soát tự động Pull Request, phát hiện các điểm nghẽn kiến trúc và lỗi rỗng handler. |
| **GitHub Copilot** | GitHub / OpenAI | Gợi ý mã nguồn boilerplate cho các mô hình dữ liệu Dart `fromJson` / `toJson`. |
| **Antigravity Assistant** | Google DeepMind | Hỗ trợ phân tích mã nguồn toàn diện, đối chiếu rubric và tạo tài liệu kiểm thử. |
