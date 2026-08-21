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
    final animeRank = getRankForScore(result.animeSection.percentage);
    final mangaRank = getRankForScore(result.mangaSection.percentage);

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
            // Overall header with user avatars
            _buildOverallHeader(context, user1, user2, result, rank),
            const SizedBox(height: 20),

            // Anime & Manga section cards side by side
            _buildSectionCards(context, result, animeRank, mangaRank),
            const SizedBox(height: 24),

            // Anime breakdown
            if (result.animeSection.hasData) ...[
              _buildSectionBreakdown(
                context,
                title: '📺 Anime Breakdown',
                breakdown: result.animeSection.breakdown,
              ),
              const SizedBox(height: 20),
            ],

            // Manga breakdown
            if (result.mangaSection.hasData) ...[
              _buildSectionBreakdown(
                context,
                title: '📖 Manga & Novels Breakdown',
                breakdown: result.mangaSection.breakdown,
              ),
              const SizedBox(height: 20),
            ],

            // Shared interests
            _buildSharedItemsSection(context, result, user1, user2),
            const SizedBox(height: 24),

            // How it works
            _buildHowItWorksCard(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OVERALL HEADER
  // ============================================================

  Widget _buildOverallHeader(
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
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
          // User avatars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUserChip(context, name1, avatar1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Iconsax.heart4,
                  color: _parseColor(rank.colorHex),
                  size: 28,
                ),
              ),
              _buildUserChip(context, name2, avatar2),
            ],
          ),
          const SizedBox(height: 16),

          // "Overall" label
          Text(
            'Overall Compatibility',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: context.theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),

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
          const SizedBox(height: 6),

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
            child: Text(
              'Rank ${rank.name}',
              style: TextStyle(
                fontFamily: 'Poppins-Bold',
                fontSize: 16,
                color: _parseColor(rank.colorHex),
              ),
            ),
          ),
          const SizedBox(height: 6),
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

  // ============================================================
  // SECTION CARDS (Anime / Manga side by side)
  // ============================================================

  Widget _buildSectionCards(
    BuildContext context,
    CompatibilityResult result,
    RankInfo animeRank,
    RankInfo mangaRank,
  ) {
    return Row(
      children: [
        // Anime card
        Expanded(
          child: _buildSectionCard(
            context,
            icon: '📺',
            label: 'Anime',
            section: result.animeSection,
            rank: animeRank,
            formatSplit: null,
          ),
        ),
        const SizedBox(width: 12),
        // Manga card
        Expanded(
          child: _buildSectionCard(
            context,
            icon: '📖',
            label: 'Manga & LN',
            section: result.mangaSection,
            rank: mangaRank,
            formatSplit1: result.user1FormatSplit,
            formatSplit2: result.user2FormatSplit,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String icon,
    required String label,
    required CompatibilitySection section,
    required RankInfo rank,
    MangaFormatSplit? formatSplit,
    MangaFormatSplit? formatSplit1,
    MangaFormatSplit? formatSplit2,
  }) {
    final hasData = section.hasData;
    final color = hasData ? _parseColor(rank.colorHex) : context.theme.colorScheme.onSurfaceVariant.withOpacity(0.5);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: hasData
            ? Border.all(color: color.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Column(
        children: [
          Text(
            icon,
            fontSize: 24,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins-SemiBold',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          if (!hasData)
            Text(
              'No data',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: context.theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            )
          else ...[
            Text(
              '${section.percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins-Bold',
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${rank.name} Rank',
                style: TextStyle(
                  fontFamily: 'Poppins-Bold',
                  fontSize: 12,
                  color: color,
                ),
              ),
            ),
            // Format split for manga
            if (formatSplit1 != null || formatSplit2 != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatSplitText(formatSplit1, formatSplit2),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: context.theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatSplitText(MangaFormatSplit? s1, MangaFormatSplit? s2) {
    final parts = <String>[];
    if (s1 != null && s1.displayLabel != 'No data') {
      parts.add('User1: ${s1.displayLabel}');
    }
    if (s2 != null && s2.displayLabel != 'No data') {
      parts.add('User2: ${s2.displayLabel}');
    }
    return parts.join('\n');
  }

  // ============================================================
  // SECTION BREAKDOWN (heuristic bars)
  // ============================================================

  Widget _buildSectionBreakdown(
    BuildContext context, {
    required String title,
    required List<HeuristicScore> breakdown,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins-Bold',
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        ...breakdown.map((h) => _buildHeuristicRow(context, h)),
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

  // ============================================================
  // SHARED ITEMS
  // ============================================================

  Widget _buildSharedItemsSection(
    BuildContext context,
    CompatibilityResult result,
    dynamic user1,
    dynamic user2,
  ) {
    final hasSharedItems = result.commonGenres.isNotEmpty ||
        result.commonTags.isNotEmpty ||
        result.commonFavouriteAnimeIds.isNotEmpty ||
        result.commonFavouriteMangaIds.isNotEmpty ||
        result.commonStudios.isNotEmpty ||
        result.commonVoiceActors.isNotEmpty ||
        result.commonStaffIds.isNotEmpty ||
        result.commonMangaGenres.isNotEmpty ||
        result.commonMangaTags.isNotEmpty;

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

        // Shared favourite anime
        if (result.commonFavouriteAnimeIds.isNotEmpty)
          _buildSharedFavAnimeSection(context, user1, result),

        // Shared favourite manga
        if (result.commonFavouriteMangaIds.isNotEmpty)
          _buildSharedFavMangaSection(context, user1, result),

        // Shared genres (anime)
        if (result.commonGenres.isNotEmpty)
          _buildChipList(
            context,
            title: 'Shared Anime Genres',
            items: result.commonGenres,
            icon: Icons.category,
          ),

        // Shared genres (manga)
        if (result.commonMangaGenres.isNotEmpty)
          _buildChipList(
            context,
            title: 'Shared Manga Genres',
            items: result.commonMangaGenres,
            icon: Icons.category_outlined,
          ),

        // Shared tags (anime)
        if (result.commonTags.isNotEmpty)
          _buildChipList(
            context,
            title: 'Shared Anime Tags',
            items: result.commonTags.map((t) => _capitalizeFirst(t)).toList(),
            icon: Icons.label_outline,
            maxItems: 10,
          ),

        // Shared tags (manga)
        if (result.commonMangaTags.isNotEmpty)
          _buildChipList(
            context,
            title: 'Shared Manga Tags',
            items: result.commonMangaTags.map((t) => _capitalizeFirst(t)).toList(),
            icon: Icons.label,
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

        // Shared staff
        if (result.commonStaffIds.isNotEmpty)
          _buildChipList(
            context,
            title: 'Shared Favourite Staff',
            items: result.commonStaffIds,
            icon: Icons.person_outline,
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

    return _buildHorizontalMediaList(
      context,
      title: 'Shared Favourite Anime',
      items: shared.map((a) => (a.title ?? '', a.cover ?? '')).toList(),
    );
  }

  Widget _buildSharedFavMangaSection(
    BuildContext context,
    dynamic user1,
    CompatibilityResult result,
  ) {
    final favManga = user1.favourites?.manga ?? [];
    final shared = favManga
        .where((m) => result.commonFavouriteMangaIds
            .contains(int.tryParse(m.id ?? '')))
        .toList();

    if (shared.isEmpty) return const SizedBox.shrink();

    return _buildHorizontalMediaList(
      context,
      title: 'Shared Favourite Manga & Novels',
      items: shared.map((m) => (m.title ?? '', m.cover ?? '')).toList(),
    );
  }

  Widget _buildHorizontalMediaList(
    BuildContext context, {
    required String title,
    required List<(String, String)> items,
  }) {
    return Column(
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
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final (title, cover) = items[index];
              return SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AnymeXImage(
                        imageUrl: cover,
                        width: 100,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
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

  // ============================================================
  // USER CHIP
  // ============================================================

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

  // ============================================================
  // HOW IT WORKS
  // ============================================================

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
            'Compatibility is calculated by comparing signals from both users\' AniList profiles across two sections:\n
\uD83D\uDCFA Anime (10 signals): watch stats, release years, genres, tags, perfect anime, favourite anime, characters, voice actors, studios, staff.\n
\uD83D\uDCD6 Manga & Novels (5 signals): read stats, release years, genres, tags, favourite manga. Novels and light novels are included under manga data.\n
Each signal is weighted differently — favourites carry the highest weight. Sections without data are excluded from the overall score.',
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

  // ============================================================
  // UTILITIES
  // ============================================================

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
    final anime = result.animeSection.hasData
        ? 'Anime: ${result.animeSection.percentage.toStringAsFixed(1)}%'
        : 'Anime: N/A';
    final manga = result.mangaSection.hasData
        ? 'Manga & LN: ${result.mangaSection.percentage.toStringAsFixed(1)}%'
        : 'Manga & LN: N/A';

    final text =
        '$name1 \u2764 $name2\n\n'
        'Overall: ${result.percentage.toStringAsFixed(1)}% (${result.rank})\n'
        '$anime\n'
        '$manga\n\n'
        '${result.rankDescription}\n\n'
        'Calculated with AnymeX';
    Share.share(text);
  }
}
