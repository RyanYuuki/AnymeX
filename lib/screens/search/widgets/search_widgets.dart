import 'package:anymex/screens/search/widgets/search_filter_selector.dart';
import 'package:flutter/material.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

void showFilterBottomSheet(
    BuildContext context, Function(dynamic args) onApplyFilter,
    {Map<String, dynamic>? currentFilters}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return FuturisticFilterSheet(
        onApplyFilter: onApplyFilter,
        currentFilters: currentFilters,
      );
    },
  );
}

class FuturisticFilterSheet extends StatefulWidget {
  const FuturisticFilterSheet({
    super.key,
    required this.onApplyFilter,
    this.currentFilters,
  });

  final Function(dynamic args) onApplyFilter;
  final Map<String, dynamic>? currentFilters;

  @override
  State<FuturisticFilterSheet> createState() => _FuturisticFilterSheetState();
}

class _FuturisticFilterSheetState extends State<FuturisticFilterSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Data structures
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
  final List<String> formats = [
    'TV',
    'TV SHORT',
    'MOVIE',
    'SPECIAL',
    'OVA',
    'ONA'
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

  // Selected values
  String? selectedSortBy;
  String? selectedSortType;
  String? selectedSeason;
  String? selectedStatus;
  String? selectedFormat;
  List<String> selectedGenres = [];

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

      // Load sort options
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
      selectedFormat = filters['format'];

      if (filters['genres'] != null && filters['genres'] is List) {
        selectedGenres = List<String>.from(filters['genres']);
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
                  color: colorScheme.primary.withOpacity(0.2),
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
                          _buildGenresSection(),
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
            color: colorScheme.primary.withOpacity(0.1),
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
              color: colorScheme.primary.withOpacity(0.1),
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
          icon: Icons.video_library_rounded,
        ),
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
              color: colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
            color: colorScheme.surface.withOpacity(0.5),
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
              : colorScheme.outline.withOpacity(0.3),
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

  Widget _buildNeonSelector({
    required String hint,
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasValue = value != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasValue
              ? colorScheme.primary.withOpacity(0.6)
              : colorScheme.outline.withOpacity(0.3),
          width: hasValue ? 2 : 1,
        ),
        color: hasValue
            ? colorScheme.primary.withOpacity(0.05)
            : colorScheme.surface.withOpacity(0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showNeonBottomSheet(
            title: hint,
            options: options,
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
                      : colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hint.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value ?? 'Select $hint',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: hasValue
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colorScheme.onSurface.withOpacity(0.6),
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
              ? colorScheme.primary.withOpacity(0.6)
              : colorScheme.outline.withOpacity(0.3),
          width: hasValue ? 2 : 1,
        ),
        color: hasValue
            ? colorScheme.primary.withOpacity(0.05)
            : colorScheme.surface.withOpacity(0.5),
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
                      : colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SORT BY',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
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
                              : colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colorScheme.onSurface.withOpacity(0.6),
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
              ? colorScheme.primary.withOpacity(0.6)
              : colorScheme.outline.withOpacity(0.3),
          width: isActive ? 2 : 1,
        ),
        color: isActive
            ? colorScheme.primary.withOpacity(0.05)
            : colorScheme.surface.withOpacity(0.5),
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
                    color: colorScheme.onSurface.withOpacity(0.7),
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
                          : colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDescending ? 'DESC' : 'ASC',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withOpacity(0.5),
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
              : colorScheme.outline.withOpacity(0.5),
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

  void _showNeonBottomSheet({
    required String title,
    required List<String> options,
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
              color: colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.1),
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
                      color: colorScheme.primary.withOpacity(0.2),
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
                            color: colorScheme.primary.withOpacity(0.5),
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
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.3),
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
                    final isSelected = selectedValue == option;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FutureisticOptionTile(
                        option: option,
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
      selectedFormat = null;
      selectedGenres.clear();
    });
  }

  void _applyFilters() {
    String? finalSort;
    if (selectedSortBy != null && selectedSortType != null) {
      finalSort = sortOptions[selectedSortBy!]![selectedSortType!];
    }

    widget.onApplyFilter({
      'season': selectedSeason,
      'sort': finalSort,
      'format': selectedFormat,
      'genres': selectedGenres.isEmpty ? null : selectedGenres,
      'status': selectedStatus,
    });
    Navigator.pop(context);
  }
}
