import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';

class MediaCardProps {
  final CarouselData itemData;
  final String tag;
  final DataVariant variant;
  final ItemType type;

  const MediaCardProps({
    required this.itemData,
    required this.tag,
    required this.variant,
    required this.type,
  });

  bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width > 600;
}

abstract class MediaCardStyle {
  String get id;
  String get displayName;
  String get description;

  double getHeight(bool isDesktop);
  double getExtraHeight(bool isDesktop);
  double getAspectRatio(bool isDesktop);
  Widget buildCard(BuildContext context, MediaCardProps props);
}

class MediaCardRegistry {
  static final List<MediaCardStyle> _styles = [];

  static List<MediaCardStyle> get styles => List.unmodifiable(_styles);

  static void register(MediaCardStyle style) {
    if (!_styles.any((s) => s.id == style.id)) {
      _styles.add(style);
    }
  }

  static MediaCardStyle getById(String id) {
    return _styles.firstWhere(
      (s) => s.id.toLowerCase() == id.toLowerCase(),
      orElse: () => _styles.first,
    );
  }

  static MediaCardStyle getByIndex(int index) {
    if (_styles.isEmpty) {
      throw StateError('MediaCardRegistry is empty. Ensure styles are registered.');
    }
    final safeIndex = index.clamp(0, _styles.length - 1);
    return _styles[safeIndex];
  }

  static Widget buildById({
    required BuildContext context,
    required String styleId,
    required MediaCardProps props,
  }) {
    final style = getById(styleId);
    return style.buildCard(context, props);
  }

  static Widget buildByIndex({
    required BuildContext context,
    required int index,
    required MediaCardProps props,
  }) {
    final style = getByIndex(index);
    return style.buildCard(context, props);
  }

  static double getHeightByIndex(int index, bool isDesktop) {
    if (_styles.isEmpty) return isDesktop ? 230 : 170;
    return getByIndex(index).getHeight(isDesktop);
  }

  static double getExtraHeightByIndex(int index, bool isDesktop) {
    if (_styles.isEmpty) return 0;
    return getByIndex(index).getExtraHeight(isDesktop);
  }

  static double getAspectRatioByIndex(int index, bool isDesktop) {
    if (_styles.isEmpty) return isDesktop ? (150 / 230) : (108 / 170);
    return getByIndex(index).getAspectRatio(isDesktop);
  }
}
