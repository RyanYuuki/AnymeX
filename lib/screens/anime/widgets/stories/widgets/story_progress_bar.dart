import 'package:flutter/material.dart';

class StoryProgressBar extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Animation<double> progress;

  const StoryProgressBar({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Row(
      children: List.generate(count, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Container(
                height: 4.0,
                color: Colors.white.withValues(alpha: 0.35),
                child: index < currentIndex
                    ? Container(color: Colors.white)
                    : (index == currentIndex
                        ? AnimatedBuilder(
                            animation: progress,
                            builder: (context, child) {
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress.value.clamp(0.0, 1.0),
                                child: Container(color: Colors.white),
                              );
                            },
                          )
                        : const SizedBox.shrink()),
              ),
            ),
          ),
        );
      }),
    );
  }
}
