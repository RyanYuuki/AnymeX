import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/default_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/ios_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/minimal_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';

class MediaIndicatorThemeRegistry {
  static const String defaultThemeId = 'default';

  static final List<MediaIndicatorTheme> themes = [
    DefaultMediaIndicatorTheme(),
    IosMediaIndicatorTheme(),
    MinimalMediaIndicatorTheme()
  ];

  static MediaIndicatorTheme resolve(String id) {
    return themes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => themes.first,
    );
  }
}
