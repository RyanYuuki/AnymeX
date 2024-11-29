// ignore_for_file: prefer_const_constructors, deprecated_member_use, non_constant_identifier_names, must_be_immutable, avoid_print, use_build_context_synchronously
import 'dart:developer';
import 'package:anymex/components/android/common/IconWithLabel.dart';
import 'package:anymex/components/android/novel/wong_title.dart';
import 'package:anymex/hiveData/appData/database.dart';
import 'package:anymex/pages/Android/Novel/reading_page.dart';
import 'package:anymex/utils/sources/novel/extensions/novel_buddy.dart';
import 'package:anymex/utils/sources/novel/handler/novel_sources_handler.dart';
import 'package:anymex/utils/sources/unified_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class NovelDetailsPage extends StatefulWidget {
  final String id;
  final String? posterUrl;
  final String? tag;
  const NovelDetailsPage({
    super.key,
    required this.id,
    this.posterUrl,
    this.tag,
  });

  @override
  State<NovelDetailsPage> createState() => _NovelDetailsPageState();
}

class _NovelDetailsPageState extends State<NovelDetailsPage>
    with SingleTickerProviderStateMixin {
  bool usingSaikouLayout =
      Hive.box('app-data').get('usingSaikouLayout', defaultValue: false);
  dynamic data;
  dynamic mappedData;
  dynamic chapterData;
  bool isLoading = true;
  int selectedIndex = 0;
  late final NovelSourcesHandler _novelSourcesHandler;
  bool isFavourite = false;

  @override
  void initState() {
    super.initState();
    _novelSourcesHandler =
        Provider.of<UnifiedSourcesHandler>(context, listen: false)
            .getNovelInstance();
    isFavourite =
        Provider.of<AppData>(context, listen: false).getNovelAvail(widget.id);
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final tempdata = await NovelBuddy().scrapeNovelDetails(widget.id);
      setState(() {
        data = tempdata;
        chapterData = tempdata['chapterList'];
        isLoading = false;
      });
    } catch (e) {
      log('Failed to fetch Anime Info: $e');
    }
  }

  double simpleStringSimilarity(String a, String b) {
    a = a.toLowerCase();
    b = b.toLowerCase();
    int minLength = a.length < b.length ? a.length : b.length;
    int matchCount = 0;
    for (int i = 0; i < minLength; i++) {
      if (a[i] == b[i]) {
        matchCount++;
      } else {
        break;
      }
    }

    return matchCount / minLength;
  }

  Future<Map<String, dynamic>?> mapNovel() async {
    List<Map<String, dynamic>> fetchedData =
        await _novelSourcesHandler.fetchNovelSearchResults(data['title']);

    for (var novel in fetchedData) {
      if (novel['title'] == data['title'] ||
          novel['title'].toLowerCase() == data['title'].toLowerCase()) {
        final novelDetails =
            await _novelSourcesHandler.fetchNovelDetails(url: novel['id']);
        setState(() {
          mappedData = novelDetails;
        });
        return novelDetails;
      }
      final similarity = simpleStringSimilarity(novel['title'], data['title']);
      if (similarity > 0.5) {
        final novelDetails =
            await _novelSourcesHandler.fetchNovelDetails(url: novel['id']);
        return novelDetails;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme customScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: originalDetailsPage(customScheme, context),
    );
  }

  Scaffold originalDetailsPage(ColorScheme CustomScheme, BuildContext context) {
    return Scaffold(
      backgroundColor: CustomScheme.surface,
      body: isLoading
          ? Column(
              children: [
                Center(
                  child: Poster(
                    context,
                    tag: widget.tag,
                    poster: widget.posterUrl,
                    isLoading: true,
                  ),
                ),
                const SizedBox(height: 30),
                CircularProgressIndicator(),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Poster(
                    context,
                    isLoading: false,
                    tag: widget.tag,
                    poster: widget.posterUrl,
                  ),
                  const SizedBox(height: 30),
                  originalInfoPage(CustomScheme, context),
                ],
              ),
            ),
    );
  }

  Widget Poster(
    BuildContext context, {
    required String? tag,
    required String? poster,
    required bool? isLoading,
  }) {
    return SizedBox(
      height: 300,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              fit: BoxFit.cover,
              imageUrl: widget.posterUrl!,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface.withOpacity(0.4),
                    Theme.of(context).colorScheme.surface.withOpacity(0.6),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 25,
            child: Row(
              children: [
                Hero(
                  tag: tag!,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: CachedNetworkImage(
                      imageUrl: poster!,
                      fit: BoxFit.cover,
                      width: 70,
                      height: 100,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 100,
                      child: Text(
                        data?['title'] ?? 'Loading',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            overflow: TextOverflow.ellipsis),
                        maxLines: 2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        iconWithName(
                          icon: Iconsax.star5,
                          name: data?['rating'] ?? '6.9',
                          isVertical: false,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 2,
                          height: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .inverseSurface
                              .withOpacity(0.4),
                        ),
                        const SizedBox(width: 10),
                        Text(data?['status'] ?? '??',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontFamily: 'Poppins-SemiBold'))
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 30,
            right: 20,
            child: Material(
              borderOnForeground: false,
              color: Colors.transparent,
              child: IconButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainer,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.close),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Column originalInfoPage(ColorScheme CustomScheme, BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50)),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => NovelReadingPage(
                                            id: data['chapterList'][0]['id'],
                                            novelTitle: data['title'],
                                            novelId: data['id'],
                                            chapterNumber: data['chapterList']
                                                [0]['number'],
                                            selectedSource: _novelSourcesHandler
                                                .getSelectedSource(),
                                            novelImage: widget.posterUrl!,
                                            chapterList: data['chapterList'],
                                            description: data['description'],
                                          )));
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text('Read: ',
                                    style: TextStyle(
                                        fontFamily: 'Poppins-SemiBold')),
                                Text('Chapter 1',
                                    style: TextStyle(
                                        fontFamily: 'Poppins-SemiBold'))
                              ],
                            )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedContainer(
                      width: 60,
                      height: 60,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: isFavourite
                                  ? Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                  : Theme.of(context).colorScheme.primary),
                          color: isFavourite
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(50)),
                      duration: Duration(milliseconds: 300),
                      child: IconButton(
                        icon: Icon(
                          isFavourite ? IconlyBold.heart : IconlyLight.heart,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                        ),
                        onPressed: () {
                          if (data != null) {
                            setState(() {
                              isFavourite = !isFavourite;
                            });
                            Provider.of<AppData>(context, listen: false)
                                .addReadNovels(
                                    novelId: data['id'],
                                    novelTitle: data['title'],
                                    chapterNumber: '1',
                                    chapterId: data['chapterList'][0]['id'],
                                    novelImage: widget.posterUrl!,
                                    currentSource: _novelSourcesHandler
                                        .getSelectedSource(),
                                    chapterList: data['chapterList'],
                                    description: data['description']);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text('Description',
                  style: TextStyle(fontFamily: 'Poppins-SemiBold')),
              const SizedBox(
                height: 5,
              ),
              Column(
                children: [
                  Text(
                    data['description']?.replaceAll(RegExp(r'<[^>]*>'), '') ??
                        data?['description']
                            ?.replaceAll(RegExp(r'<[^>]*>'), '') ??
                        'Description Not Found',
                    maxLines: 13,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Statistics',
                  style:
                      TextStyle(fontFamily: 'Poppins-SemiBold', fontSize: 16)),
              infoRow(field: 'Author', value: data['authors'].toString()),
              infoRow(field: 'Rating', value: data?['rating'] ?? '??'),
              infoRow(field: 'Total Chapters', value: data['chapters']),
              infoRow(field: 'Last Update', value: data?['lastUpdate'] ?? '??'),
              infoRow(field: 'Status', value: data?['status'] ?? '??'),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Found: ${mappedData?['title'] ?? data?['title']}',
                      style: TextStyle(fontFamily: 'Poppins-SemiBold'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      showNovelSearchModal(context, data['title'],
                          (novelId) async {
                        setState(() {
                          chapterData = null;
                        });
                        final tempData = await _novelSourcesHandler
                            .fetchNovelDetails(url: novelId);
                        setState(() {
                          mappedData = tempData;
                          chapterData = tempData['chapterList'];
                        });
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          border: BorderDirectional(
                              bottom: BorderSide(
                                  width: 2,
                                  color:
                                      Theme.of(context).colorScheme.primary))),
                      child: Text('Wrong Title?',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontFamily: 'Poppins-SemiBold')),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _novelSourcesHandler.getSelectedSource(),
                decoration: InputDecoration(
                  labelText: 'Choose Source',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  labelStyle:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          Theme.of(context).colorScheme.onPrimaryFixedVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                isExpanded: true,
                items: _novelSourcesHandler
                    .getAvailableSources()
                    .map<DropdownMenuItem<String>>((source) {
                  return DropdownMenuItem<String>(
                    value: source['name'],
                    child: Text(
                      source['name']!,
                      style: TextStyle(fontFamily: 'Poppins-SemiBold'),
                    ),
                  );
                }).toList(),
                onChanged: (value) async {
                  setState(() {
                    _novelSourcesHandler.setSelectedSource(value!);
                    chapterData = null;
                  });
                  final newData = await mapNovel();
                  setState(() {
                    chapterData = newData?['chapterList'];
                  });
                },
                dropdownColor: Theme.of(context).colorScheme.surface,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.primary,
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              if (chapterData == null)
                SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()))
              else
                ChapterList(
                  novelId: data?['id'],
                  title: mappedData?['title'] ?? data?['title'],
                  chaptersData: chapterData,
                  selectedSource: _novelSourcesHandler.getSelectedSource(),
                  novelImage: widget.posterUrl!,
                  description: data['description'],
                )
            ],
          ),
        ),
      ],
    );
  }
}

class infoRow extends StatelessWidget {
  final String value;
  final String field;

  const infoRow({super.key, required this.field, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(right: 10),
      margin: EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(field,
              style: TextStyle(
                  fontFamily: 'Poppins-Bold',
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7))),
          SizedBox(
            width: 170,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: 'Poppins-Bold')),
            ),
          ),
        ],
      ),
    );
  }
}

class ChapterList extends StatefulWidget {
  final dynamic chaptersData;
  final String title;
  final String novelId;
  final String selectedSource;
  final String novelImage;
  final String description;
  const ChapterList({
    super.key,
    this.chaptersData,
    required this.title,
    required this.novelId,
    required this.selectedSource,
    required this.novelImage,
    required this.description,
  });

  @override
  _ChapterListState createState() => _ChapterListState();
}

class _ChapterListState extends State<ChapterList> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredChapters = [];
  bool isSortedDown = true;

  @override
  void initState() {
    super.initState();
    if (isSortedDown) {
      _filteredChapters = widget.chaptersData;
    } else {
      _filteredChapters = widget.chaptersData.reversed.toList();
    }
    _searchController.addListener(_filterChapters);
  }

  void _filterChapters() {
    setState(() {
      if (isSortedDown) {
        _filteredChapters = widget.chaptersData
            .where((chapter) => chapter['title']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
      } else {
        final newList = widget.chaptersData.reversed.toList();
        _filteredChapters = newList
            .where((chapter) => chapter['title']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void sortFilteredChapter() {
    setState(() {
      isSortedDown = !isSortedDown;
      if (isSortedDown) {
        _filteredChapters = widget.chaptersData;
      } else {
        _filteredChapters = widget.chaptersData.reversed.toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chapters',
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: "Poppins-Bold",
                ),
                textAlign: TextAlign.left,
              ),
              IconButton(
                  onPressed: () {
                    sortFilteredChapter();
                  },
                  icon: Icon(
                      isSortedDown ? Icons.arrow_downward : Icons.arrow_upward))
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHigh,
                    filled: true,
                    hintText: 'Search Chapter...',
                    prefixIcon: const Icon(Iconsax.search_normal),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          widget.chaptersData == null
              ? SizedBox(
                  height: 400,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : SizedBox(
                  height: 400,
                  child: ListView.builder(
                    padding: EdgeInsets.all(0),
                    itemCount: _filteredChapters.length,
                    itemBuilder: (context, index) {
                      final manga = _filteredChapters[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        width: MediaQuery.of(context).size.width,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                manga['title'],
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => NovelReadingPage(
                                              id: manga['id'],
                                              novelTitle: widget.title,
                                              novelId: widget.novelId,
                                              chapterNumber: manga['number'],
                                              selectedSource:
                                                  widget.selectedSource,
                                              novelImage: widget.novelImage,
                                              chapterList: widget.chaptersData,
                                              description: widget.description,
                                            )));
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.4)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Read',
                                style: TextStyle(
                                  color: Theme.of(context)
                                              .colorScheme
                                              .inverseSurface ==
                                          Theme.of(context)
                                              .colorScheme
                                              .onPrimaryFixedVariant
                                      ? Colors.black
                                      : Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryFixedVariant ==
                                              const Color(0xffe2e2e2)
                                          ? Colors.black
                                          : Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          const SizedBox(
            height: 50,
          ),
        ],
      ),
    );
  }
}
