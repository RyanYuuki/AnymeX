import 'package:aurora/components/common/custom_tile.dart';
import 'package:aurora/components/common/custom_tile_ui.dart';
import 'package:aurora/components/common/switch_tile_stateless.dart';
import 'package:aurora/pages/user/settings/layout_subs/resize_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class LayoutPage extends StatefulWidget {
  const LayoutPage({super.key});

  @override
  State<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> {
  bool compactCard =
      Hive.box('app-data').get('usingCompactCards', defaultValue: false);
  bool saikouCards =
      Hive.box('app-data').get('usingSaikouCards', defaultValue: true);
  bool usingSaikouLayout =
      Hive.box('app-data').get('usingSaikouLayout', defaultValue: false);
  double cardRoundness =
      Hive.box('app-data').get('cardRoundness', defaultValue: 18.0);
  double tabBarRoundness =
      Hive.box('app-data').get('tabBarRoundness', defaultValue: 30.0);
  // double tabBarSize = Hive.box('app-data').get('tabBarSize', defaultValue: );
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
                      'UI',
                      style:
                          TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          HugeIcons.strokeRoundedPaintBrush02,
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
            child: Text('Common',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary)),
          ),
          SwitchTileStateless(
            icon: Iconsax.card5,
            title: 'Compact Card',
            description: 'Change carousel card${"'s"} looks',
            onTap: () {},
            value: compactCard,
            onChanged: (value) {
              setState(() {
                compactCard = !compactCard;
                Hive.box('app-data').put('usingCompactCards', compactCard);
              });
            },
          ),
          SwitchTileStateless(
            icon: Iconsax.card_add5,
            title: 'Saikou Like Cards',
            description: 'You Like small cards like saikou? Turn this on!',
            onTap: () {},
            value: saikouCards,
            onChanged: (value) {
              setState(() {
                saikouCards = !saikouCards;
                Hive.box('app-data').put('usingSaikouCards', saikouCards);
              });
            },
          ),
          CustomTile(
            icon: Iconsax.arrow,
            title: 'Resize TabBar',
            description: 'Change the TabBar Size.',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ResizeTabbar()));
            },
          ),
          TileWithSlider(
            sliderValue: cardRoundness,
            onChanged: (newValue) {
              setState(() {
                cardRoundness = newValue;
              });
              Hive.box('app-data').put('cardRoundness', newValue);
            },
            title: 'Card Roundness',
            description: 'Changes the card roundness',
            icon: Icons.rounded_corner_rounded,
            max: 50.0,
            min: 0.0,
          ),
          TileWithSlider(
            sliderValue: tabBarRoundness,
            onChanged: (newValue) {
              setState(() {
                tabBarRoundness = newValue;
              });
              Hive.box('app-data').put('tabBarRoundness', newValue);
            },
            title: 'TabBar Roundness',
            description: 'Changes the Tab ${"Bar's"} Roundness',
            icon: Icons.rounded_corner,
            min: 0.0,
            max: 50.0,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Text('Details Page',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary)),
          ),
          SwitchTileStateless(
            icon: Icons.color_lens,
            title: 'Saikou Style',
            description: "Try this if you like Saikou's Detail Page",
            onTap: () {},
            value: usingSaikouLayout,
            onChanged: (value) {
              setState(() {
                usingSaikouLayout = !usingSaikouLayout;
                Hive.box('app-data')
                    .put('usingSaikouLayout', usingSaikouLayout);
              });
            },
          )
        ],
      ),
    );
  }
}

class TileWithSlider extends StatefulWidget {
  const TileWithSlider({
    super.key,
    required this.sliderValue,
    required this.onChanged,
    required this.title,
    required this.description,
    required this.icon,
    required this.min,
    required this.max,
  });
  final String title;
  final String description;
  final double sliderValue;
  final ValueChanged<double> onChanged;
  final IconData icon;
  final double min;
  final double max;

  @override
  State<TileWithSlider> createState() => _TileWithSliderState();
}

class _TileWithSliderState extends State<TileWithSlider> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTileUi(
            icon: widget.icon,
            title: widget.title,
            description: widget.description),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Text(widget.sliderValue.toStringAsFixed(1),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary)),
              Expanded(
                child: Slider(
                  value: widget.sliderValue,
                  onChanged: (newValue) => widget.onChanged(newValue),
                  min: widget.min,
                  max: widget.max,
                  label: widget.sliderValue.toStringAsFixed(1),
                  divisions: (widget.max * 10).toInt(),
                ),
              ),
              Text(widget.max.toString(),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary)),
            ],
          ),
        ),
      ],
    );
  }
}
