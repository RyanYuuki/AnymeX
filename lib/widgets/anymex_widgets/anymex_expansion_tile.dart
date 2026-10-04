import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';

class AnymeXExpansionTile extends StatefulWidget {
  final String title;
  final Widget content;
  final bool initialExpanded;
  final Widget? leading;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String? subtitle;
  final Widget? trailing;
  final ValueChanged<bool>? onExpansionChanged;
  final bool showDivider;
  final bool useCard;
  final bool useContentContainer;
  final EdgeInsetsGeometry? contentMargin;
  final EdgeInsetsGeometry? padding;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const AnymeXExpansionTile({
    super.key,
    required this.title,
    required this.content,
    this.initialExpanded = true,
    this.leading,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.subtitle,
    this.trailing,
    this.onExpansionChanged,
    this.showDivider = false,
    this.useCard = true,
    this.useContentContainer = true,
    this.contentMargin,
    this.padding,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  State<AnymeXExpansionTile> createState() => _AnymeXExpansionTileState();
}

class _AnymeXExpansionTileState extends State<AnymeXExpansionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconTurns;
  late final Animation<double> _heightFactor;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _iconTurns = _controller.drive(
      Tween<double>(begin: 0.0, end: 0.5).chain(
        CurveTween(curve: Curves.easeInOutCubic),
      ),
    );
    _heightFactor = _controller.drive(
      CurveTween(curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final highlightProvider = SettingsHighlightProvider.of(context);
    final shouldExpand = widget.initialExpanded ||
        (highlightProvider?.expansionTitle == widget.title);
    if (shouldExpand && !_isExpanded) {
      _isExpanded = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    widget.onExpansionChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final Widget leadingWidget = widget.leading != null
        ? (widget.leading is Icon
            ? Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.iconBackgroundColor ??
                      colors.primary.opaque(0.12, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  (widget.leading as Icon).icon,
                  size: 20,
                  color: (widget.leading as Icon).color ??
                      widget.iconColor ??
                      colors.primary,
                ),
              )
            : widget.leading!)
        : (widget.icon != null
            ? Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.iconBackgroundColor ??
                      colors.primary.opaque(0.12, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: widget.iconColor ?? colors.primary,
                ),
              )
            : const SizedBox.shrink());

    final header = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpansion,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (widget.leading != null || widget.icon != null) ...[
                leadingWidget,
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnymeXText(
                      widget.title,
                      size: 14.5,
                      maxLines: 4,
                      variant: TextVariant.semiBold,
                      color: colors.onSurface,
                      style: widget.titleStyle,
                    ),
                    if (widget.subtitle != null &&
                        widget.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      AnymeXText(
                        widget.subtitle!,
                        size: 12,
                        variant: TextVariant.regular,
                        color:
                            colors.onSurface.opaque(0.45, iReallyMeanIt: true),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: widget.subtitleStyle,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (widget.trailing != null)
                widget.trailing!
              else
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isExpanded
                        ? colors.primary.opaque(0.15, iReallyMeanIt: true)
                        : colors.surfaceContainerHighest
                            .opaque(0.4, iReallyMeanIt: true),
                    shape: BoxShape.circle,
                  ),
                  child: RotationTransition(
                    turns: _iconTurns,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: _isExpanded
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final Widget effectiveContent = widget.useContentContainer
        ? Container(
            margin: widget.contentMargin ??
                const EdgeInsets.fromLTRB(12, 0, 12, 8),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest
                  .opaque(0.25, iReallyMeanIt: true),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.onSurface.opaque(0.06, iReallyMeanIt: true),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: widget.content,
            ),
          )
        : widget.content;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        ClipRect(
          child: AnimatedBuilder(
            animation: _controller.view,
            builder: (context, child) {
              return Align(
                alignment: Alignment.topCenter,
                heightFactor: _heightFactor.value,
                child: child,
              );
            },
            child: ExpansionSectionScope(
              sectionTitle: widget.title,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showDivider) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          height: 1,
                          thickness: 0.6,
                          color: colors.onSurface
                              .opaque(0.08, iReallyMeanIt: true),
                        ),
                      ),
                    ],
                    effectiveContent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (!widget.useCard) {
      return body;
    }

    return AnymeXCard(
      clipBehavior: Clip.antiAlias,
      child: body,
    );
  }
}

class AnymeXCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool enableAnimation;
  final Color? color;
  final ShapeBorder? shape;
  final Clip? clipBehavior;

  const AnymeXCard({
    super.key,
    required this.child,
    this.padding,
    this.enableAnimation = false,
    this.color,
    this.shape,
    this.clipBehavior,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<Settings>();
    final cardColor = color ??
        (settings.disableGradient
            ? context.colors.surfaceContainerLow
            : context.colors.surfaceContainerLow.opaque(0.35));

    return Card(
      clipBehavior: clipBehavior ?? Clip.antiAlias,
      color: cardColor,
      elevation: 0,
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: context.colors.outline.opaque(0.08),
            ),
          ),
      child: enableAnimation
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: padding ?? const EdgeInsets.all(0.0),
              child: child,
            )
          : Padding(
              padding: padding ?? const EdgeInsets.all(0.0),
              child: child,
            ),
    );
  }
}
