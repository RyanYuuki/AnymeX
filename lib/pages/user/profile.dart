import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'This Page is under construction',
            style: TextStyle(fontSize: 30),
            textAlign: TextAlign.center,
          ),
          Text(
            '🧑‍🏭🔨🧑‍🏭',
            style: TextStyle(fontSize: 30),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
