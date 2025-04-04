import 'package:anymex/controllers/services/widgets/widgets_builders.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

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
    this.enableGlow = true,
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
    return Container(
      padding: widget.padding ??
          const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
      decoration: BoxDecoration(
          boxShadow: widget.enableGlow ? [lightGlowingShadow(context)] : []),
      clipBehavior: Clip.antiAlias,
      child: TextField(
        focusNode: widget.focusNode ?? _focusNode,
        controller: widget.controller,
        onSubmitted: (value) {
          widget.onSubmitted(value);
        },
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          filled: true,
          fillColor:
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
          prefixIcon: IconButton(
            icon: Icon(widget.prefixIcon),
            onPressed: widget.onPrefixIconPressed,
          ),
          suffix: widget.suffixWidget,
          suffixIcon: widget.disableIcons
              ? widget.suffixIconWidget
              : IconButton(
                  icon: Icon(widget.suffixIcon),
                  onPressed: widget.onSuffixIconPressed,
                ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.multiplyRadius()),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondaryContainer,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.multiplyRadius()),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondaryContainer,
              width: 1,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
      decoration: BoxDecoration(boxShadow: [lightGlowingShadow(context)]),
      clipBehavior: Clip.antiAlias,
      child: AnymexOnTap(
        onTap: onSubmitted,
        scale: 1,
        margin: 0,
        child: InkWell(
          onTap: onSubmitted,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondaryContainer
                  .withOpacity(0.5),
              borderRadius: BorderRadius.circular(16.multiplyRadius()),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondaryContainer,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // const SizedBox(width: 12),
                // Expanded(
                //   child: AnymexText(
                //     text: hintText,
                //     color: Theme.of(context).hintColor,
                //     size: 16,
                //   ),
                // ),
                // if (suffixWidget != null) suffixWidget!,
                // if (!disableIcons)
                //   IconButton(
                //     icon: suffixIconWidget ?? Icon(suffixIcon),
                //     onPressed: null,
                //   ),
                buildChip(chipLabel),
                const SizedBox(width: 10),
                Icon(
                  prefixIcon,
                  color: Theme.of(context).hintColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
