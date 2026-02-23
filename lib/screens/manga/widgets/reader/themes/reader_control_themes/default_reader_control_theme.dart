import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/auto_scroll_menu.dart';
import 'package:anymex/screens/manga/widgets/reader/bottom_controls.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/top_controls.dart';
import 'package:flutter/material.dart';

class DefaultReaderControlTheme extends ReaderControlTheme {
  @override
  String get id => 'default';

  @override
  String get name => 'Default';

  @override
  Widget buildTopControls(BuildContext context, ReaderController controller) {
    return ReaderTopControls(controller: controller);
  }

  @override
  Widget buildBottomControls(
      BuildContext context, ReaderController controller) {
    return ReaderBottomControls(controller: controller);
  }

  @override
  Widget buildCenterControls(
      BuildContext context, ReaderController controller) {
    return const ReaderAutoScrollMenu();
  }
}
