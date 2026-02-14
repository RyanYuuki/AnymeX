import 'package:anymex/database/data_keys/keys.dart';
import '../models/reader/tap_zones.dart';

class TapZoneRepository {
  TapZoneLayout getPagedLayout() {
    return _loadLayout(TapZoneKeys.tapZonesPaged) ?? TapZoneLayout.defaultPaged;
  }

  TapZoneLayout getWebtoonLayout() {
    return _loadLayout(TapZoneKeys.tapZonesWebtoon) ?? TapZoneLayout.defaultWebtoon;
  }

  TapZoneLayout getPagedVerticalLayout() {
    return _loadLayout(TapZoneKeys.tapZonesPagedVertical) ??
        TapZoneLayout.defaultPagedVertical;
  }

  TapZoneLayout getWebtoonHorizontalLayout() {
    return _loadLayout(TapZoneKeys.tapZonesWebtoonHorizontal) ??
        TapZoneLayout.defaultWebtoonHorizontal;
  }

  TapZoneLayout? _loadLayout(TapZoneKeys key) {
    final String? jsonStr = key.get<String?>();
    if (jsonStr == null) return null;
    try {
      return TapZoneLayout.fromJsonString(jsonStr);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePagedLayout(TapZoneLayout layout) async {
    TapZoneKeys.tapZonesPaged.set(layout.toJsonString());
  }

  Future<void> savePagedVerticalLayout(TapZoneLayout layout) async {
    TapZoneKeys.tapZonesPagedVertical.set(layout.toJsonString());
  }

  Future<void> saveWebtoonLayout(TapZoneLayout layout) async {
    TapZoneKeys.tapZonesWebtoon.set(layout.toJsonString());
  }

  Future<void> saveWebtoonHorizontalLayout(TapZoneLayout layout) async {
    TapZoneKeys.tapZonesWebtoonHorizontal.set(layout.toJsonString());
  }

  bool getTapZonesEnabled() {
    return TapZoneKeys.tapZonesEnabled.get<bool>(true);
  }

  Future<void> saveTapZonesEnabled(bool enabled) async {
    TapZoneKeys.tapZonesEnabled.set(enabled);
  }
}
