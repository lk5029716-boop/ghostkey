import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../models/code.dart';
import '../../../../store/code_store.dart';
import 'import_helpers.dart';

/// Progress event sent during import.
class ImportProgressEvent {
  final int current;
  final int total;
  final ImportPhase phase;

  const ImportProgressEvent({
    required this.current,
    required this.total,
    required this.phase,
  });
}

enum ImportPhase { parsing, saving }

/// Shows a progress dialog that reports live progress for both parsing
/// and saving. Caller supplies a stream of [ImportProgressEvent]s.
Future<void> showImportProgressStream({
  required BuildContext context,
  required Stream<ImportProgressEvent> stream,
  required int total,
}) async {
  if (total == 0) {
    await showGhostKeySuccess(context, 0);
    return;
  }

  int saved = 0;
  await for (final event in stream) {
    if (event.phase == ImportPhase.saving) {
      saved = event.current;
    }
  }

  if (!context.mounted) return;
  await showGhostKeySuccess(context, saved);
}

/// Shows a progress dialog that updates as codes are imported.
/// First parses with live "Parsing X of Y entries…" then saves with
/// "X of Y codes imported". Uses StreamBuilder internally so there
/// are no manual stream subscriptions that could race with route
/// deactivation.
Future<void> showImportProgressWithParsing({
  required BuildContext context,
  required Future<List<Code>> Function(void Function(int current, int total) onParseProgress) parser,
}) async {
  final controller = StreamController<ImportProgressEvent>();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: StreamBuilder<ImportProgressEvent>(
        stream: controller.stream,
        builder: (ctx, snapshot) {
          // Stream closed: show success dialog
          if (snapshot.connectionState == ConnectionState.done) {
            final event = snapshot.data;
            final count = (event?.phase == ImportPhase.saving) ? (event?.current ?? 0) : 0;
            return AlertDialog(
              icon: const Icon(Icons.check_circle_outline, color: Color(0xFF0D631B), size: 48),
              title: const Text('Import complete'),
              content: Text(
                count == 1
                    ? '1 code added to your vault.'
                    : '$count codes added to your vault.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          }

          // No data yet: initial spinner
          final event = snapshot.data;
          if (event == null) {
            return const AlertDialog(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
                  SizedBox(width: 20),
                  Flexible(child: Text('Parsing codes…')),
                ],
              ),
            );
          }

          // Progress bar
          final progress = event.total > 0 ? event.current / event.total : 0.0;
          final label = event.phase == ImportPhase.parsing
              ? '${event.current} of ${event.total} entries parsed'
              : '${event.current} of ${event.total} codes imported';
          return AlertDialog(
            title: Text(event.phase == ImportPhase.parsing ? 'Parsing codes' : 'Importing codes'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  color: const Color(0xFF0D631B),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    ),
  );

  // Parse
  try {
    final codes = await parser((current, total) {
      controller.add(ImportProgressEvent(current: current, total: total, phase: ImportPhase.parsing));
    });

    if (codes.isEmpty) {
      return;
    }

    // Switch to saving
    controller.add(ImportProgressEvent(current: 0, total: codes.length, phase: ImportPhase.saving));

    int saved = 0;
    for (final code in codes) {
      try {
        await CodeStore.instance.addCode(code);
        saved++;
        controller.add(ImportProgressEvent(current: saved, total: codes.length, phase: ImportPhase.saving));
      } catch (_) {}
    }
  } finally {
    await controller.close();
  }
}

/// Legacy API: shows a progress dialog that updates as codes are saved.
/// Caller is responsible for parsing the codes first.
Future<void> showImportProgress({
  required BuildContext context,
  required List<Code> codes,
}) async {
  if (codes.isEmpty) {
    await showGhostKeySuccess(context, 0);
    return;
  }

  final controller = StreamController<int>();
  int saved = 0;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: StreamBuilder<int>(
        stream: controller.stream,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final count = snapshot.data ?? 0;
            return AlertDialog(
              icon: const Icon(Icons.check_circle_outline, color: Color(0xFF0D631B), size: 48),
              title: const Text('Import complete'),
              content: Text(
                count == 1 ? '1 code added to your vault.' : '$count codes added to your vault.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          }
          final current = snapshot.data ?? 0;
          final progress = codes.isNotEmpty ? current / codes.length : 0.0;
          return AlertDialog(
            title: const Text('Importing codes'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  color: const Color(0xFF0D631B),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                Text('$current of ${codes.length} codes imported',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    ),
  );

  for (final code in codes) {
    try {
      await CodeStore.instance.addCode(code);
      saved++;
      controller.add(saved);
    } catch (_) {}
  }

  await controller.close();
}
