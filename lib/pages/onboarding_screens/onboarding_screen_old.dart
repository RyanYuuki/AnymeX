import 'package:aurora/pages/onboarding_screens/avatar_page.dart';
import 'package:aurora/pages/onboarding_screens/onboarding_widgets.dart';
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
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  void _onNextPressed() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AvatarPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              children: const [
                OnboardingPage1(),
                OnboardingPage2(),
                OnboardingPage3(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildPageIndicator(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onPrimaryFixedVariant,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                minimumSize: const Size(double.infinity, 48),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: _onNextPressed,
              child: Text(_currentPage == 2 ? 'Get Started' : 'Next'),
            ),
          ),
          const SizedBox(height: 20), 
        ],
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context) {
    return SmoothPageIndicator(
      controller: _pageController,
      count: 3,
      effect: WormEffect(
        activeDotColor: Theme.of(context).colorScheme.primary,
        dotHeight: 8.0,
        dotWidth: 8.0,
      ),
    );
  }
}

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OnboardingText(
            text: 'Welcome to AnymeX',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          OnboardingText(
            text:
                'Stream and read your favorite anime and manga anytime, anywhere.',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const OnboardingText(
            text: 'Which Theme Would You Prefer?',
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
          _buildThemeButton(
            context: context,
            text: 'Light Mode',
            onPressed: () {
              themeProvider.setLightMode();
            },
            backgroundColor: Colors.white,
            textColor: Colors.black,
            borderColor: Colors.grey.shade300,
            icon: Icons.light_mode,
          ),
          const SizedBox(height: 20),
          _buildThemeButton(
            context: context,
            text: 'Dark Mode',
            onPressed: () {
              themeProvider.setDarkMode();
            },
            backgroundColor: Colors.black,
            textColor: Colors.white,
            borderColor: Colors.grey.shade700,
            icon: Icons.dark_mode,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
    required IconData icon,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        minimumSize: const Size(double.infinity, 60),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        textStyle: const TextStyle(fontSize: 20, fontFamily: 'Poppins'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 2),
        ),
        elevation: 5,
      ),
      icon: Icon(
        icon,
        size: 28,
        color: textColor,
      ),
      label: Text(text),
      onPressed: onPressed,
    );
  }
}


class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OnboardingText(
            text: 'Ready to Explore?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          OnboardingText(
            text: 'Start your journey by giving us your name!',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
