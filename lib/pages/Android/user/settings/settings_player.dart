import 'dart:developer';
import 'dart:io';

import 'package:anymex/pages/Android/user/settings/modals/tile_with_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class VideoPlayerSettings extends StatefulWidget {
  const VideoPlayerSettings({super.key});

  @override
  State<VideoPlayerSettings> createState() => _VideoPlayerSettingsState();
}

class _VideoPlayerSettingsState extends State<VideoPlayerSettings> {
  late double playBackSpeed;
  String resizeMode = 'Cover';
  List<String> resizeModes = ['Cover', 'Stretch', 'Zoom'];
  Color subtitleColor = Colors.white;
  Color subtitleOutlineColor = Colors.black;
  Color subtitleBackgroundColor = Colors.transparent;
  String subtitleFont = 'Default';
  final List<String> subtitleFonts = [
    'Default',
    'Roboto',
    'Montserrat',
    'Inter',
    'Lato',
    'Oswald',
  ];
  double subtitleSize = 16.0;
  int skipDuration = 10;
  int megaSkipDuration = 85;

  void loadSettingsFromDB() {
    var box = Hive.box('app-data');
    setState(() {
      playBackSpeed = box.get('playbackSpeed', defaultValue: 1.0);
      resizeMode = box.get('resizeMode', defaultValue: 'Cover');
      subtitleColor =
          colorOptions[box.get('subtitleColor', defaultValue: 'White')]!;
      subtitleOutlineColor =
          colorOptions[box.get('subtitleOutlineColor', defaultValue: 'Black')]!;
      subtitleBackgroundColor = colorOptions[
          box.get('subtitleBackgroundColor', defaultValue: 'Default')]!;
      subtitleFont = box.get('subtitleFont', defaultValue: 'Default');
      subtitleSize = box.get('subtitleSize', defaultValue: 16.0);
      skipDuration = box.get('skipDuration', defaultValue: 10);
      megaSkipDuration = box.get('megaSkipDuration', defaultValue: 85);
    });
  }

  @override
  void initState() {
    super.initState();
    loadSettingsFromDB();
  }

  void _showPlaybackSpeedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Default Speed',
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontFamily: 'Poppins-SemiBold',
                fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [0.5, 1.0, 1.5, 2.0].map((speed) {
              return RadioListTile<double>(
                title: Text(speed.toString()),
                value: speed,
                groupValue: playBackSpeed,
                onChanged: (value) {
                  setState(() {
                    playBackSpeed = value!;
                    Hive.box('app-data').put('playbackSpeed', value);
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  final Map<String, Color> colorOptions = {
    'Default': Colors.transparent,
    'White': Colors.white,
    'Black': Colors.black,
    'Red': Colors.red,
    'Green': Colors.green,
    'Blue': Colors.blue,
    'Yellow': Colors.yellow,
    'Cyan': Colors.cyan,
  };

  void _showColorSelectionDialog(
      String title, Color currentColor, Function(String) onColorSelected) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontFamily: 'Poppins-SemiBold',
                fontSize: 20),
          ),
          content: SizedBox(
            height: 300,
            width: double.maxFinite,
            child: ListView(
              children: colorOptions.entries.map((entry) {
                return RadioListTile<Color>(
                  title: Text(entry.key),
                  value: entry.value,
                  groupValue: currentColor,
                  onChanged: (Color? value) {
                    if (value != null) {
                      onColorSelected(entry.key);
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showFontSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Subtitle Font',
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontFamily: 'Poppins-SemiBold',
                fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: subtitleFonts.map((font) {
              return RadioListTile<String>(
                title: Text(font),
                value: font,
                groupValue: subtitleFont,
                onChanged: (value) {
                  setState(() {
                    if (value == "Default") {
                      subtitleFont = "Poppins";
                    } else {
                      subtitleFont = value!;
                    }
                    Hive.box('app-data').put('subtitleFont', subtitleFont);
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
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
                      'Player Settings',
                      style:
                          TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.video_settings,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Playback Speed
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Text('Common',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary)),
          ),
          ListTile(
            leading:
                Icon(Icons.speed, color: Theme.of(context).colorScheme.primary),
            title: const Text(
              'Playback Speed',
              style: TextStyle(fontFamily: "Poppins-SemiBold"),
            ),
            subtitle: Text('${playBackSpeed.toStringAsFixed(1)}x',
                style: TextStyle(
                    fontFamily: 'Poppins-SemiBold',
                    color: Theme.of(context).colorScheme.primary)),
            onTap: _showPlaybackSpeedDialog,
          ),
          // Resize Mode
          if (Platform.isAndroid && Platform.isIOS) ...[
            ListTile(
              leading: Icon(Icons.aspect_ratio,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text(
                'Resize Mode',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(resizeMode,
                  style: TextStyle(
                      fontFamily: 'Poppins-SemiBold',
                      color: Theme.of(context).colorScheme.primary)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(
                        'Select Resize Mode',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontFamily: 'Poppins-SemiBold',
                            fontSize: 20),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: resizeModes
                            .map((mode) => RadioListTile<String>(
                                  title: Text(mode),
                                  value: mode,
                                  groupValue: resizeMode,
                                  onChanged: (value) {
                                    setState(() {
                                      resizeMode = value!;
                                    });
                                    Navigator.pop(context);
                                  },
                                ))
                            .toList(),
                      ),
                    );
                  },
                );
              },
            )
          ],
          TileWithSlider(
            sliderValue: skipDuration.toDouble(),
            min: 5,
            max: 50,
            divisions: 9,
            iconSize: 24,
            onChanged: (double value) {
              setState(() {
                skipDuration = value.toInt();
                Hive.box('app-data').put('skipDuration', value.toInt());
              });
            },
            title: 'DoubleTap to Seek',
            description: 'Adjust Double Tap To Seek Duration',
            icon: Iconsax.forward5,
          ),
          TileWithSlider(
            sliderValue: megaSkipDuration.toDouble(),
            min: 60,
            max: 120,
            divisions: 12,
            iconSize: 24,
            onChanged: (double value) {
              setState(() {
                megaSkipDuration = value.toInt();
                Hive.box('app-data').put('megaSkipDuration', value.toInt());
              });
            },
            title: 'MegaSkip Duration',
            description: 'Adjust MegaSkip Duration',
            icon: Iconsax.forward5,
          ),
          // Subtitle Color
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Text('Subtitles',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary)),
          ),
          ListTile(
            leading: Icon(Icons.palette,
                color: Theme.of(context).colorScheme.primary),
            title: const Text(
              'Subtitle Color',
              style: TextStyle(fontFamily: "Poppins-SemiBold"),
            ),
            onTap: () {
              _showColorSelectionDialog('Select Subtitle Color', subtitleColor,
                  (color) {
                setState(() {
                  subtitleColor = colorOptions[color]!;
                });
                Hive.box('app-data').put('subtitleColor', color);
              });
            },
          ),
          // Subtitle Outline Color
          if (Platform.isAndroid && Platform.isIOS) ...[
            ListTile(
              leading: Icon(Icons.palette,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text(
                'Subtitle Outline Color',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                _showColorSelectionDialog(
                    'Select Subtitle Outline Color', subtitleOutlineColor,
                    (color) {
                  setState(() {
                    subtitleOutlineColor = colorOptions[color]!;
                  });
                  Hive.box('app-data').put('subtitleOutlineColor', color);
                });
              },
            )
          ],

          // Subtitle Background Color
          ListTile(
            leading: Icon(Icons.palette,
                color: Theme.of(context).colorScheme.primary),
            title: const Text(
              'Subtitle Background Color',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              _showColorSelectionDialog(
                  'Select Subtitle Background Color', subtitleBackgroundColor,
                  (color) {
                setState(() {
                  subtitleBackgroundColor = colorOptions[color]!;
                });
                Hive.box('app-data').put('subtitleBackgroundColor', color);
              });
            },
          ),
          // Subtitle Font
          ListTile(
            leading: Icon(Icons.text_fields,
                color: Theme.of(context).colorScheme.primary),
            title: const Text(
              'Subtitle Font',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(subtitleFont,
                style: TextStyle(
                    fontFamily: "Poppins-SemiBold",
                    color: Theme.of(context).colorScheme.primary)),
            onTap: _showFontSelectionDialog,
          ),
          // Subtitle Preview
          TileWithSlider(
            sliderValue: subtitleSize,
            min: 12.0,
            max: 30.0,
            divisions: 18,
            iconSize: 24,
            onChanged: (double value) {
              setState(() {
                subtitleSize = value;
                Hive.box('app-data').put('subtitleSize', value);
              });
            },
            title: 'Subtitle Size',
            description: 'Adjust Sub Size ',
            icon: Iconsax.subtitle5,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Subtitle Preview',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Container(
                  alignment: Alignment.center,
                  color: subtitleBackgroundColor,
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'Subtitle Preview Text',
                    style: GoogleFonts.getFont(
                      subtitleFont == "Default" ? "Poppins" : subtitleFont,
                      color: subtitleColor,
                      fontSize: subtitleSize,
                      shadows: [
                        Shadow(
                          offset: const Offset(1.0, 1.0),
                          blurRadius: 2.0,
                          color: subtitleOutlineColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
