import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anymex/utils/logger.dart';

class SubtitleTranslator {
  static final Map<String, String> _cache = {};

  static Future<String> translate(String text, String targetLang) async {
    if (text.isEmpty || targetLang == 'none') {
      return text;
    }
    
    final cacheKey = '$targetLang:$text';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final url = Uri.parse(
          "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}");

      final response = await http.get(url);
    
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        String translated = "";
        
        if (data[0] != null) {
          for (var part in data[0]) {
            translated += part[0].toString();
          }
        }
        
        _cache[cacheKey] = translated;
        return translated;
      } else {
        Logger.e('[SubtitleTranslator] API returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      Logger.e('[SubtitleTranslator] Translation Error: $e');
    }
    return text;
  }

  static const Map<String, String> languages = {
    'am': 'Amharic',
    'ar': 'Arabic',
    'as': 'Assamese',
    'bn': 'Bengali',
    'brx': 'Bodo',
    'my': 'Burmese',
    'zh-CN': 'Chinese (Simplified)',
    'zh-TW': 'Chinese (Traditional)',
    'hr': 'Croatian',
    'cs': 'Czech',
    'da': 'Danish',
    'doi': 'Dogri',
    'nl': 'Dutch',
    'en': 'English',
    'en-US': 'English (US)',
    'fi': 'Finnish',
    'tl': 'Filipino',
    'fr': 'French',
    'de': 'German',
    'el': 'Greek',
    'gu': 'Gujarati',
    'ha': 'Hausa',
    'he': 'Hebrew',
    'hi': 'Hindi',
    'hu': 'Hungarian',
    'ig': 'Igbo',
    'id': 'Indonesian',
    'it': 'Italian',
    'ja': 'Japanese',
    'kn': 'Kannada',
    'ks': 'Kashmiri',
    'kk': 'Kazakh',
    'km': 'Khmer',
    'kok': 'Konkani',
    'ko': 'Korean',
    'lo': 'Lao',
    'es-419': 'Latin American Spanish',
    'lv': 'Latvian',
    'lt': 'Lithuanian',
    'mk': 'Macedonian',
    'ma': 'Maithili',
    'ms': 'Malay',
    'ml': 'Malayalam',
    'mni-Mtei': 'Meitei (Manipuri)',
    'mr': 'Marathi',
    'ne': 'Nepali',
    'no': 'Norwegian',
    'or': 'Odia',
    'fa': 'Persian',
    'pl': 'Polish',
    'pt': 'Portuguese',
    'pt-BR': 'Portuguese (Brazil)',
    'pa': 'Punjabi',
    'qu': 'Quechua',
    'ro': 'Romanian',
    'ru': 'Russian',
    'sa': 'Sanskrit',
    'sat': 'Santali',
    'gd': 'Scottish Gaelic',
    'sr': 'Serbian',
    'si': 'Sinhala',
    'sk': 'Slovak',
    'sl': 'Slovenian',
    'es': 'Spanish',
    'sw': 'Swahili',
    'sv': 'Swedish',
    'ta': 'Tamil',
    'te': 'Telugu',
    'th': 'Thai',
    'tr': 'Turkish',
    'uk': 'Ukrainian',
    'ur': 'Urdu',
    'uz': 'Uzbek',
    'vi': 'Vietnamese',
    'cy': 'Welsh',
    'yo': 'Yoruba',
    'zu': 'Zulu',
  };
}
