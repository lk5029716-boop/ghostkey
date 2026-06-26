import "../store/vault_store.dart";
import "../vault_data.dart";
import "package:event_bus/event_bus.dart";

/// Event the Vault UI can listen to in order to switch its filter.
class FilterChangedEvent {
  final VaultCategory category;
  FilterChangedEvent(this.category);
}

/// Simple service that adds a placeholder item to the vault and
/// triggers a filter‑change event so the Vault tab shows only that type.
class QuickAddService {
  QuickAddService._();
  static final QuickAddService instance = QuickAddService._();

  final VaultStore _store = VaultStore.instance;
  final EventBus _bus = EventBus(); // separate bus for our custom events

  /// Add a placeholder item and request the Vault UI to filter to that category.
  Future<void> addAndShow(VaultCategory category) async {
    final placeholder = createPlaceholder(category);
    await _store.addItem(placeholder);
    _bus.fire(FilterChangedEvent(category));
  }

  EventBus get bus => _bus;
}
