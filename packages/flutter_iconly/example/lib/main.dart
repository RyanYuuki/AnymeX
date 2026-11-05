import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iconly Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              children: [
                /// Icon Style Bold
                Icon(IconlyBold.user2),

                /// Icon Style Light
                Icon(IconlyLight.activity),

                /// Icon Style Broken
                Icon(IconlyBroken.user2),

                Icon(Icons.ac_unit)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
