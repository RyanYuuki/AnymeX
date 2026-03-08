import 'dart:convert';

import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/anime/widgets/custom_list_dialog.dart';
import 'package:anymex/screens/anime/widgets/list_editor.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:hugeicons/hugeicons.dart';

class MediaPeekPopup extends StatefulWidget {
  final Media media;
  final ItemType type;
  final String tag;

  const MediaPeekPopup({
    super.key,
    required this.media,
    required this.type,
    required this.tag,
  });

  static void show(BuildContext context, Media media, ItemType type, String tag) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      showDragHandle: false,
      builder: (_) => MediaPeekPopup(media: media, type: type, tag: tag),
    );
  }

  @override
  State<MediaPeekPopup> createState() => _MediaPeekPopupState();
}

class _MediaPeekPopupState extends State<MediaPeekPopup> {
  _PeekData? _data;
  bool _loading = true;
  bool _synopsisExpanded = false;

  static const int _synopsisMaxLines = 4;

  late final RxString _animeStatus;
  late final RxDouble _animeScore;
  late final RxInt _animeProgress;
  late final Rx<TrackedMedia?> _currentMedia;

  @override
  void initState() {
    super.initState();
    _fetchPeekData();
    _initTrackingState();
  }

  void _initTrackingState() {
    final isManga = widget.type == ItemType.manga;
    final service = widget.media.serviceType.onlineService;
    service.setCurrentMedia(widget.media.id.toString(), isManga: isManga);
    final tracked = service.currentMedia.value;
    _currentMedia = service.currentMedia;
    _animeStatus = (tracked.watchingStatus ?? '').obs;
    _animeScore = (tracked.score?.toDouble() ?? 0.0).obs;
    _animeProgress = (isManga
            ? (tracked.chapterCount?.toInt() ?? 0)
            : (tracked.episodeCount?.toInt() ?? 0))
        .obs;
  }

  Future<void> _fetchPeekData() async {
    try {
      final result = await _fetchFromAnilist(widget.media.id);
      if (mounted) {
        setState(() {
          _data = result;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<_PeekData> _fetchFromAnilist(String id) async {
    const query = r'''
      query($id: Int) {
        Media(id: $id) {
          description
          synonyms
          genres
          tags { name }
        }
      }
    ''';

    final token = AuthKeys.authToken.get<String?>();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('https://graphql.anilist.co/'),
      headers: headers,
      body: jsonEncode({'query': query, 'variables': {'id': int.tryParse(id)}}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final m = body['data']['Media'] as Map<String, dynamic>;
      final rawDesc = (m['description'] as String?) ?? '';
      final description = parse(rawDesc).body?.text ?? rawDesc;
      final synonyms = (m['synonyms'] as List?)?.cast<String>() ?? [];
      final genres = (m['genres'] as List?)?.cast<String>() ?? [];
      final tags = ((m['tags'] as List?) ?? [])
          .map((t) => t['name'] as String)
          .toList();
      return _PeekData(
        description: description,
        synonyms: synonyms,
        genres: genres,
        tags: tags,
      );
    }
    return _PeekData(description: '', synonyms: [], genres: [], tags: []);
  }

  void _openLibraryDialog() {
    showCustomListDialog(context, widget.media);
  }

  void _openListEditor() {
    final isManga = widget.type == ItemType.manga;
    final fetcher = widget.media.serviceType;

    showModalBottomSheet(
      backgroundColor: context.colors.surfaceContainer,
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext ctx) {
        return ListEditorModal(
          animeStatus: _animeStatus,
          isManga: isManga,
          animeScore: _animeScore,
          animeProgress: _animeProgress,
          currentAnime: _currentMedia,
          media: widget.media,
          onUpdate: (id, score, status, progress) async {
            final listId = fetcher.onlineService.currentMedia.value.id
                ?? widget.media.id;
            fetcher.onlineService.updateListEntry(UpdateListEntryParams(
              listId: listId,
              isAnime: !isManga,
              score: score,
              status: status,
              progress: progress,
            ));
            _currentMedia.value?.score = score.toString();
            _currentMedia.value?.watchingStatus = status;
            if (isManga) {
              _currentMedia.value?.chapterCount = progress.toString();
            } else {
              _currentMedia.value?.episodeCount = progress.toString();
            }
            _animeStatus.value = status;
            _animeScore.value = score;
            _animeProgress.value = progress;
          },
          onDelete: (s) async {
            final listId = fetcher.onlineService.currentMedia.value.mediaListId
                ?? widget.media.id;
            await fetcher.onlineService.deleteListEntry(listId, isAnime: !isManga);
            _animeStatus.value = '';
          },
        );
      },
    );
  }

  void _openFullView() {
    Navigator.of(context).pop();
    if (widget.type == ItemType.manga) {
      navigate(() => MangaDetailsPage(media: widget.media, tag: widget.tag));
    } else {
      navigate(() => AnimeDetailsPage(media: widget.media, tag: widget.tag));
    }
  }

  bool get _isLoggedIn {
    try {
      final anilist = Get.find<AnilistData>();
      return anilist.isLoggedIn.value;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final screenHeight = MediaQuery.of(context).size.height;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildDragHandle(colors),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(colors),
                      const SizedBox(height: 16),
                      _buildActionButtons(colors),
                      const SizedBox(height: 20),
                      _loading ? _buildSkeleton() : _buildContent(colors),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: widget.tag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.multiplyRoundness()),
            child: AnymeXImage(
              imageUrl: widget.media.poster,
              width: 90,
              height: 130,
              radius: 12,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnymexText(
                text: widget.media.title,
                variant: TextVariant.bold,
                size: 15,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.media.romajiTitle.isNotEmpty &&
                  widget.media.romajiTitle != widget.media.title) ...[
                const SizedBox(height: 4),
                AnymexText(
                  text: widget.media.romajiTitle,
                  variant: TextVariant.regular,
                  size: 12,
                  color: colors.onSurfaceVariant,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              _buildMetaRow(colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(ColorScheme colors) {
    final items = <Widget>[];

    if (widget.media.rating.isNotEmpty && widget.media.rating != '?' && widget.media.rating != '0.0') {
      items.add(_buildMetaBadge(
        icons: Icons.star_rounded,
        label: widget.media.rating,
        color: Colors.amber,
        colors: colors,
      ));
    }

    if (widget.media.format.isNotEmpty && widget.media.format != '?') {
      items.add(_buildMetaBadge(
        icons: Icons.category_rounded,
        label: widget.media.format.replaceAll('_', ' '),
        color: colors.primary,
        colors: colors,
      ));
    }

    if (widget.media.status.isNotEmpty && widget.media.status != '?') {
      items.add(_buildMetaBadge(
        icons: Icons.circle,
        label: widget.media.status,
        color: widget.media.status.contains('RELEASING') || widget.media.status.contains('ONGOING')
            ? Colors.green
            : colors.secondary,
        colors: colors,
      ));
    }

    return Wrap(spacing: 6, runSpacing: 6, children: items);
  }

  Widget _buildMetaBadge({
    required IconData icons,
    required String label,
    required Color color,
    required ColorScheme colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icons, size: 11, color: color),
          const SizedBox(width: 4),
          AnymexText(text: label, size: 11, color: color, variant: TextVariant.semiBold),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final gap = 8.0;
        final iconBtnWidth = 50.0;
        final numIconBtns = _isLoggedIn ? 1 : 0;
        final numIconBtnGaps = numIconBtns > 0 ? numIconBtns : 0;
        final expandedWidth = (available
                - (numIconBtns * iconBtnWidth)
                - (numIconBtnGaps * gap)
                - gap)
            .clamp(0.0, available);

        return Row(
          children: [
            SizedBox(
              width: expandedWidth / 2,
              child: _DetailsStyleButton(
                onTap: _openFullView,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_new_rounded, color: colors.onSurface, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.type == ItemType.anime ? 'Watch' : 'Read',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: gap),
            SizedBox(
              width: expandedWidth / 2,
              child: _DetailsStyleButton(
                onTap: _openLibraryDialog,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(HugeIcons.strokeRoundedLibrary, color: colors.onSurface, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Add to Library',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoggedIn) ...[
              SizedBox(width: gap),
              Obx(() => SizedBox(
                width: iconBtnWidth,
                child: _DetailsStyleButton(
                  onTap: _openListEditor,
                  child: Icon(Icons.edit_note_rounded, color: colors.primary, size: 22),
                ),
              )),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 14,
            width: i == 3 ? 120 : double.infinity,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colors) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.description.isNotEmpty) ...[
          _buildSectionLabel('Synopsis', colors),
          const SizedBox(height: 8),
          _buildSynopsis(data.description, colors),
          const SizedBox(height: 20),
        ],
        if (data.synonyms.isNotEmpty) ...[
          _buildSectionLabel('Synonyms', colors),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: data.synonyms
                .map((s) => _buildTag(s, colors.surfaceContainerHigh, colors.onSurface, colors))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (data.genres.isNotEmpty) ...[
          _buildSectionLabel('Genres', colors),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: data.genres
                .map((g) => _buildTag(g, colors.primaryContainer, colors.onPrimaryContainer, colors))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (data.tags.isNotEmpty) ...[
          _buildSectionLabel('Tags', colors),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: data.tags
                .take(20)
                .map((t) => _buildTag(t, colors.secondaryContainer, colors.onSecondaryContainer, colors))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(String label, ColorScheme colors) {
    return AnymexText(
      text: label,
      variant: TextVariant.bold,
      size: 13,
      color: colors.primary,
    );
  }

  Widget _buildSynopsis(String text, ColorScheme colors) {
    return LayoutBuilder(builder: (context, constraints) {
      final span = TextSpan(
        text: text,
        style: TextStyle(fontSize: 13, color: colors.onSurface, height: 1.5),
      );
      final tp = TextPainter(
        text: span,
        maxLines: _synopsisMaxLines,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: constraints.maxWidth);
      final overflows = tp.didExceedMaxLines;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnymexText(
            text: text,
            size: 13,
            maxLines: _synopsisExpanded ? null : _synopsisMaxLines,
            overflow: _synopsisExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            color: colors.onSurface,
          ),
          if (overflows || _synopsisExpanded) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _synopsisExpanded = !_synopsisExpanded),
              child: AnymexText(
                text: _synopsisExpanded ? 'Show Less' : 'Read More',
                size: 12,
                color: colors.primary,
                variant: TextVariant.semiBold,
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildTag(String label, Color bg, Color fg, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnymexText(text: label, size: 12, color: fg, variant: TextVariant.semiBold),
    );
  }
}

class _DetailsStyleButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _DetailsStyleButton({
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.opaque(0.2),
        ),
        color: Theme.of(context).colorScheme.surfaceContainer.opaque(0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
      ),
    );
  }
}

class _PeekData {
  final String description;
  final List<String> synonyms;
  final List<String> genres;
  final List<String> tags;

  _PeekData({
    required this.description,
    required this.synonyms,
    required this.genres,
    required this.tags,
  });
}
