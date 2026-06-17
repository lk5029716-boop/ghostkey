import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logging/logging.dart';

import '../models/code.dart';
import '../services/preference_service.dart';
import '../store/code_store.dart';
import '../utils/totp_util.dart';
import 'code_timer_progress.dart';
import 'utils/icon_utils.dart';

/// The Vault's primary building block. Renders a single TOTP/HOTP code
/// with:
///
///   - issuer + account header (with optional brand SVG icon)
///   - live 6-digit code that refreshes on every TOTP period boundary
///   - circular progress ring showing seconds remaining in the period
///   - tap-to-copy with "Copied" toast
///   - long-press → context menu (Pin, Delete, Edit, Copy)
///   - multi-select support via [isSelectable] + [isSelected]
///   - drag handle for reorder mode via [isReordering]
class CodeWidget extends StatefulWidget {
  final Code code;
  final bool isCompactMode;
  final bool isReordering;
  final bool isSelectable;
  final bool isSelected;
  final VoidCallback? onSelectionChanged;

  const CodeWidget(
    this.code, {
    super.key,
    this.isCompactMode = false,
    this.isReordering = false,
    this.isSelectable = false,
    this.isSelected = false,
    this.onSelectionChanged,
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
    // Skip the timer when reordering to avoid setState during list rebuild
    if (!widget.isReordering) {
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
    return c.copyWith(
      display: c.display.copyWith(pinned: !c.display.pinned),
    );
  }

  /// Multi-select toggle: dispatches to the parent via [onSelectionChanged].
  void _toggleSelect() {
    widget.onSelectionChanged?.call();
  }

  /// Brand color from the icon registry. Returns null if the icon is
  /// rendered as a multi-color SVG (we just show the default tint).
  Color? _brandColorForIssuer(String issuer) {
    if (issuer.isEmpty) return null;
    // A few well-known brand colors so the chip feels recognizable
    // even when the SVG isn't loaded.
    final l = issuer.toLowerCase();
    if (l.contains('github')) return const Color(0xFF24292E);
    if (l.contains('google')) return const Color(0xFF4285F4);
    if (l.contains('aws') || l.contains('amazon')) {
      return const Color(0xFFFF9900);
    }
    if (l.contains('microsoft')) return const Color(0xFF00A4EF);
    if (l.contains('discord')) return const Color(0xFF5865F2);
    if (l.contains('cloudflare')) return const Color(0xFFF38020);
    return null;
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

    // Brand icon: lookup if user has a custom icon, else try the registry
    final customIconPath = widget.code.display.isCustomIcon
        ? 'assets/custom-icons/icons/${widget.code.display.iconID}.svg'
        : null;
    final registryPath = customIconPath ??
        BrandIconRegistry.instance.assetPathForIssuer(widget.code.issuer);
    final iconColor = widget.code.display.isCustomIcon
        ? null
        : _brandColorForIssuer(widget.code.issuer);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        elevation: 0,
        color: widget.isSelected
            ? scheme.primaryContainer.withOpacity(0.25)
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.isSelectable
              ? () => _toggleSelect()
              : (widget.isReordering ? null : _copyToClipboard),
          onLongPress: widget.isReordering || widget.isSelectable
              ? null
              : _showContextMenu,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (widget.isSelectable) ...[
                      Icon(
                        widget.isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 22,
                        color: widget.isSelected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                    ] else if (widget.isReordering) ...[
                      Icon(
                        Icons.drag_handle,
                        size: 22,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                    ] else if (registryPath != null) ...[
                      _BrandIconAvatar(
                        assetPath: registryPath,
                        background: iconColor,
                      ),
                      const SizedBox(width: 12),
                    ],
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

/// Brand SVG icon avatar — shown to the left of the issuer name when
/// GhostKey recognizes the service. Falls back to a colored circle with
/// the first letter if the SVG fails to load.
class _BrandIconAvatar extends StatelessWidget {
  final String assetPath;
  final Color? background;
  const _BrandIconAvatar({required this.assetPath, this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: background ?? const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: SvgPicture.asset(
        assetPath,
        width: 20,
        height: 20,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _fallbackAvatar(context),
      ),
    );
  }

  Widget _fallbackAvatar(BuildContext context) {
    final name = assetPath.split('/').last.split('.').first;
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: background != null
              ? Colors.white
              : const Color(0xFF40493D),
        ),
      ),
    );
  }
}
