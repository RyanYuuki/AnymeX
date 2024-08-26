// ignore_for_file: library_private_types_in_public_api

import 'package:aurora/pages/onboarding_screens/onboarding_widget.dart';
import 'package:aurora/pages/onboarding_screens/login_page.dart';
import 'package:aurora/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreens extends StatefulWidget {
  const OnboardingScreens({super.key});

  @override
  _OnboardingScreensState createState() => _OnboardingScreensState();
}

class _OnboardingScreensState extends State<OnboardingScreens> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              children: [
                OnboardingPage1(controller: _pageController),
                OnboardingPage2(controller: _pageController),
                OnboardingPage3(controller: _pageController),
                const LoginPage(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildPageIndicator(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context) {
    return SmoothPageIndicator(
      controller: _pageController,
      count: 4,
      effect: WormEffect(
        activeDotColor: Theme.of(context).colorScheme.primary,
        dotHeight: 8.0,
        dotWidth: 8.0,
      ),
    );
  }
}

class OnboardingPage1 extends StatelessWidget {
  final PageController controller;

  const OnboardingPage1({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const OnboardingText(
            text: 'Welcome to AnymeX',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const OnboardingText(
            text:
                'Stream and read your favorite anime and manga anytime, anywhere.',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 40),
          OnboardingButton(
            text: 'Next',
            onPressed: () {
              controller.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease,
              );
            },
          ),
        ],
      ),
    );
  }
}

class OnboardingPage2 extends StatelessWidget {
  final PageController controller;

  const OnboardingPage2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const OnboardingText(
            text: 'Which Theme Would you Prefer?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const OnboardingText(
            text: 'Choose your preferred theme:',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              minimumSize: const Size(double.infinity, 60),
              backgroundColor:
                  Theme.of(context).colorScheme.onPrimaryFixedVariant,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 20),
            ),
            onPressed: () {
              themeProvider.setLightMode();
              controller.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease,
              );
            },
            child: const Text(
              'Light Mode',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              minimumSize: const Size(double.infinity, 60),
              backgroundColor:
                  Theme.of(context).colorScheme.onPrimaryFixedVariant,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 20),
            ),
            onPressed: () {
              themeProvider.setDarkMode();
              controller.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease,
              );
            },
            child: const Text('Dark Mode',
                style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage3 extends StatelessWidget {
  final PageController controller;

  const OnboardingPage3({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const OnboardingText(
            text: 'Ready to Explore?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const OnboardingText(
            text: 'Start your journey by giving us your name!',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 40),
          OnboardingButton(
            text: 'Next',
            onPressed: () {
              controller.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease,
              );
            },
          ),
        ],
      ),
    );
  }
}
