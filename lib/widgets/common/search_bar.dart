import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
      decoration: BoxDecoration(boxShadow: [lightGlowingShadow(context)]),
      clipBehavior: Clip.antiAlias,
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor:
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
          prefixIcon: IconButton(
            icon: Icon(prefixIcon),
            onPressed: onPrefixIconPressed,
          ),
          suffix: suffixWidget,
          suffixIcon: disableIcons
              ? suffixIconWidget
              : IconButton(
                  icon: Icon(suffixIcon),
                  onPressed: onSuffixIconPressed,
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
  final VoidCallback onTap;
  final IconData prefixIcon;
  final IconData suffixIcon;
  final Widget? suffixWidget;
  final Widget? suffixIconWidget;
  final bool disableIcons;
  final String hintText;

  const TappableSearchBar({
    super.key,
    required this.onTap,
    this.prefixIcon = IconlyLight.search,
    this.suffixIcon = IconlyLight.filter,
    this.disableIcons = false,
    this.hintText = 'Search...',
    this.suffixWidget,
    this.suffixIconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
      decoration: BoxDecoration(boxShadow: [lightGlowingShadow(context)]),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.multiplyRadius()),
        onTap: onTap,
        child: Container(
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
              Icon(
                prefixIcon,
                color: Theme.of(context).hintColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnymexText(
                  text: hintText,
                  color: Theme.of(context).hintColor,
                  size: 16,
                ),
              ),
              if (suffixWidget != null) suffixWidget!,
              if (!disableIcons)
                IconButton(
                  icon: suffixIconWidget ?? Icon(suffixIcon),
                  onPressed: null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
