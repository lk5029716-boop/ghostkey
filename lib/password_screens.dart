import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'vault_data.dart';

// ═══════════════════════════════════════════════════════════════
// SHARED DESIGN TOKENS (aligned with vault_home_screen / vault_screens)
// ═══════════════════════════════════════════════════════════════
const Color _kSurfaceDim = Color(0xFFF4F3FF); // screen background
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kCardLavender = Color(0xFFFAF9FF); // very light lavender card
const Color _kPrimary = Color(0xFF5B3FE8); // indigo
const Color _kOnPrimary = Color(0xFFFFFFFF);
const Color _kOnSurface = Color(0xFF12101E); // bold black text
const Color _kOnSurfaceVariant = Color(0xFF8E8BA8); // muted gray
const Color _kOutlineVariant = Color(0xFFE4E2F5);
const Color _kError = Color(0xFFBA1A1A); // delete red

// "2FA Codes" tile blue — light blue circular chip + blue icon.
const Color _kChipBlueBg = Color(0xFFBBDEFB);
const Color _kChipBlueFg = Color(0xFF4285F4);

// Field accents
const Color _kFieldPassword = Color(0xFF5B3FE8);
const Color _kFieldUrl = Color(0xFF1565C0);
const Color _kFieldNotes = Color(0xFFE65100);

TextStyle _font(double size, FontWeight w, Color c, {double? height, double? ls}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height, letterSpacing: ls ?? 0);

void _copy(BuildContext context, String label, String value) {
  Clipboard.setData(ClipboardData(text: value));
  HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Copied $label'),
      duration: const Duration(seconds: 1),
      backgroundColor: _kPrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

// A consistent header: back arrow + bold title (matches vault_screens).
class _ScreenHeader extends StatelessWidget {
  final String title;
  const _ScreenHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: _kOnSurface),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              title,
              style: _font(18, FontWeight.w700, _kOnSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
      backgroundColor: _kSurfaceDim,
      body: SafeArea(
        child: Column(
          children: [
            const _ScreenHeader(title: 'Passwords'),
            // Search pill
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: _kOutlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: _font(15, FontWeight.w500, _kOnSurface),
                  cursorColor: _kPrimary,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    hintText: 'Search passwords',
                    hintStyle: _font(15, FontWeight.w400, _kOnSurfaceVariant),
                    prefixIcon: const Icon(Icons.search, color: _kOnSurfaceVariant, size: 22),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, color: _kOnSurfaceVariant, size: 20),
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
            // List or empty state
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
          color: _kPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withOpacity(0.35),
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
            child: const Icon(Icons.add, color: _kOnPrimary, size: 30),
          ),
        ),
      ),
    );
  }
}

// A single password entry card in the list.
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
            color: _kCardLavender,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Light blue circular icon chip with lock
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: _kChipBlueBg, shape: BoxShape.circle),
                child: const Icon(Icons.lock_outline, size: 22, color: _kChipBlueFg),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: _font(16, FontWeight.w700, _kOnSurface, height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (username.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        username,
                        style: _font(13, FontWeight.w400, _kOnSurfaceVariant, height: 1.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Copy affordance on the right edge
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: _kOnSurfaceVariant),
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
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: _kChipBlueBg, shape: BoxShape.circle),
              child: Icon(
                searching ? Icons.search_off : Icons.lock_outline,
                size: 34,
                color: _kChipBlueFg,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              searching ? 'No matching passwords' : 'No passwords saved yet',
              style: _font(16, FontWeight.w600, _kOnSurface),
              textAlign: TextAlign.center,
            ),
            if (!searching) ...[
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add your first password',
                style: _font(14, FontWeight.w400, _kOnSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SCREEN 2 — ITEM DETAIL
// ═══════════════════════════════════════════════════════════════
class PasswordItemDetailScreen extends StatelessWidget {
  final VaultItem item;
  const PasswordItemDetailScreen({super.key, required this.item});

  // Only these labels are treated as secrets (masked + eye toggle).
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

  Color _accentFor(String label) {
    final l = label.toLowerCase();
    if (_isSecret(l)) return _kFieldPassword;
    if (l.contains('url') || l.contains('website') || l.contains('link') || l.contains('domain')) {
      return _kFieldUrl;
    }
    if (l.contains('note') || l.contains('memo')) return _kFieldNotes;
    return _kChipBlueFg;
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
      backgroundColor: _kSurfaceDim,
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
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: _kChipBlueBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_outline, size: 34, color: _kChipBlueFg),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            item.title,
                            style: _font(22, FontWeight.w800, _kOnSurface, ls: -0.3),
                            textAlign: TextAlign.center,
                          ),
                          if (subtitle.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: _font(14, FontWeight.w500, _kOnSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Saved fields section
                    Text(
                      'Saved fields',
                      style: _font(13, FontWeight.w700, _kOnSurfaceVariant, ls: 0.4),
                    ),
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
                              label: Text('Edit', style: _font(15, FontWeight.w600, _kOnPrimary)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimary,
                                foregroundColor: _kOnPrimary,
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
                              label: Text('Delete', style: _font(15, FontWeight.w600, _kError)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _kError,
                                side: const BorderSide(color: _kError, width: 1.5),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete ${item.title}?', style: _font(18, FontWeight.w700, _kOnSurface)),
        content: Text(
          'This item will be permanently removed from your vault.',
          style: _font(14, FontWeight.w400, _kOnSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: _font(14, FontWeight.w600, _kOnSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // close dialog
              Navigator.of(context).maybePop(); // leave detail screen
            },
            child: Text('Delete', style: _font(14, FontWeight.w700, _kError)),
          ),
        ],
      ),
    );
  }
}

// A single "Saved fields" card. Secrets are masked with an eye toggle;
// non-secret fields (URL, Notes) show a copy icon only — no reveal.
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
    // Non-secret fields always show a copy icon.
    // Secret fields show a copy icon only once revealed.
    final showCopy = !widget.isSecret || _revealed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kOutlineVariant),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Small colored leading icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, size: 20, color: widget.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: _font(11, FontWeight.w600, _kOnSurfaceVariant, ls: 0.4),
                ),
                const SizedBox(height: 4),
                Text(
                  masked ? '••••••••••••' : widget.value,
                  style: _font(15, FontWeight.w600, _kOnSurface, height: 1.3),
                  maxLines: widget.isSecret ? 1 : 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Eye toggle only for secret fields
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
              icon: const Icon(Icons.copy, size: 18, color: _kOnSurfaceVariant),
              tooltip: 'Copy ${widget.label}',
              onPressed: () => _copy(context, widget.label, widget.value),
            ),
        ],
      ),
    );
  }
}
