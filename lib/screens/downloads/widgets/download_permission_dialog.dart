import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/downloads/download_screen.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadPermissionDialog extends StatelessWidget {
  const DownloadPermissionDialog({super.key});

  static Future<bool> checkAndPrompt(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true;
    }

    final hasStorage = await Permission.storage.isGranted ||
        await Permission.manageExternalStorage.isGranted ||
        await Permission.videos.isGranted ||
        await Permission.photos.isGranted;
    final hasNotifications = await Permission.notification.isGranted;
    final settings = Get.find<Settings>();
    final savedPath = settings.downloadPath.value;
    final hasDir = savedPath.isNotEmpty && await Directory(savedPath).exists();

    final hasSeen = DownloadKeys.hasSeenDownloadGuide.get<bool>(false);

    if (hasStorage && hasNotifications && hasDir) {
      if (!hasSeen) {
        DownloadKeys.hasSeenDownloadGuide.set(true);
      }
      return true;
    }

    if (!context.mounted) return false;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const DownloadPermissionDialog(),
    );

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnymeXDialog(
      title: 'Download Permissions',
      confirmText: 'Go to Downloads',
      cancelText: 'Cancel',
      onConfirm: () {
        DownloadKeys.hasSeenDownloadGuide.set(true);
        navigate(() => const DownloadScreen());
      },
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colors.primary.opaque(0.12, iReallyMeanIt: true),
              shape: BoxShape.circle,
            ),
            child: Icon(
              HugeIcons.strokeRoundedSecurityLock,
              color: colors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          AnymeXText(
            'To download for the first time, grant permissions by visiting the Downloads page first:',
            textAlign: TextAlign.center,
            color: colors.onSurfaceVariant,
            size: 13,
          ),
          const SizedBox(height: 16),
          _buildStepRow(
            context,
            stepNumber: '1',
            icon: HugeIcons.strokeRoundedUser,
            title: 'Profile Icon',
            description: 'Tap your profile icon in the top app bar',
          ),
          const SizedBox(height: 8),
          _buildStepRow(
            context,
            stepNumber: '2',
            icon: HugeIcons.strokeRoundedDownload04,
            title: 'Downloads Page',
            description: 'Open the Downloads screen from the menu',
          ),
          const SizedBox(height: 8),
          _buildStepRow(
            context,
            stepNumber: '3',
            icon: HugeIcons.strokeRoundedFolder01,
            title: 'Grant Permissions',
            description: 'Allow storage access and select download folder',
          ),
        ],
      ),
    );
  }
}

Widget _buildStepRow(
  BuildContext context, {
  required String stepNumber,
  required IconData icon,
  required String title,
  required String description,
}) {
  final colors = context.colors;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: colors.surfaceContainerHighest.opaque(0.35, iReallyMeanIt: true),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: colors.outline.opaque(0.1, iReallyMeanIt: true),
        width: 0.8,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary.opaque(0.15, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: colors.primary.opaque(0.15, iReallyMeanIt: true),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: AnymeXText(
                      'Step $stepNumber',
                      size: 10,
                      variant: TextVariant.bold,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnymeXText(
                    title,
                    size: 13,
                    variant: TextVariant.bold,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              AnymeXText(
                description,
                size: 11,
                color: colors.onSurface.opaque(0.7),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
