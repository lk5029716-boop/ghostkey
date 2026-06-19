// ═══════════════════════════════════════════════════════════════
// SECURITY SETUP SCREEN
// PIN setup + biometric setup in one place
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../pin_unlock_screen.dart';
import '../services/biometric_service.dart';

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  bool _biometricEnabled = false;
  bool _biometricSupported = false;
  bool _biometricEnrolled = false;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _biometricEnabled = BiometricService.instance.isEnabled;
    () async {
      final supported = await BiometricService.instance.isDeviceSupported();
      final enrolled = await BiometricService.instance.hasEnrolledBiometrics();
      if (!mounted) return;
      setState(() {
        _biometricSupported = supported;
        _biometricEnrolled = enrolled;
      });
    }();
  }

  Future<void> _setBiometric(bool v) async {
    if (v && (!_biometricSupported || !_biometricEnrolled)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No biometric is enrolled on this device. Add one in Android Settings.'),
        ),
      );
      return;
    }
    await BiometricService.instance.setEnabled(v);
    if (!mounted) return;
    setState(() => _biometricEnabled = v);
  }

  void _setupPin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PinScreen(
          title: _hasPin ? 'Change PIN' : 'Set Up PIN',
          subtitle: _hasPin
              ? 'Enter your current PIN to change it'
              : 'Create a 6-digit PIN to secure your vault',
          mode: PinScreenMode.setup,
          onUnlock: (_) {
            setState(() => _hasPin = true);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0D631B);
    const onSurface = Color(0xFF191C1D);
    const onSurfaceVar = Color(0xFF40493D);
    const surface = Color(0xFFF8F9FA);
    const outlineVar = Color(0xFFBFCABA);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Security',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: primary)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),

          // PIN card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outlineVar.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1)),
              ],
            ),
            child: Column(children: [
              _tile(
                icon: Icons.lock_outline,
                title: _hasPin ? 'Change PIN' : 'Set Up PIN',
                subtitle: _hasPin
                    ? 'Update your 6-digit PIN'
                    : 'Create a PIN to protect your vault',
                onTap: _setupPin,
              ),
              Divider(height: 1, color: outlineVar.withOpacity(0.1), indent: 56),
              _tile(
                icon: Icons.fingerprint,
                title: 'Biometric Unlock',
                subtitle: _biometricSupported && _biometricEnrolled
                    ? (_biometricEnabled ? 'Enabled' : 'Available — tap to enable')
                    : 'Not available on this device',
                trailing: Switch(
                  value: _biometricEnabled,
                  onChanged:
                      (_biometricSupported && _biometricEnrolled) ? _setBiometric : null,
                  activeColor: primary,
                  activeTrackColor: primary.withOpacity(0.3),
                ),
                onTap: null,
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: outlineVar.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.info_outline, color: primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('How it works',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: onSurface)),
                ]),
                const SizedBox(height: 8),
                Text(
                  '• PIN: Required to unlock your vault\n'
                  '• Biometric: Optional quick unlock with fingerprint or face\n'
                  '• You can use PIN only, or PIN + biometric together',
                  style: TextStyle(fontSize: 13, color: onSurfaceVar, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFACF4A4).withOpacity(0.35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0D631B), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF191C1D))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF40493D))),
              ],
            ),
          ),
          trailing ??
              (onTap != null
                  ? const Icon(Icons.chevron_right, color: Color(0xFF40493D))
                  : const SizedBox.shrink()),
        ]),
      ),
    );
  }
}
