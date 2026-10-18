import 'dart:io';

// Chạy trước khi mở app. Không sinh dữ liệu trong lúc đo hiệu năng.
// Mặc định: 3 triệu số, từ 0 đến 2.999.999, khoảng 22,89 MB.
void main(List<String> arguments) {
  final count = arguments.isEmpty ? 3000000 : int.tryParse(arguments.first);
  if (arguments.length > 1 || count == null || count < 1) {
    stderr.writeln(
      'Cách dùng: dart tool/generate_json.dart [số_phần_tử_dương]',
    );
    exitCode = 64;
    return;
  }

  final file = File.fromUri(
    Platform.script.resolve('../assets/large_numbers.json'),
  );
  file.parent.createSync(recursive: true);
  final output = file.openSync(mode: FileMode.write);
  try {
    output.writeStringSync('[');
    final chunk = StringBuffer();
    for (var number = 0; number < count; number++) {
      if (number > 0) {
        chunk.write(',');
      }
      chunk.write(number);
      if (number % 10000 == 9999) {
        output.writeStringSync(chunk.toString());
        chunk.clear();
      }
    }
    output.writeStringSync(chunk.toString());
    output.writeStringSync(']');
  } finally {
    output.closeSync();
  }

  final byteCount = file.lengthSync();
  stdout.writeln('Đã tạo $count phần tử tại ${file.path}');
  stdout.writeln(
    '$byteCount byte = ${(byteCount / 1000000).toStringAsFixed(2)} MB',
  );
}
