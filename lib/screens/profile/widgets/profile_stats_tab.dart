import 'dart:math';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/staff.dart';
import 'package:anymex/screens/anime/widgets/character_staff_sheet.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/screens/library/online/anime_list.dart';
import 'package:anymex/screens/library/online/manga_list.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

enum _StatsSubTab { overview, genres, tags, staff, voiceActors, studios }

enum _StatMetric { count, time, meanScore }

// main
class ProfileStatsTab extends StatefulWidget {
  final Profile user;
  const ProfileStatsTab({super.key, required this.user});

  @override
  State<ProfileStatsTab> createState() => _ProfileStatsTabState();
}

class _ProfileStatsTabState extends State<ProfileStatsTab> {
  bool _isAnime = true;
  _StatsSubTab _subTab = _StatsSubTab.overview;
  _StatMetric _metric = _StatMetric.count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final bottomSpace = MediaQuery.of(context).size.width > 900 ? 32.0 : 120.0;
    final anime = widget.user.stats?.animeStats;
    final manga = widget.user.stats?.mangaStats;

    // Voice Actors & Studios (Anime only)
    final visibleTabs = _StatsSubTab.values.where((t) {
      if (t == _StatsSubTab.voiceActors && !_isAnime) return false;
      if (t == _StatsSubTab.studios && !_isAnime) return false;
      return true;
    }).toList();

    if ((_subTab == _StatsSubTab.voiceActors ||
            _subTab == _StatsSubTab.studios) &&
        !_isAnime) {
      _subTab = _StatsSubTab.overview;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
            height: 50,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                _segmentBtn('Anime', _isAnime, () {
                  setState(() => _isAnime = true);
                }),
                _segmentBtn('Manga', !_isAnime, () {
                  setState(() => _isAnime = false);
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final tab = visibleTabs[i];
                final selected = _subTab == tab;
                return GestureDetector(
                  onTap: () => setState(() => _subTab = tab),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: selected
                          ? colorScheme.primary.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? colorScheme.primary.withOpacity(0.3)
                            : colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: AnymexText(
                      text: _tabLabel(tab),
                      size: 13,
                      variant:
                          selected ? TextVariant.semiBold : TextVariant.regular,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _metricPill('Count', _StatMetric.count),
              const SizedBox(width: 6),
              _metricPill('Time', _StatMetric.time),
              const SizedBox(width: 6),
              _metricPill('Score', _StatMetric.meanScore),
            ],
          ),
          const SizedBox(height: 16),
          if (_isAnime && anime != null)
            ..._buildContent(anime, null)
          else if (!_isAnime && manga != null)
            ..._buildContent(null, manga)
          else
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: AnymexText(
                  text: 'No stats available',
                  color: colorScheme.onSurface.opaque(0.5),
                ),
              ),
            ),
          SizedBox(height: bottomSpace),
        ],
      ),
    );
  }

  // content
  List<Widget> _buildContent(AnimeStats? anime, MangaStats? manga) {
    switch (_subTab) {
      case _StatsSubTab.overview:
        return _overviewView(anime, manga);
      case _StatsSubTab.genres:
        return _genresView(anime, manga);
      case _StatsSubTab.tags:
        return _tagsView(anime, manga);
      case _StatsSubTab.staff:
        return _staffView(anime, manga);
      case _StatsSubTab.voiceActors:
        return _voiceActorsView(anime);
      case _StatsSubTab.studios:
        return _studiosView(anime);
    }
  }

  // overview tab════════════════════════════════════════════════════════════════════════

  List<Widget> _overviewView(AnimeStats? anime, MangaStats? manga) {
    final isAnime = anime != null;
    final scores = isAnime ? anime.scores : manga!.scores;
    final formats = isAnime ? anime.formats : manga!.formats;
    final statuses = isAnime ? anime.statuses : manga!.statuses;
    final countries = isAnime ? anime.countries : manga!.countries;
    final releaseYears = isAnime ? anime.releaseYears : manga!.releaseYears;
    final startYears = isAnime ? anime.startYears : manga!.startYears;
    final lengths = isAnime ? anime.lengths : manga!.lengths;

    return [
      // Summary card
      _sectionContainer(
        icon: IconlyLight.chart,
        title: 'Summary',
        child: _overviewSummaryGrid(anime, manga),
      ),
      if (scores.isNotEmpty) ...[
        const SizedBox(height: 16),
        _sectionContainer(
          icon: Icons.bar_chart_rounded,
          title: 'Score Distribution',
          child: _verticalStatsBar(scores),
        ),
      ],
      if (lengths.isNotEmpty) ...[
        const SizedBox(height: 16),
        _sectionContainer(
          icon: Icons.query_builder_rounded,
          title: isAnime ? 'Episode Count' : 'Chapter Count',
          child: _verticalStatsBar(lengths),
        ),
      ],
      if (statuses.isNotEmpty) ...[
        const SizedBox(height: 16),
        _sectionContainer(
          icon: Icons.radio_button_checked,
          title: 'Status Distribution',
          child: _horizontalStatsBar(statuses),
        ),
      ],
      if (formats.isNotEmpty) ...[
        const SizedBox(height: 16),
        _sectionContainer(
          icon: Icons.style_outlined,
          title: 'Format Distribution',
          child: _horizontalStatsBar(formats),
        ),
      ],
      if (countries.isNotEmpty) ...[
        const SizedBox(height: 16),
        _sectionContainer(
          icon: Icons.public,
          title: 'Country Distribution',
          child: _horizontalStatsBar(countries),
        ),
      ],
      if (releaseYears.isNotEmpty) ...[
        const SizedBox(height: 16),
        _sectionContainer(
          icon: Icons.event,
          title: 'Release Year',
          child: _verticalStatsBar(releaseYears),
        ),
      ],
      if (startYears.isNotEmpty) ...[
        const SizedBox(height: 16),
        _sectionContainer(
          icon: Icons.calendar_month,
          title: isAnime ? 'Watch Year' : 'Read Year',
          child: _verticalStatsBar(startYears),
        ),
      ],
    ];
  }

  // genres tab
  List<Widget> _genresView(AnimeStats? anime, MangaStats? manga) {
    final items = (anime?.genres ?? manga?.genres ?? [])
        .map((g) => _RankedItem(g.genre, g.count, g.meanScore, g.amount))
        .toList();
    if (items.isEmpty) return [_emptyState('No genre data')];
    return [
      _sectionContainer(
        icon: Icons.category_rounded,
        title: 'Genres',
        child: _rankedList(items,
            onTap: (label, {id, image}) => _searchFor(label, isGenre: true)),
      ),
    ];
  }

  // tags tab═════════════════════════════════════════════════════════════════════════

  List<Widget> _tagsView(AnimeStats? anime, MangaStats? manga) {
    final items = (anime?.tags ?? manga?.tags ?? [])
        .map((t) => _RankedItem(t.tag, t.count, t.meanScore, t.amount))
        .toList();
    if (items.isEmpty) return [_emptyState('No tag data')];
    return [
      _sectionContainer(
        icon: Icons.tag,
        title: 'Tags',
        child: _rankedList(items,
            onTap: (label, {id, image}) => _searchFor(label, isTag: true)),
      ),
    ];
  }

  // staff tab
  List<Widget> _staffView(AnimeStats? anime, MangaStats? manga) {
    final items = (anime?.staff ?? manga?.staff ?? [])
        .map((s) => _RankedItem(s.name, s.count, s.meanScore, s.amount,
            image: s.image, id: s.id))
        .toList();
    if (items.isEmpty) return [_emptyState('No staff data')];
    return [
      _sectionContainer(
        icon: IconlyLight.user,
        title: 'Staff',
        child:
            _rankedList(items, showAvatar: true, onTap: (label, {id, image}) {
          if (id != null) _openSheet(id: id, name: label, image: image);
        }),
      ),
    ];
  }

  // VA
  List<Widget> _voiceActorsView(AnimeStats? anime) {
    final items = (anime?.voiceActors ?? [])
        .map((v) => _RankedItem(v.name, v.count, v.meanScore, v.amount,
            image: v.image, id: v.id))
        .toList();
    if (items.isEmpty) return [_emptyState('No voice actor data')];
    return [
      _sectionContainer(
        icon: Icons.record_voice_over,
        title: 'Voice Actors',
        child:
            _rankedList(items, showAvatar: true, onTap: (label, {id, image}) {
          if (id != null) _openSheet(id: id, name: label, image: image);
        }),
      ),
    ];
  }

  // studios tab
  List<Widget> _studiosView(AnimeStats? anime) {
    final items = (anime?.studios ?? [])
        .map((s) => _RankedItem(s.name, s.count, s.meanScore, s.amount))
        .toList();
    if (items.isEmpty) return [_emptyState('No studio data')];
    return [
      _sectionContainer(
        icon: Icons.business_outlined,
        title: 'Studios',
        child: _rankedList(items),
      ),
    ];
  }

  Widget _segmentBtn(String label, bool selected, VoidCallback onTap) {
    final c = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? c.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(21),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: c.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color:
                  selected ? c.onPrimary : c.onSurfaceVariant.withOpacity(0.7),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _metricPill(String label, _StatMetric metric) {
    final c = context.colors;
    final selected = _metric == metric;
    return GestureDetector(
      onTap: () => setState(() => _metric = metric),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? c.primary.opaque(0.15, iReallyMeanIt: true)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                selected ? c.primary.opaque(0.3) : c.outlineVariant.opaque(0.3),
          ),
        ),
        child: AnymexText(
          text: label,
          size: 11,
          variant: selected ? TextVariant.semiBold : TextVariant.regular,
          color: selected ? c.primary : c.onSurface.opaque(0.4),
        ),
      ),
    );
  }

  Widget _sectionContainer({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surfaceContainerHighest.opaque(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: c.outline.opaque(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.primary.opaque(0.15, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: c.primary),
              ),
              const SizedBox(width: 12),
              AnymexText(
                text: title,
                variant: TextVariant.bold,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _textSubtitleVertical(String text, String subtitle) {
    final c = context.colors;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnymexText(
            text: text,
            size: 20,
            variant: TextVariant.bold,
            color: c.onSurface,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            isMarquee: true,
          ),
          const SizedBox(height: 2),
          AnymexText(
            text: subtitle,
            size: 13,
            color: c.onSurfaceVariant,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _overviewSummaryGrid(AnimeStats? anime, MangaStats? manga) {
    final isAnime = anime != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _textSubtitleVertical(
                  isAnime
                      ? (anime.animeCount ?? '0')
                      : (manga?.mangaCount ?? '0'),
                  'Total'),
              _textSubtitleVertical(
                  isAnime
                      ? (anime.episodesWatched ?? '0')
                      : (manga?.chaptersRead ?? '0'),
                  isAnime ? 'Episodes Watched' : 'Chapters Read'),
              _textSubtitleVertical(
                  isAnime
                      ? _minToDays(anime.minutesWatched)
                      : (manga?.volumesRead ?? '0'),
                  isAnime ? 'Days Watched' : 'Volumes Read'),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _textSubtitleVertical(
                  isAnime
                      ? _minToDays(_plannedAmount(anime.statuses)?.toString())
                      : (_plannedCount(manga?.statuses ?? [])?.toString() ??
                          '0'),
                  isAnime ? 'Days Planned' : 'Chapters Planned'),
              _textSubtitleVertical(
                  isAnime
                      ? '${anime.meanScore ?? '0'}%'
                      : '${manga?.meanScore ?? '0'}%',
                  'Mean Score'),
              _textSubtitleVertical(
                  isAnime
                      ? (anime.standardDeviation?.toStringAsFixed(1) ?? '0.0')
                      : (manga?.standardDeviation?.toStringAsFixed(1) ?? '0.0'),
                  'Standard Deviation'),
            ],
          ),
        ],
      ),
    );
  }

  int _getVal(dynamic s) {
    if (s is TypeStat)
      return _metric == _StatMetric.count
          ? s.count
          : _metric == _StatMetric.time
              ? s.amount
              : s.meanScore.round();
    if (s is ScoreStat)
      return _metric == _StatMetric.count
          ? s.count
          : _metric == _StatMetric.time
              ? s.amount
              : s.meanScore.round();
    if (s is LengthStat)
      return _metric == _StatMetric.count
          ? s.count
          : _metric == _StatMetric.time
              ? s.amount
              : s.meanScore.round();
    if (s is YearStat)
      return _metric == _StatMetric.count
          ? s.count
          : _metric == _StatMetric.time
              ? s.amount
              : s.meanScore.round();
    return 0;
  }

  String _getLabel(dynamic s) {
    if (s is TypeStat) return _fmtLabel(s.type);
    if (s is ScoreStat) return s.score.toString();
    if (s is LengthStat) return s.length;
    if (s is YearStat)
      return "'${s.year.toString().substring(s.year.toString().length >= 2 ? s.year.toString().length - 2 : 0)}";
    return '';
  }

  String _getValDisplay(int val) {
    if (_metric == _StatMetric.time) {
      return _minToHours(val);
    }
    return val.toString();
  }

  Widget _horizontalStatsBar(List<dynamic> items) {
    final c = context.colors;
    final total = items.fold<int>(0, (s, i) => s + _getVal(i));
    if (total == 0) return const SizedBox.shrink();

    final palette = _palette(items.length);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(items.length, (i) {
              final val = _getVal(items[i]);
              if (val == 0) return const SizedBox.shrink();
              final color = palette[i];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnymexText(
                        text: val.toString(),
                        size: 13,
                        color: color,
                        variant: TextVariant.bold),
                    const SizedBox(width: 8),
                    AnymexText(
                        text: _getLabel(items[i]),
                        size: 13,
                        color: color.withOpacity(0.8),
                        variant: TextVariant.semiBold),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 16,
            width: double.infinity,
            child: Row(
              children: List.generate(items.length, (i) {
                final val = _getVal(items[i]);
                if (val == 0) return const SizedBox.shrink();
                return Expanded(
                  flex: val,
                  child: Container(color: palette[i]),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 14),
        AnymexText(
          text: 'Total entries: $total',
          size: 13,
          color: c.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _verticalStatsBar(List<dynamic> items) {
    final c = context.colors;

    // For YearStats
    var sortedItems = List<dynamic>.from(items);
    if (sortedItems.isNotEmpty && sortedItems.first is YearStat) {
      sortedItems = sortedItems.where((y) => (y as YearStat).year > 0).toList()
        ..sort((a, b) => (a as YearStat).year.compareTo((b as YearStat).year));
    }

    final maxVal = sortedItems.fold<int>(0, (m, i) => max(m, _getVal(i)));
    if (maxVal == 0) return const SizedBox.shrink();

    return Column(
      children: sortedItems.map((item) {
        final val = _getVal(item);
        if (val == 0 && item is! YearStat) return const SizedBox.shrink();
        final fraction = val / maxVal;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              SizedBox(
                width: 45,
                child: AnymexText(
                  text: _getLabel(item),
                  size: 12,
                  color: c.onSurfaceVariant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  isMarquee: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 10,
                        width: constraints.maxWidth * fraction,
                        decoration: BoxDecoration(
                          color: item is ScoreStat
                              ? _scoreColor(item.score)
                              : c.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 35,
                child: AnymexText(
                  text: _getValDisplay(val),
                  size: 11,
                  variant: TextVariant.semiBold,
                  color: c.onSurface,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _rankedList(
    List<_RankedItem> items, {
    bool showAvatar = false,
    Function(String label, {String? id, String? image})? onTap,
  }) {
    final c = context.colors;
    final hasTap = onTap != null;

    return Column(
      children: List.generate(items.length, (i) {
        final item = items[i];
        // primary info
        final primaryValue = _metric == _StatMetric.count
            ? item.count.toString()
            : _metric == _StatMetric.time
                ? _minToHours(item.amount)
                : item.meanScore.toStringAsFixed(1);
        // Secondary info
        final secondaryValue = _metric == _StatMetric.count
            ? '★ ${item.meanScore.toStringAsFixed(1)}'
            : '${item.count} titles';

        return GestureDetector(
          onTap: hasTap
              ? () => onTap(item.label, id: item.id, image: item.image)
              : null,
          child: Container(
            margin: EdgeInsets.only(top: i == 0 ? 0 : 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: c.surface.opaque(0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: c.primary.opaque(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Position badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: i < 3
                        ? c.primary.opaque(0.15, iReallyMeanIt: true)
                        : c.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AnymexText(
                    text: '#${i + 1}',
                    size: 11,
                    variant: TextVariant.bold,
                    color: i < 3 ? c.primary : c.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                // Avatar (staff / VA)
                if (showAvatar && item.image != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(item.image!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => CircleAvatar(
                            radius: 18,
                            backgroundColor: c.surfaceContainerHigh)),
                  ),
                  const SizedBox(width: 10),
                ],
                // Name
                Expanded(
                  child: AnymexText(
                    text: item.label,
                    size: 13,
                    variant: TextVariant.semiBold,
                    color: c.onSurface,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    isMarquee: true,
                  ),
                ),
                // Value column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnymexText(
                      text: primaryValue,
                      size: 14,
                      variant: TextVariant.bold,
                      color: c.primary,
                    ),
                    AnymexText(
                      text: secondaryValue,
                      size: 10,
                      color: c.onSurface.opaque(0.5),
                    ),
                  ],
                ),
                if (hasTap) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: c.primary.opaque(0.5)),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _emptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: AnymexText(
          text: msg,
          color: context.colors.onSurface.opaque(0.5),
        ),
      ),
    );
  }

  // nav
  Future<void> _searchFor(String label,
      {bool isGenre = false, bool isTag = false}) async {
    final handler = Get.find<ServiceHandler>();
    if (handler.serviceType.value != ServicesType.anilist) return;

    if (isTag) {
      navigate(() => SearchPage(
            searchTerm: '',
            isManga: !_isAnime,
            initialFilters: {
              'tags': [label]
            },
          ));
      return;
    }

    final isCurrentUser = handler.profileData.value.id == widget.user.id;

    if (isCurrentUser) {
      if (_isAnime) {
        navigate(() => AnimeList(
              initialTab: 'ALL',
              initialGenres: {label},
            ));
      } else {
        navigate(() => AnilistMangaList(
              initialTab: 'ALL',
              initialGenres: {label},
            ));
      }
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final auth = Get.find<AnilistAuth>();
      final type = _isAnime ? 'ANIME' : 'MANGA';
      final userId = int.tryParse(widget.user.id ?? '0') ?? 0;
      final lists = await auth.fetchUserMediaList(userId, type);

      if (!mounted) return;
      Navigator.pop(context);

      final data = lists['All'] ?? [];

      if (_isAnime) {
        navigate(() => AnimeList(
              data: data,
              userName: widget.user.name,
              initialTab: 'ALL',
              initialGenres: {label},
            ));
      } else {
        navigate(() => AnilistMangaList(
              data: data,
              userName: widget.user.name,
              initialTab: 'ALL',
              initialGenres: {label},
            ));
      }
    }
  }

  void _openSheet({required String id, required String name, String? image}) {
    final staffObj = Staff(id: id, name: name, image: image);
    showCharacterStaffSheet(context, item: staffObj, isCharacter: false);
  }

  // helpers
  String _tabLabel(_StatsSubTab t) {
    switch (t) {
      case _StatsSubTab.overview:
        return 'Overview';
      case _StatsSubTab.genres:
        return 'Genres';
      case _StatsSubTab.tags:
        return 'Tags';
      case _StatsSubTab.staff:
        return 'Staff';
      case _StatsSubTab.voiceActors:
        return 'Voice Actors';
      case _StatsSubTab.studios:
        return 'Studios';
    }
  }

  String _minToDays(String? min) {
    final m = int.tryParse(min ?? '0') ?? 0;
    return (m / 1440).toStringAsFixed(1);
  }

  String _minToHours(int min) {
    if (min < 60) return '${min}m';
    return '${(min / 60).toStringAsFixed(1)}h';
  }

  Color _scoreColor(int score) {
    if (score <= 30) return const Color(0xFFEF4444);
    if (score <= 50) return const Color(0xFFF97316);
    if (score <= 70) return const Color(0xFFFBBF24);
    if (score <= 85) return const Color(0xFF84CC16);
    return const Color(0xFF22C55E);
  }

  List<Color> _palette(int n) {
    const c = [
      Color(0xFF6366F1),
      Color(0xFF22D3EE),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF14B8A6),
      Color(0xFFF97316),
      Color(0xFF06B6D4),
    ];
    return List.generate(n, (i) => c[i % c.length]);
  }

  String _fmtLabel(String raw) {
    return raw
        .split('_')
        .map((w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  int? _plannedAmount(List<TypeStat> statuses) {
    final planned =
        statuses.where((s) => s.type.toUpperCase() == 'PLANNING').firstOrNull;
    return planned?.amount;
  }

  int? _plannedCount(List<TypeStat> statuses) {
    final planned =
        statuses.where((s) => s.type.toUpperCase() == 'PLANNING').firstOrNull;
    return planned?.count;
  }
}

// data holders
class _RankedItem {
  final String label;
  final int count;
  final double meanScore;
  final int amount;
  final String? image;
  final String? id;
  _RankedItem(this.label, this.count, this.meanScore, this.amount,
      {this.image, this.id});
}
