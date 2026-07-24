import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/export/export_service.dart';
import 'import_from_another_app_screen.dart';

const Color _rowTitleColor = Color(0xFF27272A);
const Color _rowSubtitleColor = Color(0xFF71717A);
const Color _dividerColor = Color(0xFFF1F5F9);
const Color _iconBgPurple = Color(0xFFF3E8FF);
const Color _iconBgBlue = Color(0xFFE0F2FE);
const Color _iconBgGreen = Color(0xFFDCFCE7);
const Color _iconBgPink = Color(0xFFFCE7F3);
const Color _iconBgOrange = Color(0xFFFEF3C7);
const Color _iconBgGray = Color(0xFFF4F4F5);

class DataSectionWidget extends StatelessWidget {
  const DataSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ImportRow(
          icon: Icons.cloud_download_outlined,
          title: 'Import from another app',
          subtitle: 'Aegis, andOTP, Bitwarden, 2FAS, Google Authenticator, and more',
          iconBg: _iconBgBlue,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ImportFromAnotherAppScreen()),
            );
          },
        ),
        _sep(),
        _ImportRow(
          icon: Icons.cloud_upload_outlined,
          title: 'Local encrypted backup',
          subtitle: 'Save an encrypted backup to your device',
          iconBg: _iconBgGreen,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Local backup coming soon — needs libsodium FFI'), duration: Duration(seconds: 2)),
            );
          },
        ),
        _sep(),
        _ImportRow(
          icon: Icons.ios_share,
          title: 'Export to file',
          subtitle: 'Plain text, HTML, or JSON',
          iconBg: _iconBgOrange,
          onTap: () => ExportService.showExportOptions(context),
        ),
      ],
    );
  }

  Widget _sep() {
    return Divider(height: 1, thickness: 1, color: _dividerColor, indent: 64);
  }
}

class _ImportRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;
  final VoidCallback onTap;

  const _ImportRow({required this.icon, required this.title, required this.subtitle, required this.iconBg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: _rowTitleColor),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: _rowTitleColor, height: 1.3)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: _rowSubtitleColor, height: 1.3)),
            ])),
            const Icon(Icons.chevron_right, color: Color(0xFFA1A1AA), size: 20),
          ]),
        ),
      ),
    );
  }
}
