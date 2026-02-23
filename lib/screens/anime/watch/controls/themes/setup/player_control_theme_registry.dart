import 'dart:convert';

import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/default_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/ios26_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/netflix_desktop_player_theme.dart.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/netflix_mobile_player_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/json_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme.dart';
import 'package:http/http.dart' as http;

class PlayerThemeImportResult {
  const PlayerThemeImportResult({
    this.addedThemeIds = const [],
    this.updatedThemeIds = const [],
    this.warnings = const [],
    this.errors = const [],
  });

  final List<String> addedThemeIds;
  final List<String> updatedThemeIds;
  final List<String> warnings;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get isSuccess => !hasErrors && (addedThemeIds.isNotEmpty || updatedThemeIds.isNotEmpty);
  int get importedCount => addedThemeIds.length + updatedThemeIds.length;

  factory PlayerThemeImportResult.failure(
    String message, {
    List<String> warnings = const [],
  }) {
    return PlayerThemeImportResult(errors: [message], warnings: warnings);
  }
}

class PlayerControlThemeRegistry {
  static const String defaultThemeId = 'default';
  static const Duration _importTimeout = Duration(seconds: 15);

  static final List<PlayerControlTheme> _builtInThemes = [
    DefaultPlayerControlTheme(),
    Ios26PlayerControlTheme(),
    NetflixDesktopPlayerControlTheme(),
    NetflixMobilePlayerControlTheme(),
  ];

  static Set<String> get builtInThemeIds =>
      _builtInThemes.map((theme) => theme.id).toSet();

  static List<JsonPlayerControlTheme> get jsonThemes => _loadJsonThemes();

  static Set<String> get jsonThemeIds => jsonThemes.map((theme) => theme.id).toSet();

  static bool isJsonThemeId(String id) => jsonThemeIds.contains(id);

  static List<PlayerControlTheme> get themes {
    final byId = <String, PlayerControlTheme>{
      for (final theme in _builtInThemes) theme.id: theme,
    };

    for (final dynamicTheme in _loadJsonThemes()) {
      byId[dynamicTheme.id] = dynamicTheme;
    }

    return byId.values.toList(growable: false);
  }

  static PlayerControlTheme resolve(String id) {
    final allThemes = themes;
    return allThemes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => allThemes.first,
    );
  }

  static String get dynamicThemeCollectionJson {
    final current = PlayerUiKeys.playerControlThemesJson.get<String>('');
    if (current.trim().isNotEmpty) return current;

    PlayerUiKeys.playerControlThemesJson
        .set(JsonPlayerControlTheme.defaultCollectionJson);
    return JsonPlayerControlTheme.defaultCollectionJson;
  }

  static void saveDynamicThemeCollectionJson(String rawJson) {
    PlayerUiKeys.playerControlThemesJson.set(rawJson);
  }

  static bool validateDynamicThemeCollectionJson(String rawJson) {
    return JsonPlayerControlTheme.isValidCollectionJson(rawJson);
  }

  static PlayerThemeImportResult importFromRawJson(String rawJson) {
    final parsed = JsonPlayerControlTheme.parseCollectionDetailed(rawJson);
    if (parsed.errors.isNotEmpty) {
      return PlayerThemeImportResult(
        warnings: parsed.warnings,
        errors: parsed.errors,
      );
    }

    final existingById = <String, Map<String, dynamic>>{
      for (final rawTheme in _decodeStoredRawThemes())
        if (_themeIdOf(rawTheme) != null) _themeIdOf(rawTheme)!: rawTheme,
    };

    final incomingById = <String, Map<String, dynamic>>{
      for (final rawTheme in parsed.rawThemes)
        if (_themeIdOf(rawTheme) != null) _themeIdOf(rawTheme)!: rawTheme,
    };

    final added = <String>[];
    final updated = <String>[];

    for (final entry in incomingById.entries) {
      if (existingById.containsKey(entry.key)) {
        updated.add(entry.key);
      } else {
        added.add(entry.key);
      }
      existingById[entry.key] = entry.value;
    }

    _saveRawThemes(existingById.values.toList(growable: false));

    return PlayerThemeImportResult(
      addedThemeIds: added,
      updatedThemeIds: updated,
      warnings: parsed.warnings,
    );
  }

  static Future<PlayerThemeImportResult> importFromUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.hasScheme || !{'http', 'https'}.contains(uri.scheme)) {
      return PlayerThemeImportResult.failure('Invalid theme URL.');
    }

    http.Response response;
    try {
      response = await http.get(uri).timeout(_importTimeout);
    } catch (error) {
      return PlayerThemeImportResult.failure('Failed to fetch theme JSON: $error');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return PlayerThemeImportResult.failure(
        'Theme URL responded with HTTP ${response.statusCode}.',
      );
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      return PlayerThemeImportResult.failure('Theme URL returned an empty body.');
    }

    return importFromRawJson(body);
  }

  static bool removeDynamicTheme(String id) {
    if (builtInThemeIds.contains(id)) return false;

    final rawThemes = _decodeStoredRawThemes();
    final nextThemes = rawThemes.where((theme) => _themeIdOf(theme) != id).toList();
    if (nextThemes.length == rawThemes.length) return false;

    _saveRawThemes(nextThemes);
    return true;
  }

  static List<Map<String, dynamic>> _decodeStoredRawThemes() {
    final rawJson = dynamicThemeCollectionJson;
    final parsed = JsonPlayerControlTheme.parseCollectionDetailed(rawJson);
    return parsed.rawThemes;
  }

  static void _saveRawThemes(List<Map<String, dynamic>> rawThemes) {
    saveDynamicThemeCollectionJson(jsonEncode({'themes': rawThemes}));
  }

  static String? _themeIdOf(Map<String, dynamic> rawTheme) {
    final id = rawTheme['id']?.toString().trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  static List<JsonPlayerControlTheme> _loadJsonThemes() {
    final rawJson = dynamicThemeCollectionJson;
    return JsonPlayerControlTheme.parseCollection(rawJson);
  }
}
