// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'package:anymex/utils/logger.dart';
import 'dart:isolate';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
  low(20, 'Low'),
  medium(40, 'Medium'),
  high(60, 'High'),
  veryHigh(100, 'Very High');

  const BlurStrength(this.radius, this.label);
  final int radius;
  final String label;
}

class FastBlurProcessor {
  static Uint8List _fastBoxBlur(
      Uint8List pixels, int width, int height, int radius) {
    if (radius <= 0) return pixels;
    final Uint8List output = Uint8List(pixels.length);

    for (int y = 0; y < height; y++) {
      int sum = 0;
      int count = 0;

      for (int x = 0; x < radius && x < width; x++) {
        final int idx = (y * width + x) * 4;
        sum += pixels[idx];
        count++;
      }

      for (int x = 0; x < width; x++) {
        final int idx = (y * width + x) * 4;

        if (x + radius < width) {
          final int newIdx = (y * width + x + radius) * 4;
          sum += pixels[newIdx];
          count++;
        }

        if (x - radius - 1 >= 0) {
          final int oldIdx = (y * width + x - radius - 1) * 4;
          sum -= pixels[oldIdx];
          count--;
        }

        output[idx] = (sum / count).round();
        output[idx + 1] = pixels[idx + 1];
        output[idx + 2] = pixels[idx + 2];
        output[idx + 3] = pixels[idx + 3];
      }
    }

    return output;
  }

  static Uint8List _ultraFastBlur(
      Uint8List pixels, int width, int height, int radius) {
    if (radius <= 0) return pixels;

    const int passes = 3;
    final int smallRadius = (radius / passes).round();

    Uint8List current = pixels;

    for (int pass = 0; pass < passes; pass++) {
      current = _fastBoxBlur(current, width, height, smallRadius);
    }

    return current;
  }
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
        await _showImagePreviewDialog(context, pickedFile!.files.first.path!);
      }
    } catch (e) {
      Logger.i('Error picking image: $e');
      _showErrorSnackbar(context, 'Failed to pick image');
    }
  }

  static Future<void> _showImagePreviewDialog(
      BuildContext context, String imagePath) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _ImagePreviewDialog(imagePath: imagePath);
      },
    );
  }

  static Future<void> _processWithBlurStrength(
    BuildContext context,
    String imagePath,
    BlurStrength blurStrength,
  ) async {
    final ProgressController progressController = Get.put(ProgressController());

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
              content: Obx(() => Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnymexProgressIndicator(
                          value: progressController.progress.value > 0
                              ? progressController.progress.value
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          progressController.currentStep.value.isEmpty
                              ? 'Initializing...'
                              : progressController.currentStep.value,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        if (progressController.progress.value > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              '${(progressController.progress.value * 100).toInt()}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
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

      await _processAndSaveBlurredImageFast(
          imagePath, progressController, blurStrength);
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

  static Future<Uint8List?> _gpuBlurImage(
    Uint8List imageBytes,
    int blurRadius,
    Function(String, double) onProgress,
  ) async {
    try {
      onProgress('Decoding image with GPU optimization...', 0.2);

      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image originalImage = frame.image;

      onProgress('Preparing GPU blur operation...', 0.3);

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      final int width = originalImage.width;
      final int height = originalImage.height;
      const double maxDimension = 1920.0;

      double scale = 1.0;
      if (width > maxDimension || height > maxDimension) {
        scale = maxDimension / (width > height ? width : height);
      }

      final int scaledWidth = (width * scale).round();
      final int scaledHeight = (height * scale).round();

      onProgress('Applying GPU-accelerated blur...', 0.5);

      canvas.scale(scale, scale);

      canvas.saveLayer(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: blurRadius.toDouble(),
            sigmaY: blurRadius.toDouble(),
          ),
      );

      canvas.drawImage(originalImage, Offset.zero, Paint());
      canvas.restore();

      onProgress('Finalizing GPU processing...', 0.8);

      final ui.Picture picture = recorder.endRecording();
      final ui.Image blurredImage =
          await picture.toImage(scaledWidth, scaledHeight);

      onProgress('Encoding final image...', 0.9);

      final ByteData? byteData =
          await blurredImage.toByteData(format: ui.ImageByteFormat.png);

      originalImage.dispose();
      blurredImage.dispose();
      picture.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('GPU blur error: $e');
      return null;
    }
  }

  static Future<String?> _cpuOptimizedBlur(Map<String, dynamic> params) async {
    try {
      final String imagePath = params['imagePath'];
      final String outputPath = params['outputPath'];
      final int blurRadius = params['blurRadius'];
      final SendPort? progressPort = params['progressPort'];

      progressPort
          ?.send({'step': 'Loading image (CPU optimized)...', 'progress': 0.1});

      final File originalFile = File(imagePath);
      final Uint8List imageBytes = await originalFile.readAsBytes();

      progressPort?.send({'step': 'Decoding image...', 'progress': 0.2});

      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;

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

      progressPort
          ?.send({'step': 'Applying ultra-fast blur...', 'progress': 0.5});

      final Uint8List pixels = originalImage.getBytes();
      final int width = originalImage.width;
      final int height = originalImage.height;

      final Uint8List blurredPixels = FastBlurProcessor._ultraFastBlur(
        pixels,
        width,
        height,
        blurRadius,
      );

      progressPort?.send({'step': 'Reconstructing image...', 'progress': 0.8});

      final img.Image blurredImage = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: blurredPixels.buffer,
      );

      progressPort
          ?.send({'step': 'Saving optimized image...', 'progress': 0.9});

      final File savedFile = File(outputPath);
      await savedFile.writeAsBytes(img.encodeJpg(blurredImage, quality: 85));

      return outputPath;
    } catch (e) {
      debugPrint('CPU blur error: $e');
      return null;
    }
  }

  static Future<void> _processAndSaveBlurredImageFast(
    String imagePath,
    ProgressController progressController,
    BlurStrength blurStrength,
  ) async {
    try {
      final settings = Get.find<Settings>();

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

      final Uint8List? gpuResult = await _gpuBlurImage(
        imageBytes,
        blurStrength.radius,
        (step, progress) => progressController.updateProgress(step, progress),
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

        result = await compute(_cpuOptimizedBlur, {
          'imagePath': imagePath,
          'outputPath': savedPath,
          'blurRadius': blurStrength.radius,
          'progressPort': progressPort.sendPort,
        });

        progressPort.close();
      }

      if (result != null) {
        progressController.updateProgress('Applying new background...', 0.98);
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

class _ImagePreviewDialog extends StatefulWidget {
  final String imagePath;

  const _ImagePreviewDialog({required this.imagePath});

  @override
  State<_ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<_ImagePreviewDialog> {
  BlurStrength selectedBlurStrength = BlurStrength.medium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wallpaper_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set Background',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'GPU-accelerated processing',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),

            // Image Preview
            Flexible(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.errorContainer,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: colorScheme.onErrorContainer,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Blur Strength Selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Blur Strength',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...BlurStrength.values.map((strength) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RadioListTile<BlurStrength>(
                        value: strength,
                        groupValue: selectedBlurStrength,
                        onChanged: (BlurStrength? value) {
                          if (value != null) {
                            setState(() {
                              selectedBlurStrength = value;
                            });
                          }
                        },
                        title: Text(
                          strength.label,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        activeColor: colorScheme.primary,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tileColor: selectedBlurStrength == strength
                            ? colorScheme.primaryContainer.withOpacity(0.3)
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        side: BorderSide(color: colorScheme.outline),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Liquid._processWithBlurStrength(
                          context,
                          widget.imagePath,
                          selectedBlurStrength,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.flash_on_rounded,
                            size: 18,
                            color: colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Fast Process',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
