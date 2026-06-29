import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../vault_data.dart';
import '../store/vault_store.dart';

// ═══════════════════════════════════════════════════════════════
// PASSWORD ADD SCREEN — full redesign
// Premium form: colored hero, inline icon+label+input rows,
// rich primary CTA, floating feedback.
// ═══════════════════════════════════════════════════════════════

class PasswordAddScreen extends StatefulWidget {
  const PasswordAddScreen({super.key});

  @override
  State<PasswordAddScreen> createState() => _PasswordAddScreenState();
}

class _PasswordAddScreenState extends State<PasswordAddScreen> {
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
        SnackBar(
          content: const Text('Title is required'),
          backgroundColor: const Color(0xFF5B3FE8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
        icon: Icons.key,
        iconColor: const Color(0xFF5B3FE8),
        iconBgColor: const Color(0xFFEBE9FE),
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
      backgroundColor: const Color(0xFFF4F3FF),
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF12101E)),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'New Password',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF12101E),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ]),
          ),

          // Scrollable form area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(children: [
                // Hero card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBE9FE),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B3FE8).withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.enhanced_encryption,
                        size: 28,
                        color: Color(0xFF5B3FE8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Save a login securely',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5B3FE8),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // Input fields
                _FieldRow(
                  icon: Icons.label_important_outline,
                  label: 'Title',
                  required: true,
                  ctrl: _titleCtrl,
                  hint: 'e.g. Google, Binance',
                ),
                const SizedBox(height: 14),
                _FieldRow(
                  icon: Icons.alternate_email,
                  label: 'Email / Username',
                  ctrl: _emailCtrl,
                  hint: 'alex@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _PasswordRow(
                  ctrl: _passwordCtrl,
                  revealed: _revealed,
                  onToggleReveal: () => setState(() => _revealed = !_revealed),
                  onGenerate: () {
                    const chars =
                        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=';
                    final rng = DateTime.now().microsecondsSinceEpoch;
                    _passwordCtrl.text =
                        List.generate(24, (i) => chars[(rng + i * 13) % chars.length]).join();
                    setState(() => _revealed = true);
                  },
                ),
                const SizedBox(height: 14),
                _FieldRow(
                  icon: Icons.link,
                  label: 'Website URL',
                  ctrl: _urlCtrl,
                  hint: 'https://example.com',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 14),
                _FieldRow(
                  icon: Icons.sticky_note_2_outlined,
                  label: 'Notes',
                  ctrl: _notesCtrl,
                  hint: 'Optional notes',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),

          // Bottom CTA bar
          _bottomBar(),
        ]),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(color: Color(0xFFF4F3FF)),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B3FE8),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF5B3FE8).withOpacity(0.5),
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
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Save Password'),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FIELD ROW — generic input row with icon + label + input
// ═══════════════════════════════════════════════════════════════
class _FieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool required;
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _FieldRow({
    required this.icon,
    required this.label,
    required this.ctrl,
    required this.hint,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isMultiline = maxLines > 1;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3FE8).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          crossAxisAlignment:
              isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEBE8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 20, color: const Color(0xFF5B3FE8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 2),
                    child: Row(children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8E8BA8),
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (required) ...[
                        const SizedBox(width: 2),
                        const Text(
                          '*',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFBA1A1A),
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
                      color: Color(0xFF12101E),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(
                        color: Color(0xFF8E8BA8),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: isMultiline ? 8 : 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PASSWORD ROW — password input + show/hide + auto-generate
// ═══════════════════════════════════════════════════════════════
class _PasswordRow extends StatelessWidget {
  final TextEditingController ctrl;
  final bool revealed;
  final VoidCallback onToggleReveal;
  final VoidCallback onGenerate;

  const _PasswordRow({
    required this.ctrl,
    required this.revealed,
    required this.onToggleReveal,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3FE8).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEBE8FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline,
                size: 20, color: const Color(0xFF5B3FE8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8E8BA8),
                          letterSpacing: 0.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: onToggleReveal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              revealed
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 14,
                              color: const Color(0xFF5B3FE8),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              revealed ? 'Hide' : 'Show',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF5B3FE8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: ctrl,
                  obscureText: !revealed,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF12101E),
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter password',
                    hintStyle: TextStyle(
                      color: Color(0xFF8E8BA8),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onGenerate,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF5B3FE8).withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 18,
                color: Color(0xFF5B3FE8),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
