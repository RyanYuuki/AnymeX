import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/widgets.dart';

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
        const Text(
          '(─‿─)',
          style: TextStyle(fontSize: 50, fontFamily: "Roboto"),
        ),
        const SizedBox(
          height: 20,
        ),
        AnymexText(
            text: isHistory ? "Your history is empty" : "Your library is empty")
      ],
    );
  }
}
