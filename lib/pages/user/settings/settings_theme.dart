import 'package:aurora/components/common/switch_tile_stateless.dart';
import 'package:aurora/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  final box = Hive.box('login-data');
  late final palettedMode = box.get('PaletteMode', defaultValue: 'Material');
  late bool isLightMode = box.get('Theme', defaultValue: 'dark') == 'light';
  bool? value1;
  bool value2 = false;
  bool? value3;
  int? selectedIndex;
  int? selectedColorIndex;
  bool? isCustomTheme;

  List<MaterialColor> colors = [
    Colors.indigo,
    Colors.red,
    Colors.pink,
    Colors.yellow,
    Colors.green,
    Colors.purple,
    Colors.deepPurple,
  ];

  List<String> colorsName = [
    'Indigo',
    'Red',
    'Pink',
    'Yellow',
    'Green',
    'Purple',
    'DeepPurple',
  ];

  void _selectChip(int index) {
    setState(() {
      selectedIndex = index;
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      if (index == 0) {
        themeProvider.setLightMode();
      } else if (index == 1) {
        themeProvider.setDarkMode();
      } else if (index == 2) {}
      box.put('Theme', index == 0 ? 'light' : 'dark');
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
    setState(() {
      if (index == 1) {
        value1 = true;
        value3 = false;
        if (value1!) {
          isCustomTheme = false;
          final themeProvider =
              Provider.of<ThemeProvider>(context, listen: false);
          themeProvider.loadDynamicTheme();
        }
        box.put('PaletteMode', 'Material');
      } else if (index == 2) {
        value2 = !value2;
      } else if (index == 3) {
        value1 = false;
        value3 = true;
        box.put('PaletteMode', 'Custom');
        if (value3!) {
          isCustomTheme = true;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    initStates();
  }

  void initStates() {
    // Themes Switches
    value1 = box.get('PaletteMode') == 'Material';
    value3 = box.get('PaletteMode') == 'Custom';
    if (value1!) {
      isCustomTheme = false;
    } else {
      isCustomTheme = true;
    }

    // Light and Dark Mode Chips
    if (isLightMode) {
      selectedIndex = 0;
    } else {
      selectedIndex = 1;
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              IconlyBroken.arrow_left_2,
              size: 30,
            ),
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
                    onPressed: () {},
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
                      label: const Icon(Iconsax.sun, size: 20),
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
            title: 'Material You',
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
          SwitchTileStateless(
            icon: Iconsax.moon5,
            title: 'Oled Theme Variant',
            value: value2,
            onChanged: (value) {
              _toggleSwitch(2);
            },
            description: 'Make it super dark',
            onTap: () {},
          ),
          SwitchTileStateless(
            icon: Iconsax.info_circle5,
            title: 'Custom Theme',
            value: value3!,
            onChanged: (value) {
              _toggleSwitch(3);
            },
            description: 'Use your own color!',
            onTap: () {},
          ),
          isCustomTheme! ? ColorChips() : SizedBox.shrink(),
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
