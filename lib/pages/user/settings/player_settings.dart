import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

class VideoPlayerSettings extends StatefulWidget {
  const VideoPlayerSettings({super.key});

  @override
  State<VideoPlayerSettings> createState() => _VideoPlayerSettingsState();
}

class _VideoPlayerSettingsState extends State<VideoPlayerSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ListView(
        children: [
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  IconlyBroken.arrow_left_2,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Player',
                      style:
                          TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.video_settings,
                          size: 40,
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ListTile(
            leading: Icon(
              Icons.speed,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text(
              'Default Playback Speed: 1.0x',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.fullscreen,
                color: Theme.of(context).colorScheme.primary),
            title: const Text(
              'Default Resize Mode',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.palette,
                color: Theme.of(context).colorScheme.primary),
            title: const Text(
              'Subtitle Color',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.palette,
                color: Theme.of(context).colorScheme.primary),
            title: const Text(
              'Subtitle Outline Color',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.palette,
                color: Theme.of(context).colorScheme.primary),
            title: const Text(
              'Subtitle Background Color',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.type_specimen_rounded,
                color: Theme.of(context).colorScheme.primary),
            title: const Text(
              'Subtitle Font',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
