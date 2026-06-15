import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_widgets.dart';
import 'pin_screens.dart';

class SplashScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const SplashScreen({super.key, required this.prefs});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final hasPin = widget.prefs.getString('pin') != null;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => hasPin
            ? PinLoginScreen(prefs: widget.prefs)
            : OnboardingScreen(prefs: widget.prefs),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.vpn_key, size: 64, color: AppColors.background),
            ),
            const SizedBox(height: 24),
            const Text('GhostKey',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Your digital executor',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─── Onboarding Screen — pixel perfect match to HTML ───
class OnboardingScreen extends StatelessWidget {
  final SharedPreferences prefs;
  const OnboardingScreen({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Status bar (matches HTML: 9:30 top-left, signal/wifi/battery top-right)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('9:30', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.8))),
                  Row(
                    children: [
                      Icon(Icons.signal_cellular_4_bar, size: 16, color: Colors.white.withOpacity(0.8)),
                      const SizedBox(width: 4),
                      Icon(Icons.wifi, size: 16, color: Colors.white.withOpacity(0.8)),
                      const SizedBox(width: 4),
                      Icon(Icons.battery_full, size: 16, color: Colors.white.withOpacity(0.8)),
                    ],
                  ),
                ],
              ),
            ),

            // Main content — centered vertically
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hero logo with glow (HTML: h-32 w-32, bg-primary opacity-20 blur-2xl)
                    SizedBox(
                      width: 128,
                      height: 128,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow behind logo
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.15),
                                  blurRadius: 40,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          // Logo icon (HTML uses img, we use shield icon matching the brand)
                          const Icon(
                            Icons.shield,
                            size: 72,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title: "GhostKey" — headline-lg-mobile = 28px/36px/600
                    const Text(
                      'GhostKey',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 36 / 28,
                        letterSpacing: -0.25,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle: "Your digital legacy secured." — body-lg = 16px/24px/400
                    const Text(
                      'Your digital legacy secured.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 24 / 16,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Feature list (HTML: space-y-6 = 24px gap, max-w-xs = 320px)
                    SizedBox(
                      width: 320,
                      child: Column(
                        children: [
                          _FeatureItem(
                            icon: Icons.vpn_key,
                            label: 'Bank-grade encryption',
                          ),
                          const SizedBox(height: 24),
                          _FeatureItem(
                            icon: Icons.alarm_on,
                            label: "Dead man's switch",
                          ),
                          const SizedBox(height: 24),
                          _FeatureItem(
                            icon: Icons.shield_person,
                            label: 'Secure inheritance',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom section (HTML: px-6 pb-10, gap-4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Primary button: full width, rounded-full, green bg, white text
                  // HTML: bg-primary (#0d631b) text-on-primary (#ffffff) py-3.5 rounded-full
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => PinSetupScreen(prefs: prefs)),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1B6D24), // HTML primary color
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Get started',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Login link (HTML: "Already have an account? Sign in")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.25,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => PinLoginScreen(prefs: prefs)),
                          );
                        },
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF88D982), // HTML primary-fixed-dim
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Nav bar indicator (HTML: w-1/3 h-1 bg-surface-variant opacity-40)
                  FractionallySizedBox(
                    widthFactor: 1 / 3,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feature row matching HTML exactly ───
// HTML: w-8 h-8 rounded-full bg-primary/10 text-primary-fixed, icon with FILL=1
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon container: 32x32 circle, primary/10 bg, primary-fixed (#88D982) icon color
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF88D982).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF88D982),
          ),
        ),
        const SizedBox(width: 16),
        // Label: label-lg = 14px/20px/500/0.1 spacing
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 20 / 14,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}
