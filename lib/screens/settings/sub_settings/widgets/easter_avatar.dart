import 'dart:async';
import 'dart:convert';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TripleTapWidget extends StatefulWidget {
  const TripleTapWidget({super.key});

  @override
  State<TripleTapWidget> createState() => _TripleTapWidgetState();
}

class _TripleTapWidgetState extends State<TripleTapWidget> {
  int _tapCount = 0;
  final int _requiredTaps = 3;
  final Duration _timeInterval = const Duration(seconds: 2);
  Timer? _timer;

  void _handleTap() {
    setState(() {
      _tapCount++;
    });

    if (_tapCount == 1) {
      _timer = Timer(_timeInterval, () {
        setState(() {
          _tapCount = 0;
        });
      });
    }

    if (_tapCount == _requiredTaps) {
      _triggerAction();
    }
  }

  void _triggerAction() {
    _timer?.cancel();

    setState(() {
      _tapCount = 0;
    });

    const funAlink =
        'aHR0cHM6Ly9taXJhaWVub2tpLmdpdGh1Yi5pby9hbnltZXgtZXh0ZW5zaW9ucy9hbmltZV9pbmRleC5qc29u';
    const funMlink =
        'aHR0cHM6Ly9taXJhaWVub2tpLmdpdGh1Yi5pby9hbnltZXgtZXh0ZW5zaW9ucy9pbmRleC5qc29u';

    final aR = utf8.decode(base64Decode(funAlink));
    final mR = utf8.decode(base64Decode(funMlink));

    final settings = Get.find<SourceController>();
    settings.activeAnimeRepo = aR;
    settings.activeMangaRepo = mR;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: _handleTap,
      child: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainer,
        child: Image.asset(
          'assets/images/logo_transparent.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
