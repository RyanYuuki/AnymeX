import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/widgets.dart';
import 'package:anymex/l10n/l10n_extension.dart';

class EmptyLibrary extends StatelessWidget {
  final bool isHistory;
  const EmptyLibrary({super.key, this.isHistory = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        150.height(),
        const AnymeXText(
          '(─‿─)',
          style: TextStyle(fontSize: 50, fontFamily: "Roboto"),
        ),
        const SizedBox(
          height: 20,
        ),
        AnymeXText(isHistory ? context.l10n.yourHistoryIsEmpty : context.l10n.libraryEmpty)
      ],
    );
  }
}
