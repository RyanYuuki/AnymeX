import 'package:anymex/screens/anime/watch/controls/themes/default_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/ios26_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_theme.dart';

class PlayerControlThemeRegistry {
  static const String defaultThemeId = 'default';

  static List<PlayerControlTheme> themes = [
    DefaultPlayerControlTheme(),
    Ios26PlayerControlTheme(),
  ];

  static PlayerControlTheme resolve(String id) {
    return themes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => themes.first,
    );
  }
}
