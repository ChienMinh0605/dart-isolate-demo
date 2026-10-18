import 'package:flutter/material.dart';

import 'presentation/app_ui.dart';
import 'presentation/json_demo_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'So sánh Main Thread và Isolate',
      debugShowCheckedModeBanner: false,
      theme: createDemoTheme(),
      home: const JsonDemoPage(),
    );
  }
}
