import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' show rootNavigatorKey, MainShell;
import '../pin_unlock_screen.dart' show PinScreen, PinScreenMode;

enum AuthMode { signup, signin }

class AuthScreen extends StatefulWidget {
  final AuthMode mode;
  const AuthScreen({super.key, required this.mode});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _busy = false;

  void _goToPinSetup() {
    final prefs = context.read<SharedPreferences>();
    prefs.setBool('onboarded', true);
    rootNavigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (_) => PinScreen(
          title: 'Create your PIN',
          subtitle: 'A 6-digit code to unlock your vault',
          mode: PinScreenMode.setup,
          onUnlock: (pin) {
            prefs.setString('pin', pin);
            rootNavigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (_) => const MainShell()),
            );
          },
          onSkip: () {
            rootNavigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (_) => const MainShell()),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onGoogle() async {
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _busy = false);
    _goToPinSetup();
  }

  Future<void> _onEmail() async {
    final result = await rootNavigatorKey.currentState!.push<bool>(
      MaterialPageRoute(builder: (_) => _EmailFormScreen(mode: widget.mode)),
    );
    if (result == true) _goToPinSetup();
  }

  Future<void> _onPhone() async {
    final result = await rootNavigatorKey.currentState!.push<bool>(
      MaterialPageRoute(builder: (_) => _PhoneFormScreen(mode: widget.mode)),
    );
    if (result == true) _goToPinSetup();
  }

  void _onSkip() => _goToPinSetup();

  @override
  Widget build(BuildContext context) {
    final isSignup = widget.mode == AuthMode.signup;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFEFF1F3)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF191C1D), size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Premium hero — large shield with multi-layer glow
                      SizedBox(
                        width: 144,
                        height: 144,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer soft glow
                            Container(
                              width: 144,
                              height: 144,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF0D631B).withOpacity(0.18),
                                    const Color(0xFF0D631B).withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                            // Mid ring
                            Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0D631B).withOpacity(0.06),
                                border: Border.all(
                                  color: const Color(0xFF0D631B).withOpacity(0.12),
                                  width: 1,
                                ),
                              ),
                            ),
                            // Inner badge
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0D631B).withOpacity(0.20),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.shield_outlined, size: 44, color: Color(0xFF0D631B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Headline
                      Text(
                        isSignup ? 'Create your account' : 'Welcome back',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          height: 36 / 28,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF191C1D),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isSignup
                            ? 'Pick a method to secure your digital legacy.\nYou can change this later.'
                            : 'Sign in to access your encrypted vault.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          color: Color(0xFF40493D),
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 36),
                      // ─── Social buttons ───
                      _GoogleButton(
                        label: isSignup ? 'Continue with Google' : 'Sign in with Google',
                        onTap: _busy ? null : _onGoogle,
                      ),
                      const SizedBox(height: 12),
                      _OutlinedSocialButton(
                        icon: Icons.mail_outline,
                        label: isSignup ? 'Continue with Email' : 'Sign in with Email',
                        onTap: _busy ? null : _onEmail,
                      ),
                      const SizedBox(height: 12),
                      _OutlinedSocialButton(
                        icon: Icons.phone_outlined,
                        label: isSignup ? 'Continue with Phone' : 'Sign in with Phone',
                        onTap: _busy ? null : _onPhone,
                      ),
                      const SizedBox(height: 32),
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: const Color(0xFFD8DCD4))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('or', style: TextStyle(fontSize: 12, color: Color(0xFF707A6C), fontWeight: FontWeight.w500)),
                          ),
                          Expanded(child: Container(height: 1, color: const Color(0xFFD8DCD4))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Skip / offline
                      _OutlinedSocialButton(
                        icon: Icons.cloud_off_outlined,
                        label: 'Continue offline',
                        iconColor: const Color(0xFF0D631B),
                        labelColor: const Color(0xFF0D631B),
                        borderColor: const Color(0xFF0D631B).withOpacity(0.25),
                        onTap: _busy ? null : _onSkip,
                      ),
                      const SizedBox(height: 16),
                      // Trust message
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline, size: 13, color: Color(0xFF707A6C)),
                          const SizedBox(width: 6),
                          Text(
                            'End-to-end encrypted • Zero-knowledge',
                            style: TextStyle(fontSize: 11, color: const Color(0xFF707A6C).withOpacity(0.9), letterSpacing: 0.2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Google Button — full-color G logo, white card with shadow ───
class _GoogleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _GoogleButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E5E0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Real Google G — 4 colors
              SizedBox(
                width: 22,
                height: 22,
                child: CustomPaint(painter: _GoogleGLogoPainter()),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F1F1F),
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward, size: 16, color: Color(0xFFBFCABA)),
            ],
          ),
        ),
      ),
    );
  }
}

// Real Google G logo with 4 brand colors
class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;
    final center = Offset(w / 2, h / 2);

    // Outer ring: blue (top), green (right), yellow (bottom-right), red (left)
    // We'll draw 4 arcs, each in one color
    final rect = Rect.fromCircle(center: center, radius: r - 1);

    // Blue (top to right)
    final p1 = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -1.5708, 1.5708, false, p1);

    // Green (right to bottom)
    final p2 = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 1.5708, false, p2);

    // Yellow (bottom to left)
    final p3 = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 1.5708, 1.5708, false, p3);

    // Red (left to top)
    final p4 = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 3.1416, 1.5708, false, p4);

    // Inner horizontal bar (blue, the tail of the G)
    final p5 = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final barY = h * 0.5;
    canvas.drawLine(
      Offset(w * 0.42, barY),
      Offset(w * 0.78, barY),
      p5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Outlined Social Button (Email / Phone) ───
class _OutlinedSocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;
  final Color? borderColor;

  const _OutlinedSocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? const Color(0xFF191C1D);
    final lc = labelColor ?? const Color(0xFF191C1D);
    final bc = borderColor ?? const Color(0xFFD8DCD4);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: bc, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: ic),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: lc,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward, size: 16, color: bc),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Email Form Screen ───
class _EmailFormScreen extends StatefulWidget {
  final AuthMode mode;
  const _EmailFormScreen({required this.mode});
  @override
  State<_EmailFormScreen> createState() => _EmailFormScreenState();
}

class _EmailFormScreenState extends State<_EmailFormScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password')),
      );
      return;
    }
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isSignup = widget.mode == AuthMode.signup;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF191C1D)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isSignup ? 'Sign up with Email' : 'Sign in with Email',
          style: const TextStyle(color: Color(0xFF191C1D), fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Hero
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D631B).withOpacity(0.08),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D631B).withOpacity(0.10),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mail_outline, size: 32, color: Color(0xFF0D631B)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSignup ? 'Create your account' : 'Sign in to GhostKey',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF191C1D), letterSpacing: -0.2),
              ),
              const SizedBox(height: 6),
              Text(
                isSignup
                    ? "We'll send a confirmation to verify your email"
                    : 'Enter your credentials to access your vault',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF707A6C), height: 1.4),
              ),
              const SizedBox(height: 28),
              _FieldLabel('Email address'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: const TextStyle(color: Color(0xFF191C1D), fontSize: 15),
                decoration: _fieldDeco('you@example.com'),
              ),
              const SizedBox(height: 20),
              _FieldLabel(isSignup ? 'Create password' : 'Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: Color(0xFF191C1D), fontSize: 15),
                decoration: _fieldDeco('••••••••').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: const Color(0xFF707A6C),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              if (isSignup) ...[
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF707A6C)),
                    SizedBox(width: 6),
                    Text('8+ characters with a number and symbol',
                        style: TextStyle(fontSize: 11, color: Color(0xFF707A6C))),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D631B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        isSignup ? 'Create account' : 'Sign in',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBFCABA), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E5E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E5E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0D631B), width: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF40493D)),
    );
  }
}

// ─── Phone Form Screen ───
class _PhoneFormScreen extends StatefulWidget {
  final AuthMode mode;
  const _PhoneFormScreen({required this.mode});
  @override
  State<_PhoneFormScreen> createState() => _PhoneFormScreenState();
}

class _PhoneFormScreenState extends State<_PhoneFormScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_phoneCtrl.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number')),
      );
      return;
    }
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _codeSent = true;
    });
  }

  Future<void> _verify() async {
    if (_codeCtrl.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code')),
      );
      return;
    }
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isSignup = widget.mode == AuthMode.signup;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF191C1D)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isSignup ? 'Sign up with Phone' : 'Sign in with Phone',
          style: const TextStyle(color: Color(0xFF191C1D), fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D631B).withOpacity(0.08),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D631B).withOpacity(0.10),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.phone_outlined, size: 32, color: Color(0xFF0D631B)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSignup ? 'Verify your phone' : 'Sign in with SMS',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF191C1D), letterSpacing: -0.2),
              ),
              const SizedBox(height: 6),
              Text(
                isSignup
                    ? "We'll text you a verification code"
                    : 'Enter your phone to receive a sign-in code',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF707A6C), height: 1.4),
              ),
              const SizedBox(height: 28),
              if (!_codeSent) ...[
                _FieldLabel('Phone number'),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Color(0xFF191C1D), fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '+1 555 123 4567',
                    hintStyle: const TextStyle(color: Color(0xFFBFCABA), fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E5E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E5E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0D631B), width: 1.5),
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 8),
                      child: Icon(Icons.phone_outlined, color: Color(0xFF707A6C), size: 20),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _busy ? null : _sendCode,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D631B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Send verification code',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ] else ...[
                Text(
                  'We sent a code to ${_phoneCtrl.text}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF40493D)),
                ),
                const SizedBox(height: 20),
                _FieldLabel('Verification code'),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF191C1D),
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 12,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    hintStyle: const TextStyle(color: Color(0xFFBFCABA), fontSize: 26, letterSpacing: 12),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E5E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E5E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0D631B), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _verify,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D631B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify and continue',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : () {
                    setState(() {
                      _codeSent = false;
                      _codeCtrl.clear();
                    });
                  },
                  child: const Text('Change number', style: TextStyle(color: Color(0xFF0D631B), fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
