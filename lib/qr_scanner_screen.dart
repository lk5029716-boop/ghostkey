import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart' as qr_decoder;
import '../enter_key_manually_screen.dart';
import '../models/code.dart';
import '../store/code_store.dart';

// ═══════════════════════════════════════════════════════════════
// QR SCANNER — Real camera scanner using mobile_scanner package.
// Detects otpauth:// URLs, parses them, and adds the code to the
// store. Supports flash toggle, gallery QR import, and manual entry.
// ═══════════════════════════════════════════════════════════════
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  bool _flashOn = false;
  bool _isProcessing = false;
  String? _lastScannedData;
  late final MobileScannerController _scannerController;
  bool _hasCameraError = false;
  String? _cameraErrorMessage;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    HapticFeedback.lightImpact();
    setState(() => _flashOn = !_flashOn);
    try {
      await _scannerController.toggleTorch();
    } catch (e) {
      // Some devices may not support torch.
      if (mounted) {
        setState(() => _flashOn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flash is not available on this device'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open gallery: ${_truncate(e.toString())}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    if (picked == null) {
      // User cancelled the picker.
      return;
    }
    await _decodeFromFileAndProcess(picked);
  }

  /// Read the picked image, try to decode it with the platform scanner
  /// (fast, uses ML Kit on Android), and fall back to a pure-Dart QR
  /// decoder for any platform that can't analyze the file directly.
  Future<void> _decodeFromFileAndProcess(XFile file) async {
    String? raw;
    String? lastError;
    // 1) Try the platform's analyzeImage first (uses Google ML Kit on
    //    Android; Vision on iOS). This is the fastest path and works
    //    for the majority of gallery images.
    try {
      final result = await _scannerController.analyzeImage(file.path);
      final barcodes = result?.barcodes;
      if (barcodes != null && barcodes.isNotEmpty) {
        raw = barcodes.first.rawValue;
      }
    } catch (e) {
      lastError = e.toString();
    }
    // 2) Fallback: pure-Dart decoder. We always try this too because
    //    some platforms return an empty BarcodeCapture even when a QR
    //    is present. Reading bytes and decoding with qr_dart_decoder
    //    works regardless of platform.
    if (raw == null || raw.isEmpty) {
      try {
        final bytes = await file.readAsBytes();
        final decoded = await _decodeBytes(bytes);
        if (decoded != null && decoded.isNotEmpty) {
          raw = decoded;
        }
      } catch (e) {
        lastError ??= e.toString();
      }
    }
    if (!mounted) return;
    if (raw == null || raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lastError != null
                ? 'No QR code found: ${_truncate(lastError)}'
                : 'No QR code found in the selected image',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    await _processScannedData(raw);
  }

  /// Decode a QR code from image bytes using the pure-Dart decoder.
  /// Returns the payload string or null on failure.
  Future<String?> _decodeBytes(Uint8List bytes) async {
    try {
      // qr_code_dart_decoder works directly from bytes — no need to
      // write a temp file. The library wraps ZXing and supports
      // multiple barcode formats; we only need QR.
      final decoder = qr_decoder.QrCodeDartDecoder(
        formats: const [qr_decoder.BarcodeFormat.qrCode],
      );
      final result = await decoder.decodeFile(bytes);
      if (result == null || result.text == null) return null;
      return result.text;
    } catch (e) {
      if (kDebugMode) debugPrint('qr_code_dart_decoder failed: $e');
      return null;
    }
  }

  String _truncate(String s) {
    return s.length > 80 ? '${s.substring(0, 80)}…' : s;
  }

  void _goManual() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EnterKeyManuallyScreen()),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    if (raw == _lastScannedData) return; // de-dupe
    _lastScannedData = raw;
    await _processScannedData(raw);
  }

  Future<void> _processScannedData(String raw) async {
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();
    try {
      // Pause the camera so the user sees the success state
      await _scannerController.stop();
      if (!mounted) return;

      if (!raw.startsWith('otpauth://')) {
        await _showResult(
          success: false,
          title: 'Invalid QR code',
          message:
              'This QR code is not a 2FA authenticator code. Expected an otpauth:// URL, got: ${raw.length > 60 ? '${raw.substring(0, 60)}…' : raw}',
        );
        await _resumeScanning();
        return;
      }

      final code = Code.fromOTPAuthUrl(raw);
      await CodeStore.instance.addCode(code);
      if (!mounted) return;
      await _showResult(
        success: true,
        title: 'Code added!',
        message:
            '${code.issuer.isNotEmpty ? code.issuer : code.account} is now in your vault.',
        onClose: () {
          if (mounted) Navigator.of(context).pop();
        },
      );
    } catch (e) {
      if (!mounted) return;
      await _showResult(
        success: false,
        title: 'Could not read code',
        message: e.toString(),
      );
      await _resumeScanning();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _resumeScanning() async {
    _lastScannedData = null;
    try {
      await _scannerController.start();
    } catch (_) {
      // No-op: scanner is either already running or unavailable.
    }
  }

  Future<void> _showResult({
    required bool success,
    required String title,
    required String message,
    VoidCallback? onClose,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: Icon(
          success ? Icons.check_circle : Icons.error_outline,
          color: success ? const Color(0xFF0D631B) : const Color(0xFFBA1A1A),
          size: 56,
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (onClose != null) onClose();
            },
            child: Text(success ? 'Done' : 'OK'),
          ),
          if (!success)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _goManual();
              },
              child: const Text('Enter manually'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // GhostKey theme colors
    const primary = Color(0xFF0D631B);
    const surface = Color(0xFFF8F9FA);
    const onSurface = Color(0xFF191C1D);
    const onSurfaceVariant = Color(0xFF40493D);
    const surfaceContainerHighest = Color(0xFFE1E3E4);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Real camera preview, with graceful fallback if unavailable.
          Positioned.fill(
            child: _hasCameraError
                ? _CameraErrorFallback(message: _cameraErrorMessage ?? 'Camera unavailable')
                : MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                    errorBuilder: (context, error, child) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !_hasCameraError) {
                          setState(() {
                            _hasCameraError = true;
                            _cameraErrorMessage = error.errorDetails?.message;
                          });
                        }
                      });
                      return _CameraErrorFallback(
                        message: _cameraErrorMessage ??
                            error.errorDetails?.message ??
                            'Camera unavailable',
                      );
                    },
                  ),
          ),

          // Dark overlay with cutout for the scan area
          ClipPath(
            clipper: _ScannerOverlayClipper(),
            child: Container(
              color: Colors.black.withOpacity(0.55),
            ),
          ),

          // Scanner frame corners + animated scanning line
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  _cornerBracket(Alignment.topLeft, primary),
                  _cornerBracket(Alignment.topRight, primary),
                  _cornerBracket(Alignment.bottomLeft, primary),
                  _cornerBracket(Alignment.bottomRight, primary),
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _scanAnimation.value * 250 + 5,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: primary,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Scan QR Code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // Instruction text
          Positioned(
            top: MediaQuery.of(context).size.height * 0.42,
            left: 0,
            right: 0,
            child: const Text(
              'Align QR code within the frame to scan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF88FF5F),
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Flash + Gallery row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _controlButton(
                          icon: _flashOn ? Icons.flash_off : Icons.flash_on,
                          label: 'Flash',
                          onTap: _toggleFlash,
                          active: _flashOn,
                        ),
                        const SizedBox(width: 32),
                        _controlButton(
                          icon: Icons.photo_library,
                          label: 'Gallery',
                          onTap: _pickFromGallery,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Enter manually
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _goManual,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: onSurface,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: surfaceContainerHighest),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Enter Code Manually',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cornerBracket(Alignment alignment, Color color) {
    return Positioned(
      top: alignment == Alignment.topLeft || alignment == Alignment.topRight ? 0 : null,
      bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? 0 : null,
      left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? 0 : null,
      right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? 0 : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: (alignment == Alignment.topLeft || alignment == Alignment.topRight)
                ? BorderSide(color: color, width: 4) : BorderSide.none,
            bottom: (alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight)
                ? BorderSide(color: color, width: 4) : BorderSide.none,
            left: (alignment == Alignment.topLeft || alignment == Alignment.bottomLeft)
                ? BorderSide(color: color, width: 4) : BorderSide.none,
            right: (alignment == Alignment.topRight || alignment == Alignment.bottomRight)
                ? BorderSide(color: color, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    const primary = Color(0xFF0D631B);
    const onSurface = Color(0xFF191C1D);
    const onSurfaceVariant = Color(0xFF40493D);
    const surfaceContainerHighest = Color(0xFFE1E3E4);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: active ? primary : surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: active ? Colors.white : onSurface, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? primary : onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fallback shown when the camera is unavailable (denied, no hardware, etc.)
class _CameraErrorFallback extends StatelessWidget {
  final String message;
  const _CameraErrorFallback({required this.message});

  @override
  Widget build(BuildContext context) {
    const onSurfaceVariant = Color(0xFF40493D);
    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, size: 56, color: onSurfaceVariant),
            const SizedBox(height: 16),
            const Text(
              'Camera not available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF191C1D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            const Text(
              'You can still add codes by entering them manually.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Custom clipper: dark overlay with transparent rounded rect cutout
// ═══════════════════════════════════════════════════════════════
class _ScannerOverlayClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final cutoutWidth = 260.0;
    final cutoutHeight = 260.0;
    final cutoutLeft = (size.width - cutoutWidth) / 2;
    final cutoutTop = (size.height - cutoutHeight) / 2 - 20;
    final cutoutRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutWidth, cutoutHeight),
      const Radius.circular(16),
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(cutoutRect)
      ..fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
