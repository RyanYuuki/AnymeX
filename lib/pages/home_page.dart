import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Anyme',
                    style: TextStyle(
                        fontSize: 40,
                        color: Theme.of(context).colorScheme.inverseSurface),
                  ),
                  TextSpan(
                      text: 'X',
                      style: TextStyle(
                        fontSize: 40,
                        color: Colors.indigo.shade400,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'The NEW Best Anime & Manga App for Android',
              style: TextStyle(fontFamily: 'Poppins-SemiBold'),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _showLoginSheet(context), // Trigger the bottom sheet
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.indigo.shade400,
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.discord,
                  color: Theme.of(context)
                      .colorScheme
                      .inverseSurface
                      .withOpacity(0.6),
                  size: 30,
                ),
                const SizedBox(width: 20),
                Icon(
                  FontAwesomeIcons.github,
                  color: Theme.of(context)
                      .colorScheme
                      .inverseSurface
                      .withOpacity(0.6),
                  size: 30,
                ),
                const SizedBox(width: 15),
                Icon(
                  FontAwesomeIcons.telegram,
                  color: Theme.of(context)
                      .colorScheme
                      .inverseSurface
                      .withOpacity(0.6),
                  size: 30,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // This method shows the login bottom sheet
  void _showLoginSheet(BuildContext context) {
    final loginRoute = CupertinoModalSheetRoute(
      swipeDismissible: true,
      builder: (context) => const _LoginBottomSheet(),
    );

    Navigator.push(context, loginRoute);
  }
}

class _LoginBottomSheet extends StatelessWidget {
  const _LoginBottomSheet();

  @override
  Widget build(BuildContext context) {
    return const DraggableSheet(
      initialExtent: Extent.proportional(1),
      minExtent: Extent.proportional(1),
      physics: BouncingSheetPhysics(
        parent: SnappingSheetPhysics(),
      ),
      child: _LoginContent(),
    );
  }
}

class _LoginContent extends StatelessWidget {
  const _LoginContent();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: Theme.of(context).colorScheme.secondary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Login',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.inverseSurface,
                decoration: TextDecoration.none
              ),
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              style: TextStyle(
                  color: Theme.of(context).colorScheme.inverseSurface),
              placeholder: 'UserName',
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              style: TextStyle(
                  color: Theme.of(context).colorScheme.inverseSurface),
              placeholder: 'Password',
              obscureText: true,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              color: Theme.of(context).colorScheme.tertiary,
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Login!',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              color: Theme.of(context).colorScheme.tertiary,
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
