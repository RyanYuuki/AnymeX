import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';

class AnymexSegmentedButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isSelected;
  final String? title;
  final IconData? icon;
  final Widget? titleWidget;
  final EdgeInsets? padding;

  const AnymexSegmentedButton({
    super.key,
    this.onTap,
    required this.isSelected,
    this.title,
    this.titleWidget,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isSelected
                  ? context.colors.primary
                  : context.colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? context.colors.primary
                    : Colors.grey.opaque(0.5),
                width: 1,
              ),
            ),
            child: titleWidget ??
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: isSelected
                          ? context.colors.onPrimary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title ?? '',
                      style: TextStyle(
                        fontFamily: "Poppins-Bold",
                        fontSize: 16,
                        color: isSelected
                            ? context.colors.onPrimary
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}
