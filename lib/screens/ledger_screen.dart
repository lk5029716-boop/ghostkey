import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> with TickerProviderStateMixin {
  bool _revealed = false;
  int _timer = 30;
  Timer? _t;
  late AnimationController _progressController;

  final List<String> _words = List.generate(24, (i) => 'word${i + 1}');

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    _progressController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _reveal() {
    setState(() {
      _revealed = true;
      _timer = 30;
    });
    _progressController.forward(from: 0);
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
    final gold = const Color(0xFFF0D25A);
    final navy = const Color(0xFF0F1226);
    final surface = const Color(0xFF151833);
    final surfaceContainer = const Color(0xFF1C2040);

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Hero icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.vpn_key, size: 48, color: Color(0xFFF0D25A)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ledger Seed Phrase',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Seed Phrase',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Secret container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: surfaceContainer),
              ),
              child: Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _revealed
                        ? GridView.count(
                            key: const ValueKey('revealed'),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            children: _words.map((w) => Center(
                              child: Text(w, style: const TextStyle(fontSize: 16, color: Colors.white)),
                            )).toList(),
                          )
                        : GridView.count(
                            key: const ValueKey('blurred'),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            children: _words.map((w) => Center(
                              child: Text(w, style: const TextStyle(fontSize: 16, color: Colors.white54)),
                            )).toList(),
                          ),
                  ),
                  if (!_revealed)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: surface.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: ElevatedButton.icon(
                            onPressed: _reveal,
                            icon: const Icon(Icons.visibility, color: Color(0xFF0F1226)),
                            label: const Text('Reveal', style: TextStyle(color: Color(0xFF0F1226), fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gold,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Warning
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Make sure no one is watching your screen.',
                  style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Actions
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: surfaceContainer),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: surfaceContainer,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Actions',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: Colors.white70),
                    ),
                  ),
                  _tile(Icons.content_copy, 'Copy to clipboard', () {
                    Clipboard.setData(ClipboardData(text: _words.join(' ')));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  }),
                  _tile(Icons.upload, 'Export', () {}),
                  _tile(Icons.edit, 'Edit', () {}),
                  _tile(Icons.delete, 'Delete', () {}, isError: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Timer
            AnimatedOpacity(
              opacity: _revealed ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text('Auto-hide in $_timer s', style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: _revealed ? (30 - _timer) / 30 : 0,
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(gold),
                      backgroundColor: surfaceContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap, {bool isError = false}) {
    final cs = Theme.of(context).colorScheme;
    final errorColor = const Color(0xFFBA1A1A);
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isError ? errorColor : cs.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: TextStyle(fontSize: 16, color: isError ? errorColor : cs.onSurface))),
            Icon(Icons.chevron_right, size: 20, color: isError ? errorColor : cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
