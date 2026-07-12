import 'package:flutter/material.dart';

import '../../../main.dart';
import 'data/import/import_service.dart';

/// Settings → Data → Import from another app.
///
/// Full-screen picker for the 10 import sources GhostKey supports.
/// Matches the design language used elsewhere in Settings (light
/// surface, M3 cards, Inter font, green primary).
class ImportFromAnotherAppScreen extends StatelessWidget {
  const ImportFromAnotherAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final outlineVar = const Color(0xFFBFCABA);
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kOnSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Import from another app',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: kOnSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intro card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSecondaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kSecondaryContainer),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline, color: kPrimary, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pick the authenticator app you want to import from. '
                        'You can import from multiple apps in any order — codes '
                        'are merged into your existing 2FA vault.',
                        style: TextStyle(fontSize: 13, color: kOnSurface),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Sources card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: outlineVar.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ImportRow(
                      icon: Icons.text_fields,
                      title: 'Plain text / otpauth:// URIs',
                      subtitle: 'One URI per line, comma-separated, or JSON',
                      onTap: () => _import(context, ImportType.plainText),
                    ),
                    _divider(outlineVar),
                    _ImportRow(
                      icon: Icons.qr_code_2,
                      title: 'Google Authenticator (QR migration)',
                      subtitle: 'Scan a Google Authenticator transfer QR code',
                      onTap: () => _import(
                        context,
                        ImportType.googleAuthenticator,
                      ),
                    ),
                    _divider(outlineVar),
                    _ImportRow(
                      icon: Icons.shield_outlined,
                      title: 'Aegis Authenticator',
                      subtitle: 'JSON export, plain or password-protected',
                      onTap: () => _import(context, ImportType.aegis),
                    ),
                    _divider(outlineVar),
                    _ImportRow(
                      icon: Icons.password_outlined,
                      title: 'andOTP',
                      subtitle: 'JSON or AES-encrypted backup',
                      onTap: () => _import(context, ImportType.andOTP),
                    ),
                    _divider(outlineVar),
                    _ImportRow(
                      icon: Icons.key_outlined,
                      title: 'Bitwarden',
                      subtitle: 'Unencrypted JSON export from web vault',
                      onTap: () => _import(context, ImportType.bitwarden),
                    ),
                    _divider(outlineVar),
                    _ImportRow(
                      icon: Icons.vpn_key_outlined,
                      title: '2FAS Authenticator',
                      subtitle: 'JSON v3 or v4, plain or password-protected',
                      onTap: () => _import(context, ImportType.twoFas),
                    ),
                    _divider(outlineVar),
                    _ImportRow(
                      icon: Icons.account_circle_outlined,
                      title: 'LastPass Authenticator',
                      subtitle: 'JSON export from LastPass app',
                      onTap: () => _import(context, ImportType.lastpass),
                    ),
                    _divider(outlineVar),
                    _ImportRow(
                      icon: Icons.rocket_launch_outlined,
                      title: 'Proton Authenticator',
                      subtitle: 'JSON export, plain or password-protected',
                      onTap: () => _import(context, ImportType.proton),
                    ),
                    _divider(outlineVar),
                    _ImportRow(
                      icon: Icons.tag_outlined,
                      title: 'Raivo OTP',
                      subtitle: 'JSON export (unzip first if needed)',
                      onTap: () => _import(context, ImportType.raivo),
                    ),
                    _divider(outlineVar),
                    _ImportRow(
                      icon: Icons.lock_outline,
                      title: 'Ente Auth (encrypted)',
                      subtitle: 'Encrypted JSON backup, password required',
                      onTap: () => _import(context, ImportType.encrypted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _import(BuildContext context, ImportType type) {
    ImportService().initiateImport(context, type);
  }

  Widget _divider(Color c) => Container(
        margin: const EdgeInsets.only(left: 56),
        height: 1,
        color: c.withOpacity(0.3),
      );
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: kPrimary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: kOnSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kOnSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
