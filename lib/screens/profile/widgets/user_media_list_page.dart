import 'dart:math';

import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/media_items/media_item.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

const _animeStandardOrder = [
  'Watching',
  'Completed', 
  'Completed TV', 
  'Completed Movie',
  'Completed OVA',
  'Completed ONA',
  'Completed TV Short',
  'Completed Special',
  'Paused',
  'Dropped',
  'Planning',
  'Rewatching',
];

const _mangaStandardOrder = [
  'Reading',
  'Completed',
  'Completed Manga',
  'Completed Novel',
  'Completed One Shot',
  'Paused',
  'Dropped',
  'Planning',
  'Rereading',
];

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

class UserMediaListPage extends StatefulWidget {
  final int userId;
  final String type;
  final String userName;
  final List<FavouriteMedia>? favourites;
  final List<String> sectionOrder;
  const UserMediaListPage({
    super.key,
    required this.userId,
    required this.type,
    required this.userName,
    this.favourites,
    this.sectionOrder = const [],
  });

  @override
  State<UserMediaListPage> createState() => _UserMediaListPageState();
}

class _UserMediaListPageState extends State<UserMediaListPage>
    with TickerProviderStateMixin {
  Map<String, List<TrackedMedia>> _lists = {};
  bool _loading = true;
  bool _isReversed = false;

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

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _fetchList();
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

  Future<void> _fetchList() async {
    final anilistAuth = Get.find<AnilistAuth>();
    final data =
        await anilistAuth.fetchUserMediaList(widget.userId, widget.type);

    final trackedById = <String, TrackedMedia>{};
    for (final list in data.values) {
      for (final entry in list) {
        final id = (entry.id ?? '').trim();
        if (id.isEmpty || trackedById.containsKey(id)) continue;
        trackedById[id] = entry;
      }
    }

    // Add fav
    if (widget.favourites != null && widget.favourites!.isNotEmpty) {
      final favEntries = widget.favourites!.map((f) {
        final id = (f.id ?? '').trim();
        final tracked = trackedById[id];

        if (tracked != null) {
          return TrackedMedia(
            id: tracked.id,
            title: tracked.title,
            poster: tracked.poster,
            episodeCount: tracked.episodeCount,
            chapterCount: tracked.chapterCount,
            rating: tracked.rating,
            totalEpisodes: tracked.totalEpisodes,
            releasedEpisodes: tracked.releasedEpisodes,
            watchingStatus: tracked.watchingStatus,
            format: tracked.format,
            mediaStatus: tracked.mediaStatus,
            score: tracked.score,
            type: tracked.type,
            mediaListId: tracked.mediaListId,
            servicesType: tracked.servicesType,
            userName: tracked.userName,
            userId: tracked.userId,
            userAvatar: tracked.userAvatar,
            userProgress: tracked.userProgress,
            userScore: tracked.userScore,
            genres: tracked.genres,
            startYear: tracked.startYear,
            updatedAt: tracked.updatedAt,
          );
        }

        return TrackedMedia(
          id: f.id,
          title: f.title,
          poster: f.cover,
          episodeCount: '0',
          totalEpisodes: f.episodes?.toString() ?? '?',
          rating: f.averageScore?.toStringAsFixed(1),
          score: f.averageScore?.toStringAsFixed(1),
        );
      }).toList();
      data['Favourites'] = favEntries;
    }

   
    final genres = <String>{..._anilistGenres};
    for (final list in data.values) {
      for (final entry in list) {
        genres.addAll(entry.genres);
      }
    }

    if (mounted) {
      setState(() {
        _lists = data;
        _allGenres = genres;
        _loading = false;
      });
      _initTabController();
    }
  }

  void _initTabController() {
    _tabController?.dispose();
    final tabs = _isReversed ? _tabNames.reversed.toList() : _tabNames;
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  List<String> get _tabNames {
    final sectionOrder = widget.sectionOrder;
    final fallbackOrder =
        widget.type == 'ANIME' ? _animeStandardOrder : _mangaStandardOrder;
    final order = sectionOrder.isNotEmpty ? sectionOrder : fallbackOrder;
    final sorted = <String>[];
    final remaining = <String>[];
    for (final name in _lists.keys) {
      if (name == 'All' || name == 'Favourites') continue;
      if (order.contains(name)) {
        sorted.add(name);
      } else {
        remaining.add(name);
      }
    }
    
    sorted.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));

    final result = [...sorted, ...remaining];
    if (_lists.containsKey('Favourites')) result.add('Favourites');
    if (_lists.containsKey('All')) result.add('All');
    return result;
  }

  List<TrackedMedia> _applyFilters(List<TrackedMedia> items) {
    var result = items.toList();

    // Search filter
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((e) => (e.title ?? '').toLowerCase().contains(_searchQuery))
          .toList();
    }

    // Genre filter
    if (_selectedGenres.isNotEmpty) {
      result = result
          .where((e) => _selectedGenres.every((g) => e.genres.contains(g)))
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
    final tabs = _isReversed ? _tabNames.reversed.toList() : _tabNames;
    final currentTabName = tabs[_tabController?.index ?? 0];
    final items = _applyFilters(_lists[currentTabName] ?? []);
    if (items.isEmpty) return;
    final random = items[Random().nextInt(items.length)];
    final isManga = widget.type == 'MANGA';
   
    final media = CardData.fromTrackedMedia(random);
    navigate(() => isManga
        ? MangaDetailsPage(media: media.data, tag: media.title)
        : AnimeDetailsPage(media: media.data, tag: media.title));
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
                      color:
                          selected ? colors.primary : colors.onSurfaceVariant),
                  title: Text(label,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? colors.primary : colors.onSurface,
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
    final typeLabel = widget.type == 'ANIME' ? 'Anime' : 'Manga';

    if (_loading) {
      return Glow(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new, color: colors.primary),
            ),
            title: Text(
              "${widget.userName}'s $typeLabel List",
              style: TextStyle(fontSize: 16, color: colors.primary),
            ),
          ),
          body: const Center(child: AnymexProgressIndicator()),
        ),
      );
    }

    if (_lists.isEmpty || _tabNames.isEmpty) {
      return Glow(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new, color: colors.primary),
            ),
            title: Text(
              "${widget.userName}'s $typeLabel List",
              style: TextStyle(fontSize: 16, color: colors.primary),
            ),
          ),
          body: const Center(child: Text('No entries found')),
        ),
      );
    }

    final tabs = _isReversed ? _tabNames.reversed.toList() : _tabNames;

    
    if (_tabController == null || _tabController!.length != tabs.length) {
      _tabController?.dispose();
      _tabController = TabController(length: tabs.length, vsync: this);
    }

    return Glow(
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new, color: colors.primary),
          ),
          title: Text(
            "${widget.userName}'s $typeLabel List",
            style: TextStyle(fontSize: 16, color: colors.primary),
          ),
          actions: [
          
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
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                              hintText: 'Search ${typeLabel.toLowerCase()}...',
                              hintStyle: TextStyle(
                                  color:
                                      colors.onSurfaceVariant.withOpacity(0.4),
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
                                  size: 18, color: colors.onSurfaceVariant),
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
                  labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: tabs.map((name) {
                    final filtered = _applyFilters(_lists[name] ?? []);
                    final label = '${name.toUpperCase()} (${filtered.length})';
                    return Tab(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
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
          children: tabs.map((name) {
            final items = _applyFilters(_lists[name] ?? []);

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
                          : 'No entries in $name',
                      style: TextStyle(
                          color: colors.onSurfaceVariant.withOpacity(0.6)),
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
                  itemWidth: 108,
                ),
                mainAxisExtent: 250,
                crossAxisSpacing: 10,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GridAnimeCard(
                  data: item,
                  isManga: widget.type == 'MANGA',
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
