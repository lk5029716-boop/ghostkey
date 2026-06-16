import 'package:flutter/material.dart';

// ─── App Colors (matching HTML design system) ───
class AppColors {
  static const Color background = Color(0xFF0F1226);
  static const Color surface = Color(0xFF151833);
  static const Color surfaceCard = Color(0xFF1C2040);
  static const Color primary = Color(0xFFF0D25A);
  static const Color primaryGreen = Color(0xFF1B6D24);
  static const Color primaryFixed = Color(0xFF88D982);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white54;
  static const Color textMuted = Colors.white24;
  static const Color error = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFFFA726);
  static const Color success = Color(0xFF4CAF50);
}

// ─── Pin Keypad Input Widget ───
class PinKeypadInput extends StatefulWidget {
  final void Function(String pin) onPinChanged;
  final VoidCallback? onComplete;

  const PinKeypadInput({super.key, required this.onPinChanged, this.onComplete});

  @override
  State<PinKeypadInput> createState() => _PinKeypadInputState();
}

class _PinKeypadInputState extends State<PinKeypadInput> {
  String _pin = '';

  void _onKey(String key) {
    setState(() {
      if (key == 'del') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < 6) {
        _pin += key;
      }
    });
    widget.onPinChanged(_pin);
    if (_pin.length == 6) {
      Future.delayed(const Duration(milliseconds: 200), () {
        widget.onComplete?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PIN dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _pin.length ? const Color(0xFFF0D25A) : Colors.white24,
              ),
            );
          }),
        ),
        const SizedBox(height: 48),
        // Keypad grid
        SizedBox(
          width: 270,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            childAspectRatio: 1.6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              ...['1','2','3','4','5','6','7','8','9'].map((k) => _KeyBtn(
                label: k,
                onTap: () => _onKey(k),
              )),
              _KeyBtn(icon: Icons.backspace_outlined, onTap: () => _onKey('del')),
              _KeyBtn(label: '0', onTap: () => _onKey('0')),
              const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyBtn extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _KeyBtn({this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1C2040).withOpacity(0.5),
      ),
      child: icon != null
          ? Icon(icon, color: Colors.white, size: 22)
          : Text(label!, style: const TextStyle(fontSize: 26, color: Colors.white)),
    );
  }
}

// ─── Primary Button ───
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryButton({super.key, required this.label, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF0D25A),
          foregroundColor: const Color(0xFF0F1226),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        child: loading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
