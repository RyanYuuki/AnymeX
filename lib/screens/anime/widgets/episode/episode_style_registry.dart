import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/episode/styles/compact_style.dart';
import 'package:anymex/screens/anime/widgets/episode/styles/detailed_style.dart';
import 'package:anymex/screens/anime/widgets/episode/styles/minimal_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum EpisodeStyleType {
  minimal,
  compact,
  detailed,
}

class EpisodeStyle {
  final String id;
  final String name;
  final String description;
  final EpisodeStyleType styleType;
  final Widget Function(
    BuildContext context,
    Episode episode,
    bool isSelected,
    bool isWatched,
    double progress,
    Media? media,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  ) builder;

  const EpisodeStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.styleType,
    required this.builder,
  });

  bool get isGrid => styleType == EpisodeStyleType.minimal;
}

class EpisodeStyleRegistry {
  static final RxString currentStyleId =
      PlayerUiKeys.mediaIndicatorTheme.get<String>('compact').obs;

  static void setStyle(String id) {
    currentStyleId.value = id;
    PlayerUiKeys.mediaIndicatorTheme.set(id);
  }

  static EpisodeStyle get activeStyle => getStyle(currentStyleId.value);

  static final List<EpisodeStyle> _styles = [
    const EpisodeStyle(
      id: 'minimal',
      name: 'Minimal',
      description:
          'Simple layout displaying episode number, title, and progress without thumbnail',
      styleType: EpisodeStyleType.minimal,
      builder: buildMinimalEpisodeStyle,
    ),
    const EpisodeStyle(
      id: 'compact',
      name: 'Compact',
      description: 'Compact card with episode thumbnail and title',
      styleType: EpisodeStyleType.compact,
      builder: buildCompactEpisodeStyle,
    ),
    const EpisodeStyle(
      id: 'detailed',
      name: 'Detailed',
      description:
          'Full-width detailed card with large thumbnail and episode metadata',
      styleType: EpisodeStyleType.detailed,
      builder: buildDetailedEpisodeStyle,
    ),
  ];

  static List<EpisodeStyle> get styles => List.unmodifiable(_styles);

  static EpisodeStyle getStyle(String? id) {
    if (id == null || id.isEmpty || id == 'default') {
      return _styles.firstWhere((s) => s.id == 'detailed');
    }
    return _styles.firstWhere(
      (s) => s.id == id,
      orElse: () => _styles.firstWhere((s) => s.id == 'detailed'),
    );
  }
}
