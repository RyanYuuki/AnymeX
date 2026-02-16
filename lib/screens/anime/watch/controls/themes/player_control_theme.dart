import 'package:anymex/screens/anime/watch/controls/themes/player_control_theme_data.dart';
import 'package:flutter/material.dart';

abstract class PlayerControlTheme {
  String get id;
  String get name;

  Widget buildTopControls(BuildContext context, PlayerTopSectionData data);
  Widget buildCenterControls(
      BuildContext context, PlayerCenterSectionData data);
  Widget buildBottomControls(
      BuildContext context, PlayerBottomSectionData data);
}
