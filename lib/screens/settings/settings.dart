import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/settings/registry/settings_model.dart';
import 'package:anymex/screens/settings/registry/settings_registry.dart';
import 'package:anymex/screens/settings/registry/settings_search_controller.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/dialogs/donation_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _search = SettingsSearchController();

  @override
  void initState() {
    super.initState();
    _search.textController.addListener(_onSearchUiStateChanged);
    _search.resultsNotifier.addListener(_onSearchUiStateChanged);
    assert(_search.validateRegistry());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDonationDialogIfNeeded();
    });
  }

  void _showDonationDialogIfNeeded() {
    if (!mounted) return;
    final dontShow = General.dontShowDonationDialog.get<bool>(false);
    if (dontShow) return;
    DonationDialog.show(context);
  }

  @override
  void dispose() {
    _search.textController.removeListener(_onSearchUiStateChanged);
    _search.resultsNotifier.removeListener(_onSearchUiStateChanged);
    _search.dispose();
    super.dispose();
  }

  void _onSearchUiStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _isSearching => _search.isSearching;

  Map<String, List<SettingItem>> get _searchResults => _search.results;

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      resizeToAvoidBottomInset: false,
      showHeader: true,
      headerTitle: 'Settings',
      headerEnableSearch: true,
      headerSearchController: _search.textController,
      headerSearchHint: 'Search settings...',
      onHeaderSearchChanged: (value) => setState(() {}),
      onHeaderSearchClear: () => setState(() {}),
      body: Builder(
        builder: (ctx) {
          final headerHeight = AnymeXHeaderScope.of(ctx);
          return _isSearching
              ? _buildSearchResults(headerHeight)
              : _buildCategoryList(headerHeight);
        },
      ),
    );
  }

  Widget _buildSearchLeading(BuildContext context, SettingItem item) {
    if (item.assetIcon != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          item.assetIcon!,
          width: 22,
          height: 22,
          fit: BoxFit.cover,
        ),
      );
    }
    final icon = item.icon ??
        SettingsRegistry.categoryIcon(item.category) ??
        Icons.settings_rounded;
    return Icon(icon, color: context.colors.primary);
  }

  Widget _buildSearchResults(double headerHeight) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: context.colors.onSurface.opaque(0.15, iReallyMeanIt: true),
            ),
            const SizedBox(height: 16),
            AnymeXText(
              'No search results',
              size: 16,
              color: context.colors.onSurface.opaque(0.4, iReallyMeanIt: true),
            ),
            const SizedBox(height: 6),
            AnymeXText(
              'Try a different keyword',
              size: 13,
              color: context.colors.onSurface.opaque(0.3, iReallyMeanIt: true),
            ),
          ],
        ),
      );
    }

    final query = _search.textController.text.trim().toLowerCase();
    final categories = _search.sortedCategories(query);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: categories.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return SizedBox(height: headerHeight - 12);
        final category = categories[index - 1];
        final items = _searchResults[category]!;

        return AnymeXSectionBuilder(
          title: category,
          children: items
              .map((item) => AnymeXTile(
                    leading: _buildSearchLeading(context, item),
                    title: item.title,
                    subtitle: item.section ?? category,
                    onTap: () async {
                      final builder = SettingsRegistry.categoryRoutes[category];
                      if (builder != null) {
                        await navigate(() => SettingsHighlightProvider(
                              highlightTitle: item.targetTitle,
                              expansionTitle: item.section,
                              child: builder(),
                            ));
                      }
                    },
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildCategoryList(double headerHeight) {
    final groups = SettingsRegistry.groupedCategories;

    return SuperListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        SizedBox(height: headerHeight),
        for (final entry in groups.entries)
          AnymeXSectionBuilder(
            title: entry.key,
            children: [
              for (final cat in entry.value)
                _buildTile(
                  icon: cat.icon,
                  title: cat.title,
                  description: cat.description,
                  destination: cat.destination,
                ),
              if (entry.key == 'About' && kDebugMode)
                _buildTile(
                  icon: HugeIcons.strokeRoundedBug01,
                  title: 'Test',
                  description: 'Debug stuffs',
                  customTap: () async {},
                ),
            ],
          ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String description,
    Widget Function()? destination,
    VoidCallback? customTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return AnymeXTile(
      icon: icon,
      iconColor: colors.primary,
      iconBackgroundColor: colors.primary.opaque(0.12, iReallyMeanIt: true),
      title: title,
      subtitle: description,
      onTap: customTap ?? () => navigate(destination),
    );
  }
}
