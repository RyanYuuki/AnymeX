import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class AvatarDecorationItem {
  final String id;
  final String title;
  final String file;
  final String url;
  final int size;

  const AvatarDecorationItem({
    required this.id,
    required this.title,
    required this.file,
    required this.url,
    required this.size,
  });

  factory AvatarDecorationItem.fromJson(Map<String, dynamic> json) {
    return AvatarDecorationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      file: json['file']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      size: json['size'] is int ? json['size'] : int.tryParse(json['size']?.toString() ?? '0') ?? 0,
    );
  }
}

class AnimeBannerItem {
  final String title;
  final String banner;
  final String author;
  final String series;

  const AnimeBannerItem({
    required this.title,
    required this.banner,
    required this.author,
    required this.series,
  });

  factory AnimeBannerItem.fromJson(Map<String, dynamic> json, {String series = 'General'}) {
    return AnimeBannerItem(
      title: json['title']?.toString() ?? '',
      banner: json['banner']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      series: series,
    );
  }
}

class CustomizationRepository {
  static List<AvatarDecorationItem>? _cachedDecorations;
  static List<AnimeBannerItem>? _cachedBanners;
  static Map<String, List<AnimeBannerItem>>? _categorizedBanners;

  static const String _decorationsFallbackUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/decorations.json';
  static const String _bannersFallbackUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/banners.json';

  static Future<List<AvatarDecorationItem>> loadDecorations() async {
    if (_cachedDecorations != null && _cachedDecorations!.isNotEmpty) {
      return _cachedDecorations!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/data/decorations.json');
      final list = json.decode(jsonString) as List;
      _cachedDecorations = list
          .map((item) => AvatarDecorationItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      return _cachedDecorations!;
    } catch (_) {
      try {
        final res = await http.get(Uri.parse(_decorationsFallbackUrl));
        if (res.statusCode == 200) {
          final list = json.decode(res.body) as List;
          _cachedDecorations = list
              .map((item) => AvatarDecorationItem.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          return _cachedDecorations!;
        }
      } catch (e) {
        // Log fallback failure
      }
    }
    return _cachedDecorations ?? [];
  }

  static Future<List<AnimeBannerItem>> loadBanners() async {
    if (_cachedBanners != null && _cachedBanners!.isNotEmpty) {
      return _cachedBanners!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/data/banners.json');
      final list = json.decode(jsonString) as List;
      _parseBannersList(list);
      return _cachedBanners!;
    } catch (_) {
      try {
        final res = await http.get(Uri.parse(_bannersFallbackUrl));
        if (res.statusCode == 200) {
          final list = json.decode(res.body) as List;
          _parseBannersList(list);
          return _cachedBanners!;
        }
      } catch (e) {
        // Log fallback failure
      }
    }
    return _cachedBanners ?? [];
  }

  static void _parseBannersList(List list) {
    final banners = <AnimeBannerItem>[];
    final map = <String, List<AnimeBannerItem>>{};

    for (final seriesGroup in list) {
      if (seriesGroup is Map) {
        final seriesName = seriesGroup['title']?.toString() ?? 'Anime';
        final bannersList = seriesGroup['banners'] as List? ?? [];
        final items = <AnimeBannerItem>[];
        for (final b in bannersList) {
          if (b is Map) {
            final item = AnimeBannerItem.fromJson(Map<String, dynamic>.from(b), series: seriesName);
            items.add(item);
            banners.add(item);
          }
        }
        map[seriesName] = items;
      }
    }

    _cachedBanners = banners;
    _categorizedBanners = map;
  }

  static Future<Map<String, List<AnimeBannerItem>>> loadCategorizedBanners() async {
    if (_categorizedBanners != null && _categorizedBanners!.isNotEmpty) {
      return _categorizedBanners!;
    }
    await loadBanners();
    return _categorizedBanners ?? {};
  }
}
