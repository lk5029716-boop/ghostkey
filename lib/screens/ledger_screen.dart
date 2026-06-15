import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  bool _revealed = false;
  int _timer = 30;
  Timer? _t;

  final List<String> _words = List.generate(24, (i) => 'word${i + 1}');

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _reveal() {
    setState(() {
      _revealed = true;
      _timer = 30;
    });
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _timer--);
      if (_timer <= 0) {
        timer.cancel();
        if (mounted) setState(() => _revealed = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [IconButton(icon: const Icon(Icons.more_vert), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Icon(Icons.vpn_key, size: 64, color: cs.secondaryContainer),
            const SizedBox(height: 16),
            const Text('Ledger Seed Phrase', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Seed Phrase', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Stack(
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: _words.map((w) => Center(child: Text(w, style: const TextStyle(fontSize: 16)))).toList(),
                  ),
                  if (!_revealed)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: ElevatedButton.icon(
                            onPressed: _reveal,
                            icon: const Icon(Icons.visibility),
                            label: const Text('Reveal'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Expanded(child: Text('Make sure no one is watching your screen.', style: TextStyle(fontSize: 12, color: Colors.orange[700]))),
            ]),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    alignment: Alignment.centerLeft,
                    child: const Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                  ),
                  _tile(Icons.content_copy, 'Copy to clipboard', () {
                    Clipboard.setData(ClipboardData(text: _words.join(' ')));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                  }),
                  _tile(Icons.upload, 'Export', () {}),
                  _tile(Icons.edit, 'Edit', () {}),
                  _tile(Icons.delete, 'Delete', () {}, isError: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_revealed)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.timer, size: 16),
                const SizedBox(width: 8),
                Text('Auto-hide in $_timer s', style: TextStyle(color: cs.onSurfaceVariant)),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap, {bool isError = false}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 20, color: isError ? cs.error : cs.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: TextStyle(fontSize: 16, color: isError ? cs.error : cs.onSurface))),
          Icon(Icons.chevron_right, size: 20, color: isError ? cs.error : cs.onSurfaceVariant),
        ]),
      ),
    );
  }
}
