import 'package:anymex/l10n/l10n_extension.dart';
import 'package:get/get.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_border.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';

class AnymeXSheetRow {
  final String label;
  final Widget? labelTrailing;
  final String? value;
  final Widget? valueWidget;
  final Color? labelColor;
  final Color? valueColor;

  const AnymeXSheetRow({
    required this.label,
    this.labelTrailing,
    this.value,
    this.valueWidget,
    this.labelColor,
    this.valueColor,
  });
}

class AnymeXSheetFooterCard {
  final String overline;
  final String title;
  final Widget? trailing;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AnymeXSheetFooterCard({
    required this.overline,
    required this.title,
    this.trailing,
    this.backgroundColor,
    this.onTap,
  });
}

class AnymeXSheet extends StatelessWidget {
  final Widget? headerIcon;
  final String? heroTitle;
  final String? heroSubtitle;
  final String? title;
  final String? message;
  final Widget? contentWidget;
  final Widget? customWidget;
  final List<AnymeXSheetRow> rows;
  final AnymeXSheetFooterCard? footerCard;
  final String? primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final bool isPrimaryLoading;
  final Color? primaryButtonColor;
  final Color? primaryButtonTextColor;
  final String? disclaimerText;
  final Color? backgroundColor;
  final bool showDragHandle;
  final double borderRadius;

  const AnymeXSheet({
    super.key,
    this.headerIcon,
    this.heroTitle,
    this.heroSubtitle,
    this.title,
    this.message,
    this.contentWidget,
    this.customWidget,
    this.rows = const [],
    this.footerCard,
    this.primaryButtonText,
    this.onPrimaryPressed,
    this.isPrimaryLoading = false,
    this.primaryButtonColor,
    this.primaryButtonTextColor,
    this.disclaimerText,
    this.backgroundColor,
    this.showDragHandle = false,
    this.borderRadius = 32.0,
  });

  static Future<T?> custom<T>(
    Widget widget,
    BuildContext context, {
    bool showDragHandle = false,
    double borderRadius = 32.0,
  }) =>
      AnymeXSheet(
        customWidget: widget,
        showDragHandle: showDragHandle,
        borderRadius: borderRadius,
      ).show<T>(context);

  Future<T?> show<T>(
    BuildContext context, {
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      enableDrag: enableDrag,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 400),
        reverseDuration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (context) => AnymeXSheet(
        headerIcon: headerIcon,
        heroTitle: heroTitle,
        heroSubtitle: heroSubtitle,
        title: title,
        message: message,
        contentWidget: contentWidget,
        customWidget: customWidget,
        rows: rows,
        footerCard: footerCard,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        isPrimaryLoading: isPrimaryLoading,
        primaryButtonColor: primaryButtonColor,
        primaryButtonTextColor: primaryButtonTextColor,
        disclaimerText: disclaimerText,
        backgroundColor: backgroundColor,
        showDragHandle: showDragHandle,
        borderRadius: borderRadius,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sheetBg = backgroundColor ?? colors.surface;
    final primaryTextColor = colors.onSurface;
    final secondaryTextColor =
        colors.onSurface.opaque(0.6, iReallyMeanIt: true);
    final cardBg = colors.surfaceContainer;
    final buttonBg = primaryButtonColor ?? colors.primary;
    final buttonFg = primaryButtonTextColor ?? colors.onPrimary;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: colors.outline.opaque(0.1, iReallyMeanIt: true),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: -2,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDragHandle)
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: secondaryTextColor.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                if (headerIcon != null) ...[
                  headerIcon!,
                  const SizedBox(height: 12),
                ],
                if (heroTitle != null && heroTitle!.isNotEmpty) ...[
                  AnymeXText(
                    heroTitle!,
                    size: 24,
                    variant: TextVariant.bold,
                    color: primaryTextColor,
                  ),
                ],
                if (heroSubtitle != null && heroSubtitle!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  AnymeXText(
                    heroSubtitle!,
                    size: 13,
                    variant: TextVariant.regular,
                    color: secondaryTextColor,
                  ),
                ],
                if (title != null && heroTitle == null) ...[
                  AnymeXText(
                    title!,
                    size: 18,
                    variant: TextVariant.bold,
                    color: primaryTextColor,
                  ),
                  const SizedBox(height: 10),
                ],
                if (customWidget != null) ...[
                  if (heroTitle != null || headerIcon != null)
                    const SizedBox(height: 16),
                  customWidget!,
                ],
                if (contentWidget != null) ...[
                  if (heroTitle != null || headerIcon != null)
                    const SizedBox(height: 16),
                  contentWidget!,
                ],
                if (message != null &&
                    customWidget == null &&
                    contentWidget == null) ...[
                  const SizedBox(height: 10),
                  AnymeXText(
                    message!,
                    textAlign: TextAlign.center,
                    size: 14,
                    color: secondaryTextColor,
                  ),
                ],
                if (rows.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  ...rows.map((row) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          AnymeXText(
                            row.label,
                            size: 14,
                            color: row.labelColor ?? secondaryTextColor,
                          ),
                          if (row.labelTrailing != null) ...[
                            const SizedBox(width: 6),
                            row.labelTrailing!,
                          ],
                          const Spacer(),
                          if (row.valueWidget != null)
                            row.valueWidget!
                          else if (row.value != null)
                            AnymeXText(
                              row.value!,
                              size: 14,
                              variant: TextVariant.semiBold,
                              color: row.valueColor ?? primaryTextColor,
                            ),
                        ],
                      ),
                    );
                  }),
                ],
                if (footerCard != null) ...[
                  const SizedBox(height: 14),
                  AnymexOnTap(
                    onTap: footerCard!.onTap,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: footerCard!.backgroundColor ?? cardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnymeXText(
                                  footerCard!.overline.toUpperCase(),
                                  size: 10,
                                  variant: TextVariant.bold,
                                  color: secondaryTextColor,
                                ),
                                const SizedBox(height: 4),
                                AnymeXText(
                                  footerCard!.title,
                                  size: 14,
                                  variant: TextVariant.bold,
                                  color: primaryTextColor,
                                ),
                              ],
                            ),
                          ),
                          if (footerCard!.trailing != null)
                            footerCard!.trailing!,
                        ],
                      ),
                    ),
                  ),
                ],
                if (primaryButtonText != null) ...[
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isPrimaryLoading ? null : onPrimaryPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonBg,
                        foregroundColor: buttonFg,
                        disabledBackgroundColor:
                            buttonBg.withValues(alpha: 0.6),
                        disabledForegroundColor:
                            buttonFg.withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            borderRadius.clamp(18.0, 36.0),
                          ),
                        ),
                      ),
                      child: isPrimaryLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: buttonFg,
                              ),
                            )
                          : AnymeXText(
                              primaryButtonText!,
                              size: 16,
                              variant: TextVariant.bold,
                              color: buttonFg,
                            ),
                    ),
                  ),
                ],
                if (disclaimerText != null &&
                    disclaimerText!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: AnymeXText(
                      disclaimerText!,
                      size: 12,
                      color: secondaryTextColor,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget loginSheetHelper({
  required BuildContext context,
  required String title,
  required String serviceName,
  bool showTokenOption = false,
}) {
  final colors = context.colors;

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.login_rounded,
              color: colors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnymeXText(
                title,
                style: const TextStyle(
                  fontFamily: 'Linotte',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
      const Divider(height: 20, thickness: 1),
      const SizedBox(height: 8),
      AnymexOnTap(
        onTap: () => Navigator.pop(context, 'browser_internal'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AnymeXBorder.decoration(
            context,
            color: colors.surfaceContainer.opaque(0.3, iReallyMeanIt: true),
            radius: 16,
          ),
          child: Row(
            children: [
              Icon(
                Icons.open_in_new_rounded,
                color: colors.primary,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymeXText(
                      context.l10n.internalBrowser,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnymeXText(
                      context.l10n.loginInsideTheAppRecommended,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurface.opaque(0.55, iReallyMeanIt: true),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurface.opaque(0.4, iReallyMeanIt: true),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      AnymexOnTap(
        onTap: () => Navigator.pop(context, 'browser_external'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AnymeXBorder.decoration(
            context,
            color: colors.surfaceContainer.opaque(0.3, iReallyMeanIt: true),
            radius: 16,
          ),
          child: Row(
            children: [
              Icon(
                Icons.explore_outlined,
                color: colors.primary,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymeXText(
                      context.l10n.externalBrowser,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnymeXText(
                      context.l10n.loginUsingYourDefaultBrowser,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurface.opaque(0.55, iReallyMeanIt: true),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurface.opaque(0.4, iReallyMeanIt: true),
              ),
            ],
          ),
        ),
      ),
      if (showTokenOption) ...[
        const SizedBox(height: 12),
        AnymexOnTap(
          onTap: () => Navigator.pop(context, 'token'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AnymeXBorder.decoration(
              context,
              color: colors.surfaceContainer.opaque(0.3, iReallyMeanIt: true),
              radius: 16,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.vpn_key_rounded,
                  color: colors.primary,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXText(
                        context.l10n.loginWithToken,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnymeXText(
                        context.l10n.manuallyPasteOauthAccessToken,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurface.opaque(0.55, iReallyMeanIt: true),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurface.opaque(0.4, iReallyMeanIt: true),
                ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 8),
    ],
  );
}
