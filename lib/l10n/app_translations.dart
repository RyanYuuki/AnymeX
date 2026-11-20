import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Main translations class for AnymeX.
///
/// Strings live in assets/l10n/<file>.json and are edited through Weblate.
/// See lib/l10n/README.md. [load] must finish before the app starts.
///
/// Usage in widgets: 'key'.tr or LocaleKeys.navHome.tr
class AppTranslations extends Translations {
  /// GetX locale key -> JSON file name in assets/l10n.
  static const _locales = {
    'en_US': 'en',
    'en': 'en',
    'am_ET': 'am',
    'am': 'am',
    'ar_SA': 'ar',
    'ar': 'ar',
    'as_IN': 'as',
    'as': 'as',
    'bn_BD': 'bn',
    'bn': 'bn',
    'hr_HR': 'hr',
    'hr': 'hr',
    'da_DK': 'da',
    'da': 'da',
    'nl_NL': 'nl',
    'nl': 'nl',
    'fil_PH': 'fil',
    'fil': 'fil',
    'fr_FR': 'fr',
    'fr': 'fr',
    'de_DE': 'de',
    'de': 'de',
    'el_GR': 'el',
    'el': 'el',
    'ha_NG': 'ha',
    'ha': 'ha',
    'he_IL': 'he',
    'he': 'he',
    'hi_IN': 'hi',
    'hi': 'hi',
    'id_ID': 'id',
    'id': 'id',
    'it_IT': 'it',
    'it': 'it',
    'ja_JP': 'ja',
    'ja': 'ja',
    'kn_IN': 'kn',
    'kn': 'kn',
    'ko_KR': 'ko',
    'ko': 'ko',
    'ms_MY': 'ms',
    'ms': 'ms',
    'ml_IN': 'ml',
    'ml': 'ml',
    'mr_IN': 'mr',
    'mr': 'mr',
    'ne_NP': 'ne',
    'ne': 'ne',
    'or_IN': 'or',
    'or': 'or',
    'ps_AF': 'ps',
    'ps': 'ps',
    'fa_IR': 'fa',
    'fa': 'fa',
    'pl_PL': 'pl',
    'pl': 'pl',
    'pt_PT': 'pt',
    'pt': 'pt',
    'pt_BR': 'pt_BR',
    'ru_RU': 'ru',
    'ru': 'ru',
    'sa_IN': 'sa',
    'sa': 'sa',
    'zh_CN': 'zh_CN',
    'zh': 'zh_CN',
    'si_LK': 'si',
    'si': 'si',
    'so_SO': 'so',
    'so': 'so',
    'es_ES': 'es',
    'es': 'es',
    'sw_KE': 'sw',
    'sw': 'sw',
    'ta_IN': 'ta',
    'ta': 'ta',
    'te_IN': 'te',
    'te': 'te',
    'th_TH': 'th',
    'th': 'th',
    'zh_TW': 'zh_TW',
    'tr_TR': 'tr',
    'tr': 'tr',
    'uk_UA': 'uk',
    'uk': 'uk',
    'vi_VN': 'vi',
    'vi': 'vi',
  };

  static Map<String, Map<String, String>> _keys = {};

  static Future<void> load() async {
    final files = _locales.values.toSet().toList();
    final maps = await Future.wait(files.map(_read));
    final byFile = Map.fromIterables(files, maps);
    _keys = _locales.map((locale, file) => MapEntry(locale, byFile[file]!));
  }

  static Future<Map<String, String>> _read(String file) async {
    final json = jsonDecode(await rootBundle.loadString('assets/l10n/$file.json'))
        as Map<String, dynamic>;
    // Weblate writes untranslated strings as ""; skip them so GetX falls back
    // to English instead of rendering blank text.
    return {
      for (final e in json.entries)
        if ((e.value as String).isNotEmpty) e.key: e.value as String,
    };
  }

  @override
  Map<String, Map<String, String>> get keys => _keys;
}
