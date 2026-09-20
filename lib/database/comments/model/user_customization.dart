import 'dart:convert';
import 'dart:developer';
import 'package:anymex/services/commentum_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CustomizationItem {
  final String id;
  final String type; // 'decoration', 'nameplate', 'banner', 'effect'
  final String title;
  final String category;
  final String url;
  final String? file;
  final String? assetId;
  final String? description;
  final int pointsRequired;
  final String? staticUrl;
  final String? webmUrl;
  final String? thumbnailUrl;
  final List<dynamic>? effects;
  final Map<String, dynamic> metadata;

  const CustomizationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.url,
    this.file,
    this.assetId,
    this.description,
    this.pointsRequired = 0,
    this.staticUrl,
    this.webmUrl,
    this.thumbnailUrl,
    this.effects,
    this.metadata = const {},
  });

  factory CustomizationItem.fromJson(Map<String, dynamic> json) {
    final meta = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'])
        : <String, dynamic>{};
    return CustomizationItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'decoration',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      url: json['url']?.toString() ?? json['banner']?.toString() ?? '',
      file: json['file']?.toString(),
      assetId: json['asset_id']?.toString(),
      description: json['description']?.toString(),
      pointsRequired: json['points_required'] is int
          ? json['points_required']
          : int.tryParse(json['points_required']?.toString() ?? '0') ?? 0,
      staticUrl:
          json['static_url']?.toString() ?? meta['static_url']?.toString(),
      webmUrl: json['webm_url']?.toString() ?? json['url']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString() ??
          meta['thumbnailPreviewSrc']?.toString(),
      effects: json['effects'] is List
          ? json['effects']
          : (meta['effects'] is List ? meta['effects'] : null),
      metadata: meta,
    );
  }
}

class AvatarDecorationItem {
  final String id;
  final String title;
  final String file;
  final String url;
  final int size;
  final String category;
  final int pointsRequired;

  const AvatarDecorationItem({
    required this.id,
    required this.title,
    required this.file,
    required this.url,
    required this.size,
    this.category = 'General',
    this.pointsRequired = 0,
  });

  factory AvatarDecorationItem.fromJson(Map<String, dynamic> json) {
    return AvatarDecorationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      file: json['file']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      size: json['size'] is int
          ? json['size']
          : int.tryParse(json['size']?.toString() ?? '0') ?? 0,
      category: json['category']?.toString() ?? 'General',
      pointsRequired: json['points_required'] is int
          ? json['points_required']
          : int.tryParse(json['points_required']?.toString() ?? '0') ?? 0,
    );
  }
}

class AnimeBannerItem {
  final String id;
  final String title;
  final String banner;
  final String author;
  final String series;
  final int pointsRequired;

  const AnimeBannerItem({
    this.id = '',
    required this.title,
    required this.banner,
    required this.author,
    required this.series,
    this.pointsRequired = 0,
  });

  factory AnimeBannerItem.fromJson(Map<String, dynamic> json,
      {String series = 'General'}) {
    return AnimeBannerItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      banner: json['banner']?.toString() ?? json['url']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      series: json['category']?.toString() ?? series,
      pointsRequired: json['points_required'] is int
          ? json['points_required']
          : int.tryParse(json['points_required']?.toString() ?? '0') ?? 0,
    );
  }
}

class CustomizationRepository {
  static List<AvatarDecorationItem>? _cachedDecorations;
  static List<CustomizationItem>? _cachedNameplates;
  static List<CustomizationItem>? _cachedEffects;
  static List<AnimeBannerItem>? _cachedBanners;
  static Map<String, List<AnimeBannerItem>>? _categorizedBanners;

  static String get _apiBaseUrl {
    if (Get.isRegistered<CommentumService>()) {
      return Get.find<CommentumService>().baseUrl;
    }
    final env = (dotenv.env['COMMENTS_BASE_URL'] ?? '').trim();
    if (env.isNotEmpty) {
      return env.endsWith('/') ? env.substring(0, env.length - 1) : env;
    }
    throw StateError('COMMENTS_BASE_URL is missing in .env');
  }

  static Future<List<AvatarDecorationItem>> loadDecorations(
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedDecorations != null &&
        _cachedDecorations!.isNotEmpty) {
      return _cachedDecorations!;
    }

    try {
      final res = await http
          .get(Uri.parse(
              '$_apiBaseUrl/customizations?type=decoration&limit=1000'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List;
        _cachedDecorations = list
            .map((item) =>
                AvatarDecorationItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        return _cachedDecorations!;
      }
    } catch (e) {
      log('Error loading decorations from API: $e');
    }
    return _cachedDecorations ?? [];
  }

  static Future<List<CustomizationItem>> loadNameplates(
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedNameplates != null &&
        _cachedNameplates!.isNotEmpty) {
      return _cachedNameplates!;
    }

    try {
      final res = await http
          .get(
              Uri.parse('$_apiBaseUrl/customizations?type=nameplate&limit=1000'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List;
        _cachedNameplates = list
            .map((item) =>
                CustomizationItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        return _cachedNameplates!;
      }
    } catch (e) {
      log('Error loading nameplates from API: $e');
    }
    return _cachedNameplates ?? [];
  }

  static Future<List<CustomizationItem>> loadEffects(
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedEffects != null && _cachedEffects!.isNotEmpty) {
      return _cachedEffects!;
    }

    try {
      final res = await http
          .get(Uri.parse('$_apiBaseUrl/customizations?type=effect&limit=1000'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List;
        _cachedEffects = list
            .map((item) =>
                CustomizationItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        return _cachedEffects!;
      }
    } catch (e) {
      log('Error loading profile effects from API: $e');
    }
    return _cachedEffects ?? [];
  }

  static Future<List<AnimeBannerItem>> loadBanners(
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedBanners != null && _cachedBanners!.isNotEmpty) {
      return _cachedBanners!;
    }

    try {
      final res = await http
          .get(Uri.parse('$_apiBaseUrl/customizations?type=banner&limit=2000'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List;
        final banners = <AnimeBannerItem>[];
        final map = <String, List<AnimeBannerItem>>{};

        for (final item in list) {
          if (item is Map) {
            final banner =
                AnimeBannerItem.fromJson(Map<String, dynamic>.from(item));
            banners.add(banner);
            map.putIfAbsent(banner.series, () => []).add(banner);
          }
        }

        _cachedBanners = banners;
        _categorizedBanners = map;
        return _cachedBanners!;
      }
    } catch (e) {
      log('Error loading banners from API: $e');
    }
    return _cachedBanners ?? [];
  }

  static Future<Map<String, List<AnimeBannerItem>>> loadCategorizedBanners(
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _categorizedBanners != null &&
        _categorizedBanners!.isNotEmpty) {
      return _categorizedBanners!;
    }
    await loadBanners(forceRefresh: forceRefresh);
    return _categorizedBanners ?? {};
  }
}
