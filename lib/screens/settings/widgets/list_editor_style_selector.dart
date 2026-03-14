import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/anime/widgets/list_editor_theme_registry.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/anymex_chip.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

void showListEditorStyleSelector(BuildContext context) {
  final selectedId =
      ListEditorThemeRegistry.normalizeId(settingsController.listEditorTheme)
          .obs;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Obx(
        () => AnymexDialog(
          title: 'List Editor Style',
          onConfirm: () {
            settingsController.listEditorTheme = selectedId.value;
          },
          contentWidget: ListEditorStyleSelector(
            initialId: selectedId.value,
            onStyleChanged: (id) {
              selectedId.value = id;
            },
          ),
        ),
      );
    },
  );
}

class ListEditorStyleSelector extends StatefulWidget {
  final String initialId;
  final ValueChanged<String> onStyleChanged;

  const ListEditorStyleSelector({
    super.key,
    required this.initialId,
    required this.onStyleChanged,
  });

  @override
  State<ListEditorStyleSelector> createState() =>
      _ListEditorStyleSelectorState();
}

class _ListEditorStyleSelectorState extends State<ListEditorStyleSelector> {
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialId;
  }

  @override
  Widget build(BuildContext context) {
    final selectedTheme = ListEditorThemeRegistry.byId(_selectedId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          child: SuperListView(
            scrollDirection: Axis.horizontal,
            children: ListEditorThemeRegistry.themes
                .map((theme) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildThemeChip(theme.id, theme.name),
                    ))
                .toList(),
          ),
        ),
        10.height(),
        Text(
          selectedTheme.description.isEmpty
              ? 'Switch the list editor layout.'
              : selectedTheme.description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildThemeChip(String id, String label) {
    final bool isSelected = id == _selectedId;

    return AnymexChip(
      isSelected: isSelected,
      label: label,
      onSelected: (selected) {
        if (!selected) return;
        setState(() {
          _selectedId = id;
        });
        widget.onStyleChanged(id);
      },
    );
  }
}
