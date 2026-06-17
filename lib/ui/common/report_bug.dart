import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// In-app bug reporter. Collects device info + a free-form description,
/// writes a log file, and shares it via the platform share sheet so
/// the user can email/send it to support.
///
/// Since GhostKey has no backend, the user attaches the log to their
/// own email/message — ente's flow (upload to internal server) doesn't
/// apply here.
class ReportBugDialog extends StatefulWidget {
  const ReportBugDialog({super.key});

  @override
  State<ReportBugDialog> createState() => _ReportBugDialogState();
}

class _ReportBugDialogState extends State<ReportBugDialog> {
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  bool _attachingLogs = true;
  bool _sending = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    setState(() => _sending = true);

    try {
      String? logPath;
      if (_attachingLogs) {
        logPath = await _writeLogFile(
          description: _descriptionController.text.trim(),
          email: _emailController.text.trim(),
        );
      }

      if (logPath != null) {
        await Share.shareXFiles(
          [XFile(logPath)],
          subject: 'GhostKey bug report',
          text:
              'Describe what happened:\n\n${_descriptionController.text.trim()}',
        );
      } else {
        // No log attachment — just open the mailto:
        final body = Uri.encodeComponent(
          'Describe what happened:\n\n${_descriptionController.text.trim()}',
        );
        final subject = Uri.encodeComponent('GhostKey bug report');
        final email = _emailController.text.trim().isEmpty
            ? 'support@ghostkey.app'
            : _emailController.text.trim();
        // ignore: deprecated_member_use
        // Use Clipboard + snackbar as a portable fallback (mailto: needs
        // platform plugin; we keep it simple for the demo).
        await Clipboard.setData(
          ClipboardData(
            text: 'To: $email\nSubject: $subject\n\n$body',
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bug report copied to clipboard'),
            ),
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
        setState(() => _sending = false);
      }
    }
  }

  Future<String> _writeLogFile({
    required String description,
    required String email,
  }) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/ghostkey-bug-${DateTime.now().millisecondsSinceEpoch}.txt';
    final buffer = StringBuffer()
      ..writeln('GhostKey bug report')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('User email: ${email.isEmpty ? '(not provided)' : email}')
      ..writeln('Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}')
      ..writeln('Dart: ${Platform.version}')
      ..writeln()
      ..writeln('--- Description ---')
      ..writeln(description.isEmpty ? '(no description)' : description);
    await File(path).writeAsString(buffer.toString());
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Report a bug'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tell us what went wrong. We\'ll attach device info to help reproduce it.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Your email (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'What happened?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _attachingLogs,
              onChanged: (v) => setState(() => _attachingLogs = v ?? true),
              title: const Text('Attach device + app info'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _sending ? null : _submit,
          child: Text(_sending ? 'Sending…' : 'Submit'),
        ),
      ],
    );
  }
}
