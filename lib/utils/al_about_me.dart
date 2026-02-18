import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

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

    // Convert Anilist custom tags
    c = c.replaceAllMapped(
      RegExp(r'img(\d+)\(([^)]+)\)'),
      (m) => '<img src="${m[2] ?? ''}" width="${m[1] ?? ''}">',
    );

    c = c.replaceAllMapped(
      RegExp(r'youtube\(([^)]+)\)'),
      (m) {
        final raw = (m[1] ?? '').trim();
        final uri = Uri.tryParse(raw);
        final id = uri?.queryParameters['v'] ?? raw;
        return '<youtube id="$id">';
      },
    );

    c = c.replaceAllMapped(
      RegExp(r'webm\(([^)]+)\)'),
      (m) => '<a href="${(m[1] ?? '').trim()}">&#9654; View video</a>',
    );

    c = c.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (m) => '<a href="${m[2] ?? ''}">${m[1] ?? ''}</a>',
    );

    // Convert remaining standalone spoilers
    c = c.replaceAllMapped(
      RegExp(r'~!([\s\S]*?)!~'),
      (m) => '<spoiler>${m[1] ?? ''}</spoiler>',
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

    // Handle div spoilers
    c = c.replaceAllMapped(
      RegExp(r'<div\s+rel=["\x27]spoiler["\x27][^>]*>([\s\S]*?)</div>',
          caseSensitive: false),
      (m) => '<spoiler>${m[1] ?? ''}</spoiler>',
    );
    
    final hasHtml = RegExp(r'<[a-zA-Z][^>]*>').hasMatch(c);
    if (!hasHtml) {
      c = _mdToHtml(c);
    }

    return c;
  }

  String _mdToHtml(String md) {
    final lines = md.split('\n');
    final buffer = StringBuffer();
    for (final rawLine in lines) {
      var line = rawLine.trim();
      if (line.isEmpty) continue;
      if (RegExp(
              r'^<(div|p|h[1-6]|ul|ol|li|blockquote|br|hr|pre|spoiler|youtube)',
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
          .replaceAllMapped(
              RegExp(r'`(.*?)`'), (m) => '<code>${m[1]}</code>')
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

    return Html(
      data: content,
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(13.5),
          lineHeight: LineHeight(1.6),
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
          backgroundColor:
              context.theme.colorScheme.primary.withOpacity(0.07),
          padding: HtmlPaddings.symmetric(horizontal: 12, vertical: 8),
          margin: Margins.only(left: 0, right: 0, top: 4, bottom: 4),
          border: Border(
              left: BorderSide(
                  color: context.theme.colorScheme.primary, width: 3)),
        ),
        'ul': Style(margin: Margins.only(bottom: 8, left: 16)),
        'ol': Style(margin: Margins.only(bottom: 8, left: 16)),
        'li': Style(
          margin: Margins.only(bottom: 4),
          color: context.theme.colorScheme.onSurfaceVariant,
        ),
        'hr': Style(
          border: Border(
              bottom: BorderSide(
                  color: context.theme.colorScheme.outlineVariant
                      .withOpacity(0.5),
                  width: 1)),
          margin: Margins.symmetric(vertical: 12),
        ),
      },
      extensions: [
        TagExtension(
          tagsToExtend: {'img'},
          builder: (ext) {
            final src = ext.attributes['src'] ?? '';
            if (src.isEmpty) return const SizedBox.shrink();
            double? parsePx(String? v) =>
                v == null ? null : double.tryParse(v.replaceAll('px', ''));
            final w = parsePx(ext.attributes['width']);
            final h = parsePx(ext.attributes['height']);
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
        TagExtension(
          tagsToExtend: {'spoiler'},
          builder: (ext) {
            return _SpoilerWidget(
              child: Html(
                data: ext.innerHtml,
                style: {
                  'body': Style(
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
        TagExtension(
          tagsToExtend: {'youtube'},
          builder: (ext) {
            final id = ext.attributes['id'] ?? '';
            if (id.isEmpty) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => launchUrl(
                Uri.parse('https://www.youtube.com/watch?v=$id'),
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
                          'https://img.youtube.com/vi/$id/hqdefault.jpg',
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
          color:
              context.theme.colorScheme.outlineVariant.withOpacity(0.4),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
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
