import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/anymex_animated_logo.dart';

/// Splash Screen with Animated Logo
class AnymeXSplashScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  final String? title;
  
  const AnymeXSplashScreen({
    Key? key,
    this.onAnimationComplete,
    this.title,
  }) : super(key: key);

  @override
  State<AnymeXSplashScreen> createState() => _AnymeXSplashScreenState();
}

class _AnymeXSplashScreenState extends State<AnymeXSplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnymeXAnimatedLogo(
              size: 200,
              autoPlay: true,
              onAnimationComplete: () {
                // Navigate to home after animation
                Future.delayed(const Duration(milliseconds: 500), () {
                  widget.onAnimationComplete?.call();
                });
              },
            ),
            const SizedBox(height: 40),
            Text(
              widget.title ?? 'AnymeX',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
