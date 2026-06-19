import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../vault_data.dart';
import '../store/vault_store.dart';
import '../crypto/bip39.dart';

class SeedAddScreen extends StatefulWidget {
  const SeedAddScreen({super.key});

  @override
  State<SeedAddScreen> createState() => _SeedAddScreenState();
}

class _SeedAddScreenState extends State<SeedAddScreen> {
  static const _primary = Color(0xFF0D631B);
  static const _surface = Color(0xFFF8F9FA);
  static const _onSurface = Color(0xFF191C1D);
  static const _onSurfaceVariant = Color(0xFF40493D);
  static const _outlineVariant = Color(0xFFBFCABA);
  static const _surfaceContainerLow = Color(0xFFF3F4F5);
  static const _error = Color(0xFFBA1A1A);

  final _titleCtrl = TextEditingController();
  final _phraseCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _revealed = false;
  bool _saving = false;
  bool _phraseValid = false;
  String? _errorMessage;
  bool _wordlistLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadWordlist();
  }

  Future<void> _loadWordlist() async {
    try {
      await Bip39Validator.loadWordlist();
      if (mounted) setState(() => _wordlistLoaded = true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Failed to load wordlist: $e');
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _phraseCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  int get _wordCount =>
      _phraseCtrl.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  void _onPhraseChanged(String value) {
    final words = value.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final allValid = words.isEmpty ? false : words.every((w) => Bip39Validator.isValidWord(w));
    final validCount = words.length == 12 || words.length == 24;
    setState(() {
      _phraseValid = allValid && validCount;
      _errorMessage = null;
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null) return;
    _phraseCtrl.text = data!.text!.trim();
    _onPhraseChanged(_phraseCtrl.text);
    HapticFeedback.lightImpact();
  }

  Future<void> _save() async {
    if (!_wordlistLoaded) return _showError('Wordlist not loaded yet. Please wait.');

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return _showError('Title is required');

    final phrase = _phraseCtrl.text.trim();
    if (phrase.isEmpty) return _showError('Seed phrase is required');

    final words = phrase.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length != 12 && words.length != 24) {
      return _showError('Seed phrase must be 12 or 24 words (got ${words.length})');
    }

    final validation = Bip39Validator.validate(words);
    if (!validation.isValid) {
      return _showError(validation.error ?? 'Invalid seed phrase (checksum failed)');
    }

    setState(() => _saving = true);
    try {
      HapticFeedback.mediumImpact();

      await VaultStore.instance.addItem(VaultItem(
        id: '',
        title: title,
        subtitle: '${words.length} words',
        category: VaultCategory.seeds,
        icon: Icons.key,
        iconColor: _primary,
        iconBgColor: const Color(0xFFC8E6C9),
        date: 'Today',
        fields: {
          'Seed Phrase': phrase,
          'Word Count': '${words.length}',
          if (_notesCtrl.text.trim().isNotEmpty) 'Notes': _notesCtrl.text.trim(),
        },
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seed phrase saved securely'),
          backgroundColor: _primary,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      _showError('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    setState(() => _errorMessage = msg);
    HapticFeedback.heavyImpact();
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _onSurfaceVariant)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _outlineVariant, fontSize: 14),
            filled: true,
            fillColor: _surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: const TextStyle(fontSize: 14, color: _onSurface, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _onSurface), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Add Seed Phrase', style: TextStyle(color: _onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text('Save', style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 16))),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _field('Title *', _titleCtrl, 'e.g. Ledger Seed, Trezor Backup'),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Seed Phrase *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _onSurfaceVariant)),
                  if (_phraseCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() => _revealed = !_revealed);
                        if (!_revealed) {
                          // Switch back to single-line when hiding
                          setState(() {});
                        }
                      },
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_revealed ? Icons.visibility_off : Icons.visibility, size: 16, color: _primary),
                        const SizedBox(width: 4),
                        Text(_revealed ? 'Hide' : 'Show', style: const TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _phraseCtrl,
                obscureText: !_revealed,
                maxLines: !_revealed ? 1 : 3,
                onChanged: _onPhraseChanged,
                decoration: InputDecoration(
                  hintText: 'Enter 12 or 24 word seed phrase',
                  hintStyle: const TextStyle(color: _outlineVariant, fontSize: 14),
                  filled: true,
                  fillColor: _surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste, size: 20, color: _primary),
                    onPressed: _pasteFromClipboard,
                    tooltip: 'Paste from clipboard',
                  ),
                ),
                style: const TextStyle(fontSize: 14, color: _onSurface, fontFamily: 'monospace'),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.error_outline, size: 14, color: _error),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: _error))),
                ]),
              ] else if (_phraseCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Icon(_phraseValid ? Icons.check_circle : Icons.warning, size: 14, color: _phraseValid ? _primary : _error),
                  const SizedBox(width: 6),
                  Text(
                    _phraseValid ? '$_wordCount words' : 'Invalid phrase',
                    style: TextStyle(fontSize: 12, color: _phraseValid ? _primary : _error, fontWeight: FontWeight.w500),
                  ),
                ]),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _field('Notes', _notesCtrl, 'Optional notes', maxLines: 3),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}