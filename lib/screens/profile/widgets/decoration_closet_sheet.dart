import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/comments/model/user_customization.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_decorated_avatar.dart';
import 'package:anymex/widgets/anymex_widgets/linked_accounts_badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DecorationClosetSheet extends StatefulWidget {
  const DecorationClosetSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DecorationClosetSheet(),
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
  List<AnimeBannerItem> _allBanners = [];
  Map<String, List<AnimeBannerItem>> _categorizedBanners = {};
  String _selectedCategory = 'All';

  bool _loadingCatalog = true;
  bool _isSaving = false;

  // Working preview state
  String? _previewDecorationUrl;
  String? _previewBannerUrl;

  final TextEditingController _customBannerController = TextEditingController();
  final TextEditingController _linkTokenController = TextEditingController();
  String _linkingService = 'mal';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _previewDecorationUrl = _commentumService.currentUserDecoration.value.isNotEmpty
        ? _commentumService.currentUserDecoration.value
        : null;
    _previewBannerUrl = _commentumService.currentUserBanner.value.isNotEmpty
        ? _commentumService.currentUserBanner.value
        : null;
    _customBannerController.text = _previewBannerUrl ?? '';
    _loadCatalog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customBannerController.dispose();
    _linkTokenController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() => _loadingCatalog = true);
    final decos = await CustomizationRepository.loadDecorations();
    final banners = await CustomizationRepository.loadBanners();
    final categorized = await CustomizationRepository.loadCategorizedBanners();
    if (mounted) {
      setState(() {
        _decorations = decos;
        _allBanners = banners;
        _categorizedBanners = categorized;
        _loadingCatalog = false;
      });
    }
  }

  Future<void> _saveCustomizations() async {
    setState(() => _isSaving = true);
    final success = await _commentumService.updateCustomizations(
      avatarDecoration: _previewDecorationUrl ?? '',
      bannerUrl: _previewBannerUrl ?? '',
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Get.snackbar(
          'Profile Updated',
          'Your avatar decoration and banner have been saved!',
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Header preview card
          _buildLivePreviewCard(colorScheme, userAvatar, userName),
          const SizedBox(height: 12),

          // Tabs
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
              tabs: const [
                Tab(text: 'Decorations'),
                Tab(text: 'Banners'),
                Tab(text: 'Linked Accounts'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab content
          Expanded(
            child: _loadingCatalog
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDecorationsTab(colorScheme),
                      _buildBannersTab(colorScheme),
                      _buildLinkedAccountsTab(colorScheme),
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
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
          // Gradient dark overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),
          // User info content
          Positioned(
            left: 16,
            bottom: 16,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(() {
                      final linked = _commentumService.currentUserLinkedAccounts.value;
                      return LinkedAccountsBadges(
                        linkedAccounts: linked,
                        fontSize: 10,
                        interactive: false,
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          // Tag top right
          Positioned(
            top: 10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: const Text(
                'Live Preview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorationsTab(ColorScheme colorScheme) {
    return Column(
      children: [
        // Controls / Clear decoration button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_decorations.length} Discord Decorations',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_previewDecorationUrl != null)
                GestureDetector(
                  onTap: () {
                    setState(() => _previewDecorationUrl = null);
                  },
                  child: Text(
                    'Remove Decoration',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Grid of decorations
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _decorations.length,
            itemBuilder: (context, index) {
              final item = _decorations[index];
              final isSelected = _previewDecorationUrl == item.url;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _previewDecorationUrl = isSelected ? null : item.url;
                  });
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
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
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
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, err) =>
                                const Icon(Icons.broken_image, size: 20),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontSize: 10.5,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
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

  Widget _buildBannersTab(ColorScheme colorScheme) {
    final categories = ['All', ..._categorizedBanners.keys];
    final displayedBanners = _selectedCategory == 'All'
        ? _allBanners
        : (_categorizedBanners[_selectedCategory] ?? []);

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
                  style: const TextStyle(fontSize: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Apply', style: TextStyle(fontSize: 12)),
              ),
              if (_previewBannerUrl != null) ...[
                const SizedBox(width: 6),
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
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedCategory = cat);
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
                      color: isSelected ? colorScheme.primary : Colors.transparent,
                      width: isSelected ? 2.5 : 0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.35),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: item.banner,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: colorScheme.surfaceContainer,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.surfaceContainer,
                            child: const Icon(Icons.broken_image, size: 24),
                          ),
                        ),
                        // Label overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            color: Colors.black.withOpacity(0.65),
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
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
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 14),
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

  Widget _buildLinkedAccountsTab(ColorScheme colorScheme) {
    return Obx(() {
      final linked = _commentumService.currentUserLinkedAccounts.value;
      final currentService = serviceHandler.serviceType.value.name.toLowerCase();

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Link your AniList, MyAnimeList, and Simkl accounts so all your customizations, banners, comments, and stats stay synced under one unified profile.',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // AniList Card
          _buildServiceCard(
            colorScheme: colorScheme,
            serviceName: 'AniList',
            serviceKey: 'anilist',
            isPrimary: currentService == 'anilist',
            linkedData: linked['anilist'],
            accentColor: const Color(0xFF02A9FF),
          ),
          const SizedBox(height: 10),

          // MAL Card
          _buildServiceCard(
            colorScheme: colorScheme,
            serviceName: 'MyAnimeList',
            serviceKey: 'mal',
            isPrimary: currentService == 'mal' || currentService == 'myanimelist',
            linkedData: linked['mal'],
            accentColor: const Color(0xFF2E51A2),
          ),
          const SizedBox(height: 10),

          // Simkl Card
          _buildServiceCard(
            colorScheme: colorScheme,
            serviceName: 'Simkl',
            serviceKey: 'simkl',
            isPrimary: currentService == 'simkl',
            linkedData: linked['simkl'],
            accentColor: const Color(0xFFFFAE19),
          ),
        ],
      );
    });
  }

  Widget _buildServiceCard({
    required ColorScheme colorScheme,
    required String serviceName,
    required String serviceKey,
    required bool isPrimary,
    required dynamic linkedData,
    required Color accentColor,
  }) {
    final username = linkedData is Map ? linkedData['username']?.toString() : null;
    final isLinked = isPrimary || (username != null && username.isNotEmpty);
    final activeToken = _commentumService.getTokenForService(serviceKey);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLinked ? accentColor.withOpacity(0.5) : colorScheme.outline.withOpacity(0.1),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                serviceName.substring(0, 1),
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      serviceName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isPrimary)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PRIMARY',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isLinked
                      ? 'Linked as @${username ?? _commentumService.currentUsername}'
                      : 'Not linked',
                  style: TextStyle(
                    color: isLinked ? accentColor : colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: isLinked ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (!isPrimary && isLinked)
            TextButton(
              onPressed: () => _handleUnlink(serviceKey),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
              ),
              child: const Text('Unlink', style: TextStyle(fontSize: 12)),
            )
          else if (!isPrimary && !isLinked)
            ElevatedButton(
              onPressed: () => _handleLink(serviceKey, activeToken),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                activeToken != null ? '1-Tap Link' : 'Link',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleLink(String serviceKey, String? activeToken) async {
    if (activeToken != null && activeToken.isNotEmpty) {
      // 1-tap link using currently saved session token
      try {
        final res = await _commentumService.linkAccount(
          targetClientType: serviceKey,
          targetAccessToken: activeToken,
        );
        if (res != null && mounted) {
          Get.snackbar('Account Linked', 'Linked $serviceKey successfully!',
              snackPosition: SnackPosition.BOTTOM);
        }
      } catch (e) {
        Get.snackbar('Link Failed', e.toString(),
            snackPosition: SnackPosition.BOTTOM);
      }
    } else {
      // Prompt for access token
      _linkingService = serviceKey;
      _linkTokenController.clear();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Link $serviceKey'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your $serviceKey access token to link this account:',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _linkTokenController,
                decoration: const InputDecoration(
                  labelText: 'Access Token',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final token = _linkTokenController.text.trim();
                if (token.isNotEmpty) {
                  Navigator.pop(ctx);
                  try {
                    await _commentumService.linkAccount(
                      targetClientType: _linkingService,
                      targetAccessToken: token,
                    );
                    Get.snackbar('Success', 'Account linked successfully!',
                        snackPosition: SnackPosition.BOTTOM);
                  } catch (e) {
                    Get.snackbar('Error', e.toString(),
                        snackPosition: SnackPosition.BOTTOM);
                  }
                }
              },
              child: const Text('Link Account'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleUnlink(String serviceKey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Unlink $serviceKey?'),
        content: const Text(
          'Are you sure you want to unlink this account? It will no longer be unified with your profile.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _commentumService.unlinkAccount(serviceKey);
      if (success) {
        Get.snackbar('Unlinked', 'Successfully unlinked $serviceKey',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  Widget _buildBottomActionBar(ColorScheme colorScheme) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    : Text(
                        'Save & Equip',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
