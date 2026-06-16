// ═══════════════════════════════════════════════════════════════
// SEED PHRASE RESTORE SCREEN
// 12 or 24 word recovery phrase entry
// Two modes: Manual (individual inputs) or Paste (single area)
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SeedPhraseRestoreScreen extends StatefulWidget {
  final ValueChanged<String>? onSave;
  const SeedPhraseRestoreScreen({super.key, this.onSave});

  @override
  State<SeedPhraseRestoreScreen> createState() => _SeedPhraseRestoreScreenState();
}

class _SeedPhraseRestoreScreenState extends State<SeedPhraseRestoreScreen> {
  // Theme — match GhostKey
  static const _primary = Color(0xFF0D631B);
  static const _onPrimary = Color(0xFFFFFFFF);
  static const _onSurface = Color(0xFF191C1D);
  static const _onSurfaceVariant = Color(0xFF40493D);
  static const _surface = Color(0xFFF8F9FA);
  static const _surfaceContainerLow = Color(0xFFF3F4F5);
  static const _outline = Color(0xFF707A6C);
  static const _outlineVariant = Color(0xFFBFCABA);
  static const _secondaryContainer = Color(0xFFACF4A4);
  static const _onSecondaryContainer = Color(0xFF307231);

  // Word count: 12 or 24
  static const List<int> _wordCounts = [12, 24];
  int _wordCount = 24;

  bool _manualMode = true;
  final TextEditingController _pasteCtrl = TextEditingController();
  List<TextEditingController> _wordCtrls = [];
  List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    _initControllers(_wordCount);
  }

  void _initControllers(int n) {
    _wordCtrls = List.generate(n, (_) => TextEditingController());
    _focusNodes = List.generate(n, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _wordCtrls) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _pasteCtrl.dispose();
    super.dispose();
  }

  void _setWordCount(int n) {
    if (n == _wordCount) return;
    for (final c in _wordCtrls) c.dispose();
    for (final f in _focusNodes) f.dispose();
    setState(() {
      _wordCount = n;
      _initControllers(n);
    });
  }

  void _onWordChanged(int index, String value) {
    if (value.contains(RegExp(r'\s'))) {
      final words = value.trim().split(RegExp(r'\s+'));
      _distributeWords(words, index);
    } else if (value.isNotEmpty && index < _wordCount - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
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

  void _onSave() {
    final words = _manualMode
        ? _wordCtrls.map((c) => c.text.trim()).toList()
        : _pasteCtrl.text.trim().split(RegExp(r'\s+'));
    final filled = words.where((w) => w.isNotEmpty).toList();
    if (filled.length < _wordCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter all $_wordCount words')),
      );
      return;
    }
    final phrase = filled.join(' ');
    widget.onSave?.call(phrase);
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recovery Phrase',
                      style: TextStyle(
                          fontSize: 28,
                          height: 36 / 28,
                          fontWeight: FontWeight.w600,
                          color: _onSurface)),
                  const SizedBox(height: 4),
                  Text(
                    _manualMode
                        ? 'Enter your $_wordCount-word phrase in order'
                        : 'Paste your $_wordCount-word phrase separated by spaces',
                    style: const TextStyle(
                        fontSize: 14,
                        color: _onSurfaceVariant,
                        height: 20 / 14),
                  ),
                  const SizedBox(height: 20),
                  _buildWordCountSelector(),
                  const SizedBox(height: 12),
                  _buildModeSelector(),
                  const SizedBox(height: 16),
                  _buildPasteBar(),
                  const SizedBox(height: 12),
                  _manualMode ? _buildManualGrid() : _buildPasteArea(),
                ],
              ),
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: _onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Text('Recovery Phrase',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCountSelector() {
    return Row(
      children: _wordCounts.map((n) {
        final active = n == _wordCount;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: n == 12 ? 8 : 0),
            child: GestureDetector(
              onTap: () => _setWordCount(n),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? _primary : _surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active ? _primary : _outlineVariant,
                  ),
                ),
                child: Text(
                  '$n words',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: active ? _onPrimary : _onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _modeChip('Manual', _manualMode, () {
            if (!_manualMode) {
              _pasteCtrlToManual();
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

  void _pasteCtrlToManual() {
    final words = _pasteCtrl.text.trim().split(RegExp(r'\s+'));
    _distributeWords(words, 0);
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
            border: Border.all(
              color: active ? _outlineVariant : Colors.transparent,
            ),
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

  Widget _buildPasteBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: _pasteFromClipboard,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                Text('Paste',
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

  Widget _buildManualGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth > 600 ? 4 : (constraints.maxWidth > 400 ? 3 : 2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
          ),
          itemCount: _wordCount,
          itemBuilder: (context, i) => _wordInput(i),
        );
      },
    );
  }

  Widget _wordInput(int i) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          bottom: BorderSide(
            color: _wordCtrls[i].text.isNotEmpty ? _primary : Colors.transparent,
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
              style: const TextStyle(fontSize: 14, color: _onSurface),
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              onChanged: (v) => _onWordChanged(i, v),
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
      padding: const EdgeInsets.all(14),
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
              'Paste your recovery phrase here, separated by spaces.',
          hintStyle: TextStyle(color: _outlineVariant),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: _onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Save',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
          ),
        ),
      ),
    );
  }
}
