String completeLanguageName(String lang) {
  lang = lang.toLowerCase();
  for (var element in sortedLanguagesMap.entries) {
    if (element.value.toLowerCase() == lang) {
      return element.key;
    }
  }
  return lang.toUpperCase();
}

String completeLanguageCode(String lang) {
  lang = lang.toLowerCase();
  for (var element in sortedLanguagesMap.entries) {
    if (element.key.toLowerCase() == lang) {
      return element.value;
    }
  }
  return lang.toUpperCase();
}

final sortedLanguagesMap = {
  "all": "All",
  "Afrikaans": "af",
  "አማርኛ": "am",
  "العربية": "ar",
  "অসমীয়া": "as",
  "Azərbaycan": "az",
  "беларуская": "be",
  "български": "bg",
  "বাংলা": "bn",
  "bosanski": "bs",
  "Català": "ca",
  "Cebuano": "ceb",
  "čeština": "cs",
  "dansk": "da",
  "Deutsch": "de",
  "Ελληνικά": "el",
  "English": "en",
  "English (United States)": "en-us",
  "Esperanto": "eo",
  "Español": "es",
  "Español (Latinoamérica)": "es-419",
  "Estonian": "et",
  "euskara": "eu",
  "فارسی": "fa",
  "Filipino": "fil",
  "suomi": "fi",
  "Faroese": "fo",
  "Français": "fr",
  "Irish": "ga",
  "Guarani": "gn",
  "Gujarati": "gu",
  "Hausa": "ha",
  "עברית": "he",
  "हिन्दी, हिंदी": "hi",
  "Hrvatski": "hr",
  "Haitian Creole": "ht",
  "Magyar": "hu",
  "Armenian": "hy",
  "Indonesia": "id",
  "Igbo": "ig",
  "Icelandic": "is",
  "Italiano": "it",
  "日本語": "ja",
  "Javanese": "jv",
  "Georgian": "ka",
  "Kazakh": "kk",
  "Cambodian": "km",
  "Kannada": "kn",
  "한국어": "ko",
  "Kurdî": "ku",
  "Kyrgyz": "ky",
  "Latin": "la",
  "Luxembourgish": "lb",
  "Laothian": "lo",
  "lietuvių kalba": "lt",
  "Latvian": "lv",
  "Malagasy": "mg",
  "Maori": "mi",
  "Macedonian": "mk",
  "മലയാളം": "ml",
  "Монгол": "mn",
  "Marathi": "mr",
  "Malaysia": "ms",
  "Maltese": "mt",
  "ဗမာစာ": "my",
  "Norwegian Bokmål (Norway)": "nb-no",
  "Nepali": "ne",
  "Nederlands": "nl",
  "Norsk": "no",
  "Nyanja": "ny",
  "Polski": "pl",
  "Pashto": "ps",
  "Português": "pt",
  "Português (Brasil)": "pt-br",
  "Portuguese (Portugal)": "pt-pt",
  "Romansh": "rm",
  "Română": "ro",
  "Pусский язык": "ru",
  "Sindhi": "sd",
  "srpskohrvatski": "sh",
  "Sinhalese": "si",
  "Slovak": "sk",
  "Slovenian": "sl",
  "Samoan": "sm",
  "Shona": "sn",
  "Somali": "so",
  "Albanian": "sq",
  "Serbian": "sr",
  "Sesotho": "st",
  "svenska": "sv",
  "Swahili": "sw",
  "Tamil": "ta",
  "Telugu": "te",
  "Tajik": "tg",
  "ไทย": "th",
  "Tigrinya": "ti",
  "Tagalog": "tl",
  "Turkmen": "tk",
  "Tonga": "to",
  "Türkçe": "tr",
  "Tatar": "tt",
  "Українська": "uk",
  "Urdu": "ur",
  "Uzbek": "uz",
  "Tiếng Việt": "vi",
  "isiXhosa": "xh",
  "Yoruba": "yo",
  "中文(Zhōngwén)": "zh",
  "繁體中文(Hong Kong)": "zh-hk",
  "Chinese (Traditional)": "zh-tw",
  "isiZulu": "zu",
};

final subtitleLangMap = {
  "English": "eng",
  "German": "ger",
  "French": "fre",
  "Spanish": "spa",
  "Italian": "ita",
  "Japanese": "jpn",
  "Chinese": "chi",
  "Korean": "kor",
  "Portuguese": "por",
  "Russian": "rus",
  "Arabic": "ara",
  "Hindi": "hin",
  "Bengali": "ben",
  "Polish": "pol",
  "Turkish": "tur",
  "Vietnamese": "vie",
  "Thai": "tha",
  "Czech": "cze",
  "Dutch": "dut",
  "Greek": "gre",
  "Hebrew": "heb",
  "Hungarian": "hun",
  "Indonesian": "ind",
  "Malay": "may",
  "Romanian": "rum",
  "Slovak": "slo",
  "Swedish": "swe",
  "Tamil": "tam",
  "Telugu": "tel",
  "Ukrainian": "ukr",
  "Urdu": "urd",
  "Unknown": "und", // fallback
};

String completeSubtitleLanguageName(String code) {
  code = code.toLowerCase();
  for (var entry in subtitleLangMap.entries) {
    if (entry.value.toLowerCase() == code) {
      return entry.key;
    }
  }
  return code.toUpperCase(); // fallback
}
