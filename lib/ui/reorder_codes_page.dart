import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/code.dart';
import '../../store/code_store.dart';
import 'code_widget.dart';

/// Drag-to-reorder page.
///
/// Mirrors ente's `ReorderCodesPage` but uses M3 styling and our
/// local-only [CodeStore.saveUpdatedIndexes].
class ReorderCodesPage extends StatefulWidget {
  const ReorderCodesPage({super.key, required this.codes});
  final List<Code> codes;

  @override
  State<ReorderCodesPage> createState() => _ReorderCodesPageState();
}

class _ReorderCodesPageState extends State<ReorderCodesPage> {
  bool _hasChanged = false;
  bool _saving = false;

  late List<Code> _codes = List<Code>.from(widget.codes);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        title: const Text(
          'Reorder codes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _hasChanged && !_saving ? _save : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: _hasChanged
                    ? kPrimary
                    : kOnSurfaceVariant.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ReorderableListView(
          buildDefaultDragHandles: false,
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(animation.value);
                final scale = 1.0 + (0.04 * t);
                return Transform.scale(
                  scale: scale,
                  child: Material(
                    elevation: 6,
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  ),
                );
              },
            );
          },
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) newIndex -= 1;
              final code = _codes.removeAt(oldIndex);
              _codes.insert(newIndex, code);
              _hasChanged = true;
            });
          },
          children: [
            for (final code in _codes)
              Padding(
                key: ValueKey('${code.hashCode}_${code.generatedID}'),
                padding: EdgeInsets.zero,
                child: ReorderableDragStartListener(
                  index: _codes.indexOf(code),
                  child: CodeWidget(
                    key: ValueKey(code.generatedID),
                    code,
                    isReordering: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await CodeStore.instance.saveUpdatedIndexes(_codes);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
      setState(() => _saving = false);
    }
  }
}
