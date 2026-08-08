import 'package:flutter/material.dart';

class MediaIndicatorBuilder extends StatelessWidget {
  final bool isVolumeIndicator;
  final double value;

  const MediaIndicatorBuilder(
      {super.key, required this.value, required this.isVolumeIndicator});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment:
            isVolumeIndicator ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(100),
            ),
            width: 42,
            child: UnconstrainedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: SizedBox.fromSize(
                            size: const Size(168, 24),
                            child: LinearProgressIndicator(
                              value: value,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Icon(
                      isVolumeIndicator
                          ? switch (value) {
                              == 0.0 => Icons.volume_off,
                              < 0.5 => Icons.volume_down,
                              _ => Icons.volume_up,
                            }
                          : switch (value) {
                              < 1.0 / 3.0 => Icons.brightness_low,
                              < 2.0 / 3.0 => Icons.brightness_medium,
                              _ => Icons.brightness_high,
                            },
                      color: Colors.white,
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
