import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnymeXAnimatedLogo(
          size: 200,
          autoPlay: true,
          onAnimationComplete: () {
            // Navigate to home after animation
            Future.delayed(const Duration(milliseconds: 500), () {
              widget.onAnimationComplete?.call();
            });
          },
        ),
      ),
    );
  }
}
