import 'package:anymex/l10n/l10n_extension.dart';
import 'dart:async';
import 'package:anymex/database/database.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/extensions/ExtensionList.dart';
import 'package:anymex/screens/extensions/ExtensionTesting/extension_test_page.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/screens/settings/sub_settings/settings_extension_manager.dart';
import 'package:anymex/screens/settings/sub_settings/settings_extensions.dart';
import 'package:anymex/screens/settings/sub_settings/settings_addons.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tabbar.dart';
import 'package:anymex/widgets/common/source_selector.dart';
import 'package:anymex/widgets/header/header.dart';
import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

class ExtensionScreen extends StatefulWidget {
  const ExtensionScreen({
    super.key,
    this.isTabScreen = false,
  });

  final bool isTabScreen;
  @override
  State<ExtensionScreen> createState() => _ExtensionScreenState();
}

class _ExtensionScreenState extends State<ExtensionScreen>
    with SingleTickerProviderStateMixin {
  final _textEditingController = TextEditingController();
  final _searchQuery = ''.obs;
  final _selectedLanguage = 'all'.obs;
  final _selectedSourceType = 'all'.obs;
  final _selectedContentType = ItemType.anime.obs;
  final _showInstalled = true.obs;

  Timer? _searchDebounce;
  late final ScrollController _appBarScrollController;
  final ValueNotifier<bool> _isAppBarVisible = ValueNotifier<bool>(true);

  static List<({String label, IconData icon, ItemType type})> get _contentTabs => [
    (label: Get.context!.l10n.anime, icon: Icons.movie_creation_outlined, type: ItemType.anime),
    (label: Get.context!.l10n.manga, icon: Icons.menu_book_outlined, type: ItemType.manga),
    (label: Get.context!.l10n.novel, icon: Icons.auto_stories_outlined, type: ItemType.novel),
  ];

  @override
  void initState() {
    super.initState();
    _appBarScrollController = ScrollController();
    _checkPermission();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _searchDebounce?.cancel();
    _appBarScrollController.dispose();
    _isAppBarVisible.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async => await Database().requestPermission();

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _searchQuery.value = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    final showMobileAppBar = widget.isTabScreen && !isDesktop;

    final statusBarHeight = MediaQuery.paddingOf(context).top;
    const appBarHeight = kToolbarHeight + 20;

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isTabScreen) ...[
          if (isDesktop) ...[
            const SizedBox(height: 10),
            Header(
              title: context.l10n.extensions,
              subtitle: context.l10n.managePluginsSources,
              actions: [
                HeaderActionButton(
                  icon: HugeIcons.strokeRoundedPlug01,
                  onTap: () => navigate(() => const SettingsAddons()),
                ),
                HeaderActionButton(
                  icon: Icons.build_outlined,
                  onTap: () => navigate(() => const ExtensionTestPage()),
                ),
                HeaderActionButton(
                  icon: HugeIcons.strokeRoundedGithub,
                  onTap: () => navigate(() => const SettingsExtensions()),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ] else ...[
            SizedBox(height: statusBarHeight + appBarHeight),
          ]
        ] else ...[
          NestedHeader(
            title: context.l10n.extensions,
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(HugeIcons.strokeRoundedPlug01,
                      color: theme.primary, size: 20),
                  onPressed: () => navigate(() => const SettingsAddons()),
                  tooltip: context.l10n.addOns,
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.build_outlined,
                      color: theme.primary, size: 20),
                  onPressed: () => navigate(() => const ExtensionTestPage()),
                  tooltip: context.l10n.testExtensions,
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(HugeIcons.strokeRoundedGithub,
                      color: theme.primary, size: 20),
                  onPressed: () => navigate(() => const SettingsExtensions()),
                  tooltip: context.l10n.repositories,
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildContentTypeBar(),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildStatusBar(),
        ),
        const SizedBox(height: 10),
        _buildSearchRow(),
        _buildSourceTypeChips(),
        Expanded(child: _buildView()),
      ],
    );

    return AnymeXScaffold(
        disabled: widget.isTabScreen,
        isTabScreen: widget.isTabScreen,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            mainContent,
            if (showMobileAppBar)
              CustomAnimatedAppBar(
                isVisible: _isAppBarVisible,
                scrollController: _appBarScrollController,
                headerContent: Header(
                  title: context.l10n.extensions,
                  subtitle: context.l10n.managePluginsSources,
                  actions: [
                    HeaderActionButton(
                      icon: HugeIcons.strokeRoundedPlug01,
                      onTap: () => navigate(() => const SettingsAddons()),
                    ),
                    HeaderActionButton(
                      icon: Icons.build_outlined,
                      onTap: () => navigate(() => const ExtensionTestPage()),
                    ),
                    HeaderActionButton(
                      icon: HugeIcons.strokeRoundedGithub,
                      onTap: () => navigate(() => const SettingsExtensions()),
                    ),
                  ],
                ),
                visibleStatusBarStyle: SystemUiOverlayStyle(
                  statusBarIconBrightness:
                      Theme.of(context).brightness == Brightness.light
                          ? Brightness.dark
                          : Brightness.light,
                  statusBarBrightness: Theme.of(context).brightness,
                  statusBarColor: Colors.transparent,
                ),
                hiddenStatusBarStyle: SystemUiOverlayStyle(
                  statusBarIconBrightness:
                      Theme.of(context).brightness == Brightness.light
                          ? Brightness.light
                          : Brightness.dark,
                  statusBarBrightness:
                      Theme.of(context).brightness == Brightness.light
                          ? Brightness.dark
                          : Brightness.light,
                  statusBarColor: Colors.transparent,
                ),
              ),
          ],
        ));
  }

  Widget _buildContentTypeBar() {
    return Obx(() {
      final selected = _selectedContentType.value;
      final tabs = _contentTabs;
      final selectedIndex = tabs.indexWhere((t) => t.type == selected);

      return AnymeXTabBar(
        selectTabs: tabs.map((t) => t.label).toList(),
        selectedIndex: selectedIndex,
        icons: tabs.map((t) => t.icon).toList(),
        height: 54,
        minTabWidth: 100.0,
        activeColor: context.colors.primary,
        activeTextColor: context.colors.onPrimary,
        inactiveTextColor: context.colors.onSurfaceVariant,
        onTabSelected: (index) {
          final t = tabs[index];
          _selectedContentType.value = t.type;
          _selectedSourceType.value = 'all';
          _textEditingController.clear();
          _searchQuery.value = '';
        },
      );
    });
  }

  Widget _buildStatusBar() {
    return Obx(() {
      final isInstalled = _showInstalled.value;
      const tabs = ['Installed', 'Available'];
      final currentIndex = isInstalled ? 0 : 1;

      return AnymeXTabBar(
        selectTabs: tabs,
        selectedIndex: currentIndex,
        height: 46,
        activeColor: context.colors.secondary,
        activeTextColor: context.colors.onSecondary,
        inactiveTextColor: context.colors.onSurfaceVariant,
        onTabSelected: (index) {
          _showInstalled.value = index == 0;
          _textEditingController.clear();
          _searchQuery.value = '';
        },
      );
    });
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textEditingController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: context.l10n.searchExtensionsEllipsis,
                hintStyle: TextStyle(
                  color: context.colors.onSurface.withOpacity(0.4),
                  fontSize: 14,
                  fontFamily: 'Linotte',
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.colors.onSurface.withOpacity(0.45),
                  size: 20,
                ),
                filled: true,
                fillColor:
                    context.colors.surfaceContainerHighest.withOpacity(0.4),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: context.colors.outline.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: context.colors.outline.withOpacity(0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: context.colors.primary.withOpacity(0.5),
                      width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final active = _selectedLanguage.value != 'all';
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: active
                        ? context.colors.primary.withOpacity(0.12)
                        : context.colors.surfaceContainerHighest
                            .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active
                          ? context.colors.primary.withOpacity(0.35)
                          : context.colors.outline.withOpacity(0.15),
                    ),
                  ),
                  child: IconButton(
                    onPressed: () => _showLanguageSelector(context),
                    icon: Icon(
                      Icons.translate_rounded,
                      size: 20,
                      color: active
                          ? context.colors.primary
                          : context.colors.onSurface.withOpacity(0.55),
                    ),
                    tooltip: context.l10n.selectLanguage,
                    padding: EdgeInsets.zero,
                  ),
                ),
                if (active)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final languages = sortedLanguagesMap.keys.toList();

    String tempLang = _selectedLanguage.value;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AnymeXDialog(
          title: context.l10n.selectLanguage,
          onConfirm: () {
            _selectedLanguage.value = tempLang;
          },
          contentWidget: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: AnymeXTileBuilder<String>(
              items: languages,
              selectedItem: tempLang,
              getTitle: (lang) => lang == 'all' ? 'All Languages' : lang,
              lazy: true,
              onItemPressed: (lang) {
                setDialogState(() {
                  tempLang = lang;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  String? _getManagerIcon(String type) {
    if (type == 'all') return null;
    final lower = type.toLowerCase();
    final manager = Get.find<ExtensionManager>().managers.firstWhereOrNull(
          (m) =>
              m.name.toLowerCase() == lower ||
              m.id.toLowerCase() == lower ||
              m.name.toLowerCase().contains(lower) ||
              lower.contains(m.name.toLowerCase()),
        );
    if (manager != null) return manager.icon;

    final allSources = [
      ...sourceController.installedExtensions,
      ...sourceController.installedMangaExtensions,
      ...sourceController.installedNovelExtensions,
      ...sourceController.availableExtensions,
      ...sourceController.availableMangaExtensions,
      ...sourceController.availableNovelExtensions,
    ];
    final match = allSources.firstWhereOrNull((s) {
      if (s.managerId != null && s.managerId!.isNotEmpty) {
        if (s.managerId!.toLowerCase() == lower) return true;
      }
      return sourceTypeName(s).toLowerCase() == lower;
    });
    if (match != null && match.managerIcon.isNotEmpty) {
      return match.managerIcon;
    }
    return null;
  }

  bool _supportsContentType(String type, ItemType contentType) {
    if (type == 'all') return true;
    final lower = type.toLowerCase();
    final activeManager =
        Get.find<ExtensionManager>().managers.firstWhereOrNull(
              (m) =>
                  m.name.toLowerCase() == lower ||
                  m.id.toLowerCase() == lower ||
                  m.name.toLowerCase().contains(lower) ||
                  lower.contains(m.name.toLowerCase()),
            );
    if (activeManager != null) {
      return switch (contentType) {
        ItemType.anime => activeManager.supportsAnime,
        ItemType.manga => activeManager.supportsManga,
        ItemType.novel => activeManager.supportsNovel,
      };
    }
    return true;
  }

  Widget _buildSourceTypeChips() {
    return Obx(() {
      final em = Get.find<ExtensionManager>();
      final activeManagers = em.managers;
      final allSourceTypes = <String>['all'];

      for (final m in activeManagers) {
        if (!allSourceTypes.contains(m.name)) {
          allSourceTypes.add(m.name);
        }
      }

      final selectedType = _selectedSourceType.value;
      final contentType = _selectedContentType.value;
      final filteredSourceTypes = allSourceTypes
          .where((type) => _supportsContentType(type, contentType))
          .toList();

      return Container(
          height: 38,
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          padding: const EdgeInsets.only(left: 16),
          alignment: Alignment.centerLeft,
          width: double.infinity,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnymeXPills(
              items: filteredSourceTypes.map((e) {
                final type = e;
                final needsPlugin =
                    _typeRequiresPlugin(type) && !_isPluginInstalled;
                final isSelected = !needsPlugin && selectedType == type;
                final label = type == 'all' ? 'All' : type;
                final iconUrl = _getManagerIcon(type);

                return PillItem(
                    iconUrl: iconUrl,
                    icon: type == 'all' ? HugeIcons.strokeRoundedPlug01 : null,
                    label: label,
                    isSelected: isSelected,
                    onTap: needsPlugin
                        ? () {
                            navigate(() => const SettingsExtensionManager());
                          }
                        : () {
                            _selectedSourceType.value = type;
                          });
              }).toList(),
            ),
          ));
    });
  }

  Widget _buildView() {
    return Obx(() {
      final query = _searchQuery.value;
      final lang = _selectedLanguage.value;
      final sourceType = _selectedSourceType.value;
      final contentType = _selectedContentType.value;
      final installed = _showInstalled.value;

      return ExtensionList(
        key: ValueKey('${contentType.name}_$installed'),
        installed: installed,
        query: query,
        itemType: contentType,
        selectedLanguage: lang,
        selectedSourceType: sourceType,
        showRecommended: !installed,
        isTabScreen: widget.isTabScreen,
      );
    });
  }

  bool get _isPluginInstalled =>
      AnymeXRuntimeBridge.isPluginInstalled ||
      AnymeXRuntimeBridge.controller.isReady.value;

  bool _typeRequiresPlugin(String type) {
    if (type == 'all') return false;
    final lower = type.toLowerCase();
    final activeManager =
        Get.find<ExtensionManager>().managers.firstWhereOrNull(
              (m) =>
                  m.name.toLowerCase() == lower ||
                  m.id.toLowerCase() == lower ||
                  m.name.toLowerCase().contains(lower) ||
                  lower.contains(m.name.toLowerCase()),
            );
    return activeManager?.requiresPlugin ?? false;
  }

  @override
  void reassemble() {
    super.reassemble();
    setState(() {});
  }
}
