import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/code.dart';
import '../store/code_store.dart';

class EnterKeyManuallyScreen extends StatefulWidget {
  /// When non-null, the screen opens in edit mode with the form
  /// pre-filled with this code's data. Saving returns the updated Code
  /// via Navigator.pop, instead of persisting directly.
  final Code? editing;

  const EnterKeyManuallyScreen({super.key, this.editing});

  @override
  State<EnterKeyManuallyScreen> createState() => _EnterKeyManuallyScreenState();
}

class _EnterKeyManuallyScreenState extends State<EnterKeyManuallyScreen> {
  static const primary = Color(0xFF0D631B);
  static const onSurface = Color(0xFF191C1D);
  static const onSurfaceVariant = Color(0xFF40493D);
  static const surfaceContainer = Color(0xFFEDEEEF);
  static const surfaceContainerLow = Color(0xFFF3F4F5);
  static const surfaceContainerHigh = Color(0xFFE7E8E9);
  static const surfaceContainerHighest = Color(0xFFE1E3E4);
  static const outlineVariant = Color(0xFFBFCABA);
  static const secondaryContainer = Color(0xFFACF4A4);
  static const onSecondaryContainer = Color(0xFF002203);

  late final TextEditingController _serviceCtrl;
  late final TextEditingController _accountCtrl;
  late final TextEditingController _keyCtrl;
  late final TextEditingController _refreshCtrl;
  late final TextEditingController _digitsCtrl;
  late final TextEditingController _usageCtrl;

  late String _authType;
  late String _algorithm;
  late bool _showAdvanced;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _serviceCtrl = TextEditingController(text: e?.issuer ?? '');
    _accountCtrl = TextEditingController(text: e?.account ?? '');
    _keyCtrl = TextEditingController(text: e?.secret ?? '');
    _refreshCtrl = TextEditingController(text: '${e?.period ?? 30}');
    _digitsCtrl = TextEditingController(text: '${e?.digits ?? 6}');
    _usageCtrl = TextEditingController(text: '${e?.counter ?? 0}');
    _authType = (e?.type ?? Type.totp).name.toUpperCase();
    _algorithm = (e?.algorithm ?? Algorithm.sha1).name.toUpperCase();
    _showAdvanced = e != null;
  }

  void _pasteClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      setState(() => _keyCtrl.text = data!.text!.toUpperCase());
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _serviceCtrl.dispose();
    _accountCtrl.dispose();
    _keyCtrl.dispose();
    _refreshCtrl.dispose();
    _digitsCtrl.dispose();
    _usageCtrl.dispose();
    super.dispose();
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Enter the secret key provided by your service provider. This is usually a string of letters and numbers like JBSWY3DPEHPK3PXP.',
              style: TextStyle(fontSize: 14, color: onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _m3Input({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    TextInputType? keyboardType,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: onSurfaceVariant, fontWeight: FontWeight.w500)),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: 16, color: onSurface),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: placeholder,
              hintStyle: TextStyle(color: onSurfaceVariant.withOpacity(0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? secondaryContainer : surfaceContainer,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: outlineVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? onSecondaryContainer : onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primary, letterSpacing: 1.2),
        ),
      );

  Widget _advancedConfigSection() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text(
                    'Advanced Configuration',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primary, letterSpacing: 1.2),
                  ),
                  const Spacer(),
                  Icon(
                    _showAdvanced ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: primary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _showAdvanced ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('AUTH TYPE', style: TextStyle(fontSize: 12, color: onSurfaceVariant, fontWeight: FontWeight.w500)),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _choiceChip('TOTP', _authType == 'TOTP', () => setState(() => _authType = 'TOTP')),
                      _choiceChip('HOTP', _authType == 'HOTP', () => setState(() => _authType = 'HOTP')),
                      _choiceChip('Steam', _authType == 'Steam', () => setState(() => _authType = 'Steam')),
                      _choiceChip('Yandex', _authType == 'Yandex', () => setState(() => _authType = 'Yandex')),
                      _choiceChip('MOTP', _authType == 'MOTP', () => setState(() => _authType = 'MOTP')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('ALGORITHM', style: TextStyle(fontSize: 12, color: onSurfaceVariant, fontWeight: FontWeight.w500)),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _choiceChip('SHA1', _algorithm == 'SHA1', () => setState(() => _algorithm = 'SHA1')),
                      _choiceChip('SHA224', _algorithm == 'SHA224', () => setState(() => _algorithm = 'SHA224')),
                      _choiceChip('SHA256', _algorithm == 'SHA256', () => setState(() => _algorithm = 'SHA256')),
                      _choiceChip('SHA384', _algorithm == 'SHA384', () => setState(() => _algorithm = 'SHA384')),
                      _choiceChip('SHA512', _algorithm == 'SHA512', () => setState(() => _algorithm = 'SHA512')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _m3Input(label: 'Refresh Time (s)', controller: _refreshCtrl, placeholder: '30', keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _m3Input(label: 'Digits', controller: _digitsCtrl, placeholder: '6', keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _m3Input(label: 'Usage Count (HOTP)', controller: _usageCtrl, placeholder: '0', keyboardType: TextInputType.number),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editing != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: surfaceContainerHigh,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Code' : 'Enter Key Manually',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.shield, color: primary),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoCard(),
                const SizedBox(height: 24),
                _sectionLabel('Account Details'),
                const SizedBox(height: 12),
                _m3Input(
                  label: 'Service Name',
                  controller: _serviceCtrl,
                  placeholder: 'e.g. Google, Binance, Github',
                ),
                const SizedBox(height: 12),
                _m3Input(
                  label: 'Account Name (Optional)',
                  controller: _accountCtrl,
                  placeholder: 'e.g. user@email.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                _sectionLabel('Security Anchor'),
                const SizedBox(height: 12),
                _m3Input(
                  label: 'Secret Key',
                  controller: _keyCtrl,
                  placeholder: 'BASE32 STRING',
                  trailing: GestureDetector(
                    onTap: _pasteClipboard,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text('PASTE', style: TextStyle(fontSize: 14, color: primary, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: [
                      Icon(Icons.lock, size: 14, color: onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Your key is encrypted and never leaves this device.',
                        style: TextStyle(fontSize: 12, color: onSurfaceVariant, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _advancedConfigSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA).withOpacity(0.9),
                border: Border(top: BorderSide(color: outlineVariant.withOpacity(0.3))),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final service = _serviceCtrl.text.trim();
                        final account = _accountCtrl.text.trim();
                        final secret = _keyCtrl.text.trim().replaceAll(' ', '');
                        if (service.isEmpty || secret.isEmpty) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Service name and secret key are required')),
                          );
                          return;
                        }
                        final digits = int.tryParse(_digitsCtrl.text.trim()) ?? 6;
                        final period = int.tryParse(_refreshCtrl.text.trim()) ?? 30;
                        final counter = int.tryParse(_usageCtrl.text.trim()) ?? 0;
                        final algo = _parseAlgorithm(_algorithm);
                        final type = _parseType(_authType);
                        final code = Code.fromAccountAndSecret(
                          type,
                          account.isEmpty ? service : account,
                          service,
                          secret,
                          null,
                          digits,
                          algorithm: algo,
                          period: period,
                        ).copyWith(counter: counter);

                        if (isEditing) {
                          // Return the updated code to the caller (CodeWidget);
                          // caller handles the save so it can preserve generatedID.
                          if (!mounted) return;
                          Navigator.pop(context, code);
                          return;
                        }

                        // Add mode: persist to the store. The DB uses
                        // code.hashCode.toString() as the unique id; when
                        // the user adds a NEW code (different data) the
                        // hashCode differs and a new row is inserted.
                        await CodeStore.instance.addCode(code);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('2FA account added!'), duration: Duration(seconds: 2)),
                        );
                        Navigator.pop(context);
                      } catch (e, st) {
                        debugPrint('Add 2FA error: $e\n$st');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: ${e.toString().substring(0, e.toString().length > 80 ? 80 : e.toString().length)}'), duration: const Duration(seconds: 4)),
                        );
                      }
                    },
                    icon: Icon(isEditing ? Icons.save : Icons.add_task),
                    label: Text(
                      isEditing ? 'Save changes' : 'Add Account',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Algorithm _parseAlgorithm(String s) {
    switch (s.toUpperCase()) {
      case 'SHA224': return Algorithm.sha1; // sha224 unsupported; fall back
      case 'SHA256': return Algorithm.sha256;
      case 'SHA384': return Algorithm.sha512; // sha384 unsupported; fall back
      case 'SHA512': return Algorithm.sha512;
      default: return Algorithm.sha1;
    }
  }

  Type _parseType(String s) {
    switch (s.toUpperCase()) {
      case 'HOTP': return Type.hotp;
      case 'STEAM': return Type.steam;
      case 'YANDEX': return Type.totp; // yandex maps to TOTP
      case 'MOTP': return Type.totp;   // MOTP uses time + pin; show as TOTP
      default: return Type.totp;
    }
  }
}
