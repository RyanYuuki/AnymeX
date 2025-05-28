import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:flutter/material.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

void showFilterBottomSheet(
    BuildContext context, Function(dynamic args) onApplyFilter,
    {Map<String, dynamic>? currentFilters}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (BuildContext context) {
      return FilterOptionsContent(
        onApplyFilter: (args) {
          onApplyFilter(args);
        },
        currentFilters: currentFilters,
      );
    },
  );
}

class FilterOptionsContent extends StatefulWidget {
  const FilterOptionsContent({
    super.key,
    required this.onApplyFilter,
    this.currentFilters,
  });
  final Function(dynamic args) onApplyFilter;
  final Map<String, dynamic>? currentFilters;

  @override
  State<FilterOptionsContent> createState() => _FilterOptionsContentState();
}

class _FilterOptionsContentState extends State<FilterOptionsContent> {
  // Improved sort options with better formatting
  Map<String, Map<String, String>> sortOptions = {
    'Score': {
      'desc': 'SCORE_DESC',
      'asc': 'SCORE',
      'descLabel': 'Score ↓ — Score (High to Low)',
      'ascLabel': 'Score ↑ — Score (Low to High)',
    },
    'Popularity': {
      'desc': 'POPULARITY_DESC',
      'asc': 'POPULARITY',
      'descLabel': 'Popularity ↓ — Most Popular First',
      'ascLabel': 'Popularity ↑ — Least Popular First',
    },
    'Trending': {
      'desc': 'TRENDING_DESC',
      'asc': 'TRENDING',
      'descLabel': 'Trending ↓ — Trending Top First',
      'ascLabel': 'Trending ↑ — Low Trending First',
    },
    'Start Date': {
      'desc': 'START_DATE_DESC',
      'asc': 'START_DATE',
      'descLabel': 'Start Date ↓ — Newest First',
      'ascLabel': 'Start Date ↑ — Oldest First',
    },
    'Title': {
      'desc': 'TITLE_ROMAJI_DESC',
      'asc': 'TITLE_ROMAJI',
      'descLabel': 'Title Z–A — Title (Z to A)',
      'ascLabel': 'Title A–Z — Title (A to Z)',
    },
  };

  List<String> season = ['WINTER', 'SPRING', 'SUMMER', 'FALL'];
  List<String> status = [
    'All',
    'FINISHED',
    'NOT_YET_RELEASED',
    'RELEASING',
    'CANCELLED',
    'HIATUS'
  ];
  List<String> format = ['TV', 'TV SHORT', 'MOVIE', 'SPECIAL', 'OVA', 'ONA'];
  List<String> genres = [
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
  String? selectedSortType; // 'desc' or 'asc'
  String? selectedSeason;
  String? selectedStatus;
  String? selectedFormat;
  List<String>? selectedGenres;

  @override
  void initState() {
    super.initState();

    if (widget.currentFilters != null) {
      // Handle sort conversion from old format to new
      String? currentSort = widget.currentFilters!['sort'];
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

      selectedSeason = widget.currentFilters!['season'] ?? selectedSeason;
      selectedStatus = widget.currentFilters!['status'] ?? selectedStatus;
      selectedFormat = widget.currentFilters!['format'] ?? selectedFormat;

      if (widget.currentFilters!['genres'] != null &&
          widget.currentFilters!['genres'] is List) {
        selectedGenres = List<String>.from(widget.currentFilters!['genres']);
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildCustomSelector({
    required String hint,
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1.5,
        ),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showOptionBottomSheet(
              context: context,
              title: hint,
              options: options,
              selectedValue: value,
              onSelected: onChanged,
              icon: icon,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hint,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value ?? 'Select $hint',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: value != null
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortSelector() {
    String displayText = 'Select Sort Option';
    if (selectedSortBy != null && selectedSortType != null) {
      displayText = sortOptions[selectedSortBy!]![
          selectedSortType == 'desc' ? 'descLabel' : 'ascLabel']!;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1.5,
        ),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showSortBottomSheet();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.sort_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sort By',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selectedSortBy != null
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: _buildSortBy(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortBy() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortOptions.entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = sortOptions.entries.elementAt(index);
        final isDescSelected =
            selectedSortBy == entry.key && selectedSortType == 'desc';
        final isAscSelected =
            selectedSortBy == entry.key && selectedSortType == 'asc';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Descending option
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    selectedSortBy = entry.key;
                    selectedSortType = 'desc';
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDescSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.2),
                      width: isDescSelected ? 2 : 1,
                    ),
                    color: isDescSelected
                        ? colorScheme.primaryContainer.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: '${entry.key}_desc',
                        groupValue:
                            selectedSortBy != null && selectedSortType != null
                                ? '${selectedSortBy}_$selectedSortType'
                                : null,
                        onChanged: (value) {
                          setState(() {
                            selectedSortBy = entry.key;
                            selectedSortType = 'desc';
                          });
                          Navigator.pop(context);
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_downward_rounded,
                        size: 18,
                        color: isDescSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value['descLabel']!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDescSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontWeight: isDescSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Ascending option
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    selectedSortBy = entry.key;
                    selectedSortType = 'asc';
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAscSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.2),
                      width: isAscSelected ? 2 : 1,
                    ),
                    color: isAscSelected
                        ? colorScheme.primaryContainer.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: '${entry.key}_asc',
                        groupValue:
                            selectedSortBy != null && selectedSortType != null
                                ? '${selectedSortBy}_$selectedSortType'
                                : null,
                        onChanged: (value) {
                          setState(() {
                            selectedSortBy = entry.key;
                            selectedSortType = 'asc';
                          });
                          Navigator.pop(context);
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 18,
                        color: isAscSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value['ascLabel']!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isAscSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontWeight: isAscSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showOptionBottomSheet({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String? selectedValue,
    required Function(String?) onSelected,
    IconData? icon,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: ListView.separated(
                      itemCount: options.length,
                      separatorBuilder: (context, index) => 5.height(),
                      itemBuilder: (context, i) {
                        final entry = options.asMap().entries.elementAt(i);
                        final index = entry.key;
                        final option = entry.value;
                        final theme = Theme.of(context);
                        final colorScheme = theme.colorScheme;
                        final isSelected = selectedValue == option;

                        return Column(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  onSelected(option);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.outline
                                              .withOpacity(0.2),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    color: isSelected
                                        ? colorScheme.primaryContainer
                                            .withOpacity(0.3)
                                        : Colors.transparent,
                                  ),
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: option,
                                        groupValue: selectedValue,
                                        onChanged: (value) {
                                          onSelected(value);
                                          Navigator.pop(context);
                                        },
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: isSelected
                                                ? colorScheme.primary
                                                : colorScheme.onSurface,
                                            fontWeight: isSelected
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (index != options.length - 1)
                              const SizedBox(height: 0),
                          ],
                        );
                      })),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Filter & Sort',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Sort Options'),
          _buildSortSelector(),
          const SizedBox(height: 20),
          _buildSectionTitle('Filter Options'),
          Row(
            children: [
              Expanded(
                child: _buildCustomSelector(
                  hint: 'Season',
                  value: selectedSeason,
                  options: season,
                  onChanged: (value) {
                    setState(() {
                      selectedSeason = value;
                    });
                  },
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCustomSelector(
                  hint: 'Status',
                  value: selectedStatus,
                  options: status,
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value;
                    });
                  },
                  icon: Icons.info_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCustomSelector(
            hint: 'Format',
            value: selectedFormat,
            options: format,
            onChanged: (value) {
              setState(() {
                selectedFormat = value;
              });
            },
            icon: Icons.video_library_rounded,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Genres'),
          Container(
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SuperListView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                children: genres
                    .map((genre) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(
                              genre,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: selectedGenres?.contains(genre) ?? false
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            selected: selectedGenres?.contains(genre) ?? false,
                            selectedColor:
                                Theme.of(context).colorScheme.primary,
                            checkmarkColor:
                                Theme.of(context).colorScheme.onPrimary,
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            side: BorderSide(
                              color: selectedGenres?.contains(genre) ?? false
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.3),
                              width: 1.5,
                            ),
                            onSelected: (selected) {
                              selectedGenres ??= [];
                              setState(() {
                                selected
                                    ? selectedGenres?.add(genre)
                                    : selectedGenres?.remove(genre);
                              });
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: AnymexButton(
                  padding: const EdgeInsets.all(16),
                  color: Colors.transparent,
                  border: BorderSide(
                      width: 1.5,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.5)),
                  radius: (16),
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnymexButton(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primary,
                  border: BorderSide.none,
                  radius: (16),
                  onTap: () {
                    String? finalSort;
                    if (selectedSortBy != null && selectedSortType != null) {
                      finalSort =
                          sortOptions[selectedSortBy!]![selectedSortType!];
                    }

                    widget.onApplyFilter({
                      'season': selectedSeason,
                      'sort': finalSort,
                      'format': selectedFormat,
                      'genres': selectedGenres,
                      'status': selectedStatus,
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Apply Filters',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
