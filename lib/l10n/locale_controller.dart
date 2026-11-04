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
      locale: Locale('es', 'ES'),
      name: 'Spanish',
      nativeName: 'Español',
    ),
    const LanguageOption(
      locale: Locale('de', 'DE'),
      name: 'German',
      nativeName: 'Deutsch',
    ),
    const LanguageOption(
      locale: Locale('zh', 'TW'),
      name: 'Traditional Chinese',
      nativeName: '繁體中文',
    ),
    const LanguageOption(
      locale: Locale('pt', 'BR'),
      name: 'Portuguese (Brazil)',
      nativeName: 'Português (Brasil)',
    ),
    const LanguageOption(
      locale: Locale('id', 'ID'),
      name: 'Indonesian',
      nativeName: 'Bahasa Indonesia',
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
