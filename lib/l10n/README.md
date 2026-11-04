# AnymeX Localization (i18n)

AnymeX uses GetX's translation mechanism for localization, with persistent language selection stored via Hive.

---

## Directory Structure

```
lib/l10n/
├── app_translations.dart   # Main GetX Translations class aggregator
├── locale_controller.dart  # Language state management, Hive persistence, & runtime switcher
├── locale_keys.dart        # Type-safe string key constants
├── README.md               # This guide
└── translations/
    ├── en.dart             # English (US) — Base translation map
    ├── es.dart             # Spanish (ES)
    ├── de.dart             # German (DE)
    └── zh_tw.dart          # Traditional Chinese (TW/HK)
```

---

## Supported Languages

| Language | Code | Native Name | File |
|---|---|---|---|
| English (US) | `en_US` | English | `en.dart` |
| Spanish (ES) | `es_ES` | Español | `es.dart` |
| German (DE) | `de_DE` | Deutsch | `de.dart` |
| Traditional Chinese | `zh_TW` | 繁體中文 | `zh_tw.dart` |

---

## How to Use in UI

### 1. Simple Translation
```dart
import 'package:get/get.dart';
import 'package:anymex/l10n/locale_keys.dart';

// Recommended (type-safe):
Text(LocaleKeys.navHome.tr)

// Or using key string directly:
Text('nav_home'.tr)
```

### 2. Parameterized Translation
In your translation file:
```dart
'episode_count': '@count Episodes',
```
In widget:
```dart
Text(LocaleKeys.episodeCount.trParams({'count': '12'}))
```

### 3. English-as-key (most UI strings)
Most screens use the English text itself as the key: `Text('Clear Cache'.tr)`.
English needs no entry (GetX returns the key when missing). Translations live in
`translations/ui_strings.dart` (`esUi`, `deUi`, `zhTWUi`), merged in `app_translations.dart`.
Don't put `.tr` on strings used for logic (map keys, `==` checks); translate at display instead.

---

## How to Add a New Language

### Step 1: Create the translation file
Create `lib/l10n/translations/<lang_code>.dart` (e.g., `ja.dart` for Japanese):
```dart
const Map<String, String> ja = {
  'nav_home': 'ホーム',
  'nav_discover': '見つける',
  'nav_search': '検索',
  // ... copy keys from en.dart and translate
};
```

### Step 2: Register in `app_translations.dart`
Add the import and the locale entry in `AppTranslations`:
```dart
import 'translations/ja.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': en,
    'es_ES': es,
    'de_DE': de,
    'zh_TW': zhTW,
    'ja_JP': ja, // <-- Add here
  };
}
```

### Step 3: Register in `locale_controller.dart`
Add the language option to `supportedLanguages`:
```dart
    const LanguageOption(
      locale: Locale('ja', 'JP'),
      name: 'Japanese',
      nativeName: '日本語',
    ),
```

The language will automatically appear in **Settings > Common Settings > App Language** and update the UI across mobile and desktop layouts in real-time.
