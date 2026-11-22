import 'package:anymex/l10n/l10n_extension.dart';
import 'dart:io';

import 'package:anymex/services/ad_support_service.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsDonation extends StatefulWidget {
  const SettingsDonation({super.key});

  @override
  State<SettingsDonation> createState() => _SettingsDonationState();
}

class _SettingsDonationState extends State<SettingsDonation> {
  static const String _upiId = 'ryan404@ptaxis';
  static const String _paypalUrl = 'https://paypal.me/reyyuuki';
  static const String _githubUrl = 'https://github.com/RyanYuuki/AnymeX';

  Future<void> _copyUpiId() async {
    await Clipboard.setData(const ClipboardData(text: _upiId));
    snackBar('UPI ID copied: $_upiId');
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        snackBar(Get.context!.l10n.couldNotOpenLink);
      }
    } catch (_) {
      snackBar(Get.context!.l10n.couldNotOpenLink);
    }
  }

  Future<void> _launchUpiScheme(String uriString) async {
    final uri = Uri.parse(uriString);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await _copyUpiId();
      }
    } catch (_) {
      await _copyUpiId();
    }
  }

  Future<void> _handleUpiTap(BuildContext context) async {
    if (Platform.isAndroid) {
      final uri = Uri.parse(
        'upi://pay?pa=$_upiId&pn=Ryan&cu=INR&tn=AnymeX%20Donation',
      );
      try {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          if (context.mounted) {
            _showIosUpiPicker(context);
          }
        }
      } catch (_) {
        if (context.mounted) {
          _showIosUpiPicker(context);
        }
      }
    } else if (Platform.isIOS) {
      _showIosUpiPicker(context);
    } else {
      await _copyUpiId();
    }
  }

  void _showIosUpiPicker(BuildContext context) {
    AnymeXDialog(
      title: context.l10n.chooseUpiApp,
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUpiAppItem(
            title: context.l10n.googlePay,
            icon: Icons.account_balance_wallet_rounded,
            onTap: () {
              Get.back();
              _launchUpiScheme(
                'gpay://upi/pay?pa=$_upiId&pn=Ryan&cu=INR&tn=AnymeX%20Donation',
              );
            },
          ),
          const SizedBox(height: 8),
          _buildUpiAppItem(
            title: context.l10n.phonepe,
            icon: Icons.account_balance_wallet_rounded,
            onTap: () {
              Get.back();
              _launchUpiScheme(
                'phonepe://upi/pay?pa=$_upiId&pn=Ryan&cu=INR&tn=AnymeX%20Donation',
              );
            },
          ),
          const SizedBox(height: 8),
          _buildUpiAppItem(
            title: context.l10n.paytm,
            icon: Icons.account_balance_wallet_rounded,
            onTap: () {
              Get.back();
              _launchUpiScheme(
                'paytmmp://upi/pay?pa=$_upiId&pn=Ryan&cu=INR&tn=AnymeX%20Donation',
              );
            },
          ),
          const SizedBox(height: 8),
          _buildUpiAppItem(
            title: context.l10n.bhimUpi,
            icon: Icons.account_balance_wallet_rounded,
            onTap: () {
              Get.back();
              _launchUpiScheme(
                'bhim://upi/pay?pa=$_upiId&pn=Ryan&cu=INR&tn=AnymeX%20Donation',
              );
            },
          ),
          const SizedBox(height: 8),
          _buildUpiAppItem(
            title: 'Copy UPI ID ($_upiId)',
            icon: Icons.copy_rounded,
            onTap: () {
              Get.back();
              _copyUpiId();
            },
          ),
        ],
      ),
      showCancelButton: false,
      confirmText: context.l10n.close,
      onConfirm: () {},
    ).show(context);
  }

  Widget _buildUpiAppItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return AnymeXContainer(
      width: double.infinity,
      color: colors.surfaceContainerHighest.opaque(0.5),
      radius: 12,
      border: Border.all(color: colors.outlineVariant.opaque(0.2)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.primary.opaque(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colors.primary, size: 20),
        ),
        title: AnymeXText(
          title,
          variant: TextVariant.semiBold,
          size: 14,
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.opaque(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.opaque(0.25), width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.primary.opaque(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: colors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          AnymeXText(
            context.l10n.supportAnymex,
            variant: TextVariant.bold,
            size: 20,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          AnymeXText(
            context.l10n.anymexIs100FreeOpenSourceAnd,
            variant: TextVariant.regular,
            size: 13,
            color: colors.onSurfaceVariant,
            textAlign: TextAlign.center,
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildAdSupportSection(BuildContext context) {
    final colors = context.colors;
    return AnymeXSectionBuilder(
      title: context.l10n.freeSupport,
      children: [
        AnymeXContainer(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: colors.primary.opaque(0.08, iReallyMeanIt: true),
          radius: 16,
          border: Border.all(
            color: colors.primary.opaque(0.28, iReallyMeanIt: true),
            width: 1.2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.opaque(0.15, iReallyMeanIt: true),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.play_circle_filled_rounded,
                      color: colors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymeXText(
                          context.l10n.watchAnAdToSupport,
                          variant: TextVariant.bold,
                          size: 15,
                        ),
                        const SizedBox(height: 4),
                        AnymeXText(
                          "Can't donate money? Support AnymeX for free by watching a short ad! You will be rewarded points in the next update based on how many ads you've watched.",
                          variant: TextVariant.regular,
                          size: 12.5,
                          color: colors.onSurfaceVariant,
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() {
                    final count = AdSupportService.instance.watchedCount.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest
                            .opaque(0.6, iReallyMeanIt: true),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.outlineVariant
                              .opaque(0.25, iReallyMeanIt: true),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 6),
                          AnymeXText(
                            'Ads Watched: $count',
                            variant: TextVariant.bold,
                            size: 13,
                            color: colors.onSurface,
                          ),
                        ],
                      ),
                    );
                  }),
                  AnymexOnTap(
                    onTap: () => AdSupportService.instance.watchAd(),
                    scale: 0.96,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary
                                .opaque(0.25, iReallyMeanIt: true),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 18,
                            color: colors.onPrimary,
                          ),
                          const SizedBox(width: 4),
                          AnymeXText(
                            context.l10n.watchAd,
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
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: context.l10n.donateSupport,
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16.0,
            AnymeXHeaderScope.of(ctx),
            16.0,
            32.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(context),
              const SizedBox(height: 20),
              _buildAdSupportSection(context),
              const SizedBox(height: 20),
              AnymeXSectionBuilder(
                title: context.l10n.indiaUpi,
                children: [
                  AnymeXTile(
                    icon: Icons.account_balance_wallet_rounded,
                    title: context.l10n.payViaAnyUpiApp,
                    subtitle: '$_upiId • Tap to launch GPay, PhonePe, Paytm, etc.',
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                    onTap: () => _handleUpiTap(context),
                  ),
                  AnymeXTile(
                    icon: Icons.copy_rounded,
                    title: context.l10n.copyUpiId,
                    subtitle: _upiId,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.primary.opaque(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AnymeXText(
                        context.l10n.copy,
                        size: 12,
                        variant: TextVariant.bold,
                        color: context.colors.primary,
                      ),
                    ),
                    onTap: _copyUpiId,
                  ),
                  AnymeXTile(
                    icon: Icons.info_outline_rounded,
                    title: context.l10n.supportedUpiApps,
                    subtitle:
                        context.l10n.compatibleWithGooglePayPhonepePaytm,
                    showChevron: false,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AnymeXSectionBuilder(
                title: context.l10n.international,
                children: [
                  AnymeXTile(
                    icon: Icons.payment_rounded,
                    title: context.l10n.donateViaPaypal,
                    subtitle: context.l10n.paypalMeReyyuukiCardsPaypalBalance,
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                    onTap: () => _openUrl(_paypalUrl),
                  ),
                  AnymeXTile(
                    icon: Icons.info_outline_rounded,
                    title: context.l10n.paypalRecipientNotice,
                    subtitle:
                        'The name on PayPal may display as Rey Yuuki (friend\'s account), but all contributions directly support AnymeX.',
                    showChevron: false,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AnymeXSectionBuilder(
                title: context.l10n.otherWaysToSupport,
                children: [
                  AnymeXTile(
                    icon: HugeIcons.strokeRoundedGithub,
                    title: context.l10n.starOnGithub,
                    subtitle: context.l10n.githubComRyanyuukiAnymexShowYour,
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                    onTap: () => _openUrl(_githubUrl),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
