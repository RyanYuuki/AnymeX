import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconly/iconly.dart';

class SourcesSettingPage extends StatefulWidget {
  const SourcesSettingPage({super.key});

  @override
  State<SourcesSettingPage> createState() => _SourcesSettingPageState();
}

class _SourcesSettingPageState extends State<SourcesSettingPage> {
  late bool? usingConsumet;

  @override
  void initState() {
    super.initState();
    initiliazeVars();
  }

  void initiliazeVars() {
    usingConsumet =
        Hive.box('app-data').get('using-consumet', defaultValue: false);
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sources',
                      style:
                          TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.source_outlined,
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
            child: Text('Anime',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary)),
          ),
          // SwitchTileStateless(
          //   icon: Iconsax.language_square,
          //   title: 'Romaji Names',
          //   description: 'Switch Anime Names to romaji',
          //   onTap: () {},
          //   value: isRomaji!,
          //   onChanged: (value) {
          //     Hive.box('app-data').put('isRomaji', value);
          //     setState(() {
          //       isRomaji = value;
          //     });
          //   },
          // ),
          // SwitchTileStateless(
          //   icon: Icons.api,
          //   title: 'Consumet API',
          //   description: 'Faster, Better, NO DUBS THO',
          //   onTap: () {},
          //   value: usingConsumet!,
          //   onChanged: (bool value) {
          //     Hive.box('app-data').put('using-consumet', value);
          //     setState(() {
          //       usingConsumet = value;
          //     });
          //   },
          // ),
          // const SizedBox(height: 20),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          //   child: Text('Manga',
          //       style: TextStyle(
          //           fontSize: 12,
          //           color: Theme.of(context).colorScheme.primary)),
          // ),
          // SwitchTile(
          //   icon: Icons.api_rounded,
          //   title: 'MangaReader API',
          //   description: "Try if you're having slow experience",
          //   onTap: () {},
          // ),
        ],
      ),
    );
  }
}
