import 'package:flutter/material.dart';

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
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.withOpacity(0.5),
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
                          ? Theme.of(context).colorScheme.onPrimary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title ?? '',
                      style: TextStyle(
                        fontFamily: "Poppins-Bold",
                        fontSize: 16,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
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
