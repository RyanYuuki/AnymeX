import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Anilist/anilist_review.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/utils/al_about_me.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/markdown.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/review_composer_sheet.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReviewsSection extends StatefulWidget {
  final int mediaId;
  final String mediaType;
  final String? mediaTitle;

  const ReviewsSection({
    super.key,
    required this.mediaId,
    this.mediaType = 'ANIME',
    this.mediaTitle,
  });

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  final _auth = Get.find<AnilistAuth>();
  List<AnilistReview> _reviews = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final reviews = await _auth.fetchReviews(mediaId: widget.mediaId);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _rateReview(int reviewId, String rating) async {
    final success = await _auth.rateReview(reviewId, rating);
    if (success) {
      await _loadReviews();
    }
  }

  Future<void> _deleteReview(int reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.colors.surfaceContainer,
        title:
            const AnymexText(text: 'Delete Review?', variant: TextVariant.bold),
        content: const AnymexText(text: 'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text('Delete', style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await _auth.deleteReview(reviewId);
      if (success) {
        successSnackBar('Review deleted');
        await _loadReviews();
      } else {
        errorSnackBar('Failed to delete review');
      }
    }
  }

  Future<void> _writeReview() async {
    final result = await ReviewComposerSheet.show(
      context,
      mediaId: widget.mediaId,
      onSubmit: (summary, body, score, isPrivate) async {
        final review = await _auth.saveReview(
          mediaId: widget.mediaId,
          summary: summary,
          body: body,
          score: score,
          isPrivate: isPrivate,
        );
        return review != null;
      },
    );
    if (result == true) {
      successSnackBar('Review posted');
      await _loadReviews();
    }
  }

  Future<void> _editReview(AnilistReview review) async {
    final result = await ReviewComposerSheet.show(
      context,
      mediaId: widget.mediaId,
      initialSummary: review.summary,
      initialBody: review.body,
      initialScore: review.score,
      initialPrivate: review.isPrivate,
      onSubmit: (summary, body, score, isPrivate) async {
        final updated = await _auth.saveReview(
          reviewId: review.id,
          mediaId: widget.mediaId,
          summary: summary,
          body: body,
          score: score,
          isPrivate: isPrivate,
        );
        return updated != null;
      },
    );
    if (result == true) {
      successSnackBar('Review updated');
      await _loadReviews();
    }
  }

  void _showReviewDetail(AnilistReview review) {
    final theme = context.colors;
    final currentUserId = _auth.profileData.value.id;
    final isOwnReview = review.userId.toString() == currentUserId;
    final userRating = review.userRating;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      if (review.user != null) {
                        navigate(
                            () => UserProfilePage(userId: review.user!.id));
                      }
                    },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: review.user?.avatarUrl != null
                          ? CachedNetworkImageProvider(review.user!.avatarUrl!)
                          : null,
                      child: review.user?.avatarUrl == null
                          ? const Icon(Icons.person, size: 22)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymexText(
                          text: review.user?.name ?? 'Unknown',
                          variant: TextVariant.semiBold,
                          size: 16,
                        ),
                        AnymexText(
                          text: review.timeAgo,
                          size: 12,
                          color: theme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getScoreColor(review.score).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              _getScoreColor(review.score).withOpacity(0.3)),
                    ),
                    child: AnymexText(
                      text: '${review.score}',
                      size: 18,
                      variant: TextVariant.bold,
                      color: _getScoreColor(review.score),
                    ),
                  ),
                  if (review.isPrivate)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.lock_rounded,
                          size: 16, color: theme.onSurfaceVariant),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (review.summary.isNotEmpty) ...[
                AnymexText(
                  text: review.summary,
                  variant: TextVariant.semiBold,
                  size: 16,
                ),
                const SizedBox(height: 12),
              ],

              AnilistAboutMe(about: review.body),
              const SizedBox(height: 16),

              Divider(color: theme.outline.withOpacity(0.1)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildRatingButton(
                    icon: Icons.thumb_up_rounded,
                    count: review.rating,
                    isActive: userRating == 'UP_VOTE',
                    activeColor: theme.primary,
                    onTap: () => _rateReview(review.id,
                        userRating == 'UP_VOTE' ? 'NO_VOTE' : 'UP_VOTE'),
                  ),
                  const SizedBox(width: 16),
                  _buildRatingButton(
                    icon: Icons.thumb_down_rounded,
                    count: review.ratingAmount - review.rating,
                    isActive: userRating == 'DOWN_VOTE',
                    activeColor: theme.error,
                    onTap: () => _rateReview(
                        review.id,
                        userRating == 'DOWN_VOTE'
                            ? 'NO_VOTE'
                            : 'DOWN_VOTE'),
                  ),
                  const Spacer(),
                  if (isOwnReview) ...[
                    IconButton(
                      icon: Icon(Icons.edit_rounded,
                          color: theme.primary, size: 20),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _editReview(review);
                      },
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_rounded,
                          color: theme.error, size: 20),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteReview(review.id);
                      },
                      tooltip: 'Delete',
                    ),
                  ],
                  if (review.siteUrl != null)
                    IconButton(
                      icon: Icon(Icons.open_in_new_rounded,
                          size: 20, color: theme.onSurfaceVariant),
                      onPressed: () {
                      },
                      tooltip: 'Open on AniList',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final isDesktop = MediaQuery.of(context).size.width > 600;

    if (_isLoading) {
      return _buildLoadingState(theme);
    }

    if (_hasError) {
      return _buildErrorState(theme);
    }

    if (_reviews.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Row(
            children: [
              Text(
                'Reviews',
                style: TextStyle(
                  fontFamily: "Poppins-SemiBold",
                  fontSize: isDesktop ? 20 : 17,
                  color: theme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_reviews.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: "Poppins-Bold",
                    color: theme.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (_auth.isLoggedIn.value)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton.icon(
                    onPressed: _writeReview,
                    icon: const Icon(Icons.rate_review_rounded, size: 18),
                    label: const Text('Write', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        SizedBox(
          height: isDesktop ? 200 : 170,
          child: ListView.builder(
            itemCount: _reviews.length,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 15, top: 5, bottom: 10),
            itemBuilder: (context, index) {
              return _buildReviewCard(_reviews[index], theme, isDesktop);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(
      AnilistReview review, ColorScheme theme, bool isDesktop) {
    final cardWidth = isDesktop ? 280.0 : 220.0;
    final scoreColor = _getScoreColor(review.score);

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showReviewDetail(review),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surfaceContainer.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.outline.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (review.user != null) {
                          navigate(() =>
                              UserProfilePage(userId: review.user!.id));
                        }
                      },
                      child: CircleAvatar(
                        radius: 14,
                        backgroundImage: review.user?.avatarUrl != null
                            ? CachedNetworkImageProvider(
                                review.user!.avatarUrl!)
                            : null,
                        child: review.user?.avatarUrl == null
                            ? const Icon(Icons.person, size: 14)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnymexText(
                            text: review.user?.name ?? 'Unknown',
                            variant: TextVariant.semiBold,
                            size: 12,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          AnymexText(
                            text: review.timeAgo,
                            size: 10,
                            color: theme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: scoreColor.withOpacity(0.3)),
                      ),
                      child: AnymexText(
                        text: '${review.score}',
                        size: 13,
                        variant: TextVariant.bold,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (review.summary.isNotEmpty)
                  AnymexText(
                    text: review.summary,
                    variant: TextVariant.semiBold,
                    size: 13,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 4),

                Expanded(
                  child: AnymexText(
                    text: review.body.replaceAll(RegExp(r'[\n\r]+'), ' ').replaceAll(RegExp(r'~!.*?!~'), '[spoiler]'),
                    size: 11,
                    color: theme.onSurfaceVariant,
                    maxLines: isDesktop ? 5 : 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(Icons.thumb_up_rounded,
                        size: 12, color: theme.onSurfaceVariant.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    AnymexText(
                      text: '${review.rating}',
                      size: 10,
                      color: theme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    const Spacer(),
                    if (review.isPrivate)
                      Icon(Icons.lock_rounded,
                          size: 12, color: theme.onSurfaceVariant.withOpacity(0.5)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingButton({
    required IconData icon,
    required int count,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isActive
                    ? activeColor
                    : context.colors.onSurfaceVariant),
            const SizedBox(width: 4),
            AnymexText(
              text: count.abs().toString(),
              size: 12,
              color:
                  isActive ? activeColor : context.colors.onSurfaceVariant,
              variant: isActive ? TextVariant.bold : TextVariant.regular,
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.amber;
    return Colors.red;
  }

  Widget _buildLoadingState(ColorScheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text(
            'Reviews',
            style: TextStyle(
              fontFamily: "Poppins-SemiBold",
              fontSize: 17,
              color: theme.primary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 170,
          child: Center(
            child: CircularProgressIndicator(
                color: theme.primary, strokeWidth: 2),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ColorScheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text(
            'Reviews',
            style: TextStyle(
              fontFamily: "Poppins-SemiBold",
              fontSize: 17,
              color: theme.primary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 28, color: theme.onSurfaceVariant),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _loadReviews,
                  child: AnymexText(
                    text: 'Tap to retry',
                    size: 12,
                    color: theme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Row(
            children: [
              Text(
                'Reviews',
                style: TextStyle(
                  fontFamily: "Poppins-SemiBold",
                  fontSize: 17,
                  color: theme.primary,
                ),
              ),
              const Spacer(),
              if (_auth.isLoggedIn.value)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton.icon(
                    onPressed: _writeReview,
                    icon: const Icon(Icons.rate_review_rounded, size: 18),
                    label:
                        const Text('Write', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 28, color: theme.onSurfaceVariant),
                const SizedBox(height: 4),
                AnymexText(
                  text: 'No reviews yet',
                  size: 12,
                  color: theme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
