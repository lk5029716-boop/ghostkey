import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:dotted_border/dotted_border.dart';

import '../../screens/password_add_screen.dart';
import '../../screens/secure_note_add_screen.dart';
import '../../screens/api_key_add_screen.dart';
import '../../screens/recovery_codes_add_screen.dart';
import '../../qr_scanner_screen.dart';
import '../../seed_phrase_restore_screen.dart';
import '../../home_tile_data.dart';

// ═══════════════════════════════════════════════════════════════
// HOME TAB — "Your Vault"
// Customizable dashboard: users add, remove, and reorder shortcut
// tiles. Long-press any tile to enter organize mode (wobble +
// remove badges + drag-to-reorder). Tap "+" to add a shortcut from
// a bottom sheet. Layout persists locally via SharedPreferences.
// Every tile routes to a real, already-implemented add screen —
// no placeholder/demo destinations.
// ═══════════════════════════════════════════════════════════════

// M3 design tokens — exact values from the "Your Vault" design spec.
const Color _cSurfaceDim = Color(0xFFF4F3FF);
const Color _cSurface = Color(0xFFFFFFFF);
const Color _cPrimary = Color(0xFF5B3FE8);
const Color _cOnPrimary = Color(0xFFFFFFFF);
const Color _cPrimaryContainer = Color(0xFFEBE8FF);
const Color _cOnSurface = Color(0xFF12101E);
const Color _cOnSurfaceVariant = Color(0xFF8E8BA8);
const Color _cSurfaceContainerHigh = Color(0xFFEBE6F4);
const Color _cOutlineVariant = Color(0xFFE4E2F5);
const Color _cDanger = Color(0xFFE0435B);

TextStyle _font(double size, FontWeight w, Color c, {double? height, double? ls}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height, letterSpacing: ls ?? 0);

// Top-level function tear-offs for navigation destinations.
Widget _buildPasswordAdd(BuildContext ctx) => const PasswordAddScreen();
Widget _buildNoteAdd(BuildContext ctx) => const SecureNoteAddScreen();
Widget _buildApiKeyAdd(BuildContext ctx) => const ApiKeyAddScreen();
Widget _buildRecoveryAdd(BuildContext ctx) => const RecoveryCodesAddScreen();
Widget _buildTotpAdd(BuildContext ctx) => const QrScannerScreen();
Widget _buildSeedAdd(BuildContext ctx) => const SeedPhraseRestoreScreen();

const Map<HomeTileType, WidgetBuilder> _kTileDestinations = {
  HomeTileType.login: _buildPasswordAdd,
  HomeTileType.note: _buildNoteAdd,
  HomeTileType.apiKey: _buildApiKeyAdd,
  HomeTileType.recoveryCodes: _buildRecoveryAdd,
  HomeTileType.totp: _buildTotpAdd,
  HomeTileType.seed: _buildSeedAdd,
};

// ── Screen ────────────────────────────────────────────────────────

class VaultHomeScreen extends StatefulWidget {
  /// Notifier so VaultPage can reload tiles when Home adds/removes one.
  static final tilesChangedNotifier = ValueNotifier<int>(0);

  const VaultHomeScreen({super.key});

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  static const _kPrefsKey = 'gk_home_tiles_v1';
  static const _uuid = Uuid();

  List<HomeTile> _tiles = [];
  final Set<String> _removingIds = {};
  bool _organizeMode = false;
  bool _loaded = false;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<HomeTile> _defaultTiles() => [
        HomeTile(id: _uuid.v4(), type: HomeTileType.login),
        HomeTile(id: _uuid.v4(), type: HomeTileType.note),
        HomeTile(id: _uuid.v4(), type: HomeTileType.totp),
        HomeTile(id: _uuid.v4(), type: HomeTileType.recoveryCodes),
      ];

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final raw = prefs.getString(_kPrefsKey);
    List<HomeTile> loaded;
    if (raw != null) {
      try {
        final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        loaded = decoded.map(HomeTile.fromJson).toList();
      } catch (_) {
        loaded = _defaultTiles();
      }
    } else {
      loaded = _defaultTiles();
    }
    if (!mounted) return;
    setState(() {
      _tiles = loaded;
      _loaded = true;
    });
    if (raw == null) _persist();
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_kPrefsKey, jsonEncode(_tiles.map((t) => t.toJson()).toList()));
  }

  void _addTile(HomeTileType type) {
    setState(() => _tiles.add(HomeTile(id: _uuid.v4(), type: type)));
    _persist();
  }

  Future<void> _removeTile(String id) async {
    setState(() => _removingIds.add(id));
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() {
      _tiles.removeWhere((t) => t.id == id);
      _removingIds.remove(id);
      if (_tiles.isEmpty) _organizeMode = false;
    });
    _persist();
    _notifyVault();
  }

  void _reorder(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    setState(() {
      final tile = _tiles.removeAt(fromIndex);
      _tiles.insert(toIndex, tile);
    });
    _persist();
  }

  void _openTile(HomeTile tile) {
    // Home tab: tapping a tile opens the add interface directly.
    // After saving, the item goes into Vault automatically.
    final builder = _kTileDestinations[tile.type]!;
    Navigator.of(context).push(MaterialPageRoute(builder: builder));
  }

  Future<void> _openAddSheet() async {
    final used = _tiles.map((t) => t.type).toSet();
    final available = HomeTileType.values.where((t) => !used.contains(t)).toList();
    final selected = await showModalBottomSheet<HomeTileType>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AddShortcutSheet(available: available),
    );
    if (selected != null) {
      _addTile(selected);
      // Notify Vault tab to reload its boxes
      _notifyVault();
    }
  }

  void _notifyVault() {
    // Fire an event so VaultPage knows the tiles changed
    VaultHomeScreen.tilesChangedNotifier.notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cSurfaceDim,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(
                    organizeMode: _organizeMode,
                    onDone: () => setState(() => _organizeMode = false),
                  ),
                  const SizedBox(height: 8),
                  const _ImportStrip(),
                  const SizedBox(height: 16),
                  if (!_loaded)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator(color: _cPrimary)),
                    )
                  else
                    _buildGrid(context),
                ],
              ),
            ),
            if (!_organizeMode)
              Positioned(right: 24, bottom: 28, child: _Fab(onTap: _openAddSheet)),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      const gap = 16.0;
      final cellW = (constraints.maxWidth - gap) / 2;
      final cellH = cellW;
      final totalSlots = _tiles.length + (_organizeMode ? 0 : 1);
      final rows = totalSlots == 0 ? 0 : ((totalSlots - 1) ~/ 2) + 1;
      final height = rows == 0 ? 0.0 : rows * cellH + (rows - 1) * gap;

      final children = <Widget>[];

      for (int i = 0; i < _tiles.length; i++) {
        final tile = _tiles[i];
        final col = i % 2;
        final row = i ~/ 2;
        children.add(
          AnimatedPositioned(
            key: ValueKey('pos_${tile.id}'),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            left: col * (cellW + gap),
            top: row * (cellH + gap),
            width: cellW,
            height: cellH,
            child: _HomeTileWidget(
              key: ValueKey(tile.id),
              tile: tile,
              width: cellW,
              height: cellH,
              organizeMode: _organizeMode,
              removing: _removingIds.contains(tile.id),
              index: i,
              onTap: () => _openTile(tile),
              onLongPress: () => setState(() => _organizeMode = true),
              onRemove: () => _removeTile(tile.id),
              onReorderRequested: (from) => _reorder(from, i),
            ),
          ),
        );
      }

      if (!_organizeMode) {
        final i = _tiles.length;
        final col = i % 2;
        final row = i ~/ 2;
        children.add(
          AnimatedPositioned(
            key: const ValueKey('add_tile'),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            left: col * (cellW + gap),
            top: row * (cellH + gap),
            width: cellW,
            height: cellH,
            child: _AddTileWidget(onTap: _openAddSheet),
          ),
        );
      }

      return SizedBox(
        height: height,
        child: Stack(clipBehavior: Clip.none, children: children),
      );
    });
  }
}

// ── Top App Bar ──────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool organizeMode;
  final VoidCallback onDone;
  const _TopBar({required this.organizeMode, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(color: Color(0xCCF4F3FF)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Good morning',
                  style: _font(12, FontWeight.w500, _cOnSurfaceVariant, ls: 0.05)),
              const SizedBox(height: 2),
              Text('Maruf', style: _font(24, FontWeight.w700, _cPrimary)),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: organizeMode
                ? _PillButton(key: const ValueKey('done'), label: 'Done', onTap: onDone)
                : const SizedBox(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }
}

// ── Import Strip ─────────────────────────────────────────────────
class _ImportStrip extends StatelessWidget {
  const _ImportStrip();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cPrimaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text('Already use a password manager?',
                style: _font(16, FontWeight.w400, _cPrimary, height: 1.4)),
          ),
          const SizedBox(width: 12),
          _PillButton(label: 'Import', onTap: () {}),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PillButton({super.key, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cPrimary,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(label, style: _font(14, FontWeight.w500, _cOnPrimary, ls: 0.05)),
        ),
      ),
    );
  }
}

// ── Home Tile (tap-to-open / long-press-to-organize / drag-to-reorder) ──
class _HomeTileWidget extends StatefulWidget {
  final HomeTile tile;
  final double width;
  final double height;
  final bool organizeMode;
  final bool removing;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRemove;
  final void Function(int fromIndex) onReorderRequested;

  const _HomeTileWidget({
    super.key,
    required this.tile,
    required this.width,
    required this.height,
    required this.organizeMode,
    required this.removing,
    required this.index,
    required this.onTap,
    required this.onLongPress,
    required this.onRemove,
    required this.onReorderRequested,
  });

  @override
  State<_HomeTileWidget> createState() => _HomeTileWidgetState();
}

class _HomeTileWidgetState extends State<_HomeTileWidget> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool _entered = false;
  late final AnimationController _wobbleCtrl;
  late final double _wobbleSign;

  @override
  void initState() {
    super.initState();
    _wobbleSign = widget.index.isEven ? 1.0 : -1.0;
    _wobbleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  void dispose() {
    _wobbleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = kTileInfo[widget.tile.type]!;

    final cardContent = AnimatedScale(
      scale: widget.removing ? 0.0 : (_pressed ? 0.96 : (_entered ? 1.0 : 0.0)),
      duration: Duration(milliseconds: widget.removing ? 180 : 220),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: widget.removing ? 0.0 : (_entered ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 200),
        child: AnimatedBuilder(
          animation: _wobbleCtrl,
          builder: (ctx, child) {
            final angle =
                widget.organizeMode ? (_wobbleSign * 0.018 * (_wobbleCtrl.value * 2 - 1)) : 0.0;
            return Transform.rotate(angle: angle, child: child);
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: info.bg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: info.bg, shape: BoxShape.circle),
                  child: Icon(info.icon, color: info.color, size: 24),
                ),
                Text(info.label, style: _font(18, FontWeight.w700, info.color, height: 24 / 18)),
              ],
            ),
          ),
        ),
      ),
    );

    if (!widget.organizeMode) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: cardContent,
      );
    }

    final withBadge = Stack(
      clipBehavior: Clip.none,
      children: [
        cardContent,
        Positioned(
          right: -6,
          top: -6,
          child: _RemoveBadge(onTap: widget.onRemove),
        ),
      ],
    );

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != widget.index,
      onAcceptWithDetails: (details) => widget.onReorderRequested(details.data),
      builder: (ctx, candidate, rejected) => LongPressDraggable<int>(
        data: widget.index,
        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.06,
            child: SizedBox(width: widget.width, height: widget.height, child: cardContent),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.25, child: withBadge),
        child: withBadge,
      ),
    );
  }
}

class _RemoveBadge extends StatelessWidget {
  final VoidCallback onTap;
  const _RemoveBadge({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.close, size: 16, color: _cDanger),
      ),
    );
  }
}

// ── "Add shortcut" dashed tile ───────────────────────────────────
class _AddTileWidget extends StatefulWidget {
  final VoidCallback onTap;
  const _AddTileWidget({super.key, required this.onTap});

  @override
  State<_AddTileWidget> createState() => _AddTileWidgetState();
}

class _AddTileWidgetState extends State<_AddTileWidget> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: DottedBorder(
          color: _cOnSurfaceVariant.withOpacity(0.5),
          strokeWidth: 1.5,
          dashPattern: const [6, 5],
          borderType: BorderType.RRect,
          radius: const Radius.circular(28),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: _cSurfaceContainerHigh.withOpacity(0.4),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: _cPrimary.withOpacity(0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: _cPrimary, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text('Add shortcut', style: _font(13, FontWeight.w600, _cOnSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Floating Add Button ──────────────────────────────────────────
class _Fab extends StatelessWidget {
  final VoidCallback onTap;
  const _Fab({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _cPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: _cOnPrimary, size: 32),
      ),
    );
  }
}

// ── "Add shortcut" bottom sheet ──────────────────────────────────
class _AddShortcutSheet extends StatelessWidget {
  final List<HomeTileType> available;
  const _AddShortcutSheet({required this.available});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(color: _cSurface, borderRadius: BorderRadius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: _cOutlineVariant, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Text('Add shortcut', style: _font(20, FontWeight.w700, _cOnSurface)),
            const SizedBox(height: 4),
            Text('Choose what to add to your Home tab',
                style: _font(13, FontWeight.w400, _cOnSurfaceVariant)),
            const SizedBox(height: 16),
            if (available.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'All shortcuts are already on your Home tab.',
                  style: _font(14, FontWeight.w500, _cOnSurfaceVariant),
                ),
              )
            else
              ...available.map((t) {
                final info = kTileInfo[t]!;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).pop(t),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: info.bg, borderRadius: BorderRadius.circular(12)),
                          child: Icon(info.icon, color: info.color, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Text(info.label, style: _font(15.5, FontWeight.w600, _cOnSurface)),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
