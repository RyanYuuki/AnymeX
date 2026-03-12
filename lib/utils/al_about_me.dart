import 'dart:io';

import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/utils/al_about_me_helpers.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/markdown.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

String preprocessAnilistAbout(String raw) {
  final source = raw.trim();
  var html = source
      .replaceAll('\u200e', '')
      .replaceAll('\u200f', '')
      .replaceAll('\u200b', '')
      .replaceAll('\u200c', '')
      .replaceAll('\u200d', '')
      .replaceAll('\u034f', '')
      .replaceAll('&lrm;', '')
      .replaceAll('&rlm;', '');

  
  final hasHtml = RegExp(r'<[a-zA-Z][^>]*>').hasMatch(html);
  if (!hasHtml) {
    // Raw convert to HTML using alparser
    html = parseMarkdown(html);
  }

  // Handles al  markdown_spoiler 
  html = html.replaceAllMapped(
    RegExp(
      r"""<span\s+class=['"]markdown_spoiler['"][^>]*>(?:\s*<span>)?([\s\S]*?)(?:</span>\s*)?</span>""",
      caseSensitive: false,
    ),
    (m) => '<details><summary>Spoiler</summary>${m[1] ?? ''}</details>',
  );

  // Handle yt divs
  html = html.replaceAllMapped(
    RegExp(
      r"""<div\s+class=['"]youtube['"]\s+id=['"]([^'"]+)['"][^>]*></div>""",
      caseSensitive: false,
    ),
    (m) {
      final token = m[1] ?? '';
      final id = RegExp(r'(?:v=|youtu\.be/|embed/|shorts/)([0-9A-Za-z_-]{11})')
          .firstMatch(token)
          ?.group(1);
      return '<youtube id="${id ?? token}"></youtube>';
    },
  );

  // Handle yt() sytax
  html = html.replaceAllMapped(
    RegExp(r'youtube\s?\(\s*([^\)]+)\s*\)', caseSensitive: false),
    (m) {
      final token = m[1] ?? '';
      final id = RegExp(r'(?:v=|youtu\.be/|embed/|shorts/)([0-9A-Za-z_-]{11})')
          .firstMatch(token)
          ?.group(1);
      return '<youtube id="${id ?? token.trim()}"></youtube>';
    },
  );

  // Handle div rel="spoiler" al-spoiler thing
  html = html.replaceAllMapped(
    RegExp(r'<div\s+rel=["\x27]spoiler["\x27][^>]*>([\s\S]*?)</div>',
        caseSensitive: false),
    (m) => '<details><summary>Spoiler</summary>${m[1] ?? ''}</details>',
  );

  // Handle centering 
  html = html.replaceAllMapped(
    RegExp(r'~~~([\s\S]*?)~~~'),
    (m) => '<center>${m[1] ?? ''}</center>',
  );

  // Handle webm() to video tag
  html = html.replaceAllMapped(
    RegExp(r'webm\((https?://[^\)]+)\)', caseSensitive: false),
    (m) =>
        '<video><source src="${m[1] ?? ''}" type="video/webm"></source></video>',
  );

  // Handle img() — al custom image syntax
  html = html.replaceAllMapped(
    RegExp(r'img((?:\d+%?)?)?\((https?://[^\)]+)\)', caseSensitive: false),
    (m) {
      final width = (m[1] ?? '').trim();
      final src = (m[2] ?? '').trim();
      if (width.isEmpty) return '<img src="$src">';
      return '<img src="$src" width="$width">';
    },
  );

  // nested img link
  html = html.replaceAllMapped(
    RegExp(r'\[!\[([^\]]*?)\]\((https?://[^\)]+)\)\]\((https?://[^\)]+)\)'),
    (m) =>
        '<a href="${m[3] ?? ''}"><img src="${m[2] ?? ''}" alt="${m[1] ?? ''}"></a>',
  );

 
  html = html.replaceAllMapped(
    RegExp(r'!\[([^\]]*?)\]\((https?://[^\)]+)\)'),
    (m) => '<img src="${m[2] ?? ''}" alt="${m[1] ?? ''}">',
  );

  // Handle links md
  html = html.replaceAllMapped(
    RegExp(r'\[([^\]]+?)\]\((https?://[^\)]+)\)'),
    (m) => '<a href="${m[2] ?? ''}">${m[1] ?? ''}</a>',
  );

  // Handle  soiler
  html = html.replaceAllMapped(
    RegExp(r'~!([\s\S]*?)!~'),
    (m) => '<details><summary>Spoiler</summary>${m[1] ?? ''}</details>',
  );

  // Handle bold/italic markdown
  html = html.replaceAllMapped(
    RegExp(r'___([^\n]*?)___'),
    (m) => '<em><strong>${m[1] ?? ''}</strong></em>',
  );
  html = html.replaceAllMapped(
    RegExp(r'__(?!_)([^\n]*?)(?<!_)__'),
    (m) => '<strong>${m[1] ?? ''}</strong>',
  );
  html = html.replaceAllMapped(
    RegExp(r'\*\*([^\n]*?)\*\*'),
    (m) => '<strong>${m[1] ?? ''}</strong>',
  );

  // Decode  HTML entities
  html = html
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");

 
  html = html.replaceAllMapped(
    RegExp(r'(<img[^>]*>\s*(?:</a>)?)[ \t]*\n[ \t]*(?=(?:<a[^>]*>\s*)?<img)'),
    (m) =>
        '${m[1]}<div style="display:block;height:0;margin:0;padding:0;line-height:0"></div>',
  );

  html = html.replaceAll('\n', '<br>');

 
  html = html.replaceAll(RegExp(r'(<br\s*/?>\s*){3,}'), '<br><br>');

  return html;
}

class AnilistAboutMe extends StatefulWidget {
  final String about;

  const AnilistAboutMe({super.key, required this.about});

  @override
  State<AnilistAboutMe> createState() => _AnilistAboutMeState();
}

class _AnilistAboutMeState extends State<AnilistAboutMe> {
  late String _html;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _rebuildHtml();
  }

  @override
  void didUpdateWidget(covariant AnilistAboutMe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.about != widget.about) {
      _rebuildHtml();
    }
  }

  void _rebuildHtml() {
    try {
      _html = preprocessAnilistAbout(widget.about);
      _failed = false;
    } catch (_) {
      _html = widget.about;
      _failed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Text(
        widget.about,
        style: TextStyle(
          fontSize: 13.5,
          color: context.theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final contentMaxWidth = viewportWidth >= 1200
            ? 760.0
            : viewportWidth >= 900
                ? 680.0
                : viewportWidth;

        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: HtmlWidget(
              _html,
              factoryBuilder: () => _AnilistWidgetFactory(),
              textStyle: TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: context.theme.colorScheme.onSurfaceVariant,
                fontFamily: 'Poppins',
                fontFamilyFallback: const [
                  'Apple Color Emoji',
                  'Segoe UI Emoji',
                  'Noto Color Emoji'
                ],
              ),
              onTapUrl: (url) async => _openUrl(url),
              onErrorBuilder: (_, __, ___) => const SizedBox.shrink(),
              customStylesBuilder: (element) {
                return switch (element.localName) {
                  'br' => const {'line-height': '15px'},
                  'i' || 'em' => const {'font-style': 'italic'},
                  'b' || 'strong' => const {'font-weight': '600'},
                  'a' => const {'text-decoration': 'none'},
                  'center' => const {'text-align': 'center'},
                  'img' => {
                      'max-width': '100%',
                      'height': 'auto',
                      if (element.attributes['width'] != null)
                        'width': element.attributes['width']!,
                    },
                  'video' => const {
                      'max-width': '100%',
                      'height': 'auto',
                    },
                  'h1' => const {'font-size': '20px', 'font-weight': '700'},
                  'h2' => const {'font-size': '18px', 'font-weight': '700'},
                  'h3' => const {'font-size': '16px', 'font-weight': '700'},
                  'h4' => const {'font-size': '14px', 'font-weight': '700'},
                  'h5' => const {'font-size': '13px', 'font-weight': '700'},
                  'blockquote' => {
                      'border-left':
                          '3px solid ${_toRgba(context.theme.colorScheme.primary)}',
                      'padding': '8px 12px',
                      'margin': '4px 0',
                      'background-color': _toRgba(
                        context.theme.colorScheme.primary.withOpacity(0.07),
                      ),
                    },
                  'hr' => {
                      'border': 'none',
                      'border-bottom':
                          '1px solid ${_toRgba(context.theme.colorScheme.outlineVariant.withOpacity(0.5))}',
                      'margin': '12px 0',
                    },
                  _ => const {},
                };
              },
              customWidgetBuilder: (element) {
                // Spoiler tag
                if (element.localName == 'details') {
                  final body = element.innerHtml
                      .replaceAll(
                        RegExp(r'<summary>[\s\S]*?</summary>',
                            caseSensitive: false),
                        '',
                      )
                      .trim();
                  return AnilistSpoilerWidget(
                    child: AnilistAboutMe(about: body),
                  );
                }

                // Yt tag
                if (element.localName == 'youtube') {
                  final id = (element.attributes['id'] ?? element.text).trim();
                  if (id.isEmpty) return null;
                  return AnilistYouTubePlayer(videoId: id);
                }

                // Video tag
                if (element.localName == 'video') {
                  var src = '';
                  final direct = (element.attributes['src'] ?? '').trim();
                  if (direct.isNotEmpty) {
                    src = direct;
                  } else {
                    for (final child in element.children) {
                      if (child.localName == 'source') {
                        final value = (child.attributes['src'] ?? '').trim();
                        if (value.isNotEmpty) {
                          src = value;
                          break;
                        }
                      }
                    }
                  }
                  if (src.isNotEmpty) {
                    return AnilistWebmPlayer(url: src);
                  }
                }

                // Iframe 
                if (element.localName == 'iframe') {
                  final src = (element.attributes['src'] ?? '').trim();
                  if (src.isNotEmpty) {
                    // yt iframe
                    final ytId = RegExp(
                      r'(?:youtube\.com/embed/|youtube\.com/watch\?v=)([0-9A-Za-z_-]{11})',
                    ).firstMatch(src)?.group(1);
                    if (ytId != null) {
                      return AnilistYouTubePlayer(videoId: ytId);
                    }
                    // Check for Spotify iframe
                    if (src.contains('spotify.com')) {
                      return AnilistExternalTile(
                        url: src,
                        icon: Icons.music_note_rounded,
                        color: const Color(0xFF1DB954),
                        title: 'Spotify',
                        subtitle: 'Tap to open in Spotify',
                      );
                    }
                    return AnilistExternalTile(
                      url: src,
                      icon: Icons.open_in_new_rounded,
                      color: context.theme.colorScheme.primary,
                      title: 'Embedded content',
                      subtitle: 'Tap to open',
                    );
                  }
                }

                // <a> tag — handle AniList media cards
                if (element.localName == 'a') {
                  final href = (element.attributes['href'] ?? '').trim();
                  if (href.isEmpty) return null;

                  // AniList anime/manga link → render as card
                  final mediaMatch = RegExp(
                    r'anilist\.co/(anime|manga)/(\d+)',
                  ).firstMatch(href);
                  if (mediaMatch != null) {
                    final type = mediaMatch.group(1) ?? 'anime';
                    final id = int.tryParse(mediaMatch.group(2) ?? '');
                    if (id != null) {
                     
                      var isCentered = false;
                      var parent = element.parent;
                      while (parent != null) {
                        if (parent.localName == 'center') {
                          isCentered = true;
                          break;
                        }
                        parent = parent.parent;
                      }
                      return _AnilistMediaCard(
                        id: id,
                        type: type,
                        centered: isCentered,
                      );
                    }
                  }
                }

                return null;
              },
            ),
          ),
        );
      },
    );
  }

  Future<bool> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return true;

    // YouTube links
    final ytId = RegExp(
      r'(?:youtube\.com/(?:watch\?v=|shorts/|embed/)|youtu\.be/)([0-9A-Za-z_-]{11})',
    ).firstMatch(url)?.group(1);
    if (ytId != null && ytId.isNotEmpty) {
      await launchUrl(
        Uri.parse('https://www.youtube.com/watch?v=$ytId'),
        mode: LaunchMode.externalApplication,
      );
      return true;
    }

    // AniList media links (anime/manga)
    final mediaMatch =
        RegExp(r'anilist\.co/(anime|manga)/(\d+)').firstMatch(url);
    if (mediaMatch != null) {
      final type = mediaMatch.group(1) ?? 'anime';
      final id = int.tryParse(mediaMatch.group(2) ?? '');
      if (id != null) {
        await _openAnilistMedia(id, type);
        return true;
      }
    }

    // AniList user links (by ID)
    final userIdMatch = RegExp(r'anilist\.co/user/(\d+)').firstMatch(url);
    if (userIdMatch != null) {
      final id = int.tryParse(userIdMatch.group(1) ?? '');
      if (id != null) {
        final currentUserId = Get.find<ServiceHandler>().profileData.value.id;
        if (id.toString() == currentUserId) {
          navigateWithSlide(() => const ProfilePage());
        } else {
          navigateWithSlide(() => UserProfilePage(userId: id));
        }
        return true;
      }
    }

    // AniList user links
    final userNameMatch =
        RegExp(r'anilist\.co/user/([^/?#]+)', caseSensitive: false)
            .firstMatch(url);
    if (userNameMatch != null) {
      final name = Uri.decodeComponent(userNameMatch.group(1)!);
      final id = await Get.find<AnilistAuth>().fetchUserIdByName(name);
      if (id != null) {
        final currentUserId = Get.find<ServiceHandler>().profileData.value.id;
        if (id.toString() == currentUserId) {
          navigateWithSlide(() => const ProfilePage());
        } else {
          navigateWithSlide(() => UserProfilePage(userId: id));
        }
        return true;
      }
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return true;
  }

  Future<void> _openAnilistMedia(int id, String type) async {
    final handler = Get.find<ServiceHandler>();
    final data = await handler.anilistService.fetchDetails(
      FetchDetailsParams(
        id: id.toString(),
        isManga: type == 'manga',
      ),
    );

    final heroTag = 'about-$type-$id-${DateTime.now().microsecondsSinceEpoch}';
    if (type == 'manga') {
      navigate(() => MangaDetailsPage(media: data, tag: heroTag));
    } else {
      navigate(() => AnimeDetailsPage(media: data, tag: heroTag));
    }
  }

  String _toRgba(Color color) {
    return 'rgba(${color.red}, ${color.green}, ${color.blue}, ${color.opacity.toStringAsFixed(2)})';
  }
}

class _AnilistMediaCard extends StatefulWidget {
  final int id;
  final String type;
  final bool centered;
  const _AnilistMediaCard({
    required this.id,
    required this.type,
    this.centered = false,
  });

  @override
  State<_AnilistMediaCard> createState() => _AnilistMediaCardState();
}

class _AnilistMediaCardState extends State<_AnilistMediaCard> {
  Future<dynamic>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = Get.find<ServiceHandler>().anilistService.fetchDetails(
          FetchDetailsParams(
            id: widget.id.toString(),
            isManga: widget.type == 'manga',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data;
        final isDesktop = MediaQuery.of(context).size.width > 600;

        return GestureDetector(
          onTap: () {
            final tag =
                'card-${widget.type}-${widget.id}-${DateTime.now().microsecondsSinceEpoch}';
            if (widget.type == 'manga') {
              navigate(() => MangaDetailsPage(media: data, tag: tag));
            } else {
              navigate(() => AnimeDetailsPage(media: data, tag: tag));
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Align(
              alignment:
                  widget.centered ? Alignment.center : Alignment.centerLeft,
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
                                data.title?.isNotEmpty == true
                                    ? data.title
                                    : (data.romajiTitle ?? 'Unknown'),
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
                                '${widget.type.capitalizeFirst} \u2022 ${data.status ?? "Unknown"}',
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

class _AnilistWidgetFactory extends WidgetFactory {
  @override
  Widget? buildImageWidget(BuildTree meta, ImageSource src) {
    final url = src.url;
    if (url.isEmpty) return super.buildImageWidget(meta, src);

    return _SmartImageWidget(
      url: url,
      width: src.width,
      height: src.height,
    );
  }
}

class _SmartImageWidget extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;

  const _SmartImageWidget({
    required this.url,
    this.width,
    this.height,
  });

  @override
  State<_SmartImageWidget> createState() => _SmartImageWidgetState();
}

class _SmartImageWidgetState extends State<_SmartImageWidget> {
  bool _useFallback = false;
  double _webViewHeight = 0;

  @override
  Widget build(BuildContext context) {
    if (_useFallback) {
      return _buildFallback(context);
    }

    return CachedNetworkImage(
      imageUrl: widget.url,
      width: widget.width,
      height: widget.height,
      fit: BoxFit.contain,
      errorWidget: (_, __, ___) {
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _useFallback = true);
        });
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFallback(BuildContext context) {
    // Desktop
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return AnilistExternalTile(
        url: widget.url,
        icon: Icons.open_in_new_rounded,
        color: context.theme.colorScheme.primary,
        title: 'Dynamic Widget',
        subtitle: 'Tap to view in browser',
      );
    }

    // Mobile
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _webViewHeight,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: InAppWebView(
        initialData: InAppWebViewInitialData(
          data: '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: transparent; overflow: hidden; }
    img { max-width: 100%; height: auto; display: block; }
  </style>
</head>
<body>
  <img src="${widget.url}" onload="window.flutter_inappwebview.callHandler('onHeight', document.body.scrollHeight);" onerror="window.flutter_inappwebview.callHandler('onHeight', 0);" />
</body>
</html>
''',
        ),
        initialSettings: InAppWebViewSettings(
          transparentBackground: true,
          disableVerticalScroll: true,
          disableHorizontalScroll: true,
          supportZoom: false,
          javaScriptEnabled: true,
        ),
        onWebViewCreated: (controller) {
          controller.addJavaScriptHandler(
            handlerName: 'onHeight',
            callback: (args) {
              final h = (args.firstOrNull as num?)?.toDouble() ?? 0;
              if (h > 0 && mounted) {
                setState(() => _webViewHeight = h);
              }
            },
          );
        },
        onLoadStop: (controller, url) async {
          // Fallback
          final h = await controller.evaluateJavascript(
            source: 'document.body.scrollHeight',
          );
          final height = (h as num?)?.toDouble() ?? 0;
          if (height > 0 && mounted && _webViewHeight == 0) {
            setState(() => _webViewHeight = height);
          }
        },
      ),
    );
  }
}
