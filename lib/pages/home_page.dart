import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.indigo.shade400,
              ),
              child: const Text(
                'Login',
                style: TextStyle(color: Colors.white),
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
}
