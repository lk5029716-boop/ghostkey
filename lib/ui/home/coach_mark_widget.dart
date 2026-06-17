import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';

/// First-run coach mark — a blurred scrim with a short hint
/// and a single "OK" button. Persists dismissal to SharedPreferences
/// so it shows once per install.
class CoachMarkWidget extends StatelessWidget {
  const CoachMarkWidget({super.key});

  static const _key = 'has_shown_coach_mark_v1';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: kSurface.withOpacity(0.4),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 48,
                    color: kPrimary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tap to copy a code',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: kOnSurface),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Long-press a code for more options.\n'
                    'Tap the sort icon to choose a different order,\n'
                    'or pick "Manual order" to drag-and-reorder.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: kOnSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 160,
                    child: OutlinedButton(
                      onPressed: _dismiss,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimary,
                        side: const BorderSide(color: kPrimary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    // Caller should listen to prefs and rebuild; for simplicity,
    // we use a ValueNotifier bound to the home page.
  }
}

/// Tracks whether the coach mark has been shown this install.
class CoachMarkState {
  static const _key = 'has_shown_coach_mark_v1';
  final ValueNotifier<bool> shown = ValueNotifier<bool>(true);

  CoachMarkState() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    shown.value = prefs.getBool(_key) ?? false;
  }

  Future<void> markShown() async {
    shown.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
