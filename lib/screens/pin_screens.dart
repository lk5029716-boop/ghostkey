import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vault_store.dart';
import '../widgets/app_widgets.dart';
import 'dashboard_screen.dart';

class PinSetupScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const PinSetupScreen({super.key, required this.prefs});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  bool _confirming = false;
  String _firstPin = '';

  void _onComplete() {
    if (_pin.length < 6) return;
    if (!_confirming) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _confirming = true;
      });
    } else if (_pin == _firstPin) {
      widget.prefs.setString('pin', _pin);
      final store = context.read<VaultStore>();
      store.setLoggedIn(true);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardScreen(prefs: widget.prefs)),
      );
    } else {
      setState(() {
        _pin = '';
        _confirming = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PINs do not match. Try again.'),
          backgroundColor: AppColors.surfaceCard,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _confirming
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => setState(() {
                  _confirming = false;
                  _pin = '';
                }),
              )
            : null,
        title: Text(_confirming ? 'Confirm PIN' : 'Create PIN',
            style: const TextStyle(color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _confirming ? 'Re-enter your 6-digit PIN' : 'Create a 6-digit PIN to secure your vault',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PinKeypadInput(
                onPinChanged: (p) => setState(() => _pin = p),
                onComplete: _onComplete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PinLoginScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const PinLoginScreen({super.key, required this.prefs});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  String _pin = '';
  bool _error = false;

  void _onComplete() {
    if (_pin.length < 6) return;
    final storedPin = widget.prefs.getString('pin');
    if (_pin == storedPin) {
      final store = context.read<VaultStore>();
      store.setLoggedIn(true);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => DashboardScreen(prefs: widget.prefs)),
        (r) => false,
      );
    } else {
      setState(() {
        _pin = '';
        _error = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect PIN'),
          backgroundColor: AppColors.surfaceCard,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 56, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text('Enter your PIN',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              if (_error) ...[
                const SizedBox(height: 8),
                const Text('Incorrect PIN, try again',
                    style: TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 32),
              PinKeypadInput(
                onPinChanged: (p) => setState(() => _pin = p),
                onComplete: _onComplete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
