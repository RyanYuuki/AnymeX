// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'dart:isolate';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/common/anymex_slider_m3.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/utils/mesh_blur_helper.dart';

class ProgressController extends GetxController {
  var currentStep = ''.obs;
  var progress = 0.0.obs;
  var isProcessing = false.obs;

  void updateProgress(String step, double progressValue) {
    currentStep.value = step;
    progress.value = progressValue;
  }

  void setProcessing(bool processing) {
    isProcessing.value = processing;
  }
}

enum BlurStrength {
  none(0, 'None'),
  low(20, 'Low'),
  medium(40, 'Medium'),
  high(60, 'High'),
  veryHigh(100, 'Very High');

  const BlurStrength(this.radius, this.label);
  final int radius;
  final String label;
}

class Liquid {
  static Future<void> pickLiquidBackground(BuildContext context) async {
    try {
      final pickedFile = await FilePicker.platform.pickFiles(
        allowCompression: false,
        type: FileType.image,
        allowMultiple: false,
      );

      if ((pickedFile?.files.isNotEmpty ?? false) &&
          pickedFile?.files.first.path != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiquidPreviewPage(
              imagePath: pickedFile!.files.first.path!,
            ),
          ),
        );
      }
    } catch (e) {
      Logger.i('Error picking image: $e');
      _showErrorSnackbar(context, 'Failed to pick image');
    }
  }

  static Future<void> processAndSaveCustomWallpaper({
    required BuildContext context,
    required String imagePath,
    required double blur,
    required double brightness,
    required double contrast,
    bool isMesh = false,
  }) async {
    final screenSize = MediaQuery.sizeOf(context);
    final ProgressController progressController = Get.put(ProgressController());

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              backgroundColor: context.colors.surface,
              surfaceTintColor: context.colors.surfaceTint,
              content: Obx(() => Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnymeXProgressIndicator(
                          value: progressController.progress.value > 0
                              ? progressController.progress.value
                              : null,
                        ),
                        const SizedBox(height: 20),
                        AnymeXText(
                          progressController.currentStep.value.isEmpty
                              ? 'Initializing...'
                              : progressController.currentStep.value,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: context.colors.onSurface,
                                  ),
                        ),
                        if (progressController.progress.value > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: AnymeXText(
                              '${(progressController.progress.value * 100).toInt()}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: context.colors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  )),
            ),
          );
        },
      );

      progressController.setProcessing(true);
      progressController.updateProgress('Preparing to process image...', 0.05);

      await _processAndSaveBlurredImageCustom(
        imagePath: imagePath,
        progressController: progressController,
        blur: blur,
        brightness: brightness,
        contrast: contrast,
        screenSize: screenSize,
        isMesh: isMesh,
      );
      Navigator.of(context).pop();
    } catch (e) {
      Logger.i('Error processing image: $e');
      progressController.updateProgress('Error: Failed to process image', 0.0);
      await Future.delayed(const Duration(seconds: 2));
    } finally {
      progressController.setProcessing(false);
      Get.back();
      Get.delete<ProgressController>();
    }
  }

  static Future<void> _processAndSaveBlurredImageCustom({
    required String imagePath,
    required ProgressController progressController,
    required double blur,
    required double brightness,
    required double contrast,
    required Size screenSize,
    bool isMesh = false,
  }) async {
    try {
      progressController.updateProgress('Clearing previous background...', 0.1);
      await _clearLiquidBackground();

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String savedPath = path.join(appDocDir.path,
          'liquid_background_${DateTime.now().microsecondsSinceEpoch}.jpg');

      progressController.updateProgress(
          'Initializing GPU acceleration...', 0.15);

      final File originalFile = File(imagePath);
      final Uint8List imageBytes = await originalFile.readAsBytes();

      String? result;

      final Uint8List? gpuResult = await _gpuBlurImageCustom(
        imageBytes: imageBytes,
        blurRadius: blur,
        brightness: brightness,
        contrast: contrast,
        screenSize: screenSize,
        isMesh: isMesh,
        onProgress: (step, progress) => progressController.updateProgress(step, progress),
      );

      if (gpuResult != null) {
        progressController.updateProgress(
            'Saving GPU-processed image...', 0.95);
        await File(savedPath).writeAsBytes(gpuResult);
        result = savedPath;
      } else {
        progressController.updateProgress(
            'Falling back to CPU optimization...', 0.4);

        final ReceivePort progressPort = ReceivePort();
        progressPort.listen((data) {
          if (data is Map<String, dynamic>) {
            final step = data['step'] as String?;
            final progress = data['progress'] as double?;
            if (step != null && progress != null) {
              progressController.updateProgress(step, progress);
            }
          }
        });

        result = await compute(_cpuOptimizedBlurCustom, {
          'imagePath': imagePath,
          'outputPath': savedPath,
          'blurRadius': blur,
          'brightness': brightness,
          'contrast': contrast,
          'screenWidth': screenSize.width,
          'screenHeight': screenSize.height,
          'isMesh': isMesh,
          'progressPort': progressPort.sendPort,
        });

        progressPort.close();
      }

      if (result != null) {
        progressController.updateProgress('Applying new background...', 0.98);
        final settings = Get.find<Settings>();
        settings.liquidBackgroundPath = result;
        Logger.i('Liquid background saved successfully: $result');

        progressController.updateProgress(
            'Background applied successfully! ✓', 1.0);
        await Future.delayed(const Duration(milliseconds: 800));
      } else {
        progressController.updateProgress('Failed to process image', 0.0);
        Logger.i('Failed to process image');
        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      Logger.i('Error processing image: $e');
      progressController.updateProgress('Error: ${e.toString()}', 0.0);
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  static Future<Uint8List?> _gpuBlurImageCustom({
    required Uint8List imageBytes,
    required double blurRadius,
    required double brightness,
    required double contrast,
    required Size screenSize,
    required Function(String, double) onProgress,
    bool isMesh = false,
  }) async {
    try {
      onProgress('Decoding image with GPU optimization...', 0.2);

      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image originalImage = frame.image;

      ui.Image sourceToDraw = originalImage;
      ui.Image? meshImage;

      if (isMesh) {
        onProgress('Generating fluid mesh gradient...', 0.3);
        final meshRaster = await compute(
          MeshBlurHelper.processMeshBackdrop,
          (imageBytes, 1.0, 0.0, 42),
        );
        meshImage = await MeshBlurHelper.inflateNativeImage(meshRaster);
        sourceToDraw = meshImage;
      }

      onProgress('Preparing GPU blur operation...', 0.35);

      final int width = sourceToDraw.width;
      final int height = sourceToDraw.height;
      const double maxDimension = 1920.0;

      double resizeScale = 1.0;
      if (width > maxDimension || height > maxDimension) {
        resizeScale = maxDimension / (width > height ? width : height);
      }

      final int outputWidth = (width * resizeScale).round();
      final int outputHeight = (height * resizeScale).round();

      final double scaleX = screenSize.width / outputWidth;
      final double scaleY = screenSize.height / outputHeight;
      final double coverScale = math.max(scaleX, scaleY);
      final double effectiveBlur =
          isMesh ? math.max(blurRadius, 12.0) : blurRadius;
      final double targetBlurSigma =
          coverScale > 0 ? (effectiveBlur / coverScale) : effectiveBlur;

      onProgress('Applying GPU-accelerated blur...', 0.5);

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
      );

      final double colorScale = brightness * contrast;
      final double colorOffset = 128.0 * (1.0 - contrast);
      final paint = Paint()
        ..colorFilter = ui.ColorFilter.matrix([
          colorScale, 0, 0, 0, colorOffset,
          0, colorScale, 0, 0, colorOffset,
          0, 0, colorScale, 0, colorOffset,
          0, 0, 0, 1, 0,
        ]);

      final dstRect =
          Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble());
      final srcRect =
          Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());

      if (targetBlurSigma > 0.5) {
        canvas.saveLayer(
          dstRect,
          Paint()
            ..imageFilter = ui.ImageFilter.blur(
              sigmaX: targetBlurSigma,
              sigmaY: targetBlurSigma,
              tileMode: TileMode.clamp,
            ),
        );
        canvas.drawImageRect(sourceToDraw, srcRect, dstRect, paint);
        canvas.restore();
      } else {
        canvas.drawImageRect(sourceToDraw, srcRect, dstRect, paint);
      }

      onProgress('Finalizing GPU processing...', 0.8);

      final ui.Picture picture = recorder.endRecording();
      final ui.Image blurredImage =
          await picture.toImage(outputWidth, outputHeight);

      onProgress('Encoding final image...', 0.9);

      final ByteData? byteData =
          await blurredImage.toByteData(format: ui.ImageByteFormat.png);

      originalImage.dispose();
      meshImage?.dispose();
      blurredImage.dispose();
      picture.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('GPU blur error: $e');
      return null;
    }
  }

  static Future<String?> _cpuOptimizedBlurCustom(
      Map<String, dynamic> params) async {
    try {
      final String imagePath = params['imagePath'];
      final String outputPath = params['outputPath'];
      final double blurRadius = (params['blurRadius'] as num).toDouble();
      final double brightness = (params['brightness'] as num).toDouble();
      final double contrast = (params['contrast'] as num?)?.toDouble() ?? 1.0;
      final double screenWidth = (params['screenWidth'] as num).toDouble();
      final double screenHeight = (params['screenHeight'] as num).toDouble();
      final bool isMesh = params['isMesh'] == true;
      final SendPort? progressPort = params['progressPort'];

      progressPort
          ?.send({'step': 'Loading image (CPU fallback)...', 'progress': 0.1});

      final File originalFile = File(imagePath);
      final Uint8List imageBytes = await originalFile.readAsBytes();

      progressPort?.send({'step': 'Decoding image...', 'progress': 0.2});

      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;

      if (isMesh) {
        progressPort?.send(
            {'step': 'Generating fluid mesh gradient...', 'progress': 0.35});
        originalImage = MeshBlurHelper.generateMeshImageFromDecoded(
            originalImage,
            seed: 42);
        originalImage = img.copyResize(originalImage,
            width: screenWidth.round(),
            height: screenHeight.round(),
            interpolation: img.Interpolation.linear);
      } else {
        const int maxDimension = 1280;
        if (originalImage.width > maxDimension ||
            originalImage.height > maxDimension) {
          progressPort
              ?.send({'step': 'Optimizing image size...', 'progress': 0.3});

          final double scale = maxDimension /
              (originalImage.width > originalImage.height
                  ? originalImage.width
                  : originalImage.height);

          originalImage = img.copyResize(
            originalImage,
            width: (originalImage.width * scale).round(),
            height: (originalImage.height * scale).round(),
            interpolation: img.Interpolation.linear,
          );
        }
      }

      final double scaleX = screenWidth / originalImage.width;
      final double scaleY = screenHeight / originalImage.height;
      final double coverScale = math.max(scaleX, scaleY);
      final double targetBlurSigma =
          coverScale > 0 ? (blurRadius / coverScale) : blurRadius;

      progressPort
          ?.send({'step': 'Applying brightness & contrast...', 'progress': 0.4});

      final double colorScale = brightness * contrast;
      final double colorOffset = 128.0 * (1.0 - contrast);

      for (final pixel in originalImage) {
        pixel.r = (pixel.r * colorScale + colorOffset).clamp(0, 255);
        pixel.g = (pixel.g * colorScale + colorOffset).clamp(0, 255);
        pixel.b = (pixel.b * colorScale + colorOffset).clamp(0, 255);
      }

      if (targetBlurSigma > 0.5) {
        progressPort
            ?.send({'step': 'Applying blur...', 'progress': 0.6});
        originalImage = img.gaussianBlur(
          originalImage,
          radius: targetBlurSigma.round().clamp(1, 100),
        );
      }

      progressPort
          ?.send({'step': 'Saving image...', 'progress': 0.9});

      final File savedFile = File(outputPath);
      await savedFile.writeAsBytes(img.encodeJpg(originalImage, quality: 90));

      return outputPath;
    } catch (e) {
      debugPrint('CPU blur error: $e');
      return null;
    }
  }

  static Future<void> _clearLiquidBackground() async {
    final settings = Get.find<Settings>();
    try {
      if (settings.liquidBackgroundPath.isNotEmpty) {
        final File file = File(settings.liquidBackgroundPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      Logger.i('Error clearing liquid background: $e');
    }
  }

  static void _showErrorSnackbar(BuildContext context, String message) {
    errorSnackBar(message);
  }
}

class LiquidPreviewPage extends StatefulWidget {
  final String imagePath;

  const LiquidPreviewPage({super.key, required this.imagePath});

  @override
  State<LiquidPreviewPage> createState() => _LiquidPreviewPageState();
}

class _LiquidPreviewPageState extends State<LiquidPreviewPage> {
  double blur = 20.0;
  double brightness = 0.7;
  double contrast = 1.0;
  int blurStyle = 0;
  ui.Image? _meshImage;
  bool _loadingMesh = false;

  void _loadMeshImage() async {
    if (_meshImage != null || _loadingMesh) return;
    setState(() => _loadingMesh = true);
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final raster = await compute(
        MeshBlurHelper.processMeshBackdrop,
        (bytes, 1.0, 0.0, widget.imagePath.hashCode),
      );
      final image = await MeshBlurHelper.inflateNativeImage(raster);
      if (mounted) {
        setState(() {
          _meshImage = image;
          _loadingMesh = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMesh = false);
    }
  }

  @override
  void dispose() {
    _meshImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = Get.find<Settings>();
    final retainColor = settings.retainOriginalColor;
    final double colorScale = brightness * contrast;
    final double colorOffset = 128.0 * (1.0 - contrast);

    Widget previewImage = ColorFiltered(
      colorFilter: ColorFilter.matrix([
        colorScale, 0, 0, 0, colorOffset,
        0, colorScale, 0, 0, colorOffset,
        0, 0, colorScale, 0, colorOffset,
        0, 0, 0, 1, 0,
      ]),
      child: blurStyle == 1 && _meshImage != null
          ? RawImage(
              image: _meshImage,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              filterQuality: FilterQuality.medium,
            )
          : Image.file(
              File(widget.imagePath),
              fit: BoxFit.cover,
            ),
    );

    if (!retainColor) {
      previewImage = ColorFiltered(
        colorFilter: ColorFilter.mode(
          colorScheme.primary.opaque(0.6),
          BlendMode.color,
        ),
        child: previewImage,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: blur > 0.5
                ? ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: previewImage,
                  )
                : previewImage,
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 24,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    blurStyle = 0;
                                  });
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: blurStyle == 0
                                        ? colorScheme.primary
                                        : colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: AnymeXText(
                                    "Gaussian Blur",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: blurStyle == 0
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    blurStyle = 1;
                                    _loadMeshImage();
                                  });
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: blurStyle == 1
                                        ? colorScheme.primary
                                        : colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: AnymeXText(
                                    "Fluid Mesh",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: blurStyle == 1
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.blur_on,
                                size: 20, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            const AnymeXText(
                              "Blur Radius",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            AnymeXText(
                              "${blur.toInt()}px",
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        4.height(),
                        AnymeXSliderM3(
                          value: blur,
                          min: 0.0,
                          max: 60.0,
                          divisions: 60,
                          onChanged: (val) {
                            setState(() {
                              blur = val;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.brightness_medium,
                                size: 20, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            const AnymeXText(
                              "Brightness",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            AnymeXText(
                              "${(brightness * 100).toInt()}%",
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        4.height(),
                        AnymeXSliderM3(
                          value: brightness,
                          min: 0.1,
                          max: 1.5,
                          divisions: 28,
                          onChanged: (val) {
                            setState(() {
                              brightness = val;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.contrast,
                                size: 20, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            const AnymeXText(
                              "Contrast",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            AnymeXText(
                              "${(contrast * 100).toInt()}%",
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        4.height(),
                        AnymeXSliderM3(
                          value: contrast,
                          min: 0.5,
                          max: 2.0,
                          divisions: 30,
                          onChanged: (val) {
                            setState(() {
                              contrast = val;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: colorScheme.outline),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const AnymeXText("Cancel"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  Liquid.processAndSaveCustomWallpaper(
                                    context: context,
                                    imagePath: widget.imagePath,
                                    blur: blur,
                                    brightness: brightness,
                                    contrast: contrast,
                                    isMesh: blurStyle == 1,
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const AnymeXText("Apply"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
