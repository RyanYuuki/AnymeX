import 'dart:io';
import 'package:flutter/material.dart';
import 'package:anymex/controllers/services/storage/anymex_cache_manager.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:extended_image/extended_image.dart' as ext;
import 'package:anymex/utils/image_cropper.dart';
import 'subsampling_scale_image_view.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

class SubsamplingImageProvider extends StatefulWidget {
  final PageUrl page;
  final BoxFit fit;
  final Alignment alignment;
  final bool cropBorders;
  final bool isContinuousMode;
  final Widget? placeholder;
  final Function(double width, double height)? onImageLoaded;
  final double? width;
  final double? height;

  const SubsamplingImageProvider({
    super.key,
    required this.page,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    required this.cropBorders,
    this.isContinuousMode = false,
    this.placeholder,
    this.onImageLoaded,
    this.width,
    this.height,
  });

  @override
  State<SubsamplingImageProvider> createState() =>
      _SubsamplingImageProviderState();
}

class _SubsamplingImageProviderState extends State<SubsamplingImageProvider> {
  Future<File>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  @override
  void didUpdateWidget(SubsamplingImageProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.url != widget.page.url) {
      _initLoad();
    }
  }

  void _initLoad() {
    final url = widget.page.url;
    if (url.startsWith('http')) {
      _loadFuture = AnymeXCacheManager.instance.getSingleFile(
        url,
        headers: widget.page.headers,
      );
    } else {
      _loadFuture = Future.value(File(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isContinuousMode) {
      final url = widget.page.url;
      if (url.startsWith('http')) {
        return ext.ExtendedImage.network(
          url,
          headers: widget.page.headers,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          enableLoadState: true,
          loadStateChanged: (ext.ExtendedImageState state) {
            if (state.extendedImageLoadState == ext.LoadState.loading) {
              return widget.placeholder;
            }
            if (state.extendedImageLoadState == ext.LoadState.completed &&
                state.extendedImageInfo != null) {
              final img = state.extendedImageInfo!.image;
              widget.onImageLoaded
                  ?.call(img.width.toDouble(), img.height.toDouble());
            }
            if (state.extendedImageLoadState == ext.LoadState.failed) {
              return _buildErrorWidget(context, () => state.reLoadImage());
            }
            return null;
          },
        );
      } else {
        final file = File(url);
        if (file.existsSync()) {
          final imageStream =
              FileImage(file).resolve(const ImageConfiguration());
          imageStream.addListener(ImageStreamListener((info, _) {
            widget.onImageLoaded?.call(
                info.image.width.toDouble(), info.image.height.toDouble());
          }));
          return Image.file(
            file,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            alignment: widget.alignment,
          );
        } else {
          return _buildErrorWidget(context, () {
            setState(() {
              _initLoad();
            });
          });
        }
      }
    }

    if (Platform.isLinux) {
      if (widget.cropBorders) {
        return CroppedNetworkImage(
          url: widget.page.url,
          headers: widget.page.headers,
          fit: widget.fit,
          alignment: widget.alignment,
          cropThreshold: 30,
          placeholder: widget.placeholder,
        );
      } else {
        final url = widget.page.url;
        if (url.startsWith('http')) {
          return ext.ExtendedImage.network(
            url,
            headers: widget.page.headers,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            alignment: widget.alignment,
            enableLoadState: true,
            loadStateChanged: (ext.ExtendedImageState state) {
              if (state.extendedImageLoadState == ext.LoadState.loading) {
                return widget.placeholder;
              }
              if (state.extendedImageLoadState == ext.LoadState.failed) {
                return _buildErrorWidget(context, () => state.reLoadImage());
              }
              return null;
            },
          );
        } else {
          final file = File(url);
          if (file.existsSync()) {
            return Image.file(
              file,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              alignment: widget.alignment,
            );
          } else {
            return _buildErrorWidget(context, () {
              setState(() {
                _initLoad();
              });
            });
          }
        }
      }
    }

    return FutureBuilder<File>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholder ??
              const Center(child: AnymeXProgressIndicator());
        }
        if (snapshot.hasData && snapshot.data != null) {
          final file = snapshot.data!;
          if (file.existsSync()) {
            final scaleType = widget.fit == BoxFit.fitWidth
                ? ScaleType.fitWidth
                : ScaleType.centerInside;
            return SubsamplingScaleImageView(
              key: ValueKey(file.path),
              image: FileImage(file),
              resolvedFilePath: file.path,
              cropBorders: widget.cropBorders,
              minimumScaleType: scaleType,
              panEnabled: false,
              zoomEnabled: false,
              quickScaleEnabled: false,
            );
          }
        }
        return _buildErrorWidget(context, () {
          setState(() {
            _initLoad();
          });
        });
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context, VoidCallback onRetry) {
    final colors = Theme.of(context).colorScheme;
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.error.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.broken_image_rounded,
                color: colors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            const AnymeXText(
              'Failed to load page',
              variant: TextVariant.bold,
              size: 14,
            ),
            const SizedBox(height: 6),
            AnymeXText(
              'Tap retry to attempt loading again',
              size: 12,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: colors.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    AnymeXText(
                      'Retry',
                      variant: TextVariant.bold,
                      size: 13,
                      color: colors.onPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.height != null && widget.width != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: content,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final targetHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : (constraints.hasBoundedWidth
                ? constraints.maxWidth * 1.4
                : screenHeight * 0.7);
        return SizedBox(
          width: constraints.hasBoundedWidth ? constraints.maxWidth : double.infinity,
          height: targetHeight > 0 ? targetHeight : screenHeight * 0.7,
          child: content,
        );
      },
    );
  }
}
