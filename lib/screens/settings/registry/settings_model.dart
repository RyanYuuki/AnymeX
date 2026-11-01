import 'package:flutter/material.dart';

class SettingItem {
  final String title;
  final String? subtitle;
  final String category;
  final String? section;
  final String? highlightTitle;
  final String? stableKey;
  final IconData? icon;
  final String? assetIcon;
  final List<String> searchTags;

  final String id;

  SettingItem({
    required this.title,
    required this.category,
    this.subtitle,
    this.section,
    this.highlightTitle,
    this.stableKey,
    this.icon,
    this.assetIcon,
    this.searchTags = const [],
  }) : id = _buildId(
          category: category,
          section: section,
          key: stableKey ?? title,
        );

  String get targetTitle => highlightTitle ?? title;

  static String _normalize(String value) => value.trim().toLowerCase();

  static String _normalizeIdPart(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  static String _buildId({
    required String category,
    String? section,
    required String key,
  }) {
    final cat = _normalizeIdPart(category);
    final sec = section == null ? '' : '_${_normalizeIdPart(section)}';
    final k = _normalizeIdPart(key);
    return '$cat${sec}_$k';
  }

  bool matches(String query) {
    final nQuery = _normalize(query);
    if (nQuery.isEmpty) return false;

    if (_normalize(title).contains(nQuery)) return true;
    if (subtitle != null && _normalize(subtitle!).contains(nQuery)) return true;
    if (section != null && _normalize(section!).contains(nQuery)) return true;
    for (final tag in searchTags) {
      if (_normalize(tag).contains(nQuery)) return true;
    }
    return false;
  }

  int relevanceScore(String query) {
    final nQuery = _normalize(query);
    if (nQuery.isEmpty) return 0;

    final nTitle = _normalize(title);
    var score = 0;

    if (nTitle == nQuery) {
      score += 1500;
    } else if (nTitle.startsWith(nQuery)) {
      score += 1000;
    } else if (nTitle.contains(nQuery)) {
      score += 700;
    }

    for (final tag in searchTags) {
      final nTag = _normalize(tag);
      if (nTag == nQuery) {
        score += 800;
      } else if (nTag.startsWith(nQuery)) {
        score += 500;
      } else if (nTag.contains(nQuery)) {
        score += 300;
      }
    }

    if (section != null && _normalize(section!).contains(nQuery)) {
      score += 200;
    }

    if (subtitle != null && _normalize(subtitle!).contains(nQuery)) {
      score += 150;
    }

    return score;
  }
}

class SettingsCategory {
  final String id;
  final String title;
  final String groupTitle;
  final String description;
  final IconData icon;
  final Widget Function() destination;
  final List<SettingItem> items;

  const SettingsCategory({
    required this.id,
    required this.title,
    required this.groupTitle,
    required this.description,
    required this.icon,
    required this.destination,
    required this.items,
  });
}
