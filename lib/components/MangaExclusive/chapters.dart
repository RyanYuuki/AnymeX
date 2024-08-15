// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';

class ChapterList extends StatelessWidget {
  dynamic chaptersData;
  ChapterList({super.key, this.chaptersData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        children: [
          const Text('Chapters',
              style: TextStyle(fontSize: 24, fontFamily: "Poppins-Bold"), textAlign: TextAlign.left),
          const SizedBox(height: 10),
          ...chaptersData.map<Widget>((manga) {
            return Container(
              margin: const EdgeInsets.only(top: 20),
              width: MediaQuery.of(context).size.width,
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).colorScheme.tertiary,
              ),
              child: Center(child: Text(manga['name'])),
            );
          }).toList()
        ],
      ),
    );
  }
}
