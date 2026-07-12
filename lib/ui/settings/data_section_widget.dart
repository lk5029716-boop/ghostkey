import 'package:flutter/material.dart';

import '../../../main.dart';
import 'data/export/export_service.dart';
import 'import_from_another_app_screen.dart';

/// Settings → Data section.
///
/// Uses the same "Pastel Vault" M3 row style as the rest of the
/// Settings screen (rounded tinted icon chip, 64px divider indent).
class DataSectionWidget extends StatelessWidget {
  const DataSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ImportRow(
          icon: Icons.cloud_download,
          title: 'Import from another app',
          subtitle: 'Aegis, andOTP, Bitwarden, 2FAS, Google Authenticator, and more',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ImportFromAnotherAppScreen()),
            );
          },
        ),
        _divider(kOutlineVariant),
        _ImportRow(
          icon: Icons.database,
          title: 'Local encrypted backup',
          subtitle: 'Save an encrypted backup to your device',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Local backup coming soon — needs libsodium FFI'), duration: Duration(seconds: 2)),
            );
          },
        ),
        _divider(kOutlineVariant),
        _ImportRow(
          icon: Icons.file_export,
          title: 'Export to file',
          subtitle: 'Plain text, HTML, or JSON',
          onTap: () => ExportService.showExportOptions(context),
        ),
      ],
    );
  }

  Widget _divider(Color color) {
    return Divider(height: 1, thickness: 1, color: color.withOpacity(0.1), indent: 64);
  }
}

class _ImportRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImportRow({required this.icon, required this.title, required this.subtitle, required this.onTap});

  Color _fg() {
    if (icon == Icons.cloud_download) return kTertiary;
    if (icon == Icons.database) return kPrimary;
    if (icon == Icons.file_export) return kSecondary;
    return kPrimary;
  }

  Color _bg() {
    if (icon == Icons.cloud_download) return kTertiaryFixed.withOpacity(0.6);
    if (icon == Icons.database) return kPrimaryFixed.withOpacity(0.5);
    if (icon == Icons.file_export) return kSecondaryContainer.withOpacity(0.6);
    return kPrimaryFixed.withOpacity(0.5);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: _bg(), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: _fg(), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF191C1D))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF40493D))),
            ])),
            const Icon(Icons.chevron_right, color: Color(0xFF40493D), size: 20),
          ]),
        ),
      ),
    );
  }
}
