import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../models/code.dart';
import '../../../../store/code_store.dart';
import '../../../../utils/share_utils.dart';

class ExportService {
  static Future<void> showExportOptions(BuildContext context) async {
    final codes = await CodeStore.instance.getAllCodes();
    if (codes.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No 2FA codes to export'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export to file'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OptionTile(
              icon: Icons.text_snippet,
              title: 'Plain Text (.txt)',
              subtitle: 'One otpauth:// URI per line',
              onTap: () => Navigator.of(ctx).pop('txt'),
            ),
            const SizedBox(height: 8),
            _OptionTile(
              icon: Icons.code,
              title: 'HTML (.html)',
              subtitle: 'Styled page with all codes listed',
              onTap: () => Navigator.of(ctx).pop('html'),
            ),
            const SizedBox(height: 8),
            _OptionTile(
              icon: Icons.data_object,
              title: 'JSON (.json)',
              subtitle: 'Machine-readable format',
              onTap: () => Navigator.of(ctx).pop('json'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (format == null || !context.mounted) return;

    switch (format) {
      case 'txt':
        await _exportTxt(context, codes);
        break;
      case 'html':
        await _exportHtml(context, codes);
        break;
      case 'json':
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('JSON export coming soon'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  static Future<void> _exportTxt(BuildContext context, List<Code> codes) async {
    final buffer = StringBuffer();
    for (final code in codes) {
      if (code.rawData.isNotEmpty) {
        buffer.writeln(code.rawData);
      }
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ghostkey-codes.txt');
    await file.writeAsString(buffer.toString());

    if (!context.mounted) return;
    await shareFile(file.path, mimeType: 'text/plain');
  }

  static Future<void> _exportHtml(BuildContext context, List<Code> codes) async {
    final rows = StringBuffer();
    for (final code in codes) {
      final issuer = _escapeHtml(code.issuer.isNotEmpty ? code.issuer : code.account);
      final account = _escapeHtml(code.account);
      final secret = _escapeHtml(code.secret);
      final uri = _escapeHtml(code.rawData);
      final maskedSecret = secret.length > 4
          ? '${secret.substring(0, 4)}${'*' * (secret.length - 4)}'
          : secret;

      rows.writeln('''
    <tr>
      <td class="issuer">$issuer</td>
      <td class="account">$account</td>
      <td class="secret">$maskedSecret</td>
      <td class="uri"><code>$uri</code></td>
    </tr>''');
    }

    final html = '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>GhostKey Exported Codes</title>
<style>
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    margin: 0;
    padding: 20px;
    background: #121212;
    color: #e0e0e0;
  }
  h1 {
    color: #ffffff;
    font-size: 24px;
    margin-bottom: 4px;
  }
  p.subtitle {
    color: #a0a0a0;
    font-size: 14px;
    margin-top: 0;
    margin-bottom: 24px;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    background: #1e1e1e;
    border-radius: 8px;
    overflow: hidden;
  }
  th {
    background: #2a2a2a;
    color: #ffffff;
    padding: 12px 16px;
    text-align: left;
    font-size: 13px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
  td {
    padding: 12px 16px;
    border-top: 1px solid #333;
    font-size: 14px;
  }
  tr:hover { background: #252525; }
  .issuer { font-weight: 600; color: #ffffff; }
  .account { color: #a0a0a0; }
  .secret { font-family: monospace; color: #4fc3f7; }
  .uri code {
    font-family: monospace;
    font-size: 12px;
    word-break: break-all;
    color: #81c784;
    background: #1a1a1a;
    padding: 4px 8px;
    border-radius: 4px;
  }
  .count {
    color: #a0a0a0;
    font-size: 13px;
    margin-bottom: 16px;
  }
</style>
</head>
<body>
  <h1>GhostKey Exported Codes</h1>
  <p class="subtitle">Exported from GhostKey</p>
  <p class="count">${codes.length} code${codes.length == 1 ? '' : 's'}</p>
  <table>
    <thead>
      <tr>
        <th>Issuer</th>
        <th>Account</th>
        <th>Secret</th>
        <th>otpauth:// URI</th>
      </tr>
    </thead>
    <tbody>$rows
    </tbody>
  </table>
</body>
</html>''';

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ghostkey-codes.html');
    await file.writeAsString(html);

    if (!context.mounted) return;
    await shareFile(file.path, mimeType: 'text/html');
  }

  static String _escapeHtml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: scheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
