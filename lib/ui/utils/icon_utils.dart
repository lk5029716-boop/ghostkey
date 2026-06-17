import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Maps authenticator issuer names to brand SVG icons.
///
/// Loads `assets/custom-icons/custom-icons.json` once at startup.
/// Each entry has: title (canonical name), slug (SVG filename stem),
/// altNames (other names that should resolve to this icon), hex (brand color).
class BrandIcon {
  final String title;
  final String slug;
  final int? hex;
  const BrandIcon({required this.title, required this.slug, this.hex});
}

class BrandIconRegistry {
  BrandIconRegistry._();
  static final BrandIconRegistry instance = BrandIconRegistry._();

  // canonical title -> icon
  final Map<String, BrandIcon> _byTitle = {};
  // normalized alt name -> icon (case-insensitive, lowercased, stripped)
  final Map<String, BrandIcon> _byAlias = {};
  bool _loaded = false;

  Future<void> init({AssetBundle? bundle}) async {
    if (_loaded) return;
    final b = bundle ?? rootBundle;
    final raw = await b.loadString('assets/custom-icons/custom-icons.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    for (final entry in (data['icons'] as List? ?? [])) {
      final title = (entry['title'] as String?)?.trim();
      if (title == null) continue;
      // Slug: prefer entry.slug, else title lowercased with spaces → underscores
      final slug = (entry['slug'] as String?) ??
          _toSlug(title);
      final hexStr = entry['hex'] as String?;
      final hex = (hexStr != null) ? int.tryParse('FF$hexStr', radix: 16) : null;
      final icon = BrandIcon(title: title, slug: slug, hex: hex);

      _byTitle[title.toLowerCase()] = icon;
      _byAlias[_normalize(title)] = icon;
      for (final alt in (entry['altNames'] as List? ?? [])) {
        if (alt is String) _byAlias[_normalize(alt)] = icon;
      }
    }
    _loaded = true;
  }

  /// Look up a brand icon for an issuer. Returns the SVG asset path
  /// (relative to the project root, for use with `flutter_svg`'s
  /// `SvgPicture.asset`) or null if no match.
  String? assetPathForIssuer(String? issuer) {
    if (issuer == null || issuer.isEmpty) return null;
    if (!_loaded) {
      // Lazy: synchronously warn and return null rather than block UI.
      if (kDebugMode) {
        debugPrint('BrandIconRegistry: init() not awaited; lookup may fail');
      }
      return null;
    }
    final norm = _normalize(issuer);
    // Try full name, then progressively shorter prefixes
    BrandIcon? icon = _byAlias[norm];
    icon ??= _byTitle[issuer.toLowerCase()];
    // Strip common suffixes and try again (e.g. "GitHub: Work" → "github")
    if (icon == null) {
      for (final sep in [':', '-', '(', '/']) {
        final idx = norm.indexOf(sep);
        if (idx > 0) {
          icon = _byAlias[norm.substring(0, idx).trim()];
          if (icon != null) break;
        }
      }
    }
    if (icon == null) return null;
    return 'assets/custom-icons/icons/${icon.slug}.svg';
  }

  /// Normalize an issuer string for lookup.
  /// Lowercase, strip whitespace, drop "inc"/"corp"/"ltd"/etc.
  String _normalize(String s) {
    var out = s.toLowerCase().trim();
    // Remove common corporate suffixes
    for (final suffix in [
      ' inc',
      ' corp',
      ' ltd',
      ' llc',
      ' co',
      ' gmbh',
      ' ag',
    ]) {
      if (out.endsWith(suffix)) out = out.substring(0, out.length - suffix.length);
    }
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _toSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
