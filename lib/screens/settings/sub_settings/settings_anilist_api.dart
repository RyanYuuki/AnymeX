import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/models/Anilist/anilist_user_settings.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/al_about_me.dart';
import 'package:anymex/utils/markdown.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_icon_wrapper.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const _titleLanguageLabels = <String, String>{
  'ROMAJI': 'Romaji (Shingeki no Kyojin)',
  'ENGLISH': 'English (Attack on Titan)',
  'NATIVE': 'Native (進撃の巨人)',
};
const _staffNameLanguageLabels = <String, String>{
  'ROMAJI_WESTERN': 'Romaji, Western Order (Killua Zoldyck)',
  'ROMAJI': 'Romaji (Zoldyck Killua)',
  'NATIVE': 'Native (キルア=ゾルディック)',
};
const _scoreFormatLabels = <String, String>{
  'POINT_100': '100 Point (55/100)',
  'POINT_10_DECIMAL': '10 Point Decimal (5.5/10)',
  'POINT_10': '10 Point (5/10)',
  'POINT_5': '5 Star (3/5)',
  'POINT_3': '3 Point Smiley :)',
};
const _rowOrderLabels = <String, String>{
  'score': 'Score', 'title': 'Title',
  'updatedAt': 'Last Updated', 'id': 'Last Added',
};
const _activityMergeLabels = <int, String>{
  360: '6 Hours', 720: '12 Hours', 1440: '1 Day', 2880: '2 Days',
  4320: '3 Days', 10080: '1 Week', 20160: '2 Weeks', 29160: 'Always',
};

final _fallbackTitleLanguageValues = _titleLanguageLabels.keys.toList();
final _fallbackStaffNameLanguageValues = _staffNameLanguageLabels.keys.toList();
final _fallbackScoreFormatValues = _scoreFormatLabels.keys.toList();
final _rowOrderValues = _rowOrderLabels.keys.toList();
final _activityMergeTimeValues = _activityMergeLabels.keys.toList();

String _pretty(String raw) => raw
    .split('_')
    .where((p) => p.isNotEmpty)
    .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
    .join(' ');

String _activityMergeLabel(int m) => _activityMergeLabels[m] ?? '$m minutes';
String _titleLanguageLabel(String v) => _titleLanguageLabels[v] ?? _pretty(v);
String _staffNameLanguageLabel(String v) => _staffNameLanguageLabels[v] ?? _pretty(v);
String _scoreFormatLabel(String v) => _scoreFormatLabels[v] ?? _pretty(v);
String _rowOrderLabel(String v) => _rowOrderLabels[v] ?? _pretty(v);

const _animeBaseSectionOrder = ['Watching', 'Planning', 'Completed', 'Dropped', 'Paused', 'Rewatching'];
const _mangaBaseSectionOrder = ['Reading', 'Planning', 'Completed', 'Dropped', 'Paused', 'Rereading'];
const _fallbackAnimeCompletedSplitSections = [
  'Completed TV', 'Completed Movie', 'Completed OVA', 'Completed ONA',
  'Completed TV Short', 'Completed Special', 'Completed Music',
];
const _fallbackMangaCompletedSplitSections = [
  'Completed Manga', 'Completed Novel', 'Completed One Shot',
];
const _animeCompletedFormats = ['TV', 'MOVIE', 'OVA', 'ONA', 'TV_SHORT', 'SPECIAL', 'MUSIC'];
const _mangaCompletedFormats = ['MANGA', 'NOVEL', 'ONE_SHOT'];

const _legacyTimezoneMap = <String, String>{
  'Etc/UTC': '00:00', 'UTC': '00:00', 'Asia/Kolkata': '05:30', 'Asia/Tokyo': '09:00',
  'Asia/Seoul': '09:00', 'Asia/Shanghai': '08:00', 'Asia/Bangkok': '07:00',
  'Asia/Singapore': '08:00', 'Asia/Dubai': '04:00', 'Europe/London': '00:00',
  'Europe/Paris': '01:00', 'Europe/Berlin': '01:00', 'Europe/Moscow': '03:00',
  'America/New_York': '-05:00', 'America/Chicago': '-06:00',
  'America/Denver': '-07:00', 'America/Los_Angeles': '-08:00',
  'America/Toronto': '-05:00', 'America/Sao_Paulo': '-03:00',
  'Australia/Sydney': '11:00', 'Australia/Melbourne': '11:00',
  'Pacific/Auckland': '13:00',
  'Asia/Hong_Kong': '08:00', 'Asia/Manila': '08:00', 'Asia/Taipei': '08:00',
  'Asia/Jakarta': '07:00', 'Asia/Kuala_Lumpur': '08:00', 'Asia/Karachi': '05:00',
  'Asia/Dhaka': '06:00', 'Europe/Rome': '01:00', 'Europe/Madrid': '01:00',
  'Europe/Athens': '02:00', 'Europe/Istanbul': '03:00', 'America/Mexico_City': '-06:00',
  'America/Bogota': '-05:00', 'America/Argentina/Buenos_Aires': '-03:00',
  'America/Phoenix': '-07:00', 'Australia/Brisbane': '10:00', 'Australia/Perth': '08:00',
  'Pacific/Honolulu': '-10:00',
};

String _normalizeTimezoneValue(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) {
    final minutes = DateTime.now().timeZoneOffset.inMinutes;
    final sign = minutes < 0 ? '-' : '';
    final abs = minutes.abs();
    return '$sign${(abs ~/ 60).toString().padLeft(2, '0')}:${(abs % 60).toString().padLeft(2, '0')}';
  }
  
  if (raw.startsWith('Etc/GMT') || raw.startsWith('GMT')) {
    final signMatch = RegExp(r'GMT([+-]?)(\d+)').firstMatch(raw);
    if (signMatch != null) {
      final sign = signMatch.group(1) ?? '';
      final hours = int.tryParse(signMatch.group(2) ?? '0') ?? 0;
      final offsetSign = (sign == '-') ? '' : '-';
      return '$offsetSign${hours.toString().padLeft(2, '0')}:00';
    }
  }

  final converted = _legacyTimezoneMap[raw] ?? raw;
  final normalized = converted.startsWith('+') ? converted.substring(1) : converted;
  return RegExp(r'^-?\d{2}:\d{2}$').hasMatch(normalized) ? normalized : '00:00';
}

String _timezoneLabel(String value) {
  final names = <String>[];
  for (final entry in _legacyTimezoneMap.entries) {
    if (entry.value == value) {
      final parts = entry.key.split('/');
      names.add(parts.last.replaceAll('_', ' '));
    }
  }

  final sign = value.startsWith('-') ? '' : '+';
  final offsetLabel = '(GMT$sign$value)';
  
  if (names.isNotEmpty) {
    final namesStr = names.take(2).join(', ');
    return '$namesStr $offsetLabel';
  }
  return offsetLabel;
}

String _formatOffset(int minutes) {
  final sign = minutes < 0 ? '-' : '';
  final abs = minutes.abs();
  return '$sign${(abs ~/ 60).toString().padLeft(2, '0')}:${(abs % 60).toString().padLeft(2, '0')}';
}

List<String> _buildTimezoneOffsets() {
  final offsets = <int>{
    for (var m = -12 * 60; m <= 14 * 60; m += 30) m,
    -570, -210, 345, 525, 765,
  }.toList()..sort();
  return offsets.map(_formatOffset).toList(growable: false);
}

bool _hasAnySection(List<String> sectionOrder, List<String> candidates) {
  final current = sectionOrder.map((e) => e.trim().toLowerCase()).toSet();
  return candidates.any((v) => current.contains(v.toLowerCase()));
}

List<String> _buildCompletedSectionsFromMediaFormats(
  List<String> allMediaFormats, {required bool anime}) {
  final preferred = anime ? _animeCompletedFormats : _mangaCompletedFormats;
  final available = allMediaFormats.toSet();
  final sections = [for (final f in preferred) if (available.contains(f)) 'Completed ${_pretty(f)}'];
  if (sections.isNotEmpty) return sections;
  return anime ? _fallbackAnimeCompletedSplitSections : _fallbackMangaCompletedSplitSections;
}

List<String> _sectionOrderOptions({
  required List<String> base,
  required List<String> splitCompletedSections,
  required bool splitCompleted,
}) => [base.first, base[1], if (splitCompleted) ...splitCompletedSections else 'Completed', ...base.skip(3)];

List<String> _normalizeSectionOrder(List<String> source, List<String> allowedValues) {
  final allowedByKey = {for (final v in allowedValues) v.toLowerCase(): v};
  final seen = <String>{};
  final ordered = <String>[];
  for (final item in source) {
    final canonical = allowedByKey[item.trim().toLowerCase()];
    if (canonical == null || !seen.add(canonical)) continue;
    ordered.add(canonical);
  }
  for (final v in allowedValues) {
    if (seen.add(v)) ordered.add(v);
  }
  return ordered;
}


class SettingsAnilistApi extends StatefulWidget {
  const SettingsAnilistApi({super.key});

  @override
  State<SettingsAnilistApi> createState() => _SettingsAnilistApiState();
}

class _SettingsAnilistApiState extends State<SettingsAnilistApi> {
  final _auth = Get.find<AnilistAuth>();
  final _aboutController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _aboutPreview = false;
  bool _aboutEditorExpanded = false;
  bool _aboutPreviewExpanded = true;
  String? _error;
  AnilistUserSettings? _settings;

  List<String> _titleLanguageValues = List.from(_fallbackTitleLanguageValues);
  List<String> _staffNameLanguageValues = List.from(_fallbackStaffNameLanguageValues);
  List<String> _scoreFormatValues = List.from(_fallbackScoreFormatValues);
  List<String> _animeCompletedSplitSections = List.from(_fallbackAnimeCompletedSplitSections);
  List<String> _mangaCompletedSplitSections = List.from(_fallbackMangaCompletedSplitSections);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final cached = _auth.cachedSettings;
    final cachedMeta = _auth.cachedMetadata;
    if (cached != null) {
      _applySettings(cached, cachedMeta);
    } else {
      setState(() { _loading = true; _error = null; });
    }
    try {
      final fetched = await _auth.fetchUserSettings();
      final metadata = await _auth.fetchSettingsMetadata();
      if (fetched == null && cached == null) {
        setState(() { _error = 'Unable to load AniList settings.'; _loading = false; });
        return;
      }
      if (fetched != null) {
        _auth.cachedSettings = fetched;
        _auth.cachedMetadata = metadata;
        _applySettings(fetched, metadata);
      }
    } catch (e) {
      if (_settings == null) {
        setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
      }
    }
  }

  void _applySettings(AnilistUserSettings fetched, AnilistSettingsMetadata? metadata) {
    _aboutController.text = fetched.about ?? '';
    final meta = metadata ?? const AnilistSettingsMetadata(
      titleLanguageValues: [], staffNameLanguageValues: [],
      scoreFormatValues: [], mediaFormatValues: [],
    );
    final mediaFormats = List<String>.from(meta.mediaFormatValues);
    final animeSplit = _buildCompletedSectionsFromMediaFormats(mediaFormats, anime: true);
    final mangaSplit = _buildCompletedSectionsFromMediaFormats(mediaFormats, anime: false);
    setState(() {
      _settings = fetched.copyWith(
        splitCompletedAnime: fetched.splitCompletedAnime ||
            _hasAnySection(fetched.animeSectionOrder, animeSplit),
        splitCompletedManga: fetched.splitCompletedManga ||
            _hasAnySection(fetched.mangaSectionOrder, mangaSplit),
      );
      _titleLanguageValues = meta.titleLanguageValues.isEmpty
          ? List.from(_fallbackTitleLanguageValues)
          : List.from(meta.titleLanguageValues.where((v) => !v.contains('STYLISED')));
      _staffNameLanguageValues = meta.staffNameLanguageValues.isEmpty
          ? List.from(_fallbackStaffNameLanguageValues)
          : List.from(meta.staffNameLanguageValues);
      _scoreFormatValues = meta.scoreFormatValues.isEmpty
          ? List.from(_fallbackScoreFormatValues)
          : List.from(meta.scoreFormatValues);
      _animeCompletedSplitSections = animeSplit;
      _mangaCompletedSplitSections = mangaSplit;
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    final current = _settings;
    if (current == null || _saving) return;
    final updated = current.copyWith(
      about: _aboutController.text.trim().isEmpty ? null : _aboutController.text.trim(),
      timezone: (current.timezone ?? '').trim().isEmpty ? null : current.timezone!.trim(),
    );
    setState(() { _saving = true; _error = null; });
    try {
      final saved = await _auth.updateUserSettings(updated);
      setState(() { _settings = saved ?? updated; _saving = false; });
      final anilistData = Get.find<AnilistData>();
      anilistData.fetchAnilistHomepage();
      anilistData.fetchAnilistMangaPage();
      _auth.fetchUserAnimeList();
      _auth.fetchUserMangaList();
      if (mounted) snackBar('Settings saved successfully.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      setState(() { _saving = false; _error = e.toString().replaceFirst('Exception: ', ''); });
      if (mounted) snackBar(_error ?? 'Failed to save.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _update(void Function(AnilistUserSettings s) updater) {
    final s = _settings;
    if (s == null) return;
    updater(s);
    setState(() {});
  }

  // About

  void _insertAboutText(String text) {
    final sel = _aboutController.selection;
    final val = _aboutController.text;
    final start = sel.isValid ? sel.start : val.length;
    final end = sel.isValid ? sel.end : val.length;
    _aboutController.value = TextEditingValue(
      text: val.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length),
    );
  }

  void _wrapAboutSelection({required String prefix, required String suffix, String placeholder = 'text'}) {
    final sel = _aboutController.selection;
    final val = _aboutController.text;
    final hasSel = sel.isValid && sel.start != sel.end;
    final start = sel.isValid ? sel.start : val.length;
    final end = sel.isValid ? sel.end : val.length;
    final selected = hasSel ? val.substring(start, end) : placeholder;
    final wrapped = '$prefix$selected$suffix';
    _aboutController.value = TextEditingValue(
      text: val.replaceRange(start, end, wrapped),
      selection: hasSel
          ? TextSelection(baseOffset: start, extentOffset: start + wrapped.length)
          : TextSelection(baseOffset: start + prefix.length, extentOffset: start + prefix.length + selected.length),
    );
  }

  String _previewAbout(String input) {
    var text = input;
    final hasMarkdown = RegExp(
      r'(^|\n)\s*(#{1,6}\s|>\s|(?:\*|-|\d+\.)\s|```|~~|\*\*|__|' r'\[[^\]]+\]\(|!\[[^\]]*\]\(|(?:_{3,}|-{3,}|\*{3,})\s*$)',
      multiLine: true,
    ).hasMatch(text);
    if (hasMarkdown) text = parseMarkdown(text);
    return text.replaceAllMapped(
      RegExp(r'''(?<!["\\'>])(https?://(?:www\.)?anilist\.co/(?:anime|manga)/\d+(?:/[^\s<]*)?)''', caseSensitive: false),
      (m) { final url = m[1] ?? ''; return '<a href="$url">$url</a>'; },
    );
  }

  // pickers

  Future<void> _showOptionPicker<T>({
    required String title,
    required List<T> items,
    required T value,
    required String Function(T) itemLabel,
    required ValueChanged<T> onChanged,
  }) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        final maxH = MediaQuery.of(sheetCtx).size.height * 0.72;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 44, height: 4, margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: context.colors.outline.opaque(0.45), borderRadius: BorderRadius.circular(999))),
              Align(alignment: Alignment.centerLeft,
                child: Text(title, style: TextStyle(color: context.colors.onSurface, fontSize: 17, fontWeight: FontWeight.w700))),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: (maxH - 90).clamp(120.0, 560.0)),
                child: ListView.separated(
                  shrinkWrap: true, primary: false, itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    final sel = item == value;
                    return Material(
                      color: sel ? context.colors.primary.opaque(0.16) : context.colors.surfaceContainer.opaque(0.72),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(sheetCtx, item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          child: Row(children: [
                            Expanded(child: Text(itemLabel(item),
                              style: TextStyle(color: context.colors.onSurface, fontSize: 15,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w500))),
                            Icon(sel ? Icons.check_circle_rounded : Icons.circle_outlined, size: 19,
                              color: sel ? context.colors.primary : context.colors.onSurface.opaque(0.5)),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }

  Future<void> _editSectionOrder({
    required String title,
    required List<String> current,
    required List<String> allowedValues,
    required ValueChanged<List<String>> onApply,
  }) async {
    var order = _normalizeSectionOrder(current, allowedValues);
    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: context.colors.surface,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: Text('$title Section Order', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                TextButton(onPressed: () { onApply(order); Navigator.pop(context); }, child: const Text('Done')),
              ]),
              const SizedBox(height: 8),
              Text('Drag to reorder status sections',
                style: TextStyle(fontSize: 13, color: context.colors.onSurface.opaque(0.65))),
              const SizedBox(height: 12),
              SizedBox(
                height: 340,
                child: ReorderableListView.builder(
                  itemCount: order.length,
                  onReorder: (old, neu) {
                    if (neu > old) neu -= 1;
                    final next = List<String>.from(order);
                    next.insert(neu, next.removeAt(old));
                    setModalState(() => order = next);
                  },
                  itemBuilder: (_, i) => Card(
                    key: ValueKey('section-${order[i]}'),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(leading: const Icon(Icons.drag_indicator_rounded), title: Text(_pretty(order[i]))),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _editCustomLists({
    required String title,
    required List<String> current,
    required ValueChanged<List<String>> onApply,
  }) async {
    var local = List<String>.from(current);
    final inputController = TextEditingController();
    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          void addItem() {
            final next = inputController.text.trim();
            if (next.isEmpty || local.any((i) => i.toLowerCase() == next.toLowerCase())) {
              inputController.clear(); return;
            }
            setModalState(() => local = [...local, next]);
            inputController.clear();
          }
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 10,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 14),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 44, height: 4, margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: context.colors.outline.opaque(0.45), borderRadius: BorderRadius.circular(999))),
                Row(children: [
                  Expanded(child: Text(title, style: TextStyle(color: context.colors.onSurface, fontSize: 18, fontWeight: FontWeight.w700))),
                  TextButton(onPressed: () { onApply(local); Navigator.pop(sheetContext); }, child: const Text('Done')),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(
                    controller: inputController, onSubmitted: (_) => addItem(),
                    decoration: InputDecoration(
                      hintText: 'New custom list name', filled: true,
                      fillColor: context.colors.surfaceContainer.opaque(0.72),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.colors.outline.opaque(0.25))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.colors.primary.opaque(0.75), width: 1.25)),
                    ),
                  )),
                  const SizedBox(width: 10),
                  FilledButton(onPressed: addItem,
                    style: FilledButton.styleFrom(minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: EdgeInsets.zero),
                    child: const Icon(Icons.add_rounded)),
                ]),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.48),
                  child: local.isEmpty
                      ? Container(width: double.infinity, padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: context.colors.surfaceContainer.opaque(0.6), borderRadius: BorderRadius.circular(14)),
                          child: Text('No custom lists yet.', style: TextStyle(color: context.colors.onSurface.opaque(0.65))))
                      : ListView.separated(
                          shrinkWrap: true, itemCount: local.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, index) => Material(
                            color: context.colors.surfaceContainer.opaque(0.72),
                            borderRadius: BorderRadius.circular(14),
                            child: ListTile(dense: true, title: Text(local[index]),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline_rounded, color: context.colors.error),
                                onPressed: () => setModalState(() { local = List.from(local)..removeAt(index); }),
                              )),
                          ),
                        ),
                ),
              ]),
            ),
          );
        },
      ),
    );
    inputController.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
  body: Column(children: [
          const NestedHeader(title: 'Anilist Settings'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _settings == null
                    ? _buildError()
                    : ScrollWrapper(
                        comfortPadding: false,
                        customPadding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
                        children: [
                          if (_error != null) _buildInlineError(),
                          _buildGeneralSection(),
                          _buildListSection(),
                          _buildOtherSection(),
                          _buildSaveButton(),
                        ],
                      ),
          ),
        ])
);
  }

  // Sections

  Widget _buildGeneralSection() {
    final s = _settings!;
    final titleValues = _titleLanguageValues.contains(s.titleLanguage)
        ? _titleLanguageValues : <String>[..._titleLanguageValues, s.titleLanguage];
    final staffValues = _staffNameLanguageValues.contains(s.staffNameLanguage)
        ? _staffNameLanguageValues : <String>[..._staffNameLanguageValues, s.staffNameLanguage];
    final mergeValues = <int>[..._activityMergeTimeValues];
    if (!mergeValues.contains(s.activityMergeTime)) mergeValues.add(s.activityMergeTime);
    mergeValues.sort();

    return AnymeXExpansionTile(
      title: 'Anime & Manga',
      initialExpanded: true,
      content: Column(children: [
        CustomTile(icon: Icons.title_rounded, title: 'Title Language',
          description: _titleLanguageLabel(s.titleLanguage), isDescBold: true,
          onTap: () => _showOptionPicker<String>(title: 'Title Language', items: titleValues,
            value: s.titleLanguage, itemLabel: _titleLanguageLabel,
            onChanged: (v) => _update((s) => s.titleLanguage = v))),
        CustomTile(icon: Icons.record_voice_over_rounded, title: 'Staff & Character Name Language',
          description: _staffNameLanguageLabel(s.staffNameLanguage), isDescBold: true,
          onTap: () => _showOptionPicker<String>(title: 'Staff & Character Name Language', items: staffValues,
            value: s.staffNameLanguage, itemLabel: _staffNameLanguageLabel,
            onChanged: (v) => _update((s) => s.staffNameLanguage = v))),
        CustomTile(icon: Icons.schedule_rounded, title: 'Activity Merge Time',
          description: _activityMergeLabel(s.activityMergeTime), isDescBold: true,
          onTap: () => _showOptionPicker<int>(title: 'Activity Merge Time', items: mergeValues,
            value: s.activityMergeTime, itemLabel: _activityMergeLabel,
            onChanged: (v) => _update((s) => s.activityMergeTime = v))),
        CustomSwitchTile(icon: Icons.notifications_active_rounded, title: 'Airing Anime Notifications',
          description: 'Enable notifications for upcoming airing episodes.',
          switchValue: s.airingNotifications,
          onChanged: (v) => _update((s) => s.airingNotifications = v)),
        CustomSwitchTile(icon: Icons.warning_amber_rounded, title: '18+ Content',
          description: 'Enable NSFW/adult entries in AniList content.',
          switchValue: s.displayAdultContent,
          onChanged: (v) => _update((s) => s.displayAdultContent = v)),
      ]),
    );
  }

  Widget _buildListSection() {
    final s = _settings!;
    final scoreValues = _scoreFormatValues.contains(s.scoreFormat)
        ? _scoreFormatValues : <String>[..._scoreFormatValues, s.scoreFormat];
    final rowValues = _rowOrderValues.contains(s.rowOrder)
        ? _rowOrderValues : <String>[..._rowOrderValues, s.rowOrder];
    final animeSections = _sectionOrderOptions(base: _animeBaseSectionOrder,
      splitCompletedSections: _animeCompletedSplitSections, splitCompleted: s.splitCompletedAnime);
    final mangaSections = _sectionOrderOptions(base: _mangaBaseSectionOrder,
      splitCompletedSections: _mangaCompletedSplitSections, splitCompleted: s.splitCompletedManga);

    return AnymeXExpansionTile(
      title: 'List Options',
      initialExpanded: true,
      content: Column(children: [
        CustomTile(icon: Icons.scoreboard_rounded, title: 'Scoring System',
          description: _scoreFormatLabel(s.scoreFormat), isDescBold: true,
          onTap: () => _showOptionPicker<String>(title: 'Scoring System', items: scoreValues,
            value: s.scoreFormat, itemLabel: _scoreFormatLabel,
            onChanged: (v) => _update((s) => s.scoreFormat = v))),
        CustomTile(icon: Icons.sort_rounded, title: 'Default List Order',
          description: _rowOrderLabel(s.rowOrder), isDescBold: true,
          onTap: () => _showOptionPicker<String>(title: 'Default List Order', items: rowValues,
            value: s.rowOrder, itemLabel: _rowOrderLabel,
            onChanged: (v) => _update((s) => s.rowOrder = v))),
        CustomSwitchTile(icon: Icons.view_stream_rounded, title: 'Split Completed Anime List',
          description: 'Separate completed anime list into sections by format.',
          switchValue: s.splitCompletedAnime,
          onChanged: (v) => _update((s) {
            s.splitCompletedAnime = v;
            s.animeSectionOrder = _normalizeSectionOrder(s.animeSectionOrder,
              _sectionOrderOptions(base: _animeBaseSectionOrder,
                splitCompletedSections: _animeCompletedSplitSections, splitCompleted: v));
          })),
        CustomSwitchTile(icon: Icons.view_stream_rounded, title: 'Split Completed Manga List',
          description: 'Separate completed manga list into sections by format.',
          switchValue: s.splitCompletedManga,
          onChanged: (v) => _update((s) {
            s.splitCompletedManga = v;
            s.mangaSectionOrder = _normalizeSectionOrder(s.mangaSectionOrder,
              _sectionOrderOptions(base: _mangaBaseSectionOrder,
                splitCompletedSections: _mangaCompletedSplitSections, splitCompleted: v));
          })),
        CustomTile(icon: Icons.list_alt_rounded, title: 'Anime Custom Lists',
          description: s.animeCustomLists.isEmpty ? 'No lists added' : s.animeCustomLists.join(', '),
          onTap: () => _editCustomLists(title: 'Anime Custom Lists', current: s.animeCustomLists,
            onApply: (v) => _update((s) => s.animeCustomLists = v))),
        CustomTile(icon: Icons.menu_book_rounded, title: 'Manga Custom Lists',
          description: s.mangaCustomLists.isEmpty ? 'No lists added' : s.mangaCustomLists.join(', '),
          onTap: () => _editCustomLists(title: 'Manga Custom Lists', current: s.mangaCustomLists,
            onApply: (v) => _update((s) => s.mangaCustomLists = v))),
        CustomTile(icon: Icons.reorder_rounded, title: 'Anime Section Order',
          description: 'Drag to reorder · ${_normalizeSectionOrder(s.animeSectionOrder, animeSections).length} items',
          onTap: () => _editSectionOrder(title: 'Anime', current: s.animeSectionOrder,
            allowedValues: animeSections, onApply: (v) => _update((s) => s.animeSectionOrder = v))),
        CustomTile(icon: Icons.reorder_rounded, title: 'Manga Section Order',
          description: 'Drag to reorder · ${_normalizeSectionOrder(s.mangaSectionOrder, mangaSections).length} items',
          onTap: () => _editSectionOrder(title: 'Manga', current: s.mangaSectionOrder,
            allowedValues: mangaSections, onApply: (v) => _update((s) => s.mangaSectionOrder = v))),
      ]),
    );
  }

  Widget _buildOtherSection() {
    final s = _settings!;
    final tzValues = _buildTimezoneOffsets().toList(growable: true);
    final tzValue = _normalizeTimezoneValue(s.timezone);
    if (!tzValues.contains(tzValue)) tzValues.add(tzValue);

    return AnymeXExpansionTile(
      title: 'Other',
      initialExpanded: false,
      content: Column(children: [
        CustomSwitchTile(icon: Icons.lock_rounded, title: 'Restrict Messages To Following',
          description: 'Allow only users I follow to message me.',
          switchValue: s.restrictMessagesToFollowing,
          onChanged: (v) => _update((s) => s.restrictMessagesToFollowing = v)),
        CustomTile(icon: Icons.public_rounded, title: 'Select Timezone',
          description: _timezoneLabel(tzValue), isDescBold: true,
          onTap: () => _showOptionPicker<String>(title: 'Select Timezone', items: tzValues,
            value: tzValue, itemLabel: _timezoneLabel,
            onChanged: (v) => _update((s) => s.timezone = v))),

        _buildAboutEditor(),
      ]),
    );
  }

  Widget _buildAboutEditor() {
    final toolbar = <(IconData, VoidCallback)>[
      (Icons.format_bold_rounded, () => _wrapAboutSelection(prefix: '**', suffix: '**')),
      (Icons.format_italic_rounded, () => _wrapAboutSelection(prefix: '*', suffix: '*')),
      (Icons.strikethrough_s_rounded, () => _wrapAboutSelection(prefix: '~~', suffix: '~~')),
      (Icons.visibility_off_rounded, () => _wrapAboutSelection(prefix: '~!', suffix: '!~', placeholder: 'spoiler')),
      (Icons.link_rounded, () => _insertAboutText('[title](https://example.com)')),
      (Icons.image_rounded, () => _insertAboutText('![alt](https://image.url)')),
      (Icons.ondemand_video_rounded, () => _insertAboutText('[Video](https://youtube.com/watch?v=)')),
      (Icons.format_list_numbered_rounded, () => _insertAboutText('1. Item\n2. Item\n')),
      (Icons.format_list_bulleted_rounded, () => _insertAboutText('- Item\n- Item\n')),
      (Icons.title_rounded, () => _insertAboutText('## Heading\n')),
      (Icons.format_quote_rounded, () => _insertAboutText('> Quote\n')),
      (Icons.code_rounded, () => _wrapAboutSelection(prefix: '`', suffix: '`', placeholder: 'code')),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AnymeXIcon(Icons.notes_rounded, size: 30, color: context.colors.primary),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.onSurface))),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Edit')),
                ButtonSegment(value: true, label: Text('Preview')),
              ],
              selected: {_aboutPreview}, showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _aboutPreview = v.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
            if (!_aboutPreview)
              IconButton(
                tooltip: _aboutEditorExpanded ? 'Collapse editor' : 'Expand editor',
                onPressed: () => setState(() => _aboutEditorExpanded = !_aboutEditorExpanded),
                icon: Icon(_aboutEditorExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded, size: 20),
                visualDensity: VisualDensity.compact,
                color: context.colors.onSurface.opaque(0.82),
              ),
          ]),
          const SizedBox(height: 10),
          if (!_aboutPreview) ...[
            Container(
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer.opaque(0.72),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.colors.outline.opaque(0.25)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(children: [
                  for (final (icon, onTap) in toolbar)
                    IconButton(onPressed: onTap, icon: Icon(icon, size: 19),
                      visualDensity: VisualDensity.compact, color: context.colors.onSurface.opaque(0.82)),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _aboutController,
              minLines: _aboutEditorExpanded ? 12 : 7,
              maxLines: _aboutEditorExpanded ? 24 : 12,
              style: TextStyle(fontSize: 15, color: context.colors.onSurface, height: 1.35),
              decoration: InputDecoration(
                hintText: 'Write your AniList bio...',
                filled: true, fillColor: context.colors.surfaceContainer.opaque(0.72),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.colors.outline.opaque(0.25))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.colors.primary.opaque(0.75), width: 1.25)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ] else
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer.opaque(0.72),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.outline.opaque(0.25)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Spacer(),
                  IconButton(
                    tooltip: _aboutPreviewExpanded ? 'Collapse preview' : 'Expand preview',
                    onPressed: () => setState(() => _aboutPreviewExpanded = !_aboutPreviewExpanded),
                    icon: Icon(_aboutPreviewExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 22),
                    visualDensity: VisualDensity.compact,
                    color: context.colors.onSurface.opaque(0.82),
                  ),
                ]),
                if (_aboutPreviewExpanded)
                  _aboutController.text.trim().isEmpty
                      ? Text('Nothing to preview yet.',
                          style: TextStyle(color: context.colors.onSurface.opaque(0.6), fontSize: 14))
                      : AnilistAboutMe(about: _previewAbout(_aboutController.text)),
              ]),
            ),
        ])),
      ]),
    );
  }

  

  Widget _buildSaveButton() => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: SizedBox(width: double.infinity, child: FilledButton.icon(
      onPressed: _saving ? null : _saveSettings,
      icon: _saving
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.save_rounded),
      label: Text(_saving ? 'Saving...' : 'Save AniList Settings'),
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14)),
    )),
  );

  Widget _buildError() => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: context.colors.error)),
      const SizedBox(height: 12),
      ElevatedButton.icon(onPressed: _loadSettings,
        icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
    ]),
  ));

  Widget _buildInlineError() => Card(
    color: context.colors.errorContainer.opaque(0.75),
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: Icon(Icons.error_outline_rounded, color: context.colors.error),
      title: Text(_error!, style: TextStyle(color: context.colors.onErrorContainer)),
      trailing: IconButton(
        onPressed: () => setState(() => _error = null),
        icon: const Icon(Icons.close_rounded)),
    ),
  );
}
