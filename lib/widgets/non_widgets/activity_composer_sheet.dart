import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:anymex/utils/al_about_me.dart';
import 'package:anymex/utils/markdown.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/screens/anime/widgets/comments/discord_markdown.dart';
import 'package:anymex/screens/anime/widgets/comments/widgets/gif_picker_sheet.dart';

enum ComposerFlavor { anilist, comment }

class ActivityComposerSheet extends StatefulWidget {
  final Future<bool> Function(String text, {bool isPrivate}) onSubmit;
  final String? initialText;
  final String hintText;
  final bool isModal;
  final bool showPrivateToggle;
  final bool showCancelButton;
  final VoidCallback? onCancel;
  final ComposerFlavor flavor;
  final TextEditingController? textController;
  final FocusNode? focusNode;
  final Widget? headerWidget;
  final Widget? leadingWidget;
  final VoidCallback? onGifTap;
  final LayerLink? layerLink;

  const ActivityComposerSheet({
    super.key,
    required this.onSubmit,
    this.hintText = "Write something...",
    this.initialText,
    this.isModal = false,
    this.showPrivateToggle = false,
    this.showCancelButton = false,
    this.onCancel,
    this.flavor = ComposerFlavor.anilist,
    this.textController,
    this.focusNode,
    this.headerWidget,
    this.leadingWidget,
    this.onGifTap,
    this.layerLink,
  });

  @override
  State<ActivityComposerSheet> createState() => ActivityComposerSheetState();
}

class ActivityComposerSheetState extends State<ActivityComposerSheet> {
  TextEditingController? _internalTextController;
  FocusNode? _internalFocusNode;

  TextEditingController get _textController =>
      widget.textController ?? (_internalTextController ??= TextEditingController());

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  bool _previewMode = false;
  bool _isSubmitting = false;
  bool _isExpanded = false;
  bool _isPrivate = false;
  bool _isPickingGif = false;

  bool get isExpanded => _isExpanded;
  set isExpanded(bool value) {
    if (mounted) setState(() => _isExpanded = value);
  }

  void expand() {
    if (!_isExpanded && mounted) setState(() => _isExpanded = true);
  }

  void collapse() {
    if (_isExpanded && mounted) setState(() => _isExpanded = false);
  }

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
    if (widget.initialText != null && widget.textController == null) {
      _textController.text = widget.initialText!;
      
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }
  }

  void cancelAction() {
    _textController.clear();
    _focusNode.unfocus();
    setState(() {
      _isExpanded = false;
      _previewMode = false;
    });
    if (widget.onCancel != null) widget.onCancel!();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (!_isExpanded && mounted) setState(() => _isExpanded = true);
    } else {
      if (!widget.isModal && !_previewMode && !_isPickingGif && _isExpanded && mounted) {
        setState(() => _isExpanded = false);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _internalTextController?.dispose();
    _internalFocusNode?.dispose();
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
            // Leave preview mode too — otherwise the composer reopens on an
            // empty preview with no visible way back to the input.
            setState(() {
              _isExpanded = false;
              _previewMode = false;
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

        if (tooltip == 'Numbered List') {
          if (startIdx < endIdx) {
            final selectedText = text.substring(startIdx, endIdx);
            final lines = selectedText.split('\n');
            int count = 1;
            final formattedLines = lines.map((l) {
              if (l.trim().isEmpty) return l;
              return '${count++}. $l';
            }).join('\n');
            final newText = text.replaceRange(startIdx, endIdx, formattedLines);
            setState(() {
              _textController.text = newText;
              _textController.selection = TextSelection(
                baseOffset: startIdx,
                extentOffset: startIdx + formattedLines.length,
              );
            });
            _focusNode.requestFocus();
            return;
          } else {
            final textBefore = text.substring(0, startIdx);
            final lines = textBefore.split('\n');
            int nextNum = 1;
            for (int i = lines.length - 1; i >= 0; i--) {
              final line = lines[i].trim();
              if (line.isEmpty) continue;
              final match = RegExp(r'^(\d+)\.').firstMatch(line);
              if (match != null) {
                nextNum = (int.tryParse(match.group(1)!) ?? 0) + 1;
              }
              break;
            }
            final needsNewline = startIdx > 0 && text[startIdx - 1] != '\n';
            final prefix = needsNewline ? '\n$nextNum. ' : '$nextNum. ';
            final newText = text.replaceRange(startIdx, endIdx, prefix);
            final newOffset = startIdx + prefix.length;
            setState(() {
              _textController.text = newText;
              _textController.selection =
                  TextSelection.collapsed(offset: newOffset);
            });
            _focusNode.requestFocus();
            return;
          }
        }

        if (tooltip == 'Bullet List') {
          if (startIdx < endIdx) {
            final selectedText = text.substring(startIdx, endIdx);
            final lines = selectedText.split('\n');
            final formattedLines = lines.map((l) {
              if (l.trim().isEmpty) return l;
              return '- $l';
            }).join('\n');
            final newText = text.replaceRange(startIdx, endIdx, formattedLines);
            setState(() {
              _textController.text = newText;
              _textController.selection = TextSelection(
                baseOffset: startIdx,
                extentOffset: startIdx + formattedLines.length,
              );
            });
            _focusNode.requestFocus();
            return;
          } else {
            final needsNewline = startIdx > 0 && text[startIdx - 1] != '\n';
            final prefix = needsNewline ? '\n- ' : '- ';
            final newText = text.replaceRange(startIdx, endIdx, prefix);
            final newOffset = startIdx + prefix.length;
            setState(() {
              _textController.text = newText;
              _textController.selection =
                  TextSelection.collapsed(offset: newOffset);
            });
            _focusNode.requestFocus();
            return;
          }
        }

        if (tooltip == 'Link' ||
            tooltip == 'Image' ||
            tooltip == 'YouTube' ||
            tooltip == 'WebM') {
          final url = await _showUrlInputDialog(tooltip);
          if (url == null || url.trim().isEmpty) return;
          final cleanUrl = url.trim();

          if (tooltip == 'Link') {
            finalEnd = ']($cleanUrl)';
          } else if (tooltip == 'Image') {
            if (widget.flavor == ComposerFlavor.comment) {
              finalEnd = ']($cleanUrl)';
            } else {
              finalEnd = '$cleanUrl)';
            }
          } else if (tooltip == 'YouTube' ||
              tooltip == 'WebM') {
            finalEnd = '$cleanUrl)';
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

  void _openGifPicker() {
    if (widget.onGifTap != null) {
      widget.onGifTap!();
      return;
    }
    _isPickingGif = true;
    GifPickerSheet.show(
      context,
      onGifSelected: (url) {
        final currentText = _textController.text;
        final space = currentText.isNotEmpty &&
                !currentText.endsWith(' ') &&
                !currentText.endsWith('\n')
            ? '\n'
            : '';
        _textController.text = '$currentText$space$url\n';
        _textController.selection =
            TextSelection.collapsed(offset: _textController.text.length);
        if (mounted) setState(() {});
        _focusNode.requestFocus();
      },
    ).then((_) {
      _isPickingGif = false;
    });
  }

  Widget _buildGifButton() {
    return IconButton(
      tooltip: 'GIF',
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          'GIF',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: context.theme.colorScheme.primary,
          ),
        ),
      ),
      onPressed: _openGifPicker,
    );
  }

  Future<String?> _showUrlInputDialog(String type) async {
    String? inputUrl;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.theme.colorScheme.surfaceContainer,
          title: AnymeXText(
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
              child: AnymeXText('Cancel',
                  style: TextStyle(
                      color: context.theme.colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.theme.colorScheme.primary,
                foregroundColor: context.theme.colorScheme.onPrimary,
              ),
              onPressed: () => Navigator.pop(context, inputUrl),
              child: const AnymeXText('Insert'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.headerWidget != null) widget.headerWidget!,
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
                      label: AnymeXText('Compose',
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
                      label: AnymeXText('Preview',
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
              children: widget.flavor == ComposerFlavor.comment
                  ? [
                      _buildFormatButton(
                          '**', '**', Icons.format_bold_rounded, 'Bold'),
                      _buildFormatButton(
                          '*', '*', Icons.format_italic_rounded, 'Italic'),
                      _buildFormatButton('~~', '~~',
                          Icons.format_strikethrough_rounded, 'Strikethrough'),
                      _buildFormatButton(
                          '||', '||', Icons.visibility_off_rounded, 'Spoiler'),
                      _buildFormatButton('`', '`', Icons.code_rounded, 'Code'),
                      _buildFormatButton('```\n', '\n```',
                          Icons.integration_instructions_rounded, 'Code Block'),
                      _buildFormatButton('[', ']()', Icons.link_rounded, 'Link'),
                      _buildFormatButton('![', ']()', Icons.image_rounded, 'Image'),
                      _buildGifButton(),
                      _buildFormatButton(
                          '> ', '', Icons.format_quote_rounded, 'Quote'),
                      _buildFormatButton('- ', '', Icons.format_list_bulleted_rounded,
                          'Bullet List'),
                      _buildFormatButton('1. ', '',
                          Icons.format_list_numbered_rounded, 'Numbered List'),
                      _buildFormatButton('# ', '', Icons.title_rounded, 'Header'),
                    ]
                  : [
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
            if (widget.leadingWidget != null) ...[
              widget.leadingWidget!,
              const SizedBox(width: 8),
            ],
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
                            ? AnymeXText("Nothing to preview",
                                style: TextStyle(
                                    color: context
                                        .theme.colorScheme.onSurfaceVariant))
                            : (widget.flavor == ComposerFlavor.comment
                                ? DiscordMarkdown(
                                    text: _textController.text,
                                    colorScheme: context.theme.colorScheme,
                                    baseStyle: TextStyle(
                                      color: context.theme.colorScheme.onSurface,
                                      fontSize: 14,
                                    ),
                                  )
                                : AnilistAboutMe(
                                    about: parseMarkdown(_textController.text))),
                      ),
                    )
                  : TextField(
                      autofocus: widget.isModal,
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: _isExpanded ? 2 : 1,
                      inputFormatters: [MarkdownListInputFormatter()],
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

    if (widget.layerLink != null) {
      return CompositedTransformTarget(
        link: widget.layerLink!,
        child: content,
      );
    }

    return content;
  }
}

/// Automatically continues markdown lists (bullet `- ` and numbered `1. `) on Enter,
/// increments numbers sequentially, and cleans up empty list markers when Enter is pressed on them.
class MarkdownListInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length > oldValue.text.length &&
        newValue.selection.isCollapsed) {
      final oldCursor = oldValue.selection.baseOffset;
      final newCursor = newValue.selection.baseOffset;

      if (oldCursor >= 0 &&
          newCursor > oldCursor &&
          newValue.text.substring(oldCursor, newCursor) == '\n') {
        final textBeforeEnter = oldValue.text.substring(0, oldCursor);
        final lineStart = textBeforeEnter.lastIndexOf('\n') + 1;
        final currentLine = textBeforeEnter.substring(lineStart);

        // Check bullet list: e.g. "- ", "* "
        final bulletMatch =
            RegExp(r'^(\s*[-*]\s+)(.*)$').firstMatch(currentLine);
        if (bulletMatch != null) {
          final prefix = bulletMatch.group(1)!;
          final content = bulletMatch.group(2)!;

          if (content.trim().isEmpty) {
            // Empty bullet line -> exit list
            final newText = oldValue.text.substring(0, lineStart) +
                oldValue.text.substring(oldCursor);
            return TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: lineStart),
            );
          } else {
            // Auto-continue bullet list
            final insertText = prefix;
            final newText = newValue.text.substring(0, newCursor) +
                insertText +
                newValue.text.substring(newCursor);
            return TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(
                  offset: newCursor + insertText.length),
            );
          }
        }

        // Check numbered list: e.g. "1. ", "2. ", "10. "
        final numberedMatch =
            RegExp(r'^(\s*)(\d+)(\.\s+)(.*)$').firstMatch(currentLine);
        if (numberedMatch != null) {
          final indent = numberedMatch.group(1)!;
          final num = int.tryParse(numberedMatch.group(2)!) ?? 1;
          final dotSpace = numberedMatch.group(3)!;
          final content = numberedMatch.group(4)!;

          if (content.trim().isEmpty) {
            // Empty numbered line -> exit list
            final newText = oldValue.text.substring(0, lineStart) +
                oldValue.text.substring(oldCursor);
            return TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: lineStart),
            );
          } else {
            // Auto-continue numbered list with next number
            final nextPrefix = '$indent${num + 1}$dotSpace';
            final newText = newValue.text.substring(0, newCursor) +
                nextPrefix +
                newValue.text.substring(newCursor);
            return TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(
                  offset: newCursor + nextPrefix.length),
            );
          }
        }
      }
    }

    return newValue;
  }
}
