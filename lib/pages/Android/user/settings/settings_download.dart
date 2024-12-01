import 'package:anymex/pages/Android/user/settings/modals/tile_with_slider.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:iconly/iconly.dart';

class SettingsDownload extends StatefulWidget {
  const SettingsDownload({super.key});

  @override
  State<SettingsDownload> createState() => _SettingsDownloadState();
}

class _SettingsDownloadState extends State<SettingsDownload> {
  late int parallelDownloads;
  late int retries;

  @override
  void initState() {
    super.initState();
    parallelDownloads =
        Hive.box('app-data').get('parallelDownloads', defaultValue: 3);
    retries = Hive.box('app-data').get('downloadRetries', defaultValue: 5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: ListView(children: [
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Downloads',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.download,
                      size: 40,
                    ))
              ],
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Common',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                ]),
          ),
          TileWithSlider(
              sliderValue: parallelDownloads.floor().toDouble(),
              onChanged: (value) {
                setState(() {
                  parallelDownloads = value.toInt();
                });
                Hive.box('app-data').put('parallelDownloads', value.toInt());
              },
              title: 'Parallel Download',
              description: 'Increase speed even more!',
              icon: (Icons.downloading),
              min: 1.floor().toDouble(),
              divisions: 10,
              max: 50.floor().toDouble()),
          TileWithSlider(
              sliderValue: retries.floor().toDouble(),
              onChanged: (value) {
                setState(() {
                  retries = value.toInt();
                });
                Hive.box('app-data').put('downloadRetries', value.toInt());
              },
              title: 'Download Retries',
              description: 'Recommended on Slow Networks',
              icon: (Icons.restart_alt),
              min: 1.floor().toDouble(),
              divisions: 10,
              max: 10.floor().toDouble()),
        ]));
  }
}
