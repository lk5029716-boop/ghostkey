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
  // Show success as a simple AlertDialog (no nested route transition)
  await showGhostKeySuccess(context, saved);
}

/// Shows a progress dialog that updates as codes are imported.
/// First parses with live "Parsing X of Y entries…" then saves with
/// "X of Y codes imported".
/// The dialog handles its own transition to success — no pop→push race.
Future<void> showImportProgressWithParsing({
  required BuildContext context,
  required Future<List<Code>> Function(void Function(int current, int total) onParseProgress) parser,
}) async {
  final controller = StreamController<ImportProgressEvent>();

  // Show progress dialog — the dialog manages its own lifecycle
  unawaited(showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: _ImportProgressDialog(
        stream: controller.stream,
      ),
    ),
  ));

  // Start parsing in background
  final codes = await parser((current, total) {
    controller.add(ImportProgressEvent(
      current: current,
      total: total,
      phase: ImportPhase.parsing,
    ));
  });

  if (codes.isEmpty) {
    await controller.close();
    // The dialog sees the stream close without any saving events and shows
    // "0 codes added" with OK button.
    return;
  }

  // Switch to saving phase
  controller.add(ImportProgressEvent(
    current: 0,
    total: codes.length,
    phase: ImportPhase.saving,
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
  // Dialog shows success with OK button — no pop→push needed.
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

  unawaited(showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: _ImportProgressDialog(
        stream: Stream.fromIterable([]), // placeholder
        legacyStream: controller.stream,
      ),
    ),
  ));

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
  // Dialog shows success with OK button
}

/// Single dialog widget that handles the full lifecycle:
/// 1. Shows progress bar + label during parsing/saving
/// 2. Auto-transitions to success/tick when the stream ends
/// 3. OK button dismisses itself — no external pop→push needed
class _ImportProgressDialog extends StatefulWidget {
  final Stream<ImportProgressEvent> stream;
  final Stream<int>? legacyStream;

  const _ImportProgressDialog({
    required this.stream,
    this.legacyStream,
  });

  @override
  State<_ImportProgressDialog> createState() => _ImportProgressDialogState();
}

class _ImportProgressDialogState extends State<_ImportProgressDialog> {
  int _current = 0;
  int _total = 1; // avoid div-by-zero
  ImportPhase _phase = ImportPhase.parsing;
  bool _done = false;
  StreamSubscription<ImportProgressEvent>? _sub;
  StreamSubscription<int>? _legacySub;

  @override
  void initState() {
    super.initState();

    // Legacy stream (raw int stream for old API)
    _legacySub = widget.legacyStream?.listen(
      (value) {
        if (mounted) setState(() => _current = value);
      },
      onDone: () {
        if (mounted) setState(() => _done = true);
      },
    );

    // New event stream
    _sub = widget.stream.listen(
      (event) {
        if (mounted) {
          setState(() {
            _current = event.current;
            _total = event.total;
            _phase = event.phase;
          });
        }
      },
      onDone: () {
        if (mounted) setState(() => _done = true);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _legacySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Done state: show success + OK button
    if (_done) {
      final count = _phase == ImportPhase.saving ? _current : 0;
      return AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: Color(0xFF0D631B),
          size: 48,
        ),
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

    // Progress state
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
