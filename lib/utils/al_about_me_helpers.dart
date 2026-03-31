import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AnilistSpoilerWidget extends StatefulWidget {
  final Widget child;
  const AnilistSpoilerWidget({super.key, required this.child});

  @override
  State<AnilistSpoilerWidget> createState() => _AnilistSpoilerWidgetState();
}

class _AnilistSpoilerWidgetState extends State<AnilistSpoilerWidget> {
  bool _open = false;

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
      clipBehavior: Clip.hardEdge,
      child: _open ? _buildRevealed(context) : _buildHidden(context),
    );
  }

  Widget _buildHidden(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _open = true),
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
            onPressed: () => setState(() => _open = false),
          ),
        ),
      ],
    );
  }
}

class AnilistYouTubePlayer extends StatefulWidget {
  final String videoId;
  const AnilistYouTubePlayer({super.key, required this.videoId});

  @override
  State<AnilistYouTubePlayer> createState() => _AnilistYouTubePlayerState();
}

class _AnilistYouTubePlayerState extends State<AnilistYouTubePlayer> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    if (_isPlaying) {
      return _buildInlinePlayer();
    }
    return _buildThumbnail();
  }

  Widget _buildInlinePlayer() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
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
    allowfullscreen></iframe>
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

  Widget _buildThumbnail() {
    return GestureDetector(
      onTap: () {
        // Inline playback on mobile, external on desktop
        if (Platform.isAndroid || Platform.isIOS) {
          setState(() => _isPlaying = true);
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
          constraints: const BoxConstraints(maxWidth: 480),
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

class AnilistExternalTile extends StatelessWidget {
  final String url;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const AnilistExternalTile({
    super.key,
    required this.url,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

class AnilistWebmPlayer extends StatefulWidget {
  final String url;
  const AnilistWebmPlayer({super.key, required this.url});

  @override
  State<AnilistWebmPlayer> createState() => _AnilistWebmPlayerState();
}

class _AnilistWebmPlayerState extends State<AnilistWebmPlayer> {
  double _webViewHeight = 200;

  String _buildVideoHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background: transparent;
      overflow: hidden;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    video {
      max-width: 100%;
      height: auto;
      display: block;
      border-radius: 12px;
    }
  </style>
</head>
<body>
  <video autoplay loop muted playsinline>
    <source src="${widget.url}" type="video/webm">
  </video>
  <script>
    const video = document.querySelector('video');
    video.addEventListener('loadedmetadata', function() {
      window.flutter_inappwebview.callHandler('onVideoLoaded', video.videoWidth, video.videoHeight);
    });
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isLinux || Platform.isWindows) {
      return AnilistExternalTile(
        url: widget.url,
        icon: Icons.videocam_rounded,
        color: context.theme.colorScheme.primary,
        title: 'WebM Video',
        subtitle: 'Tap to open in browser',
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: _webViewHeight,
              child: InAppWebView(
                initialData: InAppWebViewInitialData(
                  data: _buildVideoHtml(),
                  mimeType: 'text/html',
                  encoding: 'utf-8',
                ),
                initialSettings: InAppWebViewSettings(
                  transparentBackground: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  disableHorizontalScroll: true,
                  disableVerticalScroll: true,
                  supportZoom: false,
                ),
                onWebViewCreated: (webController) {
                  webController.addJavaScriptHandler(
                    handlerName: 'onVideoLoaded',
                    callback: (args) {
                      if (args.length >= 2) {
                        final videoWidth = (args[0] as num).toDouble();
                        final videoHeight = (args[1] as num).toDouble();
                        if (videoWidth > 0 && videoHeight > 0) {
                          const containerWidth = 480.0;
                          final newHeight =
                              containerWidth * (videoHeight / videoWidth);
                          if (mounted) {
                            setState(() => _webViewHeight = newHeight);
                          }
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

