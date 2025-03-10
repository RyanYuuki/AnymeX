import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnymexExpansionTile extends StatelessWidget {
  final String title;
  final Widget content;
  final bool initialExpanded;

  AnymexExpansionTile({
    super.key,
    required this.title,
    required this.content,
    this.initialExpanded = false,
  });

  final RxBool _isExpanded = false.obs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnymexCard(
      child: ExpansionTile(
        shape: ShapeBorder.lerp(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          1,
        ),
        title: AnymexText(
          text: title,
          size: 16,
          variant: TextVariant.semiBold,
          color: colorScheme.primary,
        ),
        initiallyExpanded: initialExpanded,
        onExpansionChanged: (expanded) => _isExpanded.value = expanded,
        childrenPadding: const EdgeInsets.all(8),
        children: [content],
      ),
    );
  }
}

class AnymexCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const AnymexCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = Get.find<Settings>();
    return Card(
      color: settings.disableGradient
          ? colorScheme.surfaceContainerLow
          : colorScheme.surfaceContainerLow.withOpacity(0.3),
      elevation: 2,
      shadowColor: colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(0.0),
        child: child,
      ),
    );
  }
}
