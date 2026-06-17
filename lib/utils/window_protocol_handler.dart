/// Windows-only deep-link registration. GhostKey is mobile-first, so
/// the real Windows implementation is omitted. Callers on Android/iOS
/// get no-op stubs.
class WindowsProtocolHandler {
  void register(String scheme, {String? executable, List<String>? arguments}) {
    // No-op on mobile. Desktop builds can wire `package:win32` later.
  }

  void unregister(String scheme) {
    // No-op on mobile.
  }
}
