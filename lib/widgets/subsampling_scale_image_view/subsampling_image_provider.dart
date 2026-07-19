import 'dart:io';
import 'package:flutter/material.dart';
import 'package:anymex/controllers/services/storage/anymex_cache_manager.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:extended_image/extended_image.dart' as ext;
import 'package:anymex/utils/image_cropper.dart';
import 'subsampling_scale_image_view.dart';

class SubsamplingImageProvider extends StatefulWidget {
  final PageUrl page;
  final BoxFit fit;
  final Alignment alignment;
  final bool cropBorders;
  final bool isContinuousMode;
  final Widget? placeholder;
  final Function(double width, double height)? onImageLoaded;

  const SubsamplingImageProvider({
    super.key,
    required this.page,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    required this.cropBorders,
    this.isContinuousMode = false,
    this.placeholder,
    this.onImageLoaded,
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
        }
        return Image.file(
          file,
          fit: widget.fit,
          alignment: widget.alignment,
        );
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
            fit: widget.fit,
            alignment: widget.alignment,
            enableLoadState: true,
            loadStateChanged: (ext.ExtendedImageState state) {
              if (state.extendedImageLoadState == ext.LoadState.loading) {
                return widget.placeholder;
              }
              return null;
            },
          );
        } else {
          return Image.file(
            File(url),
            fit: widget.fit,
            alignment: widget.alignment,
          );
        }
      }
    }

    return FutureBuilder<File>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholder ??
              const Center(child: AnymexProgressIndicator());
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
        return widget.placeholder ??
            const Center(
              child: Text(
                'Failed to load page',
                style: TextStyle(color: Colors.white),
              ),
            );
      },
    );
  }
}
