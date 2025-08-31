import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlayerOverlay extends StatelessWidget {
  final PlayerController controller;
  const PlayerOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
                gradient: LinearGradient(
              colors: controller.showControls.value
                  ? [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.transparent
                    ]
                  : [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.transparent
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )),
          ),
        ));
  }
}
