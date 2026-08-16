import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:flutter/material.dart';

class DynamicStyleSelector<T> extends StatefulWidget {
  final List<T> values;
  final T selectedValue;
  final String Function(T) getTitle;
  final String Function(T) getDescription;
  final Widget Function(T) buildPreview;
  final void Function(T) onValueChanged;

  const DynamicStyleSelector({
    super.key,
    required this.values,
    required this.selectedValue,
    required this.getTitle,
    required this.getDescription,
    required this.buildPreview,
    required this.onValueChanged,
  });

  @override
  State<DynamicStyleSelector<T>> createState() => _DynamicStyleSelectorState<T>();
}

class _DynamicStyleSelectorState<T> extends State<DynamicStyleSelector<T>> {
  late T _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.selectedValue;
  }

  @override
  void didUpdateWidget(covariant DynamicStyleSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValue != widget.selectedValue) {
      _currentValue = widget.selectedValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 420,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.08),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'LIVE PREVIEW',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey(_currentValue),
                    child: Center(
                      child: widget.buildPreview(_currentValue),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnymeXTileBuilder<T>(
            items: widget.values,
            selectedItem: _currentValue,
            getTitle: widget.getTitle,
            getSubtitle: widget.getDescription,
            onItemPressed: (value) {
              setState(() {
                _currentValue = value;
              });
              widget.onValueChanged(value);
            },
            isRadio: true,
            isSelection: true,
          ),
        ],
      ),
    );
  }
}
