# Kế Hoạch Đo Lường Firebase Analytics (TokenScope)

> **Mã môn:** PRM393 - Lập trình Di động  
> **Dự án:** TokenScope - Nền tảng giám sát chi phí và mức sử dụng API AI  
> **Mục tiêu:** Đo lường hành vi người dùng, luồng thao tác chính và tỷ lệ hoàn thành tác vụ trong ứng dụng mà không thu thập dữ liệu định danh cá nhân (PII).

---

## 1. Nguyên Tắc Thu Thập Dữ Liệu
1. **Tuân thủ quyền riêng tư (Không chứa PII):** Tuyệt đối không gửi họ tên, email, mật khẩu hoặc khóa API bí mật vào tham số sự kiện.
2. **Quy chuẩn đặt tên:** 
   - Ưu tiên các sự kiện chuẩn do Firebase khuyến nghị (`login`, `screen_view`, `search`).
   - Các sự kiện tùy chỉnh sử dụng định dạng `snake_case` (chữ thường nối bằng dấu gạch dưới).
3. **Định danh người dùng:** Gọi `setUserId(user.id)` ngay sau khi đăng nhập thành công.

---

## 2. Danh Sách 7 Sự Kiện Đo Lường Bắt Buộc

| STT | Tên sự kiện (`event_name`) | Thời điểm kích hoạt | Các tham số (`parameters`) | Câu hỏi sản phẩm / Mục tiêu đo lường |
| :---: | :--- | :--- | :--- | :--- |
| **1** | `login` *(Khuyến nghị)* | Khi người dùng đăng nhập thành công | `method`: `"google"` \| `"password"` | Phương thức xác thực nào được ưa chuộng hơn? |
| **2** | `logout` *(Khuyến nghị)* | Khi người dùng bấm đăng xuất | `screen`: `"settings"` | Tần suất người dùng chủ động thoát phiên làm việc? |
| **3** | `connect_provider` *(Tùy chỉnh)* | Khi kết nối thành công 1 nhà cung cấp AI mới | `provider_type`: `"openai"` \| `"google"` \| `"anthropic"`<br>`has_admin_key`: `true` \| `false` | Nhà cung cấp AI nào được các lập trình viên kết nối nhiều nhất? |
| **4** | `view_usage_history` *(Tùy chỉnh)* | Khi mở tab Lịch sử sử dụng | `total_records`: `int`<br>`filter_provider`: `"all"` \| `"openai"` \| `"google"` | Người dùng có thường xuyên kiểm tra chi tiết các lượt gọi không? |
| **5** | `view_usage_detail` *(Tùy chỉnh)* | Khi chạm vào một bản ghi cụ thể | `model`: `string` *(vd: "gemini-2.5-flash")*<br>`is_success`: `true` \| `false`<br>`latency_bucket`: `"<1s"` \| `"1-3s"` \| `">3s"` | Các mô hình AI nào phát sinh nhiều lượt tra cứu chi tiết nhất? |
| **6** | `export_report` *(Tùy chỉnh)* | Khi xuất và tải lên báo cáo PDF đám mây | `format`: `"pdf"`<br>`file_size_kb`: `int`<br>`storage_destination`: `"firebase_storage"` | Tính năng báo cáo chi phí có được người dùng quan tâm sử dụng? |
| **7** | `update_budget` *(Tùy chỉnh)* | Khi lưu cài đặt ngân sách hoặc ngưỡng cảnh báo | `has_limit`: `true` \| `false`<br>`warning_percent`: `int` *(vd: 80)* | Người dùng thường đặt ngưỡng cảnh báo chi tiêu ở mức bao nhiêu? |

---

## 3. Hướng Dẫn Kiểm Thử Bằng Analytics DebugView
Để kiểm tra các sự kiện theo thời gian thực (Realtime DebugView), thực hiện lệnh ADB sau trên máy ảo Android:

```powershell
adb shell setprop debug.firebase.analytics.app com.tokenscope.tokenscope
```

Sau khi chạy lệnh trên:
1. Mở **Firebase Console** $\rightarrow$ **Analytics** $\rightarrow$ **DebugView**.
2. Thực hiện các thao tác trên app (Đăng nhập, Kết nối Provider, Xem lịch sử, Xuất PDF).
3. Các sự kiện trên sẽ xuất hiện từng giây trên timeline của DebugView kèm theo đầy đủ tham số.
