import 'package:flutter/material.dart';

import '../../../main.dart';
import 'import_from_another_app_screen.dart';

/// Settings → Data section.
///
/// Uses the same row/divider style as the rest of the Settings screen
/// (rounded green-tinted icon badge, 56 px divider indent) so the Data
/// section doesn't look like a different design system.
class DataSectionWidget extends StatelessWidget {
  const DataSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final outlineVar = const Color(0xFFBFCABA);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ImportRow(
          icon: Icons.file_download_outlined,
          title: 'Import from another app',
          subtitle: 'Aegis, andOTP, Bitwarden, 2FAS, Google Authenticator, and more',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ImportFromAnotherAppScreen(),
              ),
            );
          },
        ),
        _divider(outlineVar),
        _ImportRow(
          icon: Icons.cloud_upload_outlined,
          title: 'Local encrypted backup',
          subtitle: 'Save an encrypted backup to your device',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Local backup coming soon — needs libsodium FFI'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        _divider(outlineVar),
        _ImportRow(
          icon: Icons.ios_share,
          title: 'Export to file',
          subtitle: 'Save all codes as otpauth:// URIs',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Export coming soon'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _divider(Color color) {
    return Divider(height: 1, thickness: 1, color: color.withOpacity(0.1), indent: 56);
  }
}

class _ImportRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImportRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kSecondaryContainer.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: kPrimary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF191C1D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF40493D),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF40493D),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
