import 'dart:async';
import 'dart:io';

import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';

enum TestState { notStarted, running, completed }

class TestResult {
  int size = 0;
  int time = 0;
  String? errorMessage;
  TestState state = TestState.notStarted;
}

class ExtensionTestResultItem extends StatefulWidget {
  final Source source;
  final ItemType itemType;
  final String testType;
  final String searchQuery;
  final bool autostart;

  const ExtensionTestResultItem({
    super.key,
    required this.source,
    required this.itemType,
    required this.testType,
    required this.searchQuery,
    this.autostart = true,
  });

  @override
  State<ExtensionTestResultItem> createState() =>
      ExtensionTestResultItemState();
}

class ExtensionTestResultItemState extends State<ExtensionTestResultItem> {
  late final TestResult pingResult;
  late final TestResult searchResult;
  late final TestResult detailResult;
  late final TestResult contentResult;

  @override
  void initState() {
    super.initState();
    pingResult = TestResult();
    searchResult = TestResult();
    detailResult = TestResult();
    contentResult = TestResult();

    if (widget.autostart) {
      startTest();
    }
  }

  bool get isRunning =>
      pingResult.state == TestState.running ||
      searchResult.state == TestState.running ||
      detailResult.state == TestState.running ||
      contentResult.state == TestState.running;

  Future<T?> _executeTest<T>(
    TestResult result,
    Future<T> Function() testFn, {
    void Function(T value)? onResult,
  }) async {
    if (!mounted) return null;
    setState(() => result.state = TestState.running);

    final stopwatch = Stopwatch()..start();
    try {
      final value = await testFn();
      stopwatch.stop();
      if (mounted) {
        setState(() {
          result.time = stopwatch.elapsedMilliseconds;
          result.errorMessage = null;
          onResult?.call(value);
          result.state = TestState.completed;
        });
      }
      return value;
    } catch (e) {
      stopwatch.stop();
      if (mounted) {
        setState(() {
          result.time = stopwatch.elapsedMilliseconds;
          result.errorMessage = e.toString();
          result.state = TestState.completed;
        });
      }
      debugPrint('Test error for ${widget.source.name}: $e');
      return null;
    }
  }

  Future<void> startTest() async {
    try {
      if (widget.testType == 'ping') {
        await _runPingTest();
        return;
      }

      final searchResults = await _runSearchTest();
      if (_isTestAborted(searchResult) ||
          widget.testType == 'basic' ||
          searchResults == null) {
        return;
      }

      final firstResult = searchResults.list?.first;
      if (firstResult == null) return;

      final detailedMedia = await _runDetailTest(firstResult);
      if (_isTestAborted(detailResult) || detailedMedia == null) {
        return;
      }

      if (widget.testType == 'full' && widget.itemType != ItemType.novel) {
        await _runContentTest(detailedMedia);
      }
    } catch (e) {
      debugPrint('Unhandled test error for ${widget.source.name}: $e');
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  bool _isTestAborted(TestResult result) {
    return result.errorMessage != null ||
        (result.state == TestState.completed && result.size == 0);
  }

  Future<void> _runPingTest() async {
    await _executeTest(pingResult, () => widget.source.methods.getPopular(1));
  }

  Future<dynamic> _runSearchTest() async {
    if (widget.searchQuery.isEmpty) {
      if (mounted) {
        setState(() {
          searchResult.errorMessage = 'Search query is empty';
          searchResult.state = TestState.completed;
        });
      }
      return null;
    }

    return await _executeTest(
      searchResult,
      () => widget.source.methods.search(widget.searchQuery, 1, []),
      onResult: (result) {
        searchResult.size = result?.list?.length ?? 0;
      },
    );
  }

  Future<DMedia?> _runDetailTest(dynamic searchResult) async {
    return await _executeTest(
      detailResult,
      () => widget.source.methods.getDetail(searchResult),
      onResult: (result) {
        detailResult.size = result.episodes?.length ?? 0;
      },
    );
  }

  Future<void> _runContentTest(DMedia detailedMedia) async {
    final episodes = detailedMedia.episodes;
    if (episodes == null || episodes.isEmpty) {
      if (mounted) {
        setState(() {
          contentResult.errorMessage = widget.itemType == ItemType.anime
              ? 'No episodes available'
              : 'No chapters available';
          contentResult.state = TestState.completed;
        });
      }
      return;
    }

    final firstEpisode = episodes.first;
    switch (widget.itemType) {
      case ItemType.anime:
        await _executeTest(
          contentResult,
          () => widget.source.methods.getVideoList(firstEpisode),
          onResult: (result) => contentResult.size = result.length,
        );
        break;
      case ItemType.manga:
      case ItemType.novel:
        await _executeTest(
          contentResult,
          () => widget.source.methods.getPageList(firstEpisode),
          onResult: (result) => contentResult.size = result.length,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildExtensionIcon(theme),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.source.name ?? 'Unknown',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.onSurface,
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
          if (widget.testType == 'ping')
            _buildResultDisplay(
              'Ping',
              pingResult,
              (r) => '${r.time}ms',
              theme,
              checkSize: false,
            ),
          if (widget.testType == 'basic' || widget.testType == 'full')
            _buildResultDisplay(
              'Search',
              searchResult,
              (r) => '${r.size} results in ${r.time}ms',
              theme,
            ),
          if (widget.testType == 'full') ...[
            const SizedBox(height: 8),
            _buildResultDisplay(
              _getEpisodeLabel(),
              detailResult,
              (r) => '${r.size} ${_getEpisodeLabel()} in ${r.time}ms',
              theme,
            ),
            if (widget.itemType != ItemType.novel) ...[
              const SizedBox(height: 8),
              _buildResultDisplay(
                _getServerLabel(),
                contentResult,
                (r) => '${r.size} ${_getServerLabel()} in ${r.time}ms',
                theme,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildResultDisplay(
    String label,
    TestResult result,
    String Function(TestResult) textBuilder,
    ColorScheme theme, {
    bool checkSize = true,
  }) {
    String text;
    bool success = false;
    bool isLoading = result.state == TestState.running;

    if (isLoading) {
      text = 'Testing...';
    } else if (result.state == TestState.notStarted) {
      text = 'Not tested';
    } else {
      if (result.errorMessage != null) {
        text = 'Error: ${result.errorMessage}';
      } else {
        final hasResult = checkSize ? result.size > 0 : true;
        if (hasResult) {
          text = textBuilder(result);
          success = true;
        } else {
          text = 'No results found';
        }
      }
    }

    return _buildResultRow(label, text, success, theme, isLoading: isLoading);
  }

  Widget _buildResultRow(
      String label, String result, bool success, ColorScheme theme,
      {bool isLoading = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLoading)
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.primary,
            ),
          )
        else
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? theme.primary : theme.error,
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
                  color: theme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                result,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.onSurface,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExtensionIcon(ColorScheme theme) {
    if (widget.source.iconUrl == null || widget.source.iconUrl!.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.extension, color: theme.primary, size: 24),
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
              color: theme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.extension, color: theme.primary, size: 24),
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
            color: theme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.extension, color: theme.primary, size: 24),
        ),
      ),
    );
  }

  String _getEpisodeLabel() {
    switch (widget.itemType) {
      case ItemType.anime:
        return 'Episodes';
      case ItemType.manga:
      case ItemType.novel:
        return 'Chapters';
    }
  }

  String _getServerLabel() {
    switch (widget.itemType) {
      case ItemType.anime:
        return 'Servers';
      case ItemType.manga:
        return 'Pages';
      case ItemType.novel:
        return 'Content';
    }
  }
}
