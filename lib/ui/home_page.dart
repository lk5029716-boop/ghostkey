import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../events/codes_updated_event.dart';
import '../models/code.dart';
import '../services/preference_service.dart';
import '../store/code_store.dart';
import 'code_widget.dart';
import 'code_error_widget.dart';

/// Vault home screen. Loads TOTP codes from [CodeStore], filters /
/// sorts them per [PreferenceService] settings, and renders the list
/// as [CodeWidget]s.
///
/// Ported from ente's `home_page.dart` (2,428 lines) — kept the
/// state-machine + filter + sort logic, dropped the online/offline
/// sync banners, multi-select, drag-to-reorder, tags, custom icons,
/// coach marks, and lock-screen integration that GhostKey doesn't
/// need in its local-first demo build.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _logger = Logger('HomePage');
  StreamSubscription<CodesUpdatedEvent>? _codesSub;

  bool _hasLoaded = false;
  String _searchText = '';
  bool _showSearchBar = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  List<Code> _allCodes = [];
  List<Code> _filteredCodes = [];

  @override
  void initState() {
    super.initState();
    _loadCodes();
    // Refresh on store changes (add, update, delete).
    _codesSub = CodeStore.instance.onCodesUpdated().listen((_) {
      if (mounted) _loadCodes();
    });
  }

  Future<void> _loadCodes() async {
    try {
      final codes = await CodeStore.instance.getAllCodes();
      if (!mounted) return;
      setState(() {
        _allCodes = codes;
        _hasLoaded = true;
        _applyFilterAndSort();
      });
    } catch (e, st) {
      _logger.severe('Failed to load codes', e, st);
      if (!mounted) return;
      setState(() => _hasLoaded = true);
    }
  }

  void _applyFilterAndSort() {
    // 1. Filter by search text.
    final q = _searchText.trim().toLowerCase();
    final filtered = q.isEmpty
        ? List<Code>.from(_allCodes)
        : _allCodes
            .where((c) =>
                c.issuer.toLowerCase().contains(q) ||
                c.account.toLowerCase().contains(q))
            .toList();

    // 2. Drop trashed.
    filtered.removeWhere((c) => c.isTrashed);

    // 3. Sort per PreferenceService (pinned first, then by key).
    final sortKey = PreferenceService.instance.codeSortKey();
    _sortCodes(filtered, sortKey);

    setState(() => _filteredCodes = filtered);
  }

  void _sortCodes(List<Code> codes, CodeSortKey sortKey) {
    codes.sort((a, b) {
      // Pinned always first.
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      switch (sortKey) {
        case CodeSortKey.issuerName:
          final byIssuer = a.issuer.toLowerCase().compareTo(
                b.issuer.toLowerCase(),
              );
          if (byIssuer != 0) return byIssuer;
          return a.account.toLowerCase().compareTo(b.account.toLowerCase());
        case CodeSortKey.accountName:
          return a.account.toLowerCase().compareTo(b.account.toLowerCase());
        case CodeSortKey.recentlyUsed:
          return b.display.lastUsedAt.compareTo(a.display.lastUsedAt);
        case CodeSortKey.mostFrequentlyUsed:
          return b.display.tapCount.compareTo(a.display.tapCount);
        case CodeSortKey.manual:
          return a.display.position.compareTo(b.display.position);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Search bar
  // ---------------------------------------------------------------------------

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (_showSearchBar) {
        _searchFocus.requestFocus();
      } else {
        _searchController.clear();
        _searchText = '';
        _applyFilterAndSort();
      }
    });
  }

  void _onSearchChanged(String value) {
    setState(() => _searchText = value);
    _applyFilterAndSort();
  }

  // ---------------------------------------------------------------------------
  // Sort menu
  // ---------------------------------------------------------------------------

  Future<void> _showSortMenu() async {
    final current = PreferenceService.instance.codeSortKey();
    final picked = await showModalBottomSheet<CodeSortKey>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final key in CodeSortKey.values)
              ListTile(
                leading: Icon(
                  key == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(_sortLabel(key)),
                onTap: () => Navigator.of(ctx).pop(key),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await PreferenceService.instance.setCodeSortKey(picked);
    _applyFilterAndSort();
  }

  String _sortLabel(CodeSortKey key) {
    switch (key) {
      case CodeSortKey.issuerName:
        return 'Sort by issuer';
      case CodeSortKey.accountName:
        return 'Sort by account';
      case CodeSortKey.recentlyUsed:
        return 'Recently used';
      case CodeSortKey.mostFrequentlyUsed:
        return 'Most frequently used';
      case CodeSortKey.manual:
        return 'Manual order';
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        title: _showSearchBar
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search codes',
                  border: InputBorder.none,
                ),
                style: textTheme.bodyLarge,
              )
            : Text(
                'Vault',
                style: textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortMenu,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    // Split out error codes for the dedicated banner.
    final errors = _filteredCodes.where((c) => c.hasError).toList();
    final goodCodes = _filteredCodes.where((c) => !c.hasError).toList();

    if (goodCodes.isEmpty && errors.isEmpty) {
      return _EmptyState(
        searchText: _searchText,
        onAdd: () => Navigator.of(context).pushNamed('/scanner'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCodes,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: errors.length + goodCodes.length,
        itemBuilder: (context, index) {
          if (index < errors.length) {
            return CodeErrorWidget(
              errors: errors,
              key: const ValueKey('error-banner'),
            );
          }
          final code = goodCodes[index - errors.length];
          return CodeWidget(code, key: ValueKey(code.rawData));
        },
      ),
    );
  }

  @override
  void dispose() {
    _codesSub?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
}

class _EmptyState extends StatelessWidget {
  final String searchText;
  final VoidCallback onAdd;
  const _EmptyState({required this.searchText, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final searching = searchText.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off : Icons.shield_outlined,
              size: 56,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              searching ? 'No codes match' : 'Your vault is empty',
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searching
                  ? 'Try a different search term.'
                  : 'Add your first 2FA code by scanning a QR or entering the secret key.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (!searching) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Add a code'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
