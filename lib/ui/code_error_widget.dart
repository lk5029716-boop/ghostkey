import 'package:flutter/material.dart';

import '../models/code.dart';
import 'linear_progress_widget.dart';

/// Shown in the Vault list when a stored code has [Code.err] set
/// (e.g. `otpauth://` URI was malformed on import). Renders an info
/// card listing the count of unparseable codes and offers a single
/// "Remove all" action — GhostKey's local-first flow has no
/// "Contact support" hook (we have a stub in [sendEmail]).
class CodeErrorWidget extends StatelessWidget {
  const CodeErrorWidget({super.key, required this.errors});

  final List<Code> errors;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 132,
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 3,
              child: LinearProgressWidget(
                color: scheme.error,
                fractionOfStorage: 1,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(width: 8),
                Icon(Icons.info, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '${errors.length} code${errors.length == 1 ? '' : 's'} '
                "couldn't be parsed and won't show a live OTP.",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 12),
                child: TextButton(
                  onPressed: () {
                    // Caller is expected to wire the actual delete in
                    // by removing the codes from CodeStore. The error
                    // widget is presentational only.
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Open code → Delete to remove unparseable codes',
                        ),
                      ),
                    );
                  },
                  child: const Text('How to fix'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
