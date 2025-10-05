import 'package:anymex/widgets/AlertDialogBuilder.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
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

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    return Glow(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            "${widget.source.name} Settings",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              color: theme.primary,
            ),
          ),
          iconTheme: IconThemeData(color: theme.primary),
        ),
        body: Obx(
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
            Text TitleText(String text) {
              return Text(
                text,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: theme.primary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              );
            }

            Text SubtitleText(String text) {
              return Text(
                text,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.0,
                  color: theme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              );
            }

            return ListView.builder(
              itemCount: preference.value!.length,
              itemBuilder: (context, index) {
                final pref = preference.value![index];
                switch (pref.type) {
                  case 'checkBox':
                    final p = pref.checkBoxPreference!;
                    return CheckboxListTile(
                      title: TitleText(p.title ?? ''),
                      subtitle:
                          p.summary != null ? SubtitleText(p.summary!) : null,
                      value: p.value ?? false,
                      onChanged: (val) {
                        p.value = val;
                        widget.source.methods.setPreference(pref, val);
                        setState(() {});
                      },
                    );
                  case 'switch':
                    final p = pref.switchPreferenceCompat!;
                    return SwitchListTile(
                      title: TitleText(p.title ?? ''),
                      value: p.value ?? false,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 0),
                      onChanged: (val) {
                        p.value = val;
                        widget.source.methods.setPreference(pref, val);
                        setState(() {});
                      },
                    );
                  case 'list':
                    final p = pref.listPreference!;
                    return ListTile(
                      title: TitleText(p.title ?? ''),
                      subtitle: SubtitleText(
                        p.summary != null && p.summary!.isNotEmpty
                            ? p.summary!
                            : p.entries?[p.valueIndex ?? 0] ?? '',
                      ),
                      onTap: () {
                        AlertDialogBuilder(context)
                          ..setTitle(p.title ?? '')
                          ..singleChoiceItems(
                            (p.entries ?? []),
                            p.valueIndex ?? 0,
                            (int index) {
                              p.valueIndex = index;
                              widget.source.methods
                                  .setPreference(pref, p.entryValues?[index]);
                              setState(() {});
                            },
                          )
                          ..show();
                      },
                    );
                  case 'multi_select':
                    final p = pref.multiSelectListPreference!;
                    var subtitle = (p.entries ?? [])
                        .asMap()
                        .entries
                        .where((e) =>
                            p.values?.contains(p.entryValues?[e.key]) ?? false)
                        .map((e) => e.value)
                        .toList()
                        .join(", ");
                    return ListTile(
                      title: TitleText(p.title ?? ''),
                      subtitle: SubtitleText(
                        p.summary != null && p.summary!.isNotEmpty
                            ? p.summary!
                            : subtitle,
                      ),
                      onTap: () async {
                        final newValues = <String>[];
                        AlertDialogBuilder(context)
                          ..setTitle(p.title ?? '')
                          ..multiChoiceItems(
                            p.entries ?? [],
                            p.entryValues
                                ?.map((pv) => p.values?.contains(pv) ?? false)
                                .toList(),
                            (List<bool> checked) {
                              newValues.clear();
                              for (var i = 0; i < checked.length; i++) {
                                if (checked[i]) {
                                  final value = p.entryValues?[i];
                                  if (value != null) newValues.add(value);
                                }
                              }
                            },
                          )
                          ..setPositiveButton(
                            'OK',
                            () => setState(() {
                              p.values = newValues.toList();
                              widget.source.methods
                                  .setPreference(pref, newValues);
                            }),
                          )
                          ..setNegativeButton("Cancel", () {})
                          ..show();
                      },
                    );
                  case 'text':
                    final p = pref.editTextPreference!;
                    return ListTile(
                      title: TitleText(p.title ?? ''),
                      subtitle: SubtitleText(p.value ?? p.text ?? ''),
                      onTap: () {
                        var value = p.value ?? p.text ?? '';
                        AlertDialogBuilder(context)
                          ..setTitle(p.dialogTitle ?? '')
                          ..setMessage(p.dialogMessage ?? '')
                          ..setCustomView(
                            TextFormField(
                              initialValue: p.value ?? p.text,
                              onChanged: (val) => value = val,
                            ),
                          )
                          ..setPositiveButton(
                            'OK',
                            () => setState(() {
                              p.value = value;
                              widget.source.methods.setPreference(pref, value);
                            }),
                          )
                          ..setNegativeButton("Cancel", () {})
                          ..show();
                      },
                    );

                  default:
                    return ListTile(
                      title: Text(pref.key ?? 'Unknown Preference'),
                      subtitle: Text(
                        'Unsupported preference type ${pref.type}',
                      ),
                    );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
