import 'dart:io';
import 'package:flutter/material.dart';

class NoSourceSelectedWidget extends StatelessWidget {
  const NoSourceSelectedWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Platform.isAndroid || Platform.isIOS;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "No Source Selected",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Subtitle Text
            Text(
              "Please select a source to continue.\nIf no sources are installed, you can ${isMobile ? "install one from the Extensions page" : "go back to the Home page."}",
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (isMobile) {
                  // Navigator.pushReplacement(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => const ExtensionScreen(),
                  //   ),
                  // );
                } else {
                  Navigator.pop(
                    context,
                  );
                }
              },
              icon: const Icon(Icons.extension),
              label: Text(isMobile ? "Go to Extensions" : "Go to Home Page",
                  style: const TextStyle(fontFamily: "Poppins-SemiBold")),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
