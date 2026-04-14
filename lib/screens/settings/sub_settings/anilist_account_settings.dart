import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class AnilistAccountSettings extends StatefulWidget {
  const AnilistAccountSettings({super.key});

  @override
  State<AnilistAccountSettings> createState() => _AnilistAccountSettingsState();
}

class _AnilistAccountSettingsState extends State<AnilistAccountSettings> {
  late final AnilistAuth _auth;

  static const _titleLanguages = [
    'ROMAJI',
    'ENGLISH',
    'NATIVE',
    'ROMAJI_STYLISED',
    'ENGLISH_STYLISED',
    'NATIVE_STYLISED',
  ];
  static const _titleLanguageLabels = [
    'Romaji',
    'English',
    'Native',
    'Romaji (Stylised)',
    'English (Stylised)',
    'Native (Stylised)',
  ];

  static const _staffNameLanguages = [
    'ROMAJI_WESTERN',
    'ROMAJI',
    'NATIVE',
  ];
  static const _staffNameLabels = [
    'Romaji (Western Order)',
    'Romaji',
    'Native',
  ];

  static const _scoreFormats = [
    'POINT_100',
    'POINT_10_DECIMAL',
    'POINT_10',
    'POINT_5',
    'POINT_3',
  ];
  static const _scoreFormatLabels = [
    '100 Point (0–100)',
    '10 Decimal (0.0–10.0)',
    '10 Point (0–10)',
    '5 Star (0–5)',
    '3 Smiley (0–3)',
  ];

  static const _rowOrders = ['score', 'title', 'updatedAt', 'id'];
  static const _rowOrderLabels = ['Score', 'Title', 'Last Updated', 'ID'];

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AnilistAuth>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _auth.fetchAnilistSettings();
    });
  }

  Map<String, dynamic> get s => _auth.anilistUserSettings;

  Future<void> _save(Map<String, dynamic> patch) async {
    final ok = await _auth.saveAnilistSettings(
      titleLanguage: patch['titleLanguage'],
      staffNameLanguage: patch['staffNameLanguage'],
      displayAdultContent: patch['displayAdultContent'],
      airingNotifications: patch['airingNotifications'],
      activityMergeTime: patch['activityMergeTime'],
      rowOrder: patch['rowOrder'],
      scoreFormat: patch['scoreFormat'],
      splitCompletedAnime: patch['splitCompletedAnime'],
      splitCompletedManga: patch['splitCompletedManga'],
      animeCustomLists: patch['animeCustomLists'],
      mangaCustomLists: patch['mangaCustomLists'],
    );
    if (ok) {
      successSnackBar('Settings saved');
    } else {
      errorSnackBar('Failed to save settings');
    }
  }

  void _showOptionDialog<T>({
    required String title,
    required List<T> values,
    required List<String> labels,
    required T current,
    required void Function(T) onSelect,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: AnymexText(text: title, variant: TextVariant.bold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(values.length, (i) {
            final selected = values[i] == current;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.pop(ctx);
                onSelect(values[i]);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: selected
                      ? ctx.colors.primary.withOpacity(0.15)
                      : ctx.colors.surfaceContainerHighest.withOpacity(0.4),
                  border: Border.all(
                    color: selected
                        ? ctx.colors.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AnymexText(
                        text: labels[i],
                        variant: selected ? TextVariant.semiBold : TextVariant.regular,
                        color: selected ? ctx.colors.primary : null,
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_rounded, color: ctx.colors.primary, size: 18),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _showCustomListsDialog(bool isAnime) {
    final key = isAnime ? 'animeCustomLists' : 'mangaCustomLists';
    final lists = List<String>.from(s[key] ?? []);
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          return AlertDialog(
            backgroundColor: ctx.colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: AnymexText(
              text: '${isAnime ? "Anime" : "Manga"} Custom Lists',
              variant: TextVariant.bold,
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          style: TextStyle(color: ctx.colors.onSurface),
                          decoration: InputDecoration(
                            hintText: 'New list name',
                            hintStyle: TextStyle(color: ctx.colors.onSurfaceVariant),
                            filled: true,
                            fillColor: ctx.colors.surfaceContainerHighest.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onSubmitted: (v) {
                            final name = v.trim();
                            if (name.isEmpty || lists.contains(name)) return;
                            setLocal(() => lists.add(name));
                            ctrl.clear();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          final name = ctrl.text.trim();
                          if (name.isEmpty || lists.contains(name)) return;
                          setLocal(() => lists.add(name));
                          ctrl.clear();
                        },
                        icon: Icon(Icons.add_rounded, color: ctx.colors.primary),
                        style: IconButton.styleFrom(
                          backgroundColor: ctx.colors.primary.withOpacity(0.12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (lists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: AnymexText(
                        text: 'No custom lists yet',
                        color: ctx.colors.onSurfaceVariant,
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        itemCount: lists.length,
                        onReorder: (oldIdx, newIdx) {
                          if (newIdx > oldIdx) newIdx--;
                          setLocal(() {
                            final item = lists.removeAt(oldIdx);
                            lists.insert(newIdx, item);
                          });
                        },
                        itemBuilder: (ctx, i) => Container(
                          key: ValueKey(lists[i]),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: ctx.colors.surfaceContainerHighest.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            dense: true,
                            title: AnymexText(text: lists[i]),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded,
                                      color: ctx.colors.error, size: 20),
                                  onPressed: () => setLocal(() => lists.removeAt(i)),
                                ),
                                const Icon(Icons.drag_handle_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ctx.colors.primary,
                  foregroundColor: ctx.colors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _save({key: lists});
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  String _labelFor(List<String> values, List<String> labels, String? current) {
    final idx = values.indexOf(current ?? '');
    return idx >= 0 ? labels[idx] : (current ?? '—');
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 4),
      child: AnymexText(
        text: text.toUpperCase(),
        variant: TextVariant.bold,
        color: context.colors.onSurfaceVariant.withOpacity(0.65),
        size: 11,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            const NestedHeader(title: 'AniList Settings'),
            Expanded(
              child: Obx(() {
                if (_auth.isLoadingSettings.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (s.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(IconlyLight.danger, size: 48,
                            color: context.colors.onSurfaceVariant),
                        const SizedBox(height: 12),
                        AnymexText(text: 'Failed to load settings'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _auth.fetchAnilistSettings,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return ScrollWrapper(
                  comfortPadding: false,
                  customPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  children: [
                    _sectionHeader('Profile'),
                    const SizedBox(height: 8),

                    CustomTile(
                      icon: Icons.translate_rounded,
                      title: 'Title Language',
                      description: _labelFor(_titleLanguages, _titleLanguageLabels, s['titleLanguage']),
                      onTap: () => _showOptionDialog(
                        title: 'Title Language',
                        values: _titleLanguages,
                        labels: _titleLanguageLabels,
                        current: s['titleLanguage'] as String? ?? 'ROMAJI',
                        onSelect: (v) => _save({'titleLanguage': v}),
                      ),
                    ),

                    CustomTile(
                      icon: Icons.person_rounded,
                      title: 'Staff Name Language',
                      description: _labelFor(_staffNameLanguages, _staffNameLabels, s['staffNameLanguage']),
                      onTap: () => _showOptionDialog(
                        title: 'Staff Name Language',
                        values: _staffNameLanguages,
                        labels: _staffNameLabels,
                        current: s['staffNameLanguage'] as String? ?? 'ROMAJI_WESTERN',
                        onSelect: (v) => _save({'staffNameLanguage': v}),
                      ),
                    ),

                    const SizedBox(height: 16),
                    _sectionHeader('List Settings'),
                    const SizedBox(height: 8),

                    CustomTile(
                      icon: Icons.star_rounded,
                      title: 'Score Format',
                      description: _labelFor(_scoreFormats, _scoreFormatLabels, s['scoreFormat']),
                      onTap: () => _showOptionDialog(
                        title: 'Score Format',
                        values: _scoreFormats,
                        labels: _scoreFormatLabels,
                        current: s['scoreFormat'] as String? ?? 'POINT_10',
                        onSelect: (v) => _save({'scoreFormat': v}),
                      ),
                    ),

                    CustomTile(
                      icon: Icons.sort_rounded,
                      title: 'Row Order',
                      description: _labelFor(_rowOrders, _rowOrderLabels, s['rowOrder']),
                      onTap: () => _showOptionDialog(
                        title: 'Row Order',
                        values: _rowOrders,
                        labels: _rowOrderLabels,
                        current: s['rowOrder'] as String? ?? 'score',
                        onSelect: (v) => _save({'rowOrder': v}),
                      ),
                    ),

                    CustomSwitchTile(
                      icon: Icons.view_agenda_rounded,
                      title: 'Split Completed Anime',
                      description: 'Separate completed anime by format',
                      switchValue: s['splitCompletedAnime'] as bool? ?? false,
                      onChanged: (v) => _save({'splitCompletedAnime': v}),
                    ),

                    CustomSwitchTile(
                      icon: Icons.view_agenda_outlined,
                      title: 'Split Completed Manga',
                      description: 'Separate completed manga by format',
                      switchValue: s['splitCompletedManga'] as bool? ?? false,
                      onChanged: (v) => _save({'splitCompletedManga': v}),
                    ),

                    const SizedBox(height: 16),
                    _sectionHeader('Custom Lists'),
                    const SizedBox(height: 8),

                    CustomTile(
                      icon: Icons.list_alt_rounded,
                      title: 'Anime Custom Lists',
                      description: () {
                        final lst = s['animeCustomLists'] as List? ?? [];
                        return lst.isEmpty ? 'No custom lists' : lst.join(', ');
                      }(),
                      onTap: () => _showCustomListsDialog(true),
                    ),

                    CustomTile(
                      icon: Icons.menu_book_rounded,
                      title: 'Manga Custom Lists',
                      description: () {
                        final lst = s['mangaCustomLists'] as List? ?? [];
                        return lst.isEmpty ? 'No custom lists' : lst.join(', ');
                      }(),
                      onTap: () => _showCustomListsDialog(false),
                    ),

                    const SizedBox(height: 16),
                    _sectionHeader('Content'),
                    const SizedBox(height: 8),

                    CustomSwitchTile(
                      icon: Icons.eighteen_up_rating_rounded,
                      title: 'Display Adult Content',
                      description: 'Show 18+ content from AniList',
                      switchValue: s['displayAdultContent'] as bool? ?? false,
                      onChanged: (v) => _save({'displayAdultContent': v}),
                    ),

                    const SizedBox(height: 80),
                  ],
                );
              }),
            ),
          ],
        ),
        floatingActionButton: Obx(() => _auth.isSavingSettings.value
            ? FloatingActionButton.extended(
                onPressed: null,
                icon: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                label: const Text('Saving...'),
              )
            : const SizedBox.shrink()),
      ),
    );
  }
}
