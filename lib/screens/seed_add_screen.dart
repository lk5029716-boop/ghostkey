import 'dart:math' as math;
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
  static const _secondaryContainer = Color(0xFFACF4A4);

  static const _networks = ['Ethereum', 'Bitcoin', 'Solana', 'Polygon', 'BSC', 'Avalanche', 'Arbitrum', 'Optimism', 'Other'];
  static const _wallets = ['Ledger Nano X', 'Ledger Nano S', 'Trezor Model T', 'Trezor One', 'GridPlus', 'Keystone', 'Software', 'Other'];

  final _titleCtrl = TextEditingController();
  final _phraseCtrl = TextEditingController();
  final _derivationCtrl = TextEditingController(text: "m/44'/60'/0'/0/0");
  final _networkCtrl = TextEditingController();
  final _walletCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _phraseRevealed = false;
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
    _derivationCtrl.dispose();
    _networkCtrl.dispose();
    _walletCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  static int _wordCount(String value) =>
      value.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  void _onPhraseChanged(String value) {
    final words = _wordCount(value);
    final allValid = words > 0 && _wordlistLoaded && value.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).every((w) => Bip39Validator.isValidWord(w));
    setState(() {
      _phraseValid = allValid && (words == 12 || words == 24);
      _errorMessage = null;
    });
  }

  Future<void> _pastePhrase() async {
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
    if (words.length != 12 && words.length != 24) return _showError('Seed phrase must be 12 or 24 words (got ${words.length})');

    final validation = Bip39Validator.validate(words);
    if (!validation.isValid) return _showError(validation.error ?? 'Invalid seed phrase (checksum failed)');

    setState(() => _saving = true);
    try {
      HapticFeedback.mediumImpact();

      final fields = <String, String>{
        'Seed Phrase': phrase,
        'Word Count': words.length.toString(),
        if (_derivationCtrl.text.trim().isNotEmpty) 'Derivation Path': _derivationCtrl.text.trim(),
        if (_networkCtrl.text.trim().isNotEmpty) 'Network': _networkCtrl.text.trim(),
        if (_walletCtrl.text.trim().isNotEmpty) 'Wallet': _walletCtrl.text.trim(),
        if (_notesCtrl.text.trim().isNotEmpty) 'Notes': _notesCtrl.text.trim(),
      };

      await VaultStore.instance.addItem(VaultItem(
        id: '',
        title: title,
        subtitle: '${words.length} words',
        category: VaultCategory.seeds,
        icon: Icons.memory,
        iconColor: _primary,
        iconBgColor: const Color(0xFFC8E6C9),
        date: 'Today',
        fields: fields,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Add Seed Phrase', style: TextStyle(color: _onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text('Save', style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field('Title *', _titleCtrl, 'e.g. Ledger Seed, Trezor Backup'),
            const SizedBox(height: 12),
            _phraseField(),
            const SizedBox(height: 12),
            _field('Derivation Path', _derivationCtrl, "m/44'/60'/0'/0/0"),
            const SizedBox(height: 12),
            _dropdownField('Network', _networkCtrl, _networks, 'Select network'),
            const SizedBox(height: 12),
            _dropdownField('Wallet', _walletCtrl, _wallets, 'Select wallet'),
            const SizedBox(height: 12),
            _field('Notes', _notesCtrl, 'Optional notes', maxLines: 3),
            const SizedBox(height: 8),
            _generateButton(),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {int maxLines = 1, ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _onSurfaceVariant)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _outlineVariant, fontSize: 14),
            filled: true,
            fillColor: _surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: TextStyle(fontSize: 14, color: _onSurface, fontFamily: maxLines > 1 ? null : 'monospace'),
        ),
      ],
    );
  }

  Widget _phraseField() {
    final count = _wordCount(_phraseCtrl.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Seed Phrase *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _onSurfaceVariant)),
            if (_phraseCtrl.text.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _phraseRevealed = !_phraseRevealed),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_phraseRevealed ? Icons.visibility_off : Icons.visibility, size: 16, color: _primary),
                  const SizedBox(width: 4),
                  Text(_phraseRevealed ? 'Hide' : 'Show', style: const TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.w500)),
                ]),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _phraseCtrl,
          obscureText: !_phraseRevealed,
          onChanged: _onPhraseChanged,
          maxLines: _phraseRevealed ? 3 : 1,
          decoration: InputDecoration(
            hintText: 'Enter 12 or 24 word seed phrase',
            hintStyle: const TextStyle(color: _outlineVariant, fontSize: 14),
            filled: true,
            fillColor: _surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_paste, size: 20, color: _primary),
              onPressed: _pastePhrase,
              tooltip: 'Paste from clipboard',
            ),
          ),
          style: const TextStyle(fontSize: 14, color: _onSurface, fontFamily: 'monospace', letterSpacing: 0.5),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.error_outline, size: 14, color: _error),
            const SizedBox(width: 6),
            Expanded(child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: _error))),
          ]),
        ] else if (count > 0 && _wordlistLoaded) ...[
          const SizedBox(height: 6),
          Row(children: [
            Icon(_phraseValid ? Icons.check_circle : Icons.warning, size: 14, color: _phraseValid ? _primary : _error),
            const SizedBox(width: 6),
            Text(
              _phraseValid ? '$count-word phrase ✓' : 'Invalid phrase (check word count or spelling)',
              style: TextStyle(fontSize: 12, color: _phraseValid ? _primary : _error, fontWeight: FontWeight.w500),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _dropdownField(String label, TextEditingController ctrl, List<String> options, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _onSurfaceVariant)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonFormField<String>(
            value: ctrl.text.isEmpty ? null : ctrl.text,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _outlineVariant, fontSize: 14),
              filled: true,
              fillColor: _surfaceContainerLow,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 14, color: _onSurface)))).toList(),
            onChanged: (val) => setState(() => ctrl.text = val ?? ''),
            style: const TextStyle(fontSize: 14, color: _onSurface),
            dropdownColor: _surface,
          ),
        ),
      ],
    );
  }

  Widget _generateButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _wordlistLoaded && !_saving
            ? () {
                final wordlist = Bip39Validator.words;
                if (wordlist == null || wordlist.isEmpty) return;
                final rng = math.Random.secure();
                final selected = List.generate(24, (_) => wordlist[rng.nextInt(wordlist.length)]);
                final phrase = selected.join(' ');
                _phraseCtrl.text = phrase;
                _onPhraseChanged(phrase);
                setState(() => _phraseRevealed = true);
              }
            : null,
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: const Text('Generate random 24-word phrase'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _outlineVariant),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
