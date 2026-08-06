import 'package:anymex/screens/settings/search/settings_registry.dart';
import 'package:anymex/screens/settings/search/settings_search_metadata.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

final _idIcons = <String, IconData>{
  for (final meta in settingsSearchMetadata)
    if (meta.icon != null)
      settingsEntryId(
        category: meta.category,
        section: meta.section,
        key: meta.stableKey ?? meta.title,
      ): meta.icon!,
};

final _idAssetIcons = <String, String>{
  for (final meta in settingsSearchMetadata)
    if (meta.assetIcon != null)
      settingsEntryId(
        category: meta.category,
        section: meta.section,
        key: meta.stableKey ?? meta.title,
      ): meta.assetIcon!,
};

Widget buildSettingsSearchLeading(
    BuildContext context, SettingsSearchEntry item) {
  final asset = _idAssetIcons[item.id];
  if (asset != null) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        asset,
        width: 22,
        height: 22,
        fit: BoxFit.cover,
      ),
    );
  }

  final icon = _idIcons[item.id] ??
      settingsSearchCategoryIcons[item.category] ??
      Icons.settings;

  return Icon(icon, color: context.colors.primary);
}
