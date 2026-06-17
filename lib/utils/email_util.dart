import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Local-first replacement for ente's `email_util.dart`.
///
/// Strips the email-attachment-and-zip-and-share-with-support flow down
/// to: (1) [isValidEmail] and (2) [sendEmail] which just hands off to
/// the platform mail app via `mailto:`.
///
/// Log export, share-with-support, and the email-app-not-found dialog
/// from ente's upstream are stubbed.

bool isValidEmail(String? email) {
  if (email == null || email.isEmpty) return false;
  return EmailValidator.validate(email);
}

/// Open the platform mail app with a pre-filled `mailto:` link.
Future<void> sendEmail(
  BuildContext context, {
  required String to,
  String? subject,
  String? body,
}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: to,
    query: _encodeMailtoQuery({
      if (subject != null) 'subject': subject,
      if (body != null) 'body': body,
    }),
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    // No mail app — copy the address to clipboard and surface a notice.
    await Clipboard.setData(ClipboardData(text: to));
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('No mail app — copied $to to clipboard')),
      );
    }
  }
}

/// No-op stub. Ente used this to attach + share logs with support;
/// GhostKey's demo has no support inbox yet.
Future<void> sendLogs(
  BuildContext context,
  String subject, {
  Future<void> Function()? postShare,
}) async {
  if (postShare != null) await postShare();
}

Future<void> exportLogs(BuildContext context) async {
  if (context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Log export not available in demo build')),
    );
  }
}

String _encodeMailtoQuery(Map<String, String> params) {
  return params.entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}
