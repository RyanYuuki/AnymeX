import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';

class TestResult {
  int size = 0;
  int time = 0;
  String? errorMessage;
}

class ExtensionTestResultItem extends StatefulWidget {
  final Source source;
  final ItemType itemType;
  final String testType;
  final String searchQuery;

  const ExtensionTestResultItem({
    super.key,
    required this.source,
    required this.itemType,
    required this.testType,
    required this.searchQuery,
  });

  @override
  State<ExtensionTestResultItem> createState() =>
      _ExtensionTestResultItemState();
}

class _ExtensionTestResultItemState extends State<ExtensionTestResultItem> {
  late TestResult searchResult;
  late TestResult episodeResult;
  late TestResult serverResult;
  int? pingTime;
  String? pingError;
  bool isRunning = true;

  @override
  void initState() {
    super.initState();
    searchResult = TestResult();
    episodeResult = TestResult();
    serverResult = TestResult();
    _startTest();
  }

  Future<void> _startTest() async {
    try {
      switch (widget.itemType) {
        case ItemType.anime:
          await _runAnimeTest();
          break;
        case ItemType.manga:
          await _runMangaTest();
          break;
        case ItemType.novel:
          await _runNovelTest();
          break;
      }
    } catch (e) {
      debugPrint('Test error: $e');
    } finally {
      if (mounted) {
        setState(() => isRunning = false);
      }
    }
  }

  Future<void> _runPingTest() async {
    final pingStart = DateTime.now();
    try {
      await widget.source.methods.getPopular(1);
      if (mounted) {
        setState(() {
          pingTime = DateTime.now().difference(pingStart).inMilliseconds;
          pingError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          pingTime = null;
          pingError = e.toString();
        });
      }
    }
  }

  Future<dynamic> _runSearchTest() async {
    dynamic searchResults;
    final searchStart = DateTime.now();
    try {
      searchResults =
          await widget.source.methods.search(widget.searchQuery, 1, []);

      // Safely extract list and ensure it's not null
      final resultsList = searchResults?.list;
      final size = resultsList?.length ?? 0;

      if (mounted) {
        setState(() {
          searchResult.size = size;
          searchResult.time =
              DateTime.now().difference(searchStart).inMilliseconds;
          searchResult.errorMessage = null;
        });
      }

      return searchResults;
    } catch (e) {
      final errorMsg = e.toString();
      if (mounted) {
        setState(() {
          searchResult.size = 0;
          searchResult.time =
              DateTime.now().difference(searchStart).inMilliseconds;
          searchResult.errorMessage = errorMsg;
        });
      }
      debugPrint('Search test error: $e');
      return null;
    }
  }

  Future<DMedia?> _runDetailTest(dynamic firstResult) async {
    if (firstResult == null) return null;

    DMedia? detailedMedia;
    final detailStart = DateTime.now();
    try {
      detailedMedia = await widget.source.methods.getDetail(firstResult);

      final size = detailedMedia.episodes?.length ?? 0;
      if (mounted) {
        setState(() {
          episodeResult.size = size;
          episodeResult.time =
              DateTime.now().difference(detailStart).inMilliseconds;
          episodeResult.errorMessage = null;
        });
      }

      return detailedMedia;
    } catch (e) {
      final errorMsg = e.toString();
      if (mounted) {
        setState(() {
          episodeResult.size = 0;
          episodeResult.time =
              DateTime.now().difference(detailStart).inMilliseconds;
          episodeResult.errorMessage = errorMsg;
        });
      }
      debugPrint('Detail test error: $e');
      return null;
    }
  }

  /// Runs server/video list test for anime
  Future<void> _runServerTest(DMedia detailedMedia) async {
    final episodes = detailedMedia.episodes;
    if (episodes == null || episodes.isEmpty) {
      if (mounted) {
        setState(() {
          serverResult.errorMessage = 'No episodes available';
        });
      }
      return;
    }

    final serverStart = DateTime.now();
    try {
      final servers = await widget.source.methods.getVideoList(episodes.first);
      if (mounted) {
        setState(() {
          serverResult.size = servers.length;
          serverResult.time =
              DateTime.now().difference(serverStart).inMilliseconds;
          serverResult.errorMessage = null;
        });
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (mounted) {
        setState(() {
          serverResult.size = 0;
          serverResult.time =
              DateTime.now().difference(serverStart).inMilliseconds;
          serverResult.errorMessage = errorMsg;
        });
      }
      debugPrint('Server test error: $e');
    }
  }

  /// Runs page list test for manga
  Future<void> _runPageListTest(DMedia detailedMedia) async {
    final episodes = detailedMedia.episodes;
    if (episodes == null || episodes.isEmpty) {
      if (mounted) {
        setState(() {
          serverResult.errorMessage = 'No chapters available';
        });
      }
      return;
    }

    final pageStart = DateTime.now();
    try {
      final pages = await widget.source.methods.getPageList(
        DEpisode(url: episodes.first.url, episodeNumber: "1"),
      );
      if (mounted) {
        setState(() {
          serverResult.size = pages.length;
          serverResult.time =
              DateTime.now().difference(pageStart).inMilliseconds;
          serverResult.errorMessage = null;
        });
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (mounted) {
        setState(() {
          serverResult.size = 0;
          serverResult.time =
              DateTime.now().difference(pageStart).inMilliseconds;
          serverResult.errorMessage = errorMsg;
        });
      }
      debugPrint('Page list test error: $e');
    }
  }

  Future<void> _runAnimeTest() async {
    if (widget.testType == 'ping') {
      await _runPingTest();
      return;
    }

    final searchResults = await _runSearchTest();

    if (searchResult.size == 0 ||
        widget.testType == 'basic' ||
        searchResults == null) {
      return;
    }

    final firstResult = (searchResults.list?.isNotEmpty ?? false)
        ? searchResults.list!.first
        : null;
    if (firstResult == null) {
      return;
    }

    final detailedMedia = await _runDetailTest(firstResult);

    if (episodeResult.size == 0 || detailedMedia == null) {
      return;
    }

    if (widget.testType == 'full') {
      await _runServerTest(detailedMedia);
    }
  }

  Future<void> _runMangaTest() async {
    if (widget.testType == 'ping') {
      await _runPingTest();
      return;
    }

    final searchResults = await _runSearchTest();

    if (searchResult.size == 0 ||
        widget.testType == 'basic' ||
        searchResults == null) {
      return;
    }

    final firstResult = (searchResults.list?.isNotEmpty ?? false)
        ? searchResults.list!.first
        : null;
    if (firstResult == null) {
      return;
    }

    final detailedMedia = await _runDetailTest(firstResult);

    if (episodeResult.size == 0 || detailedMedia == null) {
      return;
    }

    if (widget.testType == 'full') {
      await _runPageListTest(detailedMedia);
    }
  }

  Future<void> _runNovelTest() async {
    // Novel doesn't support ping
    if (widget.testType == 'ping') {
      if (mounted) {
        setState(() {
          pingError = 'Test not supported for novels';
        });
      }
      return;
    }

    final searchResults = await _runSearchTest();

    if (searchResult.size == 0 ||
        widget.testType == 'basic' ||
        searchResults == null) {
      return;
    }

    final firstResult = (searchResults.list?.isNotEmpty ?? false)
        ? searchResults.list!.first
        : null;
    if (firstResult == null) {
      return;
    }

    final detailedMedia = await _runDetailTest(firstResult);

    if (episodeResult.size == 0 || detailedMedia == null) {
      return;
    }

    if (widget.testType == 'full') {
      await _runNovelContentTest(detailedMedia);
    }
  }

  Future<void> _runNovelContentTest(DMedia detailedMedia) async {
    final chapters = detailedMedia.episodes;
    if (chapters == null || chapters.isEmpty) {
      if (mounted) {
        setState(() {
          serverResult.errorMessage = 'No chapters available';
        });
      }
      return;
    }

    final contentStart = DateTime.now();
    try {
      final content = await widget.source.methods.getPageList(
        DEpisode(url: chapters.first.url, episodeNumber: "1"),
      );
      if (mounted) {
        setState(() {
          serverResult.size = content.length;
          serverResult.time =
              DateTime.now().difference(contentStart).inMilliseconds;
          serverResult.errorMessage = null;
        });
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (mounted) {
        setState(() {
          serverResult.size = 0;
          serverResult.time =
              DateTime.now().difference(contentStart).inMilliseconds;
          serverResult.errorMessage = errorMsg;
        });
      }
      debugPrint('Novel content test error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Extension Header
            Row(
              children: [
                _buildExtensionIcon(theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.source.name ?? 'Unknown',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isRunning)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Results
            if (widget.testType == 'ping') ...[
              _buildPingResult(theme),
            ] else if (widget.testType == 'basic') ...[
              _buildSearchResult(theme),
            ] else if (widget.testType == 'full') ...[
              _buildSearchResult(theme),
              const SizedBox(height: 8),
              _buildEpisodeResult(theme),
              const SizedBox(height: 8),
              _buildServerResult(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExtensionIcon(ColorScheme theme) {
    if (widget.source.iconUrl == null || widget.source.iconUrl!.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.extension,
          color: theme.primary,
        ),
      );
    }

    if (widget.source.iconUrl!.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.source.iconUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.extension,
              color: theme.primary,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(widget.source.iconUrl!),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.extension,
            color: theme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildPingResult(ColorScheme theme) {
    if (pingError != null) {
      return _buildResultRow(
        'Ping',
        pingError ?? 'Test not supported',
        false,
        theme,
      );
    }

    final text = pingTime != null ? '${pingTime}ms' : 'Testing...';
    return _buildResultRow('Ping', text, pingTime != null, theme);
  }

  Widget _buildSearchResult(ColorScheme theme) {
    if (searchResult.time == 0) {
      return _buildResultRow('Search', 'Testing...', false, theme);
    }

    final success = searchResult.size > 0;
    String text;

    if (!success && searchResult.errorMessage != null) {
      text = 'Error: ${searchResult.errorMessage}';
    } else if (success) {
      text = '${searchResult.size} results in ${searchResult.time}ms';
    } else {
      text = 'No results found';
    }

    return _buildResultRow('Search', text, success, theme);
  }

  Widget _buildEpisodeResult(ColorScheme theme) {
    if (episodeResult.time == 0) {
      return _buildResultRow('Episodes', 'Testing...', false, theme);
    }

    final success = episodeResult.size > 0;
    final label = _getEpisodeLabel();
    String text;

    if (!success && episodeResult.errorMessage != null) {
      text = 'Error: ${episodeResult.errorMessage}';
    } else if (success) {
      text = '${episodeResult.size} $label in ${episodeResult.time}ms';
    } else {
      text = 'No $label found';
    }

    return _buildResultRow(label, text, success, theme);
  }

  Widget _buildServerResult(ColorScheme theme) {
    if (serverResult.time == 0) {
      return _buildResultRow('Servers', 'Testing...', false, theme);
    }

    final success = serverResult.size > 0;
    final label = _getServerLabel();
    String text;

    if (!success && serverResult.errorMessage != null) {
      text = 'Error: ${serverResult.errorMessage}';
    } else if (success) {
      text = '${serverResult.size} $label in ${serverResult.time}ms';
    } else {
      text = 'No $label found';
    }

    return _buildResultRow(label, text, success, theme);
  }

  String _getEpisodeLabel() {
    switch (widget.itemType) {
      case ItemType.manga:
        return 'Chapters';
      case ItemType.novel:
        return 'Chapters';
      case ItemType.anime:
        return 'Episodes';
    }
  }

  String _getServerLabel() {
    switch (widget.itemType) {
      case ItemType.manga:
        return 'Images';
      case ItemType.novel:
        return 'Content';
      case ItemType.anime:
        return 'Servers';
    }
  }

  Widget _buildResultRow(
      String label, String result, bool success, ColorScheme theme) {
    return Row(
      children: [
        Icon(
          success ? Icons.check_circle : Icons.cancel,
          color: success ? Colors.green : theme.error,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: theme.onSurface,
                ),
              ),
              Text(
                result,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.onSurface,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
