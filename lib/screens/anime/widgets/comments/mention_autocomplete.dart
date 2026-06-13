import 'dart:async';

import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class MentionAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final LayerLink layerLink;
  final FocusNode focusNode;

  const MentionAutocomplete({
    super.key,
    required this.controller,
    required this.layerLink,
    required this.focusNode,
  });

  @override
  State<MentionAutocomplete> createState() => _MentionAutocompleteState();
}

class _MentionAutocompleteState extends State<MentionAutocomplete> {
  final commentumService = Get.find<CommentumService>();
  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _results = [];
  String _currentQuery = '';
  bool _isLoading = false;
  Timer? _debounce;
  int _selectedindex = -1;

  String? get _triggeredQuery {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;
    if (cursorPos < 0) return null;

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

    if (query == null || query.isEmpty) {
      _hideOverlay();
      return;
    }

    if (query == _currentQuery) return;
    _currentQuery = query;
    _selectedindex = -1;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) {
      _hideOverlay();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await commentumService.searchUsersPublic(username: query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          _selectedindex = -1;
        });
        if (results.isNotEmpty && _triggeredQuery != null) {
          _showOverlay();
        } else {
          _hideOverlay();
        }
      }
    } catch (e) {
      Logger.i('Error searching users for mention: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _hideOverlay();
      }
    }
  }

  void _showOverlay() {
    _hideOverlay();
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        right: 0,
        child: CompositedTransformFollower(
          link: widget.layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,
          offset: const Offset(0, -8),
          child: SizedBox(
            width: (screenWidth - 64).clamp(200.0, 340.0),
            child: Material(
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surfaceContainerHigh,
              child: _buildDropdown(colorScheme),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildDropdown(ColorScheme colorScheme) {
    final maxResults = _isLoading ? 0 : _results.length;
    final totalItems = _isLoading ? 1 : maxResults;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: _isLoading
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            )
          : totalItems == 0
              ? const SizedBox.shrink()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: totalItems,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    final username = user['username'] as String? ?? '';
                    final avatar = user['avatar'] as String?;
                    final isSelected = index == _selectedindex;

                    return InkWell(
                      onTap: () => _selectUser(user),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : null,
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.surfaceContainer,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: avatar != null && avatar.isNotEmpty
                                  ? AnymeXImage(
                                      imageUrl: avatar,
                                      fit: BoxFit.cover,
                                      radius: 0,
                                    )
                                  : Icon(
                                      Icons.person_rounded,
                                      size: 14,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                username,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _selectUser(Map<String, dynamic> user) {
    final username = user['username'] as String? ?? '';
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;
    final beforeCursor = text.substring(0, cursorPos);
    final atIndex = beforeCursor.lastIndexOf('@');
    if (atIndex < 0) return;

    final before = text.substring(0, atIndex);
    final after = text.substring(cursorPos);

    widget.controller.text = '$before@$username $after';
    widget.controller.selection = TextSelection.collapsed(
      offset: atIndex + username.length + 2,
    );

    HapticFeedback.selectionClick();
    _hideOverlay();
    _currentQuery = '';
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (_overlayEntry == null || _results.isEmpty) {
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedindex = (_selectedindex + 1) % _results.length;
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedindex = _selectedindex <= 0
            ? _results.length - 1
            : _selectedindex - 1;
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.tab) {
      if (_selectedindex >= 0 && _selectedindex < _results.length) {
        _selectUser(_results[_selectedindex]);
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
    _debounce?.cancel();
    _hideOverlay();
    _keyListenerFocusNode.dispose();
    super.dispose();
  }

  final FocusNode _keyListenerFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyListenerFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: const SizedBox.shrink(),
    );
  }
}
