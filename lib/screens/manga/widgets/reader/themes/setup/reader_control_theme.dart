import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:flutter/material.dart';

abstract class ReaderControlTheme {
  String get id;
  String get name;

  Widget buildTopControls(BuildContext context, ReaderController controller);
  Widget buildBottomControls(BuildContext context, ReaderController controller);
  Widget buildCenterControls(BuildContext context, ReaderController controller);
}
