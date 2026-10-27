import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/settings/sub_settings/settings_donation.dart';
import 'package:anymex/services/ad_support_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationDialog extends StatelessWidget {
  const DonationDialog({super.key});

  static const String donateUrl = '';
  static const String adUrl = 'https://uplcm.com/4/12135636';

  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const DonationDialog(),
    );
  }

  static Future<void> _handleDonate(BuildContext context) async {
    if (donateUrl.isNotEmpty) {
      final uri = Uri.parse(donateUrl);
      try {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          snackBar('Could not open donation link');
        }
      } catch (_) {
        snackBar('Could not open donation link');
      }
    } else {
      navigate(SettingsDonation.new);
    }
  }

  static Future<void> _handleWatchAd(BuildContext context) async {
    await AdSupportService.instance.watchAd();
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXDialog(
      title: 'Support AnymeX',
      confirmText: 'Donate',
      cancelText: 'Maybe Later',
      showCancelButton: true,
      onConfirm: () => _handleDonate(context),
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeaderIcon(context),
          const SizedBox(height: 14),
          AnymeXText(
            'AnymeX is 100% free, open-source, and ad-free. Your support directly helps in server costs and active feature development!',
            size: 13.5,
            color: context.colors.onSurfaceVariant,
            textAlign: TextAlign.center,
            maxLines: 6,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPerk(
                context,
                icon: Icons.block_rounded,
                label: 'Ad-Free App',
              ),
              _buildPerk(
                context,
                icon: Icons.code_rounded,
                label: 'Open Source',
              ),
              _buildPerk(
                context,
                icon: Icons.volunteer_activism_rounded,
                label: 'Community Driven',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildAdSupportButton(context),
          const SizedBox(height: 14),
          _buildDontShowAgain(context),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: context.colors.primary.opaque(0.12, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: context.colors.primary.opaque(0.28, iReallyMeanIt: true),
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.opaque(0.15, iReallyMeanIt: true),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        Icons.favorite_rounded,
        color: context.colors.primary,
        size: 32,
      ),
    );
  }

  Widget _buildPerk(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest
            .opaque(0.5, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.onSurface.opaque(0.06, iReallyMeanIt: true),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.colors.primary),
          const SizedBox(width: 6),
          AnymeXText(label, size: 11.5, variant: TextVariant.semiBold),
        ],
      ),
    );
  }

  Widget _buildAdSupportButton(BuildContext context) {
    return AnymexOnTap(
      onTap: () => _handleWatchAd(context),
      scale: 0.97,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.primary.opaque(0.08, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.primary.opaque(0.28, iReallyMeanIt: true),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.colors.primary.opaque(0.18, iReallyMeanIt: true),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.touch_app_rounded,
                color: context.colors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnymeXText(
                    "If you can't donate, watch this ad to support",
                    size: 12.5,
                    variant: TextVariant.bold,
                    color: context.colors.onSurface,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  Obx(() {
                    final count = AdSupportService.instance.watchedCount.value;
                    return AnymeXText(
                      count > 0
                          ? 'Watched: $count • Points rewarded next update'
                          : 'Watch a quick ad to support us for free',
                      size: 11,
                      color: count > 0
                          ? context.colors.primary
                          : context.colors.onSurfaceVariant,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: context.colors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDontShowAgain(BuildContext context) {
    return AnymexOnTap(
      onTap: () {
        General.dontShowDonationDialog.set(true);
        Navigator.of(context).pop();
      },
      scale: 0.96,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off_outlined,
              size: 15,
              color: context.colors.onSurface.opaque(0.45, iReallyMeanIt: true),
            ),
            const SizedBox(width: 6),
            AnymeXText(
              "Don't show again",
              size: 12.5,
              variant: TextVariant.regular,
              color: context.colors.onSurface.opaque(0.5, iReallyMeanIt: true),
            ),
          ],
        ),
      ),
    );
  }
}
