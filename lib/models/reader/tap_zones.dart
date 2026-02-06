import 'dart:convert';

import 'package:flutter/material.dart';

enum ReaderAction {
  nextPage,
  prevPage,
  toggleMenu,
  scrollUp,
  scrollDown,
  nextChapter,
  prevChapter,
  none,
}

extension ReaderActionExtension on ReaderAction {
  String get displayName {
    switch (this) {
      case ReaderAction.nextPage:
        return 'Next Page';
      case ReaderAction.prevPage:
        return 'Previous Page';
      case ReaderAction.toggleMenu:
        return 'Show/Hide UI';
      case ReaderAction.scrollUp:
        return 'Scroll Up';
      case ReaderAction.scrollDown:
        return 'Scroll Down';
      case ReaderAction.nextChapter:
        return 'Next Chapter';
      case ReaderAction.prevChapter:
        return 'Previous Chapter';
      case ReaderAction.none:
        return 'None';
    }
  }
}

class TapZone {
  final Rect bounds;
  final ReaderAction action;

  TapZone({
    required this.bounds,
    required this.action,
  });

  Map<String, dynamic> toJson() {
    return {
      'l': bounds.left,
      't': bounds.top,
      'r': bounds.right,
      'b': bounds.bottom,
      'a': action.index,
    };
  }

  factory TapZone.fromJson(Map<String, dynamic> json) {
    return TapZone(
      bounds: Rect.fromLTRB(
        (json['l'] as num).toDouble(),
        (json['t'] as num).toDouble(),
        (json['r'] as num).toDouble(),
        (json['b'] as num).toDouble(),
      ),
      action: ReaderAction.values[json['a'] as int],
    );
  }

  bool contains(Offset normalizedPoint) {
    return bounds.contains(normalizedPoint);
  }
}

class TapZoneLayout {
  final String id;
  final String name;
  final List<TapZone> zones;

  TapZoneLayout({
    required this.id,
    required this.name,
    required this.zones,
  });

  ReaderAction getAction(Offset normalizedPoint) {
    for (var i = zones.length - 1; i >= 0; i--) {
      if (zones[i].contains(normalizedPoint)) {
        return zones[i].action;
      }
    }
    return ReaderAction.none;
  }

  String toJsonString() {
    return jsonEncode({
      'id': id,
      'name': name,
      'zones': zones.map((z) => z.toJson()).toList(),
    });
  }

  factory TapZoneLayout.fromJsonString(String jsonStr) {
    final map = jsonDecode(jsonStr);
    return TapZoneLayout(
      id: map['id'],
      name: map['name'],
      zones: (map['zones'] as List)
          .map((z) => TapZone.fromJson(z))
          .toList(),
    );
  }

  static TapZoneLayout get defaultPaged => TapZoneLayout(
    id: 'default_paged',
    name: 'Standard Paged',
    zones: [
      TapZone(
        bounds: const Rect.fromLTWH(0.0, 0.0, 0.3, 1.0),
        action: ReaderAction.prevPage,
      ),
      TapZone(
        bounds: const Rect.fromLTWH(0.7, 0.0, 0.3, 1.0),
        action: ReaderAction.nextPage,
      ),
      TapZone(
        bounds: const Rect.fromLTWH(0.3, 0.0, 0.4, 1.0),
        action: ReaderAction.toggleMenu,
      ),
    ],
  );

  static TapZoneLayout get defaultPagedVertical => TapZoneLayout(
    id: 'default_paged_vertical',
    name: 'Standard Paged (Vertical)',
    zones: [
      TapZone(
        bounds: const Rect.fromLTWH(0.0, 0.0, 1.0, 0.3),
        action: ReaderAction.prevPage,
      ),
      TapZone(
        bounds: const Rect.fromLTWH(0.0, 0.7, 1.0, 0.3),
        action: ReaderAction.nextPage,
      ),
      TapZone(
        bounds: const Rect.fromLTWH(0.0, 0.3, 1.0, 0.4),
        action: ReaderAction.toggleMenu,
      ),
    ],
  );

  static TapZoneLayout get defaultWebtoon => TapZoneLayout(
    id: 'default_webtoon',
    name: 'Standard Webtoon',
    zones: [
      TapZone(
        bounds: const Rect.fromLTWH(0.0, 0.0, 1.0, 0.3),
        action: ReaderAction.scrollUp,
      ),
      TapZone(
        bounds: const Rect.fromLTWH(0.0, 0.7, 1.0, 0.3),
        action: ReaderAction.scrollDown,
      ),
      TapZone(
        bounds: const Rect.fromLTWH(0.0, 0.3, 1.0, 0.4),
        action: ReaderAction.toggleMenu,
      ),
    ],
  );

  static TapZoneLayout get defaultWebtoonHorizontal => TapZoneLayout(
    id: 'default_webtoon_horizontal',
    name: 'Standard Webtoon (Horizontal)',
    zones: [
      TapZone(
        bounds: const Rect.fromLTWH(0.0, 0.0, 0.3, 1.0),
        action: ReaderAction.scrollUp,
      ),
      TapZone(
        bounds: const Rect.fromLTWH(0.7, 0.0, 0.3, 1.0),
        action: ReaderAction.scrollDown,
      ),
      TapZone(
        bounds: const Rect.fromLTWH(0.3, 0.0, 0.4, 1.0),
        action: ReaderAction.toggleMenu,
      ),
    ],
  );
}
