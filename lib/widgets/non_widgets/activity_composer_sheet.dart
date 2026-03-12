import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/utils/al_about_me.dart';
import 'package:anymex/utils/markdown.dart';

class ActivityComposerSheet extends StatefulWidget {
  final Future<bool> Function(String text, {bool isPrivate}) onSubmit;
  final String? initialText;
  final String hintText;
  final bool isModal;
  final bool showPrivateToggle;
  final bool showCancelButton;
  final VoidCallback? onCancel;

  const ActivityComposerSheet({
    super.key,
    required this.onSubmit,
    this.hintText = "Write something...",
    this.initialText,
    this.isModal = false,
    this.showPrivateToggle = false,
    this.showCancelButton = false,
    this.onCancel,
  });

  @override
  State<ActivityComposerSheet> createState() => ActivityComposerSheetState();
}

class ActivityComposerSheetState extends State<ActivityComposerSheet> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _previewMode = false;
  bool _isSubmitting = false;
  bool _isExpanded = false;
  bool _isPrivate = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    if (widget.isModal) {
      _isExpanded = true;
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _focusNode.requestFocus();
      });
    }
    if (widget.initialText != null) {
      _textController.text = widget.initialText!;
      
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }
  }

  void cancelAction() {
    _textController.clear();
    setState(() {
      _isExpanded = false;
    });
    if (widget.onCancel != null) widget.onCancel!();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !_isExpanded) {
      if (mounted) setState(() => _isExpanded = true);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get text => _textController.text;

  void appendText(String newText) {
    if (!_isExpanded) {
      setState(() => _isExpanded = true);
    }
    final current = _textController.text;
    final updated = current.isEmpty ? newText : '$current $newText';
    _textController.text = updated;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  }

  void setText(String newText) {
    if (!_isExpanded) {
      setState(() => _isExpanded = true);
    }
    _textController.text = newText;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  }

  void requestFocus() {
    _focusNode.requestFocus();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    final success = await widget.onSubmit(text, isPrivate: _isPrivate);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        if (widget.isModal) {
          Navigator.pop(context, true);
        } else {
          _textController.clear();
          _focusNode.unfocus();
          setState(() {
            _isExpanded = false;
          });
        }
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
        final text = _textController.text;
        final selection = _textController.selection;

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
          _textController.text = newText;
          _textController.selection =
              TextSelection.collapsed(offset: newSelectionIndex);
        });
        _focusNode.requestFocus();
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isExpanded)
          Row(
            children: [
              Expanded(
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
                                  : context
                                      .theme.colorScheme.onPrimaryContainer,
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
                                  : context
                                      .theme.colorScheme.onPrimaryContainer,
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
                        _focusNode.requestFocus();
                      } else {
                        _focusNode.unfocus();
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        if (_isExpanded) const SizedBox(height: 12),
        if (_isExpanded && !_previewMode)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFormatButton(
                    '**', '**', Icons.format_bold_rounded, 'Bold'),
                _buildFormatButton(
                    '*', '*', Icons.format_italic_rounded, 'Italic'),
                _buildFormatButton('~~', '~~',
                    Icons.format_strikethrough_rounded, 'Strikethrough'),
                _buildFormatButton(
                    '~!', '!~', Icons.visibility_off_rounded, 'Spoiler'),
                _buildFormatButton('[', ']()', Icons.link_rounded, 'Link'),
                _buildFormatButton('img(', ')', Icons.image_rounded, 'Image'),
                _buildFormatButton(
                    'youtube(', ')', Icons.smart_display_rounded, 'YouTube'),
                _buildFormatButton(
                    'webm(', ')', Icons.videocam_rounded, 'WebM'),
                _buildFormatButton('- ', '', Icons.format_list_bulleted_rounded,
                    'Bullet List'),
                _buildFormatButton('1. ', '',
                    Icons.format_list_numbered_rounded, 'Numbered List'),
                _buildFormatButton(
                    '~~~', '~~~', Icons.format_align_center_rounded, 'Center'),
                _buildFormatButton('# ', '', Icons.title_rounded, 'Header'),
                _buildFormatButton(
                    '> ', '', Icons.format_quote_rounded, 'Quote'),
                _buildFormatButton('`', '`', Icons.code_rounded, 'Code'),
                _buildFormatButton('```\n', '\n```',
                    Icons.integration_instructions_rounded, 'Code Block'),
              ],
            ),
          ),
        if (_isExpanded && !_previewMode) const SizedBox(height: 8),
        Row(
          key: const ValueKey('composer_bottom_row'),
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _previewMode
                  ? Container(
                      constraints:
                          const BoxConstraints(minHeight: 50, maxHeight: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        child: _textController.text.trim().isEmpty
                            ? Text("Nothing to preview",
                                style: TextStyle(
                                    color: context
                                        .theme.colorScheme.onSurfaceVariant))
                            : AnilistAboutMe(
                                about: parseMarkdown(_textController.text)),
                      ),
                    )
                  : TextField(
                      autofocus: widget.isModal,
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: _isExpanded ? 2 : 1,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: context.theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            if (widget.showPrivateToggle)
              Container(
                margin: EdgeInsets.only(bottom: _isExpanded ? 16 : 2),
                child: IconButton(
                  tooltip: _isPrivate ? 'Private' : 'Public',
                  icon: Icon(
                    _isPrivate ? Icons.lock : Icons.public,
                    color: _isPrivate
                        ? context.theme.colorScheme.error
                        : context.theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPrivate = !_isPrivate;
                    });
                  },
                ),
              ),
            if (widget.showCancelButton)
              Container(
                margin: EdgeInsets.only(bottom: _isExpanded ? 16 : 2, right: 8),
                child: IconButton(
                  tooltip: 'Cancel',
                  icon: Icon(
                    Icons.close_rounded,
                    color: context.theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    _textController.clear();
                    setState(() {
                       _isExpanded = false;
                    });
                    if (widget.onCancel != null) widget.onCancel!();
                  },
                ),
              ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _textController,
              builder: (context, value, child) {
                final isEmpty = value.text.trim().isEmpty;
                return Container(
                  margin: EdgeInsets.only(
                      bottom:
                          _isExpanded ? 16 : 2),
                  decoration: BoxDecoration(
                    color: isEmpty || _isSubmitting
                        ? context.theme.colorScheme.surfaceContainerHighest
                        : context.theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(
                            Icons.send,
                            color: isEmpty
                                ? Colors.grey
                                : context.theme.colorScheme.onPrimary,
                          ),
                    onPressed: isEmpty || _isSubmitting ? null : _submit,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
