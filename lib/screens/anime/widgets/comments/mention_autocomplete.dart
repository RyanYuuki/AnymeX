import 'dart:async';

import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class MentionAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final LayerLink layerLink;
  final FocusNode focusNode;
  final List<Map<String, dynamic>>? localUsers;

  const MentionAutocomplete({
    super.key,
    required this.controller,
    required this.layerLink,
    required this.focusNode,
    this.localUsers,
  });

  @override
  State<MentionAutocomplete> createState() => _MentionAutocompleteState();
}

class _MentionAutocompleteState extends State<MentionAutocomplete> {
  CommentumService? _commentumService;
  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _results = [];
  String _currentQuery = '';
  bool _isLoading = false;
  Timer? _debounce;
  int _selectedIndex = -1;

  CommentumService? get commentumService {
    if (_commentumService != null) return _commentumService;
    if (Get.isRegistered<CommentumService>()) {
      _commentumService = Get.find<CommentumService>();
    }
    return _commentumService;
  }

  String? get _triggeredQuery {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;
    if (cursorPos < 0 || cursorPos > text.length) return null;

    final beforeCursor = text.substring(0, cursorPos);
    final atIndex = beforeCursor.lastIndexOf('@');
    if (atIndex < 0) return null;

    final query = beforeCursor.substring(atIndex + 1);

    if (atIndex > 0) {
      final charBefore = beforeCursor[atIndex - 1];
      if (charBefore.isNotEmpty &&
          RegExp(r'[a-zA-Z0-9_]').hasMatch(charBefore)) {
        return null;
      }
    }

    if (query.contains(' ') || query.contains('\n')) return null;
    return query;
  }

  void _onTextChanged() {
    final query = _triggeredQuery;

    if (query == null) {
      _hideOverlay();
      _currentQuery = '';
      return;
    }

    if (query == _currentQuery && _overlayEntry != null) return;
    _currentQuery = query;
    _selectedIndex = -1;

    // Filter local users immediately
    final localMatches = _filterLocalUsers(query);

    if (localMatches.isNotEmpty) {
      setState(() {
        _results = localMatches;
      });
      _showOverlay();
    }

    // Debounce remote search for query length >= 1
    _debounce?.cancel();
    if (query.isNotEmpty) {
      _debounce = Timer(const Duration(milliseconds: 250), () {
        _searchUsers(query, localMatches);
      });
    } else if (localMatches.isEmpty) {
      _hideOverlay();
    }
  }

  List<Map<String, dynamic>> _filterLocalUsers(String query) {
    if (widget.localUsers == null || widget.localUsers!.isEmpty) return [];
    final lower = query.toLowerCase();
    return widget.localUsers!.where((u) {
      final name = (u['username'] as String? ?? '').toLowerCase();
      if (lower.isEmpty) return true;
      return name.contains(lower);
    }).take(8).toList();
  }

  Future<void> _searchUsers(String query, List<Map<String, dynamic>> initialMatches) async {
    final service = commentumService;
    if (service == null) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final remoteResults = await service.searchUsersPublic(username: query);
      if (mounted) {
        final seen = <String>{};
        final combined = <Map<String, dynamic>>[];

        for (final u in initialMatches) {
          final name = u['username'] as String? ?? '';
          if (name.isNotEmpty && seen.add(name.toLowerCase())) {
            combined.add(u);
          }
        }

        for (final u in remoteResults) {
          final name = u['username'] as String? ?? '';
          if (name.isNotEmpty && seen.add(name.toLowerCase())) {
            combined.add(u);
          }
        }

        setState(() {
          _results = combined;
          _isLoading = false;
          _selectedIndex = -1;
        });

        if (combined.isNotEmpty && _triggeredQuery != null) {
          _showOverlay();
        } else {
          _hideOverlay();
        }
      }
    } catch (e) {
      Logger.i('Error searching users for mention: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        if (_results.isEmpty) _hideOverlay();
      }
    }
  }

  void _showOverlay() {
    if (!mounted || !widget.focusNode.hasFocus) return;

    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: 16,
          right: 16,
          child: CompositedTransformFollower(
            link: widget.layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.bottomLeft,
            offset: const Offset(0, -10),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (screenWidth - 32).clamp(240.0, 360.0),
                  maxHeight: 250,
                ),
                child: _buildDropdown(colorScheme),
              ),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  Widget _buildDropdown(ColorScheme colorScheme) {
    return AnymeXContainer(
      borderRadius: BorderRadius.circular(16),
      color: colorScheme.surfaceContainerHigh,
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.25),
        width: 1,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Icon(
                  Icons.alternate_email_rounded,
                  size: 14,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                AnymeXText(
                  'Mention user',
                  size: 11,
                  variant: TextVariant.bold,
                  color: colorScheme.primary,
                ),
                const Spacer(),
                if (_isLoading)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.15),
          ),
          // Results list
          Flexible(
            child: _results.isEmpty && !_isLoading
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: AnymeXText(
                        'No users found',
                        size: 13,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final user = _results[index];
                      final username = user['username'] as String? ?? '';
                      final avatar = user['avatar'] as String?;
                      final isSelected = index == _selectedIndex;

                      return InkWell(
                        onTap: () => _selectUser(user),
                        borderRadius: BorderRadius.circular(10),
                        child: AnymeXContainer(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          borderRadius: BorderRadius.circular(10),
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              ClipOval(
                                child: avatar != null && avatar.isNotEmpty
                                    ? AnymeXImage(
                                        imageUrl: avatar,
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        radius: 0,
                                      )
                                    : AnymeXContainer(
                                        width: 28,
                                        height: 28,
                                        color: colorScheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.person_rounded,
                                          size: 16,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AnymeXText(
                                  '@$username',
                                  size: 13,
                                  variant: isSelected
                                      ? TextVariant.bold
                                      : TextVariant.semiBold,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _selectUser(Map<String, dynamic> user) {
    final username = user['username'] as String? ?? '';
    if (username.isEmpty) return;

    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;
    if (cursorPos < 0) return;

    final beforeCursor = text.substring(0, cursorPos);
    final atIndex = beforeCursor.lastIndexOf('@');
    if (atIndex < 0) return;

    final before = text.substring(0, atIndex);
    final after = text.substring(cursorPos);

    final newText = '$before@$username $after';
    widget.controller.text = newText;
    final newOffset = atIndex + username.length + 2; // +1 for @, +1 for space
    widget.controller.selection = TextSelection.collapsed(
      offset: newOffset.clamp(0, newText.length),
    );

    HapticFeedback.selectionClick();
    _hideOverlay();
    _currentQuery = '';
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (_overlayEntry == null || _results.isEmpty) {
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % _results.length;
      });
      _overlayEntry?.markNeedsBuild();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = _selectedIndex <= 0
            ? _results.length - 1
            : _selectedIndex - 1;
      });
      _overlayEntry?.markNeedsBuild();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.tab) {
      if (_selectedIndex >= 0 && _selectedIndex < _results.length) {
        _selectUser(_results[_selectedIndex]);
        return KeyEventResult.handled;
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _hideOverlay();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChange);
    widget.focusNode.onKeyEvent = _handleKeyEvent;
  }

  void _onFocusChange() {
    if (!widget.focusNode.hasFocus) {
      _hideOverlay();
      _currentQuery = '';
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChange);
    if (widget.focusNode.onKeyEvent == _handleKeyEvent) {
      widget.focusNode.onKeyEvent = null;
    }
    _debounce?.cancel();
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
