import 'package:anymex/screens/search/widgets/search_filter_selector.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

void showFilterBottomSheet(
    BuildContext context, Function(dynamic args) onApplyFilter,
    {Map<String, dynamic>? currentFilters, String mediaType = 'anime'}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return FuturisticFilterSheet(
        onApplyFilter: onApplyFilter,
        currentFilters: currentFilters,
        mediaType: mediaType,
      );
    },
  );
}

class FuturisticFilterSheet extends StatefulWidget {
  const FuturisticFilterSheet({
    super.key,
    required this.onApplyFilter,
    this.currentFilters,
    this.mediaType = 'anime',
  });

  final Function(dynamic args) onApplyFilter;
  final Map<String, dynamic>? currentFilters;
  final String mediaType;

  @override
  State<FuturisticFilterSheet> createState() => _FuturisticFilterSheetState();
}

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

  final List<String> animeStatuses = [
    'FINISHED',
    'RELEASING',
    'NOT_YET_RELEASED',
    'CANCELLED',
  ];
  final Map<String, String> animeStatusLabels = {
    'FINISHED': 'Finished',
    'RELEASING': 'Airing',
    'NOT_YET_RELEASED': 'Not Yet Aired',
    'CANCELLED': 'Cancelled',
  };

  final List<String> mangaStatuses = [
    'FINISHED',
    'RELEASING',
    'NOT_YET_RELEASED',
    'HIATUS',
    'CANCELLED',
  ];
  final Map<String, String> mangaStatusLabels = {
    'FINISHED': 'Finished',
    'RELEASING': 'Releasing',
    'NOT_YET_RELEASED': 'Not Yet Released',
    'HIATUS': 'Hiatus',
    'CANCELLED': 'Cancelled',
  };

  final List<String> animeFormats = [
    'TV',
    'TV_SHORT',
    'MOVIE',
    'SPECIAL',
    'OVA',
    'ONA',
    'MUSIC',
  ];
  final Map<String, String> animeFormatLabels = {
    'TV': 'TV Show',
    'TV_SHORT': 'TV Short',
    'MOVIE': 'Movie',
    'SPECIAL': 'Special',
    'OVA': 'OVA',
    'ONA': 'ONA',
    'MUSIC': 'Music',
  };

  final List<String> mangaFormats = ['MANGA', 'NOVEL', 'ONE_SHOT'];
  final Map<String, String> mangaFormatLabels = {
    'MANGA': 'Manga',
    'NOVEL': 'Light Novel',
    'ONE_SHOT': 'One Shot',
  };

  final Map<String, String> countryOptions = {
    'JP': 'Japan',
    'KR': 'South Korea',
    'CN': 'China',
    'TW': 'Taiwan',
  };

  final Map<String, int> animeStreamingServices = {
    'Crunchyroll': 5,
    'Hulu': 7,
    'Netflix': 10,
    'YouTube': 13,
    'HIDIVE': 20,
    'Amazon Prime Video': 21,
    'Vimeo': 22,
    'RetroCrush': 27,
    'Adult Swim': 28,
    'Japanese Film Archives': 29,
    'Tubi TV': 30,
    'Crackle': 31,
    'AsianCrush': 32,
    'Midnight Pulp': 33,
    'Bilibili': 45,
    'Disney Plus': 118,
    'Bilibili TV': 119,
    'Tencent Video': 121,
    'iQ': 122,
    'Youku': 126,
    'WeTV': 131,
    'Niconico Video': 180,
    'iQIYI': 204,
    'Star+': 210,
    'Max': 211,
    'Viki': 214,
    'Cineverse': 216,
    'Youku TV': 218,
    'Coolmic': 226,
    'Criterion Channel': 230,
    'Hoopla': 239,
    'Laftel': 245,
    'OceanVeil': 249,
    'Apple TV+': 250,
    'Bandai Channel': 251,
    'Prime Video': 261,
  };

  final List<String> genres = [
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

  final List<String> allTags = [
    '4-koma', 'Achromatic', 'Achronological Order', 'Acrobatics', 'Acting',
    'Adoption', 'Advertisement', 'Afterlife', 'Age Gap', 'Age Regression',
    'Agender', 'Agriculture', 'Airsoft', 'Alchemy', 'Aliens',
    'Alternate Universe', 'American Football', 'Amnesia', 'Anachronism',
    'Ancient China', 'Angels', 'Animals', 'Anthology', 'Anthropomorphism',
    'Anti-Hero', 'Archery', 'Aromantic', 'Arranged Marriage',
    'Artificial Intelligence', 'Asexual', 'Assassins', 'Astronomy',
    'Athletics', 'Augmented Reality', 'Autobiographical', 'Aviation',
    'Badminton', 'Ballet', 'Bar', 'Band', 'Baseball', 'Basketball',
    'Battle Royale', 'Biographical', 'Bisexual', 'Blackmail', 'Board Game',
    'Boarding School', 'Body Horror', 'Body Image', 'Body Swapping', 'Bowling',
    'Boxing', 'Boys\' Love', 'Bullying', 'Butler', 'Calligraphy', 'Camping',
    'Cannibalism', 'Card Battle', 'Cars', 'Centaur', 'CGI', 'Cheerleading',
    'Chibi', 'Chimera', 'Chuunibyou', 'Circus', 'Class Struggle',
    'Classic Literature', 'Classical Music', 'Clone', 'Coastal', 'Cohabitation',
    'College', 'Coming of Age', 'Conspiracy', 'Cosmic Horror', 'Cosplay',
    'Cowboys', 'Creature Taming', 'Crime', 'Criminal Organization',
    'Crossdressing', 'Crossover', 'Cult', 'Cultivation', 'Curses',
    'Cute Boys Doing Cute Things', 'Cute Girls Doing Cute Things', 'Cyberpunk',
    'Cyborg', 'Cycling', 'Dancing', 'Death Game', 'Delinquents', 'Demons',
    'Denpa', 'Desert', 'Detective', 'Dinosaurs', 'Disability',
    'Dissociative Identities', 'Dragons', 'Drawing', 'Drugs', 'Dullahan',
    'Dungeon', 'Dystopian', 'E-Sports', 'Eco-Horror', 'Economics',
    'Educational', 'Elderly Protagonist', 'Elf', 'Ensemble Cast',
    'Environmental', 'Episodic', 'Ero Guro', 'Espionage', 'Estranged Family',
    'Exorcism', 'Fairy', 'Fairy Tale', 'Fake Relationship', 'Family Life',
    'Fashion', 'Female Harem', 'Female Protagonist', 'Femboy', 'Fencing',
    'Filmmaking', 'Firefighters', 'Fishing', 'Fitness', 'Flash', 'Food',
    'Football', 'Foreign', 'Found Family', 'Fugitive', 'Full CGI', 'Full Color',
    'Gambling', 'Gangs', 'Gender Bending', 'Ghost', 'Go', 'Goblin', 'Gods',
    'Golf', 'Gore', 'Guns', 'Gyaru', 'Handball', 'Henshin', 'Heterosexual',
    'Hikikomori', 'Hip-hop Music', 'Historical', 'Homeless', 'Horticulture',
    'Ice Skating', 'Idol', 'Indigenous Cultures', 'Inn', 'Isekai', 'Iyashikei',
    'Jazz Music', 'Josei', 'Judo', 'Kabuki', 'Kaiju', 'Karuta', 'Kemonomimi',
    'Kids', 'Kingdom Management', 'Konbini', 'Kuudere', 'Lacrosse',
    'Language Barrier', 'LGBTQ+ Themes', 'Long Strip', 'Lost Civilization',
    'Love Triangle', 'Mafia', 'Magic', 'Mahjong', 'Maids', 'Makeup',
    'Male Harem', 'Male Protagonist', 'Manzai', 'Marriage', 'Martial Arts',
    'Matchmaking', 'Matriarchy', 'Medicine', 'Medieval', 'Memory Manipulation',
    'Mermaid', 'Meta', 'Metal Music', 'Military', 'Mixed Gender Harem',
    'Mixed Media', 'Modeling', 'Monster Boy', 'Monster Girl', 'Mopeds',
    'Motorcycles', 'Mountaineering', 'Musical Theater', 'Mythology',
    'Natural Disaster', 'Necromancy', 'Nekomimi', 'Ninja', 'No Dialogue',
    'Noir', 'Non-fiction', 'Nudity', 'Nun', 'Office', 'Office Lady', 'Oiran',
    'Ojou-sama', 'Orphan', 'Otaku Culture', 'Outdoor Activities', 'Pandemic',
    'Parenthood', 'Parkour', 'Parody', 'Philosophy', 'Photography', 'Pirates',
    'Poker', 'Police', 'Politics', 'Polyamorous', 'Post-Apocalyptic', 'POV',
    'Pregnancy', 'Primarily Adult Cast', 'Primarily Animal Cast',
    'Primarily Child Cast', 'Primarily Female Cast', 'Primarily Male Cast',
    'Primarily Teen Cast', 'Prison', 'Proxy Battle', 'Psychosexual', 'Puppetry',
    'Rakugo', 'Real Robot', 'Rehabilitation', 'Reincarnation', 'Religion',
    'Rescue', 'Restaurant', 'Revenge', 'Reverse Isekai', 'Robots', 'Rock Music',
    'Rotoscoping', 'Royal Affairs', 'Rugby', 'Rural', 'Samurai', 'Satire',
    'School', 'School Club', 'Scuba Diving', 'Seinen', 'Shapeshifting', 'Ships',
    'Shogi', 'Shoujo', 'Shounen', 'Shrine Maiden', 'Skateboarding', 'Skeleton',
    'Slapstick', 'Slavery', 'Snowscape', 'Software Development', 'Space',
    'Space Opera', 'Spearplay', 'Steampunk', 'Stop Motion', 'Succubus',
    'Suicide', 'Sumo', 'Super Power', 'Super Robot', 'Superhero', 'Surfing',
    'Surreal Comedy', 'Survival', 'Swimming', 'Swordplay', 'Table Tennis',
    'Tanks', 'Tanned Skin', 'Teacher', 'Teens\' Love', 'Tennis', 'Terrorism',
    'Time Loop', 'Time Manipulation', 'Time Skip', 'Tokusatsu', 'Tomboy',
    'Torture', 'Tragedy', 'Trains', 'Transgender', 'Travel', 'Triads',
    'Tsundere', 'Twins', 'Unrequited Love', 'Urban', 'Urban Fantasy', 'Vampire',
    'Vertical Video', 'Veterinarian', 'Video Games', 'Vikings', 'Villainess',
    'Virtual World', 'Vocal Synth', 'Volleyball', 'VTuber', 'War', 'Werewolf',
    'Wilderness', 'Witch', 'Work', 'Wrestling', 'Writing', 'Wuxia', 'Yakuza',
    'Yandere', 'Youkai', 'Yuri', 'Zombie',
  ];

  // State
  String? selectedSortBy;
  String? selectedSortType;
  String? selectedSeason;
  String? selectedStatus;
  List<String> selectedFormats = [];
  List<String> selectedGenres = [];
  List<String> selectedTags = [];
  String? selectedCountry;
  List<int> selectedStreamingOn = [];
  int? selectedYear;
  RangeValues yearRange = const RangeValues(1940, 2027);
  bool useYearRange = false;
  RangeValues episodeRange = const RangeValues(0, 150);
  bool useEpisodeRange = false;
  RangeValues durationRange = const RangeValues(0, 170);
  bool useDurationRange = false;
  RangeValues chaptersRange = const RangeValues(0, 500);
  bool useChaptersRange = false;
  RangeValues volumesRange = const RangeValues(0, 50);
  bool useVolumesRange = false;
  bool showAdult = false;
  bool showDoujin = false;
  bool onlyShowMine = false;
  bool hideMine = false;

  List<String> get formats =>
      widget.mediaType == 'manga' ? mangaFormats : animeFormats;
  Map<String, String> get formatLabels =>
      widget.mediaType == 'manga' ? mangaFormatLabels : animeFormatLabels;
  List<String> get statuses =>
      widget.mediaType == 'manga' ? mangaStatuses : animeStatuses;
  Map<String, String> get statusLabels =>
      widget.mediaType == 'manga' ? mangaStatusLabels : animeStatusLabels;
  bool get isManga => widget.mediaType == 'manga';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentFilters();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideController.forward();
    _fadeController.forward();
  }

  void _loadCurrentFilters() {
    if (widget.currentFilters != null) {
      final filters = widget.currentFilters!;

      String? currentSort = filters['sort'];
      if (currentSort != null) {
        for (String sortKey in sortOptions.keys) {
          if (sortOptions[sortKey]!['desc'] == currentSort) {
            selectedSortBy = sortKey;
            selectedSortType = 'desc';
            break;
          } else if (sortOptions[sortKey]!['asc'] == currentSort) {
            selectedSortBy = sortKey;
            selectedSortType = 'asc';
            break;
          }
        }
      }

      selectedSeason = filters['season'];
      selectedStatus = filters['status'];
      selectedCountry = filters['country'];
      selectedYear = filters['year'];
      showAdult = filters['adult'] ?? false;
      showDoujin = filters['doujin'] ?? false;
      onlyShowMine = filters['onlyShowMine'] ?? false;
      hideMine = filters['hideMine'] ?? false;

      if (filters['formats'] is List) {
        selectedFormats = List<String>.from(filters['formats']);
      }
      if (filters['genres'] != null && filters['genres'] is List) {
        selectedGenres = List<String>.from(filters['genres']);
      }
      if (filters['tags'] is List) {
        selectedTags = List<String>.from(filters['tags']);
      }
      if (filters['streamingOn'] is List) {
        selectedStreamingOn = List<int>.from(filters['streamingOn']);
      }
      if (filters['yearRange'] is List &&
          (filters['yearRange'] as List).length == 2) {
        yearRange = RangeValues(
          (filters['yearRange'][0] as num).toDouble(),
          (filters['yearRange'][1] as num).toDouble(),
        );
        useYearRange = true;
      }
      if (filters['episodeRange'] is List &&
          (filters['episodeRange'] as List).length == 2) {
        episodeRange = RangeValues(
          (filters['episodeRange'][0] as num).toDouble(),
          (filters['episodeRange'][1] as num).toDouble(),
        );
        useEpisodeRange = true;
      }
      if (filters['durationRange'] is List &&
          (filters['durationRange'] as List).length == 2) {
        durationRange = RangeValues(
          (filters['durationRange'][0] as num).toDouble(),
          (filters['durationRange'][1] as num).toDouble(),
        );
        useDurationRange = true;
      }
      if (filters['chaptersRange'] is List &&
          (filters['chaptersRange'] as List).length == 2) {
        chaptersRange = RangeValues(
          (filters['chaptersRange'][0] as num).toDouble(),
          (filters['chaptersRange'][1] as num).toDouble(),
        );
        useChaptersRange = true;
      }
      if (filters['volumesRange'] is List &&
          (filters['volumesRange'] as List).length == 2) {
        volumesRange = RangeValues(
          (filters['volumesRange'][0] as num).toDouble(),
          (filters['volumesRange'][1] as num).toDouble(),
        );
        useVolumesRange = true;
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: colorScheme.primary.opaque(0.2, iReallyMeanIt: true),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSortSection(),
                          const SizedBox(height: 24),
                          _buildFiltersSection(),
                          const SizedBox(height: 24),
                          _buildYearSection(),
                          const SizedBox(height: 24),
                          if (!isManga) _buildAnimeRangeSection(),
                          if (isManga) _buildMangaRangeSection(),
                          const SizedBox(height: 24),
                          _buildGenresSection(),
                          const SizedBox(height: 24),
                          _buildTagsSection(),
                          const SizedBox(height: 24),
                          if (!isManga) ...[
                            _buildStreamingSection(),
                            const SizedBox(height: 24),
                          ],
                          _buildTogglesSection(),
                          const SizedBox(height: 32),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.primary.opaque(0.1, iReallyMeanIt: true),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'FILTERS',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primary.opaque(0.1, iReallyMeanIt: true),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('SORT', Icons.sort_rounded),
        Row(
          children: [
            Expanded(flex: 3, child: _buildSortSelector()),
            const SizedBox(width: 12),
            _buildSortDirectionToggle(),
          ],
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('FILTERS', Icons.filter_list_rounded),
        Row(
          children: [
            if (!isManga) ...[
              Expanded(
                child: _buildNeonSelector(
                  hint: 'Season',
                  value: selectedSeason,
                  options: seasons,
                  optionLabels: {
                    'WINTER': '❄️ Winter',
                    'SPRING': '🌸 Spring',
                    'SUMMER': '☀️ Summer',
                    'FALL': '🍂 Fall',
                  },
                  onChanged: (value) => setState(() => selectedSeason = value),
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: _buildNeonSelector(
                hint: isManga ? 'Publishing Status' : 'Airing Status',
                value: selectedStatus,
                options: statuses,
                optionLabels: statusLabels,
                onChanged: (value) => setState(() => selectedStatus = value),
                icon: Icons.info_outline_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isManga) ...[
          _buildNeonSelector(
            hint: 'Country of Origin',
            value: selectedCountry,
            options: countryOptions.keys.toList(),
            optionLabels: countryOptions,
            onChanged: (value) => setState(() => selectedCountry = value),
            icon: Icons.flag_rounded,
          ),
          const SizedBox(height: 12),
        ],
        _buildSectionHeader('FORMAT', Icons.video_library_rounded),
        _buildMultiFormatChips(),
      ],
    );
  }

  Widget _buildMultiFormatChips() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: formats.map((fmt) {
        final isSelected = selectedFormats.contains(fmt);
        final label = formatLabels[fmt] ?? fmt;
        return GestureDetector(
          onTap: () => setState(() => isSelected
              ? selectedFormats.remove(fmt)
              : selectedFormats.add(fmt)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.opaque(0.3, iReallyMeanIt: true),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? colorScheme.primary.opaque(0.12, iReallyMeanIt: true)
                  : Colors.transparent,
            ),
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.opaque(0.7, iReallyMeanIt: true),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildYearSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('YEAR', Icons.date_range_rounded),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Use Year Range',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            Switch(
              value: useYearRange,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (v) => setState(() {
                useYearRange = v;
                if (v) selectedYear = null;
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!useYearRange)
          _buildNeonSelector(
            hint: 'Year',
            value: selectedYear?.toString(),
            options: List.generate(
                    2027 - 1940 + 1, (i) => (1940 + i).toString())
                .reversed
                .toList(),
            optionLabels: {},
            onChanged: (v) =>
                setState(() => selectedYear = v != null ? int.parse(v) : null),
            icon: Icons.calendar_month_rounded,
          )
        else
          _buildRangeSlider(
            label:
                '${yearRange.start.toInt()} – ${yearRange.end.toInt() >= 2027 ? "2027+" : yearRange.end.toInt()}',
            values: yearRange,
            min: 1940,
            max: 2027,
            divisions: 2027 - 1940,
            onChanged: (v) => setState(() => yearRange = v),
          ),
      ],
    );
  }

  Widget _buildAnimeRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            'EPISODES & DURATION', Icons.play_circle_outline_rounded),
        _buildSwitchRow(
          label: 'Filter by Episode Count',
          value: useEpisodeRange,
          onChanged: (v) => setState(() => useEpisodeRange = v),
        ),
        if (useEpisodeRange) ...[
          const SizedBox(height: 8),
          _buildRangeSlider(
            label:
                '${episodeRange.start.toInt()} – ${episodeRange.end.toInt() >= 150 ? "150+" : episodeRange.end.toInt()} eps',
            values: episodeRange,
            min: 0,
            max: 150,
            divisions: 150,
            onChanged: (v) => setState(() => episodeRange = v),
          ),
        ],
        const SizedBox(height: 12),
        _buildSwitchRow(
          label: 'Filter by Duration (min)',
          value: useDurationRange,
          onChanged: (v) => setState(() => useDurationRange = v),
        ),
        if (useDurationRange) ...[
          const SizedBox(height: 8),
          _buildRangeSlider(
            label:
                '${durationRange.start.toInt()} – ${durationRange.end.toInt() >= 170 ? "170+" : durationRange.end.toInt()} min',
            values: durationRange,
            min: 0,
            max: 170,
            divisions: 170,
            onChanged: (v) => setState(() => durationRange = v),
          ),
        ],
      ],
    );
  }

  Widget _buildMangaRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('CHAPTERS & VOLUMES', Icons.menu_book_rounded),
        _buildSwitchRow(
          label: 'Filter by Chapter Count',
          value: useChaptersRange,
          onChanged: (v) => setState(() => useChaptersRange = v),
        ),
        if (useChaptersRange) ...[
          const SizedBox(height: 8),
          _buildRangeSlider(
            label:
                '${chaptersRange.start.toInt()} – ${chaptersRange.end.toInt() >= 500 ? "500+" : chaptersRange.end.toInt()} chapters',
            values: chaptersRange,
            min: 0,
            max: 500,
            divisions: 100,
            onChanged: (v) => setState(() => chaptersRange = v),
          ),
        ],
        const SizedBox(height: 12),
        _buildSwitchRow(
          label: 'Filter by Volume Count',
          value: useVolumesRange,
          onChanged: (v) => setState(() => useVolumesRange = v),
        ),
        if (useVolumesRange) ...[
          const SizedBox(height: 8),
          _buildRangeSlider(
            label:
                '${volumesRange.start.toInt()} – ${volumesRange.end.toInt() >= 50 ? "50+" : volumesRange.end.toInt()} volumes',
            values: volumesRange,
            min: 0,
            max: 50,
            divisions: 50,
            onChanged: (v) => setState(() => volumesRange = v),
          ),
        ],
      ],
    );
  }

  Widget _buildGenresSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('GENRES', Icons.category_rounded),
        Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.opaque(0.3, iReallyMeanIt: true),
              width: 1,
            ),
            color: colorScheme.surface.opaque(0.5, iReallyMeanIt: true),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SuperListView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              children: genres.map((genre) => _buildGenreChip(genre)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenreChip(String genre) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = selectedGenres.contains(genre);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(
          genre,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
        selected: isSelected,
        checkmarkColor: colorScheme.onPrimary,
        selectedColor: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.opaque(0.3),
          width: 1,
        ),
        onSelected: (selected) {
          setState(() {
            selected ? selectedGenres.add(genre) : selectedGenres.remove(genre);
          });
        },
      ),
    );
  }

  Widget _buildTagsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasSelected = selectedTags.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('TAGS', Icons.label_rounded),
        if (hasSelected) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: selectedTags
                .map((t) => Chip(
                      label: Text(t,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600)),
                      backgroundColor: colorScheme.primary,
                      deleteIconColor: colorScheme.onPrimary,
                      onDeleted: () => setState(() => selectedTags.remove(t)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: _buildTappableBox(
            isActive: hasSelected,
            onTap: _showTagsSheet,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded,
                    size: 20,
                    color: hasSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface
                            .opaque(0.7, iReallyMeanIt: true)),
                const SizedBox(width: 8),
                Text(
                  hasSelected
                      ? 'Edit Tags (${selectedTags.length})'
                      : 'Add Tags',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasSelected
                        ? colorScheme.onSurface
                        : colorScheme.onSurface
                            .opaque(0.5, iReallyMeanIt: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreamingSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasSelected = selectedStreamingOn.isNotEmpty;
    final selectedNames = animeStreamingServices.entries
        .where((e) => selectedStreamingOn.contains(e.value))
        .map((e) => e.key)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('STREAMING ON', Icons.live_tv_rounded),
        if (hasSelected) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: selectedNames
                .map((name) => Chip(
                      label: Text(name,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600)),
                      backgroundColor: colorScheme.primary,
                      deleteIconColor: colorScheme.onPrimary,
                      onDeleted: () => setState(() => selectedStreamingOn
                          .remove(animeStreamingServices[name]!)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: _buildTappableBox(
            isActive: hasSelected,
            onTap: _showStreamingSheet,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded,
                    size: 20,
                    color: hasSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface
                            .opaque(0.7, iReallyMeanIt: true)),
                const SizedBox(width: 8),
                Text(
                  hasSelected
                      ? 'Edit Services (${selectedStreamingOn.length})'
                      : 'Select Streaming Service',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasSelected
                        ? colorScheme.onSurface
                        : colorScheme.onSurface
                            .opaque(0.5, iReallyMeanIt: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTogglesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('OPTIONS', Icons.toggle_on_rounded),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildToggleChip(
                label: '🔞 Adult',
                value: showAdult,
                onTap: () => setState(() => showAdult = !showAdult)),
            _buildToggleChip(
                label: '📚 Doujin',
                value: showDoujin,
                onTap: () => setState(() => showDoujin = !showDoujin)),
            _buildToggleChip(
                label: isManga ? '📖 My Manga Only' : '📺 My Anime Only',
                value: onlyShowMine,
                onTap: () => setState(() {
                      onlyShowMine = !onlyShowMine;
                      if (onlyShowMine) hideMine = false;
                    })),
            _buildToggleChip(
                label: isManga ? '🚫 Hide My Manga' : '🚫 Hide My Anime',
                value: hideMine,
                onTap: () => setState(() {
                      hideMine = !hideMine;
                      if (hideMine) onlyShowMine = false;
                    })),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? colorScheme.primary
                : colorScheme.outline.opaque(0.3, iReallyMeanIt: true),
            width: value ? 2 : 1,
          ),
          color: value
              ? colorScheme.primary.opaque(0.1, iReallyMeanIt: true)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.check_circle_rounded,
                    size: 16, color: colorScheme.primary),
              ),
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: value
                        ? colorScheme.primary
                        : colorScheme.onSurface
                            .opaque(0.7, iReallyMeanIt: true))),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────

  Widget _buildTappableBox({
    required bool isActive,
    required Widget child,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? colorScheme.primary.opaque(0.6, iReallyMeanIt: true)
              : colorScheme.outline.opaque(0.3, iReallyMeanIt: true),
          width: isActive ? 2 : 1,
        ),
        color: isActive
            ? colorScheme.primary.opaque(0.05, iReallyMeanIt: true)
            : colorScheme.surface.opaque(0.5, iReallyMeanIt: true),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  Widget _buildRangeSlider({
    required String label,
    required RangeValues values,
    required double min,
    required double max,
    required int divisions,
    required Function(RangeValues) onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary, fontWeight: FontWeight.w700)),
        ),
        RangeSlider(
          values: values,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: colorScheme.primary,
          inactiveColor: colorScheme.primary.opaque(0.2, iReallyMeanIt: true),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        Switch(
            value: value,
            activeColor: colorScheme.primary,
            onChanged: onChanged),
      ],
    );
  }

  Widget _buildNeonSelector({
    required String hint,
    required String? value,
    required List<String> options,
    required Map<String, String> optionLabels,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasValue = value != null;
    final displayLabel =
        hasValue ? (optionLabels[value] ?? value) : 'Select $hint';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasValue
              ? colorScheme.primary.opaque(0.6, iReallyMeanIt: true)
              : colorScheme.outline.opaque(0.3, iReallyMeanIt: true),
          width: hasValue ? 2 : 1,
        ),
        color: hasValue
            ? colorScheme.primary.opaque(0.05, iReallyMeanIt: true)
            : colorScheme.surface.opaque(0.5, iReallyMeanIt: true),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showNeonBottomSheet(
            title: hint,
            options: options,
            optionLabels: optionLabels,
            selectedValue: value,
            onSelected: onChanged,
            icon: icon,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: hasValue
                      ? colorScheme.primary
                      : colorScheme.onSurface.opaque(0.7, iReallyMeanIt: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hint.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface
                              .opaque(0.7, iReallyMeanIt: true),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: hasValue
                              ? colorScheme.onSurface
                              : colorScheme.onSurface
                                  .opaque(0.5, iReallyMeanIt: true),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colorScheme.onSurface.opaque(0.6, iReallyMeanIt: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasValue = selectedSortBy != null;
    final displayText =
        hasValue ? sortOptions[selectedSortBy!]!['label']! : 'Select Sort';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasValue
              ? colorScheme.primary.opaque(0.6, iReallyMeanIt: true)
              : colorScheme.outline.opaque(0.3, iReallyMeanIt: true),
          width: hasValue ? 2 : 1,
        ),
        color: hasValue
            ? colorScheme.primary.opaque(0.05, iReallyMeanIt: true)
            : colorScheme.surface.opaque(0.5, iReallyMeanIt: true),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _showSortBottomSheet,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.sort_rounded,
                  size: 20,
                  color: hasValue
                      ? colorScheme.primary
                      : colorScheme.onSurface.opaque(0.7, iReallyMeanIt: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SORT BY',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.opaque(0.7),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: hasValue
                              ? colorScheme.onSurface
                              : colorScheme.onSurface
                                  .opaque(0.5, iReallyMeanIt: true),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colorScheme.onSurface.opaque(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortDirectionToggle() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDescending = selectedSortType == 'desc';
    final isActive = selectedSortBy != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? colorScheme.primary.opaque(0.6, iReallyMeanIt: true)
              : colorScheme.outline.opaque(0.3, iReallyMeanIt: true),
          width: isActive ? 2 : 1,
        ),
        color: isActive
            ? colorScheme.primary.opaque(0.05, iReallyMeanIt: true)
            : colorScheme.surface.opaque(0.5, iReallyMeanIt: true),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isActive
              ? () => setState(
                  () => selectedSortType = isDescending ? 'asc' : 'desc')
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'ORDER',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        colorScheme.onSurface.opaque(0.7, iReallyMeanIt: true),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDescending
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 16,
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurface
                              .opaque(0.5, iReallyMeanIt: true),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDescending ? 'DESC' : 'ASC',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? colorScheme.onSurface
                            : colorScheme.onSurface
                                .opaque(0.5, iReallyMeanIt: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: _buildNeonButton(
            text: 'RESET',
            icon: Icons.refresh_rounded,
            isPrimary: false,
            onTap: _resetFilters,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildNeonButton(
            text: 'APPLY FILTERS',
            icon: Icons.check_rounded,
            isPrimary: true,
            onTap: _applyFilters,
          ),
        ),
      ],
    );
  }

  Widget _buildNeonButton({
    required String text,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary
              ? colorScheme.primary
              : colorScheme.outline.opaque(0.5, iReallyMeanIt: true),
          width: 2,
        ),
        color: isPrimary ? colorScheme.primary : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color:
                      isPrimary ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isPrimary
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    _showNeonBottomSheet(
      title: 'Sort By',
      options: sortOptions.keys.toList(),
      optionLabels: {},
      selectedValue: selectedSortBy,
      onSelected: (value) {
        setState(() {
          selectedSortBy = value;
          selectedSortType ??= 'desc';
        });
      },
      icon: Icons.sort_rounded,
    );
  }

  void _showTagsSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final TextEditingController searchCtrl = TextEditingController();
    List<String> filtered = List.from(allTags);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
                color: colorScheme.primary.opaque(0.3, iReallyMeanIt: true),
                width: 1),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.label_rounded,
                            color: colorScheme.primary, size: 24),
                        const SizedBox(width: 8),
                        Text('SELECT TAGS',
                            style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: colorScheme.onSurface)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchCtrl,
                      onChanged: (q) => setModalState(() {
                        filtered = allTags
                            .where((t) =>
                                t.toLowerCase().contains(q.toLowerCase()))
                            .toList();
                      }),
                      decoration: InputDecoration(
                        hintText: 'Search tags...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final tag = filtered[i];
                    final isSelected = selectedTags.contains(tag);
                    return CheckboxListTile(
                      title: Text(tag,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500)),
                      value: isSelected,
                      activeColor: colorScheme.primary,
                      onChanged: (v) => setModalState(() => setState(() => v ==
                              true
                          ? selectedTags.add(tag)
                          : selectedTags.remove(tag))),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: _buildNeonButton(
                  text: 'DONE (${selectedTags.length} selected)',
                  icon: Icons.check_rounded,
                  isPrimary: true,
                  onTap: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStreamingSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
                color: colorScheme.primary.opaque(0.3, iReallyMeanIt: true),
                width: 1),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.live_tv_rounded,
                            color: colorScheme.primary, size: 24),
                        const SizedBox(width: 8),
                        Text('STREAMING ON',
                            style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: colorScheme.onSurface)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: animeStreamingServices.entries
                      .map((entry) => CheckboxListTile(
                            title: Text(entry.key,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500)),
                            value:
                                selectedStreamingOn.contains(entry.value),
                            activeColor: colorScheme.primary,
                            onChanged: (v) =>
                                setModalState(() => setState(() => v == true
                                    ? selectedStreamingOn.add(entry.value)
                                    : selectedStreamingOn
                                        .remove(entry.value))),
                          ))
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: _buildNeonButton(
                  text: 'DONE',
                  icon: Icons.check_rounded,
                  isPrimary: true,
                  onTap: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNeonBottomSheet({
    required String title,
    required List<String> options,
    required Map<String, String> optionLabels,
    required String? selectedValue,
    required Function(String?) onSelected,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: colorScheme.primary.opaque(0.3, iReallyMeanIt: true),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.opaque(0.1, iReallyMeanIt: true),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          colorScheme.primary.opaque(0.2, iReallyMeanIt: true),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary
                                .opaque(0.5, iReallyMeanIt: true),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary
                                .opaque(0.1, iReallyMeanIt: true),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primary
                                  .opaque(0.3, iReallyMeanIt: true),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          title.toUpperCase(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (selectedValue != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: FutureisticOptionTile(
                    option: '— Clear —',
                    isSelected: false,
                    onTap: () {
                      onSelected(null);
                      Navigator.pop(context);
                    },
                    colorScheme: colorScheme,
                    theme: theme,
                  ),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final label = optionLabels[option] ?? option;
                    final isSelected = selectedValue == option;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FutureisticOptionTile(
                        option: label,
                        isSelected: isSelected,
                        onTap: () {
                          onSelected(option);
                          Navigator.pop(context);
                        },
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _resetFilters() {
    setState(() {
      selectedSortBy = null;
      selectedSortType = null;
      selectedSeason = null;
      selectedStatus = null;
      selectedCountry = null;
      selectedYear = null;
      selectedFormats.clear();
      selectedGenres.clear();
      selectedTags.clear();
      selectedStreamingOn.clear();
      useYearRange = false;
      yearRange = const RangeValues(1940, 2027);
      useEpisodeRange = false;
      episodeRange = const RangeValues(0, 150);
      useDurationRange = false;
      durationRange = const RangeValues(0, 170);
      useChaptersRange = false;
      chaptersRange = const RangeValues(0, 500);
      useVolumesRange = false;
      volumesRange = const RangeValues(0, 50);
      showAdult = false;
      showDoujin = false;
      onlyShowMine = false;
      hideMine = false;
    });
  }

  void _applyFilters() {
    String? finalSort;
    if (selectedSortBy != null && selectedSortType != null) {
      finalSort = sortOptions[selectedSortBy!]![selectedSortType!];
    }

    final Map<String, dynamic> result = {
      'season': selectedSeason,
      'sort': finalSort,
      'formats': selectedFormats.isEmpty ? null : selectedFormats,
      'genres': selectedGenres.isEmpty ? null : selectedGenres,
      'tags': selectedTags.isEmpty ? null : selectedTags,
      'status': selectedStatus,
      'year': useYearRange ? null : selectedYear,
      'country': selectedCountry,
      'adult': showAdult ? true : null,
      'doujin': showDoujin ? true : null,
      'onlyShowMine': onlyShowMine ? true : null,
      'hideMine': hideMine ? true : null,
      'streamingOn': selectedStreamingOn.isEmpty ? null : selectedStreamingOn,
    };

    if (useYearRange && yearRange.end < 2027) {
      result['yearRange'] = [yearRange.start.toInt(), yearRange.end.toInt()];
    }
    if (!isManga) {
      if (useEpisodeRange && episodeRange.end < 150) {
        result['episodeRange'] = [
          episodeRange.start.toInt(),
          episodeRange.end.toInt()
        ];
      }
      if (useDurationRange && durationRange.end < 170) {
        result['durationRange'] = [
          durationRange.start.toInt(),
          durationRange.end.toInt()
        ];
      }
    } else {
      if (useChaptersRange && chaptersRange.end < 500) {
        result['chaptersRange'] = [
          chaptersRange.start.toInt(),
          chaptersRange.end.toInt()
        ];
      }
      if (useVolumesRange && volumesRange.end < 50) {
        result['volumesRange'] = [
          volumesRange.start.toInt(),
          volumesRange.end.toInt()
        ];
      }
    }

    widget.onApplyFilter(result);
    Navigator.pop(context);
  }
}
