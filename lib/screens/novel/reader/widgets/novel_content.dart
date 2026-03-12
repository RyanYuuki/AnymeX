import 'dart:convert';
import 'dart:io';
import 'package:anymex/screens/novel/reader/controller/reader_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:html/dom.dart' as dom;

class NovelContentWidget extends StatefulWidget {
  final NovelReaderController controller;

  const NovelContentWidget({
    super.key,
    required this.controller,
  });

  @override
  State<NovelContentWidget> createState() => _NovelContentWidgetState();
}

class _NovelContentWidgetState extends State<NovelContentWidget> {
  DateTime? _lastDragEnd;
  final Map<int, GlobalKey> _paragraphKeys = {};

  bool get _isDragRecent {
    if (_lastDragEnd == null) return false;
    return DateTime.now().difference(_lastDragEnd!).inMilliseconds < 350;
  }

  void _onDragEnd() => _lastDragEnd = DateTime.now();

  void _openDictionary(String word) {
    if (word.trim().isEmpty) return;
    ContextMenuController.removeAny();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DictionarySheet(word: word.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      contextMenuBuilder: (context, selectableRegionState) {
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: selectableRegionState.contextMenuAnchors,
          buttonItems: [
            ...selectableRegionState.contextMenuButtonItems,
            ContextMenuButtonItem(
              label: 'Dictionary',
              onPressed: () async {
                selectableRegionState
                    .copySelection(SelectionChangedCause.toolbar);
                await Future.delayed(const Duration(milliseconds: 100));
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                _openDictionary(data?.text ?? '');
              },
            ),
          ],
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_isDragRecent) return;
          HapticFeedback.lightImpact();
          widget.controller.toggleControls();
        },
        onVerticalDragEnd: (details) {
          _onDragEnd();
          if (widget.controller.swipeGestures.value) {
            if (details.primaryVelocity != null) {
              final isScrollingDown = details.primaryVelocity! < 0;
              final scrollPosition =
                  widget.controller.scrollController.offset;
              final maxScroll =
                  widget.controller.scrollController.hasClients
                      ? widget.controller.scrollController.position
                          .maxScrollExtent
                      : 0;

              if (isScrollingDown && scrollPosition >= maxScroll - 50) {
                if (widget.controller.canGoNext.value) {
                  widget.controller.goToNextChapter();
                }
              } else if (!isScrollingDown && scrollPosition <= 50) {
                if (widget.controller.canGoPrevious.value) {
                  widget.controller.goToPreviousChapter();
                }
              }
            }
          }
        },
        onHorizontalDragEnd: (details) {
          _onDragEnd();
          widget.controller.handleSwipe(details, true);
        },
        child: Container(
          color: Colors.transparent,
          child: SafeArea(
            child: Obx(() {
              if (widget.controller.loadingState.value ==
                  LoadingState.loading) {
                return _buildLoadingState(context);
              }

              if (widget.controller.loadingState.value ==
                      LoadingState.error ||
                  widget.controller.novelContent.value.isEmpty) {
                return _buildEmptyState(context);
              }

              return _buildContent(context);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExpressiveLoadingIndicator(
            color: context.colors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading chapter...',
            style: TextStyle(
              color: context.colors.onSurface.opaque(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 48,
            color: context.colors.onSurface.opaque(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No content available',
            style: TextStyle(
              fontSize: 18,
              color: context.colors.onSurface.opaque(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {}
        return false;
      },
      child: CustomScrollView(
        controller: widget.controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          Obx(() {
            return SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.controller.paddingHorizontal.value,
                vertical: widget.controller.paddingVertical.value,
              ),
              sliver: HtmlWidget(
                widget.controller.novelContent.value,
                rebuildTriggers: [
                  widget.controller.showControls.value,
                  widget.controller.fontSize.value,
                  widget.controller.lineHeight.value,
                  widget.controller.letterSpacing.value,
                  widget.controller.wordSpacing.value,
                  widget.controller.paragraphSpacing.value,
                  widget.controller.fontFamily.value,
                  widget.controller.textAlign.value,
                  widget.controller.themeMode.value,
                  widget.controller.backgroundOpacity.value,
                  widget.controller.paddingHorizontal.value,
                  widget.controller.paddingVertical.value,
                  widget.controller.ttsHighlightedElement.value,
                  widget.controller.ttsCurrentWordStart.value,
                  widget.controller.ttsCurrentWordEnd.value,
                ],
                renderMode: RenderMode.sliverList,
                textStyle: _getBaseTextStyle(context),
                customWidgetBuilder: (element) =>
                    _getCustomWidget(element, context),
                enableCaching: true,
                customStylesBuilder: (element) =>
                    _getCustomStyles(element, context),
                onLoadingBuilder: (context, element, loadingProgress) =>
                    const SizedBox.shrink(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget? _getCustomWidget(dom.Element element, BuildContext context) {
    if (element.localName?.toLowerCase() == 'img') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: AnymeXImage(
          imageUrl: element.attributes['src']!,
          fit: BoxFit.contain,
          radius: 8,
        ),
      );
    }
    return null;
  }

  TextStyle _getBaseTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: widget.controller.fontSize.value,
      height: widget.controller.lineHeight.value,
      color: widget.controller.useSystemReaderTheme
          ? Theme.of(context).textTheme.bodyLarge?.color
          : widget.controller.readerTextColor,
      fontFamily: widget.controller.fontFamilyName.isEmpty
          ? null
          : widget.controller.fontFamilyName,
      letterSpacing: widget.controller.letterSpacing.value,
      wordSpacing: widget.controller.wordSpacing.value,
    );
  }

  Map<String, String>? _getCustomStyles(
      dom.Element element, BuildContext context) {
    final Map<String, String> styles = {};

    switch (element.localName?.toLowerCase()) {
      case 'body':
        styles['margin'] = '0';
        styles['padding'] = '0';
        break;

      case 'p':
        styles['margin-bottom'] =
            '${widget.controller.paragraphSpacing.value}px';
        styles['margin-top'] = '0';
        styles['margin-left'] = '0';
        styles['margin-right'] = '0';
        styles['padding'] = '0';
        styles['text-align'] = _getTextAlignmentString();

        if (widget.controller.ttsEnabled.value &&
            widget.controller.ttsHighlightedElement.value >= 0 &&
            widget.controller.ttsHighlightedElement.value <
                widget.controller.ttsSegments.length) {
          
          String elementText = element.text?.trim() ?? '';
          String currentSegment = widget.controller
              .ttsSegments[widget.controller.ttsHighlightedElement.value];
          
          if (elementText == currentSegment) {
            int wordStart = widget.controller.ttsCurrentWordStart.value;
            int wordEnd = widget.controller.ttsCurrentWordEnd.value;
            
            if (wordStart < wordEnd && wordStart >= 0 && wordEnd <= elementText.length) {
              styles['background-image'] = 
                  'linear-gradient(90deg, '
                  'transparent 0, '
                  'transparent ${wordStart}ch, '
                  '#${context.colors.primary.withOpacity(0.3).value.toRadixString(16).padLeft(8, '0')} ${wordStart}ch, '
                  '#${context.colors.primary.withOpacity(0.3).value.toRadixString(16).padLeft(8, '0')} ${wordEnd}ch, '
                  'transparent ${wordEnd}ch, '
                  'transparent 100%)';
            } else {
              styles['background-color'] =
                  '#${context.colors.primary.withOpacity(0.3).value.toRadixString(16).padLeft(8, '0')}';
            }
            styles['border-radius'] = '4px';
          }
        }
        break;

      case 'div':
        styles['margin-bottom'] =
            '${widget.controller.paragraphSpacing.value / 2}px';
        styles['margin-top'] = '0';
        styles['padding'] = '0';
        styles['text-align'] = _getTextAlignmentString();
        break;

      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        styles['margin-top'] =
            '${widget.controller.paragraphSpacing.value * 1.5}px';
        styles['margin-bottom'] =
            '${widget.controller.paragraphSpacing.value}px';
        styles['font-weight'] = 'bold';
        styles['text-align'] = _getTextAlignmentString();
        break;

      case 'br':
        styles['display'] = 'block';
        styles['content'] = '""';
        styles['margin'] =
            '${widget.controller.paragraphSpacing.value / 4}px 0';
        break;

      case 'span':
        styles['margin'] = '0';
        styles['padding'] = '0';
        break;

      case 'ul':
      case 'ol':
        styles['margin-bottom'] =
            '${widget.controller.paragraphSpacing.value}px';
        styles['padding-left'] = '24px';
        break;

      case 'li':
        styles['margin-bottom'] =
            '${widget.controller.paragraphSpacing.value / 3}px';
        styles['text-align'] = _getTextAlignmentString();
        break;

      case 'blockquote':
        styles['margin'] =
            '${widget.controller.paragraphSpacing.value}px 24px';
        styles['padding'] = '8px 16px';
        styles['border-left'] =
            '4px solid #${context.colors.primary.value.toRadixString(16).padLeft(8, '0')}';
        styles['background'] =
            '#${context.colors.surfaceContainerHighest.opaque(0.3).value.toRadixString(16).padLeft(8, '0')}';
        styles['font-style'] = 'italic';
        break;

      case 'pre':
      case 'code':
        styles['margin'] = '${widget.controller.paragraphSpacing.value}px 0';
        styles['padding'] = '16px';
        styles['background'] =
            '#${context.colors.surfaceContainerHighest.opaque(0.5).value.toRadixString(16).padLeft(8, '0')}';
        styles['border-radius'] = '8px';
        styles['font-family'] = 'monospace';
        styles['overflow-x'] = 'auto';
        break;
    }

    return styles.isNotEmpty ? styles : null;
  }

  String _getTextAlignmentString() {
    switch (widget.controller.textAlignment) {
      case TextAlign.left:
        return 'left';
      case TextAlign.right:
        return 'right';
      case TextAlign.center:
        return 'center';
      case TextAlign.justify:
        return 'justify';
      default:
        return 'left';
    }
  }
}

class _DictionarySheet extends StatefulWidget {
  final String word;
  const _DictionarySheet({required this.word});

  @override
  State<_DictionarySheet> createState() => _DictionarySheetState();
}

class _DictionarySheetState extends State<_DictionarySheet> {
  bool _loading = true;
  String? _error;
  List<_DictEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  Future<void> _lookup() async {
    try {
      final uri = Uri.parse(
          'https://api.dictionaryapi.dev/api/v2/entries/en/${Uri.encodeComponent(widget.word)}');
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(const Utf8Decoder()).join();
      client.close();

      if (response.statusCode == 200) {
        final data = jsonDecode(body) as List;
        final entries = <_DictEntry>[];
        for (final item in data) {
          for (final meaning in (item['meanings'] as List? ?? [])) {
            final pos = meaning['partOfSpeech'] as String? ?? '';
            for (final def in (meaning['definitions'] as List? ?? []).take(2)) {
              entries.add(_DictEntry(
                partOfSpeech: pos,
                definition: def['definition'] as String? ?? '',
                example: def['example'] as String?,
              ));
            }
          }
        }
        if (mounted) {
          setState(() {
            _entries = entries;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'No definition found for "${widget.word}"';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not reach dictionary. Check your connection.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.word,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text(_error!, style: TextStyle(color: colors.error))
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _entries.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, i) {
                  final e = _entries[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.partOfSpeech,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(e.definition,
                          style: const TextStyle(fontSize: 15)),
                      if (e.example != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '"${e.example}"',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: colors.onSurface.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DictEntry {
  final String partOfSpeech;
  final String definition;
  final String? example;
  const _DictEntry(
      {required this.partOfSpeech,
      required this.definition,
      this.example});
}
