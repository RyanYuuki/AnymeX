import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';

class ContentErrorWidget extends StatelessWidget {
  final String errorType;
  final String errorMessage;
  final bool isManga;
  final VoidCallback? onRetry;
  final VoidCallback? onWrongTitle;

  const ContentErrorWidget({
    super.key,
    required this.errorType,
    required this.errorMessage,
    this.isManga = false,
    this.onRetry,
    this.onWrongTitle,
  });

  String _getEmoticon(String type) {
    switch (type) {
      case 'search':
        return '(>_<)';
      case 'detail':
        return '(╥﹏╥)';
      case 'no_match':
        return '(˘･_･˘)';
      case 'empty':
        return '(｡•́︿•̀｡)';
      case 'no_source':
        return '(・_・;)';
      default:
        return '(╥﹏╥)';
    }
  }

  String _getTitle(String type, bool manga) {
    final typeName = manga ? 'Chapters' : 'Episodes';
    switch (type) {
      case 'search':
        return 'Search Failed';
      case 'detail':
        return 'Failed to Load $typeName';
      case 'no_match':
        return 'No Match Found';
      case 'empty':
        return 'No $typeName Available';
      case 'no_source':
        return 'No Source Selected';
      default:
        return 'Failed to Load $typeName';
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'search':
        return Icons.search_off_rounded;
      case 'detail':
        return Icons.error_outline_rounded;
      case 'no_match':
        return Icons.find_in_page_outlined;
      case 'empty':
        return Icons.playlist_remove_rounded;
      case 'no_source':
        return Icons.extension_off_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String _formatErrorMessage(String type, String rawMessage) {
    var cleaned = rawMessage.trim();
    if (cleaned.startsWith('Exception: ')) {
      cleaned = cleaned.substring('Exception: '.length).trim();
    }

    if (cleaned.isEmpty) {
      switch (type) {
        case 'search':
          return 'An error occurred while searching this source for matches.';
        case 'detail':
          return 'Failed to retrieve media details from the source extension.';
        case 'no_match':
          return 'Could not find a matching title in the selected source.';
        case 'empty':
          return isManga
              ? 'The source returned no chapters for this manga.'
              : 'The source returned no episodes for this anime.';
        case 'no_source':
          return 'Please select or install a source extension to load content.';
        default:
          return 'An unexpected error occurred while loading content.';
      }
    }

    switch (type) {
      case 'search':
        return 'Search error: $cleaned';
      case 'detail':
        return 'Details error: $cleaned';
      default:
        return cleaned;
    }
  }

  Widget _buildEmoticonBadge(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.opaque(0.12, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnymeXText(
        _getEmoticon(errorType),
        size: 26,
        variant: TextVariant.bold,
        color: accentColor,
      ),
    );
  }

  Widget _buildDetailsBox(BuildContext context, Color accentColor) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.opaque(0.5, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.onSurface.opaque(0.06, iReallyMeanIt: true),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getIcon(errorType),
            size: 16,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnymeXText(
              _formatErrorMessage(errorType, errorMessage),
              size: 12,
              color: colors.onSurface.opaque(0.75, iReallyMeanIt: true),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Color accentColor, bool isError) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (onRetry != null)
          AnymeXContainerButton(
            onTap: onRetry!,
            radius: 12,
            color: accentColor,
            enableGlow: true,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: isError ? colors.onError : colors.onPrimary,
                ),
                const SizedBox(width: 6),
                AnymeXText(
                  'Retry',
                  variant: TextVariant.semiBold,
                  size: 13,
                  color: isError ? colors.onError : colors.onPrimary,
                ),
              ],
            ),
          ),
        if (onRetry != null && onWrongTitle != null)
          const SizedBox(width: 12),
        if (onWrongTitle != null)
          AnymeXContainerButton(
            onTap: onWrongTitle!,
            radius: 12,
            color:
                colors.surfaceContainerHighest.opaque(0.4, iReallyMeanIt: true),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                AnymeXText(
                  'Wrong Title?',
                  variant: TextVariant.semiBold,
                  size: 13,
                  color: colors.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isError = errorType == 'search' || errorType == 'detail';
    final accentColor = isError ? colors.error : colors.primary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.opaque(0.2, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.opaque(0.25, iReallyMeanIt: true),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEmoticonBadge(accentColor),
          const SizedBox(height: 14),
          AnymeXText(
            _getTitle(errorType, isManga),
            variant: TextVariant.bold,
            size: 16,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          _buildDetailsBox(context, accentColor),
          const SizedBox(height: 18),
          _buildActions(context, accentColor, isError),
        ],
      ),
    );
  }
}
