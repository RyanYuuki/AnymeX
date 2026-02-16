import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:flutter/material.dart';

abstract class PlayerControlTheme {
  String get id;
  String get name;

  Widget buildTopControls(BuildContext context, PlayerController controller);
  Widget buildCenterControls(BuildContext context, PlayerController controller);
  Widget buildBottomControls(BuildContext context, PlayerController controller);
}
