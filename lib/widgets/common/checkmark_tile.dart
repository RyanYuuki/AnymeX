import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:checkmark/checkmark.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ListTileWithCheckMark extends StatelessWidget {
  final bool active;
  final void Function()? onTap;
  final String? title;
  final String subtitle;
  final IconData? icon;
  final Color? tileColor;
  final Widget? titleWidget;
  final Widget? leading;
  final double? iconSize;
  final bool dense;
  final Color color;
  final bool expanded;

  const ListTileWithCheckMark({
    super.key,
    this.active = false,
    this.onTap,
    this.title,
    this.subtitle = '',
    this.icon = HugeIcons.strokeRoundedTick01,
    this.tileColor,
    this.titleWidget,
    this.leading,
    this.iconSize,
    this.dense = false,
    this.expanded = true,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tileAlpha = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.secondaryContainer
        : Theme.of(context).colorScheme.surfaceContainer;
    final br = BorderRadius.circular(14.0);
    final titleWidgetFinal = Padding(
      padding: EdgeInsets.symmetric(horizontal: dense ? 10.0 : 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget ??
              Text(
                title!,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
          if (subtitle != '')
            Text(
              subtitle,
              maxLines: 1,
            )
        ],
      ),
    );
    return AnymexOnTap(
      onTap: onTap,
      child: InkWell(
        borderRadius: br,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: tileAlpha,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (leading != null)
                Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(
                              Theme.of(context).brightness == Brightness.dark
                                  ? 0.3
                                  : 0.6),
                          blurRadius: 58.0,
                          spreadRadius: 2.0,
                          offset: const Offset(-2.0, 0),
                        ),
                      ],
                    ),
                    child: leading!)
              else if (icon != null)
                Icon(
                  icon,
                  size: iconSize,
                ),
              expanded
                  ? Expanded(
                      child: titleWidgetFinal,
                    )
                  : Flexible(
                      child: titleWidgetFinal,
                    ),
              Checkmark(
                size: 18.0,
                active: active,
                activeColor: Theme.of(context).colorScheme.primary,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class Checkmark extends StatelessWidget {
  final double size;
  final bool active;
  final Color? activeColor;
  final Color? inactiveColor;

  const Checkmark({
    super.key,
    required this.size,
    required this.active,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CheckMark(
        strokeWidth: 2,
        activeColor: activeColor ?? Theme.of(context).colorScheme.primary,
        inactiveColor:
            inactiveColor ?? Theme.of(context).colorScheme.inverseSurface,
        duration: const Duration(milliseconds: 400),
        active: active,
      ),
    );
  }
}
