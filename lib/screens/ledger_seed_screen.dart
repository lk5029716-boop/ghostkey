import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LedgerSeedPhraseScreen extends StatefulWidget {
  const LedgerSeedPhraseScreen({super.key});

  @override
  State<LedgerSeedPhraseScreen> createState() => _LedgerSeedPhraseScreenState();
}

class _LedgerSeedPhraseScreenState extends State<LedgerSeedPhraseScreen> {
  bool _revealed = false;
  int _timeLeft = 30;
  Timer? _timer;

  final List<String> _words = List.generate(24, (i) => 'word${i + 1}');

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _revealed = true;
      _timeLeft = 30;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _timeLeft--;
      });
      if (_timeLeft <= 0) {
        t.cancel();
        setState(() {
          _revealed = false;
        });
      }
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _words.join(' ')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final surfaceContainerLowest = Theme.of(context).colorScheme.surfaceContainerLowest;
    final surfaceContainerHigh = Theme.of(context).colorScheme.surfaceContainerHigh;
    final surfaceContainerLow = Theme.of(context).colorScheme.surfaceContainerLow;
    final secondaryContainer = Theme.of(context).colorScheme.secondaryContainer;
    final onSecondaryContainer = Theme.of(context).colorScheme.onSecondaryContainer;
    final error = Theme.of(context).colorScheme.error;
    final errorContainer = Theme.of(context).colorScheme.errorContainer;

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            // Hero
            Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.vpn_key,
                    size: 40,
                    color: onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ledger Seed Phrase',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Seed Phrase',
                  style: TextStyle(fontSize: 14, color: onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Blurred secret container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: surfaceContainerHigh),
              ),
              child: Stack(
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: _words.map((w) {
                      return Text(
                        w,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      );
                    }).toList(),
                  ),
                  if (!_revealed)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: surfaceContainerLowest.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: _startTimer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: secondaryContainer,
                              foregroundColor: onSecondaryContainer,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.visibility, size: 18),
                                const SizedBox(width: 8),
                                const Text('Reveal'),
                              ],
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
              children: [
                Icon(Icons.warning, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Make sure no one is watching your screen.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Actions list
            Container(
              decoration: BoxDecoration(
                color: surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: surfaceContainerHigh),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  _actionTile(
                    icon: Icons.content_copy,
                    label: 'Copy to clipboard',
                    onTap: _copyToClipboard,
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                  ),
                  _actionTile(
                    icon: Icons.upload,
                    label: 'Export',
                    onTap: () {},
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                  ),
                  _actionTile(
                    icon: Icons.edit,
                    label: 'Edit',
                    onTap: () {},
                    primary: primary,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                  ),
                  _actionTile(
                    icon: Icons.delete,
                    label: 'Delete',
                    onTap: () {},
                    isError: true,
                    error: error,
                    errorContainer: errorContainer,
                    onSurface: onSurface,
                    onSurfaceVariant: onSurfaceVariant,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // Auto-hide timer
            if (_revealed)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Auto-hide in ${_timeLeft}s',
                    style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: (30 - _timeLeft) / 30,
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                      backgroundColor: surfaceContainerHigh,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color primary,
    required Color onSurface,
    required Color onSurfaceVariant,
    bool isError = false,
    Color? error,
    Color? errorContainer,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isError ? error : onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isError ? error : onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isError ? error : onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
