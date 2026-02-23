import 'package:anymex/screens/manga/widgets/reader/themes/reader_control_themes/default_reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/reader_control_themes/ios_reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';

class ReaderControlThemeRegistry {
  static const String defaultThemeId = 'default';

  static List<ReaderControlTheme> themes = [
    DefaultReaderControlTheme(),
    IOSReaderControlTheme(),
  ];

  static ReaderControlTheme resolve(String id) {
    return themes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => themes.first,
    );
  }
}
