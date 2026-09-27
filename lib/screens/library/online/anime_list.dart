import 'dart:math';
import 'dart:ui';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/media_items/media_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/services.dart';

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

class _AnimeListState extends State<AnimeList> with TickerProviderStateMixin {
  final anilistAuth = Get.find<ServiceHandler>();
  late final List<String> _allTabs;

  List<TrackedMedia> get activeMediaList {
    final base = widget.data ?? anilistAuth.animeList;
    if (anilistAuth.serviceType.value == ServicesType.simkl && widget.data == null) {
      final combined = [...anilistAuth.animeList, ...anilistAuth.mangaList];
      final seen = <String>{};
      return combined.where((e) => e.id != null && seen.add(e.id!)).toList().removeDupes();
    }
    return base.removeDupes();
  }

  List<String> get tabs {
    final animeList = activeMediaList;
    return _allTabs.where((tab) {
      if (tab == 'ALL') return true;
      return _getFilteredList(animeList, tab).isNotEmpty;
    }).toList();
  }

  final _searchController = TextEditingController();
  String _searchQuery = '';
  late ScrollController _tabScrollController;
  final _selectedTabIndex = ValueNotifier<int>(0);
  final List<GlobalKey> _tabKeys = [];

  _SortMode _sortMode = _SortMode.lastUpdated;
  bool _sortAscending = false;

  Set<String> _allGenres = {};
  Set<String> _selectedGenres = {};

  bool _isReversed = false;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabScrollController = ScrollController();
    final savedSortModeIndex = KvHelper.get<int>('online_anime_sort_mode',
        defaultVal: _SortMode.lastUpdated.index);
    _sortMode = _SortMode.values[savedSortModeIndex];
    _sortAscending =
        KvHelper.get<bool>('online_anime_sort_ascending', defaultVal: false);
    if (widget.initialGenres != null) {
      _selectedGenres = Set.from(widget.initialGenres!);
    }

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

    final sectionOrder = anilistAuth.profileData.value.animeSectionOrder;
    if (sectionOrder.isNotEmpty &&
        anilistAuth.serviceType.value == ServicesType.anilist) {
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
    _tabController?.removeListener(_onTabChanged);
    _tabController?.animation?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _selectedTabIndex.dispose();
    _tabScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted || _tabController == null) return;
    final int newIndex;
    if (_tabController!.indexIsChanging) {
      newIndex = _tabController!.index;
    } else if (_tabController!.animation != null) {
      newIndex = _tabController!.animation!.value.round();
    } else {
      newIndex = _tabController!.index;
    }
    final clampedIndex =
        newIndex.clamp(0, (_tabController!.length - 1).clamp(0, 9999));
    if (clampedIndex != _selectedTabIndex.value) {
      _selectedTabIndex.value = clampedIndex;
      _scrollToTab(clampedIndex);
    }
  }

  void _scrollToTab(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index < 0 || index >= _tabKeys.length) return;
      final keyContext = _tabKeys[index].currentContext;
      if (keyContext != null) {
        Scrollable.ensureVisible(
          keyContext,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _setupTabController(List<String> orderedTabs) {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.animation?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _tabKeys.clear();
    _tabKeys.addAll(List.generate(orderedTabs.length, (_) => GlobalKey()));
    final requestedInitialTab = widget.initialTab;
    final initialIndex = requestedInitialTab == null
        ? 0
        : orderedTabs
            .indexOf(requestedInitialTab)
            .clamp(0, orderedTabs.length - 1);
    _selectedTabIndex.value = initialIndex;
    _tabController = TabController(
      length: orderedTabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController!.addListener(_onTabChanged);
    _tabController!.animation?.addListener(_onTabChanged);
  }

  void _initTabController() {
    final orderedTabs = _isReversed ? tabs.reversed.toList() : tabs;
    _setupTabController(orderedTabs);
  }

  void _collectGenres() {
    final animeList = activeMediaList;
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

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((e) => (e.title ?? '').toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (_selectedGenres.isNotEmpty) {
      result = result
          .where((e) => _selectedGenres.every((g) => e.genres.contains(g)))
          .toList();
    }

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
    final animeList = activeMediaList;
    final items = _applyFilters(_getFilteredList(animeList, currentTabName));
    if (items.isEmpty) return;
    final random = items[Random().nextInt(items.length)];
    final media = CardData.fromTrackedMedia(random);
    navigate(() => AnimeDetailsPage(media: media.data, tag: media.title));
  }

  void _showSortMenu(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    AnymeXSheet.custom(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.sort_rounded, color: colors.primary, size: 20),
                    const SizedBox(width: 10),
                    AnymeXText('Sort By',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Linotte',
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        )),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _sortAscending = !_sortAscending;
                          KvHelper.set(
                              'online_anime_sort_ascending', _sortAscending);
                        });
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        _sortAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 16,
                      ),
                      label: AnymeXText(_sortAscending ? 'Ascending' : 'Descending',
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
                  title: AnymeXText(label,
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
                    setState(() {
                      _sortMode = mode;
                      KvHelper.set('online_anime_sort_mode', _sortMode.index);
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
      context,
      showDragHandle: true,
    );
  }

  void _showGenreFilter(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sortedGenres = _allGenres.toList()..sort();
    final tempSelected = Set<String>.from(_selectedGenres);

    AnymeXSheet.custom(
      StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Icon(Iconsax.filter, color: colors.primary, size: 20),
                  const SizedBox(width: 10),
                  AnymeXText('Filter by Genre',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Linotte',
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      )),
                  const Spacer(),
                  if (tempSelected.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          setSheetState(() => tempSelected.clear()),
                      child:
                          const AnymeXText('Clear', style: TextStyle(fontSize: 12)),
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
                      label: AnymeXText(genre,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    setState(() => _selectedGenres = Set.from(tempSelected));
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: AnymeXText(
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
      context,
      showDragHandle: true,
    );
  }

  BorderRadius _tabBorder(int index, int total, bool isSelected) {
    if (isSelected) {
      return BorderRadius.circular(50.multiplyRadius());
    }
    if (index == 0) {
      return BorderRadius.only(
        topLeft: Radius.circular(16.multiplyRadius()),
        bottomLeft: Radius.circular(16.multiplyRadius()),
        topRight: Radius.circular(5.multiplyRadius()),
        bottomRight: Radius.circular(5.multiplyRadius()),
      );
    }
    if (index == total - 1) {
      return BorderRadius.only(
        topRight: Radius.circular(16.multiplyRadius()),
        bottomRight: Radius.circular(16.multiplyRadius()),
        topLeft: Radius.circular(5.multiplyRadius()),
        bottomLeft: Radius.circular(5.multiplyRadius()),
      );
    }
    return BorderRadius.circular(5.multiplyRadius());
  }

  Widget _buildTabItem(
    BuildContext context, {
    required int index,
    required int total,
    required String tab,
    required int count,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final borderRadius = _tabBorder(index, total, isSelected);

    return AnymexOnTap(
      margin: 0,
      scale: 0.95,
      onTap: () {
        HapticFeedback.lightImpact();
        _tabController?.animateTo(index);
      },
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.opaque(0.18, iReallyMeanIt: true)
                  : theme.colorScheme.surfaceContainer.opaque(0.55),
              borderRadius: borderRadius,
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary.opaque(0.4, iReallyMeanIt: true)
                    : theme.colorScheme.onSurface
                        .opaque(0.08, iReallyMeanIt: true),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.opaque(0.08, iReallyMeanIt: true),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnymeXText(
                  tab.toUpperCase(),
                  variant: isSelected ? TextVariant.bold : TextVariant.semiBold,
                  size: 13,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest
                            .opaque(0.5, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AnymeXText(
                    count.toString(),
                    variant: TextVariant.bold,
                    size: 11,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant.opaque(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabsRow(
    BuildContext context,
    List<String> orderedTabs,
    Map<String, List<TrackedMedia>> tabFilteredItems,
  ) {
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    final h = isDesktop ? 24.0 : 16.0;

    return SizedBox(
      height: 42,
      child: ValueListenableBuilder<int>(
        valueListenable: _selectedTabIndex,
        builder: (context, currentSelected, _) {
          return ListView.separated(
            controller: _tabScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: h),
            itemCount: orderedTabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 3),
            itemBuilder: (context, index) {
              final tab = orderedTabs[index];
              final count = (tabFilteredItems[tab] ?? []).length;
              final isSelected = currentSelected == index;
              return KeyedSubtree(
                key: index < _tabKeys.length ? _tabKeys[index] : null,
                child: _buildTabItem(
                  context,
                  index: index,
                  total: orderedTabs.length,
                  tab: tab,
                  count: count,
                  isSelected: isSelected,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      onSelected: (val) {
        switch (val) {
          case 'shuffle':
            _openRandom();
            break;
          case 'filter':
            _showGenreFilter(context);
            break;
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
          value: 'shuffle',
          child: Row(
            children: [
              Icon(Iconsax.shuffle,
                  size: 20, color: colors.onSurfaceVariant),
              const SizedBox(width: 12),
              const AnymeXText('Random'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'filter',
          child: Row(
            children: [
              Icon(Iconsax.filter,
                  size: 20, color: colors.onSurfaceVariant),
              const SizedBox(width: 12),
              AnymeXText(_selectedGenres.isNotEmpty
                  ? 'Filter genres (${_selectedGenres.length})'
                  : 'Filter genres'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'sort',
          child: Row(
            children: [
              Icon(Icons.sort_rounded,
                  size: 20, color: colors.onSurfaceVariant),
              const SizedBox(width: 12),
              const AnymeXText('Sort'),
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
              AnymeXText(_isReversed ? 'Default tab order' : 'Reverse tabs'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final animeList = activeMediaList;
    final orderedTabs = _isReversed ? tabs.reversed.toList() : tabs;

    if (_tabController == null ||
        _tabController!.length != orderedTabs.length) {
      _setupTabController(orderedTabs);
    }

    final tabFilteredItems = <String, List<TrackedMedia>>{};
    for (final tab in orderedTabs) {
      tabFilteredItems[tab] = _applyFilters(_getFilteredList(animeList, tab));
    }

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: widget.title ?? 'Anime List',
      headerSubtitle: _selectedGenres.isNotEmpty
          ? '${_selectedGenres.length} genre(s) filtered'
          : '${activeMediaList.length} Anime',
      headerEnableSearch: true,
      headerSearchController: _searchController,
      headerSearchHint: 'Search anime...',
      onHeaderSearchChanged: (val) {
        setState(() => _searchQuery = val.trim().toLowerCase());
      },
      onHeaderSearchClear: () {
        setState(() => _searchQuery = '');
      },
      headerAction: _buildHeaderActions(context),
      headerBottom: _buildTabsRow(context, orderedTabs, tabFilteredItems),
      headerBottomHeight: 50.0,
      body: Builder(
        builder: (ctx) {
          final headerHeight = AnymeXHeaderScope.of(ctx);

          return TabBarView(
            controller: _tabController,
            children: orderedTabs.map((tab) {
              final items = tabFilteredItems[tab] ?? [];

              if (items.isEmpty) {
                return Center(
                  key: PageStorageKey<String>('empty-$tab'),
                  child: Padding(
                    padding: EdgeInsets.only(top: headerHeight),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.document,
                            size: 40,
                            color: colors.onSurfaceVariant.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        AnymeXText(
                          _searchQuery.isNotEmpty || _selectedGenres.isNotEmpty
                              ? 'No matches found'
                              : 'No entries in $tab',
                          style: TextStyle(
                              color: colors.onSurfaceVariant.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final crossAxisCount = getResponsiveCrossAxisVal(
                  MediaQuery.sizeOf(context).width,
                  itemWidth: 115);

              return GridView.builder(
                key: PageStorageKey<String>('grid-$tab'),
                padding: EdgeInsets.fromLTRB(10, headerHeight + 10, 10, 10),
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 5,
                    childAspectRatio: getGridCardAspectRatio(
                      context: context,
                      crossAxisCount: crossAxisCount,
                      spacing: 10,
                      padding: 20,
                    )),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return GridAnimeCard(
                    data: item,
                    isManga: false,
                    variant: CardVariant.onlinelist,
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
