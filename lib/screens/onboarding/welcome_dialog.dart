import 'dart:io';

import 'package:url_launcher/url_launcher.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/extensions/ExtensionScreen.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/custom_widgets/anymex_animated_logo.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:permission_handler/permission_handler.dart';

const MethodChannel _utilsChannel = MethodChannel('com.ryan.anymex/utils');

Future<bool> _requestStoragePermissions() async {
  if (!Platform.isAndroid) return true;

  try {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    Logger.i('Android SDK version: $sdkInt');

    if (sdkInt >= 33) {
      final permissions = [
        Permission.photos,
        Permission.videos,
      ];

      Map<Permission, PermissionStatus> statuses = await permissions.request();

      if (await Permission.manageExternalStorage.isDenied) {
        final manageStorageStatus =
            await Permission.manageExternalStorage.request();
        if (manageStorageStatus.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }
      }

      return statuses.values.every((status) =>
          status == PermissionStatus.granted ||
          status == PermissionStatus.limited);
    } else if (sdkInt >= 30) {
      final status = await Permission.manageExternalStorage.request();

      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      return status.isGranted;
    } else if (sdkInt >= 23) {
      final permissions = [
        Permission.storage,
      ];

      Map<Permission, PermissionStatus> statuses = await permissions.request();

      bool allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) {
        bool permanentlyDenied =
            statuses.values.any((status) => status.isPermanentlyDenied);
        if (permanentlyDenied) {
          await openAppSettings();
          return false;
        }
      }

      return allGranted;
    } else {
      return true;
    }
  } catch (e) {
    Logger.i('Error requesting storage permissions: $e');
    return false;
  }
}

void showWelcomeDialogg(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Welcome To AnymeX",
    pageBuilder: (context, animation1, animation2) {
      final RxBool storagePermissionGranted = false.obs;
      final RxBool installPermissionGranted = false.obs;

      Future<void> requestStoragePermission() async {
        final status = await _requestStoragePermissions();
        storagePermissionGranted.value = status;
        if (!status) {
          snackBar("Storage permission is required to download updates");
        }
      }

      Future<void> requestInstallPermission() async {
        final status = await Permission.requestInstallPackages.request();
        installPermissionGranted.value = status.isGranted;
        if (!status.isGranted) {
          snackBar("Install permission is required to update the app");
        }
      }

      return Obx(() {
        storagePermissionGranted.value;
        return Material(
          color: context.colors.surface,
          child: Center(
            child: Container(
              width: getResponsiveSize(context,
                  mobileSize: MediaQuery.of(context).size.width - 24,
                  desktopSize: MediaQuery.of(context).size.width * 0.42),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.colors.outline.withOpacity(0.12),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      color: context.colors.surfaceContainerHigh,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const AnymeXAnimatedLogo(
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to AnymeX',
                                style: TextStyle(
                                  fontFamily: 'Poppins-SemiBold',
                                  fontSize: 18,
                                  color: context.colors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Set up your preferences for the best experience',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.onSurfaceVariant
                                      .withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomTile(
                            icon: HugeIcons.strokeRoundedUserCheck01,
                            title: 'Choose Service / Tracker',
                            description:
                                'Select AniList, MyAnimeList, Simkl, or Extensions mode',
                            onTap: () {
                              SettingsSheet().showServiceSelector(context);
                            },
                          ),
                          const SizedBox(height: 6),
                          CustomTile(
                            icon: HugeIcons.strokeRoundedPuzzle,
                            title: 'Extensions & Repositories',
                            description:
                                'Manage sources and repositories to use the app to its full potential',
                            onTap: () {
                              navigate(() => const ExtensionScreen());
                            },
                          ),
                          const SizedBox(height: 6),
                          CustomTile(
                            icon: HugeIcons.strokeRoundedDiscord,
                            title: 'Join Discord Community',
                            description:
                                'Propose new features, report bugs, and chat with other members',
                            onTap: () async {
                              final url = Get.find<Settings>().discordUrl.value;
                              await launchUrl(Uri.parse(url),
                                  mode: LaunchMode.externalApplication);
                            },
                          ),
                          const SizedBox(height: 6),
                          CustomTile(
                            icon: HugeIcons.strokeRoundedTelegram,
                            title: 'Join Telegram Channel',
                            description:
                                'Stay updated with the latest releases, announcements, and discussions',
                            onTap: () async {
                              final url = Get.find<Settings>().telegramUrl.value;
                              await launchUrl(Uri.parse(url),
                                  mode: LaunchMode.externalApplication);
                            },
                          ),
                          const SizedBox(height: 6),
                          if (Platform.isAndroid) ...[
                            CustomSwitchTile(
                              icon: HugeIcons.strokeRoundedFolderSecurity,
                              title: "Storage Permission",
                              description:
                                  "Allow storage access to download app & extension updates",
                              switchValue: storagePermissionGranted.value,
                              onChanged: (val) {
                                if (val) {
                                  requestStoragePermission();
                                }
                              },
                            ),
                            const SizedBox(height: 6),
                            CustomSwitchTile(
                              icon: HugeIcons.strokeRoundedDownload01,
                              title: "Install Permission",
                              description:
                                  "Allow installing updates for extensions and app",
                              switchValue: installPermissionGranted.value,
                              onChanged: (val) {
                                if (val) {
                                  requestInstallPermission();
                                }
                              },
                            ),
                            const SizedBox(height: 6),
                            CustomTile(
                              icon: Icons.link_rounded,
                              title: 'Open Supported Links',
                              description:
                                  'Allow AnymeX to automatically open anime & manga web links',
                              onTap: () async {
                                bool opened = false;
                                try {
                                  opened =
                                      (await _utilsChannel.invokeMethod<bool>(
                                              'openOpenByDefaultSettings')) ??
                                          false;
                                } catch (e) {
                                  Logger.i(
                                      'Failed to open Open by default settings: $e');
                                }

                                if (!opened) {
                                  opened = await openAppSettings();
                                }

                                if (!opened) {
                                  snackBar(
                                      "Couldn't open app settings. Open it manually.");
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primary,
                          foregroundColor: context.colors.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          General.isFirstTime.set(false);
                          Navigator.of(context).pop();
                        },
                        label: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontFamily: 'Poppins-SemiBold',
                            fontSize: 15,
                          ),
                        ),
                        icon: const Icon(IconlyBold.arrowRight, size: 18),
                        iconAlignment: IconAlignment.end,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    },
  );
}
