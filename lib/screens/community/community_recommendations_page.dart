import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/underrated_service.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CommunityRecommendationsPage extends StatefulWidget {
  final List<UnderratedMedia> data;
  final ItemType type;
  final String title;

  const CommunityRecommendationsPage({
    super.key,
    required this.data,
    required this.type,
    this.title = 'Community Recommendations',
  });

  @override
  State<CommunityRecommendationsPage> createState() =>
      _CommunityRecommendationsPageState();
}

class _CommunityRecommendationsPageState
    extends State<CommunityRecommendationsPage> {
  // vote state per item: mediaId -> { votes, userVote, loading }
  final Map<String, VoteResult?> _votes = {};
  final Map<String, String?> _userVotes = {};
  final Map<String, bool> _loading = {};

  @override
  void initState() {
    super.initState();
    if (UnderratedService.votingEnabled) {
      for (final item in widget.data) {
        _loadVotes(item);
      }
    }
  }

  String _mediaType(UnderratedMedia item) {
    final id = item.media.id;
    if (id.endsWith('*MOVIE')) return 'movie';
    if (id.endsWith('*SERIES')) return 'show';
    return widget.type == ItemType.manga ? 'manga' : 'anime';
  }

  String _mediaId(UnderratedMedia item) {
    final id = item.media.id;
    if (id.contains('*')) return id.split('*').first;
    return id;
  }

  Future<void> _loadVotes(UnderratedMedia item) async {
    final id = _mediaId(item);
    final result = await UnderratedService.fetchVotes(_mediaType(item), id);
    if (mounted) setState(() => _votes[id] = result);
  }

  Future<void> _castVote(UnderratedMedia item, String direction) async {
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

    final result = await UnderratedService.castVote(
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
          _userVotes[id] = _userVotes[id] == direction ? null : direction;
        }
      });
    }
  }

  void _navigateToDetails(UnderratedMedia item) {
    final media = item.media;
    final tag = 'community-all-${media.id}';
    if (widget.type == ItemType.manga) {
      navigate(() => MangaDetailsPage(media: media, tag: tag));
    } else {
      navigate(() => AnimeDetailsPage(media: media, tag: tag));
    }
  }

  void _navigateToAuthor(UnderratedMedia item) {
    final serviceType = Get.find<ServiceHandler>().serviceType.value;
    if (serviceType == ServicesType.anilist && item.anilistUserId != null) {
      navigate(() => UserProfilePage(userId: item.anilistUserId!));
    } else if (item.malUsername != null && item.malUsername!.isNotEmpty) {
      launchUrlString('https://myanimelist.net/profile/${item.malUsername}');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: AnymexText(
                text: '${widget.data.length}',
                color: context.colors.primary.withOpacity(0.6),
                variant: TextVariant.semiBold,
              ),
            ),
          ],
        ),
        body: widget.data.isEmpty
            ? const Center(child: AnymexProgressIndicator())
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 220,
                ),
                itemCount: widget.data.length,
                itemBuilder: (context, index) {
                  final item = widget.data[index];
                  return _buildCard(context, item);
                },
              ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, UnderratedMedia item) {
    final theme = Theme.of(context);
    final serviceType = Get.find<ServiceHandler>().serviceType.value;
    final author = item.usernameFor(serviceType);
    final avatarUrl = item.avatarFor(serviceType);
    final id = _mediaId(item);
    final votes = _votes[id];
    final userVote = _userVotes[id];
    final isLoading = _loading[id] == true;

    return GestureDetector(
      onTap: () => _navigateToDetails(item),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Poster
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnymeXImage(
                    imageUrl: item.media.poster,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  // Score badge
                  if (item.media.rating.isNotEmpty &&
                      item.media.rating != '?')
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 11, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              item.media.rating,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontFamily: 'Poppins-SemiBold',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Author badge
                  if (author != null && author.isNotEmpty)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: GestureDetector(
                        onTap: () => _navigateToAuthor(item),
                        child: Container(
                          constraints:
                              const BoxConstraints(maxWidth: 110),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer
                                .withOpacity(0.88),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipOval(
                                child: _Avatar(
                                    avatarUrl: avatarUrl,
                                    label: author,
                                    size: 18),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: AutoSizeText(
                                  author,
                                  maxLines: 1,
                                  minFontSize: 6,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Poppins-SemiBold',
                                    color: theme.colorScheme
                                        .onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Title + reason
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymexText(
                    text: item.displayTitle,
                    variant: TextVariant.semiBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    size: 12,
                  ),
                  if (item.reason != null && item.reason!.isNotEmpty)
                    AnymexText(
                      text: item.reason!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      size: 10,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                ],
              ),
            ),
            // Vote bar
            if (UnderratedService.votingEnabled)
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.7),
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _VoteBtn(
                            icon: Icons.thumb_up_rounded,
                            count: votes?.upvotes ?? 0,
                            active: userVote == 'up',
                            activeColor: Colors.green,
                            onTap: () => _castVote(item, 'up'),
                          ),
                          Container(
                            width: 1,
                            height: 14,
                            color:
                                theme.colorScheme.outline.withOpacity(0.2),
                          ),
                          _VoteBtn(
                            icon: Icons.thumb_down_rounded,
                            count: votes?.downvotes ?? 0,
                            active: userVote == 'down',
                            activeColor: Colors.red,
                            onTap: () => _castVote(item, 'down'),
                          ),
                        ],
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
  final Color activeColor;
  final VoidCallback onTap;

  const _VoteBtn({
    required this.icon,
    required this.count,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? activeColor
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontFamily: 'Poppins-SemiBold',
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String? label;
  final double size;

  const _Avatar({this.avatarUrl, this.label, required this.size});

  @override
  Widget build(BuildContext context) {
    final has = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: has
          ? AnymeXImage(
              imageUrl: avatarUrl!,
              width: size,
              height: size,
              radius: size / 2,
            )
          : Center(
              child: Text(
                (label?.trim().isNotEmpty == true
                        ? label!.trim()[0]
                        : '?')
                    .toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.52,
                  fontWeight: FontWeight.w700,
                  color:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
    );
  }
}
