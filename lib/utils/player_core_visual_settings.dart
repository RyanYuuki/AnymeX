import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/logger.dart';

class PlayerCoreVisualSettings {
  static bool get isExperimentalEnabled =>
      PlayerUiKeys.playerExperimentalEnabled.get<bool>(false);

  static const Map<String, dynamic> mpvCoreDefaults = {
    'hwdec': 'no',
    'videoSync': 'audio',
    'interpolation': false,
    'cacheMinutes': 5,
    'demuxerReadaheadSeconds': 20,
    'demuxerMaxBytesMb': 64,
    'vdLavcThreads': 0,
    'audioPitchCorrection': true,
  };

  static const Map<String, dynamic> betterPlayerCoreDefaults = {
    'bufferSizeMb': 32,
    'autoPlay': true,
    'useBuffering': true,
  };

  static const Map<String, dynamic> mpvVisualDefaults = {
    'deband': true,
    'debandIterations': 2,
    'debandThreshold': 64,
    'correctDownscaling': true,
    'sigmoidUpscaling': true,
    'scale': 'ewa_lanczossharp',
    'cscale': 'ewa_lanczossharp',
    'dscale': 'mitchell',
    'ditherDepth': 'auto',
    'temporalDither': true,
    'toneMapping': 'auto',
    'targetPeak': 100,
  };

  static Map<String, dynamic> getMpvCoreSettings() {
    final raw = PlayerUiKeys.mpvCoreSettings.get<Map<String, dynamic>>({});
    return _normalized(raw, mpvCoreDefaults);
  }

  static Map<String, dynamic> getBetterPlayerCoreSettings() {
    final raw =
        PlayerUiKeys.betterPlayerCoreSettings.get<Map<String, dynamic>>({});
    return _normalized(raw, betterPlayerCoreDefaults);
  }

  static Map<String, dynamic> getMpvVisualSettings() {
    final raw = PlayerUiKeys.mpvVisualSettings.get<Map<String, dynamic>>({});
    return _normalized(raw, mpvVisualDefaults);
  }

  static void setMpvCoreSetting(String key, dynamic value) {
    if (!isExperimentalEnabled) return;
    final next = getMpvCoreSettings();
    next[key] = value;
    PlayerUiKeys.mpvCoreSettings.set(next);
  }

  static void setBetterPlayerCoreSetting(String key, dynamic value) {
    if (!isExperimentalEnabled) return;
    final next = getBetterPlayerCoreSettings();
    next[key] = value;
    PlayerUiKeys.betterPlayerCoreSettings.set(next);
  }

  static void setMpvVisualSetting(String key, dynamic value) {
    if (!isExperimentalEnabled) return;
    final next = getMpvVisualSettings();
    next[key] = value;
    PlayerUiKeys.mpvVisualSettings.set(next);
  }

  static Future<void> applyMpvCoreSettings(dynamic player) async {
    if (!isExperimentalEnabled) return;
    if (player?.platform == null) return;
    final settings = getMpvCoreSettings();
    final mpv = player.platform as dynamic;

    // await _safeSet(mpv, 'hwdec', settings['hwdec']);
    await _safeSet(mpv, 'video-sync', settings['videoSync']);
    await _safeSet(mpv, 'interpolation', _boolToMpv(settings['interpolation']));
    await _safeSet(
        mpv, 'cache-secs', (settings['cacheSeconds'] as num?)?.toInt() ?? 30);
    await _safeSet(mpv, 'demuxer-readahead-secs',
        (settings['demuxerReadaheadSeconds'] as num?)?.toInt() ?? 20);
    await _safeSet(
      mpv,
      'demuxer-max-bytes',
      ((settings['demuxerMaxBytesMb'] as num?)?.toInt() ?? 64) * 1024 * 1024,
    );
    await _safeSet(mpv, 'vd-lavc-threads',
        (settings['vdLavcThreads'] as num?)?.toInt() ?? 0);
    await _safeSet(
      mpv,
      'audio-pitch-correction',
      _boolToMpv(settings['audioPitchCorrection']),
    );
  }

  static Future<void> applyMpvVisualSettings(dynamic player) async {
    if (!isExperimentalEnabled) return;
    if (player?.platform == null) return;
    final settings = getMpvVisualSettings();
    final mpv = player.platform as dynamic;

    await _safeSet(mpv, 'deband', _boolToMpv(settings['deband']));
    await _safeSet(
      mpv,
      'deband-iterations',
      (settings['debandIterations'] as num?)?.toInt() ?? 2,
    );
    await _safeSet(
      mpv,
      'deband-threshold',
      (settings['debandThreshold'] as num?)?.toInt() ?? 64,
    );
    await _safeSet(
      mpv,
      'correct-downscaling',
      _boolToMpv(settings['correctDownscaling']),
    );
    await _safeSet(
      mpv,
      'sigmoid-upscaling',
      _boolToMpv(settings['sigmoidUpscaling']),
    );
    await _safeSet(mpv, 'scale', settings['scale']);
    await _safeSet(mpv, 'cscale', settings['cscale']);
    await _safeSet(mpv, 'dscale', settings['dscale']);
    await _safeSet(mpv, 'dither-depth', settings['ditherDepth']);
    await _safeSet(
      mpv,
      'temporal-dither',
      _boolToMpv(settings['temporalDither']),
    );
    await _safeSet(mpv, 'tone-mapping', settings['toneMapping']);
    await _safeSet(mpv, 'target-peak', (settings['targetPeak'] as num?) ?? 100);
  }

  static String _boolToMpv(dynamic value) => value == true ? 'yes' : 'no';

  static Map<String, dynamic> _normalized(
      Map<String, dynamic> raw, Map<String, dynamic> defaults) {
    final next = <String, dynamic>{...defaults};
    for (final entry in raw.entries) {
      if (defaults.containsKey(entry.key)) {
        next[entry.key] = entry.value;
      }
    }
    return next;
  }

  static Future<void> _safeSet(dynamic mpv, String key, dynamic value) async {
    try {
      await mpv.setProperty(key, value.toString());
    } catch (e) {
      Logger.d('mpv setProperty failed for $key=$value: $e');
    }
  }
}
