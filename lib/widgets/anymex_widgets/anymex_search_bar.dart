import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class AnymeXSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autoFocus;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<Widget>? trailing;
  final double height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? contentPadding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  const AnymeXSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search...',
    this.onSubmitted,
    this.onChanged,
    this.onClear,
    this.onTap,
    this.readOnly = false,
    this.autoFocus = false,
    this.prefixIcon,
    this.suffixIcon,
    this.trailing,
    this.height = 44,
    this.padding,
    this.contentPadding,
    this.borderRadius = 22,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  State<AnymeXSearchBar> createState() => _AnymeXSearchBarState();
}

class _AnymeXSearchBarState extends State<AnymeXSearchBar> {
  late TextEditingController _effectiveController;

  @override
  void initState() {
    super.initState();
    _effectiveController = widget.controller ?? TextEditingController();
  }

  @override
  void didUpdateWidget(AnymeXSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _effectiveController = widget.controller ?? TextEditingController();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: SizedBox(
        height: widget.height,
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _effectiveController,
          builder: (context, value, child) {
            final isNotEmpty = value.text.isNotEmpty;

            Widget? suffix;
            if (widget.suffixIcon != null) {
              suffix = widget.suffixIcon;
            } else if (isNotEmpty) {
              suffix = IconButton(
                onPressed: () {
                  _effectiveController.clear();
                  widget.onChanged?.call('');
                  widget.onClear?.call();
                },
                icon: Icon(
                  Icons.cancel_rounded,
                  size: 18,
                  color: colors.onSurface.withOpacity(0.5),
                ),
              );
            }

            final hasTrailing = widget.trailing != null && widget.trailing!.isNotEmpty;

            Widget searchInput = TextField(
              controller: _effectiveController,
              focusNode: widget.focusNode,
              readOnly: widget.readOnly,
              onTap: widget.onTap,
              autofocus: widget.autoFocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: widget.backgroundColor ??
                    colors.surfaceContainerHighest.withOpacity(0.35),
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  color: colors.onSurface.withOpacity(0.45),
                ),
                prefixIcon: widget.prefixIcon ??
                    Icon(
                      IconlyLight.search,
                      size: 18,
                      color: colors.onSurface.withOpacity(0.5),
                    ),
                suffixIcon: suffix,
                contentPadding: widget.contentPadding ??
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(
                    color: widget.borderColor ??
                        colors.onSurface.withOpacity(0.08),
                    width: 0.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(
                    color: colors.primary.withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
              ),
            );

            if (!hasTrailing) {
              return searchInput;
            }

            return Row(
              children: [
                Expanded(child: searchInput),
                ...widget.trailing!,
              ],
            );
          },
        ),
      ),
    );
  }
}
