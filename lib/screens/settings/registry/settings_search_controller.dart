import 'package:anymex/screens/settings/registry/settings_model.dart';
import 'package:anymex/screens/settings/registry/settings_registry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SettingsSearchController {
  final TextEditingController textController = TextEditingController();
  final ValueNotifier<Map<String, List<SettingItem>>> resultsNotifier =
      ValueNotifier(<String, List<SettingItem>>{});

  SettingsSearchController() {
    textController.addListener(_onSearchInputChanged);
  }

  bool get isSearching => textController.text.trim().isNotEmpty;

  Map<String, List<SettingItem>> get results => resultsNotifier.value;

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
    for (final entry in SettingsRegistry.allItems) {
      assert(SettingsRegistry.categoryRoutes.containsKey(entry.category),
          'Registry: "${entry.title}" has unknown category "${entry.category}"');
      final key = '${entry.category}:${entry.section}:${entry.title}';
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
        resultsNotifier.value = <String, List<SettingItem>>{};
      }
      return;
    }

    final grouped = <String, List<SettingItem>>{};
    for (final item in SettingsRegistry.allItems) {
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
          .map((k, v) => MapEntry(k, v.map((e) => e.id).toList())),
      grouped.map((k, v) => MapEntry(k, v.map((e) => e.id).toList())),
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
