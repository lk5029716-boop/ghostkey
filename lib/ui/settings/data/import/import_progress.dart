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

  final completer = Completer<int>();
  late StreamSubscription<ImportProgressEvent> sub;

  // Show progress dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: _ImportProgressDialog(
        total: total,
        stream: stream,
        onDone: (saved) {
          if (!completer.isCompleted) completer.complete(saved);
        },
      ),
    ),
  );

  int saved = 0;
  await for (final event in stream) {
    if (event.phase == ImportPhase.saving) {
      saved = event.current;
    }
  }

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  await showGhostKeySuccess(context, saved);
}

/// Shows a progress dialog that updates as codes are imported.
/// First parses with live "Parsing X of Y entries…" then saves with
/// "X of Y codes imported".
Future<void> showImportProgressWithParsing({
  required BuildContext context,
  required Future<List<Code>> Function(void Function(int current, int total) onParseProgress) parser,
}) async {
  final controller = StreamController<ImportProgressEvent>();
  int parseTotal = 0;

  // Start parsing in background
  final parseFuture = parser((current, total) {
    parseTotal = total;
    controller.add(ImportProgressEvent(
      current: current,
      total: total,
      phase: ImportPhase.parsing,
    ));
  });

  // Show progress dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: _ImportProgressDialog(
        total: 0, // will be updated
        stream: controller.stream,
        onDone: (_) {},
      ),
    ),
  );

  // Wait for parsing to complete
  final codes = await parseFuture;

  if (!context.mounted) {
    await controller.close();
    return;
  }

  if (codes.isEmpty) {
    await controller.close();
    Navigator.of(context, rootNavigator: true).pop();
    await showGhostKeySuccess(context, 0);
    return;
  }

  // Switch to saving phase
  controller.add(ImportProgressEvent(
    current: 0,
    total: codes.length,
    phase: ImportPhase.parsing,
  ));

  int saved = 0;
  for (final code in codes) {
    try {
      await CodeStore.instance.addCode(code);
      saved++;
      controller.add(ImportProgressEvent(
        current: saved,
        total: codes.length,
        phase: ImportPhase.saving,
      ));
    } catch (e) {
      // skip failed codes, continue
    }
  }

  await controller.close();

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  await showGhostKeySuccess(context, saved);
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

  // Show progress dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: _ImportProgressDialog(
        total: codes.length,
        stream: Stream.fromIterable([]), // placeholder, not used in legacy mode
        onDone: (_) {},
        legacyStream: controller.stream,
      ),
    ),
  );

  // Save codes one by one, reporting progress
  for (final code in codes) {
    try {
      await CodeStore.instance.addCode(code);
      saved++;
      controller.add(saved);
    } catch (e) {
      // skip failed codes, continue
    }
  }

  await controller.close();

  if (!context.mounted) return;
  await hideGhostKeyProgress(context);
  await showGhostKeySuccess(context, saved);
}

class _ImportProgressDialog extends StatefulWidget {
  final int total;
  final Stream<ImportProgressEvent> stream;
  final void Function(int saved) onDone;
  final Stream<int>? legacyStream;

  const _ImportProgressDialog({
    required this.total,
    required this.stream,
    required this.onDone,
    this.legacyStream,
  });

  @override
  State<_ImportProgressDialog> createState() => _ImportProgressDialogState();
}

class _ImportProgressDialogState extends State<_ImportProgressDialog> {
  int _current = 0;
  int _total = 0;
  ImportPhase _phase = ImportPhase.parsing;

  @override
  void initState() {
    super.initState();
    _total = widget.total;

    // Legacy stream (raw int stream for old API)
    widget.legacyStream?.listen((value) {
      if (mounted) setState(() => _current = value);
    });

    // New event stream
    widget.stream.listen((event) {
      if (mounted) {
        setState(() {
          _current = event.current;
          _total = event.total;
          _phase = event.phase;
        });
      }
      if (event.phase == ImportPhase.saving && event.current == event.total) {
        widget.onDone(event.current);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total > 0 ? _current / _total : 0.0;
    final label = _phase == ImportPhase.parsing
        ? '$_current of $_total entries parsed'
        : '$_current of $_total codes imported';
    final title = _phase == ImportPhase.parsing
        ? 'Parsing codes'
        : 'Importing codes';

    return AlertDialog(
      title: Text(title),
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
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
