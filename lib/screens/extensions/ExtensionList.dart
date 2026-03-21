import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_button.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  Worker? _installedSyncWorker;
  List<String> _localOrderIds = const <String>[];
  List<String>? _pendingCommitOrderIds;
  bool _commitScheduled = false;

  @override
  bool get wantKeepAlive => true;

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
  void initState() {
    super.initState();

    _localOrderIds = sourceController.getExtensionOrder(widget.itemType);

    _installedSyncWorker = ever(_getInstalledList(), (_) {
      _syncLocalOrderAfterFrame();
    });
  }

  @override
  void dispose() {
    _installedSyncWorker?.dispose();
    _controller.dispose();
    super.dispose();
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
  }

  List<Source> _buildNotInstalledEntries(
    List<Source> installed,
    List<Source> available,
  ) {
    final installedIds =
        installed.map((e) => '${e.name}_${e.lang}_${e.extensionType}').toSet();

    final notInstalled = available.where((source) {
      final key = '${source.name}_${source.lang}_${source.extensionType}';
      return !installedIds.contains(key);
    }).toList(growable: false);

    return _filterData(notInstalled);
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

  String _idFor(Source source) => source.id?.toString() ?? '';

  List<Source> _applyOrder(List<Source> sources) {
    if (sources.isEmpty) return sources;
    final order = _localOrderIds;
    if (order.isEmpty) return sources;

    final orderIndex = <String, int>{};
    for (var i = 0; i < order.length; i++) {
      orderIndex[order[i]] = i;
    }

    final sorted = List<Source>.from(sources);
    sorted.sort((a, b) {
      final aIdx = orderIndex[_idFor(a)] ?? order.length;
      final bIdx = orderIndex[_idFor(b)] ?? order.length;
      return aIdx.compareTo(bIdx);
    });
    return sorted;
  }

  void _syncLocalOrderAfterFrame() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final installed = _getInstalledList().toList(growable: false);
      final installedIds = installed.map(_idFor).where((e) => e.isNotEmpty);
      final installedIdSet = installedIds.toSet();

      final currentLocal = _localOrderIds;
      if (currentLocal.isEmpty) {
        setState(() {
          _localOrderIds = installed
              .map(_idFor)
              .where((e) => e.isNotEmpty)
              .toList(growable: false);
        });
        return;
      }

      final reconciled = <String>[];
      for (final id in currentLocal) {
        if (id.isNotEmpty && installedIdSet.contains(id)) {
          reconciled.add(id);
        }
      }
      for (final id in installedIds) {
        if (!reconciled.contains(id)) {
          reconciled.add(id);
        }
      }

      if (reconciled.length == currentLocal.length &&
          _listEquals(reconciled, currentLocal)) {
        return;
      }

      setState(() {
        _localOrderIds = List.unmodifiable(reconciled);
      });
    });
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _scheduleCommitOrder(List<String> orderIds) {
    _pendingCommitOrderIds = List.unmodifiable(orderIds);
    if (_commitScheduled) return;
    _commitScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _commitScheduled = false;
      if (!mounted) return;

      final ids = _pendingCommitOrderIds;
      _pendingCommitOrderIds = null;
      if (ids == null) return;

      // Avoid mutating reactive lists during the reorder/layout phase.
      // Commit the order after the current frame settles.
      if (SchedulerBinding.instance.schedulerPhase ==
              SchedulerPhase.persistentCallbacks ||
          SchedulerBinding.instance.schedulerPhase ==
              SchedulerPhase.midFrameMicrotasks) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          sourceController.saveExtensionOrder(widget.itemType, ids);
        });
        return;
      }

      sourceController.saveExtensionOrder(widget.itemType, ids);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    final allInstalled = _getInstalledList().toList(growable: false);
    final visible = _applyOrder(_filterData(allInstalled));

    if (oldIndex < 0 || oldIndex >= visible.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex < 0 || newIndex > visible.length) return;

    final reorderedVisible = List<Source>.from(visible);
    final item = reorderedVisible.removeAt(oldIndex);
    reorderedVisible.insert(newIndex, item);

    final visibleIds =
        reorderedVisible.map(_idFor).where((e) => e.isNotEmpty).toList();

    final allIds = allInstalled.map(_idFor).where((e) => e.isNotEmpty).toSet();
    final prior =
        _localOrderIds.isNotEmpty ? _localOrderIds : allInstalled.map(_idFor);

    final merged = <String>[];
    for (final id in visibleIds) {
      if (allIds.contains(id) && !merged.contains(id)) merged.add(id);
    }
    for (final id in prior) {
      if (allIds.contains(id) && !merged.contains(id)) merged.add(id);
    }
    for (final id in allInstalled.map(_idFor)) {
      if (allIds.contains(id) && !merged.contains(id)) merged.add(id);
    }

    setState(() {
      _localOrderIds = List.unmodifiable(merged);
    });
    _scheduleCommitOrder(merged);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Obx(() {
          final installedSources = _getInstalledList().toList(growable: false);
          final availableSources = _getAvailableList().toList(growable: false);

          final installed = widget.installed
              ? _applyOrder(_filterData(installedSources))
              : const <Source>[];
          final updates = widget.installed
              ? _filterData(
                  installedSources
                      .where((source) => source.hasUpdate == true)
                      .toList(growable: false),
                )
              : const <Source>[];
          final notInstalled = widget.installed
              ? const <Source>[]
              : _buildNotInstalledEntries(installedSources, availableSources);
          final recommended = !widget.installed && widget.showRecommended
              ? _computeRecommended(availableSources)
              : const <Source>[];

          final isEmpty = widget.installed
              ? installed.isEmpty && updates.isEmpty
              : notInstalled.isEmpty &&
                  (!widget.showRecommended || recommended.isEmpty);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: widget.installed
                ? _buildInstalledView(installed, updates)
                : CustomScrollView(
                    controller: _controller,
                    slivers: [
                      if (widget.showRecommended && recommended.isNotEmpty)
                        _buildSection('Recommended', recommended),
                      if (!widget.installed && notInstalled.isNotEmpty)
                        _buildGroupedSection(notInstalled),
                      if (isEmpty)
                        const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'No extensions found',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
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

  Widget _buildInstalledView(List<Source> installed, List<Source> updates) {
    final hasUpdates = updates.isNotEmpty;
    final hasInstalled = installed.isNotEmpty;

    if (!hasUpdates && !hasInstalled) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No extensions found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // When there are pending updates we need a shared scroll view so the
    // update header and the reorderable list scroll together. Use
    // SliverReorderableList which is the sliver counterpart to
    // ReorderableListView and natively supports auto-scroll.
    if (hasUpdates) {
      return CustomScrollView(
        controller: _controller,
        slivers: [
          _buildUpdateSection(updates),
          if (hasInstalled) ...[
            SliverToBoxAdapter(child: _buildInstalledHeader()),
            SliverReorderableList(
              itemCount: installed.length,
              onReorder: _onReorder,
              proxyDecorator: _proxyDecorator,
              itemBuilder: (context, index) {
                final source = installed[index];
                return _DraggableExtensionTile(
                  key: ValueKey(source.id),
                  index: index,
                  source: source,
                  mediaType: widget.itemType,
                );
              },
            ),
          ],
        ],
      );
    }

    // No updates — let ReorderableListView own the entire scroll so its
    // built-in auto-scroll logic works without any workarounds.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInstalledHeader(),
        Expanded(
          child: ReorderableListView.builder(
            onReorder: _onReorder,
            proxyDecorator: _proxyDecorator,
            buildDefaultDragHandles: false,
            itemCount: installed.length,
            itemBuilder: (context, index) {
              final source = installed[index];
              return _DraggableExtensionTile(
                key: ValueKey(source.id),
                index: index,
                source: source,
                mediaType: widget.itemType,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInstalledHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Installed',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.drag_indicator_rounded,
            size: 14,
            color: Colors.grey.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            'Hold to reorder',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = 1.02 + animation.value * 0.01;
        return Transform.scale(
          scale: scale,
          child: Material(
            elevation: 8 * animation.value,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
        );
      },
      child: child,
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
          );
        },
        childCount: updates.length + 1,
      ),
    );
  }

  Widget _buildGroupedSection(List<Source> entries) {
    final grouped = <String, List<Source>>{};
    for (final source in entries) {
      final lang = completeLanguageName(source.lang?.toLowerCase() ?? '');
      grouped.putIfAbsent(lang, () => []).add(source);
    }

    final sortedKeys = grouped.keys.toList()..sort();

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
          .map((source) => source.update())
          .whereType<Future<dynamic>>();
      await Future.wait(futures);
    } catch (e) {
      debugPrint('Error updating extensions: $e');
    }
  }
}

class _DraggableExtensionTile extends StatelessWidget {
  final int index;
  final Source source;
  final ItemType mediaType;

  const _DraggableExtensionTile({
    super.key,
    required this.index,
    required this.source,
    required this.mediaType,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ReorderableDragStartListener(
          index: index,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(
              Icons.drag_indicator_rounded,
              color: context.colors.onSurface.withValues(alpha: 0.35),
              size: 20,
            ),
          ),
        ),
        Expanded(
          child: ExtensionListTileWidget(
            source: source,
            mediaType: mediaType,
          ),
        ),
      ],
    );
  }
}

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
