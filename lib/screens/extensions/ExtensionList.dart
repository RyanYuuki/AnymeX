import 'dart:async';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/widgets/custom_widgets/custom_button.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:grouped_list/sliver_grouped_list.dart';
import 'ExtensionItem.dart';

class Extension extends StatefulWidget {
  final bool installed;
  final ItemType itemType;
  final String query;
  final String selectedLanguage;
  final bool showRecommended;

  const Extension({
    required this.installed,
    required this.query,
    required this.itemType,
    required this.selectedLanguage,
    this.showRecommended = true,
    super.key,
  });

  @override
  State<Extension> createState() => _ExtensionScreenState();
}

class _ExtensionScreenState extends State<Extension>
    with AutomaticKeepAliveClientMixin {
  final controller = ScrollController();

  final Map<String, List<Source>> _cachedData = {};
  String _lastQuery = '';
  String _lastLanguage = '';
  ItemType? _lastItemType;
  bool? _lastInstalled;

  Timer? _debounceTimer;

  static const String _installedKey = 'installed';
  static const String _updateKey = 'update';
  static const String _notInstalledKey = 'notInstalled';
  static const String _recommendedKey = 'recommended';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  @override
  void dispose() {
    controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(Extension oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.query != widget.query ||
        oldWidget.selectedLanguage != widget.selectedLanguage ||
        oldWidget.itemType != widget.itemType ||
        oldWidget.installed != widget.installed) {
      _invalidateCacheIfNeeded();
    }
  }

  void _initializeCache() {
    _lastQuery = widget.query;
    _lastLanguage = widget.selectedLanguage;
    _lastItemType = widget.itemType;
    _lastInstalled = widget.installed;
    _updateCache();
  }

  void _invalidateCacheIfNeeded() {
    bool needsUpdate = false;

    if (_lastQuery != widget.query) {
      needsUpdate = true;
      _lastQuery = widget.query;
    }

    if (_lastLanguage != widget.selectedLanguage) {
      needsUpdate = true;
      _lastLanguage = widget.selectedLanguage;
    }

    if (_lastItemType != widget.itemType) {
      needsUpdate = true;
      _lastItemType = widget.itemType;
    }

    if (_lastInstalled != widget.installed) {
      needsUpdate = true;
      _lastInstalled = widget.installed;
    }

    if (needsUpdate) {
      _cachedData.clear();
      _updateCache();
    }
  }

  void _updateCache() {
    _cachedData[_installedKey] = _computeInstalledEntries();
    _cachedData[_updateKey] = _computeUpdateEntries();
    _cachedData[_notInstalledKey] = _computeNotInstalledEntries();
    if (widget.showRecommended) {
      _cachedData[_recommendedKey] = _computeRecommendedEntries();
    }
  }

  Future<void> _refreshData() async {
    await sourceController.fetchRepos();
    _cachedData.clear();
    _updateCache();
    if (mounted) {
      setState(() {});
    }
  }

  List<Source> get _allAvailableExtensions {
    return sourceController.getAvailableExtensions(widget.itemType);
  }

  List<Source> get _installedExtensions {
    return sourceController.getInstalledExtensions(widget.itemType);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Builder(
          builder: (context) {
            final installedEntries =
                _getCachedData(_installedKey, _computeInstalledEntries);
            final updateEntries =
                _getCachedData(_updateKey, _computeUpdateEntries);
            final notInstalledEntries =
                _getCachedData(_notInstalledKey, _computeNotInstalledEntries);
            final recommendedEntries = widget.showRecommended
                ? _getCachedData(_recommendedKey, _computeRecommendedEntries)
                : <Source>[];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CustomScrollView(
                controller: controller,
                slivers: [
                  if (widget.showRecommended && recommendedEntries.isNotEmpty)
                    _buildRecommendedList(recommendedEntries),
                  if (widget.installed && updateEntries.isNotEmpty)
                    _buildUpdatePendingList(updateEntries),
                  if (widget.installed && installedEntries.isNotEmpty)
                    _buildInstalledList(installedEntries),
                  if (!widget.installed && notInstalledEntries.isNotEmpty)
                    _buildNotInstalledList(notInstalledEntries),
                  if (_isEmpty(installedEntries, updateEntries,
                      notInstalledEntries, recommendedEntries))
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'No extensions found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isEmpty(List<Source> installed, List<Source> updates,
      List<Source> notInstalled, List<Source> recommended) {
    if (widget.installed) {
      return installed.isEmpty && updates.isEmpty;
    } else {
      return notInstalled.isEmpty &&
          (!widget.showRecommended || recommended.isEmpty);
    }
  }

  List<Source> _getCachedData(
      String key, List<Source> Function() computeFunction) {
    if (_cachedData.containsKey(key)) {
      return _cachedData[key]!;
    }

    final data = computeFunction();
    _cachedData[key] = data;
    return data;
  }

  List<Source> _filterData(List<Source> data) {
    if (data.isEmpty) return data;

    return data.where((element) {
      if (widget.selectedLanguage != 'all') {
        final elementLang = element.lang?.toLowerCase() ?? '';
        final targetLang = completeLanguageCode(widget.selectedLanguage);
        if (elementLang != targetLang) return false;
      }

      if (widget.query.isNotEmpty) {
        final elementName = element.name?.toLowerCase() ?? '';
        final query = widget.query.toLowerCase();
        if (!elementName.contains(query)) return false;
      }

      return true;
    }).toList();
  }

  List<Source> _computeNotInstalledEntries() {
    final availableExtensions = _allAvailableExtensions;
    final installedExtensions = _installedExtensions;

    if (availableExtensions.isEmpty) return [];

    final installedSet =
        installedExtensions.map((e) => '${e.name}_${e.lang}').toSet();

    final notInstalled = availableExtensions.where((available) {
      final key = '${available.name}_${available.lang}';
      return !installedSet.contains(key);
    }).toList();

    return _filterData(notInstalled);
  }

  List<Source> _computeInstalledEntries() {
    final installedExtensions = _installedExtensions;
    return _filterData(installedExtensions);
  }

  List<Source> _computeUpdateEntries() {
    final installedExtensions = _installedExtensions;

    if (installedExtensions.isEmpty) return [];

    final updateAvailable = installedExtensions
        .where((installed) => installed.hasUpdate == true)
        .toList();

    return _filterData(updateAvailable);
  }

  List<Source> _computeRecommendedEntries() {
    const extens = ['anymex'];
    const preferredLangs = {'en', 'all', 'multi'};

    final availableExtensions = _allAvailableExtensions;

    if (availableExtensions.isEmpty) return [];

    final recommended = availableExtensions.where((element) {
      final name = element.name?.toLowerCase() ?? '';
      final lang = element.lang?.toLowerCase() ?? '';

      final matchesExtension = extens.any((ext) => name.contains(ext));
      final matchesLanguage = preferredLangs.contains(lang);

      return matchesExtension && matchesLanguage;
    }).toList();

    return _filterData(recommended);
  }

  Widget _buildUpdatePendingList(List<Source> updateEntries) {
    return SliverGroupedListView<Source, String>(
      elements: updateEntries,
      groupBy: (element) => "",
      groupSeparatorBuilder: (_) => Padding(
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
              onTap: () => _updateAllExtensions(updateEntries),
              child: const Text(
                'Update All',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context, Source element) => ExtensionListTileWidget(
          source: element,
          mediaType: widget.itemType,
          onUpdate: () {
            setState(() {});
          }),
      groupComparator: (group1, group2) => group1.compareTo(group2),
      itemComparator: (item1, item2) => item1.name!.compareTo(item2.name!),
      order: GroupedListOrder.ASC,
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

      _cachedData.clear();
      _updateCache();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error updating extensions: $e');
    }
  }

  Widget _buildInstalledList(List<Source> installedEntries) {
    return SliverGroupedListView<Source, String>(
      elements: installedEntries,
      groupBy: (element) => "",
      groupSeparatorBuilder: (_) => const SizedBox(height: 8),
      itemBuilder: (context, Source element) => ExtensionListTileWidget(
        source: element,
        mediaType: widget.itemType,
      ),
      groupComparator: (group1, group2) => group1.compareTo(group2),
      itemComparator: (item1, item2) => item1.name!.compareTo(item2.name!),
      order: GroupedListOrder.ASC,
    );
  }

  Widget _buildRecommendedList(List<Source> recommendedEntries) {
    return SliverGroupedListView<Source, String>(
      elements: recommendedEntries,
      groupBy: (element) => "",
      groupSeparatorBuilder: (_) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text(
              'Recommended',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
      itemBuilder: (context, Source element) => ExtensionListTileWidget(
        source: element,
        mediaType: widget.itemType,
      ),
      groupComparator: (group1, group2) => group1.compareTo(group2),
      itemComparator: (item1, item2) => item1.name!.compareTo(item2.name!),
      order: GroupedListOrder.ASC,
    );
  }

  Widget _buildNotInstalledList(List<Source> notInstalledEntries) {
    return SliverGroupedListView<Source, String>(
      elements: notInstalledEntries,
      groupBy: (element) => completeLanguageName(element.lang!.toLowerCase()),
      groupSeparatorBuilder: (String groupByValue) => Padding(
        padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
        child: Row(
          children: [
            Text(
              groupByValue,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
      itemBuilder: (context, Source element) => ExtensionListTileWidget(
        source: element,
        mediaType: widget.itemType,
      ),
      groupComparator: (group1, group2) => group1.compareTo(group2),
      itemComparator: (item1, item2) => item1.name!.compareTo(item2.name!),
      order: GroupedListOrder.ASC,
    );
  }
}
