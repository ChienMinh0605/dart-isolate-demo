import 'dart:async';

import 'package:flutter/material.dart';

import '../processing/json_benchmark.dart';
import '../processing/json_processing.dart';
import 'app_ui.dart';

class JsonDemoPage extends StatefulWidget {
  const JsonDemoPage({super.key});

  @override
  State<JsonDemoPage> createState() => _JsonDemoPageState();
}

class _JsonDemoPageState extends State<JsonDemoPage> {
  String? _jsonText;
  String _inputInfo = 'Đang tải JSON…';
  String _status = 'Đang chuẩn bị dữ liệu';
  bool _isProcessing = false;
  JsonBenchmarkResult? _mainResult;
  JsonBenchmarkResult? _workerResult;
  String? _mainError;
  String? _workerError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadJson());
  }

  // Nạp dữ liệu trước phép đo. Có chuỗi JSON mới cho phép bấm nút xử lý.
  Future<void> _loadJson() async {
    try {
      final input = await loadJsonInput();
      if (!mounted) return;
      setState(() {
        _jsonText = input.text;
        _inputInfo =
            'JSON · ${(input.byteCount / 1000000).toStringAsFixed(2)} MB';
        _status = 'Sẵn sàng';
      });
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, 'khi tải dữ liệu JSON cho demo');
      if (!mounted) return;
      setState(() {
        _inputInfo = 'Không đọc được dữ liệu: $error';
        _status = 'Kiểm tra tệp assets/large_numbers.json và pubspec.yaml.';
      });
    }
  }

  Future<void> _processJson({required bool useWorker}) async {
    final text = _jsonText;
    if (text == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = useWorker ? 'Isolate đang xử lý…' : 'Main Thread đang xử lý…';
      if (useWorker) {
        _workerError = null;
      } else {
        _mainError = null;
      }
    });

    JsonBenchmarkResult? result;
    String? errorMessage;
    try {
      result = await runJsonBenchmark(
        text,
        useWorker: useWorker,
        isActive: () => mounted,
      );
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, 'khi xử lý JSON trong demo');
      errorMessage = 'Không xử lý được JSON: $error';
    } finally {
      if (mounted) {
        // Chốt kết quả/lỗi và mở lại nút trong cùng một lần cập nhật trạng thái.
        setState(() {
          if (useWorker) {
            _workerResult = result;
            _workerError = errorMessage;
          } else {
            _mainResult = result;
            _mainError = errorMessage;
          }
          _isProcessing = false;
          _status = 'Sẵn sàng';
        });
      }
    }
  }

  void _reportError(Object error, StackTrace stackTrace, String context) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        context: ErrorDescription(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canProcess = _jsonText != null && !_isProcessing;
    return JsonDemoView(
      inputInfo: _inputInfo,
      status: _status,
      mainResult: _mainResult,
      workerResult: _workerResult,
      mainError: _mainError,
      workerError: _workerError,
      onProcess: canProcess
          ? (useWorker) => unawaited(_processJson(useWorker: useWorker))
          : null,
    );
  }
}
