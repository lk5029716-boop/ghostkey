import 'package:flutter/material.dart';

import '../../../main.dart';
import '../common/report_bug.dart';
import 'data/local_backup/local_backup_widget.dart';
import 'import_from_another_app_screen.dart';

/// Settings → Data section.
///
/// "Import from another app" is now a single row that opens a dedicated
/// full-screen picker (see [ImportFromAnotherAppScreen]). The rest of
/// the data section is kept inline: encrypted backup, export, and bug
/// reporting.
class DataSectionWidget extends StatelessWidget {
  const DataSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final outlineVar = const Color(0xFFBFCABA);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Single import entry — opens the dedicated picker screen.
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ImportFromAnotherAppScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kSecondaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.file_download_outlined,
                      color: kPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import from another app',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: kOnSurface,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Aegis, andOTP, Bitwarden, 2FAS, Google Authenticator, and more',
                          style: TextStyle(
                            fontSize: 12,
                            color: kOnSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: kOnSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 56),
          height: 1,
          color: outlineVar.withOpacity(0.3),
        ),
        const SizedBox(height: 8),
        const _SectionHeader(title: 'Export & backup'),
        const LocalBackupWidget(),
        const SizedBox(height: 4),
        _ImportRow(
          icon: Icons.file_download_outlined,
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
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Support'),
        const SizedBox(height: 4),
        _ImportRow(
          icon: Icons.bug_report_outlined,
          title: 'Report a bug',
          subtitle: 'Send device info + description to support',
          onTap: () => showDialog(
            context: context,
            builder: (_) => const ReportBugDialog(),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: kPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kSecondaryContainer.withOpacity(0.3),
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: kOnSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
