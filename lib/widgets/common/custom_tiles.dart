import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:anymex/widgets/custom_widgets/custom_icon_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconly/iconly.dart';

class SettingsHighlightProvider extends InheritedWidget {
  final String highlightTitle;
  final String? expansionTitle;

  const SettingsHighlightProvider({
    super.key,
    required this.highlightTitle,
    this.expansionTitle,
    required super.child,
  });

  static SettingsHighlightProvider? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SettingsHighlightProvider>();
  }

  @override
  bool updateShouldNotify(SettingsHighlightProvider oldWidget) {
    return highlightTitle != oldWidget.highlightTitle ||
        expansionTitle != oldWidget.expansionTitle;
  }
}

class ExpansionSectionScope extends InheritedWidget {
  final String sectionTitle;

  const ExpansionSectionScope(
      {super.key, required this.sectionTitle, required super.child});

  static String? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ExpansionSectionScope>()
      ?.sectionTitle;

  @override
  bool updateShouldNotify(ExpansionSectionScope old) =>
      sectionTitle != old.sectionTitle;
}

class HighlightDecorator extends StatefulWidget {
  final String title;
  final Widget child;

  const HighlightDecorator(
      {super.key, required this.title, required this.child});

  @override
  State<HighlightDecorator> createState() => _HighlightDecoratorState();
}

class _HighlightDecoratorState extends State<HighlightDecorator> {
  bool _scrolled = false;

  bool _isTarget(BuildContext context) {
    final provider = SettingsHighlightProvider.of(context);
    if (provider == null || provider.highlightTitle != widget.title) {
      return false;
    }
    if (provider.expansionTitle != null) {
      return ExpansionSectionScope.of(context) == provider.expansionTitle;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTarget());
  }

  Future<void> _scrollToTarget() async {
    if (!mounted || _scrolled) return;

    for (var attempt = 0; attempt < 3; attempt++) {
      await Future.delayed(Duration(milliseconds: 180 + (attempt * 120)));
      if (!mounted || _scrolled) return;
      if (!_isTarget(context)) continue;

      _scrolled = true;
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutCubic,
        alignment: 0.42,
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isTarget(context)) return widget.child;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        begin: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        end: Colors.transparent,
      ),
      duration: const Duration(seconds: 3),
      curve: Curves.easeInCirc,
      builder: (context, color, child) {
        return Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class CustomSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool switchValue;
  final EdgeInsets padding;
  final bool disabled;
  final ValueChanged<bool> onChanged;

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
    final content = Padding(
      padding: padding,
      child: Row(
        children: [
          AnymexIcon(icon, size: 30, color: context.colors.primary),
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
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.opaque(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
              decoration: BoxDecoration(
                boxShadow:
                    switchValue && !disabled ? [glowingShadow(context)] : [],
              ),
              child: Switch(
                value: switchValue,
                onChanged: disabled ? (_) {} : onChanged,
                activeColor: context.colors.primary,
                inactiveTrackColor: context.colors.surfaceContainerHighest,
              ))
        ],
      ),
    );

    return HighlightDecorator(
        title: title,
        child: Opacity(
          opacity: disabled ? 0.4 : 1.0,
          child: AnymexOnTap(
            onTap: disabled ? () {} : () => onChanged.call(!switchValue),
            child: content,
          ),
        ));
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
    return HighlightDecorator(
        title: title,
        child: AnymexOnTap(
          onTap: onTap,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: padding ?? 20.0, vertical: 10.0),
              child: Row(
                children: [
                  if (prefix == null)
                    AnymexIcon(icon, size: 30, color: context.colors.primary)
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
                            color: context.colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: (isDescBold ?? false)
                                ? "Poppins-Bold"
                                : "Poppins",
                            color: descColor ??
                                Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .opaque(0.6, iReallyMeanIt: true),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (postFix == null)
                    Icon(IconlyLight.arrow_right_2,
                        color: context.colors.primary)
                  else
                    postFix!
                ],
              ),
            ),
          ),
        ));
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
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangedEnd;

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
    return HighlightDecorator(
        title: title,
        child: AnymexOnTapAdv(
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
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            child: Column(
              children: [
                Row(
                  children: [
                    AnymexIcon(icon, size: 30, color: context.colors.primary),
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
                              color: context.colors.onSurface,
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
                                  .opaque(0.6),
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
                              context.colors,
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
        ));
  }
}
