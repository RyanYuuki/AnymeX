import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

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
    return SuperListView(
      padding: comfortPadding
          ? EdgeInsets.symmetric(
              vertical:
                  getResponsiveSize(context, mobileSize: 50, desktopSize: 40))
          : customPadding,
      physics: const BouncingScrollPhysics(),
      children: children,
    );
  }
}
