import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

class CustomSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool switchValue;
  final EdgeInsets padding;
  final Function(bool value) onChanged;

  const CustomSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.switchValue,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
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
              child: Switch(value: switchValue, onChanged: onChanged))
        ],
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

  const CustomTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.prefix,
    this.postFix,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Row(
          children: [
            if (prefix == null)
              Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary)
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
                      color: Theme.of(context)
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
  final double? divisions;
  final Function(double value) onChanged;

  const CustomSliderTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.sliderValue,
    required this.onChanged,
    required this.max,
    this.divisions,
    this.min = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon,
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
          Row(
            children: [
              Text(
                sliderValue % 1 == 0
                    ? sliderValue.toInt().toString()
                    : sliderValue.toStringAsFixed(1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomSlider(
                  value: double.parse(sliderValue.toStringAsFixed(1)),
                  onChanged: onChanged,
                  max: max,
                  min: min,
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
              Text(
                max % 1 == 0 ? max.toInt().toString() : max.toStringAsFixed(1),
              )
            ],
          )
        ],
      ),
    );
  }
}
