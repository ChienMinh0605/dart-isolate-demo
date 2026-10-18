import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../processing/json_benchmark.dart';

ThemeData createDemoTheme() {
  final colors =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFC56671),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFFA94455),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFFBE4E7),
        onPrimaryContainer: const Color(0xFF763442),
        surface: const Color(0xFFFFF9F9),
        onSurface: const Color(0xFF392D31),
        onSurfaceVariant: const Color(0xFF78666D),
        outlineVariant: const Color(0xFFEEDDE1),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class JsonDemoView extends StatelessWidget {
  const JsonDemoView({
    super.key,
    required this.inputInfo,
    required this.status,
    required this.mainResult,
    required this.workerResult,
    required this.mainError,
    required this.workerError,
    required this.onProcess,
  });

  final String inputInfo;
  final String status;
  final JsonBenchmarkResult? mainResult;
  final JsonBenchmarkResult? workerResult;
  final String? mainError;
  final String? workerError;
  final ValueChanged<bool>? onProcess;

  _ResultCard _buildCard({required bool useWorker}) {
    final process = onProcess;
    return _ResultCard(
      title: useWorker ? 'Isolate' : 'Main Thread',
      buttonLabel: useWorker ? 'Xử lý bằng Isolate' : 'Xử lý trên Main Thread',
      result: useWorker ? workerResult : mainResult,
      error: useWorker ? workerError : mainError,
      onPressed: process == null ? null : () => process(useWorker),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mode = kProfileMode ? 'PROFILE' : (kDebugMode ? 'DEBUG' : 'RELEASE');
    final mainCard = _buildCard(useWorker: false);
    final workerCard = _buildCard(useWorker: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Thread và Isolate'),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.data_object_rounded, size: 18),
                      label: Text(inputInfo),
                      side: BorderSide(color: colors.outlineVariant),
                      backgroundColor: Colors.white,
                    ),
                    Chip(
                      label: Text(mode),
                      side: BorderSide.none,
                      backgroundColor: colors.primaryContainer,
                      labelStyle: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        // Vòng tròn luôn chạy, kể cả khi chưa xử lý JSON.
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          backgroundColor: colors.primaryContainer,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          status,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      return Column(
                        children: [
                          mainCard,
                          const SizedBox(height: 16),
                          workerCard,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: mainCard),
                        const SizedBox(width: 16),
                        Expanded(child: workerCard),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.buttonLabel,
    required this.result,
    required this.error,
    required this.onPressed,
  });

  final String title;
  final String buttonLabel;
  final JsonBenchmarkResult? result;
  final String? error;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final frames = result?.frames;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            frames?.framesPerSecond?.toStringAsFixed(1) ?? '—',
            style: theme.textTheme.displaySmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'FPS UI ước tính',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Thời gian',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _milliseconds(frames?.window),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            result == null
                ? 'Chưa có kết quả'
                : '${result!.itemCount} phần tử · ${frames!.frameCount} khung UI',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: TextStyle(color: colors.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }

  String _milliseconds(Duration? duration) => duration == null
      ? '—'
      : '${(duration.inMicroseconds / 1000).toStringAsFixed(1)} ms';
}
