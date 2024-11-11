import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

const String telegramUrl = 'https://t.me/AnymeX_Discussion';
const String githubUrl = 'https://github.com/RyanYuuki/AnymeX';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      log('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                height: 200,
                width: 200,
                child: Image.asset('assets/images/logo_transparent.png'),
              ),
              const Text(
                'AnymeX',
                style: TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 20),
              Text(
                'Version: 2.7.1',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10.0),
                child: const Text(
                  'Heyyy Guys! This is AnymeX Developer (Ryan), Thanks you for using this app. it really means a lot! if you want to provide any kind of feedback or you want any feature implemented please join our telegram group and share your idea there!',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _launchUrl(telegramUrl),
                    icon: const Icon(Icons.telegram, size: 50),
                  ),
                  IconButton(
                    onPressed: () => _launchUrl(githubUrl),
                    icon: const Icon(HugeIcons.strokeRoundedGithub01, size: 48),
                  ),
                ],
              ),
              const Expanded(child: SizedBox.shrink()),
              const Text('- Ryan Yuuki >_<'),
            ],
          ),
        ),
      ),
    );
  }
}
