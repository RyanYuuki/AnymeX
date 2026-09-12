import 'package:flutter/material.dart';
import 'package:anymex/controllers/custom_logo/custom_logo_service.dart';
import 'package:anymex/models/custom_logo_model.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_animated_logo.dart';

/// Splash Screen with Animated Logo
class AnymeXSplashScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;

  const AnymeXSplashScreen({
    super.key,
    this.onAnimationComplete,
  });

  @override
  State<AnymeXSplashScreen> createState() => _AnymeXSplashScreenState();
}

class _AnymeXSplashScreenState extends State<AnymeXSplashScreen> {
  @override
  Widget build(BuildContext context) {
    final customLogo = CustomLogoService.getSelectedCustomLogo();
    final sizeMode = customLogo?.sizeMode ?? CustomLogoSizeMode.defaultSize;
    final isOriginal = sizeMode == CustomLogoSizeMode.originalSize;
    final isCustomScale = sizeMode == CustomLogoSizeMode.customScale;
    final customScale = customLogo?.customScale ?? 1.0;

    Widget logoWidget = AnymeXAnimatedLogo(
      size: 200,
      useOriginalSize: isOriginal ? true : null,
      autoPlay: true,
      onAnimationComplete: () {
        // Navigate to home after animation
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onAnimationComplete?.call();
        });
      },
    );

    if (isCustomScale) {
      logoWidget = Transform.scale(
        scale: customScale,
        alignment: Alignment.center,
        child: logoWidget,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width,
            maxHeight: MediaQuery.sizeOf(context).height,
          ),
          child: logoWidget,
        ),
      ),
    );
  }
}
