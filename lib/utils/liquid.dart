import 'dart:developer';
import 'dart:isolate';
import 'dart:io';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
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
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        await _showImagePreviewDialog(context, pickedFile.path);
      }
    } catch (e) {
      log('Error picking image: $e');
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
      progressController.updateProgress('Preparing to process image...', 0.1);

      await _processAndSaveBlurredImage(
          imagePath, progressController, blurStrength);
    } catch (e) {
      log('Error processing image: $e');
      progressController.updateProgress('Error: Failed to process image', 0.0);
      await Future.delayed(const Duration(seconds: 2));
    } finally {
      progressController.setProcessing(false);
      Get.back();
      Get.delete<ProgressController>();
    }
  }

  static Future<String?> _processImageInIsolate(
      Map<String, dynamic> params) async {
    try {
      final String imagePath = params['imagePath'];
      final String outputPath = params['outputPath'];
      final int blurRadius = params['blurRadius'];
      final SendPort? progressPort = params['progressPort'];

      progressPort?.send({'step': 'Loading image file...', 'progress': 0.3});

      final File originalFile = File(imagePath);
      final Uint8List imageBytes = await originalFile.readAsBytes();

      progressPort?.send({'step': 'Decoding image...', 'progress': 0.4});

      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;

      if (originalImage.width > 1920 || originalImage.height > 1080) {
        progressPort?.send({
          'step': 'Resizing image for optimal processing...',
          'progress': 0.5
        });
        originalImage = img.copyResize(originalImage, width: 1920);
      }

      progressPort
          ?.send({'step': 'Applying gaussian blur effect...', 'progress': 0.6});

      img.Image blurredImage =
          img.gaussianBlur(originalImage, radius: blurRadius);

      progressPort
          ?.send({'step': 'Encoding processed image...', 'progress': 0.8});

      final File savedFile = File(outputPath);
      await savedFile.writeAsBytes(img.encodeJpg(blurredImage, quality: 85));

      progressPort
          ?.send({'step': 'Saving to device storage...', 'progress': 0.9});

      return outputPath;
    } catch (e) {
      debugPrint('Error in isolate: $e');
      return null;
    }
  }

  static Future<void> _processAndSaveBlurredImage(
    String imagePath,
    ProgressController progressController,
    BlurStrength blurStrength,
  ) async {
    try {
      final settings = Get.find<Settings>();

      progressController.updateProgress(
          'Clearing previous background...', 0.25);
      await _clearLiquidBackground();

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String savedPath =
          path.join(appDocDir.path, 'liquid_background.jpg');

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

      final String? result = await compute(_processImageInIsolate, {
        'imagePath': imagePath,
        'outputPath': savedPath,
        'blurRadius': blurStrength.radius,
        'progressPort': progressPort.sendPort,
      });

      progressPort.close();

      if (result != null) {
        progressController.updateProgress('Applying new background...', 0.95);
        settings.liquidBackgroundPath = result;
        log('Liquid background saved successfully: $result');

        progressController.updateProgress(
            'Background applied successfully! ✓', 1.0);
        await Future.delayed(const Duration(seconds: 1));
        Get.delete<ProgressController>();
      } else {
        progressController.updateProgress('Failed to process image', 0.0);
        log('Failed to process image');
        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      log('Error processing image: $e');
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
        settings.liquidBackgroundPath = '';
      }
    } catch (e) {
      log('Error clearing liquid background: $e');
    }
  }

  static void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                    child: Text(
                      'Set Background',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
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
                  Text(
                    'Blur Strength',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
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
                        subtitle: Text(
                          'Blur radius: ${strength.radius}px',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
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

            // Action Buttons
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
                            Icons.auto_fix_high_rounded,
                            size: 18,
                            color: colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Apply Background',
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
