import 'package:anymex/screens/anime/watch/controls/bottom_controls.dart';
import 'package:anymex/screens/anime/watch/controls/center_controls.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/top_controls.dart';
import 'package:flutter/material.dart';

class DefaultPlayerControlTheme extends PlayerControlTheme {
  DefaultPlayerControlTheme();

  @override
  String get id => 'default';

  @override
  String get name => 'Default';

  @override
  Widget buildBottomControls(BuildContext context, PlayerController controller) {
    return const BottomControls();
  }

  @override
  Widget buildCenterControls(BuildContext context, PlayerController controller) {
    return const CenterControls();
  }

  @override
  Widget buildTopControls(BuildContext context, PlayerController controller) {
    return const TopControls();
  }
}
