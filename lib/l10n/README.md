# AnymeX Localization (i18n)

AnymeX uses GetX's translation mechanism for localization, with persistent language selection stored via Hive. Translations are flat JSON files managed through [Weblate](https://weblate.org).

---

## Directory Structure

```
assets/l10n/
├── en.json                 # English (US) — source strings for Weblate
└── <code>.json             # One file per language (fr.json, pt_BR.json, ...)

lib/l10n/
├── app_translations.dart   # Loads the JSON assets; maps GetX locales to files
├── locale_controller.dart  # Language state management, Hive persistence, & runtime switcher
├── locale_keys.dart        # Type-safe string key constants
└── README.md               # This guide
```

---

## Weblate Setup

Weblate settings live on the server, not in this repo. Create a component with:

| Setting | Value |
|---|---|
| File format | JSON file |
| File mask | `assets/l10n/*.json` |
| Monolingual base language file | `assets/l10n/en.json` |
| Template for new translations | *(empty)* |
| Source language | English |
| Version control system | GitHub pull requests |

Install the **Cleanup translation files** add-on so strings removed from `en.json` disappear from every language.

To translate, use Weblate rather than editing language files by hand; direct edits can conflict with Weblate's pending changes. `en.json` is the exception: edit it in the repo.

---

## Supported Languages

| Language | Code | Native Name |
|---|---|---|
| English (US) | `en_US` | English |
| Amharic | `am_ET` | አማርኛ |
| Arabic | `ar_SA` | العربية |
| Assamese | `as_IN` | অসমীয়া |
| Bengali | `bn_BD` | বাংলা |
| Croatian | `hr_HR` | Hrvatski |
| Danish | `da_DK` | Dansk |
| Dutch | `nl_NL` | Nederlands |
| Filipino | `fil_PH` | Filipino |
| French | `fr_FR` | Français |
| German | `de_DE` | Deutsch |
| Greek | `el_GR` | Ελληνικά |
| Hausa | `ha_NG` | Hausa |
| Hebrew | `he_IL` | עברית |
| Hindi | `hi_IN` | हिन्दी |
| Indonesian | `id_ID` | Bahasa Indonesia |
| Italian | `it_IT` | Italiano |
| Japanese | `ja_JP` | 日本語 |
| Kannada | `kn_IN` | ಕನ್ನಡ |
| Korean | `ko_KR` | 한국어 |
| Malay | `ms_MY` | Bahasa Melayu |
| Malayalam | `ml_IN` | മലയാളം |
| Marathi | `mr_IN` | मराठी |
| Nepali | `ne_NP` | नेपाली |
| Odia | `or_IN` | ଓଡ଼ିଆ |
| Pashto | `ps_AF` | پښتو |
| Persian | `fa_IR` | فارसी |
| Polish | `pl_PL` | Polski |
| Portuguese (Portugal) | `pt_PT` | Português |
| Portuguese (Brazil) | `pt_BR` | Português (Brasil) |
| Russian | `ru_RU` | Русский |
| Sanskrit | `sa_IN` | संस्कृतम् |
| Simplified Chinese | `zh_CN` | 简体中文 |
| Sinhala | `si_LK` | සිංහල |
| Somali | `so_SO` | Soomaali |
| Spanish | `es_ES` | Español |
| Swahili | `sw_KE` | Kiswahili |
| Tamil | `ta_IN` | தமிழ் |
| Telugu | `te_IN` | తెలుగు |
| Thai | `th_TH` | ไทย |
| Traditional Chinese | `zh_TW` | 繁體中文 |
| Turkish | `tr_TR` | Türkçe |
| Ukrainian | `uk_UA` | Українська |
| Vietnamese | `vi_VN` | Tiếng Việt |
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
In `assets/l10n/en.json`:
```json
"episode_count": "@count Episodes"
```
In widget:
```dart
Text(LocaleKeys.episodeCount.trParams({'count': '12'}))
```

### 3. English-as-key (most UI strings)
Most screens use the English text itself as the key: `Text('Clear Cache'.tr)`.
No other step needed: on every push to `main`, `.github/workflows/sync_l10n.yml` runs `tool/sync_l10n.py`, which adds new `.tr` literals to `assets/l10n/en.json` for Weblate.
It also collects the plain strings in `settings_registry.dart`. Don't add `.tr` there: those strings form stable IDs and route lookups, and `settings.dart` translates them at display.
It can't see other `variable.tr` uses, so add those strings to `en.json` by hand. Interpolated strings (`'Hi $name'.tr`) can't be translated: use `'Hi @name'.trParams({'name': name})`; CI warns about them.
GetX shows the key itself until a translation exists.
Don't put `.tr` on strings used for logic (map keys, `==` checks); translate at display instead.

---

## How to Add a New Language

### Step 1: Create the translation file
Start the language in Weblate; it commits `assets/l10n/<code>.json`. Missing or blank strings fall back to English.

### Step 2: Register in `app_translations.dart`
Add the locale entries to `_locales`:
```dart
    'ja_JP': 'ja',
    'ja': 'ja',
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
