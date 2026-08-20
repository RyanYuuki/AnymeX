import 'package:anymex/controllers/services/anilist/compatibility_controller.dart';
import 'package:anymex/utils/compatibility/compatibility_models.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';

class CompatibilityResultPage extends StatelessWidget {
  final CompatibilityController controller;

  const CompatibilityResultPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final result = controller.result.value;
    final user1 = controller.user1.value;
    final user2 = controller.user2.value;

    if (result == null || user1 == null || user2 == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compatibility')),
        body: const Center(child: Text('No result')),
      );
    }

    final rank = getRankForScore(result.percentage);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compatibility Result',
          style: TextStyle(fontFamily: 'Poppins-SemiBold'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareResult(user1.name ?? '', user2.name ?? '', result),
            tooltip: 'Share',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            _buildHeader(context, user1, user2, result, rank),
            const SizedBox(height: 24),
            _buildBreakdownSection(context, result),
            const SizedBox(height: 20),
            _buildSharedItemsSection(context, result, user1, user2),
            const SizedBox(height: 24),
            _buildHowItWorksCard(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    dynamic user1,
    dynamic user2,
    CompatibilityResult result,
    RankInfo rank,
  ) {
    final name1 = user1.name ?? 'User 1';
    final name2 = user2.name ?? 'User 2';
    final avatar1 = user1.avatar ?? '';
    final avatar2 = user2.avatar ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.theme.colorScheme.primaryContainer.withOpacity(0.3),
            context.theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // User avatars and names
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User 1
              _buildUserChip(context, name1, avatar1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Iconsax.heart4,
                  color: _parseColor(rank.colorHex),
                  size: 28,
                ),
              ),
              // User 2
              _buildUserChip(context, name2, avatar2),
            ],
          ),
          const SizedBox(height: 20),

          // Big percentage
          Text(
            '${result.percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              fontFamily: 'Poppins-Bold',
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [
                    _parseColor(rank.colorHex),
                    _parseColor(rank.colorHex).withOpacity(0.6),
                  ],
                ).createShader(const Rect.fromLTWH(0, 0, 200, 60)),
            ),
          ),
          const SizedBox(height: 8),

          // Rank badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: _parseColor(rank.colorHex).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _parseColor(rank.colorHex).withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rank ${rank.name}',
                  style: TextStyle(
                    fontFamily: 'Poppins-Bold',
                    fontSize: 16,
                    color: _parseColor(rank.colorHex),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rank.description,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: context.theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserChip(BuildContext context, String name, String avatar) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
          backgroundColor: context.theme.colorScheme.surfaceContainerHigh,
          child: avatar.isEmpty
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontFamily: 'Poppins-Bold',
                    fontSize: 20,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: 'Poppins-SemiBold',
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownSection(
    BuildContext context,
    CompatibilityResult result,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Score Breakdown',
          style: TextStyle(
            fontFamily: 'Poppins-Bold',
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        ...result.breakdown.map(
          (h) => _buildHeuristicRow(context, h),
        ),
      ],
    );
  }

  Widget _buildHeuristicRow(BuildContext context, HeuristicScore h) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.label,
                      style: const TextStyle(
                        fontFamily: 'Poppins-SemiBold',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      h.description,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: context.theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(h.score * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: 'Poppins-Bold',
                  fontSize: 15,
                  color: _scoreColor(h.score),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: h.score.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: context.theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                _scoreColor(h.score),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Weight: \u00d7${h.weight.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: context.theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedItemsSection(
    BuildContext context,
    CompatibilityResult result,
    dynamic user1,
    dynamic user2,
  ) {
    final hasSharedItems = result.commonGenres.isNotEmpty ||
        result.commonTags.isNotEmpty ||
        result.commonFavouriteAnimeIds.isNotEmpty ||
        result.commonStudios.isNotEmpty ||
        result.commonVoiceActors.isNotEmpty;

    if (!hasSharedItems) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shared Interests',
          style: TextStyle(
            fontFamily: 'Poppins-Bold',
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),

        // Shared favourite anime (with covers)
        if (result.commonFavouriteAnimeIds.isNotEmpty)
          _buildSharedFavAnimeSection(context, user1, result),

        // Shared genres
        if (result.commonGenres.isNotEmpty)
          _buildChipList(
            context,
            title: 'Shared Genres',
            items: result.commonGenres,
            icon: Icons.category,
          ),

        // Shared tags
        if (result.commonTags.isNotEmpty)
          _buildChipList(
            context,
            title: 'Shared Tags',
            items: result.commonTags.map((t) => _capitalizeFirst(t)).toList(),
            icon: Icons.label_outline,
            maxItems: 10,
          ),

        // Shared studios
        if (result.commonStudios.isNotEmpty)
          _buildChipList(
            context,
            title: 'Shared Studios',
            items: result.commonStudios,
            icon: Icons.business,
          ),

        // Shared VAs
        if (result.commonVoiceActors.isNotEmpty)
          _buildChipList(
            context,
            title: 'Shared Voice Actors',
            items: result.commonVoiceActors,
            icon: Icons.mic,
          ),
      ],
    );
  }

  Widget _buildSharedFavAnimeSection(
    BuildContext context,
    dynamic user1,
    CompatibilityResult result,
  ) {
    final favAnime = user1.favourites?.anime ?? [];
    final shared = favAnime
        .where((a) => result.commonFavouriteAnimeIds
            .contains(int.tryParse(a.id ?? '')))
        .toList();

    if (shared.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shared Favourite Anime',
          style: TextStyle(
            fontFamily: 'Poppins-SemiBold',
            fontSize: 14,
            color: context.theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shared.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final anime = shared[index];
              return SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AnymeXImage(
                        imageUrl: anime.cover ?? '',
                        width: 100,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      anime.title ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildChipList(
    BuildContext context, {
    required String title,
    required List<String> items,
    required IconData icon,
    int maxItems = 20,
  }) {
    final displayItems = items.take(maxItems).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins-SemiBold',
              fontSize: 14,
              color: context.theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: displayItems.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: context.theme.colorScheme.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: context.theme.colorScheme.primary),
                    const SizedBox(width: 5),
                    Text(
                      item,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: context.theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: context.theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'How it works',
                style: TextStyle(
                  fontFamily: 'Poppins-SemiBold',
                  fontSize: 14,
                  color: context.theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Compatibility is calculated by comparing 9 different signals from both users\' AniList profiles: watch stats, release year preferences, genre/tag overlap, favourite anime, characters, voice actors, and studios. Each signal is weighted differently. Favourite anime has the highest weight because they reflect deliberate picks.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: context.theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Algorithm inspired by animatch.raiku.dev',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: context.theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 0.85) return Colors.amber;
    if (score >= 0.65) return Colors.purpleAccent;
    if (score >= 0.55) return Colors.blueAccent;
    if (score >= 0.40) return Colors.green;
    if (score >= 0.20) return Colors.orange;
    return Colors.redAccent;
  }

  Color _parseColor(String hex) {
    final hexStr = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexStr', radix: 16));
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  void _shareResult(String name1, String name2, CompatibilityResult result) {
    final text =
        '$name1 \u2764 $name2\n\n'
        'Anime Compatibility: ${result.percentage.toStringAsFixed(1)}% (${result.rank})\n'
        '${result.rankDescription}\n\n'
        'Calculated with AnymeX';
    Share.share(text);
  }
}


