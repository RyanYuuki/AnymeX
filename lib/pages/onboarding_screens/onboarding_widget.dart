// onboarding_widgets.dart
import 'package:flutter/material.dart';

class OnboardingButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const OnboardingButton({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}

class OnboardingText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const OnboardingText({
    Key? key,
    required this.text,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: TextAlign.center,
    );
  }
}
