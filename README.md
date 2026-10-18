# Chủ đề 3 — Main Thread và Isolate

Ứng dụng Flutter do nhóm thực hiện cho chủ đề **Đa luồng với Isolates** trong môn Lập trình đa nền tảng. Dự án so sánh việc bóc tách một tệp JSON hơn 15 MB theo hai cách: xử lý trực tiếp trên main isolate và xử lý trong isolate nền bằng `compute()`.

Giao diện hiển thị thời gian xử lý, số phần tử và FPS UI ước tính của mỗi cách. Vòng tròn chuyển động giúp quan sát ảnh hưởng của tác vụ nặng đến việc cập nhật giao diện.

## Yêu cầu môi trường

- Flutter SDK đi kèm Dart `>=3.13.5 <4.0.0`, theo [pubspec.yaml](pubspec.yaml). Thêm thư mục `flutter/bin` vào PATH để dùng các lệnh `flutter` và `dart`.
- **Linux:** cần Clang, CMake, Ninja, pkg-config, GTK 3 và thư viện phát triển C++. Xem [hướng dẫn thiết lập Linux](https://docs.flutter.dev/platform-integration/linux/setup).
- **Windows:** cần Visual Studio với workload **Desktop development with C++**. Có thể dùng VS Code để soạn thảo; bộ công cụ C++ của Visual Studio phục vụ việc build. Xem [hướng dẫn thiết lập Windows](https://docs.flutter.dev/platform-integration/windows/setup).

Dự án có cấu hình nền tảng cho Linux và Windows. Hai nền tảng dùng chung mã Dart trong thư mục `lib`.

## Cài đặt và chạy

### 1. Chuẩn bị dự án

Tải hoặc clone source code, giải nén nếu cần, rồi mở thư mục `isolate_demo`. Mở Terminal tại thư mục chứa `pubspec.yaml` và kiểm tra môi trường:

```bash
flutter --version
flutter doctor -v
```

Hoàn tất các thành phần còn thiếu của nền tảng cần chạy trong kết quả `flutter doctor`, sau đó tải dependency:

```bash
flutter pub get
```

### 2. Kiểm tra dữ liệu đầu vào

Tệp [assets/large_numbers.json](assets/large_numbers.json) có sẵn trong source, gồm **3.000.000 số**, từ `0` đến `2999999`. Dung lượng là **22.888.891 byte**, khoảng **22,89 MB**, đáp ứng yêu cầu JSON lớn hơn 15 MB của đề.

Nếu thiếu tệp này, tạo lại trước khi chạy ứng dụng:

```bash
dart tool/generate_json.dart
```

### 3. Chạy ứng dụng

Sử dụng chế độ profile để so sánh hiệu năng.

Trên Linux:

```bash
flutter run -d linux --profile
```

Trên Windows:

```powershell
flutter run -d windows --profile
```

Ứng dụng đọc dữ liệu từ tệp JSON local nên không cần cấu hình `.env`, `google-services.json` hay tài khoản dịch vụ. Sau khi đã tải đủ dependency và công cụ build, demo có thể chạy offline.

## Sử dụng

Đợi ứng dụng báo **Sẵn sàng**. Phía trên có dung lượng JSON, nhãn chế độ chạy và vòng tròn chuyển động; bên dưới là hai thẻ **Main Thread** và **Isolate**.

1. Bấm **Xử lý trên Main Thread**, quan sát vòng tròn trong lúc ứng dụng parse JSON rồi đọc kết quả.
2. Bấm **Xử lý bằng Isolate**, tiếp tục quan sát vòng tròn và so sánh với lần trước.
3. Kiểm tra cả hai thẻ đều trả về cùng số phần tử. Với dữ liệu mặc định, kết quả là `3000000 phần tử`.

Hai nút được khoá trong lúc có tác vụ để tránh chạy chồng lượt đo. Mỗi thẻ giữ kết quả gần nhất, gồm **FPS UI ước tính**, **thời gian xử lý**, **số phần tử** và **số khung UI**.

Nhãn **Main Thread** bám theo cách gọi trong đề: nhánh này parse trực tiếp trên main isolate đang phục vụ UI. Nhánh **Isolate** dùng `compute()` để parse trong một isolate khác trên Linux hoặc Windows. Trong mô hình Dart, main isolate cũng là một isolate.

Khi thu số liệu, chạy thử mỗi nhánh một lượt trước, sau đó ghi ít nhất ba lượt cho mỗi cách và đổi thứ tự chạy. Giữ cùng dữ liệu, cùng máy, cùng chế độ profile và để cửa sổ ứng dụng ở phía trước. Nếu chuyển máy hoặc đổi nền tảng, cần đo lại trên môi trường đó.

## Cấu trúc dự án

```text
isolate_demo/
├── lib/
│   ├── main.dart                 # Khởi động và cấu hình MaterialApp
│   ├── processing/               # TV1: dữ liệu, xử lý và đo hiệu năng
│   │   ├── json_processing.dart  # Đọc JSON, parse trực tiếp và qua compute()
│   │   ├── json_benchmark.dart   # Điều phối lượt xử lý, đo thời gian/khung UI
│   │   └── frame_measurement.dart # Đếm khung UI và tính FPS ước tính
│   └── presentation/             # TV2: giao diện và trạng thái
│       ├── app_ui.dart           # Màu sắc, bố cục và các thẻ kết quả
│       └── json_demo_page.dart   # State, gọi module TV1 và cập nhật UI
├── assets/
│   └── large_numbers.json       # Dữ liệu đầu vào
├── tool/
│   └── generate_json.dart       # Sinh lại tệp JSON
├── docs/
│   └── PHAN_CONG_MA_NGUON.md     # Tệp, hàm và phạm vi commit của mỗi thành viên
├── linux/                       # Mã khởi động và cấu hình build Linux
├── windows/                     # Mã khởi động và cấu hình build Windows
├── analysis_options.yaml        # Cấu hình phân tích mã Dart
├── pubspec.yaml
└── pubspec.lock
```

## Cách hoạt động

[main.dart](lib/main.dart) khởi động ứng dụng và mở màn hình demo. Màu sắc, bố cục và các thẻ kết quả nằm trong [app_ui.dart](lib/presentation/app_ui.dart).

Hai nút cùng gọi `_processJson` trong [json_demo_page.dart](lib/presentation/json_demo_page.dart). Tệp này quản lý trạng thái, gọi `runJsonBenchmark()` rồi đưa kết quả hoặc lỗi cho giao diện hiển thị. Việc điều phối lượt xử lý và đo hiệu năng nằm trong [json_benchmark.dart](lib/processing/json_benchmark.dart); đọc asset, xác định dung lượng, bóc tách JSON và gọi `compute()` nằm trong [json_processing.dart](lib/processing/json_processing.dart).

Trước khi bật nút, giao diện gọi `loadJsonInput()` để nhận chuỗi JSON đã đọc sẵn cùng dung lượng tính bằng byte. Khi bấm nút, giao diện gọi:

```dart
result = await runJsonBenchmark(
  text,
  useWorker: useWorker,
  isActive: () => mounted,
);
```

Trong `runJsonBenchmark()`, phần chọn cách xử lý là:

```dart
if (useWorker) {
  numbers = await parseJsonInWorker(text);
} else {
  numbers = parseJson(text);
}
```

`parseJsonInWorker()` gọi `compute(parseJson, text)` và giữ tên worker `parse_json_worker`. Cả hai cách dùng cùng hàm `parseJson` và cùng chuỗi JSON đã đọc sẵn. Hàm parse chỉ nhận dữ liệu, bóc tách mảng JSON rồi trả danh sách về; mỗi lượt bấm thực hiện việc này đúng một lần. Ở nhánh `compute()`, main isolate nhận kết quả rồi mới gọi `setState` cập nhật màn hình.

Các hàm xử lý dữ liệu chuyển lỗi về bên gọi. Phần hiển thị lỗi và ghi log vẫn thuộc giao diện. Việc tách tệp giúp phân chia trách nhiệm; vị trí thực thi vẫn phụ thuộc vào cách gọi trực tiếp hoặc qua `compute()`.

`async` và `await` tổ chức việc chờ kết quả. Ở nhánh Isolate, chính `compute()` chuyển công việc sang isolate nền. Hàm parse vẫn chạy đồng bộ trên main isolate nếu được gọi trực tiếp.

Giao diện dùng `setState` để quản lý trạng thái tải dữ liệu, trạng thái bận và hai kết quả. Khi tải hoặc parse lỗi, ứng dụng hiển thị thông báo và ghi lỗi kèm stack trace. Các bước cập nhật UI sau khi chờ đều kiểm tra `mounted`; callback đo khung ngừng đăng ký tiếp khi tác vụ kết thúc hoặc màn hình bị huỷ.

## Đo hiệu năng

Ứng dụng đọc tệp JSON một lần trước khi bật hai nút. Khi bấm xử lý, ứng dụng hiển thị trạng thái bận, đợi xong khung UI đó rồi mới bắt đầu đo. Đồng hồ dừng ngay sau khi có danh sách kết quả, trước bước cập nhật kết quả lên màn hình.

**Thời gian xử lý** được đo bằng `Stopwatch`. Với nhánh Isolate, số này bao gồm cả khởi tạo isolate, giao việc, parse và nhận kết quả. Thời gian đọc tệp ban đầu nằm ngoài khoảng đo của cả hai nhánh.

**FPS UI ước tính** được tính trong [frame_measurement.dart](lib/processing/frame_measurement.dart):

```text
FPS UI = số khung UI hoàn tất / thời gian tác vụ tính bằng giây
```

Các khung được ghi nhận qua `addPostFrameCallback` trong `_observeFrames` của [json_benchmark.dart](lib/processing/json_benchmark.dart). Bộ đo chạy trên main isolate cho cả hai nhánh; chỉ phần parse được chuyển sang worker. Callback ngừng đăng ký tiếp khi tác vụ kết thúc hoặc màn hình bị hủy, theo hàm `isActive` do UI truyền vào. Đây là phép đếm phía Dart sau phần dựng khung của Flutter, không đo trực tiếp thời điểm GPU hiển thị ảnh trên màn hình. Nếu tác vụ ngắn, nhất là dưới nửa giây, số mẫu khung ít nên FPS có thể dao động. Khi so sánh, đọc cùng thời gian và số khung, thay vì chỉ nhìn một con số FPS.

Lưu ý khi đọc kết quả:

- **Main Thread có thể hiện 0 FPS:** trong khoảng parse đồng bộ, nếu không có callback khung UI nào hoàn tất thì số khung ghi nhận bằng 0. Ứng dụng vẫn có khung hình trước và sau tác vụ; con số này chỉ nói về khoảng đang đo.
- **Isolate có thời gian lớn hơn Main Thread:** chuyển việc sang isolate nền có thêm chi phí phối hợp. Lợi ích cần quan sát ở demo là main isolate có thể tiếp tục tạo khung UI trong lúc chờ, chứ thời gian nhận kết quả không được đảm bảo sẽ giảm.

Để kiểm tra chi tiết, mở đường dẫn **DevTools** trong Terminal khi chạy profile, vào **Performance**, ghi lại một lượt cho từng nút rồi so sánh timeline. Isolate xử lý JSON được đặt tên `parse_json_worker` trong code. Đối chiếu số liệu trên ứng dụng với timeline và chuyển động thực tế của vòng tròn.

## Phát triển

Phần dữ liệu, xử lý và bộ đo trong `lib/processing/`, script sinh dữ liệu và asset do **TV1** phụ trách. `main.dart`, giao diện và trạng thái trong `lib/presentation/` do **TV2** phụ trách. **Slide/Báo cáo do cả hai cùng thực hiện.** Chi tiết tệp, hàm, cấu hình dùng chung và phạm vi commit nằm trong [Phân công mã nguồn](docs/PHAN_CONG_MA_NGUON.md).

Khi sửa giao diện hoặc logic, chạy ở debug mode bằng cách bỏ `--profile` khỏi lệnh chạy. Trong Terminal đang chạy Flutter, nhấn `r` để hot reload, `R` để hot restart và `q` để dừng. Profile mode không hỗ trợ hot reload/hot restart; sau khi sửa code cần dừng rồi chạy lại.

Các lệnh kiểm tra mã nguồn:

```bash
dart format lib tool
flutter analyze
```

## Tài liệu tham khảo

- [Dart — Isolates và giao tiếp qua ports](https://dart.dev/language/isolates)
- [Flutter — compute()](https://api.flutter.dev/flutter/foundation/compute.html)
- [Flutter — Phân tích hiệu năng giao diện](https://docs.flutter.dev/perf/ui-performance)
- [Flutter — addPostFrameCallback](https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addPostFrameCallback.html)
- [Flutter — Các chế độ chạy ứng dụng](https://docs.flutter.dev/testing/build-modes)
