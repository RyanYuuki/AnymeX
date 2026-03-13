import 'package:anymex/screens/anime/widgets/list_editor_theme.dart';
import 'package:anymex/screens/anime/widgets/list_editor_themes/compact.dart';
import 'package:anymex/screens/anime/widgets/list_editor_themes/violet_nebula.dart';

class ListEditorThemeRegistry {
  static final List<ListEditorThemeSpec> themes = [
    compactListEditorTheme,
    violetNebulaListEditorTheme,
  ];

  static ListEditorThemeSpec byId(String? id) {
    if (id == null) return themes.first;
    return themes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => themes.first,
    );
  }

  static String normalizeId(String? id) => byId(id).id;
}