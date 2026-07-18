import 'dart:async';
import 'dart:io';
import 'package:anymex/database/database.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/screens/extensions/ExtensionList.dart';
import 'package:anymex/screens/extensions/ExtensionTesting/extension_test_page.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/screens/settings/sub_settings/settings_extensions.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/custom_widgets/anymex_tabbar.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';

class ExtensionScreen extends StatefulWidget {
  final bool disableGlow;
  const ExtensionScreen({super.key, this.disableGlow = false});

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

  static const _contentTabs = [
    (label: 'Anime', icon: Icons.movie_creation_outlined, type: ItemType.anime),
    (label: 'Manga', icon: Icons.menu_book_outlined, type: ItemType.manga),
    (label: 'Novel', icon: Icons.auto_stories_outlined, type: ItemType.novel),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _searchDebounce?.cancel();
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
    return Glow(
      disabled: widget.disableGlow,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            NestedHeader(
              title: 'Extensions',
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.primaryContainer.opaque(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.build_outlined,
                          color: theme.primary, size: 22),
                      onPressed: () => Get.to(() => const ExtensionTestPage()),
                      tooltip: "Test Extensions",
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.primaryContainer.opaque(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: Icon(HugeIcons.strokeRoundedGithub,
                          color: theme.primary, size: 22),
                      onPressed: () => navigate(() => const SettingsExtensions()),
                      tooltip: "Repositories",
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            const SizedBox(height: 6),
            _buildSearchRow(),
            const SizedBox(height: 4),
            Expanded(child: _buildView()),
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
            final active = _hasActiveFilters;
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
                    onPressed: () => _showFilterSheet(context),
                    icon: Icon(
                      Iconsax.setting_4,
                      size: 20,
                      color: active
                          ? context.colors.primary
                          : context.colors.onSurface.withOpacity(0.55),
                    ),
                    tooltip: 'Filter',
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

  void _showFilterSheet(BuildContext context) {
    final languages = sortedLanguagesMap.keys.toList();
    final sourceTypes = Platform.isIOS
        ? ['all', 'Mangayomi', 'Sora']
        : ['all', 'Mangayomi', 'Aniyomi', 'Cloudstream', 'Sora', 'Kotatsu'];

    AnymexSheet(
      title: 'Filter Options',
      showDragHandle: true,
      contentWidget: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Obx(() {
            final selSource = _selectedSourceType.value;
            final selLang = _selectedLanguage.value;
            final hasActive = selSource != 'all' || selLang != 'all';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasActive) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _selectedSourceType.value = 'all';
                        _selectedLanguage.value = 'all';
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.colors.primary,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                AnymexExpansionTile(
                  title: 'Source Type',
                  initialExpanded: true,
                  content: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.8,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: sourceTypes.length,
                      itemBuilder: (context, index) {
                        final type = sourceTypes[index];
                        final needsPlugin = _typeRequiresPlugin(type) &&
                            !_isPluginInstalled;
                        final isSelected = !needsPlugin && selSource == type;
                        final label = type == 'all' ? 'All Sources' : type;

                        return InkWell(
                          onTap: needsPlugin
                              ? null
                              : () {
                                  _selectedSourceType.value = type;
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 155),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.colors.primaryContainer
                                      .withOpacity(0.25)
                                  : context.colors.surfaceContainerHighest
                                      .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : context.colors.outline.withOpacity(0.12),
                                width: 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSelected) ...[
                                  Icon(Icons.check_circle_rounded,
                                      size: 14,
                                      color: context.colors.primary),
                                  const SizedBox(width: 6),
                                ] else if (needsPlugin) ...[
                                  Icon(Icons.lock_outline_rounded,
                                      size: 14,
                                      color: context.colors.onSurface
                                          .withOpacity(0.4)),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? context.colors.primary
                                          : context.colors.onSurface
                                              .withOpacity(0.85),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnymexExpansionTile(
                  title: 'Language',
                  initialExpanded: true,
                  content: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.8,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: languages.length,
                      itemBuilder: (context, index) {
                        final lang = languages[index];
                        final label = lang == 'all' ? 'All Languages' : lang;
                        final isSelected = selLang == lang;

                        return InkWell(
                          onTap: () {
                            _selectedLanguage.value = lang;
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 155),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.colors.primaryContainer
                                      .withOpacity(0.25)
                                  : context.colors.surfaceContainerHighest
                                      .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : context.colors.outline.withOpacity(0.12),
                                width: 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSelected) ...[
                                  Icon(Icons.check_circle_rounded,
                                      size: 14,
                                      color: context.colors.primary),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? context.colors.primary
                                          : context.colors.onSurface
                                              .withOpacity(0.85),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    ).show(context);
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

  bool get _isPluginInstalled => AnymeXRuntimeBridge.isPluginInstalled;

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
