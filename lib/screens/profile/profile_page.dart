import 'dart:ui';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bannerController;
  late final Animation<Alignment> _bannerAnim;

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _bannerAnim = Tween<Alignment>(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).animate(CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final handler = Get.find<ServiceHandler>();
    final profileData = handler.profileData;

    return Glow(
      child: Scaffold(
        backgroundColor: context.theme.colorScheme.surface,
        body: Obx(() {
          final user = profileData.value;
          final bannerUrl = user.avatar ?? '';

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, bannerUrl, user.cover, user.name ?? 'Guest', _bannerAnim),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildAvatarAndName(
                          context, user.avatar ?? '', user.name ?? 'Guest'),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildHighlightCard(
                              context,
                              'Anime',
                              user.stats?.animeStats?.animeCount?.toString() ?? '0',
                              IconlyBold.video,
                              context.theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildHighlightCard(
                              context,
                              'Manga',
                              user.stats?.mangaStats?.mangaCount?.toString() ?? '0',
                              IconlyBold.document,
                              context.theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildSectionHeader(context, "Statistics", IconlyLight.chart),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: context.theme.colorScheme.outlineVariant.withOpacity(0.3),
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildStatRow(context, "Episodes Watched",
                                user.stats?.animeStats?.episodesWatched?.toString() ?? '0',
                                IconlyLight.play),
                            const Divider(height: 24, thickness: 0.5),
                            _buildStatRow(context, "Minutes Watched",
                                user.stats?.animeStats?.minutesWatched?.toString() ?? '0',
                                IconlyLight.time_circle),
                            const Divider(height: 24, thickness: 0.5),
                            _buildStatRow(context, "Chapters Read",
                                user.stats?.mangaStats?.chaptersRead?.toString() ?? '0',
                                IconlyLight.paper),
                            const Divider(height: 24, thickness: 0.5),
                            _buildStatRow(context, "Volumes Read",
                                user.stats?.mangaStats?.volumesRead?.toString() ?? '0',
                                IconlyLight.bookmark),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                              child: _buildScoreCard(context, "Anime Score",
                                  user.stats?.animeStats?.meanScore?.toString() ?? '0')),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _buildScoreCard(context, "Manga Score",
                                  user.stats?.mangaStats?.meanScore?.toString() ?? '0')),
                        ],
                      ),
                    ),

                    if (user.about != null && user.about!.trim().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildSectionHeader(context, "About", IconlyLight.profile),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: context.theme.colorScheme.outlineVariant.withOpacity(0.3),
                            ),
                          ),
                          child: _buildAboutContent(context, user.about!),
                        ),
                      ),
                    ],

                    if (user.favourites?.anime.isNotEmpty ?? false) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildSectionHeader(context, "Favourite Anime", IconlyBold.video),
                      ),
                      const SizedBox(height: 10),
                      _buildMediaFavCarousel(context, user.favourites!.anime),
                    ],

                    if (user.favourites?.manga.isNotEmpty ?? false) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildSectionHeader(context, "Favourite Manga", IconlyBold.document),
                      ),
                      const SizedBox(height: 10),
                      _buildMediaFavCarousel(context, user.favourites!.manga),
                    ],

                    if (user.favourites?.characters.isNotEmpty ?? false) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildSectionHeader(context, "Favourite Characters", IconlyBold.profile),
                      ),
                      const SizedBox(height: 10),
                      _buildPersonCarousel(
                          context,
                          user.favourites!.characters
                              .map((c) => _PersonItem(name: c.name, image: c.image))
                              .toList()),
                    ],

                    if (user.favourites?.staff.isNotEmpty ?? false) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildSectionHeader(context, "Favourite Staff", Icons.people_rounded),
                      ),
                      const SizedBox(height: 10),
                      _buildPersonCarousel(
                          context,
                          user.favourites!.staff
                              .map((s) => _PersonItem(name: s.name, image: s.image))
                              .toList()),
                    ],

                    if (user.favourites?.studios.isNotEmpty ?? false) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildSectionHeader(
                            context, "Favourite Studios", Icons.business_rounded),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.favourites!.studios
                              .map(
                                (studio) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: context.theme.colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: context.theme.colorScheme.outlineVariant.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    studio.name ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: context.theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAboutContent(BuildContext context, String about) {
    final segments = _splitSpoilers(about);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: segments.map((seg) {
        if (seg.isSpoiler) {
          return _SpoilerBlock(
            rawContent: seg.content,
            htmlStyle: _htmlStyle(context),
            imgExtension: _imgExtension(context),
            preprocessHtml: (raw) => _preprocessHtml(raw, context),
          );
        }
        return Html(
          data: _preprocessHtml(seg.content, context),
          style: _htmlStyle(context),
          extensions: [_imgExtension(context)],
        );
      }).toList(),
    );
  }

  List<_ContentSegment> _splitSpoilers(String content) {
    final result = <_ContentSegment>[];
    final spoilerPattern = RegExp(r'~!([\s\S]*?)!~');
    int lastEnd = 0;
    for (final match in spoilerPattern.allMatches(content)) {
      if (match.start > lastEnd) {
        result.add(_ContentSegment(content: content.substring(lastEnd, match.start), isSpoiler: false));
      }
      result.add(_ContentSegment(content: match.group(1) ?? '', isSpoiler: true));
      lastEnd = match.end;
    }
    if (lastEnd < content.length) {
      result.add(_ContentSegment(content: content.substring(lastEnd), isSpoiler: false));
    }
    return result;
  }

  String _preprocessHtml(String raw, BuildContext context) {
    var content = raw;

    content = content.replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
        (m) => '<a href="${m[2]}">${m[1]}</a>');

    final isHtml = RegExp(r'<[a-zA-Z][^>]*>').hasMatch(content);
    if (!isHtml) content = _mdToHtml(content);

    content = content
        .replaceAll('\u200e', '')
        .replaceAll('\u200f', '')
        .replaceAll('\u200b', '')
        .replaceAll('\u200c', '')
        .replaceAll('\u200d', '')
        .replaceAll('\u034f', '')
        .replaceAll('&lrm;', '')
        .replaceAll('&#8206;', '')
        .replaceAll('&nbsp;', '\u00a0')
        .replaceAll('&#160;', '\u00a0')
        .replaceAll('&thinsp;', '')
        .replaceAll('&emsp;', '')
        .replaceAll('&ensp;', '');
    
    content = content.replaceAllMapped(
      RegExp(
        r'(<a\b[^>]*>\s*<img\b[^>]*/?\s*>\s*</a>)'
        r'(?:\s*<a\b[^>]*>\s*<img\b[^>]*/?\s*>\s*</a>)+',
        dotAll: true,
      ),
      (m) => '<div style="display:flex;flex-direction:row;flex-wrap:wrap;'
          'gap:8px;align-items:center;justify-content:center;">'
          '${m[0]}</div>',
    );

    return content;
  }

  Map<String, Style> _htmlStyle(BuildContext context) => {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(13.5),
          lineHeight: LineHeight(1.65),
          color: context.theme.colorScheme.onSurfaceVariant,
          fontFamily: 'Poppins',
        ),
        'div': Style(
          margin: Margins.only(bottom: 8),
          textAlign: TextAlign.center,
        ),
        'p': Style(
          margin: Margins.only(bottom: 8),
          color: context.theme.colorScheme.onSurfaceVariant,
        ),
        'a': Style(
          color: context.theme.colorScheme.primary,
          textDecoration: TextDecoration.none,
          display: Display.inlineBlock,
        ),
        'strong': Style(
          fontWeight: FontWeight.w700,
          color: context.theme.colorScheme.onSurface,
        ),
        'b': Style(
          fontWeight: FontWeight.w700,
          color: context.theme.colorScheme.onSurface,
        ),
        'em': Style(
          fontStyle: FontStyle.italic,
          color: context.theme.colorScheme.onSurface,
        ),
        'i': Style(
          fontStyle: FontStyle.italic,
          color: context.theme.colorScheme.onSurface,
        ),
        'h1': Style(fontSize: FontSize(18), fontWeight: FontWeight.bold, color: context.theme.colorScheme.onSurface),
        'h2': Style(fontSize: FontSize(16), fontWeight: FontWeight.bold, color: context.theme.colorScheme.onSurface),
        'h3': Style(fontSize: FontSize(14), fontWeight: FontWeight.bold, color: context.theme.colorScheme.onSurface),
        'code': Style(
          fontFamily: 'monospace',
          fontSize: FontSize(12),
          backgroundColor: context.theme.colorScheme.surfaceContainer,
          color: context.theme.colorScheme.primary,
        ),
        'blockquote': Style(
          backgroundColor: context.theme.colorScheme.primary.withOpacity(0.07),
          padding: HtmlPaddings.symmetric(horizontal: 12, vertical: 8),
          margin: Margins.only(left: 0, right: 0, top: 4, bottom: 4),
          border: Border(left: BorderSide(color: context.theme.colorScheme.primary, width: 3)),
        ),
        'img': Style(margin: Margins.only(bottom: 8)),
      };

  TagExtension _imgExtension(BuildContext context) => TagExtension(
        tagsToExtend: {'img'},
        builder: (extensionContext) {
          final src = extensionContext.attributes['src'] ?? '';
          final widthAttr = extensionContext.attributes['width'];
          final heightAttr = extensionContext.attributes['height'];
          final double? w = widthAttr != null ? double.tryParse(widthAttr) : null;
          final double? h = heightAttr != null ? double.tryParse(heightAttr) : null;
          final isIcon = w != null && w <= 80;
          return CachedNetworkImage(
            imageUrl: src,
            width: isIcon ? w : double.infinity,
            height: h ?? (isIcon ? 60 : null),
            fit: isIcon ? BoxFit.contain : BoxFit.fitWidth,
            errorWidget: (_, __, ___) => SizedBox(width: w ?? 40, height: h ?? 40),
            placeholder: (_, __) => SizedBox(width: w ?? 40, height: h ?? 40),
          );
        },
      );

  String _mdToHtml(String md) {
    final lines = md.split('\n');
    final buffer = StringBuffer();
    for (final rawLine in lines) {
      var line = rawLine.trim();
      if (line.isEmpty) continue;
      if (RegExp(r'^<(div|p|h[1-6]|ul|ol|li|blockquote|br)', caseSensitive: false).hasMatch(line)) {
        buffer.writeln(line);
        continue;
      }
      line = line
          .replaceAllMapped(RegExp(r'\*\*\*(.*?)\*\*\*'), (m) => '<strong><em>${m[1]}</em></strong>')
          .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => '<strong>${m[1]}</strong>')
          .replaceAllMapped(RegExp(r'~~(.*?)~~'), (m) => '<del>${m[1]}</del>')
          .replaceAllMapped(RegExp(r'`(.*?)`'), (m) => '<code>${m[1]}</code>')
          .replaceAllMapped(RegExp(r'^### (.+)$'), (m) => '<h3>${m[1]}</h3>')
          .replaceAllMapped(RegExp(r'^## (.+)$'), (m) => '<h2>${m[1]}</h2>')
          .replaceAllMapped(RegExp(r'^# (.+)$'), (m) => '<h1>${m[1]}</h1>');
      if (RegExp(r'^<h[1-6]>').hasMatch(line)) {
        buffer.writeln(line);
      } else {
        buffer.writeln('<p>$line</p>');
      }
    }
    return buffer.toString();
  }

  Widget _buildSliverAppBar(BuildContext context, String avatarUrl,
      String? bannerUrl, String name, Animation<Alignment> bannerAnim) {
    final hasBanner = bannerUrl != null && bannerUrl.trim().isNotEmpty;
    final imageUrl = hasBanner ? bannerUrl : avatarUrl;
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      backgroundColor: context.theme.colorScheme.surface,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surface.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(IconlyLight.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: bannerAnim,
              builder: (context, child) {
                return CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: hasBanner ? BoxFit.fitHeight : BoxFit.cover,
                  alignment: hasBanner ? bannerAnim.value : Alignment.center,
                  errorWidget: (_, __, ___) =>
                      Container(color: context.theme.colorScheme.surfaceContainer),
                );
              },
            ),
            if (!hasBanner)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: context.theme.colorScheme.surface.withOpacity(0.2)),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    context.theme.colorScheme.surface.withOpacity(0.8),
                    context.theme.colorScheme.surface,
                  ],
                  stops: const [0.0, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarAndName(BuildContext context, String avatarUrl, String name) {
    final handler = Get.find<ServiceHandler>();
    final expiry = handler.profileData.value.tokenExpiry;
    String expiryText = "";
    if (expiry != null) {
      final days = expiry.difference(DateTime.now()).inDays;
      final months = (days / 30).floor();
      expiryText = "Reconnect in $months months";
    }
    return Transform.translate(
      offset: const Offset(0, -50),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: context.theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: context.theme.colorScheme.surfaceContainer,
              backgroundImage: CachedNetworkImageProvider(avatarUrl),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: TextStyle(
              fontSize: 26,
              fontFamily: 'Poppins-Bold',
              fontWeight: FontWeight.w700,
              color: context.theme.colorScheme.onSurface,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: context.theme.colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Anilist Member",
              style: TextStyle(fontSize: 12, color: context.theme.colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
          if (expiryText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              expiryText,
              style: TextStyle(
                fontSize: 11,
                color: context.theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildHighlightCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(color: context.theme.colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.theme.colorScheme.onSurface)),
          Text(label, style: TextStyle(fontSize: 12, color: context.theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.theme.colorScheme.onSurfaceVariant)),
          Text("$value%", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.theme.colorScheme.primary)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins-SemiBold', color: context.theme.colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: context.theme.colorScheme.surface, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: context.theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 14, color: context.theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
        ),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.theme.colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildMediaFavCarousel(BuildContext context, List<FavouriteMedia> items) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildMediaCard(context, item.cover, item.title);
        },
      ),
    );
  }

  Widget _buildMediaCard(BuildContext context, String? imageUrl, String? title) {
    return Container(
      width: 112,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl, width: 112, height: 150, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(width: 112, height: 150, color: context.theme.colorScheme.surfaceContainer))
                : Container(width: 112, height: 150, color: context.theme.colorScheme.surfaceContainer),
          ),
          const SizedBox(height: 5),
          Text(title ?? '',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.theme.colorScheme.onSurface),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildPersonCarousel(BuildContext context, List<_PersonItem> items) {
    return SizedBox(
      height: 128,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildPersonCard(context, item.image, item.name);
        },
      ),
    );
  }

  Widget _buildPersonCard(BuildContext context, String? imageUrl, String? name) {
    return Container(
      width: 78,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl, width: 70, height: 70, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: context.theme.colorScheme.surfaceContainer)))
                : Container(width: 70, height: 70,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: context.theme.colorScheme.surfaceContainer)),
          ),
          const SizedBox(height: 6),
          Text(name ?? '',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: context.theme.colorScheme.onSurface),
              maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ContentSegment {
  final String content;
  final bool isSpoiler;
  const _ContentSegment({required this.content, required this.isSpoiler});
}

class _PersonItem {
  final String? name;
  final String? image;
  const _PersonItem({this.name, this.image});
}

class _SpoilerBlock extends StatefulWidget {
  final String rawContent;
  final Map<String, Style> htmlStyle;
  final TagExtension imgExtension;
  final String Function(String) preprocessHtml;

  const _SpoilerBlock({
    required this.rawContent,
    required this.htmlStyle,
    required this.imgExtension,
    required this.preprocessHtml,
  });

  @override
  State<_SpoilerBlock> createState() => _SpoilerBlockState();
}

class _SpoilerBlockState extends State<_SpoilerBlock> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      child: _revealed ? _buildRevealed(context, scheme) : _buildHidden(context, scheme),
    );
  }

  Widget _buildHidden(BuildContext context, ColorScheme scheme) {
    return InkWell(
      onTap: () => setState(() => _revealed = true),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_off_rounded,
                size: 16, color: scheme.onSurfaceVariant.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(
              'Spoiler, tap to reveal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevealed(BuildContext context, ColorScheme scheme) {
    final html = widget.preprocessHtml(widget.rawContent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: InkWell(
            onTap: () => setState(() => _revealed = false),
            borderRadius: const BorderRadius.only(topRight: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.close_rounded, size: 18, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Html(
            data: html,
            style: widget.htmlStyle,
            extensions: [widget.imgExtension],
          ),
        ),
      ],
    );
  }
}
