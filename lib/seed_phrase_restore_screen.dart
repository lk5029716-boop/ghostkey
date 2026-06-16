// ═══════════════════════════════════════════════════════════════
// SEED PHRASE RESTORE SCREEN
// Restore vault from 24-word recovery phrase
// Two modes: Manual (24 individual inputs) or Paste (single text area)
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SeedPhraseRestoreScreen extends StatefulWidget {
  final VoidCallback? onRestore;
  final VoidCallback? onCancel;
  const SeedPhraseRestoreScreen({super.key, this.onRestore, this.onCancel});

  @override
  State<SeedPhraseRestoreScreen> createState() => _SeedPhraseRestoreScreenState();
}

class _SeedPhraseRestoreScreenState extends State<SeedPhraseRestoreScreen> {
  static const _wordCount = 24;

  // Theme
  static const _primary = Color(0xFF0D631B);
  static const _onPrimary = Color(0xFFFFFFFF);
  static const _onSurface = Color(0xFF191C1D);
  static const _onSurfaceVariant = Color(0xFF40493D);
  static const _surface = Color(0xFFF8F9FA);
  static const _surfaceContainerLow = Color(0xFFF3F4F5);
  static const _surfaceContainerHigh = Color(0xFFE7E8E9);
  static const _surfaceContainerHighest = Color(0xFFE1E3E4);
  static const _outline = Color(0xFF707A6C);
  static const _outlineVariant = Color(0xFFBFCABA);
  static const _secondaryContainer = Color(0xFFACF4A4);
  static const _onSecondaryContainer = Color(0xFF307231);
  static const _primaryFixedDim = Color(0xFF88D982);
  static const _onPrimaryFixed = Color(0xFF002204);
  static const _error = Color(0xFFBA1A1A);

  bool _manualMode = true;
  final List<TextEditingController> _wordCtrls =
      List.generate(_wordCount, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_wordCount, (_) => FocusNode());
  final TextEditingController _pasteCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in _wordCtrls) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _pasteCtrl.dispose();
    super.dispose();
  }

  void _onWordChanged(int index, String value) {
    if (value.endsWith(' ') || value.contains(' ')) {
      final words = value.trim().split(RegExp(r'\s+'));
      _distributeWords(words, index);
    } else if (value.isNotEmpty && index < _wordCount - 1) {
      // Auto-advance to next field
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _onWordKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _wordCtrls[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _distributeWords(List<String> words, int startIdx) {
    for (int i = 0; i < words.length; i++) {
      final target = startIdx + i;
      if (target < _wordCount) {
        _wordCtrls[target].text = words[i];
      }
    }
    final nextFocus = (startIdx + words.length).clamp(0, _wordCount - 1);
    _focusNodes[nextFocus].requestFocus();
    setState(() {});
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null) return;
    final text = data!.text!.trim();
    if (_manualMode) {
      final words = text.split(RegExp(r'\s+'));
      _distributeWords(words, 0);
    } else {
      _pasteCtrl.text = text;
      setState(() {});
    }
    HapticFeedback.lightImpact();
  }

  void _pastePasteModeToManual() {
    final words = _pasteCtrl.text.trim().split(RegExp(r'\s+'));
    _distributeWords(words, 0);
  }

  void _clearAll() {
    for (final c in _wordCtrls) c.clear();
    _pasteCtrl.clear();
    setState(() {});
  }

  void _onRestore() {
    final words = _manualMode
        ? _wordCtrls.map((c) => c.text.trim()).toList()
        : _pasteCtrl.text.trim().split(RegExp(r'\s+'));
    if (words.where((w) => w.isNotEmpty).length < 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 24 words')),
      );
      return;
    }
    widget.onRestore?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildPasteBar(),
                  const SizedBox(height: 16),
                  _buildModeSelector(),
                  const SizedBox(height: 16),
                  _manualMode
                      ? _buildManualGrid()
                      : _buildPasteArea(),
                  const SizedBox(height: 24),
                  _buildSecurityWarning(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: _onSurfaceVariant),
              onPressed: () => widget.onCancel?.call(),
            ),
            const Text('GhostKey',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _primary)),
            const Spacer(),
            const Icon(Icons.shield, color: _primary),
            const SizedBox(width: 16),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _primaryFixedDim,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person,
                  color: _onPrimaryFixed, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enter Recovery Phrase',
            style: TextStyle(
                fontSize: 28,
                height: 36 / 28,
                fontWeight: FontWeight.w600,
                color: _onSurface)),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                color: _onSurfaceVariant),
            children: [
              TextSpan(text: 'This 24-word seed phrase is the '),
              TextSpan(
                text: 'only way',
                style: TextStyle(
                    color: _primary, fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text:
                    ' to regain access to your encrypted vault. If lost, your digital assets cannot be recovered even by GhostKey support.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasteBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: _pasteFromClipboard,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _secondaryContainer,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.content_paste,
                    size: 18, color: _onSecondaryContainer),
                SizedBox(width: 6),
                Text('Paste from clipboard',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _onSecondaryContainer)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _modeChip('Manual', _manualMode, () {
            if (!_manualMode) {
              _pastePasteModeToManual();
              setState(() => _manualMode = true);
            }
          }),
          _modeChip('Paste all', !_manualMode, () {
            if (_manualMode) {
              setState(() {
                _manualMode = false;
                _pasteCtrl.text = _wordCtrls
                    .map((c) => c.text.trim())
                    .where((w) => w.isNotEmpty)
                    .join(' ');
              });
            }
          }),
        ],
      ),
    );
  }

  Widget _modeChip(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? _surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active
                ? Border.all(color: _outlineVariant)
                : Border.all(color: Colors.transparent),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: active ? _onSurface : _onSurfaceVariant)),
        ),
      ),
    );
  }

  Widget _buildManualGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 2 cols on narrow, 3 on medium, 4 on wide
        final crossAxisCount =
            constraints.maxWidth > 600 ? 4 : (constraints.maxWidth > 400 ? 3 : 2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: _wordCount,
          itemBuilder: (context, i) {
            return _wordInput(i);
          },
        );
      },
    );
  }

  Widget _wordInput(int i) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          bottom: BorderSide(
            color: _wordCtrls[i].text.isNotEmpty
                ? _primary
                : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            child: Text('${i + 1}',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _outline,
                    letterSpacing: 0.5)),
          ),
          Expanded(
            child: TextField(
              controller: _wordCtrls[i],
              focusNode: _focusNodes[i],
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'word',
                hintStyle: TextStyle(color: _outlineVariant),
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                  fontSize: 14, color: _onSurface),
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (v) => _onWordChanged(i, v),
              onTap: () => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasteArea() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _pasteCtrl,
        maxLines: 8,
        minLines: 6,
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
        enableSuggestions: false,
        style: const TextStyle(
            fontSize: 14, height: 1.6, color: _onSurface),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText:
              'Paste your 24-word recovery phrase here, separated by spaces.\n\nExample: word1 word2 word3 word4 ...',
          hintStyle: TextStyle(color: _outlineVariant),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildSecurityWarning() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: _error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Security Protocol',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _onSurface)),
                SizedBox(height: 4),
                Text(
                  'Ensure no one is watching your screen. GhostKey will perform a local decryption of your master key using this phrase. Your data never leaves your device unencrypted.',
                  style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: _onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _onRestore,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: _onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            icon: const Icon(Icons.lock_open),
            label: const Text('Decrypt & Restore',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _clearAll,
          child: const Text('Clear all',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _outline)),
        ),
        TextButton(
          onPressed: () => widget.onCancel?.call(),
          child: const Text('Cancel and return to login',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _outline)),
        ),
      ],
    );
  }
}
