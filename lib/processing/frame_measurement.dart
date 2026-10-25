/// Số liệu khung UI trong một cửa sổ đo phía Dart.
///
/// Không biểu diễn thời điểm GPU thực sự hiển thị khung hình.
final class FrameStats {
  const FrameStats({required this.window, required this.frameCount});

  final Duration window;
  final int frameCount;

  double? get framesPerSecond => window.inMicroseconds == 0
      ? null
      : frameCount * Duration.microsecondsPerSecond / window.inMicroseconds;
}

/// Đếm các callback hoàn tất khung UI trong một lượt xử lý JSON.
final class FrameMeasurement {
  int _frameCount = 0;
  bool _finished = false;

  void recordFrame() {
    _ensureActive();
    _frameCount++;
  }

  FrameStats finish(Duration elapsed) {
    _ensureActive();
    _finished = true;
    return FrameStats(window: elapsed, frameCount: _frameCount);
  }

  void _ensureActive() {
    if (_finished) {
      throw StateError('Cửa sổ đo đã kết thúc.');
    }
  }
}
