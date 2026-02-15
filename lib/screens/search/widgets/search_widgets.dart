import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showFilterBottomSheet(
  BuildContext context,
  Function(dynamic args) onApplyFilter, {
  Map<String, dynamic>? currentFilters,
  bool isManga = false,
}) {
    BuildContext context, Function(dynamic args) onApplyFilter,
    {Map<String, dynamic>? currentFilters, String mediaType = 'anime'}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FilterSheet(
      onApplyFilter: onApplyFilter,
      currentFilters: currentFilters,
      isManga: isManga,
    ),
    builder: (BuildContext context) {
      return FuturisticFilterSheet(
        onApplyFilter: onApplyFilter,
        currentFilters: currentFilters,
        mediaType: mediaType,
      );
    },
  );
}

const _animeSorts = {
  'Trending': 'TRENDING_DESC',
  'Popularity': 'POPULARITY_DESC',
  'Score': 'SCORE_DESC',
  'Newest': 'START_DATE_DESC',
  'Oldest': 'START_DATE',
  'Title A–Z': 'TITLE_ROMAJI',
  'Title Z–A': 'TITLE_ROMAJI_DESC',
  'Episodes': 'EPISODES_DESC',
  'Favourites': 'FAVOURITES_DESC',
};

const _mangaSorts = {
  'Trending': 'TRENDING_DESC',
  'Popularity': 'POPULARITY_DESC',
  'Score': 'SCORE_DESC',
  'Newest': 'START_DATE_DESC',
  'Oldest': 'START_DATE',
  'Title A–Z': 'TITLE_ROMAJI',
  'Title Z–A': 'TITLE_ROMAJI_DESC',
  'Chapters': 'CHAPTERS_DESC',
  'Volumes': 'VOLUMES_DESC',
  'Favourites': 'FAVOURITES_DESC',
};

const _animeFormats = [
  'TV',
  'TV_SHORT',
  'MOVIE',
  'SPECIAL',
  'OVA',
  'ONA',
  'MUSIC'
];
const _animeFormatLabels = {
  'TV': 'TV',
  'TV_SHORT': 'TV Short',
  'MOVIE': 'Movie',
  'SPECIAL': 'Special',
  'OVA': 'OVA',
  'ONA': 'ONA',
  'MUSIC': 'Music',
};

const _mangaFormats = ['MANGA', 'NOVEL', 'ONE_SHOT'];
const _mangaFormatLabels = {
  'MANGA': 'Manga',
  'NOVEL': 'Novel',
  'ONE_SHOT': 'One Shot',
};

const _statuses = [
  'FINISHED',
  'RELEASING',
  'NOT_YET_RELEASED',
  'CANCELLED',
  'HIATUS'
];
const _statusLabels = {
  'FINISHED': 'Finished',
  'RELEASING': 'Releasing',
  'NOT_YET_RELEASED': 'Upcoming',
  'CANCELLED': 'Cancelled',
  'HIATUS': 'Hiatus',
};

const _seasons = ['WINTER', 'SPRING', 'SUMMER', 'FALL'];
const _seasonLabels = {
  'WINTER': 'Winter',
  'SPRING': 'Spring',
  'SUMMER': 'Summer',
  'FALL': 'Fall',
};

const _allGenres = [
  'Action',
  'Adventure',
  'Comedy',
  'Drama',
  'Ecchi',
  'Fantasy',
  'Horror',
  'Mahou Shoujo',
  'Mecha',
  'Music',
  'Mystery',
  'Psychological',
  'Romance',
  'Sci-Fi',
  'Slice of Life',
  'Sports',
  'Supernatural',
  'Thriller',
];

const _animeTags = [
  'Shounen',
  'Shoujo',
  'Seinen',
  'Josei',
  'Kids',
  'Isekai',
  'School',
  'Harem',
  'Reverse Harem',
  'Villainess',
  'Reincarnation',
  'Time Travel',
  'Historical',
  'Martial Arts',
  'Post-Apocalyptic',
  'Dystopian',
  'Space',
  'Cyberpunk',
  'Steampunk',
  'Vampire',
  'Demons',
  'Gods',
  'Magic',
  'Samurai',
  'Military',
  'Coming of Age',
  'Cooking',
  'Idol',
  'Parody',
  'Super Power',
  'LGBTQ+',
  'Tragedy',
  'Gore',
];

const _mangaTags = [
  'Shounen',
  'Shoujo',
  'Seinen',
  'Josei',
  'Kids',
  'Manhwa',
  'Manhua',
  'Webtoon',
  'Light Novel',
  'Isekai',
  'Reincarnation',
  'Time Travel',
  'Historical',
  'Villainess',
  'Martial Arts',
  'School',
  'Harem',
  'Reverse Harem',
  'Post-Apocalyptic',
  'Dystopian',
  'Space',
  'Cyberpunk',
  'Steampunk',
  'Vampire',
  'Demons',
  'Gods',
  'Magic',
  'Samurai',
  'Military',
  'Cooking',
  'Idol',
  'LGBTQ+',
  'Tragedy',
  'Parody',
  'Gore',
];

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.onApplyFilter,
    this.currentFilters,
    this.isManga = false,
    this.mediaType = 'anime',
  });

  final Function(dynamic) onApplyFilter;
  final Map<String, dynamic>? currentFilters;
  final bool isManga;
  final String mediaType;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  String? _sort;
  String? _season;
  String? _status;
  String? _format;
  String? _year;
  final Set<String> _genres = {};
  final Set<String> _tags = {};
  String _genreSearch = '';
  String _tagSearch = '';

  late final TextEditingController _yearController;

  final int _thisYear = DateTime.now().year;
  final int _prevYear = DateTime.now().year - 1;
class _FuturisticFilterSheetState extends State<FuturisticFilterSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final Map<String, Map<String, String>> sortOptions = {
    'Score': {
      'desc': 'SCORE_DESC',
      'asc': 'SCORE',
      'label': 'SCORE',
    },
    'Popularity': {
      'desc': 'POPULARITY_DESC',
      'asc': 'POPULARITY',
      'label': 'POPULARITY',
    },
    'Trending': {
      'desc': 'TRENDING_DESC',
      'asc': 'TRENDING',
      'label': 'TRENDING',
    },
    'Start Date': {
      'desc': 'START_DATE_DESC',
      'asc': 'START_DATE',
      'label': 'START_DATE',
    },
    'Title': {
      'desc': 'TITLE_ROMAJI_DESC',
      'asc': 'TITLE_ROMAJI',
      'label': 'TITLE_ROMAJI',
    },
  };

  final List<String> seasons = ['WINTER', 'SPRING', 'SUMMER', 'FALL'];
  final List<String> statuses = [
    'All',
    'FINISHED',
    'NOT_YET_RELEASED',
    'RELEASING',
    'CANCELLED',
    'HIATUS'
  ];

  final List<String> animeFormats = [
    'TV',
    'TV SHORT',
    'MOVIE',
    'SPECIAL',
    'OVA',
    'ONA'
  ];

  final List<String> mangaFormats = [
    'MANGA',
    'NOVEL',
    'ONE_SHOT',
  ];

  final List<String> genres = [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Fantasy',
    'Horror',
    'Mecha',
    'Music',
    'Mystery',
    'Psychological',
    'Romance',
    'Sci-Fi',
    'Slice of Life',
    'Sports',
    'Supernatural',
  ];

  String? selectedSortBy;
  String? selectedSortType;
  String? selectedSeason;
  String? selectedStatus;
  String? selectedFormat;
  List<String> selectedGenres = [];

  List<String> get formats =>
      widget.mediaType == 'manga' ? mangaFormats : animeFormats;

  bool get isManga => widget.mediaType == 'manga';

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _yearController = TextEditingController(text: _year ?? '');
  }

  void _loadFilters() {
    final f = widget.currentFilters;
    if (f == null) return;
    _sort = f['sort'];
    _season = f['season'];
    _status = f['status'];
    _format = f['format'];
    _year = f['year']?.toString();
    if (f['genres'] is List) _genres.addAll(List<String>.from(f['genres']));
    if (f['tags'] is List) _tags.addAll(List<String>.from(f['tags']));
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  Map<String, String> get _sortMap =>
      widget.isManga ? _mangaSorts : _animeSorts;
  List<String> get _formatList =>
      widget.isManga ? _mangaFormats : _animeFormats;
  Map<String, String> get _formatLabelMap =>
      widget.isManga ? _mangaFormatLabels : _animeFormatLabels;
  List<String> get _tagList => widget.isManga ? _mangaTags : _animeTags;

  String? get _sortLabel => _sort == null
      ? null
      : _sortMap.entries
          .firstWhere((e) => e.value == _sort,
              orElse: () => const MapEntry('', ''))
          .key;

  int get _activeCount {
    int c = 0;
    if (_sort != null) c++;
    if (_season != null) c++;
    if (_status != null) c++;
    if (_format != null) c++;
    if (_year != null) c++;
    return c + _genres.length + _tags.length;
  }

  void _setYear(String? v) {
    setState(() => _year = v);
    if (v == null) _yearController.clear();
  }

  void _reset() {
    setState(() {
      _sort = _season = _status = _format = _year = null;
      _genres.clear();
      _tags.clear();
      _genreSearch = '';
      _tagSearch = '';
      _yearController.clear();
    });
  }

  void _apply() {
    widget.onApplyFilter({
      'sort': _sort,
      'season': _season,
      'status': _status,
      'format': _format,
      'year': _year != null ? int.tryParse(_year!) : null,
      'genres': _genres.isEmpty ? null : _genres.toList(),
      'tags': _tags.isEmpty ? null : _tags.toList(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.93),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _buildHandle(cs),
          _buildHeader(cs),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('SORT BY', Icons.swap_vert_rounded),
                  _buildWrapGroup(
                    items: _sortMap.keys.toList(),
                    selected: _sortLabel,
                    onTap: (label) => setState(() {
                      final v = _sortMap[label];
                      _sort = _sort == v ? null : v;
                    }),
                  ),
                  _gap(),
                  if (!widget.isManga) ...[
                    _label('SEASON', Icons.calendar_today_outlined),
                    _buildWrapGroup(
                      items: _seasons,
                      labels: _seasonLabels,
                      selected: _season,
                      onTap: (v) =>
                          setState(() => _season = _season == v ? null : v),
                    ),
                    _gap(),
                  ],
                  _label('YEAR', Icons.date_range_outlined),
                  _buildYearRow(),
                  _gap(),
                  _label('STATUS', Icons.radio_button_on_rounded),
                  _buildWrapGroup(
                    items: _statuses,
                    labels: _statusLabels,
                    selected: _status,
                    onTap: (v) =>
                        setState(() => _status = _status == v ? null : v),
                  ),
                  _gap(),
                  _label('FORMAT', Icons.video_collection_outlined),
                  _buildWrapGroup(
                    items: _formatList,
                    labels: _formatLabelMap,
                    selected: _format,
                    onTap: (v) =>
                        setState(() => _format = _format == v ? null : v),
                  ),
                  _gap(),
                  _label('GENRES', Icons.theater_comedy_outlined),
                  _ChipPicker(
                    allItems: _allGenres,
                    selected: _genres,
                    searchQuery: _genreSearch,
                    onSearch: (q) => setState(() => _genreSearch = q),
                    onTap: (v) => setState(() => _genres.contains(v)
                        ? _genres.remove(v)
                        : _genres.add(v)),
                    hint: 'Search genres',
                  ),
                  _gap(),
                  _label('TAGS', Icons.label_outline_rounded),
                  _ChipPicker(
                    allItems: _tagList,
                    selected: _tags,
                    searchQuery: _tagSearch,
                    onSearch: (q) => setState(() => _tagSearch = q),
                    onTap: (v) => setState(() =>
                        _tags.contains(v) ? _tags.remove(v) : _tags.add(v)),
                    hint: 'Search tags',
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _buildApplyBar(cs),
        ],
      ),
    );
  }

  Widget _buildHandle(ColorScheme cs) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 4),
        child: Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withOpacity(0.13),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );

  Widget _buildHeader(ColorScheme cs) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 16),
      child: Row(
        children: [
          Text(
            'Filters',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: cs.onSurface,
            ),
          ),
          if (_activeCount > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_activeCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (_activeCount > 0)
            GestureDetector(
              onTap: _reset,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 14, color: cs.primary),
                    const SizedBox(width: 5),
                    Text(
                      'Reset',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String text, IconData icon) {
    final cs = context.colors;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 13, color: cs.primary.withOpacity(0.8)),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withOpacity(0.42),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 22);

  Widget _buildWrapGroup({
    required List<String> items,
    required String? selected,
    required void Function(String) onTap,
    Map<String, String>? labels,
  }) {
    final cs = context.colors;
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selected == item;
        final label = labels?[item] ?? item;
        return GestureDetector(
          onTap: () => onTap(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : cs.outline.withOpacity(0.18),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: cs.primary.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? cs.onPrimary : cs.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        );
      }).toList(),
  Widget _buildFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('FILTERS', Icons.filter_list_rounded),
        Row(
          children: [
            // Only show Season filter for anime, not manga
            if (!isManga) ...[
              Expanded(
                child: _buildNeonSelector(
                  hint: 'Season',
                  value: selectedSeason,
                  options: seasons,
                  onChanged: (value) => setState(() => selectedSeason = value),
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: _buildNeonSelector(
                hint: 'Status',
                value: selectedStatus,
                options: statuses,
                onChanged: (value) => setState(() => selectedStatus = value),
                icon: Icons.info_outline_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildNeonSelector(
          hint: 'Format',
          value: selectedFormat,
          options: formats,
          onChanged: (value) => setState(() => selectedFormat = value),
          icon: isManga
              ? Icons.menu_book_rounded
              : Icons.video_library_rounded,
        ),
      ],
    );
  }

  Widget _buildYearRow() {
    final cs = context.colors;
    final theme = Theme.of(context);

    Widget yearChip(String y) {
      final isSelected = _year == y;
      return GestureDetector(
        onTap: () {
          _setYear(_year == y ? null : y);
          if (_year != y) _yearController.text = y;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : cs.outline.withOpacity(0.18),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: cs.primary.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Text(
            y,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? cs.onPrimary : cs.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    final isCustom = _year != null &&
        _year != _thisYear.toString() &&
        _year != _prevYear.toString();

    return Row(
      children: [
        yearChip(_thisYear.toString()),
        const SizedBox(width: 8),
        yearChip(_prevYear.toString()),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedContainer(
            alignment: Alignment.center,
            duration: const Duration(milliseconds: 160),
            height: 38,
            decoration: BoxDecoration(
              color: isCustom
                  ? cs.primary.withOpacity(0.08)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCustom
                    ? cs.primary.withOpacity(0.6)
                    : cs.outline.withOpacity(0.18),
                width: isCustom ? 1.5 : 1,
              ),
            ),
            child: TextField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              style: theme.textTheme.bodySmall?.copyWith(
                color: isCustom ? cs.primary : cs.onSurface.withOpacity(0.7),
                fontWeight: isCustom ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: false,
                hintText: 'Custom year',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.35),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (v) {
                if (v.length == 4) {
                  final parsed = int.tryParse(v);
                  if (parsed != null &&
                      parsed >= 1960 &&
                      parsed <= DateTime.now().year) {
                    setState(() => _year = v);
                  }
                } else {
                  setState(() => _year = null);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApplyBar(ColorScheme cs) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outline.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: cs.outline.withOpacity(0.22)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: _reset,
              icon: Icon(Icons.refresh_rounded,
                  color: cs.onSurface.withOpacity(0.55)),
              tooltip: 'Reset all',
              style: IconButton.styleFrom(
                minimumSize: const Size(50, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _apply,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _activeCount > 0
                    ? 'Apply  ·  $_activeCount active'
                    : 'Apply Filters',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimary,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipPicker extends StatelessWidget {
  const _ChipPicker({
    required this.allItems,
    required this.selected,
    required this.searchQuery,
    required this.onSearch,
    required this.onTap,
    required this.hint,
  });

  final List<String> allItems;
  final Set<String> selected;
  final String searchQuery;
  final void Function(String) onSearch;
  final void Function(String) onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final theme = Theme.of(context);

    final filtered = allItems
        .where((item) =>
            searchQuery.isEmpty ||
            item.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) {
        final aS = selected.contains(a);
        final bS = selected.contains(b);
        if (aS == bS) return a.compareTo(b);
        return aS ? -1 : 1;
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.search_rounded,
                    size: 17, color: cs.onSurface.withOpacity(0.35)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: onSearch,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurface.withOpacity(0.32)),
                      border: InputBorder.none,
                      isDense: true,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filtered.map((item) {
            final isSelected = selected.contains(item);
            return GestureDetector(
              onTap: () => onTap(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary.withOpacity(0.1)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isSelected
                        ? cs.primary.withOpacity(0.6)
                        : cs.outline.withOpacity(0.18),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(Icons.check_rounded, size: 12, color: cs.primary),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      item,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? cs.primary
                            : cs.onSurface.withOpacity(0.68),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
