// lib/screens/extensions/extension_test_item.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';

class TestResult {
  int size = 0;
  int time = 0;
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

  Future<void> _runAnimeTest() async {
    if (widget.testType == 'ping') {
      if (mounted) {
        setState(() {
          pingError = 'Test not supported';
        });
      }
      return;
    }

    // Search test
    dynamic searchResults;
    final searchStart = DateTime.now();
    try {
      searchResults = await widget.source.methods.search(widget.searchQuery, 1, []);
      if (mounted) {
        setState(() {
          searchResult.size = searchResults?.list?.length ?? 0;
          searchResult.time =
              DateTime.now().difference(searchStart).inMilliseconds;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          searchResult.size = 0;
          searchResult.time =
              DateTime.now().difference(searchStart).inMilliseconds;
        });
      }
    }

    if (searchResult.size == 0 || widget.testType == 'basic' || searchResults == null || searchResults.list.isEmpty) {
      return;
    }

    // Episode test
    DMedia? detailedMedia;
    final episodeStart = DateTime.now();
    try {
        detailedMedia = await widget.source.methods.getDetail(searchResults.list.first);
      if (mounted) {
        setState(() {
          episodeResult.size = detailedMedia?.episodes?.length ?? 0;
          episodeResult.time =
              DateTime.now().difference(episodeStart).inMilliseconds;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          episodeResult.size = 0;
          episodeResult.time =
              DateTime.now().difference(episodeStart).inMilliseconds;
        });
      }
    }

    if (episodeResult.size == 0 || detailedMedia == null || (detailedMedia.episodes?.isEmpty ?? true)) {
      return;
    }

    // Server test
    final serverStart = DateTime.now();
    try {
      final servers = await widget.source.methods.getVideoList(detailedMedia.episodes!.first);
      if (mounted) {
        setState(() {
          serverResult.size = servers.length;
          serverResult.time =
              DateTime.now().difference(serverStart).inMilliseconds;
        });
      }
    }
    catch (e) {
      if (mounted) {
        setState(() {
          serverResult.size = 0;
          serverResult.time =
              DateTime.now().difference(serverStart).inMilliseconds;
        });
      }
    }
  }

  Future<void> _runMangaTest() async {
    if (widget.testType == 'ping') {
      if (mounted) {
        setState(() {
          pingError = 'Test not supported';
        });
      }
      return;
    }

    // Search test
    dynamic searchResults;
    final searchStart = DateTime.now();
    try {
      searchResults = await widget.source.methods.search(widget.searchQuery, 1, []);
      if (mounted) {
        setState(() {
          searchResult.size = searchResults?.list?.length ?? 0;
          searchResult.time =
              DateTime.now().difference(searchStart).inMilliseconds;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          searchResult.size = 0;
          searchResult.time =
              DateTime.now().difference(searchStart).inMilliseconds;
        });
      }
    }

    if (searchResult.size == 0 || widget.testType == 'basic' || searchResults == null || searchResults.list.isEmpty) {
      return;
    }

    // Chapter test
    DMedia? detailedMedia;
    final chapterStart = DateTime.now();
    try {
        detailedMedia = await widget.source.methods.getDetail(searchResults.list.first);
      if (mounted) {
        setState(() {
          episodeResult.size = detailedMedia?.episodes?.length ?? 0;
          episodeResult.time =
              DateTime.now().difference(chapterStart).inMilliseconds;
        });
      }
    }
    catch (e) {
      if (mounted) {
        setState(() {
          episodeResult.size = 0;
          episodeResult.time =
              DateTime.now().difference(chapterStart).inMilliseconds;
        });
      }
    }

    if (episodeResult.size == 0 || detailedMedia == null || (detailedMedia.episodes?.isEmpty ?? true)) {
      return;
    }

    // Image test
    final imageStart = DateTime.now();
    try {
      final pages = await widget.source.methods.getPageList(DEpisode(url: detailedMedia.episodes!.first.url, episodeNumber: "1"));
      if (mounted) {
        setState(() {
          serverResult.size = pages.length;
          serverResult.time =
              DateTime.now().difference(imageStart).inMilliseconds;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          serverResult.size = 0;
          serverResult.time =
              DateTime.now().difference(imageStart).inMilliseconds;
        });
      }
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

    // Search test
    dynamic searchResults;
    final searchStart = DateTime.now();
    try {
      searchResults = await widget.source.methods.search(widget.searchQuery, 1, []);
      if (mounted) {
        setState(() {
          searchResult.size = searchResults?.list?.length ?? 0;
          searchResult.time =
              DateTime.now().difference(searchStart).inMilliseconds;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          searchResult.size = 0;
          searchResult.time =
              DateTime.now().difference(searchStart).inMilliseconds;
        });
      }
    }

    if (searchResult.size == 0 || widget.testType == 'basic' || searchResults == null || searchResults.list.isEmpty) {
      return;
    }

    // Book/Chapter test
    final chapterStart = DateTime.now();
    try {
        final detailedMedia = await widget.source.methods.getDetail(searchResults.list.first);
        if (mounted) {
          setState(() {
            episodeResult.size = detailedMedia.episodes?.length ?? 0;
            episodeResult.time =
                DateTime.now().difference(chapterStart).inMilliseconds;
          });
        }
    } catch (e) {
      if (mounted) {
        setState(() {
          episodeResult.size = 0;
          episodeResult.time =
              DateTime.now().difference(chapterStart).inMilliseconds;
        });
      }
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
    final text = success
        ? '${searchResult.size} results in ${searchResult.time}ms'
        : 'No results found';
    return _buildResultRow('Search', text, success, theme);
  }

  Widget _buildEpisodeResult(ColorScheme theme) {
    if (episodeResult.time == 0) {
      return _buildResultRow('Episodes', 'Testing...', false, theme);
    }

    final success = episodeResult.size > 0;
    final label = widget.itemType == ItemType.manga ? 'Chapters' : 'Episodes';
    final text = success
        ? '${episodeResult.size} $label in ${episodeResult.time}ms'
        : 'No results found';
    return _buildResultRow(label, text, success, theme);
  }

  Widget _buildServerResult(ColorScheme theme) {
    if (serverResult.time == 0) {
      return _buildResultRow('Servers', 'Testing...', false, theme);
    }

    final success = serverResult.size > 0;
    final label = widget.itemType == ItemType.manga ? 'Images' : 'Servers';
    final text = success
        ? '${serverResult.size} $label in ${serverResult.time}ms'
        : 'No results found';
    return _buildResultRow(label, text, success, theme);
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
