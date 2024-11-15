import 'package:aurora/pages/user/settings/modals/tile_with_slider.dart';
import 'package:aurora/pages/user/settings/settings_layout.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class ResizeTabbar extends StatefulWidget {
  const ResizeTabbar({super.key});

  @override
  State<ResizeTabbar> createState() => _ResizeTabbarState();
}

class _ResizeTabbarState extends State<ResizeTabbar> {
  double tabBarSizeVertical =
      Hive.box('app-data').get('tabBarSizeVertical', defaultValue: 20.0);
  double tabBarSizeHorizontal =
      Hive.box('app-data').get('tabBarSizeHorizontal', defaultValue: 50.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 50),
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
                      'Resize',
                      style:
                          TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Iconsax.arrow,
                          size: 40,
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Text('Adjust',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary)),
          ),
          TileWithSlider(
            sliderValue: tabBarSizeVertical,
            onChanged: (newValue) {
              setState(() {
                tabBarSizeVertical = newValue;
              });
              Hive.box('app-data').put('tabBarSizeVertical', newValue);
            },
            title: 'Vertical Size',
            description: 'Changes the Vertical Size of TabBar',
            icon: Icons.rounded_corner_rounded,
            min: 0.0,
            max: 50,
            divisions: 10,
          ),
          TileWithSlider(
            sliderValue: tabBarSizeHorizontal,
            onChanged: (newValue) {
              setState(() {
                tabBarSizeHorizontal = newValue;
              });
              Hive.box('app-data').put('tabBarSizeHorizontal', newValue);
            },
            title: 'Horizontal Size',
            description: 'Changes the Horizontal Size of TabBar',
            icon: Icons.rounded_corner,
            min: 0.0,
            max: 50.0,
            divisions: 10,
          ),
        ],
      ),
    );
  }
}
