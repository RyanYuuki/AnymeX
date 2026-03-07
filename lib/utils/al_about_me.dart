import 'dart:io';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';

class AnilistAboutMe extends StatefulWidget {
  final String about;

  const AnilistAboutMe({super.key, required this.about});

  @override
  State<AnilistAboutMe> createState() => _AnilistAboutMeState();
}

class _AnilistAboutMeState extends State<AnilistAboutMe> {
  String _preprocessAbout(String raw) {
    var c = raw;

    // Clean up zero-width spaces and other invisible characters
    c = c
        .replaceAll('\u200e', '')
        .replaceAll('\u200f', '')
        .replaceAll('\u200b', '')
        .replaceAll('\u200c', '')
        .replaceAll('\u200d', '')
        .replaceAll('\u034f', '')
        .replaceAll('&lrm;', '')
        .replaceAll('&rlm;', '')
        .replaceAll('&#8206;', '')
        .replaceAll('&#8207;', '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#160;', ' ')
        .replaceAll('&thinsp;', '')
        .replaceAll('&emsp;', '')
        .replaceAll('&ensp;', '');

    // Handle spoilers that are inside <a> tags
    c = c.replaceAllMapped(
      RegExp(r'<a([^>]*)>([\s\S]*?)~!([\s\S]*?)!~([\s\S]*?)</a>'),
      (m) {
        final attrs = m[1] ?? '';
        final beforeSpoiler = m[2] ?? '';
        final spoilerContent = m[3] ?? '';
        final afterSpoiler = m[4] ?? '';

        String result = '';
        if (beforeSpoiler.isNotEmpty) {
          result += '<a$attrs>$beforeSpoiler</a>';
        }
        result += '<spoiler>$spoilerContent</spoiler>';
        if (afterSpoiler.isNotEmpty) {
          result += '<a$attrs>$afterSpoiler</a>';
        }
        return result;
      },
    );

    // Handle spoilers at start of <a> tag
    c = c.replaceAllMapped(
      RegExp(r'<a([^>]*)>(~![\s\S]*?!~)([\s\S]*?)</a>'),
      (m) {
        final attrs = m[1] ?? '';
        final spoilerContent = m[2] ?? '';
        final afterSpoiler = m[3] ?? '';

        return '<spoiler>${spoilerContent.replaceAll('~!', '').replaceAll('!~', '')}</spoiler><a$attrs>$afterSpoiler</a>';
      },
    );

    // Handle spoilers at end of <a> tag
    c = c.replaceAllMapped(
      RegExp(r'<a([^>]*)>([\s\S]*?)(~![\s\S]*?!~)</a>'),
      (m) {
        final attrs = m[1] ?? '';
        final beforeSpoiler = m[2] ?? '';
        final spoilerContent = m[3] ?? '';

        return '<a$attrs>$beforeSpoiler</a><spoiler>${spoilerContent.replaceAll('~!', '').replaceAll('!~', '')}</spoiler>';
      },
    );

    c = c.replaceAllMapped(
      RegExp(
          r'<div\s+class=["\x27]youtube["\x27]\s+id=["\x27]([^"\x27]+)["\x27][^>]*></div>',
          caseSensitive: false),
      (m) {
        final rawId = m[1] ?? '';
        final match = RegExp(r'(?:v=|\/|youtu\.be\/)([0-9A-Za-z_-]{11})')
            .firstMatch(rawId);
        final id = match?.group(1) ?? rawId;
        return '<youtube id="$id"></youtube>';
      },
    );

    c = c.replaceAllMapped(
      RegExp(r'<iframe[^>]*src=["\x27]([^"\x27]+)["\x27][^>]*>.*?</iframe>',
          caseSensitive: false),
      (m) {
        final src = (m[1] ?? '').trim();
        if (src.isEmpty) return '';

        final yt = RegExp(r'(?:v=|\/|youtu\.be\/|embed\/)([0-9A-Za-z_-]{11})')
            .firstMatch(src)
            ?.group(1);
        if (yt != null && yt.isNotEmpty) {
          return '<youtube id="$yt"></youtube>';
        }

        if (src.toLowerCase().contains('spotify.com')) {
          return '<spotify src="$src"></spotify>';
        }

        return '<embed src="$src"></embed>';
      },
    );

    c = c.replaceAllMapped(
      RegExp(r'webm\(([^)]+)\)'),
      (m) => '<a href="${(m[1] ?? '').trim()}">&#9654; View video</a>',
    );

    c = c.replaceAllMapped(
      RegExp(r'img(\d+)?\(([^)]+)\)'),
      (m) {
        final width = m[1];
        final url = (m[2] ?? '').trim();
        if (url.toLowerCase().contains('count.getloli.com')) {
          return '';
        }
        final wAttr =
            width != null && width.isNotEmpty ? ' width="$width"' : '';
        return '<img src="$url"$wAttr>&#8203;';
      },
    );

    c = c.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (m) => '<a href="${m[2] ?? ''}">${m[1] ?? ''}</a>',
    );

    c = c.replaceAllMapped(
      RegExp(r'~!([\s\S]*?)!~'),
      (m) {
        final content = m[1] ?? '';
        return '<spoiler>$content</spoiler>';
      },
    );

    c = c.replaceAllMapped(
      RegExp(r'!\[([^\]]*)\]\((.*?)\)', dotAll: true),
      (m) {
        String alt = m[1] ?? '';
        String rawSrc = m[2] ?? '';
        if (rawSrc.toLowerCase().contains('count.getloli.com')) {
          return '';
        }

        String src = rawSrc.replaceAllMapped(
          RegExp(r'<a[^>]*>([\s\S]*?)</a>', caseSensitive: false),
          (a) => a[1] ?? '',
        );
        return '<img src="$src" alt="$alt">';
      },
    );

    c = c.replaceAllMapped(
        RegExp(r'<img[^>]*src=["\x27]([^"\x27]+)["\x27][^>]*>',
            caseSensitive: false), (m) {
      if ((m[1] ?? '').toLowerCase().contains('count.getloli.com')) return '';
      return m[0]!;
    });

    c = c.replaceAllMapped(
      RegExp(
          r'(?<!["\x27=])https?:\/\/anilist\.co\/(anime|manga)\/(\d+)[^\s<]*'),
      (m) {
        final type = m[1] ?? 'anime';
        final id = m[2] ?? '';
        return '<anilist id="$id" type="$type"></anilist>';
      },
    );

    c = c.replaceAllMapped(
      RegExp(r'(?<!["\x27=])(https?:\/\/[^\s<]+)(?![^<]*>)'),
      (m) {
        final url = m[1] ?? '';
        return '<a href="$url">$url</a>';
      },
    );

    // Handle centering
    c = c.replaceAllMapped(
      RegExp(r'~~~([\s\S]*?)~~~'),
      (m) => '<div style="text-align:center;">${m[1] ?? ''}</div>',
    );

    c = c.replaceAllMapped(
      RegExp(r'<center>([\s\S]*?)</center>', caseSensitive: false),
      (m) => '<div style="text-align:center;">${m[1] ?? ''}</div>',
    );

    // Handle align attributes
    c = c.replaceAllMapped(
      RegExp(
        r'<(div|p)(\s[^>]*)?\salign=(["\x27])(\w+)\3([^>]*)>',
        caseSensitive: false,
      ),
      (m) {
        final tag = m[1] ?? 'div';
        final before = m[2] ?? '';
        final align = m[4] ?? 'left';
        final after = m[5] ?? '';
        if (before.contains('style=') || after.contains('style=')) {
          return '<$tag$before$after>';
        }
        return '<$tag$before style="text-align:$align;"$after>';
      },
    );

    // Handle html spoilers
    c = c.replaceAllMapped(
      RegExp(r'<div\s+rel=["\x27]spoiler["\x27][^>]*>([\s\S]*?)</div>',
          caseSensitive: false),
      (m) => '<spoiler>${m[1] ?? ''}</spoiler>',
    );

    c = c.replaceAllMapped(
      RegExp(
          r"<span\s+class=['\x22]markdown_spoiler['\x22][^>]*>(?:\s*<span>)?([\s\S]*?)(?:</span>\s*)?</span>",
          caseSensitive: false),
      (m) => '<spoiler>${m[1] ?? ''}</spoiler>',
    );

    c = _mdToHtml(c);

    bool changed = true;
    while (changed) {
      final old = c;
      c = c.replaceAll(
          RegExp(r'<div[^>]*>\s*</div>', caseSensitive: false), '');
      c = c.replaceAll(RegExp(r'<p[^>]*>\s*</p>', caseSensitive: false), '');
      c = c.replaceAll(
          RegExp(r'<center[^>]*>\s*</center>', caseSensitive: false), '');
      changed = old != c;
    }

    c = c.replaceAll(RegExp(r'(<br\s*/?>\s*)+', caseSensitive: false), '<br>');
    c = c.replaceAll(
        RegExp(r'(?:<br\s*/?>\s*)*<hr[^>]*>(?:\s*<br\s*/?>\s*)*',
            caseSensitive: false),
        '<hr>');
    c = c.replaceAll(RegExp(r'(<hr[^>]*>\s*)+', caseSensitive: false), '<hr>');

    return c;
  }

  String _mdToHtml(String md) {
    final lines = md.split('\n');
    final buffer = StringBuffer();
    bool lastWasHr = false;

    for (final rawLine in lines) {
      var line = rawLine.trim();
      if (line.isEmpty) continue;

      bool isHr = RegExp(r'^<hr.*?/?>(?:\s*<br\s*/?>)*\s*$|^[-_]{3,}$',
              caseSensitive: false)
          .hasMatch(line);
      if (isHr) {
        if (lastWasHr) continue;
        lastWasHr = true;
      } else {
        lastWasHr = false;
      }

      if (RegExp(
              r'^<(div|p|h[1-6]|ul|ol|li|blockquote|br|hr|pre|spoiler|youtube|spotify|anilist)',
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
          .replaceAllMapped(RegExp(r'^#{5}\s+(.+)$'), (m) => '<h5>${m[1]}</h5>')
          .replaceAllMapped(RegExp(r'^#{4}\s+(.+)$'), (m) => '<h4>${m[1]}</h4>')
          .replaceAllMapped(RegExp(r'^#{3}\s+(.+)$'), (m) => '<h3>${m[1]}</h3>')
          .replaceAllMapped(RegExp(r'^#{2}\s+(.+)$'), (m) => '<h2>${m[1]}</h2>')
          .replaceAllMapped(RegExp(r'^#\s+(.+)$'), (m) => '<h1>${m[1]}</h1>');

      // Horizontal rules
      if (RegExp(r'^(-{3,}|\*{3,}|(\s*-\s*){3,}|(\s*\*\s*){3,})$')
          .hasMatch(line)) {
        buffer.writeln('<hr>');
        continue;
      }
      // Bullet lists
      if (RegExp(r'^[-*+]\s+').hasMatch(line)) {
        final text = line.replaceFirst(RegExp(r'^[-*+]\s+'), '');
        buffer.writeln('<ul><li>$text</li></ul>');
        continue;
      }
      // Numbered lists
      if (RegExp(r'^\d+\.\s+').hasMatch(line)) {
        final text = line.replaceFirst(RegExp(r'^\d+\.\s+'), '');
        buffer.writeln('<ol><li>$text</li></ol>');
        continue;
      }
      // Blockquote
      if (line.startsWith('&gt;') || line.startsWith('>')) {
        final text = line
            .replaceFirst(RegExp(r'^&gt;\s*'), '')
            .replaceFirst(RegExp(r'^>\s*'), '');
        buffer.writeln('<blockquote>$text</blockquote>');
        continue;
      }
      if (RegExp(r'^<h[1-6]>').hasMatch(line)) {
        buffer.writeln(line);
      } else {
        buffer.writeln('<p>$line</p>');
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final String content;
    try {
      content = _preprocessAbout(widget.about);
    } catch (e) {
      return Text(
        widget.about,
        style: TextStyle(
          fontSize: 13.5,
          color: context.theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return SelectionArea(
        child: Html(
      data: content,
      onLinkTap: (url, attributes, element) {
        if (url != null) {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(13.5),
          lineHeight: const LineHeight(1.6),
          color: context.theme.colorScheme.onSurfaceVariant,
          fontFamily: 'Poppins',
        ),
        'div': Style(margin: Margins.only(bottom: 8)),
        'p': Style(margin: Margins.only(bottom: 8)),
        'a': Style(
          display: Display.inline,
          textDecoration: TextDecoration.none,
          color: context.theme.colorScheme.primary,
        ),
        'img': Style(
          display: Display.inline,
          margin: Margins.only(right: 4, bottom: 4),
        ),
        'h1': Style(
            fontSize: FontSize(20),
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface),
        'h2': Style(
            fontSize: FontSize(18),
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface),
        'h3': Style(
            fontSize: FontSize(16),
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface),
        'h4': Style(
            fontSize: FontSize(14),
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface),
        'h5': Style(
            fontSize: FontSize(13),
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface),
        'strong': Style(
            fontWeight: FontWeight.w700,
            color: context.theme.colorScheme.onSurface),
        'b': Style(
            fontWeight: FontWeight.w700,
            color: context.theme.colorScheme.onSurface),
        'em': Style(
            fontStyle: FontStyle.italic,
            color: context.theme.colorScheme.onSurface),
        'i': Style(
            fontStyle: FontStyle.italic,
            color: context.theme.colorScheme.onSurface),
        'del': Style(
            textDecoration: TextDecoration.lineThrough,
            color: context.theme.colorScheme.onSurfaceVariant),
        'strike': Style(
            textDecoration: TextDecoration.lineThrough,
            color: context.theme.colorScheme.onSurfaceVariant),
        'code': Style(
          fontFamily: 'monospace',
          fontSize: FontSize(12),
          backgroundColor: context.theme.colorScheme.surfaceContainer,
          color: context.theme.colorScheme.primary,
        ),
        'pre': Style(
          fontFamily: 'monospace',
          fontSize: FontSize(12),
          backgroundColor: context.theme.colorScheme.surfaceContainer,
          padding: HtmlPaddings.all(10),
          margin: Margins.only(bottom: 8),
        ),
        'blockquote': Style(
          backgroundColor: context.theme.colorScheme.primary.withOpacity(0.07),
          padding: HtmlPaddings.symmetric(horizontal: 12, vertical: 8),
          margin: Margins.only(left: 0, right: 0, top: 4, bottom: 4),
          border: Border(
              left: BorderSide(
                  color: context.theme.colorScheme.primary, width: 3)),
        ),
        'ul': Style(margin: Margins.only(bottom: 8, left: 16)),
        'anilist': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
        'youtube': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
        'spotify': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
        'embed': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
        'ol': Style(margin: Margins.only(bottom: 8, left: 16)),
        'li': Style(
          margin: Margins.only(bottom: 4),
          color: context.theme.colorScheme.onSurfaceVariant,
        ),
        'hr': Style(
          border: Border(
              bottom: BorderSide(
                  color:
                      context.theme.colorScheme.outlineVariant.withOpacity(0.5),
                  width: 1)),
          margin: Margins.symmetric(vertical: 12),
        ),
      },
      extensions: [
        TagExtension(
          tagsToExtend: {'img'},
          builder: (ext) {
            final src = ext.attributes['src'] ?? '';
            if (src.isEmpty ||
                src.toLowerCase().contains('count.getloli.com')) {
              return const SizedBox.shrink();
            }
            double? parsePx(String? v) =>
                v == null ? null : double.tryParse(v.replaceAll('px', ''));
            double? parseFromStyle(String? style, String key) {
              if (style == null || style.isEmpty) return null;
              final match = RegExp('$key\\s*:\\s*([0-9]+(?:\\.[0-9]+)?)px',
                      caseSensitive: false)
                  .firstMatch(style);
              return match == null ? null : double.tryParse(match.group(1)!);
            }

            final styleAttr = ext.attributes['style'];
            var w = parsePx(ext.attributes['width']) ??
                parseFromStyle(styleAttr, 'width');
            var h = parsePx(ext.attributes['height']) ??
                parseFromStyle(styleAttr, 'height');

            final isIcon = w != null && w <= 96;
            final isSvg = src.toLowerCase().contains('.svg');

            const headers = {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': 'image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
            };

            return Builder(
              builder: (context) {
                final screenW = MediaQuery.of(context).size.width;
                final maxMediaWidth = screenW.clamp(240.0, 520.0).toDouble();

                Widget media;

                if (isSvg) {
                  media = SvgPicture.network(
                    src,
                    headers: headers,
                    width: w?.clamp(0.0, maxMediaWidth).toDouble(),
                    height: h,
                    fit: (w == null && h == null)
                        ? BoxFit.scaleDown
                        : BoxFit.contain,
                    placeholderBuilder: (_) => SizedBox(
                      width: w != null
                          ? w.clamp(0.0, maxMediaWidth).toDouble()
                          : 40,
                      height: h ?? 40,
                    ),
                  );
                } else {
                  media = CachedNetworkImage(
                    imageUrl: src,
                    httpHeaders: headers,
                    width: w?.clamp(0.0, maxMediaWidth).toDouble(),
                    height: h,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    placeholder: (_, __) => const SizedBox.shrink(),
                  );
                }

                if (isIcon) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 4),
                    child: media,
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxMediaWidth),
                      child: media,
                    ),
                  ),
                );
              },
            );
          },
        ),
        TagExtension(
          tagsToExtend: {'spoiler'},
          builder: (ext) {
            return _SpoilerWidget(
              child: AnilistAboutMe(about: ext.innerHtml),
            );
          },
        ),
        TagExtension(
          tagsToExtend: {'youtube'},
          builder: (ext) {
            final id = ext.attributes['id'] ?? '';
            if (id.isEmpty) return const SizedBox.shrink();
            return _YouTubePlayerWidget(videoId: id);
          },
        ),
        TagExtension(
          tagsToExtend: {'spotify'},
          builder: (ext) {
            final src = ext.attributes['src'] ?? '';
            if (src.isEmpty) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => launchUrl(Uri.parse(src),
                  mode: LaunchMode.externalApplication),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF1DB954).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note_rounded,
                          color: Color(0xFF1DB954), size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Spotify Widget',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        context.theme.colorScheme.onSurface)),
                            Text('Tap to open in browser / Spotify app',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: context
                                        .theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const Icon(Icons.open_in_new_rounded,
                          size: 20, color: Color(0xFF1DB954)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        TagExtension(
          tagsToExtend: {'anilist'},
          builder: (ext) {
            final idString = ext.attributes['id'] ?? '';
            final type = ext.attributes['type'] ?? 'anime';
            final id = int.tryParse(idString);
            if (id == null) return const SizedBox.shrink();

            return _AnilistCard(id: id, type: type);
          },
        ),
        TagExtension(
          tagsToExtend: {'embed'},
          builder: (ext) {
            final src = ext.attributes['src'] ?? '';
            if (src.isEmpty) return const SizedBox.shrink();

            return GestureDetector(
              onTap: () => launchUrl(Uri.parse(src),
                  mode: LaunchMode.externalApplication),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: context.theme.colorScheme.outlineVariant
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new_rounded,
                          size: 18,
                          color: context.theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Embedded content (tap to open)',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ));
  }
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
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.theme.colorScheme.outlineVariant.withOpacity(0.4),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: open ? _buildRevealed(context) : _buildHidden(context),
        ),
      ),
    );
  }

  Widget _buildHidden(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => open = true),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_off_rounded,
                size: 16,
                color: context.theme.colorScheme.onSurfaceVariant
                    .withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(
              'Spoiler \u2014 tap to reveal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                    context.theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevealed(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 36, 16),
          child: widget.child,
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: Icon(Icons.close_rounded,
                size: 20, color: context.theme.colorScheme.onSurfaceVariant),
            onPressed: () => setState(() => open = false),
          ),
        ),
      ],
    );
  }
}

class _YouTubePlayerWidget extends StatefulWidget {
  final String videoId;

  const _YouTubePlayerWidget({required this.videoId});

  @override
  State<_YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<_YouTubePlayerWidget> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    if (_isPlaying) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black,
                ),
                clipBehavior: Clip.hardEdge,
                child: InAppWebView(
                  initialData: InAppWebViewInitialData(
                    data: '''
              <!DOCTYPE html>
              <html>
                <head>
                  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                  <style>
                    body { margin: 0; background-color: black; overflow: hidden; }
                    iframe { width: 100%; height: 100vh; border: none; }
                  </style>
                </head>
                <body>
                  <iframe 
                    src="https://www.youtube.com/embed/${widget.videoId}?autoplay=1&playsinline=1&modestbranding=1&rel=0" 
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                    allowfullscreen>
                  </iframe>
                </body>
              </html>
            ''',
                  ),
                  initialSettings: InAppWebViewSettings(
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    iframeAllowFullscreen: true,
                    transparentBackground: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (Platform.isAndroid || Platform.isIOS) {
          setState(() {
            _isPlaying = true;
          });
        } else {
          launchUrl(
            Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}'),
            mode: LaunchMode.externalApplication,
          );
        }
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
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
                          'https://img.youtube.com/vi/${widget.videoId}/hqdefault.jpg',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.black54,
                        child: const Icon(Icons.play_circle_outline,
                            color: Colors.white, size: 48),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE52D27),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 36),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnilistCard extends StatefulWidget {
  final int id;
  final String type;

  const _AnilistCard({required this.id, required this.type});

  @override
  State<_AnilistCard> createState() => _AnilistCardState();
}

class _AnilistCardState extends State<_AnilistCard> {
  Future<dynamic>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    final handler = Get.find<ServiceHandler>();
    _dataFuture = handler.anilistService.fetchDetails(FetchDetailsParams(
      id: widget.id.toString(),
      isManga: widget.type == 'manga',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(width: 0, height: 0);
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          if (snapshot.hasError) {
            debugPrint(
                'AnilistCard Error: ${snapshot.error}\\nStatus: ${snapshot.connectionState}\\nStacktrace: ${snapshot.stackTrace}');
          }
          return const SizedBox(width: 0, height: 0); // Ignore if it fails
        }

        final data = snapshot.data;

        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth > 600;

        return GestureDetector(
          onTap: () {
            if (widget.type.toLowerCase() == 'manga') {
              navigate(() => MangaDetailsPage(
                    media: data,
                    tag: data.title,
                  ));
            } else {
              navigate(() => AnimeDetailsPage(
                    media: data,
                    tag: data.title,
                  ));
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  height: isDesktop ? 120 : 100,
                  decoration: BoxDecoration(
                    color: context.theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.theme.colorScheme.outlineVariant
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12)),
                        child: AnymeXImage(
                          imageUrl: data.poster ?? '',
                          width: isDesktop ? 85 : 75,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                data.title.isNotEmpty
                                    ? data.title
                                    : (data.romajiTitle ?? 'Unknown Title'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isDesktop ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${widget.type.capitalizeFirst!} \u2022 ${data.status ?? "Unknown"} \u2022 ${data.premiered ?? "-"} '
                                '${(data.rating != null && data.rating.toString().isNotEmpty) ? '\u2022 ${data.rating}0%' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isDesktop ? 13 : 12,
                                  color: context
                                      .theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
