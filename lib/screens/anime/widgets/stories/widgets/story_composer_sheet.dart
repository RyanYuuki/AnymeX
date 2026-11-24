import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/screens/anime/widgets/stories/controller/stories_controller.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showStoryComposerSheet(BuildContext context) {
  AnymeXSheet.custom(
    const _StoryComposerSheet(),
    context,
    showDragHandle: true,
  );
}

class _StoryComposerSheet extends StatefulWidget {
  const _StoryComposerSheet();

  @override
  State<_StoryComposerSheet> createState() => _StoryComposerSheetState();
}

class _StoryComposerSheetState extends State<_StoryComposerSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    final storiesController = Get.find<StoriesController>();
    final success = await storiesController.postStory(text);
    if (!mounted) return;
    setState(() => _isPosting = false);

    if (success) {
      Get.back();
      snackBar(context.l10n.storyPostedToAnilist);
    } else {
      snackBar(context.l10n.failedToPostStory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnymeXText(
              context.l10n.postToStory,
              variant: TextVariant.bold,
              size: 17,
              color: theme.colorScheme.onSurface,
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.15),
              ),
            ),
            child: TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 2,
              maxLength: 1000,
              autofocus: true,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: context.l10n.whatsOnYourMindAniList,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: AnymeXButton(
              onTap: _isPosting ? () {} : _submit,
              height: 40,
              width: 110,
              borderRadius: BorderRadius.circular(20),
              backgroundColor: theme.colorScheme.primary,
              child: _isPosting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : AnymeXText(
                      context.l10n.postStory,
                      variant: TextVariant.bold,
                      size: 13,
                      color: theme.colorScheme.onPrimary,
                    ),
            ),
          ),
        ],
      );
  }
}
