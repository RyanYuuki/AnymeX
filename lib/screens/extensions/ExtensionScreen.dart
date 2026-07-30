import 'dart:async';
import 'dart:io';
import 'package:anymex/database/database.dart';
import 'package:anymex_extension_runtime_bridge/Services/Aniyomi/Models/Source.dart';
import 'package:anymex_extension_runtime_bridge/Services/Sora/Models/Source.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/screens/extensions/ExtensionList.dart';
import 'package:anymex/screens/extensions/ExtensionTesting/extension_test_page.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/screens/settings/sub_settings/settings_extension_manager.dart';
import 'package:anymex/screens/settings/sub_settings/settings_extensions.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/anymex_tabbar.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class ExtensionScreen extends StatefulWidget {
  const ExtensionScreen({
    super.key,
    this.disableGlow = false,
    this.isTabScreen = false,
  });

  final bool disableGlow;
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

  static const _contentTabs = [
    (label: 'Anime', icon: Icons.movie_creation_outlined, type: ItemType.anime),
    (label: 'Manga', icon: Icons.menu_book_outlined, type: ItemType.manga),
    (label: 'Novel', icon: Icons.auto_stories_outlined, type: ItemType.novel),
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

  bool get _hasActiveFilters =>
      _selectedLanguage.value != 'all' || _selectedSourceType.value != 'all';

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final showMobileAppBar = widget.isTabScreen && !isDesktop;

    final statusBarHeight = MediaQuery.of(context).padding.top;
    const appBarHeight = kToolbarHeight + 20;

    final mainContent = Column(
      children: [
        if (widget.isTabScreen) ...[
          if (isDesktop) ...[
            const SizedBox(height: 10),
            const Header(type: PageType.extensions),
            const SizedBox(height: 20),
          ] else ...[
            SizedBox(height: statusBarHeight + appBarHeight),
          ]
        ] else ...[
          NestedHeader(
            title: 'Extensions',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.build_outlined,
                      color: theme.primary, size: 20),
                  onPressed: () => Get.to(() => const ExtensionTestPage()),
                  tooltip: "Test Extensions",
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
                  tooltip: "Repositories",
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

    return Glow(
      disabled: widget.disableGlow,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            mainContent,
            if (showMobileAppBar)
              CustomAnimatedAppBar(
                isVisible: _isAppBarVisible,
                scrollController: _appBarScrollController,
                headerContent: const Header(type: PageType.extensions),
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
        ),
      ),
    );
  }

  Widget _buildContentTypeBar() {
    return Obx(() {
      final selected = _selectedContentType.value;
      const tabs = _contentTabs;
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
                hintText: 'Search extensions...',
                hintStyle: TextStyle(
                  color: context.colors.onSurface.withOpacity(0.4),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.colors.onSurface.withOpacity(0.45),
                  size: 20,
                ),
                filled: true,
                fillColor:
                    context.colors.surfaceContainerHighest.withOpacity(0.4),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
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
                    tooltip: 'Select Language',
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
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
              maxWidth: 400,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.language_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select Language',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Obx(() {
                    final selLang = _selectedLanguage.value;
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: languages.length,
                      itemBuilder: (context, index) {
                        final lang = languages[index];
                        final label = lang == 'all' ? 'All Languages' : lang;
                        final isSelected = selLang == lang;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: AnymexOnTap(
                            onTap: () {
                              _selectedLanguage.value = lang;
                              Navigator.pop(context);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primaryContainer.opaque(0.35, iReallyMeanIt: true)
                                    : theme.colorScheme.surfaceContainer.opaque(0.3, iReallyMeanIt: true),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary.opaque(0.5, iReallyMeanIt: true)
                                      : theme.colorScheme.outline.opaque(0.15, iReallyMeanIt: true),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outline.opaque(0.4, iReallyMeanIt: true),
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Icon(Icons.check_rounded,
                                            size: 14, color: theme.colorScheme.onPrimary)
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _getManagerIcon(String type) {
    switch (type) {
      case 'Mangayomi':
        return MSource(id: '', name: '', lang: '').managerIcon;
      case 'Aniyomi':
        return ASource(id: '', name: '', lang: '').managerIcon;
      case 'Cloudstream':
        return CloudStreamSource(id: '', name: '', lang: '').managerIcon;
      case 'Sora':
        return SSource(id: '', name: '', lang: '').managerIcon;
      case 'Kotatsu':
        return KotatsuSource(id: '', name: '', lang: '').managerIcon;
      default:
        return null;
    }
  }

  Widget _buildSourceTypeChips() {
    final sourceTypes = Platform.isIOS
        ? ['all', 'Mangayomi', 'Sora']
        : ['all', 'Mangayomi', 'Aniyomi', 'Cloudstream', 'Sora', 'Kotatsu'];

    return Obx(() {
      final selectedType = _selectedSourceType.value;
      return Container(
        height: 38,
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: sourceTypes.length,
          itemBuilder: (context, index) {
            final type = sourceTypes[index];
            final needsPlugin = _typeRequiresPlugin(type) && !_isPluginInstalled;
            final isSelected = !needsPlugin && selectedType == type;
            final label = type == 'all' ? 'All' : type;
            final iconUrl = _getManagerIcon(type);

            return Opacity(
              opacity: needsPlugin ? 0.5 : 1.0,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildSourceChip(
                  label: label,
                  iconUrl: iconUrl,
                  isSelected: isSelected,
                  onTap: needsPlugin
                      ? () {
                          Get.to(() => const SettingsExtensionManager());
                        }
                      : () {
                          _selectedSourceType.value = type;
                        },
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildSourceChip({
    required String label,
    String? iconUrl,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.opaque(0.15, iReallyMeanIt: true)
              : theme.colorScheme.surfaceContainerHighest
                  .opaque(0.3, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.opaque(0.4, iReallyMeanIt: true)
                : theme.colorScheme.onSurface.opaque(0.08, iReallyMeanIt: true),
            width: isSelected ? 1.2 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconUrl != null && iconUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AnymeXImage(
                  width: 16,
                  height: 16,
                  imageUrl: iconUrl,
                ),
              ),
              const SizedBox(width: 6),
            ] else ...[
              Icon(
                Icons.all_inclusive_rounded,
                size: 14,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
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
      );
    });
  }

  bool get _isPluginInstalled =>
      AnymeXRuntimeBridge.isPluginInstalled ||
      AnymeXRuntimeBridge.controller.isReady.value;

  bool _typeRequiresPlugin(String type) {
    if (type == 'all') return false;
    final activeManager =
        Get.find<ExtensionManager>().managers.firstWhereOrNull(
              (m) => m.name.toLowerCase().contains(type.toLowerCase()),
            );
    if (activeManager != null) return activeManager.requiresPlugin;
    return type == 'Aniyomi' || type == 'Cloudstream';
  }

  @override
  void reassemble() {
    super.reassemble();
    setState(() {});
  }
}
