import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/utils/al_about_me.dart';
import 'package:anymex/utils/markdown.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';

class ThreadComposerSheet extends StatefulWidget {
  final Future<bool> Function(String title, String body) onSubmit;
  final String? initialTitle;
  final String? initialBody;

  const ThreadComposerSheet({
    super.key,
    required this.onSubmit,
    this.initialTitle,
    this.initialBody,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? initialTitle,
    String? initialBody,
    required Future<bool> Function(String title, String body) onSubmit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ThreadComposerSheet(
        onSubmit: onSubmit,
        initialTitle: initialTitle,
        initialBody: initialBody,
      ),
    );
  }

  @override
  State<ThreadComposerSheet> createState() => _ThreadComposerSheetState();
}

class _ThreadComposerSheetState extends State<ThreadComposerSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _previewMode = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialBody != null) {
      _bodyController.text = widget.initialBody!;
    }
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _titleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _titleFocusNode.dispose();
    _bodyFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    setState(() => _isSubmitting = true);

    final success = await widget.onSubmit(title, body);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context, true);
      }
    }
  }

  Widget _buildFormatButton(
      String startDelimiter, String endDelimiter, IconData icon, String tooltip) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, color: context.theme.colorScheme.onSurfaceVariant, size: 20),
      onPressed: () async {
        final text = _bodyController.text;
        final selection = _bodyController.selection;

        final startIdx = selection.start >= 0 ? selection.start : text.length;
        final endIdx = selection.end >= 0 ? selection.end : text.length;

        String finalStart = startDelimiter;
        String finalEnd = endDelimiter;

        if (tooltip == 'Link' ||
            tooltip == 'Image' ||
            tooltip == 'YouTube' ||
            tooltip == 'WebM') {
          final url = await _showUrlInputDialog(tooltip);
          if (url == null) return;

          if (tooltip == 'Link') {
            finalEnd = ']($url)';
          } else if (tooltip == 'Image' ||
              tooltip == 'YouTube' ||
              tooltip == 'WebM') {
            finalEnd = '$url)';
          }
        }

        final newText = text.replaceRange(
            startIdx, endIdx, '$finalStart${text.substring(startIdx, endIdx)}$finalEnd');

        final newSelectionIndex = startIdx +
            finalStart.length +
            (startIdx == endIdx ? 0 : endIdx - startIdx + finalEnd.length);

        setState(() {
          _bodyController.text = newText;
          _bodyController.selection = TextSelection.collapsed(offset: newSelectionIndex);
        });
        _bodyFocusNode.requestFocus();
      },
    );
  }

  Future<String?> _showUrlInputDialog(String type) async {
    String? inputUrl;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: context.theme.colorScheme.surfaceContainer,
          title: Text(
            'Insert $type',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Paste URL here...',
              filled: true,
              fillColor: context.theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => inputUrl = val,
            onSubmitted: (val) => Navigator.pop(dialogContext, val),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: Text('Cancel',
                  style: TextStyle(color: context.theme.colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.theme.colorScheme.primary,
                foregroundColor: context.theme.colorScheme.onPrimary,
              ),
              onPressed: () => Navigator.pop(dialogContext, inputUrl),
              child: const Text('Insert'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Thread title',
                  hintStyle: TextStyle(
                    color: context.theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  _bodyFocusNode.requestFocus();
                },
              ),
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<int>(
                      style: SegmentedButton.styleFrom(
                        backgroundColor: context.theme.colorScheme.surfaceContainer,
                        selectedBackgroundColor:
                            context.theme.colorScheme.primaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: 0,
                          label: Text('Compose',
                              style: TextStyle(
                                  color: _previewMode
                                      ? context.theme.colorScheme.onSurfaceVariant
                                      : context.theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600)),
                          icon: Icon(Icons.edit_rounded,
                              color: _previewMode
                                  ? context.theme.colorScheme.onSurfaceVariant
                                  : context.theme.colorScheme.onPrimaryContainer,
                              size: 18),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('Preview',
                              style: TextStyle(
                                  color: !_previewMode
                                      ? context.theme.colorScheme.onSurfaceVariant
                                      : context.theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600)),
                          icon: Icon(Icons.preview_rounded,
                              color: !_previewMode
                                  ? context.theme.colorScheme.onSurfaceVariant
                                  : context.theme.colorScheme.onPrimaryContainer,
                              size: 18),
                        ),
                      ],
                      selected: {_previewMode ? 1 : 0},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() {
                          _previewMode = newSelection.first == 1;
                          if (!_previewMode) {
                            _bodyFocusNode.requestFocus();
                          } else {
                            _bodyFocusNode.unfocus();
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            if (!_previewMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFormatButton('**', '**', Icons.format_bold_rounded, 'Bold'),
                      _buildFormatButton('*', '*', Icons.format_italic_rounded, 'Italic'),
                      _buildFormatButton(
                          '~~', '~~', Icons.format_strikethrough_rounded, 'Strikethrough'),
                      _buildFormatButton(
                          '~!', '!~', Icons.visibility_off_rounded, 'Spoiler'),
                      _buildFormatButton('[', ']()', Icons.link_rounded, 'Link'),
                      _buildFormatButton('img(', ')', Icons.image_rounded, 'Image'),
                      _buildFormatButton(
                          'youtube(', ')', Icons.smart_display_rounded, 'YouTube'),
                      _buildFormatButton('webm(', ')', Icons.videocam_rounded, 'WebM'),
                      _buildFormatButton(
                          '- ', '', Icons.format_list_bulleted_rounded, 'Bullet List'),
                      _buildFormatButton(
                          '1. ', '', Icons.format_list_numbered_rounded, 'Numbered List'),
                      _buildFormatButton(
                          '~~~', '~~~', Icons.format_align_center_rounded, 'Center'),
                      _buildFormatButton('# ', '', Icons.title_rounded, 'Header'),
                      _buildFormatButton('> ', '', Icons.format_quote_rounded, 'Quote'),
                      _buildFormatButton('`', '`', Icons.code_rounded, 'Code'),
                      _buildFormatButton('```\n', '\n```',
                          Icons.integration_instructions_rounded, 'Code Block'),
                    ],
                  ),
                ),
              ),

            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _previewMode
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SingleChildScrollView(
                          child: _bodyController.text.trim().isEmpty
                              ? AnymexText(
                                  text: "Nothing to preview",
                                  color: context.theme.colorScheme.onSurfaceVariant,
                                )
                              : AnilistAboutMe(
                                  about: parseMarkdown(_bodyController.text),
                                ),
                        ),
                      )
                    : TextField(
                        controller: _bodyController,
                        focusNode: _bodyFocusNode,
                        maxLines: null,
                        minLines: 6,
                        decoration: InputDecoration(
                          hintText: 'Write your thread body...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: context.theme.colorScheme.surfaceContainer,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: AnymexText(
                      text: 'Cancel',
                      color: context.theme.colorScheme.onSurfaceVariant,
                      variant: TextVariant.semiBold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _titleController,
                    builder: (context, titleValue, child) {
                      return ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _bodyController,
                        builder: (context, bodyValue, child) {
                          final isEmpty =
                              titleValue.text.trim().isEmpty || bodyValue.text.trim().isEmpty;
                          return FilledButton(
                            onPressed: isEmpty || _isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: isEmpty || _isSubmitting
                                  ? context.theme.colorScheme.surfaceContainerHighest
                                  : context.theme.colorScheme.primary,
                              foregroundColor: isEmpty
                                  ? Colors.grey
                                  : context.theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : AnymexText(
                                    text: widget.initialTitle != null
                                        ? 'Update'
                                        : 'Create Thread',
                                    variant: TextVariant.semiBold,
                                    color: isEmpty
                                        ? Colors.grey
                                        : context.theme.colorScheme.onPrimary,
                                  ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
