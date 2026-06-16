import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'vault_data.dart';

// ═══════════════════════════════════════════════════════════════
// TOTP GENERATOR
// ═══════════════════════════════════════════════════════════════
String _generateTOTP(String secret, {int period = 30, int digits = 6}) {
  // Base32 decode
  final key = _base32Decode(secret.toUpperCase().replaceAll(' ', ''));
  if (key.isEmpty) return '------';

  final time = DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ period;
  final timeBytes = Uint8List(8);
  final bd = ByteData.view(timeBytes.buffer);
  bd.setUint64(0, time, Endian.big);

  // HMAC-SHA1
  final hmac = Hmac(sha1, key);
  final hash = hmac.convert(timeBytes).bytes;

  final offset = hash[hash.length - 1] & 0x0F;
  final binary = ((hash[offset] & 0x7F) << 24) |
      ((hash[offset + 1] & 0xFF) << 16) |
      ((hash[offset + 2] & 0xFF) << 8) |
      (hash[offset + 3] & 0xFF);

  final otp = binary % _pow10(digits);
  return otp.toString().padLeft(digits, '0');
}

Uint8List _base32Decode(String input) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  final output = <int>[];
  int buffer = 0;
  int bitsLeft = 0;

  for (final char in input.codeUnits) {
    final idx = alphabet.codeUnits.indexOf(char);
    if (idx < 0) continue;
    buffer = (buffer << 5) | idx;
    bitsLeft += 5;
    if (bitsLeft >= 8) {
      bitsLeft -= 8;
      output.add((buffer >> bitsLeft) & 0xFF);
    }
  }
  return Uint8List.fromList(output);
}

int _pow10(int n) {
  int r = 1;
  for (int i = 0; i < n; i++) r *= 10;
  return r;
}

// ═══════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════
class _RevealField extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;
  final bool isMono;

  const _RevealField({
    required this.icon,
    required this.label,
    required this.value,
    this.isWarning = false,
    this.isMono = false,
  });

  @override
  State<_RevealField> createState() => _RevealFieldState();
}

class _RevealFieldState extends State<_RevealField> {
  bool _revealed = false;
  int _timer = 30;
  Timer? _t;

  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  void _startTimer() {
    _t?.cancel();
    setState(() => _timer = 30);
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timer--);
      if (_timer <= 0) { t.cancel(); if (mounted) setState(() => _revealed = false); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.isWarning ? const Color(0xFFF59E0B).withOpacity(0.3) : const Color(0xFFBFCABA).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(widget.icon, size: 18, color: widget.isWarning ? const Color(0xFFF59E0B) : const Color(0xFF40493D)),
          const SizedBox(width: 8),
          Text(widget.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: widget.isWarning ? const Color(0xFFF59E0B) : const Color(0xFF40493D))),
          const Spacer(),
          GestureDetector(
            onTap: () {
              if (!_revealed) {
                setState(() => _revealed = true);
                _startTimer();
              } else {
                _t?.cancel();
                setState(() => _revealed = false);
              }
            },
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_revealed ? Icons.visibility_off : Icons.visibility, size: 16, color: const Color(0xFF0D631B)),
              const SizedBox(width: 4),
              Text(_revealed ? 'Hide' : 'Reveal', style: const TextStyle(fontSize: 12, color: Color(0xFF0D631B), fontWeight: FontWeight.w500)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Text(
              _revealed ? widget.value : '••••••••••••',
              style: TextStyle(
                fontSize: widget.isMono ? 15 : 16,
                fontWeight: FontWeight.w500,
                fontFamily: widget.isMono ? 'monospace' : null,
                color: const Color(0xFF191C1D),
                letterSpacing: widget.isMono ? 2 : 0.5,
              ),
            ),
          ),
          if (_revealed)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.value));
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)));
              },
              child: const Icon(Icons.copy, size: 18, color: Color(0xFF40493D)),
            ),
        ]),
        if (_revealed) ...[
          const SizedBox(height: 8),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Text('Auto-hide in $_timer s', style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w500)),
          ]),
        ],
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF40493D))),
        Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF191C1D)))),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. PASSWORD DETAIL SCREEN (Google Account, Binance Account)
// ═══════════════════════════════════════════════════════════════
class PasswordDetailScreen extends StatelessWidget {
  final VaultItem item;
  const PasswordDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final f = item.fields;
    final isBinance = item.id == 'binance';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF191C1D)), onPressed: () => Navigator.pop(context)),
        title: Text(item.title, style: const TextStyle(color: Color(0xFF191C1D))),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Color(0xFF40493D)), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          // Header
          Center(child: Column(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: item.iconBgColor, shape: BoxShape.circle), child: Icon(item.icon, size: 36, color: item.iconColor)),
            const SizedBox(height: 12),
            Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF191C1D))),
            const SizedBox(height: 4), Text(item.subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF40493D))),
          ])),
          const SizedBox(height: 32),

          // Email
          _RevealField(icon: Icons.alternate_email, label: 'Email', value: f['Email'] ?? ''),
          const SizedBox(height: 12),

          // Password
          _RevealField(icon: Icons.lock_outline, label: 'Password', value: f['Password'] ?? '', isWarning: true),
          const SizedBox(height: 12),

          // 2FA section
          if (isBinance && f.containsKey('TOTP Secret')) ...[
            // Binance: TOTP secret with live code generation
            _TotpField(secret: f['TOTP Secret']!),
            const SizedBox(height: 12),
          ] else if (f.containsKey('Backup Codes')) ...[
            // Google: Backup codes grid
            _BackupCodesGrid(codes: f['Backup Codes']!.split('\n')),
            const SizedBox(height: 12),
          ],

          // Recovery Email (Google) or extra info (Binance)
          if (f.containsKey('Recovery Email'))
            _RevealField(icon: Icons.replay, label: 'Recovery Email', value: f['Recovery Email']!),

          // Account info card
          if (f.containsKey('Account Type') || f.containsKey('Created')) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBFCABA).withOpacity(0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (f.containsKey('Account Type')) ...[
                  _InfoRow('Account Type', f['Account Type']!),
                  if (f.containsKey('Created') || f.containsKey('Last Login')) const Divider(height: 20, color: Color(0xFFE1E3E4)),
                ],
                if (f.containsKey('Created')) ...[
                  _InfoRow('Created', f['Created']!),
                  if (f.containsKey('Last Login')) const Divider(height: 20, color: Color(0xFFE1E3E4)),
                ],
                if (f.containsKey('Last Login'))
                  _InfoRow('Last Login', f['Last Login']!),
              ]),
            ),
          ],

          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOTP FIELD WITH LIVE CODE GENERATION
// ═══════════════════════════════════════════════════════════════
class _TotpField extends StatefulWidget {
  final String secret;
  const _TotpField({required this.secret});

  @override
  State<_TotpField> createState() => _TotpFieldState();
}

class _TotpFieldState extends State<_TotpField> {
  bool _secretRevealed = false;
  bool _codeRevealed = false;
  int _timer = 30;
  Timer? _t;
  String _currentCode = '';

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  void _generateCode() {
    _currentCode = _generateTOTP(widget.secret);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _timer = 30 - (now % 30);
  }

  void _startTimer() {
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timer--);
      if (_timer <= 0) {
        _generateCode();
        setState(() => _timer = 30);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.security, size: 18, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          const Text('2FA TOTP Secret', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFF59E0B))),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() => _secretRevealed = !_secretRevealed);
              if (!_secretRevealed) _startTimer();
              else _t?.cancel();
            },
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_secretRevealed ? Icons.visibility_off : Icons.visibility, size: 16, color: const Color(0xFF0D631B)),
              const SizedBox(width: 4),
              Text(_secretRevealed ? 'Hide' : 'Reveal', style: const TextStyle(fontSize: 12, color: Color(0xFF0D631B), fontWeight: FontWeight.w500)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        // Secret key
        Row(children: [
          Expanded(
            child: Text(
              _secretRevealed ? widget.secret : '••••••••••••••••',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'monospace', color: const Color(0xFF191C1D), letterSpacing: 2),
            ),
          ),
          if (_secretRevealed)
            GestureDetector(
              onTap: () { Clipboard.setData(ClipboardData(text: widget.secret)); HapticFeedback.lightImpact(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1))); },
              child: const Icon(Icons.copy, size: 18, color: Color(0xFF40493D)),
            ),
        ]),
        const SizedBox(height: 16),
        // Live TOTP code
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF3F4F5), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.pin, size: 18, color: Color(0xFF0D631B)),
            const SizedBox(width: 8),
            const Text('Live Code', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF40493D))),
            const Spacer(),
            Text(
              _codeRevealed ? _currentCode : '••••••',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: const Color(0xFF0D631B), letterSpacing: 4),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                setState(() => _codeRevealed = !_codeRevealed);
                if (_codeRevealed && _t == null) _startTimer();
              },
              child: Icon(_codeRevealed ? Icons.visibility_off : Icons.visibility, size: 18, color: const Color(0xFF0D631B)),
            ),
            if (_codeRevealed)
              GestureDetector(
                onTap: () { Clipboard.setData(ClipboardData(text: _currentCode)); HapticFeedback.lightImpact(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied'), duration: Duration(seconds: 1))); },
                child: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.copy, size: 18, color: Color(0xFF40493D))),
              ),
          ]),
        ),
        if (_codeRevealed) ...[
          const SizedBox(height: 8),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Text('Refreshes in $_timer s', style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w500)),
          ]),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BACKUP CODES GRID (for Google Account)
// ═══════════════════════════════════════════════════════════════
class _BackupCodesGrid extends StatefulWidget {
  final List<String> codes;
  const _BackupCodesGrid({required this.codes});

  @override
  State<_BackupCodesGrid> createState() => _BackupCodesGridState();
}

class _BackupCodesGridState extends State<_BackupCodesGrid> {
  bool _revealed = false;
  Timer? _t;

  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.security, size: 18, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          const Text('2FA Backup Codes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFF59E0B))),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() => _revealed = !_revealed);
              if (!_revealed) {
                _t?.cancel();
                setState(() {});
              } else {
                _t?.cancel();
                _t = Timer.periodic(const Duration(seconds: 1), (timer) {
                  if (!mounted) { timer.cancel(); return; }
                  setState(() {});
                });
              }
            },
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_revealed ? Icons.visibility_off : Icons.visibility, size: 16, color: const Color(0xFF0D631B)),
              const SizedBox(width: 4),
              Text(_revealed ? 'Hide' : 'Reveal', style: const TextStyle(fontSize: 12, color: Color(0xFF0D631B), fontWeight: FontWeight.w500)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: widget.codes.map((c) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F5), borderRadius: BorderRadius.circular(8)),
            child: _revealed
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(c, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF191C1D), letterSpacing: 1)),
                    const SizedBox(width: 8),
                    GestureDetector(onTap: () { Clipboard.setData(ClipboardData(text: c)); HapticFeedback.lightImpact(); }, child: const Icon(Icons.copy, size: 14, color: Color(0xFF40493D))),
                  ])
                : const Text('••••-••••', style: TextStyle(fontSize: 14, color: Color(0xFF40493D), letterSpacing: 1)),
          );
        }).toList()),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. SEEDS DETAIL SCREEN (Ledger Seed Phrase)
// ═══════════════════════════════════════════════════════════════
class SeedsDetailScreen extends StatelessWidget {
  final VaultItem item;
  const SeedsDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final f = item.fields;
    final words = (f['Seed Phrase'] ?? '').split(' ');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF191C1D)), onPressed: () => Navigator.pop(context)),
        title: Text(item.title, style: const TextStyle(color: Color(0xFF191C1D))),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Color(0xFF40493D)), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          Center(child: Column(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: item.iconBgColor, shape: BoxShape.circle), child: Icon(item.icon, size: 36, color: item.iconColor)),
            const SizedBox(height: 12),
            Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF191C1D))),
            const SizedBox(height: 4), Text('${words.length} words', style: const TextStyle(fontSize: 14, color: Color(0xFF40493D))),
          ])),
          const SizedBox(height: 24),

          // Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3))),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFF59E0B)),
              SizedBox(width: 10),
              Expanded(child: Text('Never share your seed phrase. Anyone with these words can steal your crypto.', style: TextStyle(fontSize: 13, color: Color(0xFFF59E0B), fontWeight: FontWeight.w500))),
            ]),
          ),
          const SizedBox(height: 16),

          // Seed phrase grid
          _SeedPhraseGrid(words: words),
          const SizedBox(height: 16),

          // Derivation path & network
          _RevealField(icon: Icons.route, label: 'Derivation Path', value: f['Derivation Path'] ?? '', isMono: true),
          const SizedBox(height: 12),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBFCABA).withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (f.containsKey('Network')) ...[
                _InfoRow('Network', f['Network']!),
                if (f.containsKey('Wallet')) const Divider(height: 20, color: Color(0xFFE1E3E4)),
              ],
              if (f.containsKey('Wallet')) ...[
                _InfoRow('Wallet', f['Wallet']!),
                if (f.containsKey('Created')) const Divider(height: 20, color: Color(0xFFE1E3E4)),
              ],
              if (f.containsKey('Created'))
                _InfoRow('Created', f['Created']!),
            ]),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _SeedPhraseGrid extends StatefulWidget {
  final List<String> words;
  const _SeedPhraseGrid({required this.words});

  @override
  State<_SeedPhraseGrid> createState() => _SeedPhraseGridState();
}

class _SeedPhraseGridState extends State<_SeedPhraseGrid> {
  bool _revealed = false;
  int _timer = 30;
  Timer? _t;

  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  void _startTimer() {
    _t?.cancel();
    setState(() => _timer = 30);
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timer--);
      if (_timer <= 0) { t.cancel(); if (mounted) setState(() => _revealed = false); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _revealed ? const Color(0xFFF59E0B).withOpacity(0.3) : const Color(0xFFBFCABA).withOpacity(0.3)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Seed Phrase', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _revealed ? const Color(0xFFF59E0B) : const Color(0xFF40493D))),
          GestureDetector(
            onTap: () {
              if (!_revealed) {
                setState(() => _revealed = true);
                _startTimer();
              } else {
                _t?.cancel();
                setState(() => _revealed = false);
              }
            },
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_revealed ? Icons.visibility_off : Icons.visibility, size: 16, color: const Color(0xFF0D631B)),
              const SizedBox(width: 4),
              Text(_revealed ? 'Hide' : 'Reveal', style: const TextStyle(fontSize: 12, color: Color(0xFF0D631B), fontWeight: FontWeight.w500)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.5,
          ),
          itemCount: widget.words.length,
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE1E3E4)),
              ),
              child: Row(children: [
                Text('${index + 1}.', style: const TextStyle(fontSize: 11, color: Color(0xFF40493D), fontWeight: FontWeight.w500)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _revealed ? widget.words[index] : '••••',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _revealed ? const Color(0xFF191C1D) : const Color(0xFF40493D)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            );
          },
        ),
        if (_revealed) ...[
          const SizedBox(height: 12),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Text('Auto-hide in $_timer s', style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w500)),
          ]),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 3. API KEYS DETAIL SCREEN (AWS Root Key, Crypto.com API)
// ═══════════════════════════════════════════════════════════════
class ApiKeysDetailScreen extends StatelessWidget {
  final VaultItem item;
  const ApiKeysDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final f = item.fields;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF191C1D)), onPressed: () => Navigator.pop(context)),
        title: Text(item.title, style: const TextStyle(color: Color(0xFF191C1D))),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Color(0xFF40493D)), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          Center(child: Column(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: item.iconBgColor, shape: BoxShape.circle), child: Icon(item.icon, size: 36, color: item.iconColor)),
            const SizedBox(height: 12),
            Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF191C1D))),
            const SizedBox(height: 4), Text(item.subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF40493D))),
          ])),
          const SizedBox(height: 24),

          // Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3))),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFF59E0B)),
              SizedBox(width: 10),
              Expanded(child: Text('API keys grant programmatic access. Keep them secret.', style: TextStyle(fontSize: 13, color: Color(0xFFF59E0B), fontWeight: FontWeight.w500))),
            ]),
          ),
          const SizedBox(height: 16),

          // API Key
          _RevealField(icon: Icons.vpn_key, label: f.containsKey('Access Key ID') ? 'Access Key ID' : 'API Key', value: f['Access Key ID'] ?? f['API Key'] ?? '', isMono: true),
          const SizedBox(height: 12),

          // API Secret
          _RevealField(icon: Icons.lock_outline, label: f.containsKey('Secret Access Key') ? 'Secret Access Key' : 'API Secret', value: f['Secret Access Key'] ?? f['API Secret'] ?? '', isWarning: true, isMono: true),
          const SizedBox(height: 12),

          // Info card with all remaining fields
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBFCABA).withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final entry in f.entries)
                if (!['Access Key ID', 'API Key', 'Secret Access Key', 'API Secret'].contains(entry.key)) ...[
                  _InfoRow(entry.key, entry.value),
                  if (entry.key != f.keys.lastWhere((k) => !['Access Key ID', 'API Key', 'Secret Access Key', 'API Secret'].contains(k)))
                    const Divider(height: 20, color: Color(0xFFE1E3E4)),
                ],
            ]),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 4. CODES DETAIL SCREEN (Recovery Codes)
// ═══════════════════════════════════════════════════════════════
class CodesDetailScreen extends StatelessWidget {
  final VaultItem item;
  const CodesDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final f = item.fields;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF191C1D)), onPressed: () => Navigator.pop(context)),
        title: Text(item.title, style: const TextStyle(color: Color(0xFF191C1D))),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Color(0xFF40493D)), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          Center(child: Column(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: item.iconBgColor, shape: BoxShape.circle), child: Icon(item.icon, size: 36, color: item.iconColor)),
            const SizedBox(height: 12),
            Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF191C1D))),
            const SizedBox(height: 4), Text(item.subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF40493D))),
          ])),
          const SizedBox(height: 24),

          // Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3))),
            child: const Row(children: [
              Icon(Icons.info_outline, size: 20, color: Color(0xFFF59E0B)),
              SizedBox(width: 10),
              Expanded(child: Text('Each code works only once. Store them safely.', style: TextStyle(fontSize: 13, color: Color(0xFFF59E0B), fontWeight: FontWeight.w500))),
            ]),
          ),
          const SizedBox(height: 16),

          // Per-service sections
          for (final entry in f.entries) ...[
            _ServiceCodeSection(service: entry.key, codes: entry.value.split('\n')),
            if (entry.key != f.keys.last) const SizedBox(height: 16),
          ],

          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _ServiceCodeSection extends StatefulWidget {
  final String service;
  final List<String> codes;
  const _ServiceCodeSection({required this.service, required this.codes});

  @override
  State<_ServiceCodeSection> createState() => _ServiceCodeSectionState();
}

class _ServiceCodeSectionState extends State<_ServiceCodeSection> {
  final Set<int> _revealed = {};

  Color get _serviceColor {
    switch (widget.service) {
      case 'Google': return const Color(0xFF4285F4);
      case 'GitHub': return const Color(0xFF333333);
      case 'Discord': return const Color(0xFF5865F2);
      default: return const Color(0xFF0D631B);
    }
  }

  IconData get _serviceIcon {
    switch (widget.service) {
      case 'Google': return Icons.email;
      case 'GitHub': return Icons.code;
      case 'Discord': return Icons.chat;
      default: return Icons.verified_user;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBFCABA).withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: _serviceColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(_serviceIcon, size: 16, color: _serviceColor)),
          const SizedBox(width: 10),
          Text(widget.service, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF191C1D))),
          const Spacer(), Text('${widget.codes.length} codes', style: const TextStyle(fontSize: 12, color: Color(0xFF40493D))),
        ]),
        const SizedBox(height: 12),
        ...widget.codes.asMap().entries.map((entry) {
          final idx = entry.key;
          final code = entry.value;
          final isRevealed = _revealed.contains(idx);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F5), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: _serviceColor, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isRevealed ? code : '••••-••••',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, fontFamily: 'monospace', color: isRevealed ? const Color(0xFF191C1D) : const Color(0xFF40493D), letterSpacing: 1),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() { if (isRevealed) _revealed.remove(idx); else _revealed.add(idx); }),
                child: Icon(isRevealed ? Icons.visibility_off : Icons.visibility, size: 16, color: const Color(0xFF0D631B)),
              ),
              const SizedBox(width: 12),
              if (isRevealed)
                GestureDetector(
                  onTap: () { Clipboard.setData(ClipboardData(text: code)); HapticFeedback.lightImpact(); },
                  child: const Icon(Icons.copy, size: 16, color: Color(0xFF40493D)),
                ),
            ]),
          );
        }),
      ]),
    );
  }
}
