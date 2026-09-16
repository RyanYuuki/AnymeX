import 'package:anymex/models/notification/announcement.dart';
import 'package:anymex/screens/anime/widgets/comments/discord_markdown.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Dedicated bottom sheet for announcements.
///
/// Shows ALL announcement information: title, category, pinned/featured
/// badges, author, publish date, view count and the full markdown content.
/// Opens from an announcement push notification tap or a notification-list
/// tap — never routed through the comment/media navigation flow.
class AnnouncementSheet extends StatefulWidget {
  final String announcementId;

  /// Used when the announcement id is unavailable (e.g. legacy pushes sent
  /// before the backend attached announcement_id): the sheet still opens and
  /// shows whatever the push itself carried.
  final String? fallbackTitle;
  final String? fallbackBody;

  const AnnouncementSheet({
    super.key,
    required this.announcementId,
    this.fallbackTitle,
    this.fallbackBody,
  });

  static Future<void> show(
    BuildContext context, {
    required String announcementId,
    String? fallbackTitle,
    String? fallbackBody,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnnouncementSheet(
        announcementId: announcementId,
        fallbackTitle: fallbackTitle,
        fallbackBody: fallbackBody,
      ),
    );
  }

  @override
  State<AnnouncementSheet> createState() => _AnnouncementSheetState();
}

class _AnnouncementSheetState extends State<AnnouncementSheet> {
  late Future<Announcement?> _future;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Announcement?> _load() async {
    try {
      // Legacy push without an id: show the push content immediately.
      if (widget.announcementId.isEmpty) return null;
      if (!Get.isRegistered<CommentumService>()) return null;
      final service = Get.find<CommentumService>();
      final announcement = await service.fetchAnnouncement(widget.announcementId);
      // Read receipt for dashboard stats — fire and forget, never blocks UI.
      if (announcement != null) {
        service.markAnnouncementRead('${announcement.id}', announcement.appId);
      } else {
        _loadFailed = true;
      }
      return announcement;
    } catch (e) {
      Logger.i('AnnouncementSheet load error: $e');
      _loadFailed = true;
      return null;
    }
  }

  void _retry() {
    setState(() {
      _loadFailed = false;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.85,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outline.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 3.5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: colors.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.campaign_rounded,
                      size: 22,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: AnymeXText(
                      'Announcement',
                      size: 16,
                      variant: TextVariant.semiBold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: FutureBuilder<Announcement?>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: colors.primary),
                      );
                    }

                    final announcement = snapshot.data;
                    if (announcement == null) {
                      return _buildFallback(context);
                    }

                    return _buildAnnouncementContent(context, announcement);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementContent(BuildContext context, Announcement announcement) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(context, announcement.category.toUpperCase(),
                  Colors.orange, Icons.campaign_outlined),
              if (announcement.pinned)
                _chip(context, 'PINNED', colors.primary, Icons.push_pin_rounded),
              if (announcement.featured)
                _chip(context, 'FEATURED', colors.tertiary, Icons.star_rounded),
            ],
          ),
          const SizedBox(height: 12),
          AnymeXText(
            announcement.title,
            size: 20,
            variant: TextVariant.bold,
            maxLines: 20,
            softWrap: true,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if ((announcement.authorName ?? '').isNotEmpty) ...[
                Icon(Icons.person_outline_rounded,
                    size: 14, color: colors.onSurface.withOpacity(0.5)),
                const SizedBox(width: 4),
                AnymeXText(
                  announcement.authorName!,
                  size: 12,
                  color: colors.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                AnymeXText('•',
                    size: 12, color: colors.onSurface.withOpacity(0.4)),
                const SizedBox(width: 6),
              ],
              Icon(Icons.schedule_rounded,
                  size: 14, color: colors.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              AnymeXText(
                announcement.publishedAt != null
                    ? timeago.format(announcement.publishedAt!)
                    : '',
                size: 12,
                color: colors.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              AnymeXText('•',
                  size: 12, color: colors.onSurface.withOpacity(0.4)),
              const SizedBox(width: 6),
              Icon(Icons.visibility_outlined,
                  size: 14, color: colors.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              AnymeXText(
                '${announcement.viewCount}',
                size: 12,
                color: colors.onSurface.withOpacity(0.6),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          DiscordMarkdown(
            text: _normalizeAnnouncementMarkdown(announcement.fullContent),
            colorScheme: colors,
            baseStyle: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// The dashboard editor writes Discord-flavored markdown (bold, italic,
  /// ||spoilers||, images, GIFs, links) plus headings and bullet lists that
  /// the comment renderer treats as plain text. Normalize those two into
  /// DiscordMarkdown-friendly lines so announcements match comment styling.
  String _normalizeAnnouncementMarkdown(String raw) {
    final out = <String>[];
    for (final line in raw.split('\n')) {
      final trimmed = line.trimLeft();
      final header = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(trimmed);
      if (header != null) {
        out.add('**${header.group(2)}**');
        continue;
      }
      final bullet = RegExp(r'^[-*+]\s+(.*)$').firstMatch(trimmed);
      if (bullet != null) {
        out.add('• ${bullet.group(1)}');
        continue;
      }
      out.add(line);
    }
    return out.join('\n');
  }

  Widget _chip(BuildContext context, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          AnymeXText(
            label,
            size: 11,
            variant: TextVariant.semiBold,
            color: color,
          ),
        ],
      ),
    );
  }

  /// Shown when the full announcement can't be loaded (no id in legacy push,
  /// network error, or deleted announcement). Falls back to the push content
  /// itself instead of mixing into the comments flow.
  Widget _buildFallback(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasFallback =
        (widget.fallbackTitle ?? widget.fallbackBody ?? '').isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasFallback) ...[
            AnymeXText(
              widget.fallbackTitle ?? 'Announcement',
              size: 20,
              variant: TextVariant.bold,
              maxLines: 20,
              softWrap: true,
            ),
            const SizedBox(height: 12),
            DiscordMarkdown(
              text: _normalizeAnnouncementMarkdown(widget.fallbackBody ?? ''),
              colorScheme: colors,
              baseStyle: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: colors.onSurface,
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(Icons.campaign_outlined,
                      size: 44, color: colors.onSurface.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  const AnymeXText('Announcement unavailable', size: 16,
                      variant: TextVariant.semiBold),
                  const SizedBox(height: 6),
                  AnymeXText(
                    _loadFailed
                        ? 'Could not load this announcement. Check your connection and try again.'
                        : 'This announcement is no longer available.',
                    size: 12,
                    color: colors.onSurface.withOpacity(0.6),
                    textAlign: TextAlign.center,
                  ),
                  if (_loadFailed) ...[
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const AnymeXText('Retry', size: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
