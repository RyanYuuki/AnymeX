// ignore_for_file: unused_field

import 'package:aurora/hiveData/appData/database.dart';
import 'package:aurora/hiveData/themeData/theme_provider.dart';
import 'package:aurora/utils/sources/novel/handler/novel_sources_handler.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class NovelReadingPage extends StatefulWidget {
  final String id;
  final String novelTitle;
  final String novelId;
  final int chapterNumber;
  final String selectedSource;
  final String novelImage;
  final dynamic chapterList;
  final String description;
  const NovelReadingPage(
      {super.key,
      required this.id,
      required this.novelTitle,
      required this.novelId,
      required this.chapterNumber,
      required this.selectedSource,
      required this.novelImage,
      required this.chapterList,
      required this.description});

  @override
  State<NovelReadingPage> createState() => _NovelReadingPageState();
}

class _NovelReadingPageState extends State<NovelReadingPage> {
  bool _isMenuVisible = false;
  bool _isLoading = true;
  double _fontSize = 18.0;
  String _selectedFontFamily = 'Default';
  Color _backgroundColor = ThemeProvider().selectedTheme.colorScheme.surface;
  Color _textColor = ThemeProvider().selectedTheme.colorScheme.inverseSurface;
  dynamic novelData;
  String _currentChapterId = '';
  final List<String> _fontFamilies = [
    'Default',
    'Roboto',
    'Montserrat',
    'Inter',
    'Lato',
    'Oswald',
  ];

  final List<Color> _backgroundColors = [
    ThemeProvider().selectedTheme.colorScheme.surface,
    Colors.white,
    const Color(0xFFF8F3E6),
    const Color(0xFFE8F0F3),
    const Color(0xFFF3E8E8),
    const Color(0xFFE8F3E8),
    Colors.grey[200]!,
    const Color(0xFF303030),
    Colors.black,
  ];

  final List<Color> _fontColors = [
    ThemeProvider().selectedTheme.colorScheme.inverseSurface,
    Colors.black,
    Colors.black87,
    const Color(0xFF4A4A4A),
    const Color(0xFF2C3E50),
    const Color(0xFF8B4513),
    Colors.white,
    Colors.white70,
  ];

  @override
  void initState() {
    super.initState();
    _currentChapterId = widget.id;
    _fetchInitialChapter();
    saveChapterProgress();
  }

  Future<void> _fetchInitialChapter() async {
    try {
      final data = await NovelSourcesHandler()
          .fetchNovelWords(widget.id, widget.selectedSource);
      if (mounted) {
        setState(() {
          novelData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void saveChapterProgress() {
    final provider = Provider.of<AppData>(context, listen: false);
    provider.addReadNovels(
        novelId: widget.novelId,
        novelTitle: widget.novelTitle,
        chapterNumber: widget.chapterNumber.toString(),
        chapterId: widget.id,
        novelImage: widget.novelImage,
        currentSource: widget.selectedSource,
        chapterList: widget.chapterList,
        description: widget.description);
  }

  Future<void> _fetchNextPreviousChapter(String chapterId) async {
    if (chapterId.isEmpty) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await NovelSourcesHandler()
          .fetchNovelWords(chapterId, widget.selectedSource);
      if (mounted) {
        setState(() {
          novelData = data;
          _currentChapterId = chapterId;
          _isLoading = false;
        });
        final provider = Provider.of<AppData>(context, listen: false);
        provider.addReadNovels(
            novelId: widget.novelId,
            novelTitle: widget.novelTitle,
            chapterNumber: widget.chapterNumber.toString(),
            chapterId: chapterId,
            novelImage: widget.novelImage,
            currentSource: widget.selectedSource,
            chapterList: widget.chapterList,
            description: widget.description);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleMenu() {
    setState(() {
      _isMenuVisible = !_isMenuVisible;
    });
  }

  TextStyle _getTextStyle(String fontFamily) {
    if (fontFamily == 'Default') {
      return TextStyle(
        fontSize: _fontSize,
        height: 1.5,
        color: _textColor,
      );
    }
    return GoogleFonts.getFont(
      fontFamily.replaceAll(' ', ''),
      fontSize: _fontSize,
      height: 1.5,
      color: _textColor,
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Reading Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.format_size),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Slider(
                              value: _fontSize,
                              min: 12,
                              max: 32,
                              divisions: 20,
                              label: _fontSize.round().toString(),
                              onChanged: (value) {
                                setSheetState(() {
                                  setState(() {
                                    _fontSize = value;
                                  });
                                });
                              },
                            ),
                          ),
                          Text(
                            _fontSize.round().toString(),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Font Style',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _fontFamilies.length,
                          itemBuilder: (context, index) {
                            final family = _fontFamilies[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                side: BorderSide.none,
                                backgroundColor:
                                    Theme.of(context).colorScheme.onSecondary,
                                label: Text(family),
                                selected: _selectedFontFamily == family,
                                onSelected: (selected) {
                                  if (selected) {
                                    setSheetState(() {
                                      setState(() {
                                        _selectedFontFamily = family;
                                      });
                                    });
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Background Color',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _backgroundColors.length,
                          itemBuilder: (context, index) {
                            final color = _backgroundColors[index];
                            return GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  setState(() {
                                    _backgroundColor = color;
                                  });
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  border: Border.all(
                                    color: _backgroundColor == color
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: _backgroundColor == color
                                    ? Icon(Icons.check,
                                        color: color.computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white,
                                        size: 20)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Text Color',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _fontColors.length,
                          itemBuilder: (context, index) {
                            final color = _fontColors[index];
                            return GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  setState(() {
                                    _textColor = color;
                                  });
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  border: Border.all(
                                    color: _textColor == color
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: _textColor == color
                                    ? Icon(Icons.check,
                                        color: color.computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white,
                                        size: 20)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Preview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Preview text with selected style',
                          style: _getTextStyle(_selectedFontFamily),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          GestureDetector(
            onTapUp: (details) {
              final screenHeight = MediaQuery.of(context).size.height;
              final screenWidth = MediaQuery.of(context).size.width;
              final tapPosition = details.globalPosition;

              if (tapPosition.dy > screenHeight * 0.2 &&
                  tapPosition.dy < screenHeight * 0.8 &&
                  tapPosition.dx > screenWidth * 0.2 &&
                  tapPosition.dx < screenWidth * 0.8) {
                _toggleMenu();
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const SizedBox(height: 80),
                if (novelData != null)
                  ...novelData['words'].map((paragraph) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          paragraph,
                          style: _getTextStyle(_selectedFontFamily),
                        ),
                      )),
                const SizedBox(height: 80),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            top: _isMenuVisible ? 0 : -80,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              padding: const EdgeInsets.only(top: 40, left: 0, right: 10),
              decoration: BoxDecoration(
                color: _backgroundColor.withOpacity(0.4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(IconlyBold.arrow_left, color: _textColor),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.novelTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: _textColor,
                              fontFamily: 'Poppins-SemiBold'),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 1.5,
                          child: Text(
                            novelData['chapterTitle'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: _textColor,
                                fontSize: 12,
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _showSettingsSheet,
                    icon: Icon(Iconsax.setting5, color: _textColor),
                  ),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            bottom: _isMenuVisible ? 0 : -80,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _backgroundColor.withOpacity(0.4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (novelData != null &&
                          novelData['prevChapterId'].isNotEmpty) {
                        _fetchNextPreviousChapter(novelData['prevChapterId']);
                      }
                    },
                    icon: Icon(Iconsax.previous5,
                        color: novelData == null ||
                                novelData['prevChapterId'].isEmpty
                            ? _textColor.withOpacity(0.3)
                            : _textColor),
                  ),
                  IconButton(
                    onPressed: () {
                      if (novelData != null &&
                          novelData['nextChapterId'].isNotEmpty) {
                        _fetchNextPreviousChapter(novelData['nextChapterId']);
                      }
                    },
                    icon: Icon(Iconsax.next5,
                        color: novelData == null ||
                                novelData['nextChapterId'].isEmpty
                            ? _textColor.withOpacity(0.3)
                            : _textColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
