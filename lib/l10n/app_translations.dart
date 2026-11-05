import 'package:get/get.dart';
import 'translations/en.dart';
import 'translations/am.dart';
import 'translations/ar.dart';
import 'translations/as.dart';
import 'translations/bn.dart';
import 'translations/hr.dart';
import 'translations/da.dart';
import 'translations/nl.dart';
import 'translations/fil.dart';
import 'translations/fr.dart';
import 'translations/de.dart';
import 'translations/el.dart';
import 'translations/ha.dart';
import 'translations/he.dart';
import 'translations/hi.dart';
import 'translations/id.dart';
import 'translations/it.dart';
import 'translations/ja.dart';
import 'translations/kn.dart';
import 'translations/ko.dart';
import 'translations/ms.dart';
import 'translations/ml.dart';
import 'translations/mr.dart';
import 'translations/ne.dart';
import 'translations/or.dart';
import 'translations/ps.dart';
import 'translations/fa.dart';
import 'translations/pl.dart';
import 'translations/pt.dart';
import 'translations/pt_br.dart';
import 'translations/ru.dart';
import 'translations/sa.dart';
import 'translations/zh_cn.dart';
import 'translations/si.dart';
import 'translations/so.dart';
import 'translations/es.dart';
import 'translations/sw.dart';
import 'translations/ta.dart';
import 'translations/te.dart';
import 'translations/th.dart';
import 'translations/zh_tw.dart';
import 'translations/tr.dart';
import 'translations/uk.dart';
import 'translations/vi.dart';
import 'translations/ui_strings.dart';

/// Main translations class for AnymeX.
///
/// Uses GetX's built-in translation system. To add a new language:
/// 1. Create a new file in lib/l10n/translations/ (e.g., ja.dart)
/// 2. Copy the structure from en.dart and translate all values
/// 3. Add the import and locale entry in this file's keys map
/// 4. Add the LanguageOption entry in lib/l10n/locale_controller.dart
///
/// Usage in widgets: 'key'.tr or LocaleKeys.navHome.tr
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': en,
        'en': en,
        'am_ET': am,
        'am': am,
        'ar_SA': ar,
        'ar': ar,
        'as_IN': asIN,
        'as': asIN,
        'bn_BD': bn,
        'bn': bn,
        'hr_HR': hr,
        'hr': hr,
        'da_DK': da,
        'da': da,
        'nl_NL': nl,
        'nl': nl,
        'fil_PH': fil,
        'fil': fil,
        'fr_FR': fr,
        'fr': fr,
        'de_DE': {...de, ...deUi},
        'de': {...de, ...deUi},
        'el_GR': el,
        'el': el,
        'ha_NG': ha,
        'ha': ha,
        'he_IL': he,
        'he': he,
        'hi_IN': hi,
        'hi': hi,
        'id_ID': {...idID, ...idUi},
        'id': {...idID, ...idUi},
        'it_IT': it,
        'it': it,
        'ja_JP': ja,
        'ja': ja,
        'kn_IN': kn,
        'kn': kn,
        'ko_KR': ko,
        'ko': ko,
        'ms_MY': ms,
        'ms': ms,
        'ml_IN': ml,
        'ml': ml,
        'mr_IN': mr,
        'mr': mr,
        'ne_NP': ne,
        'ne': ne,
        'or_IN': orIN,
        'or': orIN,
        'ps_AF': ps,
        'ps': ps,
        'fa_IR': fa,
        'fa': fa,
        'pl_PL': pl,
        'pl': pl,
        'pt_PT': ptPT,
        'pt': ptPT,
        'pt_BR': {...ptBR, ...ptBRUi},
        'ru_RU': ru,
        'ru': ru,
        'sa_IN': sa,
        'sa': sa,
        'zh_CN': zhCN,
        'zh': zhCN,
        'si_LK': si,
        'si': si,
        'so_SO': so,
        'so': so,
        'es_ES': {...es, ...esUi},
        'es': {...es, ...esUi},
        'sw_KE': sw,
        'sw': sw,
        'ta_IN': ta,
        'ta': ta,
        'te_IN': te,
        'te': te,
        'th_TH': th,
        'th': th,
        'zh_TW': {...zhTW, ...zhTWUi},
        'tr_TR': tr,
        'tr': tr,
        'uk_UA': uk,
        'uk': uk,
        'vi_VN': vi,
        'vi': vi,
      };
}
