import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:flutter/material.dart';

void showFilterBottomSheet(
    BuildContext context, Function(dynamic args) onApplyFilter,
    {Map<String, dynamic>? currentFilters}) {
  // Add currentFilters parameter
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (BuildContext context) {
      return FilterOptionsContent(
        onApplyFilter: (args) {
          onApplyFilter(args);
        },
        currentFilters: currentFilters, // Pass current filters to the content
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
  List<String> sortBy = [
    'SCORE_DESC',
    'SCORE',
    'POPULARITY_DESC',
    'POPULARITY',
    'TRENDING_DESC',
    'TRENDING',
    'START_DATE_DESC',
    'START_DATE',
    'TITLE_ROMAJI',
    'TITLE_ROMAJI_DESC'
  ];
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

  String? selectedSortBy = 'SCORE';
  String? selectedSeason = 'WINTER';
  String? selectedStatus = 'FINISHED';
  String? selectedFormat = 'TV';
  List<String> selectedGenres = [];

  @override
  void initState() {
    super.initState();

    if (widget.currentFilters != null) {
      selectedSortBy = widget.currentFilters!['sort'] ?? selectedSortBy;
      selectedSeason = widget.currentFilters!['season'] ?? selectedSeason;
      selectedStatus = widget.currentFilters!['status'] ?? selectedStatus;
      selectedFormat = widget.currentFilters!['format'] ?? selectedFormat;

      if (widget.currentFilters!['genres'] != null &&
          widget.currentFilters!['genres'] is List) {
        selectedGenres = List<String>.from(widget.currentFilters!['genres']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Filter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    fillColor: Colors.transparent,
                    hintText: 'Sort By',
                    labelText: 'Sort By',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18)),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedSortBy,
                      isExpanded: true,
                      items: sortBy
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins-SemiBold',
                                      fontSize: 13),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSortBy = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    fillColor: Colors.transparent,
                    labelText: 'Season',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedSeason,
                      isExpanded: true,
                      items: season
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins-SemiBold',
                                      fontSize: 13),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSeason = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    fillColor: Colors.transparent,
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    labelText: 'Status',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      items: status
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins-SemiBold',
                                      fontSize: 13),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    fillColor: Colors.transparent,
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    labelText: 'Format',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedFormat,
                      isExpanded: true,
                      items: format
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins-SemiBold',
                                      fontSize: 13),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedFormat = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Select Genres',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              children: genres
                  .map((genre) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: ChoiceChip(
                          label: Text(genre),
                          selected: selectedGenres.contains(genre),
                          onSelected: (selected) {
                            setState(() {
                              selected
                                  ? selectedGenres.add(genre)
                                  : selectedGenres.remove(genre);
                            });
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: AnymexButton(
                  padding: const EdgeInsets.all(16),
                  color: Colors.transparent,
                  border: BorderSide(
                      width: 1, color: Theme.of(context).colorScheme.primary),
                  radius: (20),
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins-SemiBold',
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnymexButton(
                  padding: const EdgeInsets.all(16),
                  color: Colors.transparent,
                  border: BorderSide(
                      width: 1, color: Theme.of(context).colorScheme.primary),
                  radius: (20),
                  onTap: () {
                    widget.onApplyFilter({
                      'season': selectedSeason,
                      'sort': selectedSortBy,
                      'format': selectedFormat,
                      'genres': selectedGenres,
                      'status': selectedStatus
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Apply',
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins-SemiBold',
                        color: Theme.of(context).colorScheme.onSurface),
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
