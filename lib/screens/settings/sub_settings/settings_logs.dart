import 'dart:async';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class SettingsLogs extends StatefulWidget {
  const SettingsLogs({super.key});

  @override
  State<SettingsLogs> createState() => _SettingsLogsState();
}

class _SettingsLogsState extends State<SettingsLogs> {
  final List<LogEntry> _allLogs = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _expandedEntries = <int>{};
  final Set<int> _expandedMessages = <int>{};

  StreamSubscription<LogEntry>? _logSubscription;
  StreamSubscription<void>? _clearSubscription;
  LogLevel? _selectedLevel;
  String _searchQuery = '';
  bool _autoScroll = true;
  bool _isUserScrolling = false;
  bool _isLoadingLogs = true;
  int _loadedSequenceCutoff = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialLogs();
    _logSubscription = Logger.liveStream.listen((entry) {
      if (!mounted) return;
      if (_isLoadingLogs) return;
      if (entry.sequenceId != null && entry.sequenceId! <= _loadedSequenceCutoff) {
        return;
      }
      setState(() {
        _allLogs.add(entry);
      });
      if (_autoScroll && !_isUserScrolling) {
        _scrollToBottom();
      }
    });

    _clearSubscription = Logger.onClear.listen((_) {
      if (!mounted) return;
      setState(() {
        _allLogs.clear();
        _expandedEntries.clear();
        _expandedMessages.clear();
      });
    });

    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadInitialLogs() async {
    final snapshotSeq = Logger.totalLoggedCount;
    final fileLogs = await Logger.readAllFileLogs();
    if (!mounted) return;
    final postReadLive = Logger.recentLogs
        .where((e) => e.sequenceId != null && e.sequenceId! > snapshotSeq)
        .toList();
    setState(() {
      _allLogs
        ..clear()
        ..addAll(fileLogs)
        ..addAll(postReadLive);
      _loadedSequenceCutoff = Logger.totalLoggedCount;
      _isLoadingLogs = false;
    });
    if (_autoScroll) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _clearSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final isAtBottom = (maxScroll - currentScroll).abs() < 50;

    if (!isAtBottom && _autoScroll) {
      setState(() => _autoScroll = false);
    } else if (isAtBottom && !_autoScroll) {
      setState(() => _autoScroll = true);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  List<LogEntry> get _filteredLogs {
    final query = _searchQuery.toLowerCase().trim();
    return _allLogs.where((entry) {
      if (_selectedLevel != null && entry.level != _selectedLevel) {
        return false;
      }
      if (query.isNotEmpty) {
        return entry.message.toLowerCase().contains(query) ||
            entry.tag.toLowerCase().contains(query) ||
            (entry.error?.toString().toLowerCase().contains(query) ?? false);
      }
      return true;
    }).toList();
  }

  int _countForLevel(LogLevel? level) {
    if (level == null) return _allLogs.length;
    return _allLogs.where((e) => e.level == level).length;
  }

  Color _levelColor(LogLevel level, ThemeData theme) {
    return switch (level) {
      LogLevel.error => Colors.redAccent,
      LogLevel.warning => Colors.orangeAccent,
      LogLevel.info => Colors.lightBlueAccent,
      LogLevel.debug => theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
    };
  }

  void _showSettingsSheet() {
    final settings = Get.find<Settings>();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: AnymeXText(
                  context.l10n.logCapture,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => AnymeXTile.toggle(
                  icon: HugeIcons.strokeRoundedFile02,
                  title: context.l10n.writeLogToAFile,
                  subtitle: context.l10n.whenEnabledAnymexSavesLogsLocally,
                  value: settings.writeLogToFile.value,
                  onChanged: (value) => settings.saveWriteLogToFile(value),
                ),
              ),
              Obx(
                () => AnymeXTile(
                  icon: HugeIcons.strokeRoundedFolder01,
                  title: context.l10n.logDirectory,
                  subtitle: settings.customLogDirectory.value.isEmpty
                      ? 'Default (App Documents)'
                      : settings.customLogDirectory.value,
                  onTap: () async {
                    String? result =
                        await FilePicker.platform.getDirectoryPath();
                    if (result != null) {
                      settings.saveCustomLogDirectory(result);
                    }
                  },
                ),
              ),
              AnymeXTile(
                icon: HugeIcons.strokeRoundedDelete02,
                title: context.l10n.clearStoredLogFiles,
                subtitle: context.l10n.resetInMemoryAndDiskLogFiles,
                onTap: () async {
                  await Logger.clearLogs();
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final theme = Theme.of(context);
    final color = activeColor ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : theme.colorScheme.surfaceVariant.opaque(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 1.2 : 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnymeXText(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.25)
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AnymeXText(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? color
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChipsRow() {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    final h = isDesktop ? 24.0 : 16.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: h, vertical: 6.0),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'ALL',
            count: _countForLevel(null),
            isSelected: _selectedLevel == null,
            onTap: () => setState(() => _selectedLevel = null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'ERROR',
            count: _countForLevel(LogLevel.error),
            isSelected: _selectedLevel == LogLevel.error,
            activeColor: Colors.redAccent,
            onTap: () => setState(() => _selectedLevel = LogLevel.error),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'WARN',
            count: _countForLevel(LogLevel.warning),
            isSelected: _selectedLevel == LogLevel.warning,
            activeColor: Colors.orangeAccent,
            onTap: () => setState(() => _selectedLevel = LogLevel.warning),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'INFO',
            count: _countForLevel(LogLevel.info),
            isSelected: _selectedLevel == LogLevel.info,
            activeColor: Colors.lightBlueAccent,
            onTap: () => setState(() => _selectedLevel = LogLevel.info),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'DEBUG',
            count: _countForLevel(LogLevel.debug),
            isSelected: _selectedLevel == LogLevel.debug,
            activeColor: theme.colorScheme.onSurfaceVariant,
            onTap: () => setState(() => _selectedLevel = LogLevel.debug),
          ),
        ],
      ),
    );
  }

  Widget _buildLogTile(LogEntry entry, int index) {
    final theme = Theme.of(context);
    final color = _levelColor(entry.level, theme);
    final hasDetails = entry.error != null || entry.stackTrace != null;
    final isExpanded = _expandedEntries.contains(index);
    final isMessageExpanded = _expandedMessages.contains(index);
    final isLongMessage =
        '\n'.allMatches(entry.message).length >= 4 || entry.message.length > 220;
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    final h = isDesktop ? 24.0 : 16.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: h, vertical: 3.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.opaque(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: entry.toFormattedString()));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.logsCopiedToClipboard),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        onTap: hasDetails
            ? () {
                setState(() {
                  if (isExpanded) {
                    _expandedEntries.remove(index);
                  } else {
                    _expandedEntries.add(index);
                  }
                });
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: color.withOpacity(0.4),
                        width: 0.8,
                      ),
                    ),
                    child: AnymeXText(
                      entry.levelPrefix,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnymeXText(
                      entry.tag,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnymeXText(
                    entry.formattedTimestamp,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (hasDetails) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              AnymeXText(
                entry.message,
                maxLines: isLongMessage && !isMessageExpanded ? 4 : null,
                overflow: isLongMessage && !isMessageExpanded
                    ? TextOverflow.ellipsis
                    : TextOverflow.visible,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.9),
                  height: 1.35,
                ),
              ),
              if (isLongMessage) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isMessageExpanded) {
                        _expandedMessages.remove(index);
                      } else {
                        _expandedMessages.add(index);
                      }
                    });
                  },
                  child: AnymeXText(
                    isMessageExpanded ? 'Show less' : 'Read more',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
              if (hasDetails && isExpanded) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AnymeXText(
                            context.l10n.errorDetails,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent.shade100,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              final text = StringBuffer();
                              if (entry.error != null) {
                                text.writeln('ERROR: ${entry.error}');
                              }
                              if (entry.stackTrace != null) {
                                text.writeln('STACK: ${entry.stackTrace}');
                              }
                              Clipboard.setData(ClipboardData(text: text.toString()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.errorCopiedToClipboard),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Row(
                                children: [
                                  Icon(
                                    HugeIcons.strokeRoundedCopy01,
                                    size: 13,
                                    color: Colors.redAccent.shade100,
                                  ),
                                  const SizedBox(width: 4),
                                  AnymeXText(
                                    context.l10n.actionCopy,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.redAccent.shade100,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (entry.error != null)
                        AnymeXText(
                          '${entry.error}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.red.shade200,
                          ),
                        ),
                      if (entry.stackTrace != null) ...[
                        const SizedBox(height: 6),
                        AnymeXText(
                          '${entry.stackTrace}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              HugeIcons.strokeRoundedDocumentCode,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            AnymeXText(
              _searchQuery.isNotEmpty
                  ? 'No logs match "$_searchQuery"'
                  : 'No logs recorded yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logs = _filteredLogs;

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: context.l10n.logs,
      headerEnableSearch: true,
      headerSearchController: _searchController,
      headerSearchHint: 'Search logs...',
      onHeaderSearchChanged: (val) => setState(() => _searchQuery = val),
      onHeaderSearchClear: () => setState(() => _searchQuery = ''),
      headerBottom: _buildFilterChipsRow(),
      headerBottomHeight: 48.0,
      headerAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: _autoScroll ? context.l10n.autoScrollOn : context.l10n.autoScrollOff,
            icon: Icon(
              Icons.vertical_align_bottom_rounded,
              color: _autoScroll
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              size: 20,
            ),
            onPressed: () {
              setState(() => _autoScroll = !_autoScroll);
              if (_autoScroll) _scrollToBottom();
            },
          ),
          IconButton(
            tooltip: context.l10n.copyLogs,
            icon: const Icon(HugeIcons.strokeRoundedCopy01, size: 20),
            onPressed: () => Logger.copyLogs(
              filterLevel: _selectedLevel,
              searchQuery: _searchQuery,
            ),
          ),
          IconButton(
            tooltip: context.l10n.shareLogs,
            icon: const Icon(HugeIcons.strokeRoundedShare08, size: 20),
            onPressed: () => Logger.share(),
          ),
          IconButton(
            tooltip: context.l10n.clearLogs,
            icon: const Icon(HugeIcons.strokeRoundedDelete02, size: 20),
            onPressed: () async => await Logger.clearLogs(),
          ),
          IconButton(
            tooltip: context.l10n.settings,
            icon: const Icon(HugeIcons.strokeRoundedSettings01, size: 20),
            onPressed: _showSettingsSheet,
          ),
        ],
      ),
      body: Builder(
        builder: (ctx) {
          final topPadding = AnymeXHeaderScope.of(ctx);

          if (_isLoadingLogs) {
            return Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          if (logs.isEmpty) {
            return Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: _buildEmptyState(),
            );
          }

          return Listener(
            onPointerDown: (_) => _isUserScrolling = true,
            onPointerUp: (_) => _isUserScrolling = false,
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(0, topPadding + 4, 0, 30),
              itemCount: logs.length,
              itemBuilder: (context, index) =>
                  _buildLogTile(logs[index], index),
            ),
          );
        },
      ),
    );
  }
}
