import 'package:anymex/screens/manga/widgets/reader/themes/reader_control_themes/default_reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/reader_control_themes/ios_reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/reader_control_themes/modern_reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/reader_control_themes/minimal_reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/reader_control_themes/retro_reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/reader_control_themes/cyberpunk_reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/reader_control_themes/glass_reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/reader_control_themes/cinema_reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/reader_control_themes/gaming_reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/reader_control_themes/anime_reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';

class ReaderControlThemeRegistry {
  static const String defaultThemeId = 'default';

  static List<ReaderControlTheme> themes = [
    DefaultReaderControlTheme(),
    IOSReaderControlTheme(),
    ModernReaderControlTheme(),
    MinimalReaderControlTheme(),
    RetroReaderControlTheme(),
    CyberpunkReaderControlTheme(),
    GlassReaderControlTheme(),
    CinemaReaderControlTheme(),
    GamingReaderControlTheme(),
    AnimeReaderControlTheme(),
  ];

  static ReaderControlTheme resolve(String id) {
    return themes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => themes.first,
    );
  }
}
