import 'package:anymex/utils/logger.dart';
import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/settings/sub_settings/settings_accounts.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:permission_handler/permission_handler.dart';

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
      final settings = Get.find<Settings>();
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
        return Material(
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Container(
              width: getResponsiveSize(context,
                  mobileSize: MediaQuery.of(context).size.width - 20,
                  desktopSize: MediaQuery.of(context).size.width * 0.4),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height *
                    0.8, // Limit max height
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24)),
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    child: const Center(
                      child: Text(
                        'Welcome To AnymeX',
                        style: TextStyle(fontFamily: 'Poppins-SemiBold'),
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(6.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomSwitchTile(
                              icon: HugeIcons.strokeRoundedCpu,
                              title: "Performance Mode",
                              description:
                                  "Disable Animations to get smoother experience",
                              switchValue: !settings.enableAnimation,
                              onChanged: (val) {
                                settings.enableAnimation = !val;
                              }),
                          CustomSwitchTile(
                              icon: HugeIcons.strokeRoundedBounceRight,
                              title: "Disable Gradient",
                              description:
                                  "Disable Gradient, might give you smoother experience",
                              switchValue: settings.disableGradient,
                              onChanged: (val) {
                                settings.disableGradient = val;
                              }),
                          if (Platform.isAndroid) ...[
                            CustomSwitchTile(
                                icon: HugeIcons.strokeRoundedFolderSecurity,
                                title: "Storage Permission",
                                description:
                                    "Allow storage access to download updates",
                                switchValue: storagePermissionGranted.value,
                                onChanged: (val) {
                                  if (val) {
                                    requestStoragePermission();
                                  }
                                }),
                            CustomSwitchTile(
                                icon: HugeIcons.strokeRoundedDownload01,
                                title: "Install Permission",
                                description:
                                    "Allow installing updates for the app",
                                switchValue: installPermissionGranted.value,
                                onChanged: (val) {
                                  if (val) {
                                    requestInstallPermission();
                                  }
                                }),
                          ],
                          CustomTile(
                            description:
                                'Change Service to whichever you prefer! like AL, MAL, Simkl',
                            icon: HugeIcons.strokeRoundedAiSetting,
                            title: 'Change Service',
                            onTap: () {
                              SettingsSheet().showServiceSelector(context);
                            },
                          ),
                          Container(
                            height: 50,
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                            decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainer,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    onPressed: () {
                                      Hive.box('themeData')
                                          .put('isFirstTime', false);
                                      Navigator.of(context).pop();
                                      navigate(() => const SettingsAccounts());
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Login',
                                          style: TextStyle(
                                              fontFamily: 'Poppins-SemiBold',
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .inverseSurface),
                                        ),
                                        const Spacer(),
                                        _buildIcon(context, 'anilist-icon.png'),
                                        _buildIcon(context, 'mal-icon.png'),
                                        _buildIcon(context, 'simkl-icon.png'),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12))),
                                  onPressed: () {
                                    Hive.box('themeData')
                                        .put('isFirstTime', false);
                                    Get.back();
                                  },
                                  label: Text(
                                    'Skip',
                                    style: TextStyle(
                                        fontFamily: 'Poppins-SemiBold',
                                        color: Theme.of(context)
                                            .colorScheme
                                            .inverseSurface),
                                  ),
                                  icon: Icon(IconlyBold.arrow_right,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inverseSurface),
                                  iconAlignment: IconAlignment.end,
                                ),
                              ],
                            ),
                          ),
                        ],
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

Widget _buildIcon(BuildContext context, String url) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4.0),
    child: CircleAvatar(
      radius: 11,
      backgroundColor: Colors.transparent,
      child: Image.asset(
        'assets/images/$url',
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
