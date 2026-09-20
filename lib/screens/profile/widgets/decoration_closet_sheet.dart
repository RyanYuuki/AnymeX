import 'package:anymex/database/comments/model/user_customization.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_decorated_avatar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/linked_accounts_badges.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DecorationClosetSheet extends StatefulWidget {
  const DecorationClosetSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AnymeXSheet.custom(
      const DecorationClosetSheet(),
      context,
    );
  }

  @override
  State<DecorationClosetSheet> createState() => _DecorationClosetSheetState();
}

class _DecorationClosetSheetState extends State<DecorationClosetSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommentumService _commentumService = Get.find<CommentumService>();

  List<AvatarDecorationItem> _decorations = [];
  List<CustomizationItem> _nameplates = [];
  List<AnimeBannerItem> _allBanners = [];
  Map<String, List<AnimeBannerItem>> _categorizedBanners = {};
  List<CustomizationItem> _effects = [];
  String _selectedBannerCategory = 'All';

  bool _loadingCatalog = true;
  bool _isSaving = false;

  // Working preview state
  String? _previewDecorationUrl;
  String? _previewBannerUrl;
  String? _previewNameplateUrl;
  String? _previewEffectUrl;

  final TextEditingController _customBannerController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _previewDecorationUrl =
        _commentumService.currentUserDecoration.value.isNotEmpty
            ? _commentumService.currentUserDecoration.value
            : null;
    _previewBannerUrl = _commentumService.currentUserBanner.value.isNotEmpty
        ? _commentumService.currentUserBanner.value
        : null;
    _previewNameplateUrl =
        _commentumService.currentUserNameplateTheme.value.isNotEmpty
            ? _commentumService.currentUserNameplateTheme.value
            : null;
    _previewEffectUrl =
        _commentumService.currentUserProfileEffect.value.isNotEmpty
            ? _commentumService.currentUserProfileEffect.value
            : null;

    _customBannerController.text = _previewBannerUrl ?? '';
    _loadCatalog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customBannerController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() => _loadingCatalog = true);
    final results = await Future.wait([
      CustomizationRepository.loadDecorations(),
      CustomizationRepository.loadNameplates(),
      CustomizationRepository.loadBanners(),
      CustomizationRepository.loadCategorizedBanners(),
      CustomizationRepository.loadEffects(),
    ]);

    if (mounted) {
      setState(() {
        _decorations = results[0] as List<AvatarDecorationItem>;
        _nameplates = results[1] as List<CustomizationItem>;
        _allBanners = results[2] as List<AnimeBannerItem>;
        _categorizedBanners =
            results[3] as Map<String, List<AnimeBannerItem>>;
        _effects = results[4] as List<CustomizationItem>;
        _loadingCatalog = false;
      });
    }
  }

  bool _isUnlocked(String id, int pointsRequired) {
    if (pointsRequired <= 0) return true;
    final role = _commentumService.currentUserRole.value;
    if (['owner', 'app_owner', 'super_admin', 'admin', 'moderator'].contains(role)) {
      return true;
    }
    return _commentumService.unlockedCustomizations.contains(id);
  }

  Future<void> _unlockItem(String id, String title) async {
    final res = await _commentumService.unlockCustomization(id);
    if (mounted) {
      if (res['success'] == true) {
        snackBar(res['message']?.toString() ?? 'Successfully unlocked $title!');
        setState(() {});
      } else {
        snackBar(res['error']?.toString() ?? 'Failed to unlock');
      }
    }
  }

  Future<void> _saveCustomizations() async {
    setState(() => _isSaving = true);
    final success = await _commentumService.updateCustomizations(
      avatarDecoration: _previewDecorationUrl ?? '',
      bannerUrl: _previewBannerUrl ?? '',
      nameplateTheme: _previewNameplateUrl ?? '',
      profileEffectUrl: _previewEffectUrl ?? '',
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Get.snackbar(
          'Profile Updated',
          'Your customizations have been saved and applied!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: context.colors.surfaceContainerHighest,
          colorText: context.colors.onSurface,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to update customizations. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final userAvatar = _commentumService.currentUserAvatar;
    final userName = _commentumService.currentUsername ?? 'You';

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Header Live Preview
          _buildLivePreviewCard(colorScheme, userAvatar, userName),
          const SizedBox(height: 12),

          // 4 Tabs: Decorations, Nameplates, Banners, Effects
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: const [
                Tab(text: 'Decorations'),
                Tab(text: 'Nameplates'),
                Tab(text: 'Banners'),
                Tab(text: 'Effects'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tab views
          Expanded(
            child: _loadingCatalog
                ? const Center(child: ExpressiveLoadingIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDecorationsTab(colorScheme),
                      _buildNameplatesTab(colorScheme),
                      _buildBannersTab(colorScheme),
                      _buildEffectsTab(colorScheme),
                    ],
                  ),
          ),

          // Bottom Action Bar
          _buildBottomActionBar(colorScheme),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard(
      ColorScheme colorScheme, String? userAvatar, String userName) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceContainerHigh,
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
        image: _previewBannerUrl != null && _previewBannerUrl!.isNotEmpty
            ? DecorationImage(
                image: CachedNetworkImageProvider(_previewBannerUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Dark gradient overlay for banner text readability
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.scrim.withOpacity(0.25),
                  colorScheme.scrim.withOpacity(0.72),
                ],
              ),
            ),
          ),

          // Effect overlay preview if chosen
          if (_previewEffectUrl != null && _previewEffectUrl!.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Opacity(
                  opacity: 0.5,
                  child: CachedNetworkImage(
                    imageUrl: _previewEffectUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

          // User Info (Avatar + Decoration + Nameplate + Badges)
          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnymeXDecoratedAvatar(
                  avatarUrl: userAvatar,
                  decorationUrl: _previewDecorationUrl,
                  size: 56,
                  decorationScale: 1.25,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Username with optional Nameplate background
                      _buildUsernameWithNameplate(userName, colorScheme),
                      const SizedBox(height: 4),
                      Obx(() {
                        final linked =
                            _commentumService.currentUserLinkedAccounts.value;
                        return LinkedAccountsBadges(
                          linkedAccounts: linked,
                          fontSize: 10,
                          interactive: false,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Live Preview Chip
          Positioned(
            top: 10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.65),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2), width: 0.8),
              ),
              child: AnymeXText(
                'Live Preview',
                size: 10,
                variant: TextVariant.semiBold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameWithNameplate(String userName, ColorScheme colorScheme) {
    if (_previewNameplateUrl != null && _previewNameplateUrl!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: colorScheme.surfaceContainerHighest.withOpacity(0.7),
          border: Border.all(color: colorScheme.primary.withOpacity(0.4)),
        ),
        child: AnymeXText(
          userName,
          variant: TextVariant.bold,
          size: 15,
          color: colorScheme.onSurface,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    return AnymeXText(
      userName,
      variant: TextVariant.bold,
      size: 16,
      color: Colors.white,
      style: const TextStyle(
        shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // --- TAB 1: DECORATIONS ---
  Widget _buildDecorationsTab(ColorScheme colorScheme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnymeXText(
                '${_decorations.length} Avatar Decorations',
                size: 12.5,
                variant: TextVariant.semiBold,
                color: colorScheme.onSurfaceVariant,
              ),
              if (_previewDecorationUrl != null)
                GestureDetector(
                  onTap: () => setState(() => _previewDecorationUrl = null),
                  child: AnymeXText(
                    'Remove Decoration',
                    size: 12,
                    variant: TextVariant.bold,
                    color: colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.85,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _decorations.length,
            itemBuilder: (context, index) {
              final item = _decorations[index];
              final isSelected = _previewDecorationUrl == item.url;
              final unlocked = _isUnlocked(item.id, item.pointsRequired);

              return GestureDetector(
                onTap: () {
                  if (unlocked) {
                    setState(() {
                      _previewDecorationUrl = isSelected ? null : item.url;
                    });
                  } else {
                    _unlockItem(item.id, item.title);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.08),
                      width: isSelected ? 2.2 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: CachedNetworkImage(
                            imageUrl: item.url,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 20),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                        child: AnymeXText(
                          item.title,
                          size: 10.5,
                          variant: isSelected
                              ? TextVariant.bold
                              : TextVariant.regular,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!unlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AnymeXText(
                            '★ ${item.pointsRequired}',
                            size: 9,
                            variant: TextVariant.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 2: NAMEPLATES ---
  Widget _buildNameplatesTab(ColorScheme colorScheme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnymeXText(
                '${_nameplates.length} Collectible Nameplates',
                size: 12.5,
                variant: TextVariant.semiBold,
                color: colorScheme.onSurfaceVariant,
              ),
              if (_previewNameplateUrl != null)
                GestureDetector(
                  onTap: () => setState(() => _previewNameplateUrl = null),
                  child: AnymeXText(
                    'Remove Nameplate',
                    size: 12,
                    variant: TextVariant.bold,
                    color: colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _nameplates.length,
            itemBuilder: (context, index) {
              final item = _nameplates[index];
              final isSelected = _previewNameplateUrl == item.url ||
                  _previewNameplateUrl == item.staticUrl;
              final unlocked = _isUnlocked(item.id, item.pointsRequired);
              final displayUrl = item.staticUrl ?? item.url;

              return GestureDetector(
                onTap: () {
                  if (unlocked) {
                    setState(() {
                      _previewNameplateUrl = isSelected ? null : item.url;
                    });
                  } else {
                    _unlockItem(item.id, item.title);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.1),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (displayUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: displayUrl,
                            width: 44,
                            height: 28,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.badge_outlined, size: 20),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnymeXText(
                              item.title,
                              size: 11.5,
                              variant: isSelected
                                  ? TextVariant.bold
                                  : TextVariant.semiBold,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            AnymeXText(
                              item.category,
                              size: 9.5,
                              color: colorScheme.onSurfaceVariant,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!unlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AnymeXText(
                            '★ ${item.pointsRequired}',
                            size: 9,
                            variant: TextVariant.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 3: BANNERS ---
  Widget _buildBannersTab(ColorScheme colorScheme) {
    final categories = ['All', ..._categorizedBanners.keys];
    final displayedBanners = _selectedBannerCategory == 'All'
        ? _allBanners
        : (_categorizedBanners[_selectedBannerCategory] ?? []);

    return Column(
      children: [
        // Custom URL input
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customBannerController,
                  decoration: InputDecoration(
                    hintText: 'Paste custom image URL...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: colorScheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final text = _customBannerController.text.trim();
                  if (text.isNotEmpty) {
                    setState(() => _previewBannerUrl = text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Apply', style: TextStyle(fontSize: 12)),
              ),
              if (_previewBannerUrl != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _previewBannerUrl = null;
                      _customBannerController.clear();
                    });
                  },
                  icon: Icon(Icons.clear, color: colorScheme.error, size: 20),
                  tooltip: 'Remove Banner',
                ),
              ],
            ],
          ),
        ),

        // Category Chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedBannerCategory == cat;
              return ChoiceChip(
                label: Text(cat, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedBannerCategory = cat);
                },
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide.none,
              );
            },
          ),
        ),
        const SizedBox(height: 6),

        // Grid of Banners
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 16 / 9,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: displayedBanners.length,
            itemBuilder: (context, index) {
              final item = displayedBanners[index];
              final isSelected = _previewBannerUrl == item.banner;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _previewBannerUrl = isSelected ? null : item.banner;
                    _customBannerController.text = _previewBannerUrl ?? '';
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                      width: isSelected ? 2.5 : 0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: item.banner,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: colorScheme.surfaceContainer,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: colorScheme.surfaceContainer,
                            child: const Icon(Icons.broken_image, size: 24),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            color: colorScheme.scrim.withOpacity(0.65),
                            child: AnymeXText(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              size: 9.5,
                              color: Colors.white,
                              variant: TextVariant.semiBold,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primary,
                              ),
                              child: Icon(Icons.check,
                                  color: colorScheme.onPrimary, size: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 4: EFFECTS ---
  Widget _buildEffectsTab(ColorScheme colorScheme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnymeXText(
                '${_effects.length} Profile Effects',
                size: 12.5,
                variant: TextVariant.semiBold,
                color: colorScheme.onSurfaceVariant,
              ),
              if (_previewEffectUrl != null)
                GestureDetector(
                  onTap: () => setState(() => _previewEffectUrl = null),
                  child: AnymeXText(
                    'Remove Effect',
                    size: 12,
                    variant: TextVariant.bold,
                    color: colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.9,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _effects.length,
            itemBuilder: (context, index) {
              final item = _effects[index];
              final isSelected = _previewEffectUrl == item.url;
              final unlocked = _isUnlocked(item.id, item.pointsRequired);
              final thumb = item.thumbnailUrl ?? item.url;

              return GestureDetector(
                onTap: () {
                  if (unlocked) {
                    setState(() {
                      _previewEffectUrl = isSelected ? null : item.url;
                    });
                  } else {
                    _unlockItem(item.id, item.title);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.08),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CachedNetworkImage(
                            imageUrl: thumb,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.auto_awesome, size: 24),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                        child: AnymeXText(
                          item.title,
                          size: 10.5,
                          variant: isSelected
                              ? TextVariant.bold
                              : TextVariant.regular,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!unlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AnymeXText(
                            '★ ${item.pointsRequired}',
                            size: 9,
                            variant: TextVariant.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(ColorScheme colorScheme) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(color: colorScheme.outline.withOpacity(0.08)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: AnymeXButton(
                onTap: _isSaving ? () {} : _saveCustomizations,
                backgroundColor: colorScheme.primary,
                child: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : AnymeXText(
                        'Save & Equip',
                        color: colorScheme.onPrimary,
                        variant: TextVariant.bold,
                        size: 14,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
