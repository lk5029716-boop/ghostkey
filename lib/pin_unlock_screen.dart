// ═══════════════════════════════════════════════════════════════
// PIN SCREEN — Modern biometric + 6-digit PIN
// unlock mode: small fingerprint in keypad → big biometric prompt
// setup mode: PIN entry with double confirmation
// Matches HTML reference design
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PinScreenMode { unlock, setup }

class PinScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final PinScreenMode mode;
  final String? expectedPin;
  final ValueChanged<String>? onUnlock;

  const PinScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.mode = PinScreenMode.unlock,
    this.expectedPin,
    this.onUnlock,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with TickerProviderStateMixin {
  static const _maxPinLength = 6;
  String _pin = '';
  String _firstPin = '';
  bool _confirming = false;
  String? _errorText;
  bool _showBiometric = false;

  late final AnimationController _scanController;
  late final AnimationController _ringController;
  late final AnimationController _shakeController;
  late final Animation<double> _scanAnim;
  late final Animation<double> _ringScale;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _scanAnim = CurvedAnimation(parent: _scanController, curve: Curves.easeInOut);

    _ringController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);
    _ringScale = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeController);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _ringController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onKey(String key) {
    if (_pin.length >= _maxPinLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += key;
      _errorText = null;
    });
    if (_pin.length == _maxPinLength) {
      _handleComplete();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorText = null;
    });
  }

  void _onSmallBiometric() {
    HapticFeedback.selectionClick();
    setState(() => _showBiometric = true);
  }

  void _onBigBiometric() {
    HapticFeedback.mediumImpact();
    if (widget.mode == PinScreenMode.unlock) {
      widget.onUnlock?.call('');
    } else {
      // Setup mode: no biometric available, just hide the prompt
      setState(() => _showBiometric = false);
    }
  }

  void _handleComplete() {
    if (widget.mode == PinScreenMode.unlock) {
      if (_pin == widget.expectedPin) {
        HapticFeedback.mediumImpact();
        widget.onUnlock?.call(_pin);
      } else {
        _shakeAndReset();
      }
    } else {
      if (!_confirming) {
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _confirming = true;
        });
      } else {
        if (_pin == _firstPin) {
          HapticFeedback.mediumImpact();
          widget.onUnlock?.call(_pin);
        } else {
          _shakeAndReset(setupMismatch: true);
        }
      }
    }
  }

  void _shakeAndReset({bool setupMismatch = false}) {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0).then((_) => _shakeController.reset());
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _errorText = widget.mode == PinScreenMode.setup && _confirming
            ? "PINs don't match. Try again."
            : 'Incorrect PIN';
        _pin = '';
        if (setupMismatch) {
          _firstPin = '';
          _confirming = false;
        }
      });
    });
  }

  String get _displaySubtitle {
    if (_errorText != null) return _errorText!;
    if (widget.mode == PinScreenMode.setup && _confirming) {
      return 'Re-enter your 6-digit PIN';
    }
    return widget.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFF3F4F5)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Headlines
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 36 / 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF191C1D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _displaySubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _errorText != null
                        ? const Color(0xFFBA1A1A)
                        : const Color(0xFF40493D),
                  ),
                ),
                const SizedBox(height: 32),
                // Middle: biometric prompt (only shown after small tap)
                if (_showBiometric)
                  _buildBigBiometric()
                else
                  const SizedBox(height: 128),
                const SizedBox(height: 16),
                if (_showBiometric)
                  Text(
                    widget.mode == PinScreenMode.unlock
                        ? 'OR ENTER PIN'
                        : 'OR USE FINGERPRINT',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF40493D),
                    ),
                  )
                else
                  const SizedBox(height: 8),
                const SizedBox(height: 16),
                // PIN dots with shake
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (context, child) {
                    final dx = (_shakeAnim.value == 0)
                        ? 0.0
                        : 10 *
                            (1 - _shakeAnim.value) *
                            ((_shakeAnim.value * 12).toInt().isEven ? 1 : -1);
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    );
                  },
                  child: _buildPinDots(),
                ),
                const Spacer(),
                // Number pad
                _buildKeypad(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBigBiometric() {
    return AnimatedBuilder(
      animation: _ringScale,
      builder: (context, _) {
        return GestureDetector(
          onTap: _onBigBiometric,
          child: SizedBox(
            width: 128,
            height: 128,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: _ringScale.value,
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0x330D631B),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0x660D631B),
                      width: 1,
                    ),
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF3F4F5),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.fingerprint,
                          size: 56,
                          color: const Color(0xFF0D631B).withOpacity(0.6),
                        ),
                      ),
                      // Scanning overlay
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _scanAnim,
                          builder: (context, _) {
                            return ClipOval(
                              child: Align(
                                alignment: Alignment(0, _scanAnim.value * 2 - 1),
                                child: Container(
                                  width: 96,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        const Color(0xFF0D631B).withOpacity(0.15),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_maxPinLength, (i) {
        final filled = i < _pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? const Color(0xFF0D631B) : Colors.transparent,
            border: Border.all(
              color: filled
                  ? const Color(0xFF0D631B)
                  : const Color(0xFF707A6C),
              width: 1,
            ),
          ),
          transform: filled
              ? (Matrix4.identity()..scale(1.2))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
        );
      }),
    );
  }

  Widget _buildKeypad() {
    return SizedBox(
      width: 280,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 20,
        childAspectRatio: 1.0,
        children: [
          _key('1'),
          _key('2'),
          _key('3'),
          _key('4'),
          _key('5'),
          _key('6'),
          _key('7'),
          _key('8'),
          _key('9'),
          // Row 4: small fingerprint | 0 | backspace (same in both modes)
          _smallBiometricKey(),
          _key('0'),
          _backspaceKey(),
        ],
      ),
    );
  }

  Widget _key(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKey(digit),
        customBorder: const CircleBorder(),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF191C1D),
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallBiometricKey() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onSmallBiometric,
        customBorder: const CircleBorder(),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: const Icon(
            Icons.fingerprint,
            size: 28,
            color: Color(0xFF0D631B),
          ),
        ),
      ),
    );
  }

  Widget _backspaceKey() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onBackspace,
        customBorder: const CircleBorder(),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: const Icon(
            Icons.backspace_outlined,
            size: 24,
            color: Color(0xFF40493D),
          ),
        ),
      ),
    );
  }
}
