import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// HOME TAB — "Your Vault"
// Faithful visual reproduction of the GhostKey vault home design:
// translucent top app bar, import strip, 2-column vault grid of six
// action cards, and a floating add button. Cards are purely visual
// placeholders (no service wiring) per the requested scope.
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

TextStyle _font(double size, FontWeight w, Color c, {double? height, double? ls}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height, letterSpacing: ls ?? 0);

class VaultHomeScreen extends StatelessWidget {
  const VaultHomeScreen({super.key});

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
                children: const [
                  _TopBar(),
                  SizedBox(height: 8),
                  _ImportStrip(),
                  SizedBox(height: 16),
                  _VaultGrid(),
                ],
              ),
            ),
            const Positioned(right: 24, bottom: 28, child: _Fab()),
          ],
        ),
      ),
    );
  }
}

// ── Top App Bar ──────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();
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
          // GK profile icon removed — replaced with user name above
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
  const _PillButton({required this.label, required this.onTap});
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

// ── Vault Grid ───────────────────────────────────────────────────
class _VaultGrid extends StatelessWidget {
  const _VaultGrid();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        const gap = 16.0;
        final cellW = (c.maxWidth - gap) / 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _VaultCard.square(cellW, _cSurface, _cPrimary, Icons.login, 'Create a login', _cOnSurface),
                const SizedBox(width: gap),
                _VaultCard.square(cellW, _cSurface, _cPrimary, Icons.alternate_email, 'Hide-my-email alias', _cOnSurface),
              ],
            ),
            const SizedBox(height: gap),
            Row(
              children: [
                _VaultCard.square(cellW, _cSurface, _cPrimary, Icons.note, 'Create a note', _cOnSurface),
                const SizedBox(width: gap),
                _VaultCard.square(cellW, _cSurface, _cPrimary, Icons.credit_card, 'Credit card', _cOnSurface),
              ],
            ),
            const SizedBox(height: gap),
            Row(
              children: [
                _VaultCard.square(cellW, _cSurface, _cPrimary, Icons.badge, 'Create an identity', _cOnSurface),
                const SizedBox(width: gap),
                _VaultCard.square(cellW, _cSurface, _cPrimary, Icons.dashboard_customize, 'Create a custom item', _cOnSurface),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ── Vault Card (press scale, no service wiring) ──────────────────
class _VaultCard extends StatefulWidget {
  final double width;
  final double height;
  final Color bg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final Color titleColor;

  const _VaultCard({
    required this.width,
    required this.height,
    required this.bg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.titleColor,
  });

  const _VaultCard.square(double size, this.bg, this.iconColor, this.icon, this.title, this.titleColor)
      : width = size,
        height = size;

  @override
  State<_VaultCard> createState() => _VaultCardState();
}

class _VaultCardState extends State<_VaultCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {}, // visual only — no service wiring
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: widget.bg,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: _cPrimary.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 24),
              ),
              Text(widget.title, style: _font(18, FontWeight.w700, widget.titleColor, height: 24 / 18)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Floating Add Button ──────────────────────────────────────────
class _Fab extends StatelessWidget {
  const _Fab();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // visual only
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
        child: Icon(Icons.add, color: _cOnPrimary, size: 32),
      ),
    );
  }
}
