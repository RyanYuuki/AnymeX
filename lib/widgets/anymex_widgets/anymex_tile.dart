import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tabbar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/anymex_slider_m3.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';

class AnymeXTile extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final bool showChevron;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool enabled;
  final Widget? customContent;

  const AnymeXTile({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
    this.showChevron = true,
    this.borderRadius,
    this.padding,
    this.enabled = true,
    this.customContent,
    this.maxLines,
  });

  final int? maxLines;

  static Widget _buildSwitch(
    BuildContext context,
    bool value,
    bool enabled,
    ValueChanged<bool>? onChanged,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Switch(
      value: value,
      onChanged: enabled ? onChanged : null,
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          if (value) {
            return primary.opaque(0.75, iReallyMeanIt: true);
          }
          return theme.colorScheme.onSurface.opaque(0.2, iReallyMeanIt: true);
        }
        if (states.contains(WidgetState.selected)) {
          return theme.colorScheme.onPrimary;
        }
        return theme.colorScheme.onSurface.opaque(0.35, iReallyMeanIt: true);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          if (value) {
            return primary.opaque(0.35, iReallyMeanIt: true);
          }
          return theme.colorScheme.surfaceContainerHighest
              .opaque(0.5, iReallyMeanIt: true);
        }
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return theme.colorScheme.surfaceContainerHighest;
      }),
    );
  }

  factory AnymeXTile.toggle({
    Key? key,
    IconData? icon,
    Widget? leading,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    Color? iconColor,
    Color? iconBackgroundColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    bool enabled = true,
    Widget? child,
  }) {
    return AnymeXTile(
      key: key,
      icon: icon,
      leading: leading,
      title: title,
      subtitle: subtitle,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      borderRadius: borderRadius,
      padding: padding,
      enabled: enabled,
      showChevron: false,
      onTap: enabled && onChanged != null ? () => onChanged(!value) : null,
      trailing: Builder(
        builder: (context) => _buildSwitch(context, value, enabled, onChanged),
      ),
      customContent: child != null
          ? AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: value
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: child,
                    )
                  : const SizedBox.shrink(),
            )
          : null,
    );
  }

  factory AnymeXTile.expandableToggle({
    Key? key,
    IconData? icon,
    Widget? leading,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required Widget child,
    Color? iconColor,
    Color? iconBackgroundColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    bool enabled = true,
  }) {
    return AnymeXTile.toggle(
      key: key,
      icon: icon,
      leading: leading,
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: onChanged,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      borderRadius: borderRadius,
      padding: padding,
      enabled: enabled,
      child: child,
    );
  }

  factory AnymeXTile.slider({
    Key? key,
    IconData? icon,
    Widget? leading,
    required String title,
    String? subtitle,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double>? onChanged,
    String Function(double)? valueTransformer,
    Color? iconColor,
    Color? iconBackgroundColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    bool enabled = true,
  }) {
    String formatValue(double v) => valueTransformer != null
        ? valueTransformer(v)
        : (divisions != null ? v.toInt().toString() : v.toStringAsFixed(1));

    var localValue = value.clamp(min, max);

    return AnymeXTile(
      key: key,
      icon: icon,
      leading: leading,
      title: title,
      subtitle: subtitle,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      borderRadius: borderRadius,
      padding: padding ??
          const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
      enabled: enabled,
      showChevron: false,
      trailing: Builder(
        builder: (context) {
          final primary = Theme.of(context).colorScheme.primary;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),

            ),
            child: AnymeXText(
              text: formatValue(value),
              size: 12,
              variant: TextVariant.semiBold,
              color: primary,
            ),
          );
        },
      ),
      customContent: StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: AnymeXSliderM3(
              value: localValue,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged == null || !enabled
                  ? null
                  : (v) {
                      setState(() => localValue = v);
                      onChanged(v);
                    },
            ),
          );
        },
      ),
    );
  }

  factory AnymeXTile.radio({
    Key? key,
    IconData? icon,
    Widget? leading,
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback? onTap,
    Color? iconColor,
    Color? iconBackgroundColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    bool enabled = true,
  }) {
    return AnymeXTile(
      key: key,
      icon: icon,
      leading: leading,
      title: title,
      subtitle: subtitle,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      borderRadius: borderRadius,
      padding: padding,
      enabled: enabled,
      showChevron: false,
      onTap: enabled ? onTap : null,
      trailing: Builder(
        builder: (context) {
          final colors = context.colors;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? colors.primary : colors.onSurface.withOpacity(0.24),
                width: 2,
              ),
              color: selected ? colors.primary : Colors.transparent,
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  factory AnymeXTile.checkbox({
    Key? key,
    IconData? icon,
    Widget? leading,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    Color? iconColor,
    Color? iconBackgroundColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    bool enabled = true,
  }) {
    return AnymeXTile(
      key: key,
      icon: icon,
      leading: leading,
      title: title,
      subtitle: subtitle,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      borderRadius: borderRadius,
      padding: padding,
      enabled: enabled,
      showChevron: false,
      onTap: enabled && onChanged != null ? () => onChanged(!value) : null,
      trailing: Builder(
        builder: (context) {
          final colors = context.colors;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? colors.primary : colors.onSurface.withOpacity(0.24),
                width: 2,
              ),
              color: value ? colors.primary : Colors.transparent,
            ),
            child: value
                ? Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: colors.onPrimary,
                  )
                : null,
          );
        },
      ),
    );
  }


  static Widget segmented<T>({
    Key? key,
    IconData? icon,
    Widget? leading,
    required String title,
    String? subtitle,
    required T value,
    required List<T> options,
    String Function(T)? optionLabelTransformer,
    required ValueChanged<T>? onChanged,
    Color? iconColor,
    Color? iconBackgroundColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    bool enabled = true,
  }) {
    return AnymeXTile(
      key: key,
      icon: icon,
      leading: leading,
      title: title,
      subtitle: subtitle,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      borderRadius: borderRadius,
      padding: padding,
      enabled: enabled,
      showChevron: false,
      customContent: _SegmentedContent<T>(
        value: value,
        options: options,
        optionLabelTransformer: optionLabelTransformer,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  static Widget segmentedTile<T>({
    Key? key,
    IconData? icon,
    Widget? leading,
    required String title,
    String? subtitle,
    required T value,
    required List<T> options,
    String Function(T)? optionLabelTransformer,
    required ValueChanged<T>? onChanged,
    Color? iconColor,
    Color? iconBackgroundColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    bool enabled = true,
  }) =>
      AnymeXTile.segmented<T>(
        key: key,
        icon: icon,
        leading: leading,
        title: title,
        subtitle: subtitle,
        value: value,
        options: options,
        optionLabelTransformer: optionLabelTransformer,
        onChanged: onChanged,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        borderRadius: borderRadius,
        padding: padding,
        enabled: enabled,
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final Widget leadingWidget = leading ??
        (icon != null
            ? Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBackgroundColor ??
                      colors.primary.opaque(0.12, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? colors.primary,
                ),
              )
            : const SizedBox.shrink());

    final Widget trailingWidget = trailing ??
        (showChevron && onTap != null
            ? Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.onSurface.opaque(0.35, iReallyMeanIt: true),
              )
            : const SizedBox.shrink());

    final radius = borderRadius ?? BorderRadius.zero;

    final contentWidget = Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: radius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (leading != null || icon != null) ...[
                leadingWidget,
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnymeXText(
                      text: title,
                      size: 14.5,
                      maxLines: maxLines ?? 2,
                      variant: TextVariant.semiBold,
                      color: enabled
                          ? colors.onSurface
                          : colors.onSurface.opaque(0.4, iReallyMeanIt: true),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      AnymeXText(
                        text: subtitle!,
                        size: 12,
                        variant: TextVariant.regular,
                        color:
                            colors.onSurface.opaque(0.45, iReallyMeanIt: true),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailingWidget,
            ],
          ),
          if (customContent != null) ...[
            customContent!,
          ],
        ],
      ),
    );

    if (onTap != null && enabled) {
      return Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: AnymexOnTap(
          margin: 0,
          scale: 0.98,
          onTap: onTap,
          child: contentWidget,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: contentWidget,
    );
  }
}




class _SegmentedContent<T> extends StatelessWidget {
  final T value;
  final List<T> options;
  final String Function(T)? optionLabelTransformer;
  final ValueChanged<T>? onChanged;

  const _SegmentedContent({
    required this.value,
    required this.options,
    this.optionLabelTransformer,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIndex = options.indexOf(value);
    final labels = options
        .map((opt) => optionLabelTransformer != null
            ? optionLabelTransformer!(opt)
            : opt.toString())
        .toList();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AnymeXTabBar(
        selectTabs: labels,
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onTabSelected: (index) {
          if (onChanged != null && index >= 0 && index < options.length) {
            onChanged!(options[index]);
          }
        },
      ),
    );
  }
}
