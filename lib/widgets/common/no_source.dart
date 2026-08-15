import 'dart:io';
import 'package:anymex/screens/extensions/ExtensionScreen.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';

class NoSourceSelectedWidget extends StatelessWidget {
  const NoSourceSelectedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isMobile = Platform.isAndroid || Platform.isIOS;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.opaque(0.2, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.primaryContainer.opaque(0.25, iReallyMeanIt: true),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.extension_off_rounded,
              size: 28,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const AnymeXText(
            text: 'No Source Installed',
            variant: TextVariant.bold,
            size: 16,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          AnymeXText(
            text: isMobile
                ? 'Install a source extension to start browsing content.'
                : 'Go back to the home page and install a source extension.',
            size: 13,
            color: colors.onSurface.opaque(0.55, iReallyMeanIt: true),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          AnymeXContainerButton(
            onTap: () {
              if (isMobile) {
                navigate(() => const ExtensionScreen());
              } else {
                Navigator.pop(context);
              }
            },
            radius: 14,
            color: colors.primary,
            enableGlow: true,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isMobile ? Icons.extension_rounded : Icons.home_rounded,
                  size: 18,
                  color: colors.onPrimary,
                ),
                const SizedBox(width: 8),
                AnymeXText(
                  text: isMobile ? 'Browse Extensions' : 'Go to Home',
                  variant: TextVariant.semiBold,
                  size: 14,
                  color: colors.onPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
