import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../vault_data.dart';
import '../store/vault_store.dart';

// ═══════════════════════════════════════════════════════════════
// PASSWORD ADD SCREEN
// ═══════════════════════════════════════════════════════════════

class PasswordAddScreen extends StatefulWidget {
  const PasswordAddScreen({super.key});

  @override
  State<PasswordAddScreen> createState() => _PasswordAddScreenState();
}

class _PasswordAddScreenState extends State<PasswordAddScreen> {
  static const _primary = Color(0xFF0D631B);
  static const _surface = Color(0xFFF8F9FA);
  static const _onSurface = Color(0xFF191C1D);
  static const _onSurfaceVariant = Color(0xFF40493D);
  static const _outlineVariant = Color(0xFFBFCABA);
  static const _surfaceContainerLow = Color(0xFFF3F4F5);
  static const _error = Color(0xFFBA1A1A);

  final _titleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _revealed = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _urlCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await VaultStore.instance.addItem(VaultItem(
        id: '',
        title: _titleCtrl.text.trim(),
        subtitle: _emailCtrl.text.trim().isNotEmpty
            ? _emailCtrl.text.trim()
            : _urlCtrl.text.trim(),
        category: VaultCategory.password,
        icon: Icons.lock,
        iconColor: const Color(0xFF1976D2),
        iconBgColor: const Color(0xFFBBDEFB),
        date: 'Today',
        fields: {
          if (_emailCtrl.text.trim().isNotEmpty) 'Email': _emailCtrl.text.trim(),
          if (_passwordCtrl.text.isNotEmpty) 'Password': _passwordCtrl.text,
          if (_urlCtrl.text.trim().isNotEmpty) 'URL': _urlCtrl.text.trim(),
          if (_notesCtrl.text.trim().isNotEmpty) 'Notes': _notesCtrl.text.trim(),
        },
      ));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
        title: const Text('Add Password', style: TextStyle(color: _onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text('Save',
                style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field('Title *', _titleCtrl, 'e.g. Google, Binance'),
            const SizedBox(height: 12),
            _field('Email / Username', _emailCtrl, 'alex@gmail.com'),
            const SizedBox(height: 12),
            _passwordField(),
            const SizedBox(height: 12),
            _field('Website URL', _urlCtrl, 'https://example.com'),
            const SizedBox(height: 12),
            _field('Notes', _notesCtrl, 'Optional notes', maxLines: 3),
            const SizedBox(height: 8),
            _generateButton(),
          ],
        ),
      ),
    );
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
          style: const TextStyle(fontSize: 14, color: _onSurface),
        ),
      ],
    );
  }

  Widget _passwordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _onSurfaceVariant)),
            GestureDetector(
              onTap: () => setState(() => _revealed = !_revealed),
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
          controller: _passwordCtrl,
          obscureText: !_revealed,
          decoration: InputDecoration(
            hintText: 'Enter password',
            hintStyle: const TextStyle(color: _outlineVariant, fontSize: 14),
            filled: true,
            fillColor: _surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: IconButton(
              icon: const Icon(Icons.refresh, size: 18, color: _primary),
              onPressed: () {
                const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
                final rng = DateTime.now().millisecondsSinceEpoch;
                _passwordCtrl.text = List.generate(20, (i) => chars[(rng + i * 7) % chars.length]).join();
                setState(() => _revealed = true);
              },
            ),
          ),
          style: const TextStyle(fontSize: 14, color: _onSurface, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  Widget _generateButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=';
          final rng = DateTime.now().microsecondsSinceEpoch;
          _passwordCtrl.text = List.generate(24, (i) => chars[(rng + i * 13) % chars.length]).join();
          setState(() => _revealed = true);
        },
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: const Text('Generate strong password'),
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
