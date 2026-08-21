import 'package:flutter/material.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

class ListTileChapterFilter extends StatelessWidget {
  final String label;
  final int type;
  final VoidCallback onTap;

  const ListTileChapterFilter(
      {super.key,
      required this.label,
      required this.type,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      dense: true,
      tristate: true,
      value: type == 0
          ? false
          : type == 1
              ? true
              : null,
      title: AnymeXText(
        label,
        style: const TextStyle(fontSize: 14),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (value) {
        onTap.call();
      },
    );
  }
}
