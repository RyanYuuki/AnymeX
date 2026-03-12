import 'dart:math';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/media_items/media_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

enum _SortMode { lastUpdated, score, title, releaseDate }

const _anilistGenres = [
  'Action',
  'Adventure',
  'Comedy',
  'Drama',
  'Ecchi',
  'Fantasy',
  'Hentai',
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

class AnimeList extends StatefulWidget {
  final List<TrackedMedia>? data;
  final String? title;
  final String? initialTab;
  final String? userName;
  final Set<String>? initialGenres;
  
  const AnimeList({
    super.key,
    this.data,
    this.title,
    this.initialTab,
    this.userName,
    this.initialGenres,
  });

  @override
  State<AnimeList> createState() => _AnimeListState();
}

class _AnimeListState extends State<AnimeList>
    with TickerProviderStateMixin {
  final anilistAuth = Get.find<ServiceHandler>();
  late final List<String> _allTabs;

  List<String> get tabs {
    final animeList = widget.data ?? anilistAuth.animeList;
    return _allTabs.where((tab) {
      if (tab == 'ALL') return true;
      return _getFilteredList(animeList, tab).isNotEmpty;
    }).toList();
  }

  // Search
  bool _searchOpen = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Sort
  _SortMode _sortMode = _SortMode.lastUpdated;
  bool _sortAscending = false;

  // Genre filter
  Set<String> _allGenres = {};
  Set<String> _selectedGenres = {};

  bool _isReversed = false;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    if (widget.initialGenres != null) {
      _selectedGenres = Set.from(widget.initialGenres!);
    }
    
    // user tabs (list)
    final List<String> defaultTabs;
    if (anilistAuth.serviceType.value != ServicesType.anilist) {
      defaultTabs = [
        'WATCHING',
        'COMPLETED',
        'PAUSED',
        'DROPPED',
        'PLANNING',
        'ALL',
      ];
    } else {
      final splitAnime =
          anilistAuth.profileData.value.splitCompletedAnime == true;
      defaultTabs = [
        'WATCHING',
        if (splitAnime) ...[
          'COMPLETED TV',
          'COMPLETED MOVIE',
          'COMPLETED OVA',
          'COMPLETED ONA',
          'COMPLETED TV SHORT',
          'COMPLETED SPECIAL',
        ] else
          'COMPLETED',
        'PAUSED',
        'DROPPED',
        'PLANNING',
        'REWATCHING',
        'FAVOURITES',
        'ALL',
      ];
    }

    
    final sectionOrder =
        anilistAuth.profileData.value.animeSectionOrder;
    if (sectionOrder.isNotEmpty &&
        anilistAuth.serviceType.value == ServicesType.anilist) {
      // Mapping
      const nameMap = {
        'Watching': 'WATCHING',
        'Completed': 'COMPLETED',
        'Completed TV': 'COMPLETED TV',
        'Completed Movie': 'COMPLETED MOVIE',
        'Completed OVA': 'COMPLETED OVA',
        'Completed ONA': 'COMPLETED ONA',
        'Completed TV Short': 'COMPLETED TV SHORT',
        'Completed Special': 'COMPLETED SPECIAL',
        'Paused': 'PAUSED',
        'Dropped': 'DROPPED',
        'Planning': 'PLANNING',
        'Rewatching': 'REWATCHING',
      };
      final ordered = <String>[];
      for (final name in sectionOrder) {
        final tab = nameMap[name];
        if (tab != null && defaultTabs.contains(tab)) {
          ordered.add(tab);
        }
      }
  
      for (final tab in defaultTabs) {
        if (!ordered.contains(tab)) {
          ordered.add(tab);
        }
      }
      _allTabs = ordered;
    } else {
      _allTabs = defaultTabs;
    }
    _initTabController();
    _collectGenres();
    _searchController.addListener(() {
      if (_searchQuery != _searchController.text.toLowerCase()) {
        setState(() => _searchQuery = _searchController.text.toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _initTabController() {
    _tabController?.dispose();
    final orderedTabs = _isReversed ? tabs.reversed.toList() : tabs;
    final requestedInitialTab = widget.initialTab;
    final initialIndex = requestedInitialTab == null
        ? 0
        : orderedTabs.indexOf(requestedInitialTab).clamp(0, orderedTabs.length - 1);
    _tabController = TabController(
      length: orderedTabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  void _collectGenres() {
    final animeList = widget.data ?? anilistAuth.animeList;
    final genres = <String>{..._anilistGenres};
    for (final entry in animeList) {
      genres.addAll(entry.genres);
    }
    _allGenres = genres;
  }

  List<TrackedMedia> _getFilteredList(List<TrackedMedia> baseList, String tab) {
    if (tab == 'FAVOURITES') {
      final favs = anilistAuth.profileData.value.favourites?.anime ?? [];
      return favs.map((f) {
        final tracked = baseList.where((b) => b.id == f.id).firstOrNull;
        if (tracked != null) return tracked;

        return TrackedMedia(
          id: f.id,
          title: f.title,
          poster: f.cover,
          episodeCount: 'N/A',
          rating: f.averageScore?.toString(),
        );
      }).toList();
    }
    return filterListByStatus(baseList, tab);
  }

  List<TrackedMedia> _applyFilters(List<TrackedMedia> items) {
    var result = items.toList();

    // Search filter
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((e) =>
              (e.title ?? '').toLowerCase().contains(_searchQuery))
          .toList();
    }

    // Genre filter
    if (_selectedGenres.isNotEmpty) {
      result = result
          .where(
              (e) => _selectedGenres.every((g) => e.genres.contains(g)))
          .toList();
    }

    // Sort
    result.sort((a, b) {
      int cmp;
      switch (_sortMode) {
        case _SortMode.score:
          final sa = double.tryParse(a.score ?? '0') ?? 0;
          final sb = double.tryParse(b.score ?? '0') ?? 0;
          cmp = sa.compareTo(sb);
          break;
        case _SortMode.title:
          cmp = (a.title ?? '').compareTo(b.title ?? '');
          break;
        case _SortMode.releaseDate:
          cmp = (a.startYear ?? 0).compareTo(b.startYear ?? 0);
          break;
        case _SortMode.lastUpdated:
          cmp = (a.updatedAt ?? 0).compareTo(b.updatedAt ?? 0);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return result;
  }

  void _openRandom() {
    final orderedTabs = _isReversed ? tabs.reversed.toList() : tabs;
    final currentTabName = orderedTabs[_tabController?.index ?? 0];
    final animeList = widget.data ?? anilistAuth.animeList;
    final items = _applyFilters(_getFilteredList(animeList, currentTabName));
    if (items.isEmpty) return;
    final random = items[Random().nextInt(items.length)];
    final media = CardData.fromTrackedMedia(random);
    navigate(() => AnimeDetailsPage(media: media.data, tag: media.title));
  }

  void _showSortMenu(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.sort_rounded, color: colors.primary, size: 20),
                    const SizedBox(width: 10),
                    Text('Sort By',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Poppins-Bold',
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        )),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _sortAscending = !_sortAscending);
                        Navigator.pop(ctx);
                      },
                      icon: Icon(
                        _sortAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 16,
                      ),
                      label: Text(_sortAscending ? 'Ascending' : 'Descending',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              ..._SortMode.values.map((mode) {
                final selected = _sortMode == mode;
                final label = {
                  _SortMode.lastUpdated: 'Last Updated',
                  _SortMode.score: 'Score',
                  _SortMode.title: 'Title',
                  _SortMode.releaseDate: 'Release Date',
                }[mode]!;
                final icon = {
                  _SortMode.lastUpdated: Icons.update_rounded,
                  _SortMode.score: Icons.star_rounded,
                  _SortMode.title: Icons.sort_by_alpha_rounded,
                  _SortMode.releaseDate: Icons.calendar_today_rounded,
                }[mode]!;
                return ListTile(
                  leading: Icon(icon,
                      color: selected
                          ? colors.primary
                          : colors.onSurfaceVariant),
                  title: Text(label,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? colors.primary
                            : colors.onSurface,
                      )),
                  trailing: selected
                      ? Icon(Icons.check_rounded,
                          color: colors.primary, size: 20)
                      : null,
                  onTap: () {
                    setState(() => _sortMode = mode);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showGenreFilter(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sortedGenres = _allGenres.toList()..sort();
    final tempSelected = Set<String>.from(_selectedGenres);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Iconsax.filter, color: colors.primary, size: 20),
                      const SizedBox(width: 10),
                      Text('Filter by Genre',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins-Bold',
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          )),
                      const Spacer(),
                      if (tempSelected.isNotEmpty)
                        TextButton(
                          onPressed: () =>
                              setSheetState(() => tempSelected.clear()),
                          child: const Text('Clear',
                              style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sortedGenres.map((genre) {
                        final isSelected = tempSelected.contains(genre);
                        return FilterChip(
                          label: Text(genre,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? colors.onPrimaryContainer
                                    : colors.onSurfaceVariant,
                              )),
                          selected: isSelected,
                          onSelected: (val) {
                            setSheetState(() {
                              if (val) {
                                tempSelected.add(genre);
                              } else {
                                tempSelected.remove(genre);
                              }
                            });
                          },
                          backgroundColor: colors.surfaceContainer,
                          selectedColor: colors.primaryContainer,
                          checkmarkColor: colors.onPrimaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? colors.primary.withOpacity(0.5)
                                  : colors.outlineVariant.withOpacity(0.3),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(
                            () => _selectedGenres = Set.from(tempSelected));
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: Text(
                        tempSelected.isEmpty
                            ? 'Show All'
                            : 'Apply (${tempSelected.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final animeList = widget.data ?? anilistAuth.animeList;
    final userName = widget.userName ?? anilistAuth.profileData.value.name;
    final orderedTabs = _isReversed ? tabs.reversed.toList() : tabs;

    if (_tabController == null || _tabController!.length != orderedTabs.length) {
      _tabController?.dispose();
      _tabController = TabController(length: orderedTabs.length, vsync: this);
    }

    return Glow(
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: colors.primary,
              )),
          title: Text("$userName's ${widget.title ?? 'Anime'} List",
                  style: TextStyle(fontSize: 16, color: colors.primary)),
          actions: [
            // Search toggle
            IconButton(
              onPressed: () {
                setState(() {
                  _searchOpen = !_searchOpen;
                  if (!_searchOpen) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                });
              },
              icon: Icon(
                _searchOpen ? Icons.close_rounded : Iconsax.search_normal,
                size: 20,
              ),
              tooltip: _searchOpen ? 'Close search' : 'Search',
            ),
            // Random
            IconButton(
              onPressed: _openRandom,
              icon: const Icon(Iconsax.shuffle, size: 20),
              tooltip: 'Random',
            ),
            // Genre filter
            IconButton(
              onPressed: () => _showGenreFilter(context),
              icon: Badge(
                isLabelVisible: _selectedGenres.isNotEmpty,
                label: Text('${_selectedGenres.length}',
                    style: const TextStyle(fontSize: 9)),
                child: const Icon(Iconsax.filter, size: 20),
              ),
              tooltip: 'Filter genres',
            ),
            // 3-dot menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 22),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (val) {
                switch (val) {
                  case 'sort':
                    _showSortMenu(context);
                    break;
                  case 'reverse_tabs':
                    setState(() {
                      _isReversed = !_isReversed;
                      _initTabController();
                    });
                    break;
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'sort',
                  child: Row(
                    children: [
                      Icon(Icons.sort_rounded,
                          size: 20, color: colors.onSurfaceVariant),
                      const SizedBox(width: 12),
                      const Text('Sort'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'reverse_tabs',
                  child: Row(
                    children: [
                      Icon(Iconsax.arrow_swap_horizontal,
                          size: 20, color: colors.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Text(_isReversed ? 'Default tab order' : 'Reverse tabs'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(_searchOpen ? 90 : 46),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchOpen)
                  Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Icon(Iconsax.search_normal,
                            size: 18,
                            color: colors.onSurfaceVariant.withOpacity(0.5)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: TextStyle(
                                color: colors.onSurface, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search anime...',
                              hintStyle: TextStyle(
                                  color: colors.onSurfaceVariant
                                      .withOpacity(0.4),
                                  fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(Icons.close_rounded,
                                  size: 18,
                                  color: colors.onSurfaceVariant),
                            ),
                          )
                        else
                          const SizedBox(width: 14),
                      ],
                    ),
                  ),
                TabBar(
                  controller: _tabController,
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  tabAlignment: TabAlignment.start,
                  isScrollable: true,
                  dividerColor: Colors.transparent,
                  unselectedLabelColor: Colors.grey,
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 14),
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: orderedTabs.map((tab) {
                    final filtered =
                        _applyFilters(_getFilteredList(animeList, tab));
                    final label =
                        '${tab.toUpperCase()} (${filtered.length})';
                    return Tab(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 300),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: orderedTabs.map((tab) {
            final items =
                _applyFilters(_getFilteredList(animeList, tab));

            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.document,
                        size: 40,
                        color: colors.onSurfaceVariant.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isNotEmpty || _selectedGenres.isNotEmpty
                          ? 'No matches found'
                          : 'No entries in $tab',
                      style: TextStyle(
                          color:
                              colors.onSurfaceVariant.withOpacity(0.6)),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(10),
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: getResponsiveCrossAxisVal(
                      MediaQuery.of(context).size.width,
                      itemWidth: 108),
                  mainAxisExtent: 250,
                  crossAxisSpacing: 10),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GridAnimeCard(data: item, isManga: false);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
