// ═══════════════════════════════════════════════════════════════
// SECURITY SETUP SCREEN — GhostKey themed
// PIN setup, lockout config, biometric, screenshot control
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
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

  // Toggle FLAG_SECURE on the main window to block/allow screenshots
  void _setScreenshotAllowed(bool allow) {
    if (allow) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // Clear the secure flag by setting a new window flag via MethodChannel
      const channel = MethodChannel('ghostkey/window');
      channel.invokeMethod('setSecure', false).catchError((_) {});
    } else {
      const channel = MethodChannel('ghostkey/window');
      channel.invokeMethod('setSecure', true).catchError((_) {});
    }
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
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [3, 5, 10].map((v) {
          return ListTile(
            title: Text('$v attempts',
                style: const TextStyle(fontSize: 16, color: Color(0xFF191C1D))),
            trailing: _maxAttempts == v
                ? const Icon(Icons.check, color: kPrimary)
                : null,
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
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [1, 5, 15].map((m) {
          return ListTile(
            title: Text('$m ${m == 1 ? 'minute' : 'minutes'}',
                style: const TextStyle(fontSize: 16, color: Color(0xFF191C1D))),
            trailing: _lockoutMinutes == m
                ? const Icon(Icons.check, color: kPrimary)
                : null,
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
    const primary = kPrimary;
    const onSurface = kOnSurface;
    const surface = kSurface;
    const outlineVar = kOutlineVariant;
    const cardBg = Colors.white;

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
                fontSize: 20, fontWeight: FontWeight.w700, color: kOnSurface)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),

          // ── Section: Settings ──────────────────────────────────
          _sectionHeader('Settings', primary),
          const SizedBox(height: 8),
          _card(cardBg, outlineVar, [
            _toggleRow(
              icon: Icons.grid_view_rounded,
              title: 'PIN code',
              value: _pinEnabled,
              activeColor: primary,
              onChanged: (v) {
                setState(() => _pinEnabled = v);
                _saveBool(_kPinEnabled, v);
                if (v) {
                  _changePin();
                }
              },
            ),
            _divider(outlineVar),
            _actionRow(
              icon: Icons.refresh,
              title: 'Change PIN',
              onTap: _pinEnabled ? _changePin : null,
            ),
          ]),
          const SizedBox(height: 24),

          // ── Section: Lockout settings ─────────────────────────
          _sectionHeader('Lockout settings', primary),
          const SizedBox(height: 8),
          _card(cardBg, outlineVar, [
            _valueRow(
              icon: Icons.remove_circle_outline,
              title: 'Max failed attempts',
              value: '$_maxAttempts',
              description:
                  'Select the maximum number of unsuccessful attempts to enter the passcode before locking the application (lockout time can be changed below).',
              onTap: _showAttemptsPicker,
            ),
            _divider(outlineVar),
            _valueRow(
              icon: Icons.timer_outlined,
              title: 'Lockout time',
              value:
                  '$_lockoutMinutes ${_lockoutMinutes == 1 ? 'minute' : 'minutes'}',
              description: 'Select the time for which the app will be locked.',
              onTap: _showLockoutPicker,
            ),
          ]),
          const SizedBox(height: 24),

          // ── Section: Biometrics ────────────────────────────────
          _sectionHeader('Biometrics', primary),
          const SizedBox(height: 8),
          _card(cardBg, outlineVar, [
            _toggleRow(
              icon: Icons.fingerprint,
              title: 'Biometric Lock',
              value: _biometricEnabled,
              activeColor: primary,
              onChanged:
                  (_biometricSupported && _biometricEnrolled) ? _setBiometric : null,
            ),
          ]),
          const SizedBox(height: 24),

          // ── Section: Screenshots ───────────────────────────────
          _sectionHeader('Screenshots', primary),
          const SizedBox(height: 8),
          _card(cardBg, outlineVar, [
            _toggleRow(
              icon: Icons.screenshot_monitor,
              title: 'Allow screenshots',
              subtitle: 'Allow screenshots of the app for 5 minutes.',
              value: _allowScreenshots,
              activeColor: primary,
              onChanged: (v) {
                setState(() => _allowScreenshots = v);
                _saveBool(_kAllowScreenshots, v);
                _setScreenshotAllowed(v);
              },
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
              letterSpacing: 0.1)),
    );
  }

  Widget _divider(Color color) {
    return Divider(height: 1, thickness: 1, color: color.withOpacity(0.1), indent: 56);
  }

  Widget _card(Color bg, Color outline, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _iconBadge(IconData icon, {Color? color}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color ?? kPrimary, size: 22),
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required Color activeColor,
    ValueChanged<bool>? onChanged,
  }) {
    final disabled = onChanged == null;
    return InkWell(
      onTap: disabled ? null : () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          _iconBadge(icon, color: disabled ? Colors.grey : null),
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
            activeColor: activeColor,
            activeTrackColor: activeColor.withOpacity(0.3),
          ),
        ]),
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          _iconBadge(icon, color: enabled ? null : Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: enabled ? const Color(0xFF191C1D) : Colors.grey)),
          ),
          Icon(Icons.chevron_right,
              color: enabled ? const Color(0xFF40493D) : Colors.grey[300]),
        ]),
      ),
    );
  }

  Widget _valueRow({
    required IconData icon,
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
              _iconBadge(icon),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF191C1D))),
              ),
              Text(value,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF40493D))),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Color(0xFF40493D)),
            ]),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 56),
              child: Text(description,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[500], height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}
