import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// A utility class for accessing localized strings in a more convenient way.
/// Similar to Dartotsu's getString pattern.
class GetString {
  static BuildContext? _context;

  /// Initialize the GetString with the current context.
  /// This should be called in the build method or where context is available.
  static void init(BuildContext context) {
    _context = context;
  }

  /// Get the current AppLocalizations instance
  static AppLocalizations? get _l10n {
    if (_context == null) return null;
    return AppLocalizations.of(_context!);
  }

  // Navigation labels
  static String get home => _l10n?.home ?? 'Home';
  static String get anime => _l10n?.anime ?? 'Anime';
  static String get manga => _l10n?.manga ?? 'Manga';
  static String get library => _l10n?.library ?? 'Library';
  static String get extensions => _l10n?.extensions ?? 'Extensions';
  static String get profile => _l10n?.profile ?? 'Profile';

  // Settings page
  static String get settings => _l10n?.settings ?? 'Settings';
  static String get accounts => _l10n?.accounts ?? 'Accounts';
  static String get accountsDescription => _l10n?.accountsDescription ?? 'Manage your MyAnimeList, Anilist, Simkl Accounts!';
  static String get common => _l10n?.common ?? 'Common';
  static String get commonDescription => _l10n?.commonDescription ?? 'Tweak Settings';
  static String get ui => _l10n?.ui ?? 'UI';
  static String get uiDescription => _l10n?.uiDescription ?? 'Play around with App UI';
  static String get player => _l10n?.player ?? 'Player';
  static String get playerDescription => _l10n?.playerDescription ?? 'Play around with Player';
  static String get theme => _l10n?.theme ?? 'Theme';
  static String get themeDescription => _l10n?.themeDescription ?? 'Play around with App theme';
  static String get extensionsDescription => _l10n?.extensionsDescription ?? 'Extensions that tends to your needs';
  static String get experimental => _l10n?.experimental ?? 'Experimental';
  static String get experimentalDescription => _l10n?.experimentalDescription ?? 'Experimental Settings that are still being tested.';
  static String get shareLogs => _l10n?.shareLogs ?? 'Share Logs';
  static String get shareLogsDescription => _l10n?.shareLogsDescription ?? 'Share Logs of the App';
  static String get about => _l10n?.about ?? 'About';
  static String get aboutDescription => _l10n?.aboutDescription ?? 'About the App';

  // Local source
  static String get search => _l10n?.search ?? 'Search';
  static String get searchStuffToDownload => _l10n?.searchStuffToDownload ?? 'Search stuff you wanna download';
  static String get anymexDownloads => _l10n?.anymexDownloads ?? 'AnymeX Downloads';
  static String get download => _l10n?.download ?? 'Download';
  static String get local => _l10n?.local ?? 'Local';

  // Source selection
  static String get selectSource => _l10n?.selectSource ?? 'SELECT SOURCE';
  static String get unknownSource => _l10n?.unknownSource ?? 'Unknown Source';
  static String get unknown => _l10n?.unknown ?? 'Unknown';

  // GitHub repositories
  static String addGithubRepo(String type) => _l10n?.addGithubRepo(type) ?? 'Add github repo for $type';
  static String get animeGithubRepo => _l10n?.animeGithubRepo ?? 'Anime Github Repo';
  static String get mangaGithubRepo => _l10n?.mangaGithubRepo ?? 'Manga Github Repo';
  static String get novelGithubRepo => _l10n?.novelGithubRepo ?? 'Novel Github Repo';

  // Local library
  static String get localLibrary => _l10n?.localLibrary ?? 'Local Library';
  static String get noSourcesInstalled => _l10n?.noSourcesInstalled ?? 'No Sources Installed';
  static String noSourcesAvailable(String type) => _l10n?.noSourcesAvailable(type) ?? 'No $type Sources Available';
  static String installExtensionsToStart(String type) => _l10n?.installExtensionsToStart(type) ?? 'Install $type extensions to get started';

  // App name
  static String get appName => _l10n?.appName ?? 'AnymeX';
}