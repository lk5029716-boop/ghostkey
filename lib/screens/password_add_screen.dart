import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../vault_data.dart';
import '../store/vault_store.dart';

// ═══════════════════════════════════════════════════════════════
// PASSWORD ADD SCREEN
// Redesigned to match the app's color core: light purple surface,
// white rounded inputs, larger field icons, full-width primary CTA.
// ═══════════════════════════════════════════════════════════════

class PasswordAddScreen extends StatefulWidget {
  const PasswordAddScreen({super.key});

  @override
  State<PasswordAddScreen> createState() => _PasswordAddScreenState();
}

class _PasswordAddScreenState extends State<PasswordAddScreen> {
  // App color core
  static const _primary = Color(0xFF5B3FE8);
  static const _surfaceDim = Color(0xFFF4F3FF);
  static const _surface = Color(0xFFFFFFFF);
  static const _onSurface = Color(0xFF12101E);
  static const _onSurfaceVariant = Color(0xFF8E8BA8);
  static const _outlineVariant = Color(0xFFE4E2F5);
  static const _fieldBg = Color(0xFFF6F5FF);
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
      backgroundColor: _surfaceDim,
      appBar: AppBar(
        backgroundColor: _surfaceDim,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'New Password',
          style: TextStyle(
            color: _onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(
                    icon: Icons.label_outline,
                    label: 'Title',
                    required: true,
                    ctrl: _titleCtrl,
                    hint: 'e.g. Google, Binance',
                  ),
                  const SizedBox(height: 14),
                  _field(
                    icon: Icons.alternate_email,
                    label: 'Email / Username',
                    ctrl: _emailCtrl,
                    hint: 'alex@gmail.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _passwordField(),
                  const SizedBox(height: 14),
                  _field(
                    icon: Icons.link,
                    label: 'Website URL',
                    ctrl: _urlCtrl,
                    hint: 'https://example.com',
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    icon: Icons.notes,
                    label: 'Notes',
                    ctrl: _notesCtrl,
                    hint: 'Optional notes',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          _bottomBar(),
        ]),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(color: _surfaceDim),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primary.withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save Password'),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required IconData icon,
    required String label,
    required TextEditingController ctrl,
    required String hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _onSurface,
                letterSpacing: 0.1,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 2),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _error,
                ),
              ),
            ],
          ]),
        ),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 15,
            color: _onSurface,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: _onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: maxLines == 1
                ? Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: Icon(icon, color: _primary, size: 20),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: _surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: maxLines == 1 ? 0 : 16,
              vertical: maxLines == 1 ? 16 : 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _outlineVariant, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _onSurface,
                  letterSpacing: 0.1,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _revealed = !_revealed),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 16,
                    color: _primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _revealed ? 'Hide' : 'Show',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
        TextField(
          controller: _passwordCtrl,
          obscureText: !_revealed,
          style: const TextStyle(
            fontSize: 15,
            color: _onSurface,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Enter password',
            hintStyle: const TextStyle(
              color: _onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 8),
              child: Icon(Icons.lock_outline, color: _primary, size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: IconButton(
              icon: const Icon(Icons.auto_awesome, size: 18, color: _primary),
              tooltip: 'Generate strong password',
              onPressed: () {
                const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=';
                final rng = DateTime.now().microsecondsSinceEpoch;
                _passwordCtrl.text =
                    List.generate(24, (i) => chars[(rng + i * 13) % chars.length]).join();
                setState(() => _revealed = true);
              },
            ),
            filled: true,
            fillColor: _surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _outlineVariant, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}