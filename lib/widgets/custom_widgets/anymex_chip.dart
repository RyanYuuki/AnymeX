import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnymexChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool e) onSelected;
  final bool showCheck;

  const AnymexChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.showCheck = true,
  });

  BoxShadow glowingShadow(BuildContext context) {
    final controller = Get.find<Settings>();
    if (controller.glowMultiplier == 0.0) {
      return const BoxShadow(color: Colors.transparent);
    } else {
      return BoxShadow(
        color: Theme.of(context).colorScheme.primary.withOpacity(
            Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.2),
        blurRadius: 20.0.multiplyBlur(),
        spreadRadius:
            -1.0.multiplyGlow(), // Negative spread makes shadow smaller
        offset: const Offset(0, 0), // Centered shadow
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [glowingShadow(context)]),
      child: FilterChip(
        selected: isSelected,
        onSelected: onSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        selectedColor: Theme.of(context).colorScheme.primary,
        side: BorderSide.none,
        showCheckmark: showCheck,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class AnymexIconChip extends StatelessWidget {
  final Widget icon;
  final bool isSelected;
  final Function(bool e) onSelected;
  final bool showCheck;

  const AnymexIconChip(
      {super.key,
      required this.icon,
      required this.isSelected,
      required this.onSelected,
      this.showCheck = true});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: isSelected,
      onSelected: onSelected,
      showCheckmark: showCheck,
      label: icon,
      checkmarkColor: isSelected
          ? Theme.of(context).colorScheme.onPrimary
          : Theme.of(context).colorScheme.onSurfaceVariant,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      selectedColor: Theme.of(context).colorScheme.primary,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
