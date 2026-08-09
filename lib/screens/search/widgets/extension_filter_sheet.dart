import 'package:anymex/utils/function.dart';
import 'package:anymex_extension_runtime_bridge/Services/Mangayomi/Eval/dart/model/filter.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:flutter_iconly/flutter_iconly.dart';


class ExtensionFilterSheet extends StatefulWidget {
  final List<dynamic> filterList;
  final List<dynamic> activeFilters;
  final void Function(List<dynamic> applied) onApply;
  final Future<List<dynamic>> Function() onReset;

  const ExtensionFilterSheet({super.key, 
    required this.filterList,
    required this.activeFilters,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<ExtensionFilterSheet> createState() => ExtensionFilterSheetState();
}

class ExtensionFilterSheetState extends State<ExtensionFilterSheet> {
  late List<dynamic> _filters;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();

    _filters = _deepCloneFilters(widget.filterList, widget.activeFilters);
  }

  List<dynamic> _deepCloneFilters(
    List<dynamic> source,
    List<dynamic> active,
  ) {
    if (active.isEmpty) return List.from(source);

    final activeMap = <String, dynamic>{};
    for (final f in active) {
      final key = _filterKey(f);
      if (key != null) activeMap[key] = f;
    }
    return source.map((f) {
      final key = _filterKey(f);
      if (key != null && activeMap.containsKey(key)) return activeMap[key];
      return f;
    }).toList();
  }

  String? _filterKey(dynamic f) {
    if (f is CheckBoxFilter) return 'cb|${f.name}|${f.value}';
    if (f is SelectFilter) return 'sel|${f.name}';
    if (f is TriStateFilter) return 'tri|${f.name}|${f.value}';
    if (f is SortFilter) return 'sort|${f.name}';
    if (f is TextFilter) return 'txt|${f.name}';
    if (f is GroupFilter) return 'grp|${f.name}';
    return null;
  }

  void _apply() {
    final applied = _filters.where((f) {
      if (f is CheckBoxFilter) return f.state == true;
      if (f is TriStateFilter) return f.state != 0;
      if (f is SelectFilter) return f.state != 0;
      if (f is SortFilter) return true;
      if (f is TextFilter) return f.state.isNotEmpty;
      if (f is GroupFilter) {
        return f.state.any((inner) {
          if (inner is CheckBoxFilter) return inner.state == true;
          if (inner is TriStateFilter) return inner.state != 0;
          if (inner is GroupFilter) return true;
          return false;
        });
      }
      return false;
    }).toList();
    widget.onApply(applied.isEmpty ? [] : _filters);
    Navigator.pop(context);
  }

  void _reset() async {
    if (_isResetting) return;
    setState(() {
      _isResetting = true;
    });
    try {
      final freshFilters = await widget.onReset();
      if (mounted) {
        setState(() {
          _filters = freshFilters;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _filters = List.from(widget.filterList);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const AnymexText.bold(text: 'Filters', size: 18),
                const Spacer(),
                _isResetting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      )
                    : TextButton(
                        onPressed: _reset,
                        child: AnymexText.semiBold(
                          text: 'Reset',
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const AnymexText.semiBold(
                    text: 'Apply',
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 0.8,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnymexText.regular(
                    text: "Note: If the extension supports reset to load filters and it doesn't work, try searching something first or open WebView. If that doesn't work, then click the 'Reset' button to load filters.",
                    size: 11.5,
                    maxLines: 999,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filters.length,
              itemBuilder: (ctx, i) => _buildFilter(i),
            ),
          ),
          40.height(),
        ],
      ),
    );
  }

  Widget _buildFilter(int index) {
    final f = _filters[index];
    if (f is HeaderFilter) return _buildHeader(f);
    if (f is SeparatorFilter) return const SizedBox(height: 8);
    if (f is CheckBoxFilter) return _buildCheckbox(index, f);
    if (f is TriStateFilter) return _buildTriState(index, f);
    if (f is SelectFilter) return _buildSelect(index, f);
    if (f is SortFilter) return _buildSort(index, f);
    if (f is TextFilter) return _buildText(index, f);
    if (f is GroupFilter) {
      return _GroupFilterWidget(
        filterIdx: index,
        group: f,
        allFilters: _filters,
        parentSetState: setState,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildHeader(HeaderFilter f) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: AnymexText.bold(
        text: f.name,
        size: 15,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildCheckbox(int i, CheckBoxFilter f) {
    return CheckboxListTile(
      dense: true,
      title: AnymexText(text: f.name, size: 14),
      value: f.state,
      onChanged: (v) {
        setState(() {
          _filters[i] = CheckBoxFilter(
            f.type,
            f.name,
            f.value,
            f.typeName,
            state: v ?? false,
          );
        });
      },
    );
  }

  Widget _buildTriState(int i, TriStateFilter f) {
    final labels = ['Off', 'Include', 'Exclude'];
    final theme = Theme.of(context);
    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (f.state) {
      case 1:
        bgColor = theme.colorScheme.primary.withOpacity(0.15);
        borderColor = theme.colorScheme.primary.withOpacity(0.4);
        textColor = theme.colorScheme.primary;
        break;
      case 2:
        bgColor = theme.colorScheme.error.withOpacity(0.15);
        borderColor = theme.colorScheme.error.withOpacity(0.4);
        textColor = theme.colorScheme.error;
        break;
      case 0:
      default:
        bgColor = theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);
        borderColor = theme.colorScheme.onSurface.withOpacity(0.1);
        textColor = theme.colorScheme.onSurface;
        break;
    }

    return ListTile(
      dense: true,
      title: AnymexText(text: f.name, size: 14),
      trailing: GestureDetector(
        onTap: () {
          setState(() {
            final next = (f.state + 1) % 3;
            _filters[i] = TriStateFilter(
              f.type,
              f.name,
              f.value,
              f.typeName,
              state: next,
            );
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: AnymexText.semiBold(
            text: labels[f.state],
            size: 12,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSelect(int i, SelectFilter f) {
    return AnymexExpansionTile(
      title: f.name,
      content: Wrap(
        alignment: WrapAlignment.start,
        spacing: 8,
        runSpacing: 6,
        children: [
          for (int j = 0; j < f.values.length; j++)
            if (f.values[j] is SelectFilterOption)
              _buildChipOption(
                label: (f.values[j] as SelectFilterOption).name,
                isSelected: f.state == j,
                onTap: () {
                  setState(() {
                    _filters[i] = SelectFilter(
                      f.type,
                      f.name,
                      j,
                      f.values,
                      f.typeName,
                    );
                  });
                },
              ),
        ],
      ),
    );
  }

  Widget _buildSort(int i, SortFilter f) {
    final state = f.state;
    return AnymexExpansionTile(
      title: f.name,
      content: Wrap(
        alignment: WrapAlignment.start,
        spacing: 8,
        runSpacing: 6,
        children: [
          for (int j = 0; j < f.values.length; j++) ...[
            if (f.values[j] is SelectFilterOption) ...[
              GestureDetector(
                onTap: () {
                  setState(() {
                    final newAsc = state.index == j ? !state.ascending : true;
                    _filters[i] = SortFilter(
                      f.type,
                      f.name,
                      SortState(j, newAsc, state.typeName),
                      f.values,
                      f.typeName,
                    );
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: state.index == j
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.15)
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state.index == j
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.4)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnymexText(
                        text: (f.values[j] as SelectFilterOption).name,
                        size: 12,
                      ),
                      if (state.index == j) ...[
                        const SizedBox(width: 4),
                        Icon(
                          state.ascending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildText(int i, TextFilter f) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: TextField(
        controller: TextEditingController(text: f.state)
          ..selection = TextSelection.collapsed(offset: f.state.length),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: f.name,
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 13,
          ),
          isDense: true,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
          ),
        ),
        onChanged: (v) {
          _filters[i] = TextFilter(f.type, f.name, f.typeName, state: v);
        },
      ),
    );
  }

  Widget _buildChipOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.15)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.4)
                : theme.colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
        child: AnymexText(
          text: label,
          size: 12,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _GroupFilterWidget extends StatefulWidget {
  final int filterIdx;
  final GroupFilter group;
  final List<dynamic> allFilters;
  final void Function(VoidCallback fn) parentSetState;

  const _GroupFilterWidget({
    required this.filterIdx,
    required this.group,
    required this.allFilters,
    required this.parentSetState,
  });

  @override
  State<_GroupFilterWidget> createState() => _GroupFilterWidgetState();
}

class _GroupFilterWidgetState extends State<_GroupFilterWidget> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = widget.group;

    final flatItems = group.state.where((item) {
      if (item is! CheckBoxFilter && item is! TriStateFilter) return false;
      if (_searchQuery.isEmpty) return true;
      final name =
          (item is CheckBoxFilter ? item.name : (item as TriStateFilter).name)
              .toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    final subGroups = group.state.whereType<GroupFilter>().where((sg) {
      if (_searchQuery.isEmpty) return true;
      if (sg.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return true;
      }
      return sg.state.any((item) {
        final name = (item is CheckBoxFilter
                ? item.name
                : (item is TriStateFilter ? item.name : ''))
            .toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      });
    }).toList();

    final hasContent = flatItems.isNotEmpty || subGroups.isNotEmpty;

    return AnymexExpansionTile(
      title: group.name,
      initialExpanded: false,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search ${group.name.toLowerCase()}...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.45),
                  ),
                  prefixIcon: Icon(
                    IconlyLight.search,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.cancel_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.35),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.colorScheme.onSurface.withOpacity(0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                    ),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (!hasContent)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: AnymexText.regular(
                text: 'No matches found',
                size: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          if (flatItems.isNotEmpty) ...[
            if (flatItems.length > 20)
              SizedBox(
                height: 250,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 130,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: flatItems.length,
                  itemBuilder: (context, idx) =>
                      _buildFlatItemChip(flatItems[idx]),
                ),
              )
            else
              Wrap(
                alignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final item in flatItems) _buildFlatItemChip(item),
                ],
              ),
          ],
          if (subGroups.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final subGroup in subGroups) ...[
              _buildSubGroup(subGroup),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildFlatItemChip(dynamic item) {
    if (item is CheckBoxFilter) {
      return _buildGroupCheckboxChip(item);
    } else if (item is TriStateFilter) {
      return _buildGroupTriStateChip(item);
    }
    return const SizedBox.shrink();
  }

  Widget _buildSubGroup(GroupFilter subGroup) {
    final subItems = subGroup.state.where((item) {
      if (_searchQuery.isEmpty) return true;
      final name = (item is CheckBoxFilter
              ? item.name
              : (item is TriStateFilter ? item.name : ''))
          .toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    if (subItems.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 6.0),
      child: AnymexExpansionTile(
        title: subGroup.name,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subItems.length > 20)
              SizedBox(
                height: 250,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 130,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: subItems.length,
                  itemBuilder: (context, idx) {
                    final item = subItems[idx];
                    if (item is CheckBoxFilter) {
                      return _buildNestedGroupCheckboxChip(subGroup, item);
                    } else if (item is TriStateFilter) {
                      return _buildNestedGroupTriStateChip(subGroup, item);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              )
            else
              Wrap(
                alignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final item in subItems) ...[
                    if (item is CheckBoxFilter)
                      _buildNestedGroupCheckboxChip(subGroup, item)
                    else if (item is TriStateFilter)
                      _buildNestedGroupTriStateChip(subGroup, item),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCheckboxChip(CheckBoxFilter cb) {
    return _buildChipOption(
      label: cb.name,
      isSelected: cb.state,
      onTap: () {
        widget.parentSetState(() {
          cb.state = !cb.state;
        });
        setState(() {});
      },
    );
  }

  Widget _buildGroupTriStateChip(TriStateFilter tri) {
    final theme = Theme.of(context);
    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (tri.state) {
      case 1:
        bgColor = theme.colorScheme.primary.withOpacity(0.15);
        borderColor = theme.colorScheme.primary.withOpacity(0.4);
        textColor = theme.colorScheme.primary;
        break;
      case 2:
        bgColor = theme.colorScheme.error.withOpacity(0.15);
        borderColor = theme.colorScheme.error.withOpacity(0.4);
        textColor = theme.colorScheme.error;
        break;
      case 0:
      default:
        bgColor = theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);
        borderColor = theme.colorScheme.onSurface.withOpacity(0.1);
        textColor = theme.colorScheme.onSurface;
        break;
    }

    return GestureDetector(
      onTap: () {
        widget.parentSetState(() {
          tri.state = (tri.state + 1) % 3;
        });
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: AnymexText(
          text: tri.name,
          size: 12,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildNestedGroupCheckboxChip(
    GroupFilter subGroup,
    CheckBoxFilter cb,
  ) {
    return _buildChipOption(
      label: cb.name,
      isSelected: cb.state,
      onTap: () {
        widget.parentSetState(() {
          cb.state = !cb.state;
        });
        setState(() {});
      },
    );
  }

  Widget _buildNestedGroupTriStateChip(
    GroupFilter subGroup,
    TriStateFilter tri,
  ) {
    return _buildGroupTriStateChip(tri);
  }

  Widget _buildChipOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.15)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.4)
                : theme.colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
        child: AnymexText(
          text: label,
          size: 12,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
