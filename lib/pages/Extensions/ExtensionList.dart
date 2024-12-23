import 'package:anymex/Preferences/PrefManager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grouped_list/sliver_grouped_list.dart';

import '../../Preferences/Preferences.dart';
import '../../api/Mangayomi/Extensions/GetSourceList.dart';
import '../../api/Mangayomi/Extensions/extensions_provider.dart';
import '../../api/Mangayomi/Extensions/fetch_anime_sources.dart';
import '../../api/Mangayomi/Extensions/fetch_manga_sources.dart';
import '../../api/Mangayomi/Model/Source.dart';
import 'ExtensionItem.dart';

class Extension extends ConsumerStatefulWidget {
  final bool installed;
  final bool isManga;
  final String query;

  const Extension({
    required this.installed,
    required this.query,
    required this.isManga,
    super.key,
  });

  @override
  ConsumerState<Extension> createState() => _ExtensionScreenState();
}

class _ExtensionScreenState extends ConsumerState<Extension> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (widget.isManga) {
      await ref
          .read(fetchMangaSourcesListProvider(id: null, reFresh: false).future);
    } else {
      await ref
          .read(fetchAnimeSourcesListProvider(id: null, reFresh: false).future);
    }
  }

  Future<void> _refreshData() async {
    if (widget.isManga) {
      return await ref.refresh(
          fetchMangaSourcesListProvider(id: null, reFresh: true).future);
    } else {
      return await ref.refresh(
          fetchAnimeSourcesListProvider(id: null, reFresh: true).future);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streamExtensions =
        ref.watch(getExtensionsStreamProvider(widget.isManga));

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: streamExtensions.when(
          data: (data) {
            data = _filterData(data);
            final installedEntries = _getInstalledEntries(data);
            final updateEntries = _getUpdateEntries(data);
            final notInstalledEntries = _getNotInstalledEntries(data);

            return Scrollbar(
              interactive: true,
              controller: _scrollController,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  if (widget.installed) _buildUpdatePendingList(updateEntries),
                  if (widget.installed) _buildInstalledList(installedEntries),
                  if (!widget.installed)
                    _buildNotInstalledList(notInstalledEntries),
                ],
              ),
            );
          },
          error: (error, _) => Center(
            child: ElevatedButton(
              onPressed: () => _fetchData(),
              child: const Text('Refresh'),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  List<Source> _filterData(List<Source> data) {
    return data
        .where((element) =>
            widget.query.isEmpty ||
            element.name!.toLowerCase().contains(widget.query.toLowerCase()))
        .where((element) =>
            PrefManager.getVal(PrefName.NSFWExtensions) ||
            element.isNsfw == false)
        .toList();
  }

  List<Source> _getInstalledEntries(List<Source> data) {
    return data
        .where((element) => element.version == element.versionLast!)
        .where((element) => element.isAdded!)
        .toList();
  }

  List<Source> _getUpdateEntries(List<Source> data) {
    return data
        .where((element) =>
            compareVersions(element.version!, element.versionLast!) < 0)
        .where((element) => element.isAdded!)
        .toList();
  }

  List<Source> _getNotInstalledEntries(List<Source> data) {
    return data
        .where((element) => element.version == element.versionLast!)
        .where((element) => !element.isAdded!)
        .toList();
  }

  SliverGroupedListView<Source, String> _buildUpdatePendingList(
      List<Source> updateEntries) {
    return SliverGroupedListView<Source, String>(
      elements: updateEntries,
      groupBy: (element) => "",
      groupSeparatorBuilder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Update Pending',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            ElevatedButton(
              onPressed: () async {
                for (var source in updateEntries) {
                  source.isManga!
                      ? await ref.watch(fetchMangaSourcesListProvider(
                              id: source.id, reFresh: true)
                          .future)
                      : await ref.watch(fetchAnimeSourcesListProvider(
                              id: source.id, reFresh: true)
                          .future);
                }
              },
              child: const Text(
                'Update All',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context, Source element) =>
          ExtensionListTileWidget(source: element),
      groupComparator: (group1, group2) => group1.compareTo(group2),
      itemComparator: (item1, item2) => item1.name!.compareTo(item2.name!),
      order: GroupedListOrder.ASC,
    );
  }

  SliverGroupedListView<Source, String> _buildInstalledList(
      List<Source> installedEntries) {
    return SliverGroupedListView<Source, String>(
      elements: installedEntries,
      groupBy: (element) => "",
      groupSeparatorBuilder: (_) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(),
      ),
      itemBuilder: (context, Source element) =>
          ExtensionListTileWidget(source: element),
      groupComparator: (group1, group2) => group1.compareTo(group2),
      itemComparator: (item1, item2) => item1.name!.compareTo(item2.name!),
      order: GroupedListOrder.ASC,
    );
  }

  SliverGroupedListView<Source, String> _buildNotInstalledList(
      List<Source> notInstalledEntries) {
    return SliverGroupedListView<Source, String>(
      elements: notInstalledEntries,
      groupBy: (element) => (element.lang!.toLowerCase()),
      groupSeparatorBuilder: (String groupByValue) => Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          children: [
            Text(
              groupByValue,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
      itemBuilder: (context, Source element) =>
          ExtensionListTileWidget(source: element),
      groupComparator: (group1, group2) => group1.compareTo(group2),
      itemComparator: (item1, item2) => item1.name!.compareTo(item2.name!),
      order: GroupedListOrder.ASC,
    );
  }
}
