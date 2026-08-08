import 'package:anymex/controllers/services/widgets/widgets_builders.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Function(String) onSubmitted;
  final Function(String)? onChanged;
  final VoidCallback? onPrefixIconPressed;
  final VoidCallback? onSuffixIconPressed;
  final IconData prefixIcon;
  final IconData suffixIcon;
  final Widget? suffixIconWidget;
  final Widget? suffixWidget;
  final bool disableIcons;
  final String hintText;
  final EdgeInsets? padding;
  final bool enableGlow;
  final BoxBorder? border;

  const CustomSearchBar({
    super.key,
    this.controller,
    required this.onSubmitted,
    this.onChanged,
    this.onPrefixIconPressed,
    this.onSuffixIconPressed,
    this.prefixIcon = IconlyLight.search,
    this.suffixIcon = IconlyLight.filter,
    this.disableIcons = false,
    this.hintText = 'Search...',
    this.suffixWidget,
    this.suffixIconWidget,
    this.padding,
    this.focusNode,
    this.enableGlow = false,
    this.border,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late FocusNode _focusNode;
  final settings = Get.find<Settings>();

  @override
  void initState() {
    super.initState();
    if (settings.isTV.value) {
      _focusNode = FocusNode(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _focusNode.focusInDirection(TraversalDirection.left);
              return KeyEventResult.skipRemainingHandlers;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _focusNode.focusInDirection(TraversalDirection.right);
              return KeyEventResult.skipRemainingHandlers;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _focusNode.focusInDirection(TraversalDirection.up);
              return KeyEventResult.skipRemainingHandlers;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _focusNode.focusInDirection(TraversalDirection.down);
              return KeyEventResult.skipRemainingHandlers;
            }
          }
          return KeyEventResult.ignored;
        },
      );
    } else {
      _focusNode = FocusNode();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(16.multiplyRadius());

    return Container(
      padding: widget.padding ??
          const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: TextField(
        focusNode: widget.focusNode ?? _focusNode,
        controller: widget.controller,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.opaque(0.45, iReallyMeanIt: true),
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.opaque(0.35),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: IconButton(
            icon: Icon(
              widget.prefixIcon,
              color: theme.colorScheme.onSurface.opaque(0.6, iReallyMeanIt: true),
              size: 20,
            ),
            onPressed: widget.onPrefixIconPressed,
          ),
          suffixIcon: widget.disableIcons
              ? widget.suffixIconWidget
              : (widget.onSuffixIconPressed != null || widget.suffixIconWidget != null)
                  ? IconButton(
                      icon: widget.suffixIconWidget ??
                          Icon(
                            widget.suffixIcon,
                            color: theme.colorScheme.onSurface
                                .opaque(0.6, iReallyMeanIt: true),
                            size: 20,
                          ),
                      onPressed: widget.onSuffixIconPressed,
                    )
                  : null,
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: theme.colorScheme.primary.opaque(0.5, iReallyMeanIt: true),
              width: 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: theme.colorScheme.onSurface.opaque(0.08, iReallyMeanIt: true),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class TappableSearchBar extends StatelessWidget {
  final VoidCallback onSubmitted;
  final IconData prefixIcon;
  final String chipLabel;
  final String hintText;

  const TappableSearchBar({
    super.key,
    this.prefixIcon = IconlyLight.search,
    this.hintText = 'Search...',
    this.chipLabel = "SEARCH",
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(16.multiplyRadius());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: AnymexOnTap(
        onTap: onSubmitted,
        scale: 1,
        margin: 0,
        child: InkWell(
          onTap: onSubmitted,
          borderRadius: borderRadius,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.opaque(0.35),
              borderRadius: borderRadius,
              border: Border.all(
                color: theme.colorScheme.onSurface
                    .opaque(0.08, iReallyMeanIt: true),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                buildChip(chipLabel),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hintText,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface
                          .opaque(0.45, iReallyMeanIt: true),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Icon(
                  prefixIcon,
                  color: theme.colorScheme.onSurface
                      .opaque(0.6, iReallyMeanIt: true),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
