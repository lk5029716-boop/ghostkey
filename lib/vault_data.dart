// ═══════════════════════════════════════════════════════════════
// VAULT DATA MODEL
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';

enum VaultCategory { password, seeds, apiKeys, codes }

class VaultItem {
  final String id;
  final String title;
  final String subtitle;
  final VaultCategory category;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String date;
  final Map<String, String> fields; // category-specific data

  const VaultItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.date,
    required this.fields,
  });
}

// Demo vault data
final List<VaultItem> kVaultItems = [
  // Password
  VaultItem(
    id: 'google',
    title: 'Google Account',
    subtitle: 'alex@gmail.com',
    category: VaultCategory.password,
    icon: Icons.vpn_key,
    iconColor: const Color(0xFF4285F4),
    iconBgColor: const Color(0xFFBBDEFB),
    date: 'May 28, 2024',
    fields: {
      'Email': 'alex@gmail.com',
      'Password': 'Str0ng!P@ssw0rd#2024',
      'Recovery Email': 'alex.backup@gmail.com',
      '2FA Type': 'Backup Codes',
      'Backup Codes': '8472-9910\n5531-0087\n2294-7763\n1108-4456\n6677-3321\n9901-5543\n3344-8899\n7755-1122',
    },
  ),
  VaultItem(
    id: 'binance',
    title: 'Binance Account',
    subtitle: 'alex@gmail.com',
    category: VaultCategory.password,
    icon: Icons.currency_bitcoin,
    iconColor: const Color(0xFFF0B90B),
    iconBgColor: const Color(0xFFFFF3CD),
    date: 'May 27, 2024',
    fields: {
      'Email': 'alex@gmail.com',
      'Password': 'Bin@nce!Secure#9921',
      '2FA Type': 'TOTP Secret',
      'TOTP Secret': 'JBSWY3DPEHPK3PXP',
      'Account Type': 'Verified',
      'Created': 'Jan 12, 2023',
      'Last Login': 'May 27, 2024',
    },
  ),
  // Seeds
  VaultItem(
    id: 'ledger',
    title: 'Ledger Seed Phrase',
    subtitle: '24 words',
    category: VaultCategory.seeds,
    icon: Icons.memory,
    iconColor: const Color(0xFF0D631B),
    iconBgColor: const Color(0xFFC8E6C9),
    date: 'May 26, 2024',
    fields: {
      'Seed Phrase': 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art',
      'Derivation Path': "m/44'/60'/0'/0/0",
      'Network': 'Ethereum',
      'Wallet': 'Ledger Nano X',
      'Created': 'Jan 15, 2023',
    },
  ),
  // API Keys
  VaultItem(
    id: 'aws',
    title: 'AWS Root Key',
    subtitle: 'AKIA....EXAMPLE',
    category: VaultCategory.apiKeys,
    icon: Icons.dialpad,
    iconColor: const Color(0xFFFF9900),
    iconBgColor: const Color(0xFFFFE0B2),
    date: 'May 26, 2024',
    fields: {
      'Access Key ID': 'AKIAIOSFODNN7EXAMPLE',
      'Secret Access Key': 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
      'IAM User': 'admin@company.com',
      'Region': 'us-east-1 (N. Virginia)',
      'Console URL': 'https://console.aws.amazon.com',
      'Created': 'May 15, 2024',
      'Permissions': 'AdministratorAccess',
    },
  ),
  VaultItem(
    id: 'crypto_com',
    title: 'Crypto.com API',
    subtitle: 'Read-only',
    category: VaultCategory.apiKeys,
    icon: Icons.vpn_key,
    iconColor: const Color(0xFF00796B),
    iconBgColor: const Color(0xFFB2DFDB),
    date: 'May 24, 2024',
    fields: {
      'API Key': 'ck_live_abc123...xyz789',
      'API Secret': 'sk_live_def456...uvw012',
      'Permissions': 'Read-only (Trade: disabled)',
      'Created': 'May 24, 2024',
      'Rate Limit': '100 req/min',
    },
  ),
  // Codes
  VaultItem(
    id: 'recovery',
    title: 'Recovery Codes',
    subtitle: '8 codes',
    category: VaultCategory.codes,
    icon: Icons.grid_view,
    iconColor: const Color(0xFF7B1FA2),
    iconBgColor: const Color(0xFFE1BEE7),
    date: 'May 25, 2024',
    fields: {
      'Google': '8472-9910\n5531-0087\n2294-7763',
      'GitHub': '1108-4456\n6677-3321\n9901-5543',
      'Discord': '3344-8899\n7755-1122',
    },
  ),
];
