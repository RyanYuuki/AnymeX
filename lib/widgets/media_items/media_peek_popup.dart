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
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
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

  static void show(
      BuildContext context, Media media, ItemType type, String tag) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MediaPeekPopup(media: media, type: type, tag: tag),
    );
  }

  static void showIfUntracked(
    BuildContext context,
    Media? media,
    ItemType type,
    String tag,
  ) {
    if (media == null) return;
    if ((media.userStatus ?? '').isNotEmpty) return;
    show(context, media, type, tag);
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
    _animeScore = (double.tryParse(tracked.score ?? '') ?? 0.0).obs;
    _animeProgress = (int.tryParse(isManga
                ? (tracked.chapterCount ?? '')
                : (tracked.episodeCount ?? '')) ??
            0)
        .obs;
  }

  Future<void> _fetchPeekData() async {
    try {
      // Use the same fetchDetails the info page uses — works for all services
      final service = widget.media.serviceType.service;
      final details = await service
          .fetchDetails(FetchDetailsParams(id: widget.media.id.toString()));

      // Fetch synonyms + tags via AniList only (they live in AniList's schema)
      List<String> synonyms = [];
      List<String> tags = [];
      final isAniList = widget.media.serviceType == ServicesType.anilist ||
          widget.media.serviceType == ServicesType.extensions;
      if (isAniList) {
        final extra = await _fetchAnilistExtras(widget.media.id);
        synonyms = extra['synonyms'] ?? [];
        tags = extra['tags'] ?? [];
      }

      final rawDesc = details.description;
      final description = rawDesc == '?' || rawDesc.isEmpty
          ? ''
          : parse(rawDesc).body?.text ?? rawDesc;

      if (mounted) {
        setState(() {
          _data = _PeekData(
            description: description,
            synonyms: synonyms,
            genres: details.genres,
            tags: tags,
            status: details.status,
          );
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, List<String>>> _fetchAnilistExtras(String id) async {
    const query = r'''
      query($id: Int) {
        Media(id: $id) {
          synonyms
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
    try {
      final response = await http.post(
        Uri.parse('https://graphql.anilist.co/'),
        headers: headers,
        body: jsonEncode({
          'query': query,
          'variables': {'id': int.tryParse(id)}
        }),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final m = body['data']['Media'] as Map<String, dynamic>;
        return {
          'synonyms': (m['synonyms'] as List?)?.cast<String>() ?? [],
          'tags': ((m['tags'] as List?) ?? [])
              .map((t) => t['name'] as String)
              .toList(),
        };
      }
    } catch (_) {}
    return {'synonyms': [], 'tags': []};
  }

  void _openLibraryDialog() => showCustomListDialog(context, widget.media);

  void _openListEditor() {
    final isManga = widget.type == ItemType.manga;
    final fetcher = widget.media.serviceType;
    showModalBottomSheet(
      backgroundColor: context.colors.surfaceContainer,
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => ListEditorModal(
        animeStatus: _animeStatus,
        isManga: isManga,
        animeScore: _animeScore,
        animeProgress: _animeProgress,
        currentAnime: _currentMedia,
        media: widget.media,
        onUpdate: (id, score, status, progress, startedAt, completedAt,
            isPrivate) async {
          final listId =
              fetcher.onlineService.currentMedia.value.id ?? widget.media.id;
          fetcher.onlineService.updateListEntry(UpdateListEntryParams(
            listId: listId,
            isAnime: !isManga,
            score: score,
            status: status,
            progress: progress,
            startedAt: startedAt,
            completedAt: completedAt,
            isPrivate: isPrivate,
          ));
          _currentMedia.value?.score = score.toString();
          _currentMedia.value?.watchingStatus = status;
          if (isManga) {
            _currentMedia.value?.chapterCount = progress.toString();
          } else {
            _currentMedia.value?.episodeCount = progress.toString();
          }
          _currentMedia.value?.startedAt = startedAt;
          _currentMedia.value?.completedAt = completedAt;
          _currentMedia.value?.isPrivate = isPrivate;
          _animeStatus.value = status;
          _animeScore.value = score;
          _animeProgress.value = progress;
        },
        onDelete: (s) async {
          final listId = fetcher.onlineService.currentMedia.value.mediaListId ??
              widget.media.id;
          await fetcher.onlineService
              .deleteListEntry(listId, isAnime: !isManga);
          _animeStatus.value = '';
        },
      ),
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

  void _openSearchWithFilter({
    required String filterKey,
    required String value,
  }) {
    Navigator.of(context).pop();
    navigate(() => SearchPage(
          searchTerm: '',
          isManga: widget.type == ItemType.manga,
          initialFilters: {
            filterKey: [value]
          },
        ));
  }

  bool get _isLoggedIn {
    try {
      return Get.find<AnilistData>().isLoggedIn.value;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(colors),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(colors),
                      const SizedBox(height: 16),
                      _buildActionButtons(colors),
                      const SizedBox(height: 20),
                      _loading ? _buildSkeleton(colors) : _buildContent(colors),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(12.multiplyRadius()),
          child: AnymeXImage(
            imageUrl: widget.media.poster,
            width: 90,
            height: 130,
            radius: 12,
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
                  widget.media.romajiTitle != widget.media.title &&
                  widget.media.romajiTitle != '?') ...[
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

    final rating = widget.media.rating;
    if (rating.isNotEmpty &&
        rating != '?' &&
        rating != '0' &&
        rating != '0.0') {
      items.add(_buildMetaBadge(
          icon: Icons.star_rounded, label: rating, color: Colors.amber));
    }

    final format = widget.media.format;
    if (format.isNotEmpty && format != '?') {
      items.add(_buildMetaBadge(
          icon: Icons.category_rounded,
          label: format.replaceAll('_', ' '),
          color: colors.primary));
    }

    // Prefer the fetched status (accurate, service-specific),
    // fall back to widget.media.status while loading
    final rawStatus = (_data?.status.isNotEmpty == true)
        ? _data!.status
        : widget.media.status;
    final status = rawStatus;
    if (status.isNotEmpty && status != '?') {
      final upper = status.toUpperCase().replaceAll(' ', '_');
      final isAiring = upper.contains('RELEASING') ||
          upper.contains('ONGOING') ||
          upper.contains('AIRING');
      final label = _convertMediaStatus(upper);
      items.add(_buildMetaBadge(
          icon: Icons.circle,
          label: label,
          color: isAiring ? Colors.green : colors.secondary));
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 6, children: items);
  }

  String _convertMediaStatus(String status) {
    switch (status) {
      case 'RELEASING':
      case 'ONGOING':
      case 'AIRING':
        return 'Airing';
      case 'FINISHED':
      case 'FINISHED_AIRING':
        return 'Finished';
      case 'NOT_YET_RELEASED':
      case 'NOT_YET_AIRED':
        return 'Upcoming';
      case 'HIATUS':
        return 'On Hiatus';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  Widget _buildMetaBadge(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          AnymexText(
              text: label,
              size: 11,
              color: color,
              variant: TextVariant.semiBold),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colors) {
    return LayoutBuilder(builder: (context, constraints) {
      final available = constraints.maxWidth;
      const gap = 8.0;
      const iconBtnWidth = 50.0;

      // Layout: [Watch icon] [List Editor wide] [Library icon]
      // When not logged in: [Watch/Read wide] [Library icon]
      const fixedUsed = iconBtnWidth * 2 + gap * 2; // watch icon + library icon
      final listEditorW =
          _isLoggedIn ? (available - fixedUsed).clamp(0.0, available) : 0.0;
      final watchW = _isLoggedIn
          ? iconBtnWidth
          : (available - iconBtnWidth - gap).clamp(0.0, available);

      return Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Watch/Read — icon-only when logged in, wide with label when not
          SizedBox(
            width: watchW,
            child: _DetailsStyleButton(
              onTap: _openFullView,
              child: _isLoggedIn
                  ? Icon(
                      widget.type == ItemType.anime
                          ? Icons.play_arrow_rounded
                          : Icons.menu_book_rounded,
                      color: colors.onSurface,
                      size: 22,
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.type == ItemType.anime
                              ? Icons.play_arrow_rounded
                              : Icons.menu_book_rounded,
                          color: colors.onSurface,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.type == ItemType.anime ? 'Watch' : 'Read',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          // List Editor — wide with status label, logged in only
          if (_isLoggedIn) ...[
            const SizedBox(width: gap),
            SizedBox(
              width: listEditorW,
              child: _DetailsStyleButton(
                onTap: _openListEditor,
                child: Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_note_rounded,
                            color: colors.primary, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            convertAniListStatus(
                              _animeStatus.value,
                              isManga: widget.type == ItemType.manga,
                            ),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )),
              ),
            ),
          ],
          const SizedBox(width: gap),
          // Add to Library — icon only, always shown
          SizedBox(
            width: iconBtnWidth,
            child: _DetailsStyleButton(
              onTap: _openLibraryDialog,
              child: Icon(HugeIcons.strokeRoundedLibrary,
                  color: colors.onSurface, size: 20),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSkeleton(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(4, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 14,
            width: i == 3 ? 120 : double.infinity,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContent(ColorScheme colors) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.description.isNotEmpty) ...[
          _sectionLabel('Synopsis', colors),
          const SizedBox(height: 8),
          _buildSynopsis(data.description, colors),
          const SizedBox(height: 20),
        ],
        if (data.synonyms.isNotEmpty) ...[
          _sectionLabel('Synonyms', colors),
          const SizedBox(height: 8),
          _chipRow(
              data.synonyms, colors.surfaceContainerHigh, colors.onSurface),
          const SizedBox(height: 20),
        ],
        if (data.genres.isNotEmpty) ...[
          _sectionLabel('Genres', colors),
          const SizedBox(height: 8),
          _chipRow(
            data.genres,
            colors.primaryContainer,
            colors.onPrimaryContainer,
            onTap: (genre) =>
                _openSearchWithFilter(filterKey: 'genres', value: genre),
          ),
          const SizedBox(height: 20),
        ],
        if (data.tags.isNotEmpty) ...[
          _sectionLabel('Tags', colors),
          const SizedBox(height: 8),
          _chipRow(
            data.tags.take(20).toList(),
            colors.secondaryContainer,
            colors.onSecondaryContainer,
            onTap: (tag) =>
                _openSearchWithFilter(filterKey: 'tags', value: tag),
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String label, ColorScheme colors) {
    return AnymexText(
        text: label,
        variant: TextVariant.bold,
        size: 13,
        color: colors.primary);
  }

  Widget _buildSynopsis(String text, ColorScheme colors) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final tp = TextPainter(
        text: TextSpan(
            text: text, style: const TextStyle(fontSize: 13, height: 1.5)),
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
            overflow: _synopsisExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            color: colors.onSurface,
          ),
          if (overflows || _synopsisExpanded) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () =>
                  setState(() => _synopsisExpanded = !_synopsisExpanded),
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

  Widget _chipRow(
    List<String> items,
    Color bg,
    Color fg, {
    void Function(String value)? onTap,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.asMap().entries.map((e) {
          return Padding(
            padding: EdgeInsets.only(right: e.key < items.length - 1 ? 6 : 0),
            child: _chip(
              e.value,
              bg,
              fg,
              onTap: onTap == null ? null : () => onTap(e.value),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg, {VoidCallback? onTap}) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: AnymexText(
          text: label, size: 12, color: fg, variant: TextVariant.semiBold),
    );

    if (onTap == null) return chip;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: chip,
      ),
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
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 50,
      child: Material(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outline.withOpacity(0.2)),
            ),
            alignment: Alignment.center,
            child: child,
          ),
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
  final String status;

  _PeekData({
    required this.description,
    required this.synonyms,
    required this.genres,
    required this.tags,
    this.status = '',
  });
}
