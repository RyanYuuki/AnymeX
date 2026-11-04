/// Translation keys used throughout the app.
///
/// Always use these constants instead of raw strings for type-safety
/// and refactoring support. Example: `LocaleKeys.navHome.tr`
abstract final class LocaleKeys {
  // ─── Navigation ──────────────────────────────────────────────────────
  static const navHome = 'nav_home';
  static const navDiscover = 'nav_discover';
  static const navSearch = 'nav_search';
  static const navLibrary = 'nav_library';
  static const navHistory = 'nav_history';
  static const navStats = 'nav_stats';
  static const navAnime = 'nav_anime';
  static const navManga = 'nav_manga';
  static const navNovel = 'nav_novel';
  static const navExtensions = 'nav_extensions';
  static const navProfile = 'nav_profile';
  static const navMovies = 'nav_movies';
  static const navSeries = 'nav_series';

  // ─── Common Actions ──────────────────────────────────────────────────
  static const actionOk = 'action_ok';
  static const actionCancel = 'action_cancel';
  static const actionSave = 'action_save';
  static const actionDelete = 'action_delete';
  static const actionEdit = 'action_edit';
  static const actionClose = 'action_close';
  static const actionRetry = 'action_retry';
  static const actionConfirm = 'action_confirm';
  static const actionDone = 'action_done';
  static const actionBack = 'action_back';
  static const actionNext = 'action_next';
  static const actionSkip = 'action_skip';
  static const actionApply = 'action_apply';
  static const actionReset = 'action_reset';
  static const actionRefresh = 'action_refresh';
  static const actionShare = 'action_share';
  static const actionCopy = 'action_copy';
  static const actionCopied = 'action_copied';
  static const actionSearch = 'action_search';
  static const actionClear = 'action_clear';
  static const actionSelectAll = 'action_select_all';
  static const actionDeselectAll = 'action_deselect_all';
  static const actionUpdate = 'action_update';

  // ─── Common Labels ───────────────────────────────────────────────────
  static const labelSettings = 'label_settings';
  static const labelAbout = 'label_about';
  static const labelGeneral = 'label_general';
  static const labelAppearance = 'label_appearance';
  static const labelTheme = 'label_theme';
  static const labelLanguage = 'label_language';
  static const labelVersion = 'label_version';
  static const labelLoading = 'label_loading';
  static const labelNoData = 'label_no_data';
  static const labelError = 'label_error';
  static const labelSuccess = 'label_success';
  static const labelWarning = 'label_warning';
  static const labelAll = 'label_all';
  static const labelNone = 'label_none';
  static const labelEnabled = 'label_enabled';
  static const labelDisabled = 'label_disabled';
  static const labelOn = 'label_on';
  static const labelOff = 'label_off';
  static const labelYes = 'label_yes';
  static const labelNo = 'label_no';
  static const labelName = 'label_name';
  static const labelDescription = 'label_description';
  static const labelDownloads = 'label_downloads';

  // ─── Settings Categories ─────────────────────────────────────────────
  static const settingsAccounts = 'settings_accounts';
  static const settingsAccountsDesc = 'settings_accounts_desc';
  static const settingsAccountsSync = 'settings_accounts_sync';
  static const settingsDiscordRpc = 'settings_discord_rpc';
  static const settingsDiscordRpcDesc = 'settings_discord_rpc_desc';
  static const settingsTheme = 'settings_theme';
  static const settingsThemeDesc = 'settings_theme_desc';
  static const settingsUi = 'settings_ui';
  static const settingsUiDesc = 'settings_ui_desc';
  static const settingsPlayer = 'settings_player';
  static const settingsPlayerDesc = 'settings_player_desc';
  static const settingsReader = 'settings_reader';
  static const settingsReaderDesc = 'settings_reader_desc';
  static const settingsExtensions = 'settings_extensions';
  static const settingsExtensionsDesc = 'settings_extensions_desc';
  static const settingsCommon = 'settings_common';
  static const settingsCommonDesc = 'settings_common_desc';
  static const settingsNetwork = 'settings_network';
  static const settingsNetworkDesc = 'settings_network_desc';
  static const settingsPerformance = 'settings_performance';
  static const settingsPerformanceDesc = 'settings_performance_desc';
  static const settingsBackup = 'settings_backup';
  static const settingsBackupDesc = 'settings_backup_desc';
  static const settingsDownloads = 'settings_downloads';
  static const settingsDownloadsDesc = 'settings_downloads_desc';
  static const settingsLogs = 'settings_logs';
  static const settingsLogsDesc = 'settings_logs_desc';
  static const settingsStorage = 'settings_storage';
  static const settingsStorageDesc = 'settings_storage_desc';
  static const settingsDonation = 'settings_donation';
  static const settingsDonationDesc = 'settings_donation_desc';
  static const settingsAbout = 'settings_about';
  static const settingsAboutDesc = 'settings_about_desc';
  static const settingsComments = 'settings_comments';
  static const settingsCommentsDesc = 'settings_comments_desc';
  static const settingsAddons = 'settings_addons';
  static const settingsAddonsDesc = 'settings_addons_desc';
  static const settingsSearchHint = 'settings_search_hint';

  // ─── Media Types ─────────────────────────────────────────────────────
  static const mediaAnime = 'media_anime';
  static const mediaManga = 'media_manga';
  static const mediaNovel = 'media_novel';
  static const mediaMovie = 'media_movie';
  static const mediaSeries = 'media_series';

  // ─── Media Details ───────────────────────────────────────────────────
  static const detailsSynopsis = 'details_synopsis';
  static const detailsEpisodes = 'details_episodes';
  static const detailsChapters = 'details_chapters';
  static const detailsCharacters = 'details_characters';
  static const detailsRelated = 'details_related';
  static const detailsRecommendations = 'details_recommendations';
  static const detailsScore = 'details_score';
  static const detailsStatus = 'details_status';
  static const detailsType = 'details_type';
  static const detailsGenres = 'details_genres';
  static const detailsStudios = 'details_studios';
  static const detailsAiring = 'details_airing';
  static const detailsCompleted = 'details_completed';
  static const detailsOngoing = 'details_ongoing';

  // ─── Library ─────────────────────────────────────────────────────────
  static const libraryWatching = 'library_watching';
  static const libraryReading = 'library_reading';
  static const libraryCompleted = 'library_completed';
  static const libraryOnHold = 'library_on_hold';
  static const libraryDropped = 'library_dropped';
  static const libraryPlanToWatch = 'library_plan_to_watch';
  static const libraryPlanToRead = 'library_plan_to_read';
  static const libraryEmpty = 'library_empty';
  static const libraryNoItems = 'library_no_items';

  // ─── Player ──────────────────────────────────────────────────────────
  static const playerPlay = 'player_play';
  static const playerPause = 'player_pause';
  static const playerNext = 'player_next';
  static const playerPrevious = 'player_previous';
  static const playerSpeed = 'player_speed';
  static const playerQuality = 'player_quality';
  static const playerSubtitles = 'player_subtitles';
  static const playerFullscreen = 'player_fullscreen';
  static const playerEpisode = 'player_episode';
  static const playerChapter = 'player_chapter';

  // ─── Search ──────────────────────────────────────────────────────────
  static const searchHint = 'search_hint';
  static const searchNoResults = 'search_no_results';
  static const searchTrending = 'search_trending';
  static const searchPopular = 'search_popular';
  static const searchRecent = 'search_recent';

  // ─── Errors ──────────────────────────────────────────────────────────
  static const errorGeneric = 'error_generic';
  static const errorNetwork = 'error_network';
  static const errorNotFound = 'error_not_found';
  static const errorTimeout = 'error_timeout';
  static const errorServerError = 'error_server_error';
  static const errorNoInternet = 'error_no_internet';
  static const errorUnknown = 'error_unknown';

  // ─── Home ────────────────────────────────────────────────────────────
  static const homeContinueWatching = 'home_continue_watching';
  static const homeContinueReading = 'home_continue_reading';
  static const homeRecentlyUpdated = 'home_recently_updated';
  static const homeTrending = 'home_trending';
  static const homePopular = 'home_popular';
  static const homeTopRated = 'home_top_rated';
  static const homeSeeAll = 'home_see_all';

  // ─── Stats ───────────────────────────────────────────────────────────
  static const statsOverview = 'stats_overview';
  static const statsTotalWatched = 'stats_total_watched';
  static const statsTotalRead = 'stats_total_read';
  static const statsMeanScore = 'stats_mean_score';
  static const statsDaysWatched = 'stats_days_watched';
  static const statsChaptersRead = 'stats_chapters_read';

  // ─── Extensions ──────────────────────────────────────────────────────
  static const extensionsInstalled = 'extensions_installed';
  static const extensionsAvailable = 'extensions_available';
  static const extensionsUpdatesAvailable = 'extensions_updates_available';
  static const extensionsInstall = 'extensions_install';
  static const extensionsUninstall = 'extensions_uninstall';

  // ─── Downloads ───────────────────────────────────────────────────────
  static const downloadsActive = 'downloads_active';
  static const downloadsCompleted = 'downloads_completed';
  static const downloadsPaused = 'downloads_paused';
  static const downloadsFailed = 'downloads_failed';

  // ─── Onboarding ──────────────────────────────────────────────────────
  static const onboardingWelcome = 'onboarding_welcome';
  static const onboardingGetStarted = 'onboarding_get_started';

  // ─── Miscellaneous ───────────────────────────────────────────────────
  static const incognitoMode = 'incognito_mode';
  static const incognitoEnabled = 'incognito_enabled';
  static const incognitoDisabled = 'incognito_disabled';

  // ─── Parameterized ───────────────────────────────────────────────────
  static const episodeCount = 'episode_count';
  static const chapterCount = 'chapter_count';
  static const itemCount = 'item_count';
}
