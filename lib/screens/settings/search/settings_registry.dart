import 'package:anymex/screens/settings/sub_settings/settings_about.dart';
import 'package:anymex/screens/settings/sub_settings/settings_accounts.dart';
import 'package:anymex/screens/settings/sub_settings/settings_backup.dart';
import 'package:anymex/screens/settings/sub_settings/settings_common.dart';
import 'package:anymex/screens/settings/sub_settings/settings_experimental.dart';
import 'package:anymex/screens/settings/sub_settings/settings_extensions.dart';
import 'package:anymex/screens/settings/sub_settings/settings_logs.dart';
import 'package:anymex/screens/settings/sub_settings/settings_player.dart';
import 'package:anymex/screens/settings/sub_settings/settings_reader.dart';
import 'package:anymex/screens/settings/sub_settings/settings_storage_manager.dart';
import 'package:anymex/screens/settings/sub_settings/settings_theme.dart';
import 'package:anymex/screens/settings/sub_settings/settings_ui.dart';
import 'package:anymex/screens/settings/search/settings_search_metadata.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Model

class SettingsSearchEntry {
  final String id;
  final String title, category;
  final String? expansionTitle;
  final String? highlightTitle;

  SettingsSearchEntry(
    this.title,
    this.category, {
    this.expansionTitle,
    this.highlightTitle,
    String? stableKey,
  }) : id = settingsEntryId(
          category: category,
          section: expansionTitle,
          key: stableKey ?? title,
        );
  String get targetTitle => highlightTitle ?? title;

  String _normalize(String value) => value.trim().toLowerCase();

  bool matches(String query) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return false;
    return _normalize(title).contains(normalizedQuery);
  }

  int relevanceScore(String query) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return 0;

    final titleN = _normalize(title);
    if (!titleN.contains(normalizedQuery)) return 0;

    var score = 0;

    if (titleN == normalizedQuery) {
      score += 1100;
    } else if (titleN.startsWith(normalizedQuery)) {
      score += 900;
    } else if (titleN.contains(normalizedQuery)) {
      score += 700;
    }

    return score;
  }
}

String _normalizeIdPart(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'_+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

String settingsEntryId({
  required String category,
  String? section,
  required String key,
}) {
  final cat = _normalizeIdPart(category);
  final sec = section == null ? '' : '_${_normalizeIdPart(section)}';
  final k = _normalizeIdPart(key);
  return '${cat}${sec}_$k';
}

// Category config

final categoryRoutes = <String, Widget Function()>{
  'Accounts': () => const SettingsAccounts(),
  'Common': () => const SettingsCommon(),
  'Backup & Restore': () => const BackupRestorePage(),
  'Storage Manager': () => const SettingsStorageManager(),
  'UI': () => const SettingsUi(),
  'Player': () => const SettingsPlayer(),
  'Reader': () => const SettingsReader(),
  'Theme': () => const SettingsTheme(),
  'Extensions': () => const SettingsExtensions(),
  'Experimental': () => const SettingsExperimental(),
  'Logs': () => const SettingsLogs(),
  'About': () => const AboutPage(),
};

final settingsRegistry = settingsSearchMetadata
    .map((meta) => SettingsSearchEntry(
          meta.title,
          meta.category,
          expansionTitle: meta.section,
          highlightTitle: meta.highlightTitle,
          stableKey: meta.stableKey,
        ))
    .toList();

class SettingsSearchController {
  final TextEditingController textController = TextEditingController();
  final ValueNotifier<Map<String, List<SettingsSearchEntry>>> resultsNotifier =
      ValueNotifier(<String, List<SettingsSearchEntry>>{});

  SettingsSearchController() {
    textController.addListener(_onSearchInputChanged);
  }

  bool get isSearching => textController.text.trim().isNotEmpty;

  Map<String, List<SettingsSearchEntry>> get results => resultsNotifier.value;

  List<String> sortedCategories(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    int categoryScore(String category) {
      final items = results[category];
      if (items == null || items.isEmpty) return 0;
      var best = 0;
      for (final item in items) {
        final score = item.relevanceScore(normalizedQuery);
        if (score > best) best = score;
      }
      if (normalizedQuery.isNotEmpty) {
        final categoryLower = category.toLowerCase();
        if (categoryLower == normalizedQuery) {
          best += 1600;
        } else if (categoryLower.startsWith(normalizedQuery)) {
          best += 280;
        }
      }
      return best;
    }

    final categories = results.keys.toList()
      ..sort((a, b) {
        final scoreCmp = categoryScore(b).compareTo(categoryScore(a));
        if (scoreCmp != 0) return scoreCmp;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    return categories;
  }

  bool validateRegistry() {
    final seen = <String>{};
    for (final entry in settingsRegistry) {
      assert(categoryRoutes.containsKey(entry.category),
          'Registry: "${entry.title}" has unknown category "${entry.category}"');
      final key = '${entry.category}:${entry.expansionTitle}:${entry.title}';
      assert(seen.add(key), 'Registry: duplicate entry "$key"');
    }
    return true;
  }

  void _onSearchInputChanged() {
    _computeResults();
  }

  void _computeResults() {
    final query = textController.text.trim();
    if (query.isEmpty) {
      if (resultsNotifier.value.isNotEmpty) {
        resultsNotifier.value = <String, List<SettingsSearchEntry>>{};
      }
      return;
    }

    final grouped = <String, List<SettingsSearchEntry>>{};
    for (final item in settingsRegistry) {
      if (item.matches(query)) {
        grouped.putIfAbsent(item.category, () => []).add(item);
      }
    }

    for (final list in grouped.values) {
      list.sort((a, b) {
        final scoreCmp =
            b.relevanceScore(query).compareTo(a.relevanceScore(query));
        if (scoreCmp != 0) return scoreCmp;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    }

    final hasChanged = !mapEquals(
      resultsNotifier.value
          .map((k, v) => MapEntry(k, v.map((e) => e.title).toList())),
      grouped.map((k, v) => MapEntry(k, v.map((e) => e.title).toList())),
    );

    if (hasChanged) {
      resultsNotifier.value = grouped;
    }
  }

  void dispose() {
    textController.removeListener(_onSearchInputChanged);
    textController.dispose();
    resultsNotifier.dispose();
  }
}
