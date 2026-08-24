import 'dart:io';
import 'dart:ui' as ui;

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/compatibility_controller.dart';
import 'package:get/get.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Anilist/social_user.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/anime/studio_details_page.dart';
import 'package:anymex/screens/anime/widgets/character_staff_sheet.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/screens/profile/widgets/favorites_section.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/utils/compatibility/compatibility_models.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_linear_indicator.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/marquee_text.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:anymex/widgets/media_items/media_peek_popup.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CompatibilityResultPage extends StatefulWidget {
  final CompatibilityController controller;

  const CompatibilityResultPage({super.key, required this.controller});

  @override
  State<CompatibilityResultPage> createState() => _CompatibilityResultPageState();
}

class _CompatibilityResultPageState extends State<CompatibilityResultPage> {
  final GlobalKey _shareCardKey = GlobalKey();
  int _selectedTab = 0; 
  bool _isSharing = false;
  bool _isHowItWorksExpanded = false;
  final Set<String> _expandedSections = <String>{};

  bool _isExpanded(String sectionKey) => _expandedSections.contains(sectionKey);

  void _toggleExpanded(String sectionKey) {
    setState(() {
      if (_expandedSections.contains(sectionKey)) {
        _expandedSections.remove(sectionKey);
      } else {
        _expandedSections.add(sectionKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final result = widget.controller.result.value;
      final user1 = widget.controller.user1.value;
      final user2 = widget.controller.user2.value;

      if (result == null || user1 == null || user2 == null) {
        return const AnymeXScaffold(
          showHeader: true,
          headerTitle: 'Compatibility',
          body: Center(
            child: AnymeXText('No result', size: 16),
          ),
        );
      }

      final rank = getRankForScore(result.percentage.roundToDouble());
      final screenWidth = MediaQuery.sizeOf(context).width;
      final isLargeScreen = screenWidth > 768;
      final maxContentWidth = isLargeScreen ? 1120.0 : 640.0;

      return AnymeXScaffold(
        showHeader: true,
        headerTitle: 'AniMatch',
        headerAction: IconButton(
          icon: _isSharing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.share_rounded),
          onPressed: _isSharing
              ? null
              : () => _shareCard(user1.name ?? '', user2.name ?? '', result),
          tooltip: 'Share Match Card',
        ),
        body: Builder(
          builder: (ctx) => ScrollWrapper(
            comfortPadding: false,
            customPadding: EdgeInsets.fromLTRB(
              16,
              AnymeXHeaderScope.of(ctx),
              16,
              36,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    
                      if (isLargeScreen) ...[
                        _buildTopActionBar(context, user1, user2, result),
                        const SizedBox(height: 14),
                      ],

                    
                      RepaintBoundary(
                        key: _shareCardKey,
                        child: _buildOverallHeader(context, user1, user2, result, rank),
                      ),
                      const SizedBox(height: 16),

                   
                      _buildSectionTabsWithProgress(context, result),
                      const SizedBox(height: 18),

                    
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.025),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<int>(_selectedTab),
                          child: (_selectedTab == 0 && result.animeSection.hasData)
                              ? _buildSectionGrid(context, result.animeSection, isManga: false, isLargeScreen: isLargeScreen)
                              : (_selectedTab == 1 && result.mangaSection.hasData)
                                  ? _buildSectionGrid(context, result.mangaSection, isManga: true, isLargeScreen: isLargeScreen)
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 48),
                                      child: Center(
                                        child: AnymeXText(
                                          'No data available for this section',
                                          size: 14,
                                          color: context.colors.onSurfaceVariant.opaque(0.7),
                                        ),
                                      ),
                                    ),
                        ),
                      ),

                      const SizedBox(height: 16),

                     
                      if (result.socialData != null) ...[
                        _buildSocialConnectionsCard(context, user1, user2, result.socialData!),
                        const SizedBox(height: 16),
                      ],
                      _buildHowItWorksCard(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }



  Widget _buildTopActionBar(
    BuildContext context,
    Profile user1,
    Profile user2,
    CompatibilityResult result,
  ) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Iconsax.heart5, color: c.primary, size: 20),
            const SizedBox(width: 8),
            const AnymeXText(
              'AniMatch',
              size: 18,
              variant: TextVariant.bold,
            ),
          ],
        ),
        AnymeXButton(
          onTap: _isSharing
              ? () {}
              : () => _shareCard(user1.name ?? '', user2.name ?? '', result),
          height: 38,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Icon(Icons.share_rounded, size: 15, color: c.onPrimary),
              const SizedBox(width: 6),
              AnymeXText(
                'Share Match Card',
                size: 12,
                variant: TextVariant.bold,
                color: c.onPrimary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  

  Color _getRankColor(RankInfo rank) {
    try {
      final hex = rank.colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.amber;
    }
  }

  Widget _buildOverallHeader(
    BuildContext context,
    Profile user1,
    Profile user2,
    CompatibilityResult result,
    RankInfo rank,
  ) {
    final name1 = user1.name ?? 'User 1';
    final name2 = user2.name ?? 'User 2';
    final avatar1 = user1.avatar ?? '';
    final avatar2 = user2.avatar ?? '';
    final c = context.colors;
    final rankColor = _getRankColor(rank);

    String formatUserSubtitle(Profile u, String name) {
      if (u.createdAt != null && u.createdAt! > 0) {
        final year = DateTime.fromMillisecondsSinceEpoch(u.createdAt! * 1000).year;
        return '@${name.toLowerCase()} · Joined $year';
      }
      return '@${name.toLowerCase()}';
    }

    final user1Subtitle = formatUserSubtitle(user1, name1);
    final user2Subtitle = formatUserSubtitle(user2, name2);

    return AnymeXContainer(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      radius: 20,
      enableGlow: true,
      color: c.surfaceContainerHighest.opaque(0.4),
      border: Border.all(
        color: c.outline.opaque(0.15),
        width: 1.5,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.heart5, color: c.primary, size: 16),
              const SizedBox(width: 8),
              AnymeXText(
                'AniMatch Compatibility',
                size: 13,
                variant: TextVariant.bold,
                color: c.onSurfaceVariant.opaque(0.9),
              ),
            ],
          ),
          const SizedBox(height: 18),

         
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
             
              Expanded(
                child: _buildUserAvatarColumn(
                  context,
                  name1,
                  avatar1,
                  subtitle: user1Subtitle,
                  userId: int.tryParse(user1.id ?? '') ?? 0,
                  borderColor: c.primary,
                ),
              ),

           
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: result.percentage),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (context, val, _) {
                            return AnymeXText(
                              '${val.toStringAsFixed(0)}%',
                              size: 42,
                              variant: TextVariant.bold,
                              color: c.onSurface,
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutBack,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: rankColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: rankColor,
                                width: 2,
                              ),
                            ),
                            child: AnymeXText(
                              rank.name,
                              size: 26,
                              variant: TextVariant.bold,
                              color: rankColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AnymeXText(
                      result.rankDescription,
                      size: 12,
                      textAlign: TextAlign.center,
                      color: c.onSurfaceVariant.opaque(0.85),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

           
              Expanded(
                child: _buildUserAvatarColumn(
                  context,
                  name2,
                  avatar2,
                  subtitle: user2Subtitle,
                  userId: int.tryParse(user2.id ?? '') ?? 0,
                  borderColor: c.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatarColumn(
    BuildContext context,
    String name,
    String avatar, {
    String? subtitle,
    int? userId,
    required Color borderColor,
  }) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (userId != null && userId > 0) {
          navigate(() => UserProfilePage(userId: userId));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor.opaque(0.85),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: avatar.isNotEmpty
                    ? AnymeXImage(
                        imageUrl: avatar,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 72,
                        height: 72,
                        color: c.surfaceContainerHigh,
                        alignment: Alignment.center,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: MarqueeText(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: c.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
                if (userId != null && userId > 0) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 13,
                    color: borderColor.opaque(0.9),
                  ),
                ],
              ],
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              MarqueeText(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: c.onSurfaceVariant.opaque(0.75),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }



  Widget _buildSectionTabsWithProgress(
    BuildContext context,
    CompatibilityResult result,
  ) {
    final animeRank = getRankForScore(result.animeSection.percentage.roundToDouble());
    final mangaRank = getRankForScore(result.mangaSection.percentage.roundToDouble());

    return Row(
      children: [
        _buildSectionTabItem(
          context,
          tabIndex: 0,
          title: 'Anime',
          percentage: result.animeSection.percentage,
          rank: animeRank,
          icon: Iconsax.video_play,
        ),
        const SizedBox(width: 14),
        _buildSectionTabItem(
          context,
          tabIndex: 1,
          title: 'Manga',
          percentage: result.mangaSection.percentage,
          rank: mangaRank,
          icon: Iconsax.book,
        ),
      ],
    );
  }

  Widget _buildSectionTabItem(
    BuildContext context, {
    required int tabIndex,
    required String title,
    required double percentage,
    required RankInfo rank,
    required IconData icon,
  }) {
    final c = context.colors;
    final isSelected = _selectedTab == tabIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
            setState(() => _selectedTab = tabIndex);
          }
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected
                  ? c.surfaceContainerHighest.opaque(0.45)
                  : c.surfaceContainerHighest.opaque(0.2),
              border: Border.all(
                color: isSelected ? c.primary.opaque(0.8) : c.outline.opaque(0.1),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? c.primary : c.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MarqueeText(
                        '$title (${percentage.toStringAsFixed(0)}% · ${rank.name})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? c.onSurface : c.onSurfaceVariant,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AnymeXLinearIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  minHeight: 9,
                  backgroundColor: c.surfaceContainerHigh.opaque(0.6),
                  color: isSelected ? c.primary : c.primary.opaque(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  HeuristicDetail? _findDetail(CompatibilitySection section, List<String> possibleKeys) {
    return section.details.where((d) {
      final k = d.key.toLowerCase().replaceAll('_', '');
      return possibleKeys.any((pk) => k == pk.toLowerCase().replaceAll('_', ''));
    }).firstOrNull;
  }

  Widget _buildSectionGrid(
    BuildContext context,
    CompatibilitySection section, {
    required bool isManga,
    required bool isLargeScreen,
  }) {
    final watchStatsDetail = _findDetail(section, ['watchStats', 'mangaReadStats', 'watch_stats', 'read_stats']);
    final releaseYearDetail = _findDetail(section, ['releaseYear', 'mangaReleaseYear', 'release_year']);
    final genresDetail = _findDetail(section, ['genres', 'mangaGenres', 'genre']);
    final tagsDetail = _findDetail(section, ['tags', 'mangaTags', 'tag']);
    final perfectMediaDetail = _findDetail(section, ['perfectAnime', 'perfectManga', 'perfect_anime', 'perfect_manga']);
    final favMediaDetail = _findDetail(section, ['favouriteAnime', 'favouriteManga', 'fav_anime', 'fav_manga']);
    final favCharactersDetail = _findDetail(section, ['favouriteCharacters', 'fav_characters', 'characters']);
    final voiceActorsDetail = _findDetail(section, ['voiceActors', 'voice_actors', 'voiceactor']);
    final studiosDetail = _findDetail(section, ['studios', 'studio']);
    final favStaffDetail = _findDetail(section, ['staff', 'fav_staff', 'favouritestaff']);

    if (isLargeScreen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (watchStatsDetail != null) ...[
                  _buildWatchStatsCard(context, watchStatsDetail, isManga: isManga, isLargeScreen: isLargeScreen),
                  const SizedBox(height: 16),
                ],
                if (genresDetail != null) ...[
                  _buildGenresCard(context, genresDetail, isLargeScreen: isLargeScreen, isManga: isManga),
                  const SizedBox(height: 16),
                ],
                if (perfectMediaDetail != null) ...[
                  _buildPerfectMediaCard(context, perfectMediaDetail, isManga: isManga, isLargeScreen: isLargeScreen),
                  const SizedBox(height: 16),
                ],
                if (!isManga && favCharactersDetail != null) ...[
                  _buildCharactersCard(context, favCharactersDetail, isLargeScreen: isLargeScreen),
                  const SizedBox(height: 16),
                ],
                if (!isManga && studiosDetail != null) ...[
                  _buildStudiosCard(context, studiosDetail, isLargeScreen: isLargeScreen),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (releaseYearDetail != null) ...[
                  _buildReleaseYearCard(context, releaseYearDetail, isLargeScreen: isLargeScreen),
                  const SizedBox(height: 16),
                ],
                if (tagsDetail != null) ...[
                  _buildTagsCard(context, tagsDetail, isLargeScreen: isLargeScreen, isManga: isManga),
                  const SizedBox(height: 16),
                ],
                if (favMediaDetail != null) ...[
                  _buildFavouritesMediaCard(context, favMediaDetail, isManga: isManga, isLargeScreen: isLargeScreen),
                  const SizedBox(height: 16),
                ],
                if (!isManga && voiceActorsDetail != null) ...[
                  _buildVoiceActorsCard(context, voiceActorsDetail, isLargeScreen: isLargeScreen),
                  const SizedBox(height: 16),
                ],
                if (!isManga && favStaffDetail != null) ...[
                  _buildStaffCard(context, favStaffDetail, isLargeScreen: isLargeScreen),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (watchStatsDetail != null) ...[
          _buildWatchStatsCard(context, watchStatsDetail, isManga: isManga),
          const SizedBox(height: 16),
        ],

        if (releaseYearDetail != null) ...[
          _buildReleaseYearCard(context, releaseYearDetail),
          const SizedBox(height: 16),
        ],

        if (genresDetail != null) ...[
          _buildGenresCard(context, genresDetail, isManga: isManga),
          const SizedBox(height: 16),
        ],

        if (tagsDetail != null) ...[
          _buildTagsCard(context, tagsDetail, isManga: isManga),
          const SizedBox(height: 16),
        ],

        if (perfectMediaDetail != null) ...[
          _buildPerfectMediaCard(context, perfectMediaDetail, isManga: isManga),
          const SizedBox(height: 16),
        ],

        if (favMediaDetail != null) ...[
          _buildFavouritesMediaCard(context, favMediaDetail, isManga: isManga),
          const SizedBox(height: 16),
        ],

        if (favCharactersDetail != null) ...[
          _buildCharactersCard(context, favCharactersDetail),
          const SizedBox(height: 16),
        ],

        if (voiceActorsDetail != null) ...[
          _buildVoiceActorsCard(context, voiceActorsDetail),
          const SizedBox(height: 16),
        ],

        if (studiosDetail != null) ...[
          _buildStudiosCard(context, studiosDetail),
          const SizedBox(height: 16),
        ],

        if (favStaffDetail != null) ...[
          _buildStaffCard(context, favStaffDetail),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  

  Widget _buildWatchStatsCard(
    BuildContext context,
    HeuristicDetail detail, {
    required bool isManga,
    bool isLargeScreen = false,
  }) {
    final c = context.colors;
    final totalsCard = detail.cards.where((c) => c.title == 'Totals').firstOrNull;
    final rows = totalsCard?.rows ?? [];

    Widget body;
    if (rows.isEmpty) {
      body = Center(
        child: AnymeXText(
          'No stats available',
          size: 12,
          color: c.onSurfaceVariant.opaque(0.6),
        ),
      );
    } else {
      body = Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows.map((row) {
          IconData rowIcon = Iconsax.chart;
          final labelLower = row.label.toLowerCase();
          if (labelLower.contains('completed')) {
            rowIcon = Iconsax.send_2;
          } else if (labelLower.contains('episodes') || labelLower.contains('chapters')) {
            rowIcon = Iconsax.play_circle;
          } else if (labelLower.contains('hours') || labelLower.contains('volumes')) {
            rowIcon = Iconsax.clock;
          } else if (labelLower.contains('mean') || labelLower.contains('score')) {
            rowIcon = Icons.star_rounded;
          }

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.primary.opaque(0.12),
                    ),
                    child: Icon(rowIcon, size: 18, color: c.primary),
                  ),
                  const SizedBox(height: 8),
               
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: AnymeXText(
                          row.user1Value,
                          size: 13,
                          variant: TextVariant.bold,
                          textAlign: TextAlign.right,
                          color: c.primary,
                          maxLines: 1,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: c.primary.opaque(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: AnymeXText(
                          'vs',
                          size: 8.5,
                          variant: TextVariant.bold,
                          color: c.primary,
                        ),
                      ),
                      Flexible(
                        child: AnymeXText(
                          row.user2Value,
                          size: 13,
                          variant: TextVariant.bold,
                          textAlign: TextAlign.left,
                          color: c.secondary,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 18,
                    child: MarqueeText(
                      row.label,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: c.onSurfaceVariant.opaque(0.8),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    return AnymeXContainer(
      padding: const EdgeInsets.all(20),
      radius: 20,
      enableGlow: true,
      color: c.surfaceContainerHighest.opaque(0.38),
      border: Border.all(
        color: c.outline.opaque(0.12),
        width: 1.2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            context,
            icon: isManga ? Iconsax.book_1 : Iconsax.video_play,
            title: isManga ? 'Read Stats' : 'Watch Stats',
            subtitle: isManga
                ? 'Calculated based on how much manga you\'ve read.'
                : 'Calculated based on how much anime you\'ve watched.',
            percentage: detail.percentage,
            weight: detail.weight,
          ),
          const SizedBox(height: 20),
          body,
        ],
      ),
    );
  }

  

  Widget _buildReleaseYearCard(BuildContext context, HeuristicDetail detail, {bool isLargeScreen = false}) {
    final c = context.colors;
    final decadeCards = detail.cards.where((card) {
      final propRow = card.rows.where((r) => r.label.toLowerCase().contains('proportion')).firstOrNull;
      final prop1 = double.tryParse(propRow?.user1Value.replaceAll('%', '') ?? '0') ?? 0.0;
      final prop2 = double.tryParse(propRow?.user2Value.replaceAll('%', '') ?? '0') ?? 0.0;
      return prop1 > 0 || prop2 > 0;
    }).toList();

    Widget body;
    if (decadeCards.isEmpty) {
      body = Center(
        child: AnymeXText(
          'No decade breakdown available',
          size: 12,
          color: c.onSurfaceVariant.opaque(0.6),
        ),
      );
    } else {
      body = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: decadeCards.map((card) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _buildDecadeGaugeItem(context, card),
            );
          }).toList(),
        ),
      );
    }

    return AnymeXContainer(
      padding: const EdgeInsets.all(20),
      radius: 20,
      enableGlow: true,
      color: c.surfaceContainerHighest.opaque(0.38),
      border: Border.all(
        color: c.outline.opaque(0.12),
        width: 1.2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            context,
            icon: Iconsax.calendar,
            title: 'Release Year Stats',
            subtitle: 'Calculated based on which release decades you watched the most and scored the highest.',
            percentage: detail.percentage,
            weight: detail.weight,
          ),
          const SizedBox(height: 20),
          body,
        ],
      ),
    );
  }

  Widget _buildDecadeGaugeItem(BuildContext context, HeuristicCardData card) {
    final c = context.colors;
    final propRow = card.rows.where((r) => r.label.toLowerCase().contains('proportion')).firstOrNull;
    final prop1 = double.tryParse(propRow?.user1Value.replaceAll('%', '') ?? '0') ?? 0.0;
    final prop2 = double.tryParse(propRow?.user2Value.replaceAll('%', '') ?? '0') ?? 0.0;
    final avgPct = ((prop1 + prop2) / 2.0).clamp(0.0, 100.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BikeMeterSweepGauge(
          targetPercentage: avgPct,
          size: 52,
          strokeWidth: 3.5,
          primaryColor: c.primary,
          secondaryColor: c.secondary.opaque(0.85),
          backgroundColor: c.surfaceContainerHigh.opaque(0.6),
        ),
        const SizedBox(height: 10),
        AnymeXText(
          card.title,
          size: 13,
          variant: TextVariant.bold,
        ),
        const SizedBox(height: 4),
        if (propRow != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnymeXText(propRow.user1Value, size: 11, variant: TextVariant.bold, color: c.primary),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnymeXText('vs', size: 9, color: c.onSurfaceVariant.opaque(0.6), variant: TextVariant.bold),
              ),
              AnymeXText(propRow.user2Value, size: 11, variant: TextVariant.bold, color: c.secondary),
            ],
          ),
      ],
    );
  }

  

  Widget _buildGenresCard(BuildContext context, HeuristicDetail detail, {bool isLargeScreen = false, bool isManga = false}) {
    return _buildHeuristicCardContainer(
      context,
      icon: Iconsax.category,
      title: 'Common Genres',
      subtitle: 'Based on your top 5 genres.',
      detail: detail,
      padding: const EdgeInsets.all(18),
      child: _buildExpandableCardListBody(
        context,
        detail,
        emptyText: 'No common genres',
        itemTypeLabel: 'Genres',
        isTag: false,
        isManga: isManga,
      ),
    );
  }


  Widget _buildTagsCard(BuildContext context, HeuristicDetail detail, {bool isLargeScreen = false, bool isManga = false}) {
    return _buildHeuristicCardContainer(
      context,
      icon: Icons.tag,
      title: 'Common Tags',
      subtitle: 'Based on your top 10 tags.',
      detail: detail,
      padding: const EdgeInsets.all(18),
      child: _buildExpandableCardListBody(
        context,
        detail,
        emptyText: 'No common tags',
        itemTypeLabel: 'Tags',
        isTag: true,
        isManga: isManga,
      ),
    );
  }

  Widget _buildExpandableCardListBody(
    BuildContext context,
    HeuristicDetail detail, {
    required String emptyText,
    required String itemTypeLabel,
    required bool isTag,
    required bool isManga,
  }) {
    final cards = detail.cards;
    if (cards.isEmpty) {
      return Center(child: _buildEmptyPlaceholder(context, emptyText));
    }
    final isExpanded = _isExpanded(detail.key);
    final visibleCount = isExpanded ? cards.length : 2;
    final displayedCards = cards.take(visibleCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...displayedCards.map((card) => _buildGenreOrTagRowItem(context, card, isTag: isTag, isManga: isManga)),
        if (cards.length > 2) ...[
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _toggleExpanded(detail.key);
              },
              child: AnymeXText(
                isExpanded ? 'Collapse $itemTypeLabel' : 'View all $itemTypeLabel (${cards.length})',
                size: 12,
                variant: TextVariant.semiBold,
                color: context.colors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenreOrTagRowItem(
    BuildContext context,
    HeuristicCardData card, {
    bool isTag = false,
    bool isManga = false,
  }) {
    final c = context.colors;
    final meanScoreRow = card.rows.where((r) => r.label.toLowerCase().contains('mean')).firstOrNull;
    final countRow = card.rows.where((r) => r.label.toLowerCase().contains('count')).firstOrNull;
    final commonMedia = card.commonMediaItems;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final label = card.title.trim();
        if (label.isNotEmpty) {
          _showCommonMediaSheet(
            context,
            title: label,
            mediaList: commonMedia,
            isManga: isManga,
            isTag: isTag,
          );
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.surfaceContainerHigh.opaque(0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: c.outline.opaque(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: MarqueeText(
                      card.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: c.onSurface,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 13,
                    color: c.primary.opaque(0.75),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        if (meanScoreRow != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AnymeXText(
                                meanScoreRow.user1Value,
                                size: 12,
                                variant: TextVariant.bold,
                                color: c.primary,
                              ),
                              AnymeXText('Mean Score', size: 10, color: c.onSurfaceVariant.opaque(0.75)),
                              AnymeXText(
                                meanScoreRow.user2Value,
                                size: 12,
                                variant: TextVariant.bold,
                                color: c.secondary,
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        if (countRow != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AnymeXText(
                                countRow.user1Value,
                                size: 12,
                                variant: TextVariant.bold,
                                color: c.primary.opaque(0.9),
                              ),
                              AnymeXText('Count', size: 10, color: c.onSurfaceVariant.opaque(0.75)),
                              AnymeXText(
                                countRow.user2Value,
                                size: 12,
                                variant: TextVariant.bold,
                                color: c.secondary.opaque(0.9),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (card.posterUrls.isNotEmpty) ...[
                    const SizedBox(width: 14),
                    _buildMiniPosterCollage(card.posterUrls),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPosterCollage(List<String> posterUrls) {
    final count = posterUrls.take(3).length;
    if (count == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      width: (count - 1) * 16.0 + 34.0,
      child: Stack(
        children: posterUrls.take(3).toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final url = entry.value;
          return Positioned(
            left: idx * 16.0,
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black.withOpacity(0.5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: AnymeXImage(
                  imageUrl: url,
                  width: 32,
                  height: 46,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showCommonMediaSheet(
    BuildContext context, {
    required String title,
    required List<FavouriteMedia> mediaList,
    required bool isManga,
    required bool isTag,
  }) {
    final c = context.colors;
    final typeLabel = isManga ? 'Manga' : 'Anime';

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLarge = screenWidth > 768;
    final crossAxisCount = isLarge ? 5 : 3;

    AnymeXSheet.custom(
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: c.onSurfaceVariant.opaque(0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.primary.opaque(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isTag ? Icons.tag : Iconsax.category,
                    size: 20,
                    color: c.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: MarqueeText(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: c.onSurface,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.primary.opaque(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: AnymeXText(
                              '${mediaList.length} Shared',
                              size: 11,
                              variant: TextVariant.bold,
                              color: c.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      AnymeXText(
                        'Common $typeLabel in both user profiles',
                        size: 11,
                        color: c.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (mediaList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.surfaceContainerHighest.opaque(0.4),
                      ),
                      child: Icon(
                        isTag ? Icons.tag : Iconsax.category,
                        size: 28,
                        color: c.onSurfaceVariant.opaque(0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnymeXText(
                      'No Mutual $typeLabel in $title',
                      size: 14,
                      variant: TextVariant.bold,
                      color: c.onSurface,
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AnymeXText(
                        'Both users enjoy this ${isTag ? "tag" : "genre"}, but haven\'t completed any of the same titles yet.',
                        size: 11.5,
                        textAlign: TextAlign.center,
                        color: c.onSurfaceVariant.opaque(0.7),
                      ),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.58,
                ),
                child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 0.58,
                ),
                itemCount: mediaList.length,
                itemBuilder: (context, index) {
                  final item = mediaList[index];
                  final id = item.id ?? '';
                  final mTitle = item.title ?? 'Media';
                  final cover = item.cover ?? '';
                  final tag = 'compat_modal_${isManga ? 'manga' : 'anime'}_${id}_$mTitle';

                  final media = Media(
                    id: id,
                    title: mTitle,
                    cover: cover,
                    poster: cover,
                    description: '',
                    serviceType: ServicesType.anilist,
                  );

                  return GestureDetector(
                    onSecondaryTap: () {
                      MediaPeekPopup.showIfUntracked(
                        context,
                        media,
                        isManga ? ItemType.manga : ItemType.anime,
                        tag,
                      );
                    },
                    onLongPress: () {
                      MediaPeekPopup.showIfUntracked(
                        context,
                        media,
                        isManga ? ItemType.manga : ItemType.anime,
                        tag,
                      );
                    },
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (id.isNotEmpty) {
                        Navigator.of(context).pop();
                        if (isManga) {
                          navigateWithAnimation(() => MangaDetailsPage(media: media, tag: tag));
                        } else {
                          navigateWithAnimation(() => AnimeDetailsPage(media: media, tag: tag));
                        }
                      }
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: (cover.isNotEmpty)
                                  ? AnymeXImage(
                                      imageUrl: cover,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : Container(
                                      color: c.surfaceContainerHigh,
                                      child: const Icon(Icons.movie_outlined, size: 28),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 28,
                            child: AnymeXText(
                              mTitle,
                              size: 11,
                              variant: TextVariant.semiBold,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              color: c.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            AnymeXButton(
              onTap: () {
                Navigator.of(context).pop();
                navigate(() => SearchPage(
                  searchTerm: '',
                  isManga: isManga,
                  initialFilters: {
                    isTag ? 'tags' : 'genres': [title],
                  },
                ));
              },
              variant: ButtonVariant.simple,
              backgroundColor: c.primary.opaque(0.18),
              borderRadius: BorderRadius.circular(16),
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.discover, size: 18, color: c.primary),
                  const SizedBox(width: 8),
                  AnymeXText(
                    'Explore all $title on AniList',
                    size: 13,
                    variant: TextVariant.bold,
                    color: c.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_outward_rounded, size: 15, color: c.onSurfaceVariant),
                ],
              ),
            ),
          ],
        ),
      ),
      context,
    );
  }


  Widget _buildFavouritesMediaCard(
    BuildContext context,
    HeuristicDetail detail, {
    required bool isManga,
    bool isLargeScreen = false,
  }) {
    return _buildHeuristicCardContainer(
      context,
      icon: Iconsax.heart5,
      title: isManga ? 'Common Favourite Manga' : 'Common Favourite Anime',
      subtitle: isManga ? 'Based on your favourite manga.' : 'Based on your favourite anime.',
      detail: detail,
      padding: const EdgeInsets.all(18),
      child: _buildHorizontalMediaPosterList(context, detail.mediaItems, isManga: isManga),
    );
  }

  Widget _buildPerfectMediaCard(
    BuildContext context,
    HeuristicDetail detail, {
    required bool isManga,
    bool isLargeScreen = false,
  }) {
    return _buildHeuristicCardContainer(
      context,
      icon: Iconsax.star5,
      title: isManga ? 'Common Perfect Manga' : 'Common Perfect Anime',
      subtitle: isManga ? 'Based on manga scored 10/10.' : 'Based on anime scored 10/10.',
      detail: detail,
      padding: const EdgeInsets.all(18),
      child: _buildHorizontalMediaPosterList(context, detail.mediaItems, isManga: isManga, isPerfect: true),
    );
  }

  Widget _buildHorizontalMediaPosterList(
    BuildContext context,
    List<FavouriteMedia> items, {
    required bool isManga,
    bool isPerfect = false,
  }) {
    if (items.isEmpty) {
      return Center(child: _buildEmptyPlaceholder(context, 'Nothing in Common!'));
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: items
              .map((item) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildMediaPosterItem(context, item, isManga: isManga, isPerfect: isPerfect),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMediaPosterItem(
    BuildContext context,
    FavouriteMedia item, {
    required bool isManga,
    bool isPerfect = false,
  }) {
    final c = context.colors;
    final id = item.id ?? '';
    final title = item.title ?? 'Media';
    final cover = item.cover ?? '';
    final tag = 'compat_${isManga ? 'manga' : 'anime'}_${id}_$title';

    final media = Media(
      id: id,
      title: title,
      cover: cover,
      poster: cover,
      description: '',
      serviceType: ServicesType.anilist,
    );

    return Container(
      width: 104,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: GestureDetector(
        onSecondaryTap: () {
          MediaPeekPopup.showIfUntracked(
            context,
            media,
            isManga ? ItemType.manga : ItemType.anime,
            tag,
          );
        },
        onLongPress: () {
          MediaPeekPopup.showIfUntracked(
            context,
            media,
            isManga ? ItemType.manga : ItemType.anime,
            tag,
          );
        },
        onTap: () {
          HapticFeedback.lightImpact();
          if (id.isNotEmpty) {
            if (isManga) {
              navigateWithAnimation(() => MangaDetailsPage(media: media, tag: tag));
            } else {
              navigateWithAnimation(() => AnimeDetailsPage(media: media, tag: tag));
            }
          }
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: tag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (cover.isNotEmpty)
                      ? AnymeXImage(
                          imageUrl: cover,
                          width: 104,
                          height: 144,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 104,
                          height: 144,
                          color: c.surfaceContainerHigh,
                        ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 18,
                width: 104,
                child: MarqueeText(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: c.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 

  Widget _buildCharactersCard(BuildContext context, HeuristicDetail? detail, {bool isLargeScreen = false}) {
    return _buildHeuristicCardContainer(
      context,
      icon: Iconsax.profile_2user,
      title: 'Common Characters',
      subtitle: 'Based on your favourite characters.',
      percentage: detail?.percentage ?? 0.0,
      weight: detail?.weight ?? 0.8,
      detail: detail,
      padding: const EdgeInsets.all(18),
      child: _buildHorizontalPersonList(
        context,
        detail?.characterItems ?? [],
        getId: (c) => c.id,
        getName: (c) => c.name,
        getImage: (c) => c.image,
        isCharacter: true,
      ),
    );
  }


  Widget _buildVoiceActorsCard(BuildContext context, HeuristicDetail? detail, {bool isLargeScreen = false}) {
    final c = context.colors;
    final cards = detail?.cards ?? [];

    Widget body;
    if (cards.isEmpty) {
      body = Center(child: _buildEmptyPlaceholder(context, 'Nothing in Common!'));
    } else {
      body = Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: cards.map((card) {
              final tag = 'compat_va_${card.mediaId ?? card.title}';
              final meanScoreRow = card.rows.where((r) => r.label.toLowerCase().contains('mean')).firstOrNull;

              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (card.mediaId != null && card.mediaId!.isNotEmpty) {
                      showCharacterStaffSheet(
                        context,
                        item: PersonItem(id: card.mediaId, name: card.title, image: card.imageUrl),
                        isCharacter: false,
                        heroTag: tag,
                      );
                    }
                  },
                  child: MouseRegion(
                    cursor: (card.mediaId != null && card.mediaId!.isNotEmpty)
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Hero(
                          tag: tag,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: c.primary, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: c.primary.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: (card.imageUrl != null && card.imageUrl!.isNotEmpty)
                                   ? AnymeXImage(
                                      imageUrl: card.imageUrl!,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 70,
                                      height: 70,
                                      color: c.surfaceContainerHigh,
                                      child: Icon(Icons.person, color: c.onSurfaceVariant),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 80,
                          height: 18,
                          child: MarqueeText(
                            card.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: c.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (meanScoreRow != null)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.surfaceContainerHigh.opaque(0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnymeXText(meanScoreRow.user1Value, size: 10, variant: TextVariant.bold, color: c.primary),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: AnymeXText('vs', size: 8, color: c.onSurfaceVariant.opaque(0.6), variant: TextVariant.bold),
                                ),
                                AnymeXText(meanScoreRow.user2Value, size: 10, variant: TextVariant.bold, color: c.secondary),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    return _buildHeuristicCardContainer(
      context,
      icon: Icons.mic_rounded,
      title: 'Common Voice Actors',
      subtitle: 'Based on your top 6 voice actors.',
      percentage: detail?.percentage ?? 0.0,
      weight: detail?.weight ?? 0.5,
      detail: detail,
      padding: const EdgeInsets.all(18),
      child: body,
    );
  }

 

  Widget _buildStudiosCard(BuildContext context, HeuristicDetail? detail, {bool isLargeScreen = false}) {
    final c = context.colors;
    final cards = detail?.cards ?? [];

    Widget body;
    if (cards.isEmpty) {
      body = Center(child: _buildEmptyPlaceholder(context, 'Nothing in Common!'));
    } else {
      body = Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cards.map((card) {
            final studioId = int.tryParse(card.mediaId ?? '') ?? 0;
            final meanScoreRow = card.rows.where((r) => r.label.toLowerCase().contains('mean')).firstOrNull;

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (studioId > 0) {
                  showStudioDetailsSheet(context, studioId, card.title);
                }
              },
              child: MouseRegion(
                cursor: studioId > 0 ? SystemMouseCursors.click : SystemMouseCursors.basic,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.surfaceContainerHigh.opaque(0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: c.outlineVariant.opaque(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: MarqueeText(
                          card.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.onSurface,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      if (meanScoreRow != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.surfaceContainerHighest.opaque(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnymeXText(
                                meanScoreRow.user1Value,
                                size: 9.5,
                                variant: TextVariant.bold,
                                color: c.primary,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: AnymeXText(
                                  'vs',
                                  size: 8,
                                  variant: TextVariant.bold,
                                  color: c.onSurfaceVariant.opaque(0.6),
                                ),
                              ),
                              AnymeXText(
                                meanScoreRow.user2Value,
                                size: 9.5,
                                variant: TextVariant.bold,
                                color: c.secondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (studioId > 0) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_outward_rounded, size: 11, color: c.primary.opaque(0.7)),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    return _buildHeuristicCardContainer(
      context,
      icon: Icons.business_outlined,
      title: 'Common Studios',
      subtitle: 'Based on your top 3 studios.',
      percentage: detail?.percentage ?? 0.0,
      weight: detail?.weight ?? 0.9,
      detail: detail,
      padding: const EdgeInsets.all(18),
      child: body,
    );
  }

 

  Widget _buildStaffCard(BuildContext context, HeuristicDetail? detail, {bool isLargeScreen = false}) {
    return _buildHeuristicCardContainer(
      context,
      icon: Iconsax.user_tag,
      title: 'Common Favourite Staff',
      subtitle: 'Based on your favourite staff.',
      percentage: detail?.percentage ?? 0.0,
      weight: detail?.weight ?? 0.5,
      detail: detail,
      padding: const EdgeInsets.all(18),
      child: _buildHorizontalPersonList(
        context,
        detail?.staffItems ?? [],
        getId: (s) => s.id,
        getName: (s) => s.name,
        getImage: (s) => s.image,
        isCharacter: false,
      ),
    );
  }

  Widget _buildHorizontalPersonList<T>(
    BuildContext context,
    List<T> items, {
    required String? Function(T) getId,
    required String? Function(T) getName,
    required String? Function(T) getImage,
    required bool isCharacter,
  }) {
    if (items.isEmpty) {
      return Center(child: _buildEmptyPlaceholder(context, 'Nothing in Common!'));
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(right: 14),
              child: _buildPersonCircleItem(
                context,
                id: getId(item),
                name: getName(item),
                imageUrl: getImage(item),
                isCharacter: isCharacter,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  
  Widget _buildPersonCircleItem(
    BuildContext context, {
    required String? id,
    required String? name,
    required String? imageUrl,
    required bool isCharacter,
  }) {
    final c = context.colors;
    final tag = 'compat_${isCharacter ? "char" : "staff"}_${id ?? name}';

    return Container(
      width: 78,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (id != null && id.isNotEmpty) {
            showCharacterStaffSheet(
              context,
              item: PersonItem(id: id, name: name, image: imageUrl),
              isCharacter: isCharacter,
              heroTag: tag,
            );
          }
        },
        child: MouseRegion(
          cursor: (id != null && id.isNotEmpty) ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: tag,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.primary.opaque(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withOpacity(0.12),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? AnymeXImage(
                            imageUrl: imageUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 70,
                            height: 70,
                            color: c.surfaceContainerHigh,
                            alignment: Alignment.center,
                            child: const Icon(Icons.person, size: 28),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 18,
                width: 78,
                child: MarqueeText(
                  name ?? '',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: c.onSurface,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 

  Widget _buildHeuristicCardContainer(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    double percentage = 0.0,
    double weight = 1.0,
    HeuristicDetail? detail,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) {
    final c = context.colors;
    return AnymeXContainer(
      padding: padding,
      radius: 20,
      enableGlow: true,
      color: c.surfaceContainerHighest.opaque(0.38),
      border: Border.all(
        color: c.outline.opaque(0.12),
        width: 1.2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(
            context,
            icon: icon,
            title: title,
            subtitle: subtitle,
            percentage: detail?.percentage ?? percentage,
            weight: detail?.weight ?? weight,
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCardHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required double percentage,
    required double weight,
    bool compact = false,
  }) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c.primary.opaque(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: compact ? 16 : 18, color: c.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarqueeText(
                title,
                style: TextStyle(
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.bold,
                  color: c.onSurface,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              AnymeXText(
                subtitle,
                size: 11,
                color: c.onSurfaceVariant.opaque(0.75),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.primary.opaque(0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnymeXText(
            '${percentage.toStringAsFixed(0)}%',
            size: 11,
            variant: TextVariant.bold,
            color: c.primary,
          ),
        ),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: c.surfaceContainerHigh.opaque(0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnymeXText(
            'x${weight.toStringAsFixed(1)}',
            size: 10,
            variant: TextVariant.semiBold,
            color: c.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context, String text) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.slash, size: 16, color: c.onSurfaceVariant.opaque(0.5)),
          const SizedBox(width: 6),
          AnymeXText(
            text,
            size: 12,
            color: c.onSurfaceVariant.opaque(0.65),
            variant: TextVariant.semiBold,
          ),
        ],
      ),
    );
  }

  

  Widget _buildSocialConnectionsCard(
    BuildContext context,
    Profile user1,
    Profile user2,
    MutualSocialData social,
  ) {
    final c = context.colors;
    final name1 = user1.name ?? 'User 1';
    final name2 = user2.name ?? 'User 2';

    String relationshipText;
    IconData relIcon;

    if (social.isMutualFriends) {
      relationshipText = 'Mutual Friends (Both follow each other on AniList)';
      relIcon = Iconsax.heart5;
    } else if (social.user1FollowsUser2 && !social.user2FollowsUser1) {
      relationshipText = '$name1 follows $name2';
      relIcon = Iconsax.user_tick;
    } else if (!social.user1FollowsUser2 && social.user2FollowsUser1) {
      relationshipText = '$name2 follows $name1';
      relIcon = Iconsax.user_tag;
    } else {
      relationshipText = 'Shared Community Network';
      relIcon = Iconsax.people;
    }

    return AnymeXContainer(
      padding: const EdgeInsets.all(18),
      radius: 20,
      enableGlow: true,
      color: c.surfaceContainerHighest.opaque(0.38),
      border: Border.all(
        color: c.outline.opaque(0.12),
        width: 1.2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.primary.opaque(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Iconsax.profile_2user, size: 18, color: c.primary),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: AnymeXText(
                  'Mutual Connections',
                  variant: TextVariant.bold,
                  size: 15,
                ),
              ),
              if (social.isMutualFriends)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.primary.opaque(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AnymeXText(
                    'Mutual Friends',
                    size: 11,
                    variant: TextVariant.bold,
                    color: c.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
         
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.surfaceContainerHigh.opaque(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(relIcon, size: 16, color: c.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: AnymeXText(
                    relationshipText,
                    size: 12,
                    variant: TextVariant.semiBold,
                  ),
                ),
              ],
            ),
          ),
         
          if (social.mutualFollowing.isNotEmpty) ...[
            const SizedBox(height: 14),
            AnymeXText(
              'Shared Following (${social.mutualFollowing.length})',
              size: 12,
              variant: TextVariant.semiBold,
              color: c.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: social.mutualFollowing
                  .map((user) => _buildSocialUserChip(context, user))
                  .toList(),
            ),
          ],

          if (social.mutualFollowers.isNotEmpty) ...[
            const SizedBox(height: 14),
            AnymeXText(
              'Mutual Followers (${social.mutualFollowers.length})',
              size: 12,
              variant: TextVariant.semiBold,
              color: c.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: social.mutualFollowers
                  .map((user) => _buildSocialUserChip(context, user))
                  .toList(),
            ),
          ],
          
          if (social.mutualFollowing.isEmpty && social.mutualFollowers.isEmpty) ...[
            const SizedBox(height: 10),
            _buildEmptyPlaceholder(context, 'No mutual connections found on AniList'),
          ],
        ],
      ),
    );
  }

  Widget _buildSocialUserChip(BuildContext context, SocialUser user) {
    final c = context.colors;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        navigate(() => UserProfilePage(userId: user.id));
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: c.surface.opaque(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: c.outline.opaque(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                    ? AnymeXImage(
                        imageUrl: user.avatarUrl!,
                        width: 22,
                        height: 22,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 22,
                        height: 22,
                        color: c.surfaceContainerHigh,
                        alignment: Alignment.center,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: MarqueeText(
                  user.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.onSurface,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHowItWorksCard(BuildContext context) {
    final c = context.colors;
    return AnymeXContainer(
      radius: 20,
      enableGlow: true,
      color: c.surfaceContainerHighest.opaque(0.38),
      border: Border.all(
        color: c.outline.opaque(0.12),
        width: 1.2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _isHowItWorksExpanded = !_isHowItWorksExpanded),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.primary.opaque(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: c.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymeXText(
                          'How it works & Compatibility Ranks',
                          variant: TextVariant.bold,
                          size: 14,
                          color: c.onSurface,
                        ),
                        const SizedBox(height: 2),
                        AnymeXText(
                          _isHowItWorksExpanded
                              ? 'Tap to collapse scoring details and rank guide'
                              : 'Learn how compatibility is calculated.',
                          size: 11,
                          color: c.onSurfaceVariant.opaque(0.75),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isHowItWorksExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: c.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

         
          AnimatedCrossFade(
            crossFadeState: _isHowItWorksExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymeXText(
                    'Compatibility is calculated by comparing signals from both users\' AniList profiles across 16 heuristics in Anime and Manga.\n'
                    'Set overlaps use cube-root exponential scaling (1/3), decade proportions are adjusted for personal baseline mean score deviation, and weights are dynamically distributed.',
                    size: 12,
                    color: c.onSurfaceVariant.opaque(0.85),
                  ),
                  const SizedBox(height: 6),
                  AnymeXText(
                    'Powered by AniMatch 16-point compatibility analysis in AnymeX',
                    size: 11,
                    color: c.onSurfaceVariant.opaque(0.6),
                  ),
                  const SizedBox(height: 18),

                  AnymeXText(
                    'Compatibility Ranks',
                    variant: TextVariant.bold,
                    size: 14,
                    color: c.onSurface,
                  ),
                  const SizedBox(height: 2),
                  AnymeXText(
                    'Every score is mapped to a rank. The table below shows each bracket, its badge, and what the range represents.',
                    size: 11,
                    color: c.onSurfaceVariant.opaque(0.75),
                  ),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52,
                          child: AnymeXText(
                            'Badge',
                            size: 11,
                            variant: TextVariant.semiBold,
                            color: c.onSurfaceVariant.opaque(0.7),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: AnymeXText(
                            'Rank',
                            size: 11,
                            variant: TextVariant.semiBold,
                            color: c.onSurfaceVariant.opaque(0.7),
                          ),
                        ),
                        SizedBox(
                          width: 68,
                          child: AnymeXText(
                            'Range',
                            size: 11,
                            variant: TextVariant.semiBold,
                            color: c.onSurfaceVariant.opaque(0.7),
                          ),
                        ),
                        Expanded(
                          child: AnymeXText(
                            'Description',
                            size: 11,
                            variant: TextVariant.semiBold,
                            color: c.onSurfaceVariant.opaque(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  ...kRanks.reversed.map((r) {
                    final rankColor = _getRankColor(r);
                    final rangeStr = '${r.min.toInt()}-${r.max > 100 ? 100 : r.max.toInt()}%';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: c.surfaceContainerHigh.opaque(0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: c.outline.opaque(0.08),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 52,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: rankColor.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: rankColor.withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: AnymeXText(
                                  r.name,
                                  size: 11,
                                  variant: TextVariant.bold,
                                  color: rankColor,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            child: AnymeXText(
                              r.name,
                              size: 12,
                              variant: TextVariant.bold,
                              color: c.onSurface,
                            ),
                          ),
                          SizedBox(
                            width: 68,
                            child: AnymeXText(
                              rangeStr,
                              size: 11.5,
                              color: c.onSurfaceVariant,
                              variant: TextVariant.semiBold,
                            ),
                          ),
                          Expanded(
                            child: AnymeXText(
                              r.description,
                              size: 11.5,
                              color: c.onSurfaceVariant.opaque(0.9),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

 

  String _buildShareUrl(String name1, String name2) {
    String serverUrl = (dotenv.env['WATCHIUM_SERVER_URL'] ?? '').trim();
    if (serverUrl.isEmpty) {
      serverUrl = WatchiumKeys.serverUrl.get<String>('').trim();
    }
    if (serverUrl.isEmpty) {
      try {
        final envFile = File('.env');
        if (envFile.existsSync()) {
          final lines = envFile.readAsLinesSync();
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.startsWith('WATCHIUM_SERVER_URL=')) {
              serverUrl = trimmed.substring('WATCHIUM_SERVER_URL='.length).trim();
              break;
            }
          }
        }
      } catch (_) {}
    }
    serverUrl = serverUrl.replaceAll(RegExp(r'/+$'), '');
    if (serverUrl.isNotEmpty) {
      return '$serverUrl/animatch/${Uri.encodeComponent(name1)}/${Uri.encodeComponent(name2)}';
    }
    return 'anymex://animatch?user1=${Uri.encodeComponent(name1)}&user2=${Uri.encodeComponent(name2)}';
  }

  Future<void> _shareCard(String name1, String name2, CompatibilityResult result) async {
    final shareUrl = _buildShareUrl(name1, name2);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await Clipboard.setData(ClipboardData(text: shareUrl));
      snackBar('AniMatch link copied to clipboard!');
      return;
    }

    if (_isSharing) return;

    setState(() => _isSharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _shareTextFallback(name1, name2, result);
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _shareTextFallback(name1, name2, result);
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final fileName = 'animatch_${name1}_${name2}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      final text = '$name1 \u2764 $name2 | Compatibility: ${result.percentage.toStringAsFixed(0)}% (Rank ${result.rank})\nCheck Compatibility: $shareUrl\nCalculated with AnymeX';

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: fileName)],
        text: text,
      );
    } catch (e) {
      Logger.e('Could not share image, sharing text instead.', error: e);
      _shareTextFallback(name1, name2, result);
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _shareTextFallback(String name1, String name2, CompatibilityResult result) {
    final shareUrl = _buildShareUrl(name1, name2);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      Clipboard.setData(ClipboardData(text: shareUrl));
      snackBar('AniMatch link copied to clipboard!');
      return;
    }

    final anime = result.animeSection.hasData
        ? 'Anime: ${result.animeSection.percentage.toStringAsFixed(1)}%'
        : 'Anime: N/A';
    final manga = result.mangaSection.hasData
        ? 'Manga: ${result.mangaSection.percentage.toStringAsFixed(1)}%'
        : 'Manga: N/A';

    final text =
        '$name1 \u2764 $name2\n\n'
        'AniMatch Compatibility: ${result.percentage.toStringAsFixed(0)}% (Rank ${result.rank})\n'
        '$anime\n'
        '$manga\n\n'
        '${result.rankDescription}\n\n'
        'Check on AnymeX: $shareUrl';
    Share.share(text);
  }
}


class _BikeMeterSweepGauge extends StatefulWidget {
  final double targetPercentage;
  final double size;
  final double strokeWidth;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;

  const _BikeMeterSweepGauge({
    required this.targetPercentage,
    this.size = 52.0,
    this.strokeWidth = 3.5,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
  });

  @override
  State<_BikeMeterSweepGauge> createState() => _BikeMeterSweepGaugeState();
}

class _BikeMeterSweepGaugeState extends State<_BikeMeterSweepGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _BikeMeterSweepGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetPercentage != widget.targetPercentage) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final targetFrac = (widget.targetPercentage / 100.0).clamp(0.0, 1.0);

        double currentVal;
        if (t <= 0.40) {
          final p = Curves.easeOutCubic.transform(t / 0.40);
          currentVal = p;
        } else if (t <= 0.48) {
          currentVal = 1.0;
        } else {
          final p = Curves.easeInOutCubic.transform((t - 0.48) / 0.52);
          currentVal = ui.lerpDouble(1.0, targetFrac, p) ?? targetFrac;
        }

        final displayPct = (currentVal * 100.0).round();

        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                value: currentVal.clamp(0.0, 1.0),
                strokeWidth: widget.strokeWidth,
                backgroundColor: widget.backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.targetPercentage > 30
                      ? widget.primaryColor
                      : widget.secondaryColor,
                ),
              ),
            ),
            AnymeXText(
              '$displayPct%',
              size: 11,
              variant: TextVariant.bold,
            ),
          ],
        );
      },
    );
  }
}

