// ═══════════════════════════════════════════════════════════════
// PIN UNLOCK SCREEN — Modern biometric + PIN entry
// Matches HTML reference: Unlock GhostKey
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinUnlockScreen extends StatefulWidget {
  final VoidCallback? onUnlock;
  const PinUnlockScreen({super.key, this.onUnlock});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen>
    with TickerProviderStateMixin {
  static const _maxPinLength = 6;
  String _pin = '';

  late final AnimationController _scanController;
  late final AnimationController _ringController;
  late final Animation<double> _scanAnim;
  late final Animation<double> _ringScale;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _ringController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _ringScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  void _onDigit(String d) {
    if (_pin.length >= _maxPinLength) return;
    HapticFeedback.lightImpact();
    setState(() => _pin += d);
    if (_pin.length == _maxPinLength) {
      // Verify
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) widget.onUnlock?.call();
      });
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _onBiometric() {
    HapticFeedback.lightImpact();
    // Simulate biometric
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) widget.onUnlock?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0D631B);
    const onSurface = Color(0xFF191C1D);
    const onSurfaceVariant = Color(0xFF40493D);
    const surface = Color(0xFFF8F9FA);
    const surfaceContainerLow = Color(0xFFF3F4F5);
    const surfaceVariant = Color(0xFFE1E3E4);
    const outline = Color(0xFF707A6C);

    return Scaffold(
      backgroundColor: surface,
      body: Stack(
        children: [
          // Subtle background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [surface, surfaceContainerLow],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Status bar simulation
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('9:30',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: onSurfaceVariant)),
                        Row(children: const [
                          Icon(Icons.signal_cellular_4_bar,
                              size: 16, color: onSurfaceVariant),
                          SizedBox(width: 4),
                          Icon(Icons.wifi, size: 16, color: onSurfaceVariant),
                          SizedBox(width: 4),
                          Icon(Icons.battery_full,
                              size: 16, color: onSurfaceVariant),
                        ]),
                      ],
                    ),
                  ),
                  // Headline
                  Column(
                    children: const [
                      Text('Unlock GhostKey',
                          style: TextStyle(
                              fontSize: 28,
                              height: 36 / 28,
                              fontWeight: FontWeight.w600,
                              color: onSurface)),
                      SizedBox(height: 4),
                      Text('Use your biometric or PIN to continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              color: onSurfaceVariant)),
                    ],
                  ),
                  const Spacer(),
                  // Biometric + PIN dots
                  Column(
                    children: [
                      // Animated biometric button
                      _buildBiometricButton(primary, onSurfaceVariant, surfaceContainerLow),
                      const SizedBox(height: 32),
                      const Text('OR ENTER PIN',
                          style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w500,
                              color: onSurfaceVariant)),
                      const SizedBox(height: 24),
                      // PIN dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_maxPinLength, (i) {
                          final filled = i < _pin.length;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: filled ? primary : Colors.transparent,
                              border: Border.all(
                                color: filled ? primary : outline,
                                width: 1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            transform: filled
                                ? (Matrix4.identity()..scale(1.2))
                                : Matrix4.identity(),
                            transformAlignment: Alignment.center,
                          );
                        }),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Number pad
                  _buildNumberPad(onSurface, onSurfaceVariant, surfaceVariant),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricButton(
      Color primary, Color onSurfaceVariant, Color surfaceContainerLow) {
    return GestureDetector(
      onTap: _onBiometric,
      child: SizedBox(
        width: 128,
        height: 128,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated outer ring 1
            AnimatedBuilder(
              animation: _ringScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _ringScale.value,
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: primary.withOpacity(0.2), width: 2),
                    ),
                  ),
                );
              },
            ),
            // Inner ring
            AnimatedBuilder(
              animation: _ringScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 - (_ringScale.value - 1) * 0.3,
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: primary.withOpacity(0.4), width: 1),
                    ),
                  ),
                );
              },
            ),
            // Icon container with scan effect
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.fingerprint,
                        size: 64,
                        color: primary,
                        weight: 300),
                  ),
                  // Scanning gradient overlay
                  AnimatedBuilder(
                    animation: _scanAnim,
                    builder: (context, child) {
                      return ClipOval(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                primary.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              stops: [
                                (_scanAnim.value - 0.3).clamp(0.0, 1.0),
                                _scanAnim.value.clamp(0.0, 1.0),
                                (_scanAnim.value + 0.3).clamp(0.0, 1.0),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad(Color onSurface, Color onSurfaceVariant, Color surfaceVariant) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['bio', '0', 'del'],
    ];
    return SizedBox(
      width: 320,
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: row.map((k) {
                return _buildKey(k, onSurface, onSurfaceVariant, surfaceVariant);
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String k, Color onSurface, Color onSurfaceVariant, Color surfaceVariant) {
    if (k == 'bio') {
      return _KeyButton(
        onTap: _onBiometric,
        child: Icon(Icons.fingerprint, size: 28, color: onSurfaceVariant),
      );
    }
    if (k == 'del') {
      return _KeyButton(
        onTap: _onBackspace,
        child: Icon(Icons.backspace_outlined, size: 28, color: onSurfaceVariant),
      );
    }
    return _KeyButton(
      onTap: () => _onDigit(k),
      child: Text(k,
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: onSurface)),
    );
  }
}

class _KeyButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _KeyButton({required this.onTap, required this.child});

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _pressed
              ? const Color(0xFFE1E3E4) // surface-variant
              : Colors.transparent,
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}
