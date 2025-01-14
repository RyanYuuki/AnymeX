import 'package:flutter/material.dart';

class AlertDialogBuilder {
  final BuildContext context;
  String? _title;
  Widget? _titleWidget;
  String? _message;
  String? _positiveButtonTitle;
  String? _negativeButtonTitle;
  String? _neutralButtonTitle;
  VoidCallback? _onPositiveButtonClick;
  VoidCallback? _onNegativeButtonClick;
  VoidCallback? _onNeutralButtonClick;
  List<String>? _items;
  List<bool>? _checkedItems;
  ValueChanged<List<bool>>? _onItemsSelected;
  int _selectedItemIndex = -1;
  ValueChanged<int>? _onItemSelected;
  List<String>? _reorderableItems;
  ValueChanged<List<String>>? _onReorderedItems;
  bool _isReorderableMultiSelectable = false;
  Widget? _customView;
  VoidCallback? _onShow;
  VoidCallback? _onAttach;
  VoidCallback? _onDismiss;
  bool _cancelable = true;

  AlertDialogBuilder(this.context);

  AlertDialogBuilder setCancelable(bool cancelable) =>
      _with(() => _cancelable = cancelable);

  AlertDialogBuilder setOnShowListener(VoidCallback onShow) =>
      _with(() => _onShow = onShow);

  AlertDialogBuilder setOnAttachListener(VoidCallback attach) =>
      _with(() => _onAttach = attach);

  AlertDialogBuilder setOnDismissListener(VoidCallback onDismiss) =>
      _with(() => _onDismiss = onDismiss);

  AlertDialogBuilder setTitle(String? title) => _with(() => _title = title);

  AlertDialogBuilder setTitleWidget(Widget? w) => _with(() => _titleWidget = w);

  AlertDialogBuilder setMessage(String? message) =>
      _with(() => _message = message);

  AlertDialogBuilder setCustomView(Widget customView) =>
      _with(() => _customView = customView);

  AlertDialogBuilder setPositiveButton(String? title, VoidCallback? onClick) =>
      _with(() {
        _positiveButtonTitle = title;
        _onPositiveButtonClick = onClick;
      });

  AlertDialogBuilder setNegativeButton(String? title, VoidCallback? onClick) =>
      _with(() {
        _negativeButtonTitle = title;
        _onNegativeButtonClick = onClick;
      });

  AlertDialogBuilder setNeutralButton(String? title, VoidCallback? onClick) =>
      _with(() {
        _neutralButtonTitle = title;
        _onNeutralButtonClick = onClick;
      });

  AlertDialogBuilder singleChoiceItems(List<String> items,
          int selectedItemIndex, ValueChanged<int> onItemSelected) =>
      _with(() {
        _items = items;
        _selectedItemIndex = selectedItemIndex;
        _onItemSelected = onItemSelected;
      });

  AlertDialogBuilder multiChoiceItems(List<String> items,
          List<bool>? checkedItems, ValueChanged<List<bool>> onItemsSelected) =>
      _with(() {
        _items = items;
        _checkedItems = checkedItems ?? List<bool>.filled(items.length, false);
        _onItemsSelected = onItemsSelected;
      });

  AlertDialogBuilder reorderableItems(
          List<String> items, ValueChanged<List<String>> onReorderedItems) =>
      _with(() {
        _reorderableItems = items;
        _onReorderedItems = onReorderedItems;
      });

  AlertDialogBuilder reorderableMultiSelectableItems(
          List<String> items,
          List<bool>? checkedItems,
          ValueChanged<List<String>> onReorderedItems,
          ValueChanged<List<bool>> onReorderedItemsSelected) =>
      _with(() {
        _reorderableItems = items;
        _checkedItems = checkedItems ?? List<bool>.filled(items.length, false);
        _onReorderedItems = onReorderedItems;
        _onItemsSelected = onReorderedItemsSelected;
        _isReorderableMultiSelectable = true;
      });

  void show() {
    var theme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: _cancelable,
      builder: (BuildContext context) {
        _onShow?.call();
        return AlertDialog(
          title: _titleWidget ?? Text(_title ?? ''),
          titleTextStyle: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: theme.primary),
          content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) =>
                  _buildContent(setState)),
          actions: _buildActions(),
        );
      },
    ).then((_) => _onDismiss?.call());
    _onAttach?.call();
  }

  Widget _buildContent(StateSetter setState) {
    if (_reorderableItems != null) {
      return _isReorderableMultiSelectable
          ? _buildReorderableSelectableContent(setState)
          : _buildReorderableContent(setState);
    } else if (_items != null) {
      return _onItemSelected != null
          ? _buildRadioListContent(setState)
          : _buildCheckboxListContent(setState);
    }
    return _buildDefaultContent();
  }

  Widget _buildReorderableContent(StateSetter setState) =>
      _buildReorderableWidget(setState, (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        final items = List<String>.from(_reorderableItems!);
        final item = items.removeAt(oldIndex);
        items.insert(newIndex, item);
        setState(() => _reorderableItems = items);
        _onReorderedItems?.call(items);
      });

  Widget _buildReorderableSelectableContent(StateSetter setState) =>
      _buildReorderableWithCheckBoxWidget(setState, (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        final items = List<String>.from(_reorderableItems!);
        final checkedStates = List<bool>.from(_checkedItems!);
        final item = items.removeAt(oldIndex);
        final state = checkedStates.removeAt(oldIndex);
        items.insert(newIndex, item);
        checkedStates.insert(newIndex, state);
        setState(() {
          _reorderableItems = items;
          _checkedItems = checkedStates;
        });
        _onReorderedItems?.call(items);
        _onItemsSelected?.call(checkedStates);
      });

  Widget _buildReorderableWithCheckBoxWidget(
          StateSetter setState, void Function(int, int) onReorder) =>
      SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ReorderableListView(
                onReorder: onReorder,
                children: _reorderableItems!.asMap().entries.map((entry) {
                  int index = entry.key;
                  String item = entry.value;
                  return CheckboxListTile(
                    key: ValueKey(item),
                    title: Text(item,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    value: _checkedItems![index],
                    onChanged: (bool? value) {
                      setState(() {
                        _checkedItems![index] = value!;
                        _onItemsSelected?.call(_checkedItems!);
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );

  Widget _buildReorderableWidget(
          StateSetter setState, void Function(int, int) onReorder) =>
      SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ReorderableListView(
                onReorder: onReorder,
                children: _reorderableItems!.map((item) {
                  return ListTile(
                    key: ValueKey(item),
                    title: Text(item,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );

  Widget _buildRadioListContent(StateSetter setState) => _buildListContent(
        (item) => RadioListTile<int>(
          title: Text(item,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          value: _items!.indexOf(item),
          groupValue: _selectedItemIndex,
          onChanged: (int? value) {
            setState(() => _selectedItemIndex = value!);
            _onItemSelected?.call(value!);
            Navigator.of(context).pop();
          },
        ),
      );

  Widget _buildCheckboxListContent(StateSetter setState) => _buildListContent(
        (item) {
          final index = _items!.indexOf(item);
          return CheckboxListTile(
            title: Text(item,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            value: _checkedItems![index],
            onChanged: (bool? value) {
              setState(() => _checkedItems![index] = value!);
              _onItemsSelected?.call(_checkedItems!);
            },
            controlAffinity: ListTileControlAffinity.leading,
          );
        },
      );

  Widget _buildListContent(Widget Function(String) itemBuilder) =>
      ConstrainedBox(
        constraints:
            BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.7),
        child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _items!.map(itemBuilder).toList()),
        ),
      );

  Widget _buildDefaultContent() => ConstrainedBox(
        constraints:
            BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.7),
        child: _customView ?? Text(_message ?? ''),
      );

  List<Widget> _buildActions() {
    var theme = Theme.of(context).colorScheme;
    final actions = <Widget>[];
    if (_neutralButtonTitle != null) {
      actions.add(
          _buildButton(_neutralButtonTitle!, _onNeutralButtonClick, theme));
    }
    if (_negativeButtonTitle != null) {
      actions.add(
          _buildButton(_negativeButtonTitle!, _onNegativeButtonClick, theme));
    }
    if (_positiveButtonTitle != null) {
      actions.add(
          _buildButton(_positiveButtonTitle!, _onPositiveButtonClick, theme));
    }
    return actions;
  }

  Widget _buildButton(String title, VoidCallback? onClick, ColorScheme theme) =>
      TextButton(
        onPressed: () {
          onClick?.call();
          Navigator.of(context).pop();
        },
        child: Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.primary)),
      );

  AlertDialogBuilder _with(VoidCallback action) {
    action();
    return this;
  }
}
