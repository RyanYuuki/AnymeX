import 'dart:io';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class PipUi extends StatelessWidget {
  final PlayerController controller;
  const PipUi({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) {
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            windowManager.startDragging();
          }
        },
        child: Stack(
          children: [
            Center(
              child: controller.videoWidget,
            ),
            Obx(() {
              final isPlaying = controller.isPlaying.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: "Exit PiP",
                          onPressed: () => controller.togglePip(),
                          icon: const Icon(Icons.open_in_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 32,
                          onPressed: () => controller.togglePlayPause(),
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
