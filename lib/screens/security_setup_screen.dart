// ═══════════════════════════════════════════════════════════════
// SECURITY SETUP SCREEN
// PIN setup, lockout config, biometric, screenshot control
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pin_unlock_screen.dart';
import '../services/biometric_service.dart';

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  static const _kPinEnabled = 'security_pin_enabled';
  static const _kMaxAttempts = 'security_max_attempts';
  static const _kLockoutTime = 'security_lockout_minutes';
  static const _kAllowScreenshots = 'security_allow_screenshots';

  bool _pinEnabled = false;
  int _maxAttempts = 3;
  int _lockoutMinutes = 5;
  bool _allowScreenshots = false;
  bool _biometricEnabled = false;
  bool _biometricSupported = false;
  bool _biometricEnrolled = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
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

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pinEnabled = p.getBool(_kPinEnabled) ?? false;
      _maxAttempts = p.getInt(_kMaxAttempts) ?? 3;
      _lockoutMinutes = p.getInt(_kLockoutTime) ?? 5;
      _allowScreenshots = p.getBool(_kAllowScreenshots) ?? false;
    });
  }

  Future<void> _saveBool(String key, bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, v);
  }

  Future<void> _saveInt(String key, int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(key, v);
  }

  Future<void> _setBiometric(bool v) async {
    if (v && (!_biometricSupported || !_biometricEnrolled)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No biometric enrolled. Add fingerprint/face in Android Settings.'),
        ),
      );
      return;
    }
    await BiometricService.instance.setEnabled(v);
    if (!mounted) return;
    setState(() => _biometricEnabled = v);
  }

  void _changePin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PinScreen(
          title: 'Change PIN',
          subtitle: 'Enter your current PIN to change it',
          mode: PinScreenMode.setup,
          onUnlock: (_) {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showAttemptsPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [3, 5, 10].map((v) {
          return ListTile(
            title: Text('$v attempts'),
            trailing: _maxAttempts == v ? const Icon(Icons.check, color: Colors.red) : null,
            onTap: () {
              setState(() => _maxAttempts = v);
              _saveInt(_kMaxAttempts, v);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showLockoutPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [1, 5, 15].map((m) {
          return ListTile(
            title: Text('$m ${m == 1 ? 'minute' : 'minutes'}'),
            trailing: _lockoutMinutes == m ? const Icon(Icons.check, color: Colors.red) : null,
            onTap: () {
              setState(() => _lockoutMinutes = m);
              _saveInt(_kLockoutTime, m);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE53935);
    const onSurface = Color(0xFF191C1D);
    const onSurfaceVar = Color(0xFF757575);
    const surface = Color(0xFFFFFFFF);
    const divider = Color(0xFFE0E0E0);

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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: onSurface)),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // ── Section: Settings ──────────────────────────────────
          _sectionHeader('Settings', red),
          _toggleRow(
            icon: Icons.grid_view_rounded,
            iconColor: red,
            title: 'PIN code',
            value: _pinEnabled,
            onChanged: (v) {
              setState(() => _pinEnabled = v);
              _saveBool(_kPinEnabled, v);
              if (v && !_pinEnabled) {
                // First time enabling — prompt to set up PIN
                _changePin();
              }
            },
          ),
          _divider(divider),
          _actionRow(
            icon: Icons.refresh,
            iconColor: red,
            title: 'Change PIN',
            onTap: _pinEnabled ? _changePin : null,
          ),

          // ── Section: Lockout settings ─────────────────────────
          _sectionHeader('Lockout settings', red),
          _valueRow(
            icon: Icons.remove_circle_outline,
            iconColor: red,
            title: 'Max failed attempts',
            value: '$_maxAttempts',
            description:
                'Select the maximum number of unsuccessful attempts to enter the passcode before locking the application (lockout time can be changed below).',
            onTap: _showAttemptsPicker,
          ),
          _divider(divider),
          _valueRow(
            icon: Icons.timer_outlined,
            iconColor: red,
            title: 'Lockout time',
            value: '$_lockoutMinutes ${_lockoutMinutes == 1 ? 'minute' : 'minutes'}',
            description:
                'Select the time for which the app will be locked.',
            onTap: _showLockoutPicker,
          ),

          // ── Section: Biometrics ────────────────────────────────
          _sectionHeader('Biometrics', red),
          _toggleRow(
            icon: Icons.fingerprint,
            iconColor: red,
            title: 'Biometric Lock',
            value: _biometricEnabled,
            onChanged: (_biometricSupported && _biometricEnrolled) ? _setBiometric : null,
          ),

          // ── Allow screenshots ──────────────────────────────────
          _divider(divider),
          _toggleRow(
            icon: Icons.screenshot_monitor,
            iconColor: red,
            title: 'Allow screenshots',
            subtitle: 'Allow screenshots of the app for 5 minutes.',
            value: _allowScreenshots,
            onChanged: (v) {
              setState(() => _allowScreenshots = v);
              _saveBool(_kAllowScreenshots, v);
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _divider(Color color) {
    return Divider(height: 1, color: color, indent: 56);
  }

  Widget _iconContainer(IconData icon, Color color) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    final disabled = onChanged == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        _iconContainer(icon, disabled ? Colors.grey : iconColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: disabled ? Colors.grey : const Color(0xFF191C1D))),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFE53935),
          activeTrackColor: const Color(0xFFE53935).withOpacity(0.3),
        ),
      ]),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          _iconContainer(icon, disabled ? Colors.grey : iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: disabled ? Colors.grey : const Color(0xFF191C1D))),
          ),
          Icon(Icons.chevron_right,
              color: disabled ? Colors.grey[300] : const Color(0xFF40493D)),
        ]),
      ),
    );
  }

  Widget _valueRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _iconContainer(icon, iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF191C1D))),
              ),
              Text(value,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF757575))),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Color(0xFF40493D)),
            ]),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}
