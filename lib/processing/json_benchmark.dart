import 'package:flutter/scheduler.dart';

import 'frame_measurement.dart';
import 'json_processing.dart';

/// Kết quả rút gọn, không giữ danh sách JSON lớn trong trạng thái giao diện.
final class JsonBenchmarkResult {
  const JsonBenchmarkResult({required this.itemCount, required this.frames});

  final int itemCount;
  final FrameStats frames;
}

/// Điều phối một lượt parse và đo khung UI trên main isolate.
///
/// Chỉ phần parse được chuyển sang worker khi [useWorker] là true.
/// Trả null nếu màn hình đã bị hủy trước khi bắt đầu đo.
Future<JsonBenchmarkResult?> runJsonBenchmark(
  String text, {
  required bool useWorker,
  required bool Function() isActive,
}) async {
  // Chờ UI hiển thị trạng thái bận trước khi bắt đầu cửa sổ đo.
  await SchedulerBinding.instance.endOfFrame;
  if (!isActive()) return null;

  final stopwatch = Stopwatch()..start();
  final measurement = FrameMeasurement();

  try {
    _observeFrames(measurement, stopwatch, isActive);
    final List<Object?> numbers;
    if (useWorker) {
      numbers = await parseJsonInWorker(text);
    } else {
      // Gọi trực tiếp: parse vẫn chặn main isolate trong lúc thực thi.
      numbers = parseJson(text);
    }
    stopwatch.stop();
    return JsonBenchmarkResult(
      itemCount: numbers.length,
      frames: measurement.finish(stopwatch.elapsed),
    );
  } finally {
    // Lỗi parse/worker được chuyển về UI; luôn dừng cửa sổ đo.
    stopwatch.stop();
  }
}

void _observeFrames(
  FrameMeasurement measurement,
  Stopwatch clock,
  bool Function() isActive,
) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (!clock.isRunning || !isActive()) return;
    measurement.recordFrame();
    _observeFrames(measurement, clock, isActive);
  });
}
