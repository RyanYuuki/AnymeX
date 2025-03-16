import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class NovelDetailsPage extends StatefulWidget {
  const NovelDetailsPage({super.key});

  @override
  State<NovelDetailsPage> createState() => _NovelDetailsPageState();
}

class _NovelDetailsPageState extends State<NovelDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Glow(
        child: Scaffold(
      body: ScrollWrapper(children: [
        Container(
          height: MediaQuery.of(context).size.height,
          alignment: Alignment.center,
          child: const AnymexText(text: "ITS WORK IN PROGRESS"),
        )
      ]),
    ));
  }
}
