import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_icon_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconly/iconly.dart';

class CustomSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool switchValue;
  final EdgeInsets padding;
  final bool disabled;
  final Function(bool value) onChanged;

  const CustomSwitchTile({
    super.key,
    this.disabled = false,
    required this.icon,
    required this.title,
    required this.description,
    required this.switchValue,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
  });

  @override
  Widget build(BuildContext context) {
    if (disabled) {
      return Opacity(
        opacity: 0.4,
        child: AnymexOnTap(
          onTap: () {},
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                AnymexIcon(icon,
                    size: 30, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                    decoration: BoxDecoration(
                      boxShadow: switchValue ? [glowingShadow(context)] : [],
                    ),
                    child: Switch(
                      value: switchValue,
                      onChanged: (e) {},
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ))
              ],
            ),
          ),
        ),
      );
    }
    return AnymexOnTap(
      onTap: () {
        onChanged.call(!switchValue);
      },
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            AnymexIcon(icon,
                size: 30, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
                decoration: BoxDecoration(
                  boxShadow: switchValue ? [glowingShadow(context)] : [],
                ),
                child: Switch(
                  value: switchValue,
                  onChanged: onChanged,
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveTrackColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ))
          ],
        ),
      ),
    );
  }
}

class CustomTile extends StatelessWidget {
  final IconData icon;
  final Widget? prefix;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final Widget? postFix;
  final double? padding;
  final bool? isDescBold;
  final Color? descColor;

  const CustomTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.prefix,
    this.postFix,
    this.padding,
    this.isDescBold,
    this.descColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnymexOnTap(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: padding ?? 20.0, vertical: 10.0),
          child: Row(
            children: [
              if (prefix == null)
                AnymexIcon(icon,
                    size: 30, color: Theme.of(context).colorScheme.primary)
              else
                prefix!,
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily:
                            (isDescBold ?? false) ? "Poppins-Bold" : "Poppins",
                        color: descColor ??
                            Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (postFix == null)
                Icon(IconlyLight.arrow_right_2,
                    color: Theme.of(context).colorScheme.primary)
              else
                postFix!
            ],
          ),
        ),
      ),
    );
  }
}

class CustomSliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final double sliderValue;
  final double max;
  final double min;
  final String? label;
  final double? divisions;
  final Function(double value) onChanged;
  final Function(double value)? onChangedEnd;

  const CustomSliderTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.sliderValue,
    this.label,
    required this.onChanged,
    this.onChangedEnd,
    required this.max,
    this.divisions,
    this.min = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnymexOnTapAdv(
      onKeyEvent: (p0, e) {
        if (e is KeyDownEvent) {
          double step = (max - min) / (divisions ?? (max - min));

          if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
            double newValue = (sliderValue + step).clamp(min, max);
            onChanged(newValue);
            return KeyEventResult.handled;
          } else if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
            double newValue = (sliderValue - step).clamp(min, max);
            onChanged(newValue);
            return KeyEventResult.handled;
          }
        } else if (e is KeyUpEvent) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        child: Column(
          children: [
            Row(
              children: [
                AnymexIcon(icon,
                    size: 30, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                children: [
                  AnymexText(
                    text: sliderValue % 1 == 0
                        ? sliderValue.toInt().toString()
                        : sliderValue.toStringAsFixed(1),
                    variant: TextVariant.semiBold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomSlider(
                      focusNode: FocusNode(
                          canRequestFocus: false, skipTraversal: true),
                      value: double.parse(sliderValue.toStringAsFixed(1)),
                      onChanged: onChanged,
                      max: max,
                      min: min,
                      label: label ?? sliderValue.toStringAsFixed(1),
                      onDragEnd: onChangedEnd,
                      glowBlurMultiplier: 1,
                      glowSpreadMultiplier: 1,
                      divisions: divisions?.toInt() ?? (max * 10).toInt(),
                      customValueIndicatorSize: RoundedSliderValueIndicator(
                          Theme.of(context).colorScheme,
                          width: 40,
                          height: 40,
                          radius: 50),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnymexText(
                    text: max % 1 == 0
                        ? max.toInt().toString()
                        : max.toStringAsFixed(1),
                    variant: TextVariant.semiBold,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

extension TVSupport on Widget {
  AnymexOnTap tvSupport() {
    return AnymexOnTap(child: this);
  }
}
