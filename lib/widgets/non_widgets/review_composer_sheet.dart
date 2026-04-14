import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/utils/al_about_me.dart';
import 'package:anymex/utils/markdown.dart';

class ReviewComposerSheet extends StatefulWidget {
  final Future<bool> Function(String summary, String body, int score, bool isPrivate) onSubmit;
  final String? initialSummary;
  final String? initialBody;
  final int? initialScore;
  final bool? initialPrivate;
  final int mediaId;

  const ReviewComposerSheet({
    super.key,
    required this.onSubmit,
    required this.mediaId,
    this.initialSummary,
    this.initialBody,
    this.initialScore,
    this.initialPrivate,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Future<bool> Function(String summary, String body, int score, bool isPrivate) onSubmit,
    required int mediaId,
    String? initialSummary,
    String? initialBody,
    int? initialScore,
    bool? initialPrivate,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReviewComposerSheet(
        onSubmit: onSubmit,
        mediaId: mediaId,
        initialSummary: initialSummary,
        initialBody: initialBody,
        initialScore: initialScore,
        initialPrivate: initialPrivate,
      ),
    );
  }

  @override
  State<ReviewComposerSheet> createState() => _ReviewComposerSheetState();
}

class _ReviewComposerSheetState extends State<ReviewComposerSheet> {
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final FocusNode _summaryFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();

  bool _previewMode = false;
  bool _isSubmitting = false;
  bool _isPrivate = false;
  double _score = 50;

  String? _summaryError;
  String? _bodyError;

  @override
  void initState() {
    super.initState();
    if (widget.initialSummary != null) {
      _summaryController.text = widget.initialSummary!;
      _summaryController.selection = TextSelection.fromPosition(
        TextPosition(offset: _summaryController.text.length),
      );
    }
    if (widget.initialBody != null) {
      _bodyController.text = widget.initialBody!;
      _bodyController.selection = TextSelection.fromPosition(
        TextPosition(offset: _bodyController.text.length),
      );
    }
    if (widget.initialScore != null) {
      _score = widget.initialScore!.toDouble();
    }
    if (widget.initialPrivate != null) {
      _isPrivate = widget.initialPrivate!;
    }

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _summaryFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _bodyController.dispose();
    _summaryFocusNode.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    final summary = _summaryController.text.trim();
    final body = _bodyController.text.trim();

    if (summary.length < 20) {
      _summaryError = 'Summary must be at least 20 characters (${summary.length}/20)';
      valid = false;
    } else if (summary.length > 120) {
      _summaryError = 'Summary must be at most 120 characters (${summary.length}/120)';
      valid = false;
    } else {
      _summaryError = null;
    }

    if (body.length < 2200) {
      _bodyError = 'Body must be at least 2200 characters (${body.length}/2200)';
      valid = false;
    } else {
      _bodyError = null;
    }

    setState(() {});
    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);

    final success = await widget.onSubmit(
      _summaryController.text.trim(),
      _bodyController.text.trim(),
      _score.round(),
      _isPrivate,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context, true);
      }
    }
  }

  Widget _buildFormatButton(String startDelimiter, String endDelimiter,
      IconData icon, String tooltip) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon,
          color: context.theme.colorScheme.onSurfaceVariant, size: 20),
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

        final newText = text.replaceRange(startIdx, endIdx,
            '$finalStart${text.substring(startIdx, endIdx)}$finalEnd');

        final newSelectionIndex = startIdx +
            finalStart.length +
            (startIdx == endIdx ? 0 : endIdx - startIdx + finalEnd.length);

        setState(() {
          _bodyController.text = newText;
          _bodyController.selection =
              TextSelection.collapsed(offset: newSelectionIndex);
        });
        _bodyFocusNode.requestFocus();
      },
    );
  }

  Future<String?> _showUrlInputDialog(String type) async {
    String? inputUrl;
    return showDialog<String>(
      context: context,
      builder: (context) {
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
            onSubmitted: (val) => Navigator.pop(context, val),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('Cancel',
                  style: TextStyle(
                      color: context.theme.colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.theme.colorScheme.primary,
                foregroundColor: context.theme.colorScheme.onPrimary,
              ),
              onPressed: () => Navigator.pop(context, inputUrl),
              child: const Text('Insert'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Write Review',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: context.theme.colorScheme.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context, null),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<int>(
              style: SegmentedButton.styleFrom(
                backgroundColor: context.theme.colorScheme.surface,
                selectedBackgroundColor:
                    context.theme.colorScheme.primaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 8),
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
                    _summaryFocusNode.unfocus();
                  }
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: bottomInset + 16,
              ),
              child: _previewMode ? _buildPreviewContent() : _buildComposeContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Summary',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _summaryController,
          focusNode: _summaryFocusNode,
          maxLength: 120,
          minLines: 1,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Brief summary of your review (20-120 chars)',
            counterText: '${_summaryController.text.length}/120',
            errorText: _summaryError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: context.theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
          ),
          onChanged: (_) {
            if (_summaryError != null) {
              setState(() => _summaryError = null);
            } else {
              setState(() {});
            }
          },
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Text(
              'Score',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Slider(
                value: _score,
                min: 0,
                max: 100,
                divisions: 100,
                label: _score.round().toString(),
                activeColor: _scoreColor,
                onChanged: (val) {
                  setState(() => _score = val);
                },
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '${_score.round()}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _scoreColor,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Icon(
              _isPrivate ? Icons.lock_rounded : Icons.public,
              size: 18,
              color: _isPrivate
                  ? context.theme.colorScheme.error
                  : context.theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              _isPrivate ? 'Private' : 'Public',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isPrivate
                    ? context.theme.colorScheme.error
                    : context.theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Switch(
              value: _isPrivate,
              activeColor: context.theme.colorScheme.error,
              onChanged: (val) {
                setState(() => _isPrivate = val);
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        Text(
          'Body',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFormatButton('**', '**', Icons.format_bold_rounded, 'Bold'),
              _buildFormatButton('*', '*', Icons.format_italic_rounded, 'Italic'),
              _buildFormatButton('~~', '~~', Icons.format_strikethrough_rounded, 'Strikethrough'),
              _buildFormatButton('~!', '!~', Icons.visibility_off_rounded, 'Spoiler'),
              _buildFormatButton('[', ']()', Icons.link_rounded, 'Link'),
              _buildFormatButton('img(', ')', Icons.image_rounded, 'Image'),
              _buildFormatButton('youtube(', ')', Icons.smart_display_rounded, 'YouTube'),
              _buildFormatButton('webm(', ')', Icons.videocam_rounded, 'WebM'),
              _buildFormatButton('- ', '', Icons.format_list_bulleted_rounded, 'Bullet List'),
              _buildFormatButton('1. ', '', Icons.format_list_numbered_rounded, 'Numbered List'),
              _buildFormatButton('~~~', '~~~', Icons.format_align_center_rounded, 'Center'),
              _buildFormatButton('# ', '', Icons.title_rounded, 'Header'),
              _buildFormatButton('> ', '', Icons.format_quote_rounded, 'Quote'),
              _buildFormatButton('`', '`', Icons.code_rounded, 'Code'),
              _buildFormatButton('```\n', '\n```', Icons.integration_instructions_rounded, 'Code Block'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        TextField(
          controller: _bodyController,
          focusNode: _bodyFocusNode,
          maxLines: 10,
          minLines: 6,
          decoration: InputDecoration(
            hintText: 'Write your review here (min 2200 chars)...',
            errorText: _bodyError,
            errorMaxLines: 2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: context.theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
          ),
          onChanged: (_) {
            if (_bodyError != null) {
              setState(() => _bodyError = null);
            }
          },
        ),

        const SizedBox(height: 4),

        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _bodyController,
          builder: (context, value, child) {
            final len = value.text.trim().length;
            final meetsMin = len >= 2200;
            return Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$len/2200',
                style: TextStyle(
                  fontSize: 12,
                  color: meetsMin
                      ? context.theme.colorScheme.primary
                      : context.theme.colorScheme.error.withOpacity(0.8),
                  fontWeight: meetsMin ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _bodyController,
          builder: (context, bodyValue, child) {
            return ValueListenableBuilder<TextEditingValue>(
              valueListenable: _summaryController,
              builder: (context, summaryValue, child) {
                final summaryEmpty = summaryValue.text.trim().isEmpty;
                final bodyEmpty = bodyValue.text.trim().isEmpty;
                final canSubmit = !summaryEmpty && !bodyEmpty && !_isSubmitting;

                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canSubmit
                          ? context.theme.colorScheme.primary
                          : context.theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: canSubmit
                          ? context.theme.colorScheme.onPrimary
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: canSubmit ? _submit : null,
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.theme.colorScheme.onPrimary,
                            ),
                          )
                        : Text(
                            widget.initialBody != null ? 'Update Review' : 'Submit Review',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPreviewContent() {
    final summary = _summaryController.text.trim();
    final body = _bodyController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.theme.colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.short_text_rounded,
                        size: 16,
                        color: context.theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _scoreColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_score.round()}/100',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _scoreColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

        if (summary.isNotEmpty) const SizedBox(height: 12),

        Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: body.isEmpty
              ? Text(
                  "Nothing to preview",
                  style: TextStyle(
                      color: context.theme.colorScheme.onSurfaceVariant),
                )
              : AnilistAboutMe(about: parseMarkdown(body)),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.colorScheme.primary,
              foregroundColor: context.theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.theme.colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    widget.initialBody != null ? 'Update Review' : 'Submit Review',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Color get _scoreColor {
    if (_score >= 70) return Colors.green;
    if (_score >= 40) return Colors.amber.shade700;
    return Colors.red;
  }
}
