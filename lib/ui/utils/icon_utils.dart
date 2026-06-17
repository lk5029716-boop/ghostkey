import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Maps authenticator issuer names to brand SVG icons.
///
/// Loads `assets/custom-icons/custom-icons.json` once at startup.
/// Each entry has: title (canonical name), slug (SVG filename stem).
class BrandIcon {
  final String title;
  final String slug;
  const BrandIcon({required this.title, required this.slug});
}

class BrandIconRegistry {
  BrandIconRegistry._();
  static final BrandIconRegistry instance = BrandIconRegistry._();

  // normalized name -> icon
  final Map<String, BrandIcon> _byName = {};
  bool _loaded = false;
  bool _loading = false;

  Future<void> init({AssetBundle? bundle}) async {
    if (_loaded || _loading) return;
    _loading = true;
    try {
      final b = bundle ?? rootBundle;
      final raw = await b.loadString('assets/custom-icons/custom-icons.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      for (final entry in (data['icons'] as List? ?? [])) {
        final title = (entry['title'] as String?)?.trim();
        if (title == null || title.isEmpty) continue;
        final slug = (entry['slug'] as String?)?.trim() ?? _toSlug(title);
        final icon = BrandIcon(title: title, slug: slug);
        // Index by multiple normalized forms
        _byName[_normalize(title)] = icon;
        _byName[title.toLowerCase()] = icon;
        _byName[slug] = icon;
        // Also index without spaces/special chars
        _byName[_normalizeSlug(title)] = icon;
      }
      _loaded = true;
    } catch (e) {
      if (kDebugMode) debugPrint('BrandIconRegistry init failed: $e');
    } finally {
      _loading = false;
    }
  }

  /// Ensure init has been called. Safe to call multiple times.
  Future<void> ensureInit() async {
    if (!_loaded) await init();
  }

  /// Look up a brand icon for an issuer. Returns the SVG asset path
  /// or null if no match. Must call [init] first.
  String? assetPathForIssuer(String? issuer) {
    if (issuer == null || issuer.isEmpty) return null;
    if (!_loaded) return null;

    final norm = _normalize(issuer);
    // Direct match
    BrandIcon? icon = _byName[norm];
    // Try lowercase
    icon ??= _byName[issuer.toLowerCase()];
    // Try without special chars
    icon ??= _byName[_normalizeSlug(issuer)];
    // Strip common suffixes and try again
    if (icon == null) {
      for (final sep in [':', '-', '(', '/', '.']) {
        final idx = norm.indexOf(sep);
        if (idx > 0) {
          icon = _byName[norm.substring(0, idx).trim()];
          if (icon != null) break;
        }
      }
    }
    // Try first word only
    if (icon == null) {
      final firstWord = norm.split(' ').first;
      if (firstWord.length > 2) {
        icon = _byName[firstWord];
      }
    }
    if (icon == null) return null;
    return 'assets/custom-icons/icons/${icon.slug}.svg';
  }

  /// Normalize an issuer string for lookup.
  String _normalize(String s) {
    var out = s.toLowerCase().trim();
    for (final suffix in [
      ' inc', ' corp', ' ltd', ' llc', ' co', ' gmbh', ' ag',
      ' com', ' org', ' net',
    ]) {
      if (out.endsWith(suffix)) {
        out = out.substring(0, out.length - suffix.length).trim();
      }
    }
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _normalizeSlug(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _toSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
