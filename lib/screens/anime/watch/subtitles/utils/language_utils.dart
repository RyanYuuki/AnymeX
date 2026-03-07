class LanguageUtils {
  static const Map<String, String> iso1ToIso2B = {
    'en': 'eng', 'es': 'spa', 'pt': 'por', 'fr': 'fre', 'de': 'ger',
    'it': 'ita', 'ru': 'rus', 'ja': 'jpn', 'ko': 'kor', 'zh': 'chi',
    'ar': 'ara', 'hi': 'hin', 'bn': 'ben', 'ta': 'tam', 'te': 'tel',
    'ml': 'mal', 'as': 'asm', 'th': 'tha', 'vi': 'vie', 'id': 'ind',
    'ms': 'may', 'tl': 'tgl', 'ne': 'nep', 'fa': 'per', 'ur': 'urd',
    'pl': 'pol', 'nl': 'dut', 'tr': 'tur', 'el': 'gre', 'he': 'heb',
    'cs': 'cze', 'hu': 'hun', 'ro': 'rum', 'sv': 'swe', 'no': 'nor',
    'da': 'dan', 'fi': 'fin', 'uk': 'ukr', 'bg': 'bul', 'hr': 'hrv',
    'sr': 'srp', 'sk': 'slo', 'sl': 'slv', 'et': 'est', 'lv': 'lav',
    'lt': 'lit', 'sq': 'alb', 'mk': 'mac', 'bs': 'bos', 'ka': 'geo',
    'hy': 'arm', 'az': 'aze', 'kk': 'kaz', 'uz': 'uzb', 'mn': 'mon',
    'km': 'khm', 'lo': 'lao', 'my': 'bur', 'si': 'sin', 'am': 'amh',
    'sw': 'swa', 'af': 'afr', 'cy': 'wel', 'ga': 'gle', 'gd': 'gla',
    'eu': 'baq', 'ca': 'cat', 'gl': 'glg', 'is': 'ice', 'mt': 'mlt',
  };

  static const Map<String, String> iso2ToDisplay = {
    'eng': 'English', 'spa': 'Spanish', 'por': 'Portuguese',
    'pob': 'Portuguese (Brazil)', 'fre': 'French', 'ger': 'German',
    'ita': 'Italian', 'jpn': 'Japanese', 'kor': 'Korean',
    'chi': 'Chinese', 'ara': 'Arabic', 'hin': 'Hindi',
    'ben': 'Bengali', 'tam': 'Tamil', 'tel': 'Telugu',
    'mal': 'Malayalam', 'asm': 'Assamese', 'tha': 'Thai',
    'vie': 'Vietnamese', 'ind': 'Indonesian', 'may': 'Malay',
    'tgl': 'Tagalog', 'nep': 'Nepali', 'per': 'Persian',
    'urd': 'Urdu', 'pol': 'Polish', 'dut': 'Dutch',
    'tur': 'Turkish', 'gre': 'Greek', 'heb': 'Hebrew',
    'cze': 'Czech', 'hun': 'Hungarian', 'rum': 'Romanian',
    'swe': 'Swedish', 'nor': 'Norwegian', 'dan': 'Danish',
    'fin': 'Finnish', 'ukr': 'Ukrainian', 'bul': 'Bulgarian',
    'hrv': 'Croatian', 'srp': 'Serbian', 'slo': 'Slovak',
    'slv': 'Slovenian', 'est': 'Estonian', 'lav': 'Latvian',
    'lit': 'Lithuanian', 'alb': 'Albanian', 'mac': 'Macedonian',
    'bos': 'Bosnian', 'geo': 'Georgian', 'arm': 'Armenian',
    'aze': 'Azerbaijani', 'kaz': 'Kazakh', 'uzb': 'Uzbek',
    'mon': 'Mongolian', 'khm': 'Khmer', 'lao': 'Lao',
    'bur': 'Burmese', 'sin': 'Sinhala', 'amh': 'Amharic',
    'swa': 'Swahili', 'afr': 'Afrikaans', 'wel': 'Welsh',
    'gle': 'Irish', 'gla': 'Scottish Gaelic', 'baq': 'Basque',
    'cat': 'Catalan', 'glg': 'Galician', 'ice': 'Icelandic',
    'mlt': 'Maltese',
  };

  static const Map<String, String> subdlLanguageMap = {
    'eng': 'EN', 'spa': 'ES', 'spn': 'ES', 'fre': 'FR', 'fra': 'FR',
    'ger': 'DE', 'deu': 'DE', 'por': 'PT', 'pob': 'BR_PT',
    'ita': 'IT', 'rus': 'RU', 'jpn': 'JA', 'chi': 'ZH', 'zho': 'ZH',
    'kor': 'KO', 'ara': 'AR', 'dut': 'NL', 'nld': 'NL', 'pol': 'PL',
    'tur': 'TR', 'swe': 'SV', 'nor': 'NO', 'dan': 'DA', 'fin': 'FI',
    'gre': 'EL', 'ell': 'EL', 'heb': 'HE', 'hin': 'HI', 'cze': 'CS',
    'ces': 'CS', 'hun': 'HU', 'rum': 'RO', 'ron': 'RO', 'tha': 'TH',
    'vie': 'VI', 'ind': 'ID', 'ukr': 'UK', 'bul': 'BG', 'hrv': 'HR',
    'srp': 'SR', 'slo': 'SK', 'slk': 'SK', 'slv': 'SL', 'est': 'ET',
    'lav': 'LV', 'lit': 'LT', 'per': 'FA', 'fas': 'FA', 'ben': 'BN',
    'cat': 'CA', 'baq': 'EU', 'eus': 'EU', 'glg': 'GL', 'bos': 'BS',
    'mac': 'MK', 'mkd': 'MK', 'alb': 'SQ', 'sqi': 'SQ', 'bel': 'BE',
    'aze': 'AZ', 'geo': 'KA', 'kat': 'KA', 'mal': 'ML', 'tam': 'TA',
    'tel': 'TE', 'urd': 'UR', 'may': 'MS', 'msa': 'MS', 'tgl': 'TL',
    'ice': 'IS', 'isl': 'IS', 'kur': 'KU',
  };

  static String? toIso6391(String? code) {
    if (code == null) return null;
    
    final lower = code.toLowerCase().trim();
    
    if (lower == 'pob' || lower == 'pt-br' || lower == 'ptbr') return 'pt-br';
    if (lower == 'spn') return 'es';
    if (lower == 'fre' || lower == 'fra') return 'fr';
    if (lower == 'ger' || lower == 'deu') return 'de';
    if (lower == 'dut' || lower == 'nld') return 'nl';
    if (lower == 'cze' || lower == 'ces') return 'cs';
    if (lower == 'rum' || lower == 'ron') return 'ro';
    if (lower == 'slo' || lower == 'slk') return 'sk';
    if (lower == 'per' || lower == 'fas') return 'fa';
    if (lower == 'may' || lower == 'msa') return 'ms';
    if (lower == 'ice' || lower == 'isl') return 'is';
    if (lower == 'baq' || lower == 'eus') return 'eu';
    
    if (lower.length == 3 && iso1ToIso2B.containsValue(lower)) {
      return iso1ToIso2B.entries.firstWhere(
        (e) => e.value == lower,
        orElse: () => const MapEntry('', ''),
      ).key;
    }
    
    if (lower.length == 2 && RegExp(r'^[a-z]{2}$').hasMatch(lower)) {
      return lower;
    }
    
    return null;
  }

  static String normalizeLanguageCode(String? code) {
    if (code == null) return 'und';
    
    final lower = code.toLowerCase().trim();
    
    if (lower == 'pob' || lower == 'ptbr' || lower == 'pt-br') return 'pob';
    if (lower == 'spn' || lower == 'ea') return 'spn';
    if (lower == 'sx') return 'sat';
    if (lower == 'at') return 'ast';
    if (lower == 'ex') return 'ext';
    if (lower == 'ma') return 'mni';
    if (lower == 'ze') return 'ze';
    if (lower == 'me') return 'mne';
    
    if (lower.contains('chinese') && lower.contains('simplified')) return 'zhs';
    if (lower.contains('chinese') && lower.contains('traditional')) return 'zht';
    if (lower == 'zh-cn' || lower == 'zhcn') return 'zhs';
    if (lower == 'zh-tw' || lower == 'zhtw') return 'zht';
    
    if (lower.length == 3 && RegExp(r'^[a-z]{3}$').hasMatch(lower)) {
      return lower;
    }
    
    if (lower.length == 2 && RegExp(r'^[a-z]{2}$').hasMatch(lower)) {
      return iso1ToIso2B[lower] ?? lower;
    }
    
    return 'und';
  }

  static String? toSubDLLanguage(String? code) {
    if (code == null) return null;
    final normalized = normalizeLanguageCode(code);
    return subdlLanguageMap[normalized];
  }

  static String getFlagUrl(String languageCode) {
    final code = languageCode.toLowerCase();
    final iso1 = toIso6391(code) ?? code.substring(0, 2).toLowerCase();
    return 'https://flagcdn.com/w40/${iso1.substring(0, 2)}.png';
  }

  static List<String> getSupportedLanguages() {
    return iso2ToDisplay.keys.toList();
  }

  static String getLanguageDisplay(String code) {
    return iso2ToDisplay[normalizeLanguageCode(code)] ?? code;
  }
}
