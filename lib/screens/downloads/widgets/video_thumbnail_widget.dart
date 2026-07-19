import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:anymex/utils/local_thumbnail_service.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoPath;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Widget? fallback;

  const VideoThumbnailWidget({
    super.key,
    required this.videoPath,
    this.width = 76,
    this.height = 52,
    this.borderRadius,
    this.fallback,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  Future<String?>? _pathFuture;
  Future<Uint8List?>? _bytesFuture;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _loadThumbnail();
    }
  }

  void _loadThumbnail() {
    setState(() {
      _pathFuture = LocalThumbnailService.getThumbnailPath(widget.videoPath);
      _bytesFuture = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = widget.borderRadius ?? BorderRadius.circular(10);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: FutureBuilder<String?>(
          future: _pathFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData &&
                snapshot.data != null) {
              final path = snapshot.data!;
              return Image.file(
                File(path),
                width: widget.width,
                height: widget.height,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
              );
            }

            if (snapshot.connectionState == ConnectionState.done &&
                (snapshot.data == null || snapshot.hasError)) {
              _bytesFuture ??= LocalThumbnailService.getThumbnail(widget.videoPath);
              return FutureBuilder<Uint8List?>(
                future: _bytesFuture,
                builder: (context, byteSnapshot) {
                  if (byteSnapshot.connectionState == ConnectionState.done &&
                      byteSnapshot.hasData &&
                      byteSnapshot.data != null) {
                    return Image.memory(
                      byteSnapshot.data!,
                      width: widget.width,
                      height: widget.height,
                      fit: BoxFit.cover,
                    );
                  }
                  return _buildFallback(theme);
                },
              );
            }

            return _buildFallback(theme);
          },
        ),
      ),
    );
  }

  Widget _buildFallback(ThemeData theme) {
    return widget.fallback ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer.withOpacity(0.5),
          ),
          child: Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: theme.colorScheme.primary.withOpacity(0.4),
              size: 20,
            ),
          ),
        );
  }
}
