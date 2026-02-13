import 'dart:async';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/widgets/custom_widgets/custom_button.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'ExtensionItem.dart';

class ExtensionList extends StatefulWidget {
  final bool installed;
  final ItemType itemType;
  final String query;
  final String selectedLanguage;
  final bool showRecommended;

  const ExtensionList({
    required this.installed,
    required this.query,
    required this.itemType,
    required this.selectedLanguage,
    this.showRecommended = true,
    super.key,
  });

  @override
  State<ExtensionList> createState() => _ExtensionListState();
}

class _ExtensionListState extends State<ExtensionList>
    with AutomaticKeepAliveClientMixin {
  final _controller = ScrollController();

  final _installedEntries = <Source>[].obs;
  final _updateEntries = <Source>[].obs;
  final _notInstalledEntries = <Source>[].obs;
  final _recommendedEntries = <Source>[].obs;

  List<Worker>? _workers;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _computeAllData();
    _setupReactiveListeners();
  }

  void _setupReactiveListeners() {
    // Listen to both installed and available lists for this item type
    _workers = [
      ever(_getInstalledList(), (_) => _computeAllData()),
      ever(_getAvailableList(), (_) => _computeAllData()),
    ];
  }

  RxList<Source> _getInstalledList() {
    return switch (widget.itemType) {
      ItemType.manga => sourceController.installedMangaExtensions,
      ItemType.anime => sourceController.installedExtensions,
      ItemType.novel => sourceController.installedNovelExtensions,
    };
  }

  RxList<Source> _getAvailableList() {
    return switch (widget.itemType) {
      ItemType.manga => sourceController.availableMangaExtensions,
      ItemType.anime => sourceController.availableExtensions,
      ItemType.novel => sourceController.availableNovelExtensions,
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_workers != null) {
      for (var w in _workers!) {
        w.dispose();
      }
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(ExtensionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query ||
        oldWidget.selectedLanguage != widget.selectedLanguage) {
      _computeAllData();
    }
  }

  void _computeAllData() {
    if (!mounted) return;

    final installed = _getInstalledList().toList();
    final available = _getAvailableList().toList();

    if (widget.installed) {
      _installedEntries.value = _filterData(installed);
      _updateEntries.value =
          _filterData(installed.where((s) => s.hasUpdate == true).toList());
      _notInstalledEntries.clear();
      _recommendedEntries.clear();
    } else {
      final installedIds = installed.map((e) => '${e.name}_${e.lang}').toSet();

      final notInstalled = available.where((a) {
        final key = '${a.name}_${a.lang}_${a.extensionType?.name ?? 'PC'}';
        return !installedIds.contains(key);
      }).toList();

      _notInstalledEntries.value = _filterData(notInstalled);
      _installedEntries.clear();
      _updateEntries.clear();

      if (widget.showRecommended) {
        _recommendedEntries.value = _computeRecommended(available);
      } else {
        _recommendedEntries.clear();
      }
    }
  }

  List<Source> _computeRecommended(List<Source> available) {
    const extens = ['anymex'];
    const preferredLangs = {'en', 'all', 'multi'};

    final recommended = available.where((element) {
      final name = element.name?.toLowerCase() ?? '';
      final lang = element.lang?.toLowerCase() ?? '';
      return extens.any((ext) => name.contains(ext)) &&
          preferredLangs.contains(lang);
    }).toList();

    return _filterData(recommended);
  }

  Future<void> _refreshData() async {
    await sourceController.fetchRepos();
    _computeAllData();
  }

  List<Source> _filterData(List<Source> data) {
    if (data.isEmpty) return data;

    final lang = widget.selectedLanguage;
    final query = widget.query.toLowerCase();
    final hasLangFilter = lang != 'all';
    final hasQuery = query.isNotEmpty;

    if (!hasLangFilter && !hasQuery) return data;

    final targetLang = hasLangFilter ? completeLanguageCode(lang) : '';

    return data.where((element) {
      if (hasLangFilter && (element.lang?.toLowerCase() ?? '') != targetLang) {
        return false;
      }
      if (hasQuery && !(element.name?.toLowerCase() ?? '').contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Obx(() {
          final installed = _installedEntries.toList();
          final updates = _updateEntries.toList();
          final notInstalled = _notInstalledEntries.toList();
          final recommended = _recommendedEntries.toList();

          final isEmpty = widget.installed
              ? installed.isEmpty && updates.isEmpty
              : notInstalled.isEmpty &&
                  (!widget.showRecommended || recommended.isEmpty);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: CustomScrollView(
              controller: _controller,
              slivers: [
                if (widget.showRecommended && recommended.isNotEmpty)
                  _buildSection('Recommended', recommended),
                if (widget.installed && updates.isNotEmpty)
                  _buildUpdateSection(updates),
                if (widget.installed && installed.isNotEmpty)
                  _buildSection(null, installed),
                if (!widget.installed && notInstalled.isNotEmpty)
                  _buildGroupedSection(notInstalled),
                if (isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'No extensions found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSection(String? title, List<Source> entries) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0 && title != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            );
          }
          final itemIndex = title != null ? index - 1 : index;
          if (itemIndex < 0 || itemIndex >= entries.length) {
            return const SizedBox.shrink();
          }
          final source = entries[itemIndex];
          return ExtensionListTileWidget(
            key: ValueKey(source.id),
            source: source,
            mediaType: widget.itemType,
            onUpdate: _computeAllData,
          );
        },
        childCount: entries.length + (title != null ? 1 : 0),
      ),
    );
  }

  Widget _buildUpdateSection(List<Source> updates) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Update Pending',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  AnymeXButton(
                    variant: ButtonVariant.outline,
                    onTap: () => _updateAllExtensions(updates),
                    child: const Text(
                      'Update All',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }
          final source = updates[index - 1];
          return ExtensionListTileWidget(
            key: ValueKey('update_${source.id}'),
            source: source,
            mediaType: widget.itemType,
            onUpdate: _computeAllData,
          );
        },
        childCount: updates.length + 1,
      ),
    );
  }

  Widget _buildGroupedSection(List<Source> entries) {
    // Pre-group by language
    final grouped = <String, List<Source>>{};
    for (final source in entries) {
      final lang = completeLanguageName(source.lang?.toLowerCase() ?? '');
      grouped.putIfAbsent(lang, () => []).add(source);
    }

    final sortedKeys = grouped.keys.toList()..sort();

    // Flatten into a single list with headers
    final items = <_ListItem>[];
    for (final key in sortedKeys) {
      items.add(_ListItem.header(key));
      final sources = grouped[key]!
        ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      for (final source in sources) {
        items.add(_ListItem.source(source));
      }
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          if (item.isHeader) {
            return Padding(
              padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
              child: Text(
                item.headerTitle!,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            );
          }
          return ExtensionListTileWidget(
            key: ValueKey(item.source!.id),
            source: item.source!,
            mediaType: widget.itemType,
            onUpdate: _computeAllData,
          );
        },
        childCount: items.length,
      ),
    );
  }

  Future<void> _updateAllExtensions(List<Source> updateEntries) async {
    if (updateEntries.isEmpty) return;
    try {
      final futures = updateEntries
          .map((source) =>
              source.extensionType?.getManager().updateSource(source))
          .whereType<Future<dynamic>>();
      await Future.wait(futures);
      _computeAllData();
    } catch (e) {
      debugPrint('Error updating extensions: $e');
    }
  }
}

/// Helper for flattened grouped list
class _ListItem {
  final bool isHeader;
  final String? headerTitle;
  final Source? source;

  _ListItem.header(this.headerTitle)
      : isHeader = true,
        source = null;
  _ListItem.source(this.source)
      : isHeader = false,
        headerTitle = null;
}
