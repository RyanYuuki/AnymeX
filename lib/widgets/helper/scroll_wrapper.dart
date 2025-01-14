import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';

class ScrollWrapper extends StatelessWidget {
  final EdgeInsets? customPadding;
  final bool comfortPadding;
  final List<Widget> children;
  const ScrollWrapper(
      {super.key,
      this.customPadding,
      this.comfortPadding = true,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: comfortPadding
          ? EdgeInsets.symmetric(
              vertical:
                  getResponsiveSize(context, mobileSize: 50, dektopSize: 40))
          : customPadding,
      physics: const BouncingScrollPhysics(),
      children: children,
    );
  }
}
