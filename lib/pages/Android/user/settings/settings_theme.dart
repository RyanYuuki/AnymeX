import 'dart:ui';

import 'package:anymex/components/android/setting/scheme_varaint_dialog.dart';
import 'package:flutter/material.dart';
import 'package:anymex/components/android/common/custom_tile.dart';
import 'package:anymex/components/android/common/switch_tile_stateless.dart';
import 'package:anymex/hiveData/themeData/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  final box = Hive.box('login-data');
  late final palettedMode = box.get('PaletteMode', defaultValue: 'Material');
  late bool isLightMode = box.get('Theme', defaultValue: 'dark') == 'light';
  late bool isDarkMode = box.get('Theme', defaultValue: 'dark') == 'dark';
  bool? value1;
  bool? value2;
  bool? value3;
  bool? value4;
  int? selectedIndex;
  int? selectedColorIndex;
  bool? isCustomTheme;
  bool isAndroid12orAbove = true;

  List<MaterialColor> colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
  ];

  List<String> colorsName = [
    'Red',
    'Pink',
    'Purple',
    'DeepPurple',
    'Indigo',
    'Blue',
    'LightBlue',
    'Cyan',
    'Teal',
    'Green',
    'LightGreen',
    'Lime',
    'Yellow',
    'Amber',
    'Orange',
    'DeepOrange',
    'Brown',
  ];

  @override
  void initState() {
    super.initState();
    initStates();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _selectChip(int index) {
    setState(() {
      selectedIndex = index;
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      if (index == 0) {
        themeProvider.setLightMode();
      } else if (index == 1) {
        themeProvider.setDarkMode();
      } else if (index == 2) {
        Hive.box('login-data').put('Theme', 'system');
      }
      box.put(
          'Theme',
          index == 0
              ? 'light'
              : index == 1
                  ? 'dark'
                  : 'system');
    });
  }

  void _selectColor(int index) {
    setState(() {
      selectedColorIndex = index;
      MaterialColor newColor = colors[selectedColorIndex ?? 0];
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.changeSeedColor(newColor);
      box.put('SelectedColorIndex', selectedColorIndex);
    });
  }

  void _toggleSwitch(int index) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    setState(() {
      if (index == 1) {
        value1 = true;
        value3 = false;
        value4 = false;
        if (value1!) {
          isCustomTheme = false;
          themeProvider.loadDynamicTheme();
        }
        box.put('PaletteMode', 'Material');
      } else if (index == 2) {
        value2 = !value2!;
        box.put('isOled', value2);
        if (value2!) {
          themeProvider.setOledTheme(true);
        } else {
          themeProvider.setOledTheme(false);
        }
      } else if (index == 3) {
        value4 = false;
        value1 = false;
        value3 = true;
        box.put('PaletteMode', 'Custom');
        if (value3!) {
          isCustomTheme = true;
        }
      } else if (index == 4) {
        value3 = false;
        value1 = false;
        value4 = true;
        box.put('PaletteMode', 'Banner');
        if (value4!) {
          isCustomTheme = false;
        }
      }
    });
  }

  void _showSchemeVariantDialog() {
    showDialog(
      context: context,
      builder: (context) => SchemeVariantDialog(
        selectedVariant: box.get('DynamicPalette', defaultValue: 'tonalSpot'),
        onVariantSelected: (variant) {
          final themeProvider =
              Provider.of<ThemeProvider>(context, listen: false);
          box.put('DynamicPalette', variant);
          if (isLightMode) {
            themeProvider.setLightMode();
          } else {
            themeProvider.setDarkMode();
          }
        },
      ),
    );
  }

  void initStates() {
    isAndroid12orAbove =
        Hive.box('app-data').get('isAndroid12orAbove', defaultValue: true);
    // Themes Switches
    value1 = box.get('PaletteMode') == 'Material';
    value2 = box.get('isOled', defaultValue: false);
    value3 = box.get('PaletteMode') == 'Custom';
    value4 = box.get('PaletteMode') == 'Banner';
    if (value2!) {
      isCustomTheme = true;
    } else {
      isCustomTheme = false;
    }

    // Light and Dark Mode Chips
    if (isLightMode) {
      selectedIndex = 0;
    } else if (isDarkMode) {
      selectedIndex = 1;
    } else {
      selectedIndex = 2;
    }

    int? colorIndex = box.get('SelectedColorIndex');
    if (colorIndex != null && colorIndex < colors.length) {
      selectedColorIndex = colorIndex;
    } else {
      selectedColorIndex = 0;
    }
  }

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Themes',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                IconButton(
                    onPressed: _showSchemeVariantDialog,
                    icon: const Icon(
                      Icons.palette,
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
                Text('Theme',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .colorScheme
                            .inverseSurface
                            .withOpacity(0.8))),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Icon(Icons.sunny, size: 20),
                      selected: selectedIndex == 0,
                      onSelected: (bool selected) {
                        _selectChip(0);
                      },
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Icon(Iconsax.moon, size: 20),
                      selected: selectedIndex == 1,
                      onSelected: (bool selected) {
                        _selectChip(1);
                      },
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Icon(Iconsax.autobrightness, size: 20),
                      selected: selectedIndex == 2,
                      onSelected: (bool selected) {
                        _selectChip(2);
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 30),
          SwitchTileStateless(
            icon: Iconsax.paintbucket5,
            title: isAndroid12orAbove ? 'Material You' : 'Default Theme',
            value: value1!,
            onChanged: (value) {
              _toggleSwitch(1);
            },
            description: 'Change the app theme',
            onTap: () {
              Provider.of<ThemeProvider>(context).loadDynamicTheme();
              Provider.of<ThemeProvider>(context).updateTheme();
            },
          ),
          if (isAndroid12orAbove)
            CustomTile(
                icon: Iconsax.paintbucket,
                title: 'Palette',
                onTap: _showSchemeVariantDialog,
                description: 'Change color styles!'),
          SwitchTileStateless(
            icon: Iconsax.moon5,
            title: 'Oled Theme Variant',
            value: value2!,
            onChanged: (value) {
              _toggleSwitch(2);
            },
            description: 'Make it super dark',
            onTap: () {},
          ),
          SwitchTileStateless(
            icon: Iconsax.moon5,
            title: 'Use Anime Banner as Color',
            value: value4!,
            onChanged: (value) {
              _toggleSwitch(4);
            },
            description: 'Warning! only works with consumet',
            onTap: () {},
          ),
          SwitchTileStateless(
            icon: Iconsax.brush_1,
            title: 'Custom Theme',
            value: value3!,
            onChanged: (value) {
              _toggleSwitch(3);
            },
            description: 'Use your own color!',
            onTap: () {},
          ),
          isCustomTheme! ? ColorChips() : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Padding ColorChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Wrap(
        children: colorsName.map<Widget>((color) {
          final index = colorsName.indexOf(color);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: ChoiceChip(
              avatar: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: colors[index]),
              ),
              label: Text(color),
              selected: selectedColorIndex == colorsName.indexOf(color),
              onSelected: (value) {
                _selectColor(index);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  DropdownMenuItem<int> _buildDropdownMenuItem(int value, String label) {
    return DropdownMenuItem<int>(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(label),
        ),
      ),
    );
  }
}
