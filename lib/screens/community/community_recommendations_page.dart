import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/community_service.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/models_convertor/carousel_mapper.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/community/user_recommendations_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/media_items/media_peek_popup.dart';
import 'package:anymex/widgets/non_widgets/reasons_sheet.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommunityRecommendationsPage extends StatefulWidget {
  final ItemType type;
  final String category;
  final String title;

  const CommunityRecommendationsPage({
    super.key,
    required this.category,
    required this.type,
    this.title = 'Community Recommendations',
  });

  @override
  State<CommunityRecommendationsPage> createState() =>
      _CommunityRecommendationsPageState();
}

class _CommunityRecommendationsPageState
    extends State<CommunityRecommendationsPage> {
  final Map<String, VoteResult?> _votes = {};
  final Map<String, String?> _userVotes = {};
  final Map<String, bool> _loading = {};
  late bool _isGridView = General.communityListViewIsGrid.get<bool>(true);

  @override
  void initState() {
    super.initState();
    if (CommunityService.votingEnabled) {
      final svc = Get.find<CommunityService>();
      final sourceList = switch (widget.category) {
        'anime' => svc.communityAnimes,
        'manga' => svc.communityMangas,
        'shows' => svc.communityShows,
        'movies' => svc.communityMovies,
        _ => <CommunityMedia>[].obs,
      };
      for (final item in sourceList) {
        _loadVotes(item);
      }
    }
  }

  String _mediaType(CommunityMedia item) {
    final id = item.media.id;
    if (id.endsWith('*MOVIE')) return 'movie';
    if (id.endsWith('*SERIES')) return 'show';
    return widget.type == ItemType.manga ? 'manga' : 'anime';
  }

  String _mediaId(CommunityMedia item) {
    final id = item.media.id;
    if (id.contains('*')) return id.split('*').first;
    return id;
  }

  List<CommunityMedia> _getFilteredData() {
    final svc = Get.find<CommunityService>();
    return switch (widget.category) {
      'anime' => svc.getFilteredCommunityAnimes(),
      'manga' => svc.getFilteredCommunityMangas(),
      'shows' => svc.getFilteredCommunityShows(),
      'movies' => svc.getFilteredCommunityMovies(),
      _ => <CommunityMedia>[],
    };
  }

  Future<void> _loadVotes(CommunityMedia item) async {
    final id = _mediaId(item);
    final serviceHandler = Get.find<ServiceHandler>();
    final profile = serviceHandler.onlineService.profileData.value;
    final serviceType = serviceHandler.serviceType.value;

    int? anilistId;
    int? malId;
    int? simklId;

    if (serviceType == ServicesType.anilist) {
      anilistId = int.tryParse(profile.id ?? '');
    } else if (serviceType == ServicesType.mal) {
      malId = int.tryParse(profile.id ?? '');
    } else if (serviceType == ServicesType.simkl) {
      simklId = int.tryParse(profile.id ?? '');
    }

    final result = await CommunityService.fetchVotes(
      _mediaType(item),
      id,
      anilistUserId: anilistId,
      malUserId: malId,
      simklUserId: simklId,
    );
    if (mounted) {
      setState(() {
        _votes[id] = result;
        if (result != null) {
          _userVotes[id] = result.userVote;
        }
      });
    }
  }

  Future<void> _castVote(CommunityMedia item, String direction) async {
    final id = _mediaId(item);
    if (_loading[id] == true) return;

    final serviceHandler = Get.find<ServiceHandler>();
    final profile = serviceHandler.onlineService.profileData.value;
    final serviceType = serviceHandler.serviceType.value;

    int? anilistId;
    int? malId;
    int? simklId;
    String displayName = 'User';

    if (serviceType == ServicesType.anilist) {
      anilistId = int.tryParse(profile.id ?? '');
      displayName = profile.name ?? 'User';
    } else if (serviceType == ServicesType.mal) {
      malId = int.tryParse(profile.id ?? '');
      displayName = profile.name ?? 'User';
    } else if (serviceType == ServicesType.simkl) {
      simklId = int.tryParse(profile.id ?? '');
      displayName = profile.name ?? 'User';
    }

    if (anilistId == null && malId == null && simklId == null) return;

    setState(() => _loading[id] = true);

    final result = await CommunityService.castVote(
      mediaType: _mediaType(item),
      mediaId: id,
      direction: direction,
      anilistUserId: anilistId,
      malUserId: malId,
      simklUserId: simklId,
      displayName: displayName,
    );

    if (mounted) {
      setState(() {
        _loading[id] = false;
        if (result != null) {
          _votes[id] = result;
          _userVotes[id] = result.userVote;
        }
      });
    }
  }

  void _showSettingsSheet(BuildContext context) {
    final svc = Get.find<CommunityService>();
    showModalBottomSheet(
      context: context,
      builder: (_) => Obx(() {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymexText(
                  text: 'Filter Settings',
                  variant: TextVariant.semiBold,
                  color: context.colors.primary,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const AnymexText(text: 'Hide by List Status'),
                  subtitle: const AnymexText(
                      text: 'Filter out entries already in your list'),
                  value: svc.filterByListEnabled.value,
                  onChanged: (v) {
                    svc.filterByListEnabled.value = v;
                    General.filterByListEnabled.set(v);
                  },
                ),
                if (svc.filterByListEnabled.value) ...[
                  SwitchListTile(
                    title: const AnymexText(text: 'Hide Completed'),
                    value: svc.filterCompleted.value,
                    onChanged: (v) {
                      svc.filterCompleted.value = v;
                      General.filterCompleted.set(v);
                    },
                  ),
                  SwitchListTile(
                    title: const AnymexText(text: 'Hide Watching / Reading'),
                    value: svc.filterWatching.value,
                    onChanged: (v) {
                      svc.filterWatching.value = v;
                      General.filterWatching.set(v);
                    },
                  ),
                  SwitchListTile(
                    title: const AnymexText(text: 'Hide Dropped'),
                    value: svc.filterDropped.value,
                    onChanged: (v) {
                      svc.filterDropped.value = v;
                      General.filterDropped.set(v);
                    },
                  ),
                  SwitchListTile(
                    title: const AnymexText(text: 'Hide Planning'),
                    value: svc.filterPlanning.value,
                    onChanged: (v) {
                      svc.filterPlanning.value = v;
                      General.filterPlanning.set(v);
                    },
                  ),
                  SwitchListTile(
                    title: const AnymexText(text: 'Hide On Hold / Paused'),
                    value: svc.filterPaused.value,
                    onChanged: (v) {
                      svc.filterPaused.value = v;
                      General.filterPaused.set(v);
                    },
                  ),
                  SwitchListTile(
                    title: const AnymexText(text: 'Hide Rewatching'),
                    value: svc.filterRepeating.value,
                    onChanged: (v) {
                      svc.filterRepeating.value = v;
                      General.filterRepeating.set(v);
                    },
                  ),
                ],
                SwitchListTile(
                  title: const AnymexText(text: 'Hide NSFW'),
                  value: svc.hideNsfw.value,
                  onChanged: (v) {
                    svc.hideNsfw.value = v;
                    General.hideNsfwRecommendations.set(v);
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = getPlatform(context);

    return Glow(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          title: AnymexText(
            text: widget.title,
            variant: TextVariant.semiBold,
            color: context.colors.primary,
          ),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                  General.communityListViewIsGrid.set(_isGridView);
                });
              },
              icon: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              ),
            ),
            IconButton(
              onPressed: () => _showSettingsSheet(context),
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
        body: Obx(() {
          final data = _getFilteredData();
          final cardStyle = CardStyle.values[settingsController.cardStyle];
          final cardHeight = getCardHeight(cardStyle, isDesktop);
          final crossAxisCount = isDesktop ? 4 : 3;

          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_list_off_rounded,
                      size: 48,
                      color: context.colors.onSurfaceVariant.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  AnymexText(
                    text: 'No recommendations found',
                    color: context.colors.onSurfaceVariant.withOpacity(0.7),
                    variant: TextVariant.semiBold,
                  ),
                ],
              ),
            );
          }

          if (_isGridView) {
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent:
                    cardHeight + (CommunityService.votingEnabled ? 38 : 0),
              ),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final id = _mediaId(item);
                return _SeeAllCard(
                  item: item,
                  type: widget.type,
                  cardStyle: cardStyle,
                  isDesktop: isDesktop,
                  votes: _votes[id],
                  userVote: _userVotes[id],
                  isLoading: _loading[id] == true,
                  onVote: (dir) => _castVote(item, dir),
                );
              },
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final id = _mediaId(item);
                return _SeeAllListTile(
                  item: item,
                  type: widget.type,
                  votes: _votes[id],
                  userVote: _userVotes[id],
                  isLoading: _loading[id] == true,
                  onVote: (dir) => _castVote(item, dir),
                );
              },
            );
          }
        }),
      ),
    );
  }
}

class _SeeAllCard extends StatelessWidget {
  final CommunityMedia item;
  final ItemType type;
  final CardStyle cardStyle;
  final bool isDesktop;
  final VoteResult? votes;
  final String? userVote;
  final bool isLoading;
  final void Function(String direction) onVote;

  const _SeeAllCard({
    required this.item,
    required this.type,
    required this.cardStyle,
    required this.isDesktop,
    required this.votes,
    required this.userVote,
    required this.isLoading,
    required this.onVote,
  });

  String get _mediaType {
    final id = item.media.id;
    if (id.endsWith('*MOVIE')) return 'movie';
    if (id.endsWith('*SERIES')) return 'show';
    return type == ItemType.manga ? 'manga' : 'anime';
  }

  String get _mediaId {
    final id = item.media.id;
    if (id.contains('*')) return id.split('*').first;
    return id;
  }

  void _navigateToDetails() {
    final media = item.media;
    final tag = 'community-all-${media.id}';
    if (type == ItemType.manga) {
      navigate(() => MangaDetailsPage(media: media, tag: tag));
    } else {
      navigate(() => AnimeDetailsPage(media: media, tag: tag));
    }
  }

  void _showPeekPopup(BuildContext context) {
    final serviceType = Get.find<ServiceHandler>().serviceType.value;
    MediaPeekPopup.show(
      context,
      item.media,
      type,
      'community-all-${item.media.id}',
      author: item.usernameFor(serviceType),
      avatarUrl: item.avatarFor(serviceType),
      reason: item.reason,
      reasons: item.reasons,
      rawJson: item.rawJson,
      anilistUserId: item.anilistUserId,
      malUserId: item.malUserId,
      anilistUsername: item.anilistUsername,
      malUsername: item.malUsername,
      simklUserId: item.simklUserId,
      simklUsername: item.simklUsername,
      voteMediaType: _mediaType,
      voteMediaId: _mediaId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serviceHandler = Get.find<ServiceHandler>();
    final serviceType = serviceHandler.serviceType.value;
    final author = item.usernameFor(serviceType);
    final avatarUrl = item.avatarFor(serviceType);
    final carouselData = item.toCarouselData(isManga: type == ItemType.manga);
    final tag = 'community-all-${carouselData.id}-${item.media.hashCode}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _navigateToDetails,
            onLongPress: () => _showPeekPopup(context),
            child: Stack(
              children: [
                MediaCardGate(
                  itemData: carouselData,
                  tag: tag,
                  variant: DataVariant.underrated,
                  cardStyle: cardStyle,
                  type: type,
                ),
                if (item.hasMultipleReasons)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _ReasonCountBadge(count: item.reasonCount),
                  )
                else if (author != null && author.isNotEmpty)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _AuthorBadge(
                      item: item,
                      author: author,
                      avatarUrl: avatarUrl,
                      serviceType: serviceType,
                      theme: theme,
                      isAdmin: item.isFirstReasonAdmin,
                      userProfile: item.firstReason?.user,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (CommunityService.votingEnabled)
          _VoteBar(
            votes: votes,
            userVote: userVote,
            isLoading: isLoading,
            onVote: onVote,
          ),
      ],
    );
  }
}

class _AuthorBadge extends StatelessWidget {
  final CommunityMedia item;
  final String author;
  final String? avatarUrl;
  final ServicesType serviceType;
  final ThemeData theme;
  final bool isAdmin;
  final ReasonUserProfile? userProfile;

  const _AuthorBadge({
    required this.item,
    required this.author,
    required this.avatarUrl,
    required this.serviceType,
    required this.theme,
    this.isAdmin = false,
    this.userProfile,
  });

  void _navigateToAuthor() => navigateToAuthorProfile(item);

  void _navigateToUserRecs() {
    if (userProfile != null) {
      navigate(() => UserRecommendationsPage(user: userProfile!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToAuthor,
      onLongPress: userProfile != null ? _navigateToUserRecs : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 100),
        padding: const EdgeInsets.only(left: 3, right: 10, top: 3, bottom: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withOpacity(0.85),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: _AuthorAvatar(
                  avatarUrl: avatarUrl, fallbackLabel: author, size: 24),
            ),
            const SizedBox(width: 3),
            Flexible(
              child: AutoSizeText(
                author,
                maxLines: 1,
                minFontSize: 6,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'Poppins-SemiBold',
                  color: theme.colorScheme.onSecondaryContainer,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(Icons.verified_rounded,
                    size: 11, color: theme.colorScheme.onSecondaryContainer),
              ),
          ],
        ),
      ),
    );
  }
}

class _VoteBar extends StatelessWidget {
  final VoteResult? votes;
  final String? userVote;
  final bool isLoading;
  final void Function(String direction) onVote;

  const _VoteBar({
    required this.votes,
    required this.userVote,
    required this.isLoading,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest.opaque(0.6),
        border: Border(
          top: BorderSide(color: colors.outline.withOpacity(0.08)),
        ),
      ),
      child: isLoading
          ? Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: colors.primary,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: _VoteBtn(
                      icon: Icons.thumb_up_rounded,
                      count: votes?.upvotes ?? 0,
                      active: userVote == 'up',
                      isUpvote: true,
                      onTap: () => onVote('up'),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 14,
                    color: colors.outline.withOpacity(0.12),
                  ),
                  Expanded(
                    child: _VoteBtn(
                      icon: Icons.thumb_down_rounded,
                      count: votes?.downvotes ?? 0,
                      active: userVote == 'down',
                      isUpvote: false,
                      onTap: () => onVote('down'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _VoteBtn extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool active;
  final bool isUpvote;
  final VoidCallback onTap;

  const _VoteBtn({
    required this.icon,
    required this.count,
    required this.active,
    required this.isUpvote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final activeColor = isUpvote ? colors.primary : colors.error;
    final activeBgColor = isUpvote
        ? colors.primary.opaque(0.12, iReallyMeanIt: true)
        : colors.error.opaque(0.12, iReallyMeanIt: true);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: active ? activeBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: active ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Icon(
                  icon,
                  size: 13,
                  color: active ? activeColor : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  color: active ? activeColor : colors.onSurfaceVariant,
                  fontFamily: 'Poppins-SemiBold',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? fallbackLabel;
  final double size;

  const _AuthorAvatar(
      {required this.avatarUrl,
      required this.fallbackLabel,
      required this.size});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? AnymeXImage(
              imageUrl: avatarUrl!,
              width: size,
              height: size,
              radius: size / 2,
            )
          : Center(
              child: Text(
                (fallbackLabel?.trim().isNotEmpty == true
                        ? fallbackLabel!.trim()[0]
                        : '?')
                    .toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.52,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
    );
  }
}

class _ReasonCountBadge extends StatelessWidget {
  final int count;
  const _ReasonCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 8, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.9),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_rounded,
              size: 12, color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              '$count',
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'Poppins-SemiBold',
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeeAllListTile extends StatelessWidget {
  final CommunityMedia item;
  final ItemType type;
  final VoteResult? votes;
  final String? userVote;
  final bool isLoading;
  final void Function(String direction) onVote;

  const _SeeAllListTile({
    required this.item,
    required this.type,
    required this.votes,
    required this.userVote,
    required this.isLoading,
    required this.onVote,
  });

  String get _mediaType {
    final id = item.media.id;
    if (id.endsWith('*MOVIE')) return 'movie';
    if (id.endsWith('*SERIES')) return 'show';
    return type == ItemType.manga ? 'manga' : 'anime';
  }

  String get _mediaId {
    final id = item.media.id;
    if (id.contains('*')) return id.split('*').first;
    return id;
  }

  void _navigateToDetails() {
    final media = item.media;
    final tag = 'community-list-${media.id}';
    if (type == ItemType.manga) {
      navigate(() => MangaDetailsPage(media: media, tag: tag));
    } else {
      navigate(() => AnimeDetailsPage(media: media, tag: tag));
    }
  }

  void _navigateToAuthor() => navigateToAuthorProfile(item);

  void _navigateToUserRecs() {
    final user = item.firstReason?.user;
    if (user != null) {
      navigate(() => UserRecommendationsPage(user: user));
    }
  }

  void _showPeekPopup(BuildContext context) {
    final serviceType = Get.find<ServiceHandler>().serviceType.value;
    MediaPeekPopup.show(
      context,
      item.media,
      type,
      'community-list-${item.media.id}',
      author: item.usernameFor(serviceType),
      avatarUrl: item.avatarFor(serviceType),
      reason: item.reason,
      anilistUserId: item.anilistUserId,
      malUserId: item.malUserId,
      anilistUsername: item.anilistUsername,
      malUsername: item.malUsername,
      simklUserId: item.simklUserId,
      simklUsername: item.simklUsername,
      voteMediaType: _mediaType,
      voteMediaId: _mediaId,
      rawJson: item.rawJson,
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceType = Get.find<ServiceHandler>().serviceType.value;
    final author = item.usernameFor(serviceType);
    final avatarUrl = item.avatarFor(serviceType);
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _navigateToDetails,
      onLongPress: () => _showPeekPopup(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
              child: AnymeXImage(
                imageUrl: item.media.poster,
                width: 70,
                height: 100,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymexText(
                      text: item.displayTitle,
                      variant: TextVariant.semiBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.reason != null && item.reason!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      AnymexText(
                        text: item.reason!,
                        variant: TextVariant.regular,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                    if (author != null && author.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _navigateToAuthor,
                        onLongPress: item.firstReason?.user != null
                            ? _navigateToUserRecs
                            : null,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            ClipOval(
                              child: _AuthorAvatar(
                                  avatarUrl: avatarUrl,
                                  fallbackLabel: author,
                                  size: 18),
                            ),
                            const SizedBox(width: 4),
                            AnymexText(
                              text: author,
                              variant: TextVariant.semiBold,
                              color: colors.primary,
                            ),
                            if (item.isFirstReasonAdmin) ...[
                              const SizedBox(width: 3),
                              Icon(Icons.verified_rounded,
                                  size: 12, color: colors.primary),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (item.hasMultipleReasons) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => ReasonsSheet.show(
                          context,
                          item: item,
                          mediaItemType: type,
                          voteMediaType: _mediaType,
                          voteMediaId: _mediaId,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.secondaryContainer.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_rounded,
                                  size: 12, color: colors.onSecondaryContainer),
                              const SizedBox(width: 4),
                              AnymexText(
                                text: '${item.reasonCount} recommendations',
                                size: 11,
                                color: colors.onSecondaryContainer,
                                variant: TextVariant.semiBold,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (CommunityService.votingEnabled) ...[
                      const SizedBox(height: 6),
                      _VoteBar(
                        votes: votes,
                        userVote: userVote,
                        isLoading: isLoading,
                        onVote: onVote,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
