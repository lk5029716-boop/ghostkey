import 'package:flutter/material.dart';
import '../vault_data.dart';
import '../store/vault_store.dart';

// ═══════════════════════════════════════════════════════════════
// SECURE NOTE ADD SCREEN
// ═══════════════════════════════════════════════════════════════

class SecureNoteAddScreen extends StatefulWidget {
  const SecureNoteAddScreen({super.key});

  @override
  State<SecureNoteAddScreen> createState() => _SecureNoteAddScreenState();
}

class _SecureNoteAddScreenState extends State<SecureNoteAddScreen> {
  static const _primary = Color(0xFF0D631B);
  static const _surface = Color(0xFFF8F9FA);
  static const _onSurface = Color(0xFF191C1D);
  static const _onSurfaceVariant = Color(0xFF40493D);
  static const _outlineVariant = Color(0xFFBFCABA);
  static const _surfaceContainerLow = Color(0xFFF3F4F5);

  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
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
        subtitle: _contentCtrl.text.trim().length > 50
            ? '${_contentCtrl.text.trim().substring(0, 50)}...'
            : _contentCtrl.text.trim(),
        category: VaultCategory.codes,
        icon: Icons.description,
        iconColor: const Color(0xFF00796B),
        iconBgColor: const Color(0xFFB2DFDB),
        date: 'Today',
        fields: {
          'Content': _contentCtrl.text.trim(),
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
        title: const Text('Add Secure Note', style: TextStyle(color: _onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text('Save', style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 16))),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Title *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _onSurfaceVariant)),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. WiFi Password, PIN Code',
              hintStyle: const TextStyle(color: _outlineVariant, fontSize: 14),
              filled: true, fillColor: _surfaceContainerLow,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14, color: _onSurface),
          ),
          const SizedBox(height: 16),
          const Text('Content *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _onSurfaceVariant)),
          const SizedBox(height: 6),
          Expanded(
            child: TextField(
              controller: _contentCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Write your secure note here...',
                hintStyle: const TextStyle(color: _outlineVariant, fontSize: 14),
                filled: true, fillColor: _surfaceContainerLow,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(14),
              ),
              style: const TextStyle(fontSize: 14, color: _onSurface),
            ),
          ),
        ]),
      ),
    );
  }
}
