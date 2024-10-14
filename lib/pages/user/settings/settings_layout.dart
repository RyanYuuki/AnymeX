import 'package:aurora/components/common/switch_tile_stateless.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
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
                      'Layout',
                      style:
                          TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.stairs_outlined,
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
