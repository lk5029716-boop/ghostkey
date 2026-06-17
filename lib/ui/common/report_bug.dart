import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// In-app bug reporter. Collects device info + a free-form description,
/// writes a log file, and shares it via email or the platform share sheet.
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
      final description = _descriptionController.text.trim();
      final email = _emailController.text.trim();

      // Build the email body
      final body = StringBuffer()
        ..writeln('GhostKey Bug Report')
        ..writeln()
        ..writeln('--- Description ---')
        ..writeln(description.isEmpty ? '(no description provided)' : description)
        ..writeln()
        ..writeln('--- Device Info ---')
        ..writeln('Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}')
        ..writeln('Dart: ${Platform.version}');

      if (email.isNotEmpty) {
        body.writeln('User email: $email');
      }

      final subject = Uri.encodeComponent('GhostKey bug report');
      final bodyEncoded = Uri.encodeComponent(body.toString());

      // Try to open mailto: link first
      final mailtoUri = Uri.parse(
        'mailto:support@ghostkey.app?subject=$subject&body=$bodyEncoded',
      );

      try {
        final canLaunch = await canLaunchUrl(mailtoUri);
        if (canLaunch) {
          await launchUrl(mailtoUri);
          if (mounted) Navigator.of(context).pop();
          return;
        }
      } catch (_) {
        // mailto: not available, fall through to share
      }

      // Fallback: write log file and use share sheet
      if (_attachingLogs) {
        final logPath = await _writeLogFile(
          description: description,
          email: email,
        );
        await Share.shareXFiles(
          [XFile(logPath)],
          subject: 'GhostKey bug report',
          text: description.isEmpty
              ? 'GhostKey bug report'
              : 'Describe what happened:\n\n$description',
        );
      } else {
        // Last resort: copy to clipboard
        await Clipboard.setData(ClipboardData(text: body.toString()));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bug report copied to clipboard — paste it in an email to support@ghostkey.app'),
              duration: Duration(seconds: 4),
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
