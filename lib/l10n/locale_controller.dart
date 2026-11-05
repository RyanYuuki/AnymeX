import 'dart:ui';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:get/get.dart';

/// Controller for managing the app's locale/language.
///
/// Persists the selected language using Hive (via DataKeys) and
/// updates the GetX locale at runtime.
class LocaleController extends GetxController {
  /// The currently active locale.
  final Rx<Locale> currentLocale = const Locale('en', 'US').obs;

  /// List of supported locales with display names.
  /// Add new entries here when adding a new language.
  static final List<LanguageOption> supportedLanguages = [
    const LanguageOption(
      locale: Locale('en', 'US'),
      name: 'English',
      nativeName: 'English',
    ),
    const LanguageOption(
      locale: Locale('am', 'ET'),
      name: 'Amharic',
      nativeName: 'አማርኛ',
    ),
    const LanguageOption(
      locale: Locale('ar', 'SA'),
      name: 'Arabic',
      nativeName: 'العربية',
    ),
    const LanguageOption(
      locale: Locale('as', 'IN'),
      name: 'Assamese',
      nativeName: 'অসমীয়া',
    ),
    const LanguageOption(
      locale: Locale('bn', 'BD'),
      name: 'Bengali',
      nativeName: 'বাংলা',
    ),
    const LanguageOption(
      locale: Locale('hr', 'HR'),
      name: 'Croatian',
      nativeName: 'Hrvatski',
    ),
    const LanguageOption(
      locale: Locale('da', 'DK'),
      name: 'Danish',
      nativeName: 'Dansk',
    ),
    const LanguageOption(
      locale: Locale('nl', 'NL'),
      name: 'Dutch',
      nativeName: 'Nederlands',
    ),
    const LanguageOption(
      locale: Locale('fil', 'PH'),
      name: 'Filipino',
      nativeName: 'Filipino',
    ),
    const LanguageOption(
      locale: Locale('fr', 'FR'),
      name: 'French',
      nativeName: 'Français',
    ),
    const LanguageOption(
      locale: Locale('de', 'DE'),
      name: 'German',
      nativeName: 'Deutsch',
    ),
    const LanguageOption(
      locale: Locale('el', 'GR'),
      name: 'Greek',
      nativeName: 'Ελληνικά',
    ),
    const LanguageOption(
      locale: Locale('ha', 'NG'),
      name: 'Hausa',
      nativeName: 'Hausa',
    ),
    const LanguageOption(
      locale: Locale('he', 'IL'),
      name: 'Hebrew',
      nativeName: 'עברית',
    ),
    const LanguageOption(
      locale: Locale('hi', 'IN'),
      name: 'Hindi',
      nativeName: 'हिन्दी',
    ),
    const LanguageOption(
      locale: Locale('id', 'ID'),
      name: 'Indonesian',
      nativeName: 'Bahasa Indonesia',
    ),
    const LanguageOption(
      locale: Locale('it', 'IT'),
      name: 'Italian',
      nativeName: 'Italiano',
    ),
    const LanguageOption(
      locale: Locale('ja', 'JP'),
      name: 'Japanese',
      nativeName: '日本語',
    ),
    const LanguageOption(
      locale: Locale('kn', 'IN'),
      name: 'Kannada',
      nativeName: 'ಕನ್ನಡ',
    ),
    const LanguageOption(
      locale: Locale('ko', 'KR'),
      name: 'Korean',
      nativeName: '한국어',
    ),
    const LanguageOption(
      locale: Locale('ms', 'MY'),
      name: 'Malay',
      nativeName: 'Bahasa Melayu',
    ),
    const LanguageOption(
      locale: Locale('ml', 'IN'),
      name: 'Malayalam',
      nativeName: 'മലയാളം',
    ),
    const LanguageOption(
      locale: Locale('mr', 'IN'),
      name: 'Marathi',
      nativeName: 'मराठी',
    ),
    const LanguageOption(
      locale: Locale('ne', 'NP'),
      name: 'Nepali',
      nativeName: 'नेपाली',
    ),
    const LanguageOption(
      locale: Locale('or', 'IN'),
      name: 'Odia',
      nativeName: 'ଓଡ଼ିଆ',
    ),
    const LanguageOption(
      locale: Locale('ps', 'AF'),
      name: 'Pashto',
      nativeName: 'پښتو',
    ),
    const LanguageOption(
      locale: Locale('fa', 'IR'),
      name: 'Persian',
      nativeName: 'فارسی',
    ),
    const LanguageOption(
      locale: Locale('pl', 'PL'),
      name: 'Polish',
      nativeName: 'Polski',
    ),
    const LanguageOption(
      locale: Locale('pt', 'PT'),
      name: 'Portuguese',
      nativeName: 'Português',
    ),
    const LanguageOption(
      locale: Locale('pt', 'BR'),
      name: 'Portuguese (Brazil)',
      nativeName: 'Português (Brasil)',
    ),
    const LanguageOption(
      locale: Locale('ru', 'RU'),
      name: 'Russian',
      nativeName: 'Русский',
    ),
    const LanguageOption(
      locale: Locale('sa', 'IN'),
      name: 'Sanskrit',
      nativeName: 'संस्कृतम्',
    ),
    const LanguageOption(
      locale: Locale('zh', 'CN'),
      name: 'Simplified Chinese',
      nativeName: '简体中文',
    ),
    const LanguageOption(
      locale: Locale('si', 'LK'),
      name: 'Sinhala',
      nativeName: 'සිංහල',
    ),
    const LanguageOption(
      locale: Locale('so', 'SO'),
      name: 'Somali',
      nativeName: 'Soomaali',
    ),
    const LanguageOption(
      locale: Locale('es', 'ES'),
      name: 'Spanish',
      nativeName: 'Español',
    ),
    const LanguageOption(
      locale: Locale('sw', 'KE'),
      name: 'Swahili',
      nativeName: 'Kiswahili',
    ),
    const LanguageOption(
      locale: Locale('ta', 'IN'),
      name: 'Tamil',
      nativeName: 'தமிழ்',
    ),
    const LanguageOption(
      locale: Locale('te', 'IN'),
      name: 'Telugu',
      nativeName: 'తెలుగు',
    ),
    const LanguageOption(
      locale: Locale('th', 'TH'),
      name: 'Thai',
      nativeName: 'ไทย',
    ),
    const LanguageOption(
      locale: Locale('zh', 'TW'),
      name: 'Traditional Chinese',
      nativeName: '繁體中文',
    ),
    const LanguageOption(
      locale: Locale('tr', 'TR'),
      name: 'Turkish',
      nativeName: 'Türkçe',
    ),
    const LanguageOption(
      locale: Locale('uk', 'UA'),
      name: 'Ukrainian',
      nativeName: 'Українська',
    ),
    const LanguageOption(
      locale: Locale('vi', 'VN'),
      name: 'Vietnamese',
      nativeName: 'Tiếng Việt',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _loadSavedLocale();
  }

  /// Loads the previously saved locale from persistent storage.
  void _loadSavedLocale() {
    final savedLangCode = General.appLanguageCode.get<String>('en');
    final savedCountryCode = General.appCountryCode.get<String>('US');
    final locale = Locale(savedLangCode, savedCountryCode);

    // Validate it's a supported locale, fallback to English if not
    final isSupported = supportedLanguages.any((l) =>
        l.locale.languageCode == locale.languageCode &&
        (locale.countryCode == null ||
            locale.countryCode!.isEmpty ||
            l.locale.countryCode == locale.countryCode));
    currentLocale.value = isSupported ? locale : const Locale('en', 'US');
    Get.updateLocale(currentLocale.value);
  }

  /// Changes the app's language at runtime and persists the choice.
  void changeLocale(Locale locale) {
    currentLocale.value = locale;
    Get.updateLocale(locale);
    General.appLanguageCode.set(locale.languageCode);
    General.appCountryCode.set(locale.countryCode ?? '');
  }

  /// Returns the display name for the currently selected language.
  String get currentLanguageName {
    return supportedLanguages
        .firstWhere(
          (l) => l.locale.languageCode == currentLocale.value.languageCode,
          orElse: () => supportedLanguages.first,
        )
        .name;
  }

  /// Returns the native name for the currently selected language.
  String get currentLanguageNativeName {
    return supportedLanguages
        .firstWhere(
          (l) => l.locale.languageCode == currentLocale.value.languageCode,
          orElse: () => supportedLanguages.first,
        )
        .nativeName;
  }
}

/// Represents a selectable language option.
class LanguageOption {
  final Locale locale;
  final String name;
  final String nativeName;

  const LanguageOption({
    required this.locale,
    required this.name,
    required this.nativeName,
  });
}
