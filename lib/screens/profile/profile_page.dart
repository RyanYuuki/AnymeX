import 'dart:ui';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:url_launcher/url_launcher.dart';

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
              _buildSliverAppBar(context, bannerUrl, user.cover,
                  user.name ?? 'Guest', _bannerAnim),
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
    var content = about;

    content = content
        .replaceAll('\u200e', '')
        .replaceAll('\u200f', '')
        .replaceAll('\u200b', '')
        .replaceAll('\u200c', '')
        .replaceAll('\u200d', '')
        .replaceAll('\u034f', '')
        .replaceAll('&lrm;', '')
        .replaceAll('&#8206;', '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#160;', ' ')
        .replaceAll('&thinsp;', '')
        .replaceAll('&emsp;', '')
        .replaceAll('&ensp;', '');

    content = content.replaceAllMapped(
      RegExp(r'img(\d+)\(([^)]+)\)'),
      (m) => '<img src="${m[2]}" width="${m[1]}">',
    );

    content = content.replaceAllMapped(
      RegExp(r'youtube\(([^)]+)\)'),
      (m) {
        final uri = Uri.tryParse(m[1].trim());
        final id = uri?.queryParameters['v'] ?? m[1].trim();
        return '<youtube id="$id">';
      },
    );

    content = content.replaceAllMapped(
      RegExp(r'webm\(([^)]+)\)'),
      (m) => '<a href="${m[1].trim()}">▶ View video</a>',
    );

    content = content.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (m) => '<a href="${m[2]}">${m[1]}</a>',
    );

    content = content.replaceAllMapped(
      RegExp(r'~!([\s\S]*?)!~'),
      (m) => '<spoiler>${m[1]}</spoiler>',
    );

    content = content.replaceAllMapped(
      RegExp(r'<(div|p)\b([^>]*?)\balign=["\'](\w+)["\']([^>]*)>',
          caseSensitive: false),
      (m) {
        final tag = m[1];
        final before = m[2] ?? '';
        final align = m[3];
        final after = m[4] ?? '';
        return '<$tag$before style="text-align:$align;"$after>';
      },
    );

    // If no HTML, convert markdown to HTML
    final hasHtml = RegExp(r'<[a-zA-Z][^>]*>').hasMatch(content);
    if (!hasHtml) {
      content = _mdToHtml(content);
    }

    return Html(
      data: content,
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(13.5),
          lineHeight: LineHeight(1.6),
          color: context.theme.colorScheme.onSurfaceVariant,
          fontFamily: 'Poppins',
        ),
        "div": Style(
          margin: Margins.only(bottom: 8),
        ),
        "p": Style(
          margin: Margins.only(bottom: 8),
        ),
        "a": Style(
          display: Display.inline,
          textDecoration: TextDecoration.none,
          color: context.theme.colorScheme.primary,
        ),
        "img": Style(
          display: Display.inline,
          margin: Margins.only(right: 4, bottom: 4),
        ),
        "h1": Style(
            fontSize: FontSize(20),
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface),
        "h2": Style(
            fontSize: FontSize(18),
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface),
        "h3": Style(
            fontSize: FontSize(16),
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface),
        "h4": Style(
            fontSize: FontSize(14),
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface),
        "h5": Style(
            fontSize: FontSize(13),
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface),
        "strong": Style(
            fontWeight: FontWeight.w700,
            color: context.theme.colorScheme.onSurface),
        "b": Style(
            fontWeight: FontWeight.w700,
            color: context.theme.colorScheme.onSurface),
        "em": Style(
            fontStyle: FontStyle.italic,
            color: context.theme.colorScheme.onSurface),
        "i": Style(
            fontStyle: FontStyle.italic,
            color: context.theme.colorScheme.onSurface),
        "del": Style(
            textDecoration: TextDecoration.lineThrough,
            color: context.theme.colorScheme.onSurfaceVariant),
        "code": Style(
          fontFamily: 'monospace',
          fontSize: FontSize(12),
          backgroundColor: context.theme.colorScheme.surfaceContainer,
          color: context.theme.colorScheme.primary,
        ),
        "blockquote": Style(
          backgroundColor: context.theme.colorScheme.primary.withOpacity(0.07),
          padding: HtmlPaddings.symmetric(horizontal: 12, vertical: 8),
          margin: Margins.only(left: 0, right: 0, top: 4, bottom: 4),
          border: Border(
              left: BorderSide(
                  color: context.theme.colorScheme.primary, width: 3)),
        ),
        "ul": Style(margin: Margins.only(bottom: 8, left: 16)),
        "ol": Style(margin: Margins.only(bottom: 8, left: 16)),
        "li": Style(
          margin: Margins.only(bottom: 4),
          color: context.theme.colorScheme.onSurfaceVariant,
        ),
      },
      extensions: [
        // Custom img rendering
        TagExtension(
          tagsToExtend: {"img"},
          builder: (ext) {
            final src = ext.attributes["src"] ?? "";
            final widthAttr = ext.attributes["width"];
            final heightAttr = ext.attributes["height"];
            double? parsePx(String? value) {
              if (value == null) return null;
              return double.tryParse(value.replaceAll("px", ""));
            }
            final w = parsePx(widthAttr);
            final h = parsePx(heightAttr);
            final isIcon = w != null && w <= 80;
            return CachedNetworkImage(
              imageUrl: src,
              width: isIcon ? w : (w ?? double.infinity),
              height: h,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) =>
                  SizedBox(width: w ?? 40, height: h ?? 40),
              placeholder: (_, __) =>
                  SizedBox(width: w ?? 40, height: h ?? 40),
            );
          },
        ),
        // Spoiler tag
        TagExtension(
          tagsToExtend: {"spoiler"},
          builder: (ext) {
            return _SpoilerWidget(
              child: Html(
                data: ext.innerHtml,
                style: {
                  "body": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    color: context.theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'Poppins',
                    fontSize: FontSize(13.5),
                  ),
                },
              ),
            );
          },
        ),
        // YouTube embed
        TagExtension(
          tagsToExtend: {"youtube"},
          builder: (ext) {
            final id = ext.attributes["id"] ?? "";
            if (id.isEmpty) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => launchUrl(
                Uri.parse("https://www.youtube.com/watch?v=$id"),
                mode: LaunchMode.externalApplication,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black,
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CachedNetworkImage(
                      imageUrl:
                          "https://img.youtube.com/vi/$id/hqdefault.jpg",
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.black54,
                        child: const Icon(Icons.play_circle_outline,
                            color: Colors.white, size: 48),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.white, size: 32),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _mdToHtml(String md) {
    final lines = md.split('\n');
    final buffer = StringBuffer();
    for (final rawLine in lines) {
      var line = rawLine.trim();
      if (line.isEmpty) continue;
      if (RegExp(
              r'^<(div|p|h[1-6]|ul|ol|li|blockquote|br|spoiler|youtube)',
              caseSensitive: false)
          .hasMatch(line)) {
        buffer.writeln(line);
        continue;
      }
      line = line
          .replaceAllMapped(RegExp(r'\*\*\*(.*?)\*\*\*'),
              (m) => '<strong><em>${m[1]}</em></strong>')
          .replaceAllMapped(
              RegExp(r'\*\*(.*?)\*\*'), (m) => '<strong>${m[1]}</strong>')
          .replaceAllMapped(RegExp(r'_(.*?)_'), (m) => '<em>${m[1]}</em>')
          .replaceAllMapped(RegExp(r'\*(.*?)\*'), (m) => '<em>${m[1]}</em>')
          .replaceAllMapped(RegExp(r'~~(.*?)~~'), (m) => '<del>${m[1]}</del>')
          .replaceAllMapped(RegExp(r'`(.*?)`'), (m) => '<code>${m[1]}</code>')
          .replaceAllMapped(
              RegExp(r'^#{5}\s+(.+)$'), (m) => '<h5>${m[1]}</h5>')
          .replaceAllMapped(
              RegExp(r'^#{4}\s+(.+)$'), (m) => '<h4>${m[1]}</h4>')
          .replaceAllMapped(
              RegExp(r'^#{3}\s+(.+)$'), (m) => '<h3>${m[1]}</h3>')
          .replaceAllMapped(
              RegExp(r'^#{2}\s+(.+)$'), (m) => '<h2>${m[1]}</h2>')
          .replaceAllMapped(
              RegExp(r'^#\s+(.+)$'), (m) => '<h1>${m[1]}</h1>');
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
                child: Container(
                    color: context.theme.colorScheme.surface.withOpacity(0.2)),
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

  Widget _buildAvatarAndName(
      BuildContext context, String avatarUrl, String name) {
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
              style: TextStyle(
                  fontSize: 12,
                  color: context.theme.colorScheme.primary,
                  fontWeight: FontWeight.w600),
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

  Widget _buildHighlightCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
          color: context.theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.theme.colorScheme.onSurface)),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: context.theme.colorScheme.onSurfaceVariant)),
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
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.theme.colorScheme.onSurfaceVariant)),
          Text("$value%",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.theme.colorScheme.primary)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins-SemiBold',
                color: context.theme.colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildStatRow(
      BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: context.theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon,
              size: 16, color: context.theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: context.theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: context.theme.colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildMediaFavCarousel(
      BuildContext context, List<FavouriteMedia> items) {
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

  Widget _buildMediaCard(
      BuildContext context, String? imageUrl, String? title) {
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
                    imageUrl: imageUrl,
                    width: 112,
                    height: 150,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                        width: 112,
                        height: 150,
                        color: context.theme.colorScheme.surfaceContainer))
                : Container(
                    width: 112,
                    height: 150,
                    color: context.theme.colorScheme.surfaceContainer),
          ),
          const SizedBox(height: 5),
          Text(title ?? '',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: context.theme.colorScheme.onSurface),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
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

  Widget _buildPersonCard(
      BuildContext context, String? imageUrl, String? name) {
    return Container(
      width: 78,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.theme.colorScheme.surfaceContainer)))
                : Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.theme.colorScheme.surfaceContainer)),
          ),
          const SizedBox(height: 6),
          Text(name ?? '',
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: context.theme.colorScheme.onSurface),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _PersonItem {
  final String? name;
  final String? image;
  const _PersonItem({this.name, this.image});
}

class _SpoilerWidget extends StatefulWidget {
  final Widget child;
  const _SpoilerWidget({required this.child});
  @override
  State<_SpoilerWidget> createState() => _SpoilerWidgetState();
}

class _SpoilerWidgetState extends State<_SpoilerWidget> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: open ? _buildRevealed(context) : _buildHidden(context),
    );
  }

  Widget _buildHidden(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => open = true),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_off_rounded,
                size: 16,
                color: context.theme.colorScheme.onSurfaceVariant
                    .withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(
              'Spoiler — tap to reveal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.theme.colorScheme.onSurfaceVariant
                    .withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevealed(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: InkWell(
            onTap: () => setState(() => open = false),
            borderRadius:
                const BorderRadius.only(topRight: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.close_rounded,
                  size: 18,
                  color: context.theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: widget.child,
        ),
      ],
    );
  }
}
