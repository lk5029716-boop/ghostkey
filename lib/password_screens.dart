import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'vault_data.dart';
import 'main.dart';

// ─────────────────────────────────────────────────────────────────────────
// PASSWORD LIST + ITEM DETAIL
// Built with the SAME Pastel Vault building blocks as the Settings tab
// (kSurface, kPrimary, _card / _iconBadge / _sectionHeader / _divider),
// so the whole app reads as one design system.
// ─────────────────────────────────────────────────────────────────────────

TextStyle _pj(double size, FontWeight w, Color c, {double? height, double? ls}) =>
    GoogleFonts.plusJakartaSans(
        fontSize: size, fontWeight: w, color: c, height: height, letterSpacing: ls ?? 0);

void _copy(BuildContext context, String label, String value) {
  Clipboard.setData(ClipboardData(text: value));
  HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Copied $label', style: _pj(14, FontWeight.w600, Colors.white)),
      duration: const Duration(seconds: 1),
      backgroundColor: kPrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

// Tinted rounded icon chip — same shape/feel as the Settings tab.
Widget _iconBadge(IconData icon, {required Color fg, required Color bg, double size = 48}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.33)),
    child: Icon(icon, size: size * 0.46, color: fg),
  );
}

// Uppercase section header — same as the Settings tab.
Widget _sectionHeader(String title, Color color) {
  return Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(title.toUpperCase(),
        style: _pj(12, FontWeight.w600, color, ls: 1.5)),
  );
}

// Back arrow + bold centered title — matches the Settings header bar.
class _ScreenHeader extends StatelessWidget {
  final String title;
  const _ScreenHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: kOnSurface),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              title,
              style: _pj(20, FontWeight.w700, kOnSurface, ls: -0.01),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 48), // balance the back button
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SCREEN 1 — PASSWORD LIST
// ═══════════════════════════════════════════════════════════════
class PasswordListScreen extends StatefulWidget {
  final List<VaultItem>? items;
  const PasswordListScreen({super.key, this.items});

  @override
  State<PasswordListScreen> createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  List<VaultItem> get _source =>
      widget.items ??
      kVaultItems.where((i) => i.category == VaultCategory.password).toList();

  List<VaultItem> get _filtered {
    if (_query.trim().isEmpty) return _source;
    final q = _query.toLowerCase();
    return _source.where((i) {
      final user = (i.fields['Email'] ?? i.fields['Username'] ?? i.subtitle).toLowerCase();
      return i.title.toLowerCase().contains(q) || user.contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: Column(
          children: [
            const _ScreenHeader(title: 'Passwords'),
            // Search pill (rounded, soft shadow, no border)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: _pj(15, FontWeight.w500, kOnSurface),
                  cursorColor: kPrimary,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    hintText: 'Search passwords',
                    hintStyle: _pj(15, FontWeight.w400, kOnSurfaceVariant),
                    prefixIcon: const Icon(Icons.search, color: kOnSurfaceVariant, size: 22),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, color: kOnSurfaceVariant, size: 20),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? _EmptyState(searching: _query.trim().isNotEmpty)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) => _PasswordCard(
                        item: items[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PasswordItemDetailScreen(item: items[i]),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: kPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {}, // TODO: wire to add-password flow
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}

// A single password entry card — SAME language as the Settings rows:
// white, 28px radius, soft indigo shadow, 48px tinted chip, copy on the right.
class _PasswordCard extends StatefulWidget {
  final VaultItem item;
  final VoidCallback onTap;
  const _PasswordCard({required this.item, required this.onTap});

  @override
  State<_PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<_PasswordCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final username = item.fields['Email'] ?? item.fields['Username'] ?? item.subtitle;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Tinted circular chip with lock (matches Settings icon badges)
              _iconBadge(Icons.lock_outline, fg: kPrimary, bg: kPrimary.withOpacity(0.12)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: _pj(16, FontWeight.w600, kOnSurface, height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (username.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        username,
                        style: _pj(13, FontWeight.w400, kOnSurfaceVariant, height: 1.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: kOnSurfaceVariant),
                tooltip: 'Copy password',
                onPressed: () {
                  final pwd = item.fields['Password'] ?? '';
                  _copy(context, 'password', pwd);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool searching;
  const _EmptyState({required this.searching});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _iconBadge(
              searching ? Icons.search_off : Icons.lock_outline,
              fg: kPrimary,
              bg: kPrimary.withOpacity(0.12),
              size: 72,
            ),
            const SizedBox(height: 18),
            Text(
              searching ? 'No matching passwords' : 'No passwords saved yet',
              style: _pj(16, FontWeight.w600, kOnSurface),
              textAlign: TextAlign.center,
            ),
            if (!searching) ...[
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add your first password',
                style: _pj(14, FontWeight.w400, kOnSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

  Color _accentFor(String label) {
    final l = label.toLowerCase();
    if (_isSecret(l)) return kPrimary;
    if (l.contains('url') || l.contains('website') || l.contains('link') || l.contains('domain')) {
      return const Color(0xFF1565C0);
    }
    if (l.contains('note') || l.contains('memo')) return const Color(0xFFE65100);
    return kPrimary;
  }

// ═══════════════════════════════════════════════════════════════
// SCREEN 2 — ITEM DETAIL
// ═══════════════════════════════════════════════════════════════
class PasswordItemDetailScreen extends StatelessWidget {
  final VaultItem item;
  const PasswordItemDetailScreen({super.key, required this.item});

  bool _isSecret(String label) {
    final l = label.toLowerCase();
    return l.contains('password') || l.contains('secret') || l.contains('pin');
  }

  IconData _iconFor(String label) {
    final l = label.toLowerCase();
    if (_isSecret(l)) return Icons.lock_outline;
    if (l.contains('url') || l.contains('website') || l.contains('link') || l.contains('domain')) {
      return Icons.link;
    }
    if (l.contains('note') || l.contains('memo')) return Icons.notes;
    if (l.contains('email') || l.contains('user') || l.contains('login')) {
      return Icons.alternate_email;
    }
    return Icons.label_important_outline;
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = item.subtitle.isNotEmpty
        ? item.subtitle
        : (item.fields['Email'] ?? item.fields['Username'] ?? '');
    final fields = item.fields.entries
        .where((e) => e.value.trim().isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: Column(
          children: [
            _ScreenHeader(title: item.title),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Centered icon chip + title + subtitle
                    Center(
                      child: Column(
                        children: [
                          _iconBadge(Icons.lock_outline, fg: kPrimary, bg: kPrimary.withOpacity(0.12), size: 72),
                          const SizedBox(height: 14),
                          Text(
                            item.title,
                            style: _pj(22, FontWeight.w700, kOnSurface, ls: -0.3),
                            textAlign: TextAlign.center,
                          ),
                          if (subtitle.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: _pj(14, FontWeight.w500, kOnSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Section header — uppercase, same as Settings
                    _sectionHeader('Saved fields', kPrimary),
                    const SizedBox(height: 12),
                    for (final entry in fields) ...[
                      _FieldCard(
                        icon: _iconFor(entry.key),
                        accent: _accentFor(entry.key),
                        label: entry.key,
                        value: entry.value,
                        isSecret: _isSecret(entry.key),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                    // Bottom actions: Edit (solid indigo) + Delete (outlined red)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () {}, // TODO: wire to edit flow
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              label: Text('Edit', style: _pj(15, FontWeight.w600, Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDelete(context),
                              icon: const Icon(Icons.delete_outline, size: 20),
                              label: Text('Delete', style: _pj(15, FontWeight.w600, kError)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kError,
                                side: const BorderSide(color: kError, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete ${item.title}?', style: _pj(18, FontWeight.w700, kOnSurface)),
        content: Text(
          'This item will be permanently removed from your vault.',
          style: _pj(14, FontWeight.w400, kOnSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: _pj(14, FontWeight.w600, kOnSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).maybePop();
            },
            child: Text('Delete', style: _pj(14, FontWeight.w700, kError)),
          ),
        ],
      ),
    );
  }
}

// A single "Saved fields" card — SAME language as Settings rows:
// white, 28px radius, soft shadow, 48px tinted icon chip, no visible border.
class _FieldCard extends StatefulWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final bool isSecret;

  const _FieldCard({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    required this.isSecret,
  });

  @override
  State<_FieldCard> createState() => _FieldCardState();
}

class _FieldCardState extends State<_FieldCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final masked = widget.isSecret && !_revealed;
    final showCopy = !widget.isSecret || _revealed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _iconBadge(widget.icon, fg: widget.accent, bg: widget.accent.withOpacity(0.12)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: _pj(11, FontWeight.w600, kOnSurfaceVariant, ls: 0.4),
                ),
                const SizedBox(height: 4),
                Text(
                  masked ? '••••••••••••' : widget.value,
                  style: _pj(15, FontWeight.w600, kOnSurface, height: 1.3),
                  maxLines: widget.isSecret ? 1 : 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (widget.isSecret)
            IconButton(
              icon: Icon(
                _revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: widget.accent,
              ),
              tooltip: _revealed ? 'Hide' : 'Reveal',
              onPressed: () => setState(() => _revealed = !_revealed),
            ),
          if (showCopy)
            IconButton(
              icon: const Icon(Icons.copy, size: 18, color: kOnSurfaceVariant),
              tooltip: 'Copy ${widget.label}',
              onPressed: () => _copy(context, widget.label, widget.value),
            ),
        ],
      ),
    );
  }
}
