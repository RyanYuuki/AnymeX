import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SourcePreferenceScreen extends StatefulWidget {
  final Source source;
  const SourcePreferenceScreen({super.key, required this.source});

  @override
  State<SourcePreferenceScreen> createState() => _SourcePreferenceScreenState();
}

class _SourcePreferenceScreenState extends State<SourcePreferenceScreen> {
  Rx<List<SourcePreference>?> preference = Rx(null);

  @override
  void initState() {
    super.initState();
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    preference.value = await widget.source.methods.getPreference();
  }

  Future<void> _savePreference(SourcePreference pref, dynamic value) async {
    await widget.source.methods.setPreference(pref, value);
    final currentPreferences = preference.value;
    if (currentPreferences != null) {
      preference.value = List<SourcePreference>.from(currentPreferences);
    }
    if (mounted) setState(() {});
  }

  String _listPreferenceSubtitle(ListPreference pref) {
    final entry = _listPreferenceSelectedEntry(pref);
    if (entry != null && entry.isNotEmpty) return entry;
    if (pref.summary != null && pref.summary!.isNotEmpty) return pref.summary!;
    return 'Select option';
  }

  String? _listPreferenceSelectedEntry(ListPreference pref) {
    final entries = pref.entries ?? [];
    if (entries.isEmpty) return null;

    final valueIndex = pref.valueIndex;
    if (valueIndex != null && valueIndex >= 0 && valueIndex < entries.length) {
      return entries[valueIndex];
    }

    final value = pref.value;
    final entryValues = pref.entryValues ?? [];
    final index = value == null ? -1 : entryValues.indexOf(value);
    if (index >= 0 && index < entries.length) return entries[index];

    return null;
  }

  int _initialListPreferenceIndex(ListPreference pref) {
    final entries = pref.entries ?? [];
    final valueIndex = pref.valueIndex;
    if (valueIndex != null && valueIndex >= 0 && valueIndex < entries.length) {
      return valueIndex;
    }

    final value = pref.value;
    final entryValues = pref.entryValues ?? [];
    final index = value == null ? -1 : entryValues.indexOf(value);
    if (index >= 0 && index < entries.length) return index;

    return 0;
  }

  String? _listPreferenceValueAt(ListPreference pref, int index) {
    final entryValues = pref.entryValues ?? [];
    if (index >= 0 && index < entryValues.length) return entryValues[index];
    return null;
  }

  String _multiSelectPreferenceSubtitle(MultiSelectListPreference pref) {
    final selectedEntries = _multiSelectPreferenceSelectedEntries(pref);
    if (selectedEntries.isNotEmpty) return selectedEntries.join(', ');
    if (pref.summary != null && pref.summary!.isNotEmpty) return pref.summary!;
    return 'Select multiple';
  }

  List<String> _multiSelectPreferenceSelectedEntries(
    MultiSelectListPreference pref,
  ) {
    final selectedValues = (pref.values ?? []).toSet();
    final entries = pref.entries ?? [];
    final entryValues = pref.entryValues ?? [];

    return entries
        .asMap()
        .entries
        .where((entry) =>
            entry.key < entryValues.length &&
            selectedValues.contains(entryValues[entry.key]))
        .map((entry) => entry.value)
        .toList();
  }

  String _multiSelectPreferenceValueAt(
    MultiSelectListPreference pref,
    int index,
  ) {
    final entryValues = pref.entryValues ?? [];
    if (index >= 0 && index < entryValues.length) return entryValues[index];
    return (pref.entries ?? [])[index];
  }

  @override
  Widget build(BuildContext context) {
    var theme = context.colors;
    return AnymeXScaffold(
  body: Column(
          children: [
            NestedHeader(
              title: "${widget.source.name} Settings",
            ),
            Expanded(
              child: Obx(
                () {
                  if (preference.value == null) {
                    return const Center(
                      child: ExpressiveLoadingIndicator(),
                    );
                  }
                  if (preference.value!.isEmpty) {
                    return const Center(
                      child: AnymeXText("Source doesn't have any settings"),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: AnymeXSectionBuilder(
                      margin: EdgeInsets.zero,
                      children: preference.value!.map((pref) {
                        switch (pref.type) {
                          case 'checkBox':
                            final p = pref.checkBoxPreference!;
                            return AnymeXTile.toggle(
                              title: p.title ?? '',
                              subtitle: p.summary ?? 'Toggle setting',
                              value: p.value ?? false,
                              onChanged: (v) {
                                p.value = v;
                                _savePreference(pref, v);
                              },
                            );
                          case 'switch':
                            final p = pref.switchPreferenceCompat!;
                            return AnymeXTile.toggle(
                              title: p.title ?? '',
                              subtitle: p.summary ?? 'Toggle setting',
                              value: p.value ?? false,
                              onChanged: (v) {
                                p.value = v;
                                _savePreference(pref, v);
                              },
                            );
                          case 'list':
                            final p = pref.listPreference!;
                            return AnymeXTile(
                              title: p.title ?? '',
                              subtitle: _listPreferenceSubtitle(p),
                              onTap: () {
                                int tempIndex = _initialListPreferenceIndex(p);
                                showDialog(
                                  context: context,
                                  builder: (context) => StatefulBuilder(
                                    builder: (context, setDialogState) =>
                                        AnymeXDialog(
                                      title: p.title ?? 'Select Option',
                                      onConfirm: () {
                                        p.valueIndex = tempIndex;
                                        final newValue =
                                            _listPreferenceValueAt(p, tempIndex);
                                        p.value = newValue;
                                        _savePreference(pref, newValue);
                                      },
                                      contentWidget: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                                        ),
                                        child: AnymeXTileBuilder<int>(
                                          items: List.generate(p.entries?.length ?? 0, (index) => index),
                                          selectedItem: tempIndex,
                                          getTitle: (i) => p.entries![i],
                                          getSubtitle: (i) => 'Option ${i + 1}',
                                          lazy: true,
                                          onItemPressed: (i) {
                                            setDialogState(() {
                                              tempIndex = i;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          case 'multi_select':
                            final p = pref.multiSelectListPreference!;
                            return AnymeXTile(
                              title: p.title ?? '',
                              subtitle: _multiSelectPreferenceSubtitle(p),
                              onTap: () {
                                final tempSelectedValues =
                                    (p.values ?? []).toSet();
                                showDialog(
                                  context: context,
                                  builder: (context) => StatefulBuilder(
                                    builder: (context, setDialogState) =>
                                        AnymeXDialog(
                                      title: p.title ?? 'Select Options',
                                      onConfirm: () {
                                        p.values = tempSelectedValues.toList();
                                        _savePreference(pref, p.values);
                                      },
                                      contentWidget: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                                        ),
                                        child: AnymeXTileBuilder<int>(
                                          items: List.generate(p.entries?.length ?? 0, (index) => index),
                                          isSelected: (i) {
                                            final val = _multiSelectPreferenceValueAt(p, i);
                                            return tempSelectedValues.contains(val);
                                          },
                                          getTitle: (i) => p.entries![i],
                                          getSubtitle: (i) => 'Option ${i + 1}',
                                          lazy: true,
                                          onItemPressed: (i) {
                                            final val = _multiSelectPreferenceValueAt(p, i);
                                            setDialogState(() {
                                              if (tempSelectedValues.contains(val)) {
                                                tempSelectedValues.remove(val);
                                              } else {
                                                tempSelectedValues.add(val);
                                              }
                                            });
                                          },
                                          isRadio: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          case 'text':
                            final p = pref.editTextPreference!;
                            return AnymeXTile(
                              title: p.title ?? '',
                              subtitle: p.value ?? p.text ?? 'Edit text',
                              onTap: () {
                                String tempValue = p.value ?? p.text ?? '';
                                showDialog(
                                  context: context,
                                  builder: (context) => AnymeXDialog(
                                    title:
                                        p.dialogTitle ?? p.title ?? 'Edit Text',
                                    onConfirm: () {
                                      p.value = tempValue;
                                      p.text = tempValue;
                                      _savePreference(pref, tempValue);
                                    },
                                    contentWidget: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (p.dialogMessage != null) ...[
                                          AnymeXText(p.dialogMessage!,
                                            size: 14,
                                            color: theme.onSurfaceVariant,
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                        TextField(
                                          controller: TextEditingController(
                                              text: tempValue),
                                          onChanged: (val) => tempValue = val,
                                          maxLines: 3,
                                          minLines: 1,
                                          style:
                                              TextStyle(color: theme.onSurface),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: theme
                                                .surfaceContainerHighest
                                                .opaque(0.3),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: theme.outline),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              trailing: Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: theme.onSurface.opaque(0.5),
                              ),
                              showChevron: false,
                            );

                          default:
                            return AnymeXTile(
                              title: pref.key ?? 'Unknown Preference',
                              subtitle: 'Unsupported type ${pref.type}',
                              showChevron: false,
                              onTap: () {},
                            );
                        }
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        )
);
  }
}


