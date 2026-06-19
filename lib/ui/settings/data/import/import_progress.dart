import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../models/code.dart';
import '../../../../store/code_store.dart';
import 'import_helpers.dart';

/// Shows a progress dialog that updates as codes are imported.
/// Caller is responsible for parsing the codes; this just handles
/// saving them one-by-one with live progress.
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
        stream: controller.stream,
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
  final Stream<int> stream;

  const _ImportProgressDialog({
    required this.total,
    required this.stream,
  });

  @override
  State<_ImportProgressDialog> createState() => _ImportProgressDialogState();
}

class _ImportProgressDialogState extends State<_ImportProgressDialog> {
  int _current = 0;

  @override
  void initState() {
    super.initState();
    widget.stream.listen((value) {
      if (mounted) setState(() => _current = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.total > 0 ? _current / widget.total : 0.0;
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
          Text(
            '$_current of ${widget.total} codes imported',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
