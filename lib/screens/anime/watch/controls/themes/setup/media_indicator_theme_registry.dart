import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/default_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/ios_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/minimal_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/neon_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/retro_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/elegant_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/cyberpunk_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/cinema_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/bubble_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/gaming_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';

class MediaIndicatorThemeRegistry {
  static const String defaultThemeId = 'default';

  static final List<MediaIndicatorTheme> themes = [
    DefaultMediaIndicatorTheme(),
    IosMediaIndicatorTheme(),
    MinimalMediaIndicatorTheme(),
    NeonMediaIndicatorTheme(),
    RetroMediaIndicatorTheme(),
    ElegantMediaIndicatorTheme(),
    CyberpunkMediaIndicatorTheme(),
    CinemaMediaIndicatorTheme(),
    BubbleMediaIndicatorTheme(),
    GamingMediaIndicatorTheme(),
  ];

  static MediaIndicatorTheme resolve(String id) {
    return themes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => themes.first,
    );
  }
}
