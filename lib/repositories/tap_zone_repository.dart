import 'package:hive/hive.dart';
import '../models/reader/tap_zones.dart';

class TapZoneRepository {
  final Box _box = Hive.box('preferences');
  static const String _pagedKey = 'tap_zones_paged';
  static const String _pagedVerticalKey = 'tap_zones_paged_vertical';
  static const String _webtoonKey = 'tap_zones_webtoon';
  static const String _webtoonHorizontalKey = 'tap_zones_webtoon_horizontal';
  static const String _enabledKey = 'tap_zones_enabled';

  TapZoneLayout getPagedLayout() {
    return _loadLayout(_pagedKey) ?? TapZoneLayout.defaultPaged;
  }

  TapZoneLayout getWebtoonLayout() {
    return _loadLayout(_webtoonKey) ?? TapZoneLayout.defaultWebtoon;
  }

  TapZoneLayout getPagedVerticalLayout() {
    return _loadLayout(_pagedVerticalKey) ?? TapZoneLayout.defaultPagedVertical;
  }

  TapZoneLayout getWebtoonHorizontalLayout() {
    return _loadLayout(_webtoonHorizontalKey) ?? TapZoneLayout.defaultWebtoonHorizontal;
  }

  TapZoneLayout? _loadLayout(String key) {
    final String? jsonStr = _box.get(key);
    if (jsonStr == null) return null;
    try {
      return TapZoneLayout.fromJsonString(jsonStr);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePagedLayout(TapZoneLayout layout) async {
    await _box.put(_pagedKey, layout.toJsonString());
  }

  Future<void> savePagedVerticalLayout(TapZoneLayout layout) async {
    await _box.put(_pagedVerticalKey, layout.toJsonString());
  }

  Future<void> saveWebtoonLayout(TapZoneLayout layout) async {
    await _box.put(_webtoonKey, layout.toJsonString());
  }

  Future<void> saveWebtoonHorizontalLayout(TapZoneLayout layout) async {
    await _box.put(_webtoonHorizontalKey, layout.toJsonString());
  }

  bool getTapZonesEnabled() {
    return _box.get(_enabledKey, defaultValue: true);
  }

  Future<void> saveTapZonesEnabled(bool enabled) async {
    await _box.put(_enabledKey, enabled);
  }
}
