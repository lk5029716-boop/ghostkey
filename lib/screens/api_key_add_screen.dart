import 'package:flutter/material.dart';
import '../vault_data.dart';
import '../store/vault_store.dart';

// ═══════════════════════════════════════════════════════════════
// API KEY ADD SCREEN
// ═══════════════════════════════════════════════════════════════

class ApiKeyAddScreen extends StatefulWidget {
  const ApiKeyAddScreen({super.key});

  @override
  State<ApiKeyAddScreen> createState() => _ApiKeyAddScreenState();
}

class _ApiKeyAddScreenState extends State<ApiKeyAddScreen> {
  static const _primary = Color(0xFF0D631B);
  static const _surface = Color(0xFFF8F9FA);
  static const _onSurface = Color(0xFF191C1D);
  static const _onSurfaceVariant = Color(0xFF40493D);
  static const _outlineVariant = Color(0xFFBFCABA);
  static const _surfaceContainerLow = Color(0xFFF3F4F5);

  final _titleCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _apiSecretCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _secretRevealed = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _apiKeyCtrl.dispose();
    _apiSecretCtrl.dispose();
    _urlCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      await VaultStore.instance.addItem(VaultItem(
        id: '',
        title: _titleCtrl.text.trim(),
        subtitle: _apiKeyCtrl.text.trim(),
        category: VaultCategory.apiKeys,
        icon: Icons.vpn_key,
        iconColor: const Color(0xFFF57C00),
        iconBgColor: const Color(0xFFFFE0B2),
        date: 'Today',
        fields: {
          'API Key': _apiKeyCtrl.text.trim(),
          if (_apiSecretCtrl.text.isNotEmpty) 'API Secret': _apiSecretCtrl.text,
          if (_urlCtrl.text.trim().isNotEmpty) 'Endpoint URL': _urlCtrl.text.trim(),
          if (_notesCtrl.text.trim().isNotEmpty) 'Notes': _notesCtrl.text.trim(),
        },
      ));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _onSurface), onPressed: () => Navigator.pop(context)),
        title: const Text('Add API Key', style: TextStyle(color: _onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text('Save', style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 16))),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _field('Title *', _titleCtrl, 'e.g. AWS, Crypto.com'),
          const SizedBox(height: 12),
          _field('API Key *', _apiKeyCtrl, 'Enter API key'),
          const SizedBox(height: 12),
          _secretField(),
          const SizedBox(height: 12),
          _field('Endpoint URL', _urlCtrl, 'https://api.example.com'),
          const SizedBox(height: 12),
          _field('Notes', _notesCtrl, 'Optional notes', maxLines: 3),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _onSurfaceVariant)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl, maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: _outlineVariant, fontSize: 14),
          filled: true, fillColor: _surfaceContainerLow,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        style: const TextStyle(fontSize: 14, color: _onSurface),
      ),
    ]);
  }

  Widget _secretField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('API Secret', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _onSurfaceVariant)),
        GestureDetector(
          onTap: () => setState(() => _secretRevealed = !_secretRevealed),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_secretRevealed ? Icons.visibility_off : Icons.visibility, size: 16, color: _primary),
            const SizedBox(width: 4),
            Text(_secretRevealed ? 'Hide' : 'Show', style: const TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.w500)),
          ]),
        ),
      ]),
      const SizedBox(height: 6),
      TextField(
        controller: _apiSecretCtrl, obscureText: !_secretRevealed,
        decoration: InputDecoration(
          hintText: 'Enter API secret', hintStyle: const TextStyle(color: _outlineVariant, fontSize: 14),
          filled: true, fillColor: _surfaceContainerLow,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        style: const TextStyle(fontSize: 14, color: _onSurface, fontFamily: 'monospace'),
      ),
    ]);
  }
}
