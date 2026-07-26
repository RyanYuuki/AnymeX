import 'dart:typed_data';
import 'package:anymex/screens/anime/watch/controller/player_utils.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

class PlayerThumbnailPreview extends StatelessWidget {
  final Uint8List? imageBytes;
  final Duration position;
  final Duration totalDuration;

  const PlayerThumbnailPreview({
    super.key,
    required this.imageBytes,
    required this.position,
    required this.totalDuration,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final formattedTime = PlayerUtils.formatDuration(position);
    final formattedTotal = PlayerUtils.formatDuration(totalDuration);

    return Container(
      width: 160,
      height: 110,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.primary.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageBytes != null && imageBytes!.isNotEmpty)
            Image.memory(
              imageBytes!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(colors),
            )
          else
            _buildPlaceholder(colors),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: Colors.black.withOpacity(0.75),
              child: Text(
                '$formattedTime / $formattedTotal',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colors) {
    return Container(
      color: Colors.black45,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.primary,
          ),
        ),
      ),
    );
  }
}
