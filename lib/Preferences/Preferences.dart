import 'HiveDataClasses/MalToken/MalToken.dart';
import 'PrefManager.dart';

class PrefName {
  static const Pref<String> source =
      Pref(Location.General, 'source', 'ANILIST');

  //theme
  static const Pref<bool> isDarkMode =
      Pref(Location.General, 'isDarkMode', false);
  static const Pref<bool> isOled = Pref(Location.General, 'isOled', false);
  static const Pref<bool> useMaterialYou =
      Pref(Location.General, 'useMaterialYou', false);
  static const Pref<String> theme = Pref(Location.General, 'Theme', 'purple');
  static const Pref<int> customColor =
      Pref(Location.General, 'customColor', 4280391411);
  static const Pref<bool> useCustomColor =
      Pref(Location.General, 'useCustomColor', false);
  static const Pref<bool> showYtButton =
      Pref(Location.General, 'showYtButton', true);

  //home page
  static const Pref<Map<String, bool>> anilistHomeLayout =
      Pref(Location.General, 'homeLayoutOrder', {
    'Continue Watching': true,
    'Favourite Anime': false,
    'Planned Anime': false,
    'Continue Reading': true,
    'Favourite Manga': false,
    'Planned Manga': false,
    'Recommended': true,
  });

  static const Pref<Map<String, bool>> malHomeLayout =
      Pref(Location.General, 'malHomeLayoutOrder', {
    'Continue Watching': true,
    'OnHold Anime': false,
    'Planned Anime': true,
    'Dropped Anime': false,
    'Continue Reading': true,
    'OnHold Manga': false,
    'Planned Manga': true,
    'Dropped Manga': false,
  });
  static const Pref<List<int>> anilistRemoveList =
      Pref(Location.General, 'anilistRemoveList', []);
  static const Pref<List<int>> malRemoveList =
      Pref(Location.General, 'malRemoveList', []);
  static const Pref<bool> anilistHidePrivate =
      Pref(Location.General, 'anilistHidePrivate', false);

  //anime page
  static const Pref<Map<String, bool>> anilistAnimeLayout =
      Pref(Location.General, 'animeLayoutOrder', {
    'Recent Updates': true,
    'Trending Movies': true,
    'Top Rated Series': true,
    'Most Favourite Series': true,
  });

  static const Pref<Map<String, bool>> malAnimeLayout =
      Pref(Location.General, 'malAnimeLayoutOrder', {
    'Top Airing': true,
    'Trending Movies': true,
    'Top Rated Series': true,
    'Most Favourite Series': true,
  });
  static const Pref<bool> adultOnly =
      Pref(Location.General, 'adultOnly', false);
  static const Pref<bool> includeAnimeList =
      Pref(Location.General, 'includeAnimeList', false);
  static const Pref<bool> recentlyListOnly =
      Pref(Location.General, 'recentlyListOnly', false);
  static const Pref<bool> NSFWExtensions =
      Pref(Location.General, 'NSFWExtensions', true);
  static const Pref<int> AnimeDefaultView =
      Pref(Location.General, 'AnimeDefaultView', 0);

  //manga page
  static const Pref<Map<String, bool>> anilistMangaLayout =
      Pref(Location.General, 'mangaLayoutOrder', {
    'Trending Manhwa': true,
    'Trending Novels': true,
    'Top Rated Manga': true,
    'Most Favourite Manga': true,
  });

  static const Pref<Map<String, bool>> malMangaLayout =
      Pref(Location.General, 'malMangaLayoutOrder', {
    'Trending Manhwa': true,
    'Trending Novels': true,
    'Top Rated Manga': true,
    'Most Favourite Manga': true,
  });
  static const Pref<bool> includeMangaList =
      Pref(Location.General, 'includeMangaList', false);

  //
  static const Pref<int> unReadCommentNotifications =
      Pref(Location.General, 'unReadCommentNotifications', 0);
  static const Pref<bool> incognito =
      Pref(Location.General, 'incognito', false);
  static const Pref<bool> offlineMode =
      Pref(Location.General, 'offline', false);

  //Protection
  static const Pref<String> anilistToken =
      Pref(Location.Protected, 'AnilistToken', '');
  static const Pref<ResponseToken?> malToken =
      Pref(Location.Protected, 'MalToken', null);
  static const Pref<String> discordToken =
      Pref(Location.Protected, 'DiscordToken', '');
  static const Pref<String> discordUserName =
      Pref(Location.Protected, 'discordUserName', '');
  static const Pref<String> discordAvatar =
      Pref(Location.Protected, 'discordAvatar', '');

  // irrelevant
  static const Pref<List<String>> GenresList =
      Pref(Location.Irrelevant, 'GenresList', []);
  static const Pref<List<String>> TagsListIsAdult =
      Pref(Location.Irrelevant, 'TagsListIsAdult', []);
  static const Pref<List<String>> TagsListNonAdult =
      Pref(Location.Irrelevant, 'TagsListNonAdult', []);
}
