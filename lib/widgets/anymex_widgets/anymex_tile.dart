import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tabbar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:anymex/widgets/common/anymex_slider_m3.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/tile_icon_shapes.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

enum TileStyle { classic, modern }

class AnymeXTileScope extends InheritedWidget {
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final TileStyle? style;
  final M3EShapeKind? iconShape;

  const AnymeXTileScope({
    super.key,
    this.borderRadius,
    this.backgroundColor,
    this.style,
    this.iconShape,
    required super.child,
  });

  static AnymeXTileScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AnymeXTileScope>();
  }

  @override
  bool updateShouldNotify(AnymeXTileScope oldWidget) {
    return borderRadius != oldWidget.borderRadius ||
        backgroundColor != oldWidget.backgroundColor ||
        style != oldWidget.style ||
        iconShape != oldWidget.iconShape;
  }
}

class AnymeXTile extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final Widget? badge;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final bool showChevron;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool enabled;
  final Widget? customContent;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final int? maxLines;
  final bool autoResize;
  final bool isCheckbox;
  final bool isRadio;
  final TileStyle? style;
  final Color? backgroundColor;
  final M3EShapeKind? iconShape;

  const AnymeXTile({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.badge,
    this.onTap,
    this.onLongPress,
    this.iconColor,
    this.iconBackgroundColor,
    this.showChevron = true,
    this.borderRadius,
    this.padding,
    this.enabled = true,
    this.customContent,
    this.maxLines = 4,
    this.autoResize = true,
    this.isCheckbox = false,
    this.isRadio = false,
    this.titleStyle,
    this.subtitleStyle,
    this.style,
    this.backgroundColor,
    this.iconShape,
  });

  AnymeXTile copyWith({
    IconData? icon,
    Widget? leading,
    String? title,
    String? subtitle,
    Widget? subtitleWidget,
    Widget? trailing,
    Widget? badge,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Color? iconColor,
    Color? iconBackgroundColor,
    bool? showChevron,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    bool? enabled,
    Widget? customContent,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    int? maxLines,
    bool? autoResize,
    bool? isCheckbox,
    bool? isRadio,
    TileStyle? style,
    Color? backgroundColor,
    M3EShapeKind? iconShape,
  }) {
    return AnymeXTile(
      key: key,
      icon: icon ?? this.icon,
      leading: leading ?? this.leading,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      subtitleWidget: subtitleWidget ?? this.subtitleWidget,
      trailing: trailing ?? this.trailing,
      badge: badge ?? this.badge,
      onTap: onTap ?? this.onTap,
      onLongPress: onLongPress ?? this.onLongPress,
      iconColor: iconColor ?? this.iconColor,
      iconBackgroundColor: iconBackgroundColor ?? this.iconBackgroundColor,
      showChevron: showChevron ?? this.showChevron,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      enabled: enabled ?? this.enabled,
      customContent: customContent ?? this.customContent,
      titleStyle: titleStyle ?? this.titleStyle,
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      maxLines: maxLines ?? this.maxLines,
      autoResize: autoResize ?? this.autoResize,
      isCheckbox: isCheckbox ?? this.isCheckbox,
      isRadio: isRadio ?? this.isRadio,
      style: style ?? this.style,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      iconShape: iconShape ?? this.iconShape,
    );
  }

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
    TileStyle? style,
    Color? backgroundColor,
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
      style: style,
      backgroundColor: backgroundColor,
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
    TileStyle? style,
    Color? backgroundColor,
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
      style: style,
      backgroundColor: backgroundColor,
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
    TileStyle? style,
    Color? backgroundColor,
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
      style: style,
      backgroundColor: backgroundColor,
      trailing: Builder(
        builder: (context) {
          final primary = Theme.of(context).colorScheme.primary;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: primary.opaque(0.12, iReallyMeanIt: true),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AnymeXText(
              formatValue(value),
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
    Widget? subtitleWidget,
    required bool selected,
    required VoidCallback? onTap,
    VoidCallback? onLongPress,
    Color? iconColor,
    Color? iconBackgroundColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    bool enabled = true,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    TileStyle? style,
    Color? backgroundColor,
    M3EShapeKind? iconShape,
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
      onLongPress: enabled ? onLongPress : null,
      titleStyle: titleStyle,
      subtitleStyle: subtitleStyle,
      subtitleWidget: subtitleWidget,
      isRadio: true,
      style: style,
      backgroundColor: backgroundColor,
      iconShape: iconShape,
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
                color: selected
                    ? colors.primary
                    : colors.onSurface.opaque(0.24, iReallyMeanIt: true),
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
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    TileStyle? style,
    Color? backgroundColor,
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
      titleStyle: titleStyle,
      subtitleStyle: subtitleStyle,
      isCheckbox: true,
      style: style,
      backgroundColor: backgroundColor,
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
                color: value
                    ? colors.primary
                    : colors.onSurface.opaque(0.24, iReallyMeanIt: true),
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
    TileStyle? style,
    Color? backgroundColor,
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
      style: style,
      backgroundColor: backgroundColor,
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
    TileStyle? style,
    Color? backgroundColor,
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
        style: style,
        backgroundColor: backgroundColor,
      );

  static AnymeXTile pills<T>({
    Key? key,
    IconData? icon,
    Widget? leading,
    required String title,
    String? subtitle,
    required T value,
    required List<T> options,
    String Function(T)? optionLabelTransformer,
    String Function(T)? optionDescriptionTransformer,
    required ValueChanged<T>? onChanged,
    Color? iconColor,
    Color? iconBackgroundColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    bool enabled = true,
    bool expand = true,
    bool wrap = false,
    PillStyle pillStyle = PillStyle.connective,
    TileStyle? style,
    Color? backgroundColor,
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
      style: style,
      backgroundColor: backgroundColor,
      customContent: Builder(
        builder: (context) => _buildPillsSelectorContent<T>(
          context: context,
          value: value,
          options: options,
          optionLabelTransformer: optionLabelTransformer,
          optionDescriptionTransformer: optionDescriptionTransformer,
          onChanged: enabled ? onChanged : null,
          expand: expand,
          wrap: wrap,
          pillStyle: pillStyle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tileScope = AnymeXTileScope.of(context);
    final effectiveStyle = style ??
        tileScope?.style ??
        (settingsController.tileStyle == 1
            ? TileStyle.modern
            : TileStyle.classic);
    final isModern = effectiveStyle == TileStyle.modern;
    final effectiveShapeKind = iconShape ??
        tileScope?.iconShape ??
        getTileIconShapeKind(settingsController.tileIconShape);
    final shapeBgColor = iconBackgroundColor ??
        (isModern
            ? colors.surfaceContainerHighest.opaque(0.5)
            : colors.primary.opaque(0.12, iReallyMeanIt: true));
    final shapeIconColor = iconColor ?? colors.primary;
    final double iconContainerSize = isModern ? 42 : 36;
    final double iconGlyphSize = isModern ? 19 : 20;

    final Widget leadingWidget = leading ??
        (icon != null
            ? (effectiveShapeKind != null
                ? M3EShapeContainer(
                    kind: effectiveShapeKind,
                    width: iconContainerSize,
                    height: iconContainerSize,
                    color: shapeBgColor,
                    child: Center(
                      child: Icon(
                        icon,
                        size: iconGlyphSize,
                        color: shapeIconColor,
                      ),
                    ),
                  )
                : Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      color: shapeBgColor,
                      shape: isModern ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: isModern ? null : BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: iconGlyphSize,
                        color: shapeIconColor,
                      ),
                    ),
                  ))
            : const SizedBox.shrink());

    final Widget trailingWidget = trailing ??
        (showChevron && onTap != null
            ? (isModern
                ? CustomPaint(
                    size: const Size(14, 14),
                    painter: _ModernTileChevronPainter(
                      color: colors.onSurface.opaque(0.35, iReallyMeanIt: true),
                      strokeWidth: 1.8,
                    ),
                  )
                : Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.onSurface.opaque(0.35, iReallyMeanIt: true),
                  ))
            : const SizedBox.shrink());

    final radius = borderRadius ??
        tileScope?.borderRadius ??
        (isModern ? BorderRadius.circular(18.0) : BorderRadius.zero);
    final cardBg = backgroundColor ??
        tileScope?.backgroundColor ??
        (isModern
            ? colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true)
            : null);

    final contentWidget = Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isModern ? 13 : 12,
          ),
      decoration: BoxDecoration(
        color: cardBg,
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
                    if (badge != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: AnymeXText(
                              title,
                              size: 14.5,
                              maxLines: maxLines ?? 4,
                              autoResize: autoResize,
                              variant: isModern
                                  ? TextVariant.bold
                                  : TextVariant.semiBold,
                              color: enabled
                                  ? colors.onSurface
                                  : colors.onSurface
                                      .opaque(0.4, iReallyMeanIt: true),
                              style: titleStyle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          badge!,
                        ],
                      )
                    else
                      AnymeXText(
                        title,
                        size: 14.5,
                        maxLines: maxLines ?? 4,
                        autoResize: autoResize,
                        variant: isModern
                            ? TextVariant.bold
                            : TextVariant.semiBold,
                        color: enabled
                            ? colors.onSurface
                            : colors.onSurface
                                .opaque(0.4, iReallyMeanIt: true),
                        style: titleStyle,
                      ),
                    if (subtitleWidget != null) ...[
                      const SizedBox(height: 2),
                      subtitleWidget!,
                    ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      AnymeXText(
                        subtitle!,
                        size: isModern ? 11.5 : 12,
                        variant: TextVariant.regular,
                        color: isModern
                            ? colors.onSurface.opaque(0.6, iReallyMeanIt: true)
                            : colors.onSurface
                                .opaque(0.45, iReallyMeanIt: true),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: subtitleStyle,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailingWidget,
            ],
          ),
          if (customContent != null) ...[
            customContent!,
          ],
        ],
      ),
    );

    final tileWidget = ((onTap != null || onLongPress != null) && enabled)
        ? (isModern
            ? Material(
                color: Colors.transparent,
                borderRadius: radius,
                child: InkWell(
                  borderRadius: radius,
                  onTap: onTap,
                  onLongPress: onLongPress,
                  child: contentWidget,
                ),
              )
            : Material(
                color: Colors.transparent,
                borderRadius: radius,
                child: AnymexOnTap(
                  margin: 0,
                  scale: 0.98,
                  onTap: onTap,
                  onLongPress: onLongPress,
                  child: contentWidget,
                ),
              ))
        : Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: contentWidget,
          );

    return HighlightDecorator(
      title: title,
      child: tileWidget,
    );
  }
}

class _ModernTileChevronPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _ModernTileChevronPainter({
    required this.color,
    this.strokeWidth = 1.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(size.width * 0.35, size.height * 0.22);
    path.lineTo(size.width * 0.65, size.height * 0.5);
    path.lineTo(size.width * 0.35, size.height * 0.78);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ModernTileChevronPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
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

Widget _buildPillsSelectorContent<T>({
  required BuildContext context,
  required T value,
  required List<T> options,
  String Function(T)? optionLabelTransformer,
  String Function(T)? optionDescriptionTransformer,
  ValueChanged<T>? onChanged,
  bool expand = true,
  bool wrap = false,
  PillStyle pillStyle = PillStyle.connective,
}) {
  final colors = context.colors;
  final currentDescription = optionDescriptionTransformer?.call(value);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: AnymeXPills(
          style: pillStyle,
          expandEqually: expand,
          wrap: expand ? false : wrap,
          scrollable: expand ? false : !wrap,
          items: options.map((opt) {
            final label = optionLabelTransformer != null
                ? optionLabelTransformer(opt)
                : opt.toString();
            return PillItem(
              label: label,
              isSelected: opt == value,
              onTap: () {
                if (onChanged != null) {
                  onChanged(opt);
                }
              },
            );
          }).toList(),
        ),
      ),
      if (currentDescription != null && currentDescription.isNotEmpty) ...[
        const SizedBox(height: 6),
        AnymeXText(
          currentDescription,
          size: 11.5,
          color: colors.onSurface.opaque(0.55, iReallyMeanIt: true),
          maxLines: 4,
        ),
      ],
    ],
  );
}
