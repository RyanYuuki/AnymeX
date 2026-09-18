import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/comments/model/comment.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_decorated_avatar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/linked_accounts_badges.dart';
import 'package:anymex/widgets/anymex_widgets/discord_badge_widget.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class UserCommentsSheet {
  static void show(
    BuildContext context, {
    required Comment comment,
    required CommentSectionController controller,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colorScheme = Theme.of(context).colorScheme;
        final currentUserId = Get.find<ServiceHandler>().profileData.value.id;
        final isSelf = comment.userId == currentUserId;

        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.88,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header with Decorated Avatar, Username, Tier, and View Profile Button
                  Row(
                    children: [
                      AnymeXDecoratedAvatar(
                        avatarUrl: comment.avatarUrl,
                        decorationUrl: comment.avatarDecoration,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: AnymeXText(
                                    comment.username,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (comment.badges != null && comment.badges!.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  DiscordBadgesRow(badges: comment.badges, size: 16.0),
                                ],
                                if (comment.linkedAccounts?.isNotEmpty == true) ...[
                                  const SizedBox(width: 6),
                                  LinkedAccountsBadges(
                                    linkedAccounts: comment.linkedAccounts,
                                    fontSize: 8.5,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (comment.userTier != null && comment.userTier!.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: AnymeXText(
                                      comment.userTier!,
                                      size: 10,
                                      variant: TextVariant.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                if (comment.userPoints != null) ...[
                                  AnymeXText(
                                    '${comment.userPoints} pts',
                                    size: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ] else ...[
                                  AnymeXText(
                                    'Comments History',
                                    size: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          final parsedId = int.tryParse(comment.userId);
                          if (isSelf) {
                            navigate(() => const ProfilePage());
                          } else if (parsedId != null && parsedId > 0) {
                            navigate(() => UserProfilePage(userId: parsedId));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_outline, size: 14, color: colorScheme.primary),
                              const SizedBox(width: 4),
                              AnymeXText(
                                'Profile',
                                size: 12,
                                variant: TextVariant.bold,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                  const SizedBox(height: 8),

                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>?>(
                      future: controller.getUserHistoryFromDb(comment.userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: ExpressiveLoadingIndicator(),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data == null) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline, size: 40, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                const SizedBox(height: 8),
                                AnymeXText('Failed to load comments.', color: colorScheme.onSurfaceVariant),
                              ],
                            ),
                          );
                        }

                        final data = snapshot.data!;
                        final history = data['history'] as List<dynamic>? ?? [];

                        final comments = history.where((e) {
                          final action = (e as Map<String, dynamic>)['action']?.toString() ?? '';
                          return action == 'comment';
                        }).toList();

                        if (comments.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.comment_outlined, size: 40, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                                const SizedBox(height: 8),
                                AnymeXText('No comments found.', color: colorScheme.onSurfaceVariant),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: comments.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.15)),
                          itemBuilder: (context, index) {
                            final entry = comments[index] as Map<String, dynamic>;
                            final content = entry['content']?.toString() ?? '';
                            final mediaTitle = entry['media_title']?.toString() ?? '';
                            final timestamp = entry['created_at']?.toString() ?? '';
                            final deleted = entry['deleted'] == true;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (deleted)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colorScheme.error.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: AnymeXText('DELETED',
                                              color: colorScheme.error,
                                              size: 10,
                                              variant: TextVariant.bold),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: AnymeXText('COMMENT',
                                              color: colorScheme.primary,
                                              size: 10,
                                              variant: TextVariant.bold),
                                        ),
                                      const Spacer(),
                                      if (timestamp.isNotEmpty)
                                        AnymeXText(
                                          _formatDate(timestamp),
                                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                          size: 10,
                                        ),
                                    ],
                                  ),
                                  if (content.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    AnymeXText(
                                      content,
                                      size: 13,
                                      color: deleted
                                          ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                                          : colorScheme.onSurface,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (mediaTitle.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.movie_outlined, size: 12, color: colorScheme.primary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: AnymeXText(
                                            'On: $mediaTitle',
                                            size: 11,
                                            color: colorScheme.primary,
                                            variant: TextVariant.semiBold,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('MMM d, y • h:mm a').format(dateTime);
    } catch (_) {
      return isoString;
    }
  }
}
