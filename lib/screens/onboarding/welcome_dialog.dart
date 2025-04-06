import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/settings/sub_settings/settings_accounts.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';

void showWelcomeDialogg(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Welcome To AnymeX",
    pageBuilder: (context, animation1, animation2) {
      final settings = Get.find<Settings>();
      return Obx(() {
        return Material(
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Container(
              width: getResponsiveSize(context,
                  mobileSize: MediaQuery.of(context).size.width - 20,
                  dektopSize: MediaQuery.of(context).size.width * 0.4),
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
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
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
                        CustomTile(
                          description:
                              'Change Service to whichever you prefer! like AL, MAL, Simkl',
                          icon: HugeIcons.strokeRoundedAiSetting,
                          title: ('Change Service'),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
