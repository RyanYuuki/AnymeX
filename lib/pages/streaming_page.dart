import 'package:flutter/material.dart';
class StreamingPage extends StatelessWidget {
  final String? id;
  const StreamingPage({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Text('Hello'),
        ),
      ),
    );
  }
}