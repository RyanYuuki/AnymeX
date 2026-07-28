import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
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
    return Glow(
      child: Scaffold(
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
                      child: Text("Source doesn't have any settings"),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: preference.value!.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final pref = preference.value![index];
                      switch (pref.type) {
                        case 'checkBox':
                          final p = pref.checkBoxPreference!;
                          return _PreferenceTile(
                            title: p.title ?? '',
                            subtitle: p.summary ?? 'Toggle setting',
                            isSelected: p.value ?? false,
                            onTap: () {
                              final newVal = !(p.value ?? false);
                              p.value = newVal;
                              _savePreference(pref, newVal);
                            },
                            type: _PreferenceType.toggle,
                          );
                        case 'switch':
                          final p = pref.switchPreferenceCompat!;
                          return _PreferenceTile(
                            title: p.title ?? '',
                            subtitle: p.summary ?? 'Toggle setting',
                            isSelected: p.value ?? false,
                            onTap: () {
                              final newVal = !(p.value ?? false);
                              p.value = newVal;
                              _savePreference(pref, newVal);
                            },
                            type: _PreferenceType.toggle,
                          );
                        case 'list':
                          final p = pref.listPreference!;
                          return _PreferenceTile(
                            title: p.title ?? '',
                            subtitle: _listPreferenceSubtitle(p),
                            isSelected: false,
                            onTap: () {
                              int tempIndex = _initialListPreferenceIndex(p);
                              showDialog(
                                context: context,
                                builder: (context) => StatefulBuilder(
                                  builder: (context, setDialogState) =>
                                      AnymexDialog(
                                    title: p.title ?? 'Select Option',
                                    onConfirm: () {
                                      p.valueIndex = tempIndex;
                                      final newValue =
                                          _listPreferenceValueAt(p, tempIndex);
                                      p.value = newValue;
                                      _savePreference(pref, newValue);
                                    },
                                    contentWidget: SizedBox(
                                      height: 300,
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: p.entries?.length ?? 0,
                                        itemBuilder: (context, i) => Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: _PreferenceTile(
                                            title: p.entries![i],
                                            subtitle: 'Option ${i + 1}',
                                            isSelected: tempIndex == i,
                                            onTap: () {
                                              setDialogState(() {
                                                tempIndex = i;
                                              });
                                            },
                                            type: _PreferenceType.toggle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            type: _PreferenceType.list,
                          );
                        case 'multi_select':
                          final p = pref.multiSelectListPreference!;
                          return _PreferenceTile(
                            title: p.title ?? '',
                            subtitle: _multiSelectPreferenceSubtitle(p),
                            isSelected: false,
                            onTap: () {
                              final tempSelectedValues =
                                  (p.values ?? []).toSet();
                              showDialog(
                                context: context,
                                builder: (context) => StatefulBuilder(
                                  builder: (context, setDialogState) =>
                                      AnymexDialog(
                                    title: p.title ?? 'Select Options',
                                    onConfirm: () {
                                      p.values = tempSelectedValues.toList();
                                      _savePreference(pref, p.values);
                                    },
                                    contentWidget: SizedBox(
                                      height: 300,
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: p.entries?.length ?? 0,
                                        itemBuilder: (context, i) {
                                          final val =
                                              _multiSelectPreferenceValueAt(
                                                  p, i);
                                          final isCurrentlySelected =
                                              tempSelectedValues.contains(val);
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: _PreferenceTile(
                                              title: p.entries![i],
                                              subtitle: 'Option ${i + 1}',
                                              isSelected: isCurrentlySelected,
                                              onTap: () {
                                                setDialogState(() {
                                                  if (isCurrentlySelected) {
                                                    tempSelectedValues
                                                        .remove(val);
                                                  } else {
                                                    tempSelectedValues.add(val);
                                                  }
                                                });
                                              },
                                              type: _PreferenceType.toggle,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            type: _PreferenceType.list,
                          );
                        case 'text':
                          final p = pref.editTextPreference!;
                          return _PreferenceTile(
                            title: p.title ?? '',
                            subtitle: p.value ?? p.text ?? 'Edit text',
                            isSelected: false,
                            onTap: () {
                              String tempValue = p.value ?? p.text ?? '';
                              showDialog(
                                context: context,
                                builder: (context) => AnymexDialog(
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
                                        AnymexText(
                                          text: p.dialogMessage!,
                                          size: 14,
                                          color: theme.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      TextField(
                                        controller: TextEditingController(
                                            text: tempValue),
                                        onChanged: (val) => tempValue = val,
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
                            type: _PreferenceType.text,
                          );

                        default:
                          return _PreferenceTile(
                            title: pref.key ?? 'Unknown Preference',
                            subtitle: 'Unsupported type ${pref.type}',
                            isSelected: false,
                            onTap: () {},
                            type: _PreferenceType.text,
                          );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PreferenceType { toggle, list, text }

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.type,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final _PreferenceType type;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.primaryContainer.opaque(0.35)
                : context.colors.surfaceContainerHighest.opaque(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? context.colors.primary.opaque(0.4)
                  : context.colors.outline.opaque(0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymexText(
                      text: title,
                      variant: TextVariant.semiBold,
                      color: isSelected ? context.colors.primary : null,
                    ),
                    const SizedBox(height: 4),
                    AnymexText(
                      text: subtitle,
                      size: 11,
                      color: context.colors.onSurface.opaque(0.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (type == _PreferenceType.toggle)
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.onSurface.opaque(0.5),
                )
              else if (type == _PreferenceType.list)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: context.colors.onSurface.opaque(0.5),
                )
              else
                Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: context.colors.onSurface.opaque(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
