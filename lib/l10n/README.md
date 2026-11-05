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
    ├── zh_tw.dart          # Traditional Chinese (TW/HK)
    ├── pt_br.dart          # Brazilian Portuguese (BR)
    ├── id.dart             # Indonesian (ID)
    └── ui_strings.dart     # English-as-key UI strings for every language
```

---

## Supported Languages

| Language | Code | Native Name | File |
|---|---|---|---|
| English (US) | `en_US` | English | `en.dart` |
| Amharic | `am_ET` | አማርኛ | `am.dart` |
| Arabic | `ar_SA` | العربية | `ar.dart` |
| Assamese | `as_IN` | অসমীয়া | `as.dart` |
| Bengali | `bn_BD` | বাংলা | `bn.dart` |
| Croatian | `hr_HR` | Hrvatski | `hr.dart` |
| Danish | `da_DK` | Dansk | `da.dart` |
| Dutch | `nl_NL` | Nederlands | `nl.dart` |
| Filipino | `fil_PH` | Filipino | `fil.dart` |
| French | `fr_FR` | Français | `fr.dart` |
| German | `de_DE` | Deutsch | `de.dart` |
| Greek | `el_GR` | Ελληνικά | `el.dart` |
| Hausa | `ha_NG` | Hausa | `ha.dart` |
| Hebrew | `he_IL` | עברית | `he.dart` |
| Hindi | `hi_IN` | हिन्दी | `hi.dart` |
| Indonesian | `id_ID` | Bahasa Indonesia | `id.dart` |
| Italian | `it_IT` | Italiano | `it.dart` |
| Japanese | `ja_JP` | 日本語 | `ja.dart` |
| Kannada | `kn_IN` | ಕನ್ನಡ | `kn.dart` |
| Korean | `ko_KR` | 한국어 | `ko.dart` |
| Malay | `ms_MY` | Bahasa Melayu | `ms.dart` |
| Malayalam | `ml_IN` | മലയാളം | `ml.dart` |
| Marathi | `mr_IN` | मराठी | `mr.dart` |
| Nepali | `ne_NP` | नेपाली | `ne.dart` |
| Odia | `or_IN` | ଓଡ଼ିଆ | `or.dart` |
| Pashto | `ps_AF` | پښتو | `ps.dart` |
| Persian | `fa_IR` | فارसी | `fa.dart` |
| Polish | `pl_PL` | Polski | `pl.dart` |
| Portuguese (Portugal) | `pt_PT` | Português | `pt.dart` |
| Portuguese (Brazil) | `pt_BR` | Português (Brasil) | `pt_br.dart` |
| Russian | `ru_RU` | Русский | `ru.dart` |
| Sanskrit | `sa_IN` | संस्कृतम् | `sa.dart` |
| Simplified Chinese | `zh_CN` | 简体中文 | `zh_cn.dart` |
| Sinhala | `si_LK` | සිංහල | `si.dart` |
| Somali | `so_SO` | Soomaali | `so.dart` |
| Spanish | `es_ES` | Español | `es.dart` |
| Swahili | `sw_KE` | Kiswahili | `sw.dart` |
| Tamil | `ta_IN` | தமிழ் | `ta.dart` |
| Telugu | `te_IN` | తెలుగు | `te.dart` |
| Thai | `th_TH` | ไทย | `th.dart` |
| Traditional Chinese | `zh_TW` | 繁體中文 | `zh_tw.dart` |
| Turkish | `tr_TR` | Türkçe | `tr.dart` |
| Ukrainian | `uk_UA` | Українська | `uk.dart` |
| Vietnamese | `vi_VN` | Tiếng Việt | `vi.dart` |
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
`translations/ui_strings.dart` (`esUi`, `deUi`, `zhTWUi`, `ptBRUi`, `idUi`), merged in `app_translations.dart`.
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

Then add a `jaUi` map to `translations/ui_strings.dart`, keyed by the English
text of every UI string (copy the keys from `esUi`). Missing keys fall back to English.

### Step 2: Register in `app_translations.dart`
Add the import and the locale entry in `AppTranslations`:
```dart
import 'translations/ja.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': en,
    'es_ES': {...es, ...esUi},
    'de_DE': {...de, ...deUi},
    'zh_TW': {...zhTW, ...zhTWUi},
    'pt_BR': {...ptBR, ...ptBRUi},
    'id_ID': {...idID, ...idUi},
    'ja_JP': {...ja, ...jaUi}, // <-- Add here
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
