import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/settings/search/settings_registry.dart';
import 'package:anymex/screens/settings/search/settings_search_icons.dart';
import 'package:anymex/screens/settings/sub_settings/settings_about.dart';
import 'package:anymex/screens/settings/sub_settings/settings_donation.dart';
import 'package:anymex/screens/settings/sub_settings/settings_comments.dart';
import 'package:anymex/screens/settings/sub_settings/settings_accounts.dart';
import 'package:anymex/screens/settings/sub_settings/settings_discord.dart';
import 'package:anymex/screens/settings/sub_settings/settings_backup.dart';
import 'package:anymex/screens/settings/sub_settings/settings_common.dart';
import 'package:anymex/screens/settings/sub_settings/settings_downloads.dart';
import 'package:anymex/screens/settings/sub_settings/settings_extensions.dart';
import 'package:anymex/screens/settings/sub_settings/settings_addons.dart';
import 'package:anymex/screens/settings/sub_settings/settings_logs.dart';
import 'package:anymex/screens/settings/sub_settings/settings_network.dart';
import 'package:anymex/screens/settings/sub_settings/settings_player.dart';
import 'package:anymex/screens/settings/sub_settings/settings_reader.dart';
import 'package:anymex/screens/settings/sub_settings/settings_storage_manager.dart';
import 'package:anymex/screens/settings/sub_settings/settings_theme.dart';
import 'package:anymex/screens/settings/sub_settings/settings_ui.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
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
    _showDonationDialog();
  }

  void _showDonationDialog() {
    AnymeXDialog(
      title: 'Support AnymeX',
      confirmText: 'Donate',
      cancelText: 'Soon',
      showCancelButton: true,
      onConfirm: () {
        navigate(SettingsDonation.new);
      },
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: context.colors.primary.opaque(0.12, iReallyMeanIt: true),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.colors.primary.opaque(0.25, iReallyMeanIt: true),
              ),
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: context.colors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          AnymeXText(
            'AnymeX is completely free, open-source, and ad-free. Your support directly helps in motivation and features being actively developed!',
            size: 13.5,
            color: context.colors.onSurfaceVariant,
            textAlign: TextAlign.center,
            maxLines: 10,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDonationPerk(
                icon: Icons.block_rounded,
                label: 'Ad-Free',
              ),
              _buildDonationPerk(
                icon: Icons.code_rounded,
                label: 'Open Source',
              ),
              _buildDonationPerk(
                icon: Icons.volunteer_activism_rounded,
                label: 'Community',
              ),
            ],
          ),
          const SizedBox(height: 18),
          AnymexOnTap(
            onTap: () {
              General.dontShowDonationDialog.set(true);
              Navigator.of(context).pop();
            },
            scale: 0.96,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.visibility_off_outlined,
                    size: 15,
                    color: context.colors.onSurface
                        .opaque(0.45, iReallyMeanIt: true),
                  ),
                  const SizedBox(width: 6),
                  AnymeXText(
                    "Don't show again",
                    size: 12.5,
                    variant: TextVariant.regular,
                    color: context.colors.onSurface
                        .opaque(0.5, iReallyMeanIt: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).show(context);
  }

  Widget _buildDonationPerk({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest
            .opaque(0.5, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.onSurface.opaque(0.06, iReallyMeanIt: true),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.colors.primary),
          const SizedBox(width: 6),
          AnymeXText(label, size: 11.5, variant: TextVariant.semiBold),
        ],
      ),
    );
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
            AnymeXText('No search results',
              size: 16,
              color: context.colors.onSurface.opaque(0.4, iReallyMeanIt: true),
            ),
            const SizedBox(height: 6),
            AnymeXText('Try a different keyword',
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
                    leading: buildSettingsSearchLeading(context, item),
                    title: item.title,
                    subtitle: item.expansionTitle ?? category,
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
        );
      },
    );
  }

  Widget _buildCategoryList(double headerHeight) {
    return SuperListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        SizedBox(height: headerHeight),
        _buildCategorySection(
          title: "Accounts & Sync",
          tiles: [
            _buildTile(
              icon: IconlyLight.profile,
              title: "Accounts",
              description: "Manage your MyAnimeList, Anilist, Simkl Accounts!",
              destination: SettingsAccounts.new,
            ),
            _buildTile(
              icon: Icons.discord,
              title: "Discord RPC",
              description: "Configure Discord Rich Presence & activity status",
              destination: SettingsDiscord.new,
            ),
          ],
        ),
        _buildCategorySection(
          title: "Preferences & System",
          tiles: [
            _buildTile(
              icon: HugeIcons.strokeRoundedBulb,
              title: "Common",
              description: "Tweak general app settings",
              destination: SettingsCommon.new,
            ),
            _buildTile(
              icon: HugeIcons.strokeRoundedLibraries,
              title: "Backup & Restore",
              description: "Backup and restore your library",
              destination: BackupRestorePage.new,
            ),
            _buildTile(
              icon: Icons.wifi_tethering_rounded,
              title: "Network",
              description: "Configure DNS-over-HTTPS, proxy & TLS settings",
              destination: SettingsNetwork.new,
            ),
            _buildTile(
              icon: Icons.storage_rounded,
              title: "Storage Manager",
              description:
                  "Manage cached images, thresholds, and reset app data",
              destination: SettingsStorageManager.new,
            ),
          ],
        ),
        _buildCategorySection(
          title: "Appearance & Interface",
          tiles: [
            _buildTile(
              icon: HugeIcons.strokeRoundedPaintBoard,
              title: "UI",
              description: "Customize the interface to your liking",
              destination: SettingsUi.new,
            ),
            _buildTile(
              icon: HugeIcons.strokeRoundedPaintBrush01,
              title: "Theme",
              description: "Personalize the look and make it yours",
              destination: SettingsTheme.new,
            ),
          ],
        ),
        _buildCategorySection(
          title: "Media & Playback",
          tiles: [
            _buildTile(
              icon: HugeIcons.strokeRoundedPlay,
              title: "Player",
              description: "Play around with the video player",
              destination: SettingsPlayer.new,
            ),
            _buildTile(
              icon: Icons.menu_book_rounded,
              title: "Reader",
              description: "Configure manga and novel reader defaults",
              destination: SettingsReader.new,
            ),
            _buildTile(
              icon: Icons.settings_suggest_rounded,
              title: "Download Settings",
              description: "Configure parallel downloads and directory",
              destination: SettingsDownloads.new,
            ),
          ],
        ),
        _buildCategorySection(
          title: "Extensions & Diagnostics",
          tiles: [
            _buildTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: "Comment System",
              description: "Commentum v2 settings, moderation & preferences",
              destination: SettingsComments.new,
            ),
            _buildTile(
              icon: Icons.extension_rounded,
              title: "Extensions",
              description: "Extensions tailored to your needs",
              destination: SettingsExtensions.new,
            ),
            _buildTile(
              icon: HugeIcons.strokeRoundedPlug01,
              title: "Add-ons",
              description: "TorrServer & streaming add-ons",
              destination: SettingsAddons.new,
            ),
            _buildTile(
              icon: HugeIcons.strokeRoundedFile01,
              title: "Logs",
              description: "Manage log capture and share saved logs",
              destination: SettingsLogs.new,
            ),
          ],
        ),
        _buildCategorySection(
          title: "About",
          tiles: [
            _buildTile(
              icon: Icons.favorite_rounded,
              title: "Support AnymeX",
              description: "Donate via UPI, PayPal & support development",
              destination: SettingsDonation.new,
            ),
            _buildTile(
              icon: HugeIcons.strokeRoundedInformationCircle,
              title: "About",
              description: "About the App",
              destination: AboutPage.new,
            ),
            if (kDebugMode)
              _buildTile(
                icon: HugeIcons.strokeRoundedBug01,
                title: "Test",
                description: "Debug extensions and update sheet",
                customTap: () async {
                  AnymeXDialog(
                    title: "Debug",
                    contentWidget: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnymeXTile(
                          icon: HugeIcons.strokeRoundedBug01,
                          title: "Debug Extensions",
                          subtitle: "Debug extensions and view logs",
                          onTap: () async {},
                        ),
                      ],
                    ),
                    onConfirm: () {},
                  ).show(context);
                },
              ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildCategorySection({
    required String title,
    required List<Widget> tiles,
  }) {
    return AnymeXSectionBuilder(
      title: title,
      children: tiles,
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

class CustomBackButton extends StatelessWidget {
  const CustomBackButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            Theme.of(context).colorScheme.surfaceContainer.opaque(0.5),
      ),
      onPressed: () {
        Navigator.pop(context);
      },
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
    );
  }
}
