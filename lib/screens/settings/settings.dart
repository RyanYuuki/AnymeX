import 'package:anymex/screens/downloads/download_screen.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/screens/profile/profile_management_page.dart';
import 'package:anymex/screens/settings/search/settings_registry.dart';
import 'package:anymex/screens/settings/search/settings_search_icons.dart';
import 'package:anymex/screens/settings/sub_settings/settings_about.dart';
import 'package:anymex/screens/settings/sub_settings/settings_accounts.dart';
import 'package:anymex/screens/settings/sub_settings/settings_backup.dart';
import 'package:anymex/screens/settings/sub_settings/settings_common.dart';
import 'package:anymex/screens/settings/sub_settings/settings_downloads.dart';
import 'package:anymex/screens/settings/sub_settings/settings_experimental.dart';
import 'package:anymex/screens/settings/sub_settings/settings_extensions.dart';
import 'package:anymex/screens/settings/sub_settings/settings_logs.dart';
import 'package:anymex/screens/settings/sub_settings/settings_player.dart';
import 'package:anymex/screens/settings/sub_settings/settings_reader.dart';
import 'package:anymex/screens/settings/sub_settings/settings_storage_manager.dart';
import 'package:anymex/screens/settings/sub_settings/settings_theme.dart';
import 'package:anymex/screens/settings/sub_settings/settings_ui.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class _CategoryItem {
  final IconData icon;
  final String title;
  final String description;
  final Widget Function()? destination;
  final void Function()? customTap;
  final bool isDebugOnly;
  final bool addDividerAbove;

  const _CategoryItem({
    required this.icon,
    required this.title,
    required this.description,
    this.destination,
    this.customTap,
    this.isDebugOnly = false,
    this.addDividerAbove = false,
  });
}

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

  Map<String, List<SettingsSearchEntry>> get _searchResults => _search.results;

  @override
  Widget build(BuildContext context) {
    final listPadding = getResponsiveValue(context,
        mobileValue: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 20.0),
        desktopValue: const EdgeInsets.fromLTRB(20.0, 20.0, 25.0, 20.0));

    return Glow(
        child: Scaffold(
            body: Column(children: [
      const NestedHeader(title: 'Settings'),
      Padding(
        padding:
            EdgeInsets.fromLTRB(listPadding.left, 16, listPadding.right, 0),
        child: _buildSearchBar(context),
      ),
      Expanded(
          child: _isSearching
              ? _buildSearchResults(listPadding)
              : _buildCategoryList(listPadding)),
    ])));
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [lightGlowingShadow(context)],
      ),
      child: TextField(
        controller: _search.textController,
        style: TextStyle(color: context.colors.onSurface, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search settings...',
          filled: true,
          fillColor: context.colors.secondaryContainer.opaque(0.5),
          hintStyle: TextStyle(
            color: context.colors.onSurface.opaque(0.4, iReallyMeanIt: true),
            fontSize: 16,
          ),
          prefixIcon: Icon(IconlyLight.search, color: context.colors.primary),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: context.colors.onSurface
                          .opaque(0.5, iReallyMeanIt: true)),
                  onPressed: () {
                    _search.textController.clear();
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: context.colors.secondaryContainer,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: context.colors.secondaryContainer,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(EdgeInsets padding) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64,
                color:
                    context.colors.onSurface.opaque(0.15, iReallyMeanIt: true)),
            const SizedBox(height: 16),
            AnymexText(
              text: 'No search results',
              size: 16,
              color: context.colors.onSurface.opaque(0.4, iReallyMeanIt: true),
            ),
            const SizedBox(height: 6),
            AnymexText(
              text: 'Try a different keyword',
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
      padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 20),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final items = _searchResults[category]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AnymexExpansionTile(
            title: category,
            initialExpanded: true,
            content: Column(
              children: items
                  .map((item) => ListTile(
                        leading: buildSettingsSearchLeading(context, item),
                        title: Text(item.title),
                        subtitle: Text(
                          item.expansionTitle ?? category,
                          style: TextStyle(
                            color: context.colors.onSurface.opaque(0.5),
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: context.colors.onSurface.opaque(0.3),
                        ),
                        onTap: () async {
                          final builder = categoryRoutes[category];
                          if (builder != null) {
                            await navigate(() => SettingsHighlightProvider(
                                  highlightTitle: item.targetTitle,
                                  expansionTitle: item.expansionTitle,
                                  child: builder(),
                                ));
                          }
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryList(EdgeInsets padding) {
    return SuperListView(
      padding: padding,
      children: [
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color:
                  Theme.of(context).colorScheme.surfaceContainer.opaque(0.3)),
          child: Column(
            children: [
              ..._buildCategoryWidgets(),
            ],
          ),
        ),
        30.height(),
      ],
    );
  }

  List<Widget> _buildCategoryWidgets() {
    final items = [
      _CategoryItem(
          icon: HugeIcons.strokeRoundedUser02,
          title: "Profiles",
          description: "Manage profiles, PIN locks, and switching",
          destination: () => const ProfileManagementPage()),
      _CategoryItem(
          icon: IconlyLight.profile,
          title: "Accounts",
          description: "Manage your MyAnimeList, Anilist, Simkl Accounts!",
          destination: () => const SettingsAccounts()),
      _CategoryItem(
          icon: HugeIcons.strokeRoundedBulb,
          title: "Common",
          description: "Tweak Settings",
          destination: () => const SettingsCommon()),
      _CategoryItem(
          icon: HugeIcons.strokeRoundedLibraries,
          title: "Backup & Restore",
          description: "Backup and restore your library",
          destination: () => const BackupRestorePage()),
      _CategoryItem(
          icon: Icons.storage_rounded,
          title: "Storage Manager",
          description: "Manage cached images, thresholds, and reset app data",
          destination: () => const SettingsStorageManager()),
      _CategoryItem(
          icon: HugeIcons.strokeRoundedPaintBoard,
          title: "UI",
          description: "Customize the interface to your liking",
          destination: () => const SettingsUi()),
      _CategoryItem(
          icon: HugeIcons.strokeRoundedPlay,
          title: "Player",
          description: "Play around with the video player",
          destination: () => const SettingsPlayer()),
      _CategoryItem(
          icon: Icons.menu_book_rounded,
          title: "Reader",
          description: "Configure manga and novel reader defaults",
          destination: () => const SettingsReader()),
      _CategoryItem(
          icon: HugeIcons.strokeRoundedPaintBrush01,
          title: "Theme",
          description: "Personalize the look and make it yours",
          destination: () => const SettingsTheme()),
      _CategoryItem(
          icon: Icons.settings_suggest_rounded,
          title: "Download Settings",
          description: "Configure parallel downloads and directory",
          destination: () => const SettingsDownloads()),

      _CategoryItem(
          icon: Icons.extension_rounded,
          title: "Extensions",
          description: "Extensions tailored to your needs",
          destination: () => const SettingsExtensions(),
          addDividerAbove: true),
      _CategoryItem(
          icon: HugeIcons.strokeRoundedInformationCircle,
          title: "Experimental",
          description: "Experimental Settings that are still being tested",
          destination: () => const SettingsExperimental(),
          addDividerAbove: true),
      _CategoryItem(
          icon: HugeIcons.strokeRoundedFile01,
          title: "Logs",
          description: "Manage log capture and share saved logs",
          destination: () => const SettingsLogs(),
          addDividerAbove: true),
      _CategoryItem(
          icon: HugeIcons.strokeRoundedInformationCircle,
          title: "About",
          description: "About the App",
          destination: () => const AboutPage(),
          addDividerAbove: true),
      _CategoryItem(
        icon: HugeIcons.strokeRoundedInformationCircle,
        title: "Test",
        description: "Debug extensions",
        isDebugOnly: true,
        addDividerAbove: true,
        customTap: () async {
          final list = Get.find<ExtensionManager>()
              .installedAnimeExtensions
              .whereType<CloudStreamSource>()
              .toList();
          for (CloudStreamSource i in list) {
            debugPrint("${i.id} - ${i.internalName} - ${i.jarUrl}");
            final search =
                await i.methods.search("Attack on titan", 1, []);
            print(search.toJson());
          }
        },
      ),
    ];

    final widgets = <Widget>[];
    for (final item in items) {
      if (item.isDebugOnly && !kDebugMode) continue;

      if (item.addDividerAbove) {
        widgets.add(const SizedBox(height: 10));
      }

      widgets.add(
        CustomTile(
          icon: item.icon,
          title: item.title,
          description: item.description,
          onTap: item.customTap ?? () => navigate(item.destination!),
        ),
      );
    }
    return widgets;
  }
}

class CustomBackButton extends StatelessWidget {
  const CustomBackButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
        style: ElevatedButton.styleFrom(
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainer.opaque(0.5)),
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_ios_new_rounded));
  }
}
