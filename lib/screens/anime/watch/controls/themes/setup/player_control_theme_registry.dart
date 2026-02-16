import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/default_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/ios26_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/netflix_desktop_player_theme.dart.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/netflix_mobile_player_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme.dart';

class PlayerControlThemeRegistry {
  static const String defaultThemeId = 'default';

  static List<PlayerControlTheme> themes = [
    DefaultPlayerControlTheme(),
    Ios26PlayerControlTheme(),
    NetflixDesktopPlayerControlTheme(),
    NetflixMobilePlayerControlTheme()
  ];

  static PlayerControlTheme resolve(String id) {
    return themes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => themes.first,
    );
  }
}
