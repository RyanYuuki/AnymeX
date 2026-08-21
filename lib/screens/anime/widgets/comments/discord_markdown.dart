import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------------------
// DiscordMarkdown – main renderer
// ---------------------------------------------------------------------------

/// Discord-style markdown renderer for comment text.
///
/// Parses bold, italic, strikethrough, inline spoiler, code, blockquotes,
/// auto-linked URLs (including image thumbnails), and @mentions using a custom
/// inline parser that builds a [RichText] from regex-matched segments.
class DiscordMarkdown extends StatelessWidget {
  const DiscordMarkdown({
    super.key,
    required this.text,
    required this.colorScheme,
    required this.baseStyle,
    this.fontSize = 16,
  });

  final String text;
  final ColorScheme colorScheme;
  final TextStyle baseStyle;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');

    // Collect image URLs that should render as thumbnails below text.
    final imageUrls = <String>[];
    for (final line in lines) {
      imageUrls.addAll(_extractImageUrls(line));
    }

    final nonEmptyLines = lines.where((l) => l.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (nonEmptyLines.isEmpty)
          const SizedBox.shrink()
        else
          ...nonEmptyLines.map((line) {
            if (line.trimLeft().startsWith('>')) {
              return _buildBlockquote(line, context);
            }
            return _buildInlineText(line, context);
          }),
        if (imageUrls.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: imageUrls
                .map((url) => _ImageThumbnail(
                      url: url,
                      colorScheme: colorScheme,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildBlockquote(String line, BuildContext context) {
    String content = line;
    int quoteLevel = 0;
    while (content.trimLeft().startsWith('>')) {
      content = content.replaceFirst(RegExp(r'^\s*>\s?'), '');
      quoteLevel++;
    }

    final indent = 12.0 + (quoteLevel - 1) * 8.0;
    final spans = _parseInlineSpans(content, context);

    return Padding(
      padding: EdgeInsets.only(left: indent, top: 4, bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              width: 3,
            ),
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: RichText(
          text: TextSpan(
            style: baseStyle.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: fontSize,
            ),
            children: spans,
          ),
        ),
      ),
    );
  }

  Widget _buildInlineText(String line, BuildContext context) {
    final spans = _parseInlineSpans(line, context);
    return RichText(
      text: TextSpan(
        style: baseStyle.copyWith(
          color: colorScheme.onSurface,
          fontSize: fontSize,
        ),
        children: spans,
      ),
    );
  }

  /// Parses all inline markdown patterns from [text] into a flat list of
  /// [InlineSpan]s. Spoilers produce [WidgetSpan] wrapping [InlineSpoiler].
  List<InlineSpan> _parseInlineSpans(String text, BuildContext context) {
    final placeholders = <String, InlineSpan>{};
    int placeholderCounter = 0;

    String replaceWithPlaceholder(
      String input,
      RegExp regex,
      InlineSpan Function(RegExpMatch) builder,
    ) {
      final result = StringBuffer();
      int lastEnd = 0;
      for (final match in regex.allMatches(input)) {
        result.write(input.substring(lastEnd, match.start));
        final key = '\x00$placeholderCounter\x00';
        placeholderCounter++;
        placeholders[key] = builder(match);
        result.write(key);
        lastEnd = match.end;
      }
      result.write(input.substring(lastEnd));
      return result.toString();
    }

    // 1. Spoiler: ||text||
    String processed = replaceWithPlaceholder(
      text,
      RegExp(r'\|\|(.+?)\|\|'),
      (match) => WidgetSpan(
        child: InlineSpoiler(
          colorScheme: colorScheme,
          child: RichText(
            text: TextSpan(
              style: baseStyle.copyWith(
                color: colorScheme.onSurface,
                fontSize: fontSize,
              ),
              children: _parseInlineSpans(match.group(1)!, context),
            ),
          ),
        ),
        alignment: PlaceholderAlignment.middle,
      ),
    );

    // 2. Inline code: `text`
    processed = replaceWithPlaceholder(
      processed,
      RegExp(r'`([^`]+)`'),
      (match) => TextSpan(
        text: match.group(1)!,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize * 0.9,
          backgroundColor:
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          color: colorScheme.onSurface,
        ),
      ),
    );

    // 3. Bold + Italic combined: ***text*** or ___text___
    processed = replaceWithPlaceholder(
      processed,
      RegExp(r'\*\*\*(.+?)\*\*\*|___(.+?)___'),
      (match) => TextSpan(
        text: (match.group(1) ?? match.group(2))!,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
      ),
    );

    // 4. Bold: **text** or __text__
    processed = replaceWithPlaceholder(
      processed,
      RegExp(r'\*\*(.+?)\*\*|__(.+?)__'),
      (match) => TextSpan(
        text: (match.group(1) ?? match.group(2))!,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );

    // 5. Italic: *text* or _text_
    processed = replaceWithPlaceholder(
      processed,
      RegExp(r'(?<!\w)\*([^*\n]+?)\*(?!\w)|(?<!\w)_([^_\n]+?)_(?!\w)'),
      (match) => TextSpan(
        text: (match.group(1) ?? match.group(2))!,
        style: const TextStyle(fontStyle: FontStyle.italic),
      ),
    );

    // 6. Strikethrough: ~~text~~
    processed = replaceWithPlaceholder(
      processed,
      RegExp(r'~~(.+?)~~'),
      (match) => TextSpan(
        text: match.group(1)!,
        style: TextStyle(
          decoration: TextDecoration.lineThrough,
          decorationColor: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );

    // 7. @mentions
    processed = replaceWithPlaceholder(
      processed,
      RegExp(r'@(\w{1,32})'),
      (match) => TextSpan(
        text: match.group(0)!,
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    // 8. URLs
    processed = replaceWithPlaceholder(
      processed,
      RegExp(r'(https?:\/\/[^\s<>"{}|\\^`\[\]]+)'),
      (match) {
        final url = match.group(1)!;
        return TextSpan(
          text: url,
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: _isImageUrl(url) ? fontSize * 0.85 : null,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _openUrl(url),
        );
      },
    );

    // Rebuild the span list from the processed string + placeholders.
    final spans = <InlineSpan>[];
    final placeholderPattern = RegExp(r'\x00(\d+)\x00');
    int lastEnd = 0;

    for (final match in placeholderPattern.allMatches(processed)) {
      if (match.start > lastEnd) {
        final literal = processed.substring(lastEnd, match.start);
        if (literal.isNotEmpty) {
          spans.add(TextSpan(text: literal));
        }
      }
      final key = '\x00${match.group(1)!}\x00';
      spans.add(placeholders[key]!);
      lastEnd = match.end;
    }
    if (lastEnd < processed.length) {
      final tail = processed.substring(lastEnd);
      if (tail.isNotEmpty) {
        spans.add(TextSpan(text: tail));
      }
    }

    return spans;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.webm') ||
        lower.contains('giphy.com') ||
        lower.contains('tenor.com') ||
        lower.contains('media.tenor.co') ||
        lower.contains('media.giphy.com');
  }

  static List<String> _extractImageUrls(String line) {
    final urls = <String>[];
    final urlPattern = RegExp(r'(https?:\/\/[^\s<>"{}|\\^`\[\]]+)');
    for (final match in urlPattern.allMatches(line)) {
      if (_isImageUrl(match.group(1)!)) {
        urls.add(match.group(1)!);
      }
    }
    return urls;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ---------------------------------------------------------------------------
// InlineSpoiler – reusable tap-to-reveal spoiler widget
// ---------------------------------------------------------------------------

/// A blurred overlay that the user taps to reveal the hidden content.
///
/// Used for Discord-style `||spoiler||` inline text.
class InlineSpoiler extends StatefulWidget {
  const InlineSpoiler({
    super.key,
    required this.colorScheme,
    required this.child,
    this.revealDuration = const Duration(milliseconds: 300),
  });

  final ColorScheme colorScheme;
  final Widget child;
  final Duration revealDuration;

  @override
  State<InlineSpoiler> createState() => _InlineSpoilerState();
}

class _InlineSpoilerState extends State<InlineSpoiler>
    with SingleTickerProviderStateMixin {
  bool _revealed = false;
  late AnimationController _controller;
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.revealDuration,
    );
    _blurAnimation = Tween<double>(begin: 5.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() {
      _revealed = !_revealed;
      if (_revealed) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final blur = _blurAnimation.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: !_revealed
                  ? widget.colorScheme.onSurface.withValues(alpha: 0.25)
                  : widget.colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: blur,
                  sigmaY: blur,
                ),
                enabled: blur > 0.1,
                child: Opacity(
                  opacity: _revealed ? 1.0 : 0.0,
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ImageThumbnail – inline image preview with full-size viewer
// ---------------------------------------------------------------------------

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({
    required this.url,
    required this.colorScheme,
    this.maxHeight = 200.0,
    this.maxWidth = 280.0,
  });

  final String url;
  final ColorScheme colorScheme;
  final double maxHeight;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: maxWidth,
        ),
        child: GestureDetector(
          onTap: () => _openFullSizeViewer(context),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 100,
              width: 150,
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 60,
              width: 120,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: colorScheme.error.withValues(alpha: 0.6),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullSizeViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(
          imageUrls: [url],
          initialIndex: 0,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FullScreenImageViewer – photo_view powered gallery
// ---------------------------------------------------------------------------

class _FullScreenImageViewer extends StatefulWidget {
  const _FullScreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: widget.imageUrls.length > 1
            ? Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: const TextStyle(fontSize: 14),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.launch_outlined, size: 20),
            tooltip: 'Open in browser',
            onPressed: () async {
              final uri = Uri.parse(widget.imageUrls[_currentIndex]);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            Navigator.of(context).pop();
          }
        },
        child: PhotoViewGallery.builder(
          pageController: _pageController,
          itemCount: widget.imageUrls.length,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider:
                  CachedNetworkImageProvider(widget.imageUrls[index]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              initialScale: PhotoViewComputedScale.contained,
              heroAttributes:
                  PhotoViewHeroAttributes(tag: widget.imageUrls[index]),
              errorBuilder: (_, __, ___) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load image',
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            );
          },
          scrollPhysics: const BouncingScrollPhysics(),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MarkdownFormattingToolbar – composer toolbar
// ---------------------------------------------------------------------------

/// A horizontal row of formatting buttons that wrap selected text inside a
/// [TextEditingController] with Discord-style markdown syntax.
class MarkdownFormattingToolbar extends StatelessWidget {
  const MarkdownFormattingToolbar({
    super.key,
    required this.controller,
    required this.colorScheme,
    this.onSpoilerTap,
  });

  final TextEditingController controller;
  final ColorScheme colorScheme;
  final VoidCallback? onSpoilerTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarButton(
              label: 'Bold',
              child: Text(
                'B',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              colorScheme: colorScheme,
              onTap: () => _wrapSelection('**', '**'),
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              label: 'Italic',
              child: Text(
                'I',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              colorScheme: colorScheme,
              onTap: () => _wrapSelection('*', '*'),
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              label: 'Strikethrough',
              child: Text(
                'S',
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  decorationColor:
                      colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              colorScheme: colorScheme,
              onTap: () => _wrapSelection('~~', '~~'),
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              label: 'Code',
              child: Text(
                '< >',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: colorScheme.onSurface,
                ),
              ),
              colorScheme: colorScheme,
              onTap: () => _wrapSelection('`', '`'),
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              label: 'Spoiler',
              child: Text(
                '||S||',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              colorScheme: colorScheme,
              onTap: onSpoilerTap ?? () => _wrapSelection('||', '||'),
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              label: 'Image URL',
              child: const Text(
                '\u{1F5BC}',
                style: TextStyle(fontSize: 16),
              ),
              colorScheme: colorScheme,
              onTap: _insertImageTemplate,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Text manipulation helpers
  // ---------------------------------------------------------------------------

  void _wrapSelection(String prefix, String suffix) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.start;
    final end = selection.end;

    if (start < 0 || end < 0) return;

    final selectedText = text.substring(start, end);
    final hasSelection = selectedText.isNotEmpty;

    final replacement =
        hasSelection ? '$prefix$selectedText$suffix' : '$prefix$suffix';

    controller.text = text.replaceRange(start, end, replacement);

    if (hasSelection) {
      controller.selection = TextSelection(
        baseOffset: start + prefix.length,
        extentOffset: start + prefix.length + selectedText.length,
      );
    } else {
      controller.selection =
          TextSelection.collapsed(offset: start + prefix.length);
    }
  }

  void _insertImageTemplate() {
    final text = controller.text;
    final selection = controller.selection;
    final offset =
        selection.baseOffset >= 0 ? selection.baseOffset : text.length;

    const template = 'https://';
    controller.text = text.replaceRange(offset, offset, template);
    controller.selection =
        TextSelection.collapsed(offset: offset + template.length);
  }
}

// ---------------------------------------------------------------------------
// _ToolbarButton – individual formatting button
// ---------------------------------------------------------------------------

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.child,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final Widget child;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
