import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/community_service.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/screens/community/user_recommendations_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/recommend_sheet.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ReasonsSheet extends StatefulWidget {
  final CommunityMedia item;
  final ItemType mediaItemType;
  final String? voteMediaType;
  final String? voteMediaId;

  const ReasonsSheet({
    super.key,
    required this.item,
    required this.mediaItemType,
    this.voteMediaType,
    this.voteMediaId,
  });

  static void show(
    BuildContext context, {
    required CommunityMedia item,
    required ItemType mediaItemType,
    String? voteMediaType,
    String? voteMediaId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReasonsSheet(
        item: item,
        mediaItemType: mediaItemType,
        voteMediaType: voteMediaType,
        voteMediaId: voteMediaId,
      ),
    );
  }

  @override
  State<ReasonsSheet> createState() => _ReasonsSheetState();
}

class _ReasonsSheetState extends State<ReasonsSheet> {
  // Admin check
  bool _isAdmin = false;
  bool _adminLoading = true;

  // Vote state
  VoteResult? _votes;
  String? _userVote;
  bool _voteLoading = false;

  ServiceHandler get _sh => Get.find<ServiceHandler>();

  @override
  void initState() {
    super.initState();
    _runAdminCheck();
    if (CommunityService.votingEnabled &&
        widget.voteMediaType != null &&
        widget.voteMediaId != null) {
      _loadVotes();
    }
  }

  // ─────────────────────────────────────────────
  // Current-user helpers
  // ─────────────────────────────────────────────

  int? get _myId {
    final profile = _sh.profileData.value;
    return int.tryParse(profile.id ?? '');
  }

  ServicesType get _serviceType => _sh.serviceType.value;

  bool _isMyReason(ReasonEntry reason) {
    final myId = _myId;
    if (myId == null) return false;
    return reason.userIdFor(_serviceType) == myId;
  }

  bool get _hasMyReason {
    return widget.item.reasons.any(_isMyReason);
  }

  // ─────────────────────────────────────────────
  // Admin check
  // ─────────────────────────────────────────────

  Future<void> _runAdminCheck() async {
    final profile = _sh.profileData.value;
    final isAdmin = await CommunityService.checkIsAdmin(
      serviceType: _serviceType,
      profile: profile,
    );
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _adminLoading = false;
    });
  }

  // ─────────────────────────────────────────────
  // Voting
  // ─────────────────────────────────────────────

  Future<void> _loadVotes() async {
    final profile = _sh.profileData.value;
    int? anilistId;
    int? malId;
    int? simklId;

    if (_serviceType == ServicesType.anilist) {
      anilistId = int.tryParse(profile.id ?? '');
    } else if (_serviceType == ServicesType.mal) {
      malId = int.tryParse(profile.id ?? '');
    } else if (_serviceType == ServicesType.simkl) {
      simklId = int.tryParse(profile.id ?? '');
    }

    final result = await CommunityService.fetchVotes(
      widget.voteMediaType!,
      widget.voteMediaId!,
      anilistUserId: anilistId,
      malUserId: malId,
      simklUserId: simklId,
    );
    if (mounted) {
      setState(() {
        _votes = result;
        if (result != null) _userVote = result.userVote;
      });
    }
  }

  Future<void> _castVote(String direction) async {
    if (_voteLoading) return;

    final profile = _sh.profileData.value;
    int? anilistId;
    int? malId;
    int? simklId;
    String displayName = 'User';

    if (_serviceType == ServicesType.anilist) {
      anilistId = int.tryParse(profile.id ?? '');
      displayName = profile.name ?? 'User';
    } else if (_serviceType == ServicesType.mal) {
      malId = int.tryParse(profile.id ?? '');
      displayName = profile.name ?? 'User';
    } else if (_serviceType == ServicesType.simkl) {
      simklId = int.tryParse(profile.id ?? '');
      displayName = profile.name ?? 'User';
    }

    if (anilistId == null && malId == null && simklId == null) return;

    setState(() => _voteLoading = true);

    final result = await CommunityService.castVote(
      mediaType: widget.voteMediaType!,
      mediaId: widget.voteMediaId!,
      direction: direction,
      anilistUserId: anilistId,
      malUserId: malId,
      simklUserId: simklId,
      displayName: displayName,
    );

    if (mounted) {
      setState(() {
        _voteLoading = false;
        if (result != null) {
          _votes = result;
          _userVote = result.userVote;
        }
      });
    }
  }

  // ─────────────────────────────────────────────
  // Edit / Delete
  // ─────────────────────────────────────────────

  Future<void> _editReason(ReasonEntry reason) async {
    final controller = TextEditingController(text: reason.text);
    final colors = Theme.of(context).colorScheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: MediaQuery.of(ctx).viewInsets,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            color: colors.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colors.onSurfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.edit_rounded,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text('Edit Reason',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: colors.onSurface)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 700,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Why are you recommending this? (min 30 chars)',
                    filled: true,
                    fillColor: colors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final newReason = controller.text.trim();
                      if (newReason.length < 30) {
                        warningSnackBar('Please write at least 30 characters');
                        return;
                      }
                      Navigator.of(ctx).pop();

                      final profile = _sh.profileData.value;
                      final error = await CommunityService.editReason(
                        mediaType: widget.voteMediaType ?? 'anime',
                        mediaId: widget.voteMediaId ??
                            widget.item.media.id.toString(),
                        newReason: newReason,
                        serviceType: _serviceType,
                        profile: profile,
                      );

                      if (!mounted) return;
                      if (error == null) {
                        successSnackBar('Reason updated!');
                      } else {
                        errorSnackBar(error);
                      }
                    },
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Save Changes'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _deleteReason() async {
    final colors = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reason?'),
        content: Text(
          _isAdmin
              ? 'This reason will be deleted immediately.'
              : 'Your deletion request will be sent to admins for review.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final profile = _sh.profileData.value;
    final (error, pending) = await CommunityService.deleteReasonWithStatus(
      mediaType: widget.voteMediaType ?? 'anime',
      mediaId: widget.voteMediaId ?? widget.item.media.id.toString(),
      serviceType: _serviceType,
      profile: profile,
      isAdmin: _isAdmin,
    );

    if (!mounted) return;
    if (error == null) {
      if (pending) {
        successSnackBar('Deletion request sent to admins for review.');
      } else {
        successSnackBar('Reason deleted.');
      }
      Navigator.of(context).pop();
    } else {
      errorSnackBar(error);
    }
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final reasons = widget.item.reasons;
    final showVoteBar = CommunityService.votingEnabled &&
        widget.voteMediaType != null &&
        widget.voteMediaId != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.93,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              _buildDragHandle(colors),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildHeader(colors),
              ),
              const SizedBox(height: 16),
              // Reasons list
              Expanded(
                child: reasons.isEmpty
                    ? _buildEmptyState(colors)
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: reasons.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: index < reasons.length - 1 ? 10 : 0),
                            child:
                                _buildReasonCard(colors, reasons[index], index),
                          );
                        },
                      ),
              ),
              // Bottom section: vote bar + add button
              if (showVoteBar || !_hasMyReason)
                _buildBottomSection(colors, bottomPadding, showVoteBar),
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
    final item = widget.item;
    final posterUrl = item.media.poster;
    final title = item.displayTitle;
    final count = item.reasonCount;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AnymeXImage(
            imageUrl: posterUrl,
            width: 40,
            height: 56,
            radius: 8,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnymexText(
                text: title,
                variant: TextVariant.bold,
                size: 14,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              AnymexText(
                text:
                    count == 1 ? '1 Recommendation' : '$count Recommendations',
                size: 12,
                color: colors.onSurfaceVariant,
                variant: TextVariant.semiBold,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rate_review_outlined,
                size: 48, color: colors.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 16),
            AnymexText(
              text: 'No recommendations yet',
              size: 14,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            AnymexText(
              text: 'Be the first to recommend this title!',
              size: 12,
              color: colors.onSurfaceVariant.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonCard(ColorScheme colors, ReasonEntry reason, int index) {
    final isMine = _isMyReason(reason);
    final canEditOrDelete = isMine || (_isAdmin && !_adminLoading);

    final serviceType = _serviceType;
    final username = reason.usernameFor(serviceType) ?? 'Unknown';
    final avatarUrl = reason.avatarFor(serviceType);
    final fallbackLetter =
        username.trim().isNotEmpty ? username.trim()[0] : '?';

    // Navigate to THIS reason author's profile (not the entry-level author)
    void navigateProfile() {
      if (reason.user != null) {
        navigateToReasonAuthorProfile(reason, serviceType);
      }
    }

    void navigateUserRecs() {
      if (reason.user != null) {
        navigate(() => UserRecommendationsPage(user: reason.user!));
      }
    }

    final hasValidProfile = reason.user?.userIdFor(serviceType) != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMine
            ? colors.primaryContainer.withOpacity(0.25)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border:
            isMine ? Border.all(color: colors.primary.withOpacity(0.2)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              // Avatar
              _ReasonAvatar(
                avatarUrl: avatarUrl,
                fallbackLetter: fallbackLetter,
                size: 36,
              ),
              const SizedBox(width: 10),
              // Username + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: hasValidProfile ? navigateProfile : null,
                      onLongPress: reason.user != null ? navigateUserRecs : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: AnymexText(
                              text: username,
                              variant: TextVariant.semiBold,
                              size: 13,
                              color:
                                  hasValidProfile ? colors.primary : colors.onSurface,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (reason.user?.isAdmin == true) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified_rounded,
                                size: 14, color: colors.primary),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (reason.addedAt != null) ...[
                          AnymexText(
                            text: _formatDate(reason.addedAt!),
                            size: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ],
                        if (reason.editedAt != null) ...[
                          if (reason.addedAt != null) const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: colors.outlineVariant, width: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: AnymexText(
                              text: 'Edited',
                              size: 9,
                              color: colors.onSurfaceVariant,
                              variant: TextVariant.semiBold,
                            ),
                          ),
                        ],
                        if (isMine) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: AnymexText(
                              text: 'You',
                              size: 9,
                              color: colors.primary,
                              variant: TextVariant.semiBold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Reason text
          if (reason.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              reason.text,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: colors.onSurface,
                height: 1.5,
              ),
            ),
          ],
          // Edit / Delete buttons
          if (canEditOrDelete) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _editReason(reason),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded,
                              size: 14, color: colors.onSurfaceVariant),
                          const SizedBox(width: 3),
                          AnymexText(
                            text: 'Edit',
                            size: 11,
                            color: colors.onSurfaceVariant,
                            variant: TextVariant.semiBold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _deleteReason,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 14, color: colors.error),
                          const SizedBox(width: 3),
                          AnymexText(
                            text: 'Delete',
                            size: 11,
                            color: colors.error,
                            variant: TextVariant.semiBold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomSection(
      ColorScheme colors, double bottomPadding, bool showVoteBar) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withOpacity(0.3)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Vote bar
          if (showVoteBar) ...[
            _buildVoteBar(colors),
            if (!_hasMyReason) const SizedBox(height: 10),
          ],
          // Add recommendation button
          if (!_hasMyReason)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  RecommendSheet.show(
                    context,
                    widget.item.media,
                    widget.mediaItemType,
                    existingEntry: widget.item.rawJson,
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Your Recommendation'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVoteBar(ColorScheme colors) {
    final upvotes = _votes?.upvotes ?? 0;
    final downvotes = _votes?.downvotes ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.opaque(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: _voteLoading
          ? Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              ),
            )
          : Row(
              children: [
                AnymexText(
                  text: 'Was this helpful?',
                  size: 13,
                  color: colors.onSurfaceVariant,
                  variant: TextVariant.semiBold,
                ),
                const Spacer(),
                _ReasonsVoteButton(
                  icon: Icons.thumb_up_rounded,
                  count: upvotes,
                  active: _userVote == 'up',
                  isUpvote: true,
                  onTap: () => _castVote('up'),
                ),
                const SizedBox(width: 12),
                _ReasonsVoteButton(
                  icon: Icons.thumb_down_rounded,
                  count: downvotes,
                  active: _userVote == 'down',
                  isUpvote: false,
                  onTap: () => _castVote('down'),
                ),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────
  // Date formatting
  // ─────────────────────────────────────────────

  String _formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('MMM d, yyyy').format(dateTime);
    } catch (_) {
      return isoString;
    }
  }
}

// ─────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────

class _ReasonAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String fallbackLetter;
  final double size;

  const _ReasonAvatar({
    required this.avatarUrl,
    required this.fallbackLetter,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? AnymeXImage(
              imageUrl: avatarUrl!,
              width: size,
              height: size,
              radius: size / 2,
            )
          : Center(
              child: Text(
                fallbackLetter.toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.44,
                  fontWeight: FontWeight.w700,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
    );
  }
}

class _ReasonsVoteButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool active;
  final bool isUpvote;
  final VoidCallback onTap;

  const _ReasonsVoteButton({
    required this.icon,
    required this.count,
    required this.active,
    required this.isUpvote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final activeColor = isUpvote ? colors.primary : colors.error;
    final activeBgColor = isUpvote
        ? colors.primary.opaque(0.15, iReallyMeanIt: true)
        : colors.error.opaque(0.15, iReallyMeanIt: true);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? activeBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border:
                active ? Border.all(color: activeColor.withOpacity(0.2)) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: active ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Icon(
                  icon,
                  size: 18,
                  color: active ? activeColor : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              AnymexText(
                text: '$count',
                size: 13,
                color: active ? activeColor : colors.onSurfaceVariant,
                variant: TextVariant.semiBold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
