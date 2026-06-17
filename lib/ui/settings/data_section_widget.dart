import 'package:flutter/material.dart';

import '../../../main.dart';
import '../common/report_bug.dart';
import 'data/import/import_service.dart';
import 'data/local_backup/local_backup_widget.dart';

/// Settings → Data section.
///
/// Shows all 11 import sources GhostKey supports, plus Export. Wires each
/// row to [ImportService.initiateImport] so the user can actually trigger
/// the import flows we built.
class DataSectionWidget extends StatelessWidget {
  const DataSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: 'Import from another app'),
        const SizedBox(height: 4),
        _ImportRow(
          icon: Icons.text_fields,
          title: 'Plain text / otpauth:// URIs',
          subtitle: 'One URI per line, comma-separated, or JSON export',
          onTap: () =>
              ImportService().initiateImport(context, ImportType.plainText),
        ),
        _ImportRow(
          icon: Icons.qr_code_2,
          title: 'Google Authenticator (QR migration)',
          subtitle: 'Scan a Google Authenticator transfer QR code',
          onTap: () => ImportService()
              .initiateImport(context, ImportType.googleAuthenticator),
        ),
        _ImportRow(
          icon: Icons.shield_outlined,
          title: 'Aegis Authenticator',
          subtitle: 'JSON export, plain or password-protected',
          onTap: () =>
              ImportService().initiateImport(context, ImportType.aegis),
        ),
        _ImportRow(
          icon: Icons.password_outlined,
          title: 'andOTP',
          subtitle: 'JSON or AES-encrypted backup',
          onTap: () =>
              ImportService().initiateImport(context, ImportType.andOTP),
        ),
        _ImportRow(
          icon: Icons.key_outlined,
          title: 'Bitwarden',
          subtitle: 'Unencrypted JSON export from web vault',
          onTap: () =>
              ImportService().initiateImport(context, ImportType.bitwarden),
        ),
        _ImportRow(
          icon: Icons.vpn_key_outlined,
          title: '2FAS Authenticator',
          subtitle: 'JSON v3 or v4, plain or password-protected',
          onTap: () =>
              ImportService().initiateImport(context, ImportType.twoFas),
        ),
        _ImportRow(
          icon: Icons.account_circle_outlined,
          title: 'LastPass Authenticator',
          subtitle: 'JSON export from LastPass app',
          onTap: () =>
              ImportService().initiateImport(context, ImportType.lastpass),
        ),
        _ImportRow(
          icon: Icons.rocket_launch_outlined,
          title: 'Proton Authenticator',
          subtitle: 'JSON export, plain or password-protected',
          onTap: () =>
              ImportService().initiateImport(context, ImportType.proton),
        ),
        _ImportRow(
          icon: Icons.tag_outlined,
          title: 'Raivo OTP',
          subtitle: 'JSON export (unzip first if needed)',
          onTap: () =>
              ImportService().initiateImport(context, ImportType.raivo),
        ),
        _ImportRow(
          icon: Icons.lock_outline,
          title: 'Ente Auth (encrypted)',
          subtitle: 'Encrypted JSON backup, password required',
          onTap: () =>
              ImportService().initiateImport(context, ImportType.encrypted),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Export & backup'),
        const LocalBackupWidget(),
        const SizedBox(height: 8),
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
        _SectionHeader(title: 'Support'),
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
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
