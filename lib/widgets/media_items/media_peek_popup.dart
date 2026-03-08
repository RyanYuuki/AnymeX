import 'dart:convert';

import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
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
  bool _addingToList = false;

  static const int _synopsisMaxLines = 4;

  @override
  void initState() {
    super.initState();
    _fetchPeekData();
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

  Future<void> _addToList() async {
    setState(() => _addingToList = true);
    try {
      final service = serviceHandler.serviceType.value.onlineService;
      await service.updateListEntry(UpdateListEntryParams(
        listId: widget.media.id,
        isAnime: widget.type == ItemType.anime,
        status: 'PLANNING',
        score: 0,
        progress: 0,
      ));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Added "${widget.media.title}" to Planning'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _addingToList = false);
    }
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
    return Row(
      children: [
        if (_isLoggedIn) ...[
          Expanded(
            child: _ActionButton(
              onTap: _addingToList ? null : _addToList,
              color: colors.primary,
              icon: _addingToList
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  : Icon(Icons.add_rounded, color: colors.onPrimary, size: 18),
              label: 'Add to List',
              textColor: colors.onPrimary,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: _ActionButton(
            onTap: _openFullView,
            color: colors.secondaryContainer,
            icon: Icon(Icons.open_in_new_rounded, color: colors.onSecondaryContainer, size: 18),
            label: widget.type == ItemType.anime ? 'Watch' : 'Read',
            textColor: colors.onSecondaryContainer,
          ),
        ),
      ],
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

class _ActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color color;
  final Widget icon;
  final String label;
  final Color textColor;

  const _ActionButton({
    required this.onTap,
    required this.color,
    required this.icon,
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12.multiplyRoundness()),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              AnymexText(
                text: label,
                size: 13,
                color: textColor,
                variant: TextVariant.semiBold,
              ),
            ],
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

  _PeekData({
    required this.description,
    required this.synonyms,
    required this.genres,
    required this.tags,
  });
}
