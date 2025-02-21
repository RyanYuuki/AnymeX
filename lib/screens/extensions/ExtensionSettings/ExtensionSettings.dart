import 'package:anymex/widgets/common/glow.dart';
import 'package:flutter/material.dart';

import '../../../core/Eval/dart/model/source_preference.dart';
import '../../../core/Model/Source.dart';
import '../../../core/extension_preferences_providers.dart';
import 'ListTileChapterFilter.dart';

class SourcePreferenceWidget extends StatefulWidget {
  final List<SourcePreference> sourcePreference;
  final Source source;

  const SourcePreferenceWidget(
      {super.key, required this.sourcePreference, required this.source});

  @override
  State<SourcePreferenceWidget> createState() => _SourcePreferenceWidgetState();
}

class _SourcePreferenceWidgetState extends State<SourcePreferenceWidget> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    return Glow(
      child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: Text(
              '${widget.source.name} Settings',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
                color: theme.primary,
              ),
            ),
            iconTheme: IconThemeData(color: theme.primary),
          ),
          body: widget.sourcePreference.isEmpty
              ? const Center(
                  child: Text("No Settings Available"),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.sourcePreference.length,
                  itemBuilder: (context, index) {
                    final preference = widget.sourcePreference[index];
                    return _buildPreferenceWidget(preference, theme);
                  },
                )),
    );
  }

  Widget _buildPreferenceWidget(
      SourcePreference preference, ColorScheme theme) {
    if (preference.editTextPreference != null) {
      return _buildEditTextPreference(
          preference, preference.editTextPreference!, theme);
    } else if (preference.checkBoxPreference != null) {
      return _buildCheckBoxPreference(
          preference, preference.checkBoxPreference!, theme);
    } else if (preference.switchPreferenceCompat != null) {
      return _buildSwitchPreference(
          preference, preference.switchPreferenceCompat!, theme);
    } else if (preference.listPreference != null) {
      return _buildListPreference(
          preference, preference.listPreference!, theme);
    } else if (preference.multiSelectListPreference != null) {
      return _buildMultiSelectPreference(
          preference, preference.multiSelectListPreference!, theme);
    }
    return const SizedBox.shrink();
  }

  Widget _buildEditTextPreference(
      preference, EditTextPreference pref, ColorScheme theme) {
    return ListTile(
      title: Text(
        pref.title!,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        pref.summary!,
        style: TextStyle(
          fontSize: 10,
          color: theme.secondary,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: () {
        _showEditTextDialog(preference, pref);
      },
    );
  }

  Widget _buildCheckBoxPreference(
      SourcePreference preference, CheckBoxPreference pref, ColorScheme theme) {
    return CheckboxListTile(
      title: Text(
        pref.title!,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        pref.summary!,
        style: TextStyle(
          fontSize: 10,
          color: theme.secondary,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
      ),
      value: pref.value,
      onChanged: (value) {
        setState(() {
          pref.value = value;
        });
        setPreferenceSetting(preference, widget.source);
      },
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }

  Widget _buildSwitchPreference(SourcePreference preference,
      SwitchPreferenceCompat pref, ColorScheme theme) {
    return SwitchListTile(
      title: Text(
        pref.title!,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        pref.summary!,
        style: TextStyle(
          fontSize: 10,
          color: theme.secondary,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
      ),
      value: pref.value!,
      onChanged: (value) {
        setState(() {
          pref.value = value;
        });
        setPreferenceSetting(preference, widget.source);
      },
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }

  Widget _buildListPreference(
      SourcePreference preference, ListPreference pref, ColorScheme theme) {
    return ListTile(
      title: Text(
        pref.title!,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        pref.entries![pref.valueIndex!],
        style: TextStyle(
          fontSize: 10,
          color: theme.secondary,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: () async {
        final res = await _showListDialog(pref);
        if (res != null) {
          setState(() {
            pref.valueIndex = res;
          });
          setPreferenceSetting(preference, widget.source);
        }
      },
    );
  }

  Widget _buildMultiSelectPreference(SourcePreference preference,
      MultiSelectListPreference pref, ColorScheme theme) {
    return ListTile(
      title: Text(
        pref.title!,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        pref.summary!,
        style: TextStyle(
          fontSize: 10,
          color: theme.secondary,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: () {
        _showMultiSelectDialog(preference, pref);
      },
    );
  }

  Future<void> _showEditTextDialog(
      SourcePreference preference, EditTextPreference pref) async {
    await showDialog(
      context: context,
      builder: (context) => EditTextDialogWidget(
        text: pref.value!,
        onChanged: (value) {
          setState(() {
            pref.value = value;
          });
          setPreferenceSetting(preference, widget.source);
        },
        dialogTitle: pref.dialogTitle!,
        dialogMessage: pref.dialogMessage!,
      ),
    );
  }

  Future<int?> _showListDialog(ListPreference pref) async {
    return await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pref.title!),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: pref.entries!.length,
            itemBuilder: (context, index) {
              return RadioListTile(
                dense: true,
                contentPadding: const EdgeInsets.all(0),
                value: index,
                groupValue: pref.valueIndex,
                onChanged: (value) {
                  Navigator.pop(context, index);
                },
                title: Text(pref.entries![index]),
              );
            },
          ),
        ),
        actions: _buildDialogActions(context),
      ),
    );
  }

  void _showMultiSelectDialog(
      SourcePreference preference, MultiSelectListPreference pref) {
    List<String> indexList = List.from(pref.values!);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(pref.title!),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pref.entries!.length,
                  itemBuilder: (context, index) {
                    if (index > 1) return const SizedBox.shrink();
                    return ListTileChapterFilter(
                      label: pref.entries![index],
                      type:
                          indexList.contains(pref.entryValues?[index]) ? 1 : 0,
                      onTap: () {
                        setState(() {
                          if (indexList.contains(pref.entryValues![index])) {
                            indexList.remove(pref.entryValues![index]);
                          } else {
                            indexList.add(pref.entryValues![index]);
                          }
                          pref.values = indexList;
                        });
                        setPreferenceSetting(preference, widget.source);
                      },
                    );
                  },
                ),
              ),
              actions: _buildDialogActions(context),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildDialogActions(BuildContext context) {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Ok'),
      ),
    ];
  }
}

class EditTextDialogWidget extends StatefulWidget {
  final String text;
  final String dialogTitle;
  final String dialogMessage;
  final Function(String) onChanged;

  const EditTextDialogWidget({
    super.key,
    required this.text,
    required this.onChanged,
    required this.dialogTitle,
    required this.dialogMessage,
  });

  @override
  State<EditTextDialogWidget> createState() => _EditTextDialogWidgetState();
}

class _EditTextDialogWidgetState extends State<EditTextDialogWidget> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.text);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.dialogTitle),
          Text(widget.dialogMessage, style: const TextStyle(fontSize: 13)),
        ],
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.primary),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.primary),
              ),
              border: const OutlineInputBorder(borderSide: BorderSide()),
            ),
          ),
        ),
      ),
      actions: _buildDialogActions(context),
    );
  }

  List<Widget> _buildDialogActions(BuildContext context) {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () {
          widget.onChanged(_controller.text);
          Navigator.pop(context);
        },
        child: const Text('Ok'),
      ),
    ];
  }
}
