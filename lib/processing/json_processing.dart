import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dữ liệu đầu vào đã đọc sẵn, dùng chung cho hai cách xử lý.
final class JsonInput {
  const JsonInput({required this.text, required this.byteCount});

  final String text;
  final int byteCount;
}

/// Đọc JSON và xác định dung lượng trước khi bắt đầu một lượt đo.
Future<JsonInput> loadJsonInput() async {
  final text = await rootBundle.loadString(
    'assets/large_numbers.json',
    cache: false,
  );
  return JsonInput(text: text, byteCount: utf8.encode(text).length);
}

/// Bóc tách mảng JSON ngay trên isolate gọi hàm.
///
/// Ném [FormatException] nếu JSON không hợp lệ hoặc không phải một mảng.
/// Hàm chỉ xử lý dữ liệu, không phụ thuộc widget hay trạng thái giao diện.
List<Object?> parseJson(String text) {
  final Object? decoded = jsonDecode(text);
  if (decoded is! List<Object?>) {
    throw const FormatException('Dữ liệu JSON phải là một mảng.');
  }
  return decoded;
}

/// Dùng cùng hàm parse trong worker isolate trên nền tảng native.
///
/// Trả kết quả hoặc chuyển lỗi về bên gọi để giao diện xử lý.
/// Trên Flutter web, compute chạy trên event loop hiện tại.
Future<List<Object?>> parseJsonInWorker(String text) {
  return compute(parseJson, text, debugLabel: 'parse_json_worker');
}
