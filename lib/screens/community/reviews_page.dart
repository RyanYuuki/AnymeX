import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Anilist/anilist_review.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/utils/al_about_me.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/review_composer_sheet.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ReviewsPage extends StatefulWidget {
  final int mediaId;
  final String mediaType;
  final String? mediaTitle;

  const ReviewsPage({
    super.key,
    required this.mediaId,
    this.mediaType = 'ANIME',
    this.mediaTitle,
  });

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final _auth = Get.find<AnilistAuth>();
  List<AnilistReview> _reviews = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _hasNextPage = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasNextPage &&
        !_isLoading) {
      _loadMoreReviews();
    }
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _currentPage = 1;
    });
    try {
      final (reviews, hasNext) = await _auth.fetchReviews(
        mediaId: widget.mediaId,
        page: 1,
      );
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _hasNextPage = hasNext;
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

  Future<void> _loadMoreReviews() async {
    if (_isLoadingMore || !_hasNextPage) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    try {
      final (newReviews, hasNext) = await _auth.fetchReviews(
        mediaId: widget.mediaId,
        page: _currentPage,
      );
      if (mounted) {
        setState(() {
          _reviews.addAll(newReviews);
          _hasNextPage = hasNext;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _currentPage--;
        });
      }
    }
  }

  Future<void> _rateReview(int reviewId, String rating) async {
    final success = await _auth.rateReview(reviewId, rating);
    if (success) {
      await _loadReviews();
    } else {
      if (mounted) errorSnackBar('Failed to rate review');
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
    var userRating = review.userRating;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
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
                              navigate(() =>
                                  UserProfilePage(userId: review.user!.id));
                            }
                          },
                          child: CircleAvatar(
                            radius: 22,
                            backgroundImage: review.user?.avatarUrl != null
                                ? CachedNetworkImageProvider(
                                    review.user!.avatarUrl!)
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
                            color:
                                _getScoreColor(review.score).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _getScoreColor(review.score)
                                    .withOpacity(0.3)),
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
                          onTap: () async {
                            final newRating = userRating == 'UP_VOTE'
                                ? 'NO_VOTE'
                                : 'UP_VOTE';
                            setModalState(() => userRating = newRating);
                            final success =
                                await _auth.rateReview(review.id, newRating);
                            if (!success) {
                              setModalState(() =>
                                  userRating = review.userRating);
                              if (mounted) errorSnackBar('Failed to rate review');
                            } else {
                              await _loadReviews();
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildRatingButton(
                          icon: Icons.thumb_down_rounded,
                          count: review.ratingAmount - review.rating,
                          isActive: userRating == 'DOWN_VOTE',
                          activeColor: theme.error,
                          onTap: () async {
                            final newRating = userRating == 'DOWN_VOTE'
                                ? 'NO_VOTE'
                                : 'DOWN_VOTE';
                            setModalState(() => userRating = newRating);
                            final success =
                                await _auth.rateReview(review.id, newRating);
                            if (!success) {
                              setModalState(() =>
                                  userRating = review.userRating);
                              if (mounted) errorSnackBar('Failed to rate review');
                            } else {
                              await _loadReviews();
                            }
                          },
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
                            onPressed: () =>
                                launchUrlString(review.siteUrl!),
                            tooltip: 'Open on AniList',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;

    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            NestedHeader(
              title: widget.mediaTitle != null
                  ? '${widget.mediaTitle} Reviews'
                  : 'Reviews',
              action: _auth.isLoggedIn.value
                  ? TextButton.icon(
                      onPressed: _writeReview,
                      icon: const Icon(Icons.rate_review_rounded, size: 18),
                      label: const Text('Write',
                          style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.primary,
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                      ? _buildErrorWidget(theme)
                      : _reviews.isEmpty
                          ? _buildEmptyWidget(theme)
                          : RefreshIndicator(
                              onRefresh: _loadReviews,
                              child: ListView.builder(
                                controller: _scrollController,
                                physics:
                                    const AlwaysScrollableScrollPhysics(
                                        parent: BouncingScrollPhysics()),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                itemCount:
                                    _reviews.length + (_hasNextPage ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _reviews.length &&
                                      _hasNextPage) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Center(
                                        child: _isLoadingMore
                                            ? CircularProgressIndicator(
                                                color: theme.primary,
                                                strokeWidth: 2)
                                            : TextButton(
                                                onPressed: _loadMoreReviews,
                                                child: AnymexText(
                                                  text: 'Load More',
                                                  color: theme.primary,
                                                  variant:
                                                      TextVariant.semiBold,
                                                ),
                                              ),
                                      ),
                                    );
                                  }
                                  return _buildFullReviewCard(
                                      _reviews[index], theme);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullReviewCard(AnilistReview review, ColorScheme theme) {
    final currentUserId = _auth.profileData.value.id;
    final isOwnReview = review.userId.toString() == currentUserId;
    final scoreColor = _getScoreColor(review.score);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showReviewDetail(review),
          child: Container(
            padding: const EdgeInsets.all(14),
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
                        radius: 16,
                        backgroundImage: review.user?.avatarUrl != null
                            ? CachedNetworkImageProvider(
                                review.user!.avatarUrl!)
                            : null,
                        child: review.user?.avatarUrl == null
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnymexText(
                            text: review.user?.name ?? 'Unknown',
                            variant: TextVariant.semiBold,
                            size: 14,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          AnymexText(
                            text: review.timeAgo,
                            size: 11,
                            color: theme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: scoreColor.withOpacity(0.3)),
                      ),
                      child: AnymexText(
                        text: '${review.score}',
                        size: 15,
                        variant: TextVariant.bold,
                        color: scoreColor,
                      ),
                    ),
                    if (review.isPrivate)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(Icons.lock_rounded,
                            size: 14, color: theme.onSurfaceVariant),
                      ),
                  ],
                ),
                if (review.summary.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  AnymexText(
                    text: review.summary,
                    variant: TextVariant.semiBold,
                    size: 14,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                AnymexText(
                  text: review.body
                      .replaceAll(RegExp(r'[\n\r]+'), ' ')
                      .replaceAll(RegExp(r'~!.*?!~'), '[spoiler]'),
                  size: 12,
                  color: theme.onSurfaceVariant,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.thumb_up_rounded,
                        size: 14,
                        color: theme.onSurfaceVariant.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    AnymexText(
                      text: '${review.rating}',
                      size: 11,
                      color: theme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    const SizedBox(width: 12),
                    if (review.siteUrl != null)
                      GestureDetector(
                        onTap: () => launchUrlString(review.siteUrl!),
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new_rounded,
                                size: 14, color: theme.primary),
                            const SizedBox(width: 4),
                            AnymexText(
                              text: 'AniList',
                              size: 11,
                              color: theme.primary,
                              variant: TextVariant.semiBold,
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    if (isOwnReview) ...[
                      GestureDetector(
                        onTap: () => _editReview(review),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.edit_rounded,
                              size: 16, color: theme.primary),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _deleteReview(review.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.delete_rounded,
                              size: 16, color: theme.error),
                        ),
                      ),
                    ],
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

  Widget _buildErrorWidget(ColorScheme theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 40, color: theme.onSurfaceVariant),
          const SizedBox(height: 12),
          AnymexText(
            text: 'Failed to load reviews',
            size: 14,
            color: theme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loadReviews,
            child: AnymexText(
              text: 'Retry',
              color: theme.primary,
              variant: TextVariant.semiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(ColorScheme theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rate_review_outlined,
              size: 48, color: theme.onSurfaceVariant),
          const SizedBox(height: 12),
          AnymexText(
            text: 'No reviews yet',
            size: 16,
            color: theme.onSurfaceVariant,
          ),
          if (_auth.isLoggedIn.value) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _writeReview,
              icon: const Icon(Icons.rate_review_rounded, size: 20),
              label: const Text('Write the first review',
                  style: TextStyle(fontSize: 14)),
              style: TextButton.styleFrom(
                foregroundColor: theme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
