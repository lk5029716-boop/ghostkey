import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_widgets.dart';
import '../main.dart' show kPrimary, kOnPrimary, kOnSurface, kOnSurfaceVariant, kSurface, kSurfaceContainer, kSurfaceContainerHigh, kOutline, kOutlineVariant;
import 'pin_screens.dart';

enum AuthMode { signup, signin }

class AuthScreen extends StatefulWidget {
  final AuthMode mode;
  const AuthScreen({super.key, required this.mode});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _busy = false;

  Future<void> _afterAuth() async {
    final prefs = context.read<SharedPreferences>();
    await prefs.setBool('onboarded', true);
    if (!mounted) return;
    // Always go to PIN setup (which itself offers Skip)
    rootNavigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
    );
  }

  Future<void> _onGoogle() async {
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _busy = false);
    _afterAuth();
  }

  Future<void> _onEmail() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _EmailFormScreen(mode: widget.mode)),
    );
    if (result == true) {
      _afterAuth();
    }
  }

  Future<void> _onPhone() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _PhoneFormScreen(mode: widget.mode)),
    );
    if (result == true) {
      _afterAuth();
    }
  }

  Future<void> _onSkip() async {
    final prefs = context.read<SharedPreferences>();
    await prefs.setBool('onboarded', true);
    if (!mounted) return;
    rootNavigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignup = widget.mode == AuthMode.signup;
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: kOnSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    // Hero icon
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kPrimary.withOpacity(0.08),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.12),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shield_outlined, size: 44, color: kPrimary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isSignup ? 'Create your account' : 'Welcome back',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: kOnSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSignup
                          ? 'Secure your digital legacy in seconds'
                          : 'Sign in to access your vault',
                      style: const TextStyle(
                        fontSize: 14,
                        color: kOnSurfaceVariant,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Google button — white, premium
                    _SocialButton(
                      icon: _GoogleLogo(),
                      label: isSignup ? 'Continue with Google' : 'Sign in with Google',
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1F1F1F),
                      borderColor: const Color(0xFFDADCE0),
                      onTap: _busy ? null : _onGoogle,
                    ),
                    const SizedBox(height: 12),
                    // Email button — outlined
                    _SocialButton(
                      icon: const Icon(Icons.mail_outline, size: 20, color: kOnSurface),
                      label: isSignup ? 'Continue with Email' : 'Sign in with Email',
                      backgroundColor: kSurface,
                      foregroundColor: kOnSurface,
                      borderColor: kOutlineVariant,
                      onTap: _busy ? null : _onEmail,
                    ),
                    const SizedBox(height: 12),
                    // Phone button — outlined
                    _SocialButton(
                      icon: const Icon(Icons.phone_outlined, size: 20, color: kOnSurface),
                      label: isSignup ? 'Continue with Phone' : 'Sign in with Phone',
                      backgroundColor: kSurface,
                      foregroundColor: kOnSurface,
                      borderColor: kOutlineVariant,
                      onTap: _busy ? null : _onPhone,
                    ),
                    const SizedBox(height: 32),
                    // Divider with "or"
                    Row(
                      children: [
                        Expanded(child: Container(height: 1, color: kOutlineVariant.withOpacity(0.5))),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('or', style: TextStyle(fontSize: 13, color: kOnSurfaceVariant)),
                        ),
                        Expanded(child: Container(height: 1, color: kOutlineVariant.withOpacity(0.5))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Skip / offline
                    TextButton(
                      onPressed: _busy ? null : _onSkip,
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.cloud_off_outlined, size: 18, color: kPrimary),
                          SizedBox(width: 8),
                          Text(
                            'Continue offline',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kPrimary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Your data stays on this device. You can add an account later in Settings.',
                        style: TextStyle(fontSize: 11, color: kOnSurfaceVariant.withOpacity(0.7), height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              SizedBox(width: 24, height: 24, child: Center(child: icon)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: foregroundColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
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
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kOnSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isSignup ? 'Sign up with Email' : 'Sign in with Email',
            style: const TextStyle(color: kOnSurface, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _FieldLabel('Email address'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: const TextStyle(color: kOnSurface, fontSize: 15),
                decoration: _fieldDeco('you@example.com'),
              ),
              const SizedBox(height: 20),
              _FieldLabel(isSignup ? 'Create password' : 'Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: kOnSurface, fontSize: 15),
                decoration: _fieldDeco('••••••••').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: kOnSurfaceVariant, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              if (isSignup) ...[
                const SizedBox(height: 8),
                Text(
                  'Use 8+ characters with a number and symbol',
                  style: TextStyle(fontSize: 11, color: kOnSurfaceVariant.withOpacity(0.8)),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: kOnPrimary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isSignup ? 'Create account' : 'Sign in',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
      hintStyle: const TextStyle(color: kOnSurfaceVariant, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kOutlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kOutlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
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
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kOnSurfaceVariant),
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
  bool _busy = false;
  bool _codeSent = false;
  final _codeCtrl = TextEditingController();

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
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kOnSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isSignup ? 'Sign up with Phone' : 'Sign in with Phone',
            style: const TextStyle(color: kOnSurface, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              if (!_codeSent) ...[
                const _FieldLabel('Phone number'),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: kOnSurface, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '+1 555 123 4567',
                    hintStyle: const TextStyle(color: kOnSurfaceVariant, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kOutlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kOutlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kPrimary, width: 1.5),
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 8),
                      child: Icon(Icons.phone_outlined, color: kOnSurfaceVariant, size: 20),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _busy ? null : _sendCode,
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: kOnPrimary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Send verification code',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ] else ...[
                Text(
                  'We sent a code to ${_phoneCtrl.text}',
                  style: const TextStyle(fontSize: 13, color: kOnSurfaceVariant),
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Verification code'),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kOnSurface, fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 8),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    hintStyle: const TextStyle(color: kOnSurfaceVariant, fontSize: 24, letterSpacing: 8),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kOutlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kOutlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kPrimary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _verify,
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: kOnPrimary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verify and continue',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : () {
                    setState(() {
                      _codeSent = false;
                      _codeCtrl.clear();
                    });
                  },
                  child: const Text('Change number', style: TextStyle(color: kPrimary, fontSize: 13)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
