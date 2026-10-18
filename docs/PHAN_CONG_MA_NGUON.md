# Phân công mã nguồn — Chủ đề 3

**TV1:** dữ liệu, Business Logic và đo hiệu năng. **TV2 (bạn):** UI Design và State Management. Cả hai cùng làm Slide/Báo cáo.

Đây là phạm vi mỗi người tiếp nhận và hoàn thiện từ bản demo chung hiện có. Khi commit, mỗi người dùng tài khoản của mình và mô tả đúng phần đã rà soát, kiểm tra hoặc chỉnh sửa. Tỷ lệ 50/50 là dự kiến, không suy ra từ số dòng hoặc số commit.

## 1. Tệp của từng thành viên

| Người phụ trách | Tệp / thư mục | Nội dung |
|---|---|---|
| TV1 | `lib/processing/json_processing.dart` | Đọc JSON, xác định dung lượng; parse trực tiếp và qua `compute()`; kiểm tra dữ liệu và chuyển ngoại lệ về bên gọi. |
| TV1 | `lib/processing/json_benchmark.dart` | Điều phối lượt xử lý, đo thời gian, theo dõi khung UI và trả kết quả rút gọn. |
| TV1 | `lib/processing/frame_measurement.dart` | Đếm khung UI và tính FPS UI ước tính trong cửa sổ đo. |
| TV1 | `tool/generate_json.dart` | Sinh tệp JSON, nhận số phần tử từ dòng lệnh, ghi dữ liệu theo từng đợt. |
| TV1 | `assets/large_numbers.json` | Đầu vào dùng chung; mặc định 3.000.000 số, 22.888.891 byte. |
| TV2 | `lib/main.dart` | Khởi động ứng dụng và cấu hình `MaterialApp`. |
| TV2 | `lib/presentation/app_ui.dart` | Theme đỏ nhạt, bố cục, vòng tròn chuyển động, nút, thẻ kết quả và thông báo lỗi. |
| TV2 | `lib/presentation/json_demo_page.dart` | Trạng thái tải/bận/kết quả/lỗi; gọi module TV1; khóa thao tác; kiểm tra vòng đời và cập nhật UI. |

`frame_measurement.dart` đã chuyển từ `presentation/` sang `processing/`. Đồng hồ, callback thu khung và nhánh chọn main/worker đã chuyển khỏi màn hình sang `json_benchmark.dart`. `main.dart` vẫn ở vị trí mặc định của Flutter.

## 2. TV1 cần nắm những gì?

### Dữ liệu và parse — json_processing.dart

- `JsonInput`: giữ chuỗi JSON và dung lượng tính bằng byte.
- `loadJsonInput()`: đọc asset một lần trước các lượt đo, tính dung lượng UTF-8.
- `parseJson(text)`: gọi `jsonDecode`, kiểm tra kết quả là mảng, trả danh sách. Gọi trực tiếp thì hàm chạy trên isolate đang gọi, trong demo là main isolate.
- `parseJsonInWorker(text)`: gọi `compute(parseJson, text)` để chạy cùng hàm parse trong worker isolate trên Linux/Windows.

### Điều phối và kết quả — json_benchmark.dart

- `runJsonBenchmark()`: đợi UI dựng xong trạng thái bận, kiểm tra màn hình còn hoạt động, bắt đầu đồng hồ và theo dõi khung, gọi đúng hàm parse, dừng đồng hồ rồi trả thống kê.
- `JsonBenchmarkResult`: chỉ giữ số phần tử và `FrameStats`; không giữ danh sách JSON lớn trong UI.
- `_observeFrames()`: đăng ký callback khung khi lượt đo đang chạy và màn hình còn hoạt động.
- `finally`: dừng đồng hồ cả khi parse/worker phát sinh lỗi. Ngoại lệ được chuyển về TV2 để hiển thị.

### Bộ đếm — frame_measurement.dart

- `FrameMeasurement`: nhận số khung đã quan sát và chốt cửa sổ đo.
- `FrameStats`: giữ thời gian, số khung và tính FPS UI ước tính.

Bộ đo luôn chạy trên main isolate, kể cả nhánh worker. Chỉ phần parse được đưa sang isolate nền. Thời gian đo không gồm đọc tệp; thời gian worker có cả khởi tạo isolate, giao việc, parse và nhận kết quả. FPS là ước tính từ callback phía Dart, không phải phép đo trực tiếp GPU/màn hình.

`tool/generate_json.dart` tạo dữ liệu trước khi chạy app. Khi thay dữ liệu, giữ dung lượng trên 15 MB để đáp ứng đề.

## 3. TV2 cần nắm những gì?

Trong `lib/presentation/json_demo_page.dart`:

- `_loadJson()`: gọi `loadJsonInput()`, sau đó lưu chuỗi và cập nhật thông tin/trạng thái tải.
- `_processJson()`: ngăn thao tác chồng, cập nhật trạng thái bận, gọi `runJsonBenchmark()`, nhận kết quả hoặc lỗi rồi mở lại nút.
- `isActive: () => mounted`: cho bộ đo biết màn hình còn hoạt động. TV2 cũng kiểm tra `mounted` trước khi cập nhật state sau bước chờ.
- `_reportError()`: ghi log kèm stack trace; thông báo lỗi được đưa vào state để hiển thị.
- `build()`: truyền trạng thái và callback vào `JsonDemoView`.

`app_ui.dart` chứa theme và các widget trình bày. TV2 hiển thị `JsonBenchmarkResult` do TV1 trả về, không cài đặt lại phép đo hoặc hàm parse.

## 4. Hai phần nối với nhau ở đâu?

TV2 gọi hàm đọc dữ liệu trước khi bật nút:

```dart
final input = await loadJsonInput();
```

Khi người dùng bấm nút, TV2 gọi:

```dart
result = await runJsonBenchmark(
  text,
  useWorker: useWorker,
  isActive: () => mounted,
);
```

TV1 chọn hàm parse theo `useWorker`, đo và trả kết quả hoặc chuyển lỗi về. TV2 quyết định trạng thái/hiển thị. Hai nhánh luôn dùng cùng chuỗi đã đọc sẵn và cùng hàm parse.

Nếu màn hình bị hủy trước khi bắt đầu đo, hàm trả `null`. Khi màn hình bị hủy trong lúc worker chạy, callback thu khung ngừng đăng ký tiếp và TV2 không cập nhật UI; việc này không hủy công việc worker đang thực hiện.

## 5. Cấu hình và tài liệu dùng chung

| Nhóm tệp | Cách phối hợp |
|---|---|
| `.gitignore`, `.metadata`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml` | TV2 đưa cấu hình chung vào repo đầu tiên; TV1 rà soát khai báo asset và dependency. |
| `linux/`, `windows/` | TV2 tích hợp scaffold Flutter. Chỉ ghi nền tảng đã kiểm chứng sau khi có người chạy thật. |
| `README.md`, `docs/PHAN_CONG_MA_NGUON.md` | Cả hai rà soát; ai chỉnh nội dung thì commit thay đổi đó. |
| Slide/Báo cáo | Cả hai thực hiện và commit phần nội dung thực tế mình chỉnh sửa. |

Không đưa SDK, `build/`, `.dart_tool/`, `.idea/` hoặc thư mục `ephemeral` lên repo; giữ các `.gitignore` hiện có.

## 6. Bàn giao và commit

Gửi TV1 bản source đầy đủ để họ chạy được app và hiểu chỗ tích hợp. **Phần lập trình TV1 tiếp nhận gồm toàn bộ `lib/processing/`, script sinh dữ liệu và asset.** TV1 đọc, chạy thử và hoàn thiện phần mình trước khi commit.

Các lệnh dưới đây chạy trong bản clone repo của từng người, sau khi đã có cấu hình Flutter chung và đưa đúng tệp vào bản clone. Việc tách mã local chưa tạo commit nào.

TV1 stage dữ liệu, xử lý và bộ đo:

```bash
git add lib/processing/json_processing.dart lib/processing/json_benchmark.dart lib/processing/frame_measurement.dart tool/generate_json.dart assets/large_numbers.json
git diff --cached --stat
git status --short
```

TV2 stage khởi động, giao diện và trạng thái:

```bash
git add lib/main.dart lib/presentation/app_ui.dart lib/presentation/json_demo_page.dart
git diff --cached --stat
git status --short
```

Đọc lại phần đã stage rồi mới `git commit`; đặt thông điệp theo công việc thực tế. Tài liệu và cấu hình stage riêng khi đã hoàn thiện. Tránh `git add .` trong bước chia phần.

TV2 có thể push UI/state lên nhánh riêng `chien-ui-state` trước khi TV1 upload. Nhánh này chưa chạy độc lập do còn thiếu module/asset TV1. Khi đủ cả hai phần, nhóm review, kiểm tra tích hợp rồi ghép vào nhánh chính dùng để nộp.

Kiểm tra sau khi ghép:

```bash
flutter pub get
dart format lib tool
flutter analyze
flutter run -d linux --profile
```

Trên Windows, thay lệnh cuối bằng `flutter run -d windows --profile`. Xác nhận cả hai nút trả cùng số phần tử và cập nhật kết quả; quan sát vòng tròn khi từng nhánh xử lý.
