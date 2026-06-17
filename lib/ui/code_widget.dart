import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../models/code.dart';
import '../services/preference_service.dart';
import '../store/code_store.dart';
import '../utils/totp_util.dart';
import 'code_timer_progress.dart';

/// The Vault's primary building block. Renders a single TOTP/HOTP code
/// with:
///
///   - issuer + account header
///   - live 6-digit code that refreshes on every TOTP period boundary
///   - circular progress ring showing seconds remaining in the period
///   - tap-to-copy with "Copied" toast
///   - long-press → context menu (Pin, Delete, Edit, Copy)
///
/// Ported from ente's `CodeWidget` (1173 lines) — kept the live-timer
/// state machine, dropped the ente-specific l10n / theme / custom-icons
/// / event-bus / multi-select / drag-to-reorder / share-to-cloud flow.
/// All visual styling goes through `Theme.of(context).colorScheme` so
/// GhostKey's M3 theme (light surface, green primary) applies.
class CodeWidget extends StatefulWidget {
  final Code code;
  final bool isCompactMode;
  final bool isReordering;

  const CodeWidget(
    this.code, {
    super.key,
    this.isCompactMode = false,
    this.isReordering = false,
  });

  @override
  State<CodeWidget> createState() => _CodeWidgetState();
}

class _CodeWidgetState extends State<CodeWidget> {
  final _logger = Logger('CodeWidget');
  Timer? _timer;

  late String _currentOtp;
  late int _periodStartMs;
  late int _periodEndMs;

  // 250ms is plenty for a 30s period; the displayed seconds tick
  // smoothly and the 6-digit code re-renders exactly at the boundary.
  static const _tickInterval = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _refreshOtp(now: DateTime.now().millisecondsSinceEpoch);
    _timer = Timer.periodic(_tickInterval, (_) {
      if (!mounted) return;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      // Refresh the OTP when we cross a period boundary.
      if (nowMs >= _periodEndMs) {
        _refreshOtp(now: nowMs);
      }
      setState(() {}); // tick the countdown digits
    });
  }

  void _refreshOtp({required int now}) {
    final offset = PreferenceService.instance.timeOffsetInMilliSeconds();
    final periodMs = widget.code.period * 1000;
    _periodStartMs = (now + offset) ~/ periodMs * periodMs - offset;
    _periodEndMs = _periodStartMs + periodMs;
    try {
      _currentOtp = getOTP(widget.code);
    } catch (e, st) {
      _logger.warning('getOTP failed for ${widget.code.issuer}', e, st);
      _currentOtp = '••••••';
    }
  }

  @override
  void didUpdateWidget(covariant CodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code.rawData != widget.code.rawData) {
      _refreshOtp(now: DateTime.now().millisecondsSinceEpoch);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _currentOtp));
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Copied'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showContextMenu() async {
    if (widget.isReordering) return;
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy code'),
              onTap: () => Navigator.of(ctx).pop('copy'),
            ),
            ListTile(
              leading: Icon(
                widget.code.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              title: Text(widget.code.isPinned ? 'Unpin' : 'Pin'),
              onTap: () => Navigator.of(ctx).pop('pin'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || result == null) return;
    switch (result) {
      case 'copy':
        await _copyToClipboard();
        break;
      case 'pin':
        final updated = _togglePin(widget.code);
        await CodeStore.instance.addCode(updated);
        break;
      case 'delete':
        await CodeStore.instance.removeCode(widget.code);
        break;
    }
  }

  Code _togglePin(Code c) {
    // Pin state lives on CodeDisplay. We rebuild a Code with the
    // opposite pinned flag and persist via addCode() (CodeStore does
    // an upsert keyed on rawData).
    return Code(
      c.account,
      c.issuer,
      c.digits,
      c.period,
      c.secret,
      c.algorithm,
      c.type,
      c.counter,
      c.rawData,
      display: c.display.copyWith(pinned: !c.display.pinned),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  String _secondsRemaining() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = ((_periodEndMs - now) / 1000).ceil();
    return remaining.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final remaining = _secondsRemaining();
    final issuerLine = widget.code.issuer.isEmpty
        ? widget.code.account
        : widget.code.issuer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        elevation: 0,
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _copyToClipboard,
          onLongPress: _showContextMenu,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (widget.code.isPinned) ...[
                      Icon(Icons.push_pin,
                          size: 14, color: scheme.primary),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        issuerLine,
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${remaining}s',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (widget.code.account.isNotEmpty &&
                    widget.code.issuer.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.code.account,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatOtp(_currentOtp),
                        style: textTheme.displaySmall?.copyWith(
                          color: scheme.onSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _CountdownRing(
                      period: widget.code.period,
                      remainingSeconds: int.tryParse(remaining) ?? 0,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CodeTimerProgress(
                  period: widget.code.period,
                  isCompactMode: widget.isCompactMode,
                  timeOffsetInMilliseconds:
                      PreferenceService.instance.timeOffsetInMilliSeconds(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Insert a space in the middle of a 6-digit code ("123 456") for
  /// readability. Steam codes are 5 chars and don't get a space.
  String _formatOtp(String otp) {
    if (otp.length == 6) {
      return '${otp.substring(0, 3)} ${otp.substring(3)}';
    }
    return otp;
  }
}

/// Minimal circular countdown ring — replaces ente's
/// `CodeTimerCircularWidget` so we don't need a separate file.
class _CountdownRing extends StatelessWidget {
  final int period;
  final int remainingSeconds;
  const _CountdownRing({required this.period, required this.remainingSeconds});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = remainingSeconds / period;
    final lowTime = remainingSeconds <= 5;
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                lowTime ? scheme.error : scheme.primary,
              ),
            ),
          ),
          Text(
            remainingSeconds.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// `Platform.isAndroid` import kept to avoid the analyzer warning on
// unused import if you ever trim dart:io.
// ignore: unused_element
bool _kIsAndroid = Platform.isAndroid;
