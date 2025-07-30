import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/widgets/custom_widgets/custom_button.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

class _ExtensionScreenState extends State<Extension> {
  final controller = ScrollController();

  Future<void> _refreshData() async {
    await sourceController.fetchRepos();
    setState(() {});
  }

  List<Source> get _allAvailableExtensions =>
      sourceController.getAvailableExtensions(widget.itemType);

  List<Source> get _installedExtensions =>
      sourceController.getInstalledExtensions(widget.itemType);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Obx(
          () {
            final installedEntries = _getInstalledEntries();
            final updateEntries = _getUpdateEntries();
            final notInstalledEntries = _getNotInstalledEntries();
            final recommendedEntries = widget.showRecommended
                ? _getRecommendedEntries()
                : [].cast<Source>();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CustomScrollView(
                controller: controller,
                slivers: [
                  if (widget.showRecommended && (recommendedEntries.isNotEmpty))
                    _buildRecommendedList(recommendedEntries),
                  if (widget.installed) _buildUpdatePendingList(updateEntries),
                  if (widget.installed) _buildInstalledList(installedEntries),
                  if (!widget.installed)
                    _buildNotInstalledList(notInstalledEntries),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Source> _filterData(List<Source> data) {
    return data
        .where((element) => widget.selectedLanguage != 'all'
            ? element.lang!.toLowerCase() ==
                completeLanguageCode(widget.selectedLanguage)
            : true)
        .where((element) =>
            widget.query.isEmpty ||
            element.name!.toLowerCase().contains(widget.query.toLowerCase()))
        .toList();
  }

  List<Source> _getNotInstalledEntries() {
    final availableExtensions = _allAvailableExtensions;
    final installedExtensions = _installedExtensions;

    final notInstalled = availableExtensions.where((available) {
      return !installedExtensions.any((installed) =>
          installed.name == available.name && installed.lang == available.lang);
    }).toList();

    return _filterData(notInstalled);
  }

  List<Source> _getInstalledEntries() {
    final installedExtensions = _installedExtensions;
    return _filterData(installedExtensions);
  }

  List<Source> _getUpdateEntries() {
    final installedExtensions = _installedExtensions;

    final updateAvailable = <Source>[];

    for (final installed in installedExtensions) {
      if (installed.hasUpdate ?? false) {
        updateAvailable.add(installed);
      }
    }

    return _filterData(updateAvailable);
  }

  List<Source> _getRecommendedEntries() {
    final extens = [
      'anymex',
    ];

    final availableExtensions = _allAvailableExtensions;
    final recommended = availableExtensions.where((element) {
      final name = element.name?.toLowerCase() ?? '';
      final lang = element.lang?.toLowerCase() ?? '';
      final matchesExtension = extens.any((ext) => name.contains(ext));
      return matchesExtension &&
          (lang == 'en' || lang == 'all' || lang == 'multi');
    }).toList();

    return _filterData(recommended);
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
            AnymeXButton(
              variant: ButtonVariant.outline,
              onTap: () async {
                for (var source in updateEntries) {
                  await source.extensionType!.getManager().updateSource(source);
                }
                setState(() {});
              },
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
      ),
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
      itemBuilder: (context, Source element) => ExtensionListTileWidget(
        source: element,
        mediaType: widget.itemType,
      ),
      groupComparator: (group1, group2) => group1.compareTo(group2),
      itemComparator: (item1, item2) => item1.name!.compareTo(item2.name!),
      order: GroupedListOrder.ASC,
    );
  }

  // New method to build recommended list
  SliverGroupedListView<Source, String> _buildRecommendedList(
      List<Source> recommendedEntries) {
    return SliverGroupedListView<Source, String>(
      elements: recommendedEntries,
      groupBy: (element) => "",
      groupSeparatorBuilder: (_) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
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

  SliverGroupedListView<Source, String> _buildNotInstalledList(
      List<Source> notInstalledEntries) {
    return SliverGroupedListView<Source, String>(
      elements: notInstalledEntries,
      groupBy: (element) => completeLanguageName(element.lang!.toLowerCase()),
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
