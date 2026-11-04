import 'package:get/get.dart';
import 'translations/en.dart';
import 'translations/es.dart';
import 'translations/de.dart';
import 'translations/zh_tw.dart';
import 'translations/pt_br.dart';
import 'translations/id.dart';
import 'translations/ui_strings.dart';

/// Main translations class for AnymeX.
///
/// Uses GetX's built-in translation system. To add a new language:
/// 1. Create a new file in `lib/l10n/translations/` (e.g., `ja.dart`)
/// 2. Copy the structure from `en.dart` and translate all values
/// 3. Add the import and locale entry in this file's `keys` map
/// 4. Add the `LanguageOption` entry in `lib/l10n/locale_controller.dart`
///
/// Usage in widgets: `'key'.tr` or `LocaleKeys.navHome.tr`
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': en,
        'es_ES': {...es, ...esUi},
        'de_DE': {...de, ...deUi},
        'zh_TW': {...zhTW, ...zhTWUi},
        'pt_BR': {...ptBR, ...ptBRUi},
        'id_ID': {...idID, ...idUi},
      };
}
