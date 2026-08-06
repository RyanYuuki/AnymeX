import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShaderOsd extends StatelessWidget {
  final PlayerController controller;
  const ShaderOsd({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.showShaderOsd.value) return const SizedBox.shrink();
      final shaderName = controller.activeShaderName.value;
      final isCleared = shaderName.isEmpty || shaderName == "Default";
      return Positioned(
        right: 24,
        top: 80,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: controller.showShaderOsd.value ? 1.0 : 0.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCleared
                    ? Colors.white24
                    : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCleared ? Icons.blur_off_rounded : Icons.photo_filter_rounded,
                  color: isCleared
                      ? Colors.white70
                      : Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  isCleared ? 'Shaders Disabled' : shaderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
