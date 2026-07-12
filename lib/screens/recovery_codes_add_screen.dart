import 'package:flutter/material.dart';
import '../vault_data.dart';
import '../store/vault_store.dart';

// ═══════════════════════════════════════════════════════════════
// RECOVERY CODES ADD SCREEN
// ═══════════════════════════════════════════════════════════════

class RecoveryCodesAddScreen extends StatefulWidget {
  const RecoveryCodesAddScreen({super.key});

  @override
  State<RecoveryCodesAddScreen> createState() => _RecoveryCodesAddScreenState();
}

class _RecoveryCodesAddScreenState extends State<RecoveryCodesAddScreen> {
  static const _primary = Color(0xFF5B3FE8);
  static const _surface = Color(0xFFF8F9FF);
  static const _onSurface = Color(0xFF12101E);
  static const _onSurfaceVariant = Color(0xFF8E8BA8);
  static const _outlineVariant = Color(0xFF8E8BA8);
  static const _surfaceContainerLow = Color(0xFFF8F9FF);

  final _titleCtrl = TextEditingController();
  final _codesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _codesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    if (_codesCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter at least one code')));
      return;
    }
    setState(() => _saving = true);
    try {
      final codes = _codesCtrl.text.trim().split(RegExp(r'[\s\n,]+')).where((c) => c.isNotEmpty).toList();
      await VaultStore.instance.addItem(VaultItem(
        id: '',
        title: _titleCtrl.text.trim(),
        subtitle: '${codes.length} codes',
        category: VaultCategory.codes,
        icon: Icons.grid_view,
        iconColor: const Color(0xFF5B3FE8),
        iconBgColor: const Color(0xFFEBE8FF),
        date: 'Today',
        fields: {
          _titleCtrl.text.trim(): codes.join('\n'),
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
        title: const Text('Add Recovery Codes', style: TextStyle(color: _onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text('Save', style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 16))),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _field('Title *', _titleCtrl, 'e.g. Google, GitHub'),
          const SizedBox(height: 12),
          _codesField(),
          const SizedBox(height: 12),
          _field('Notes', _notesCtrl, 'Optional notes', maxLines: 2),
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

  Widget _codesField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Recovery Codes *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _onSurfaceVariant)),
      const SizedBox(height: 6),
      TextField(
        controller: _codesCtrl,
        maxLines: 8,
        decoration: InputDecoration(
          hintText: 'Paste or type codes here\nOne per line, or separated by spaces/commas',
          hintStyle: const TextStyle(color: _outlineVariant, fontSize: 13),
          filled: true, fillColor: _surfaceContainerLow,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(14),
        ),
        style: const TextStyle(fontSize: 14, color: _onSurface, fontFamily: 'monospace'),
      ),
    ]);
  }
}
