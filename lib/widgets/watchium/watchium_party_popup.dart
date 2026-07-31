import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/watchium/watchium_party_settings.dart';

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class WatchiumPartyPopup extends StatelessWidget {
  const WatchiumPartyPopup({super.key});

  void _closePane() {
    Get.find<WatchiumService>().isPartyPaneOpened.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final watchium = Get.find<WatchiumService>();

    return Obx(() {
      if (!watchium.inRoom.value) return const SizedBox.shrink();
      return EpisodeSidePane(
        isVisible: watchium.isPartyPaneOpened.value,
        onOverlayTap: _closePane,
        child: _WatchiumPartyPopupContent(
          watchium: watchium,
          onClose: _closePane,
        ),
      );
    });
  }
}

enum _PartyTab { chat, members }

class _WatchiumPartyPopupContent extends StatefulWidget {
  final WatchiumService watchium;
  final VoidCallback onClose;

  const _WatchiumPartyPopupContent({
    required this.watchium,
    required this.onClose,
  });

  @override
  State<_WatchiumPartyPopupContent> createState() =>
      _WatchiumPartyPopupContentState();
}

class _WatchiumPartyPopupContentState
    extends State<_WatchiumPartyPopupContent> {
  _PartyTab _currentTab = _PartyTab.chat;
  bool _showSettings = false;
  late final TextEditingController _chatController;
  final FocusNode _chatFocusNode = FocusNode();
  final ScrollController _chatScrollController = ScrollController();
  Worker? _chatWorker;
  Worker? _reactionWorker;
  bool _showJumpToBottom = false;
  static const _quickReactions = ['😂', '💀', '🔥', '👍', '❤️', '😮', '👏', '😭'];

  @override
  void initState() {
    super.initState();
    _chatController = TextEditingController();
    // Scroll to bottom when new messages/reactions arrive
    _chatWorker = ever(widget.watchium.chatMessages, _scrollChatToBottom);
    _reactionWorker = ever(widget.watchium.reactions, _scrollChatToBottom);
    _chatScrollController.addListener(_onChatScroll);
    _jumpToBottomAfterFrame();
  }

  void _scrollChatToBottom(_) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  void _jumpToBottom({bool animate = true}) {
    if (!_chatScrollController.hasClients) return;
    final pos = _chatScrollController.position;
    if (!pos.hasContentDimensions) return;
    if (animate) {
      _chatScrollController.animateTo(
        pos.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      pos.jumpTo(pos.maxScrollExtent);
    }
  }

  void _jumpToBottomAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) return;
      if (_chatScrollController.position.hasContentDimensions) {
        _jumpToBottom(animate: false);
      } else {
        _jumpToBottomAfterFrame();
      }
    });
  }

  void _onChatScroll() {
    if (!_chatScrollController.hasClients) return;
    final pos = _chatScrollController.position;
    final show = pos.hasContentDimensions &&
        pos.maxScrollExtent > 0 &&
        pos.pixels < pos.maxScrollExtent - 80;
    if (show != _showJumpToBottom) {
      setState(() => _showJumpToBottom = show);
    }
  }

  @override
  void dispose() {
    _chatWorker?.dispose();
    _reactionWorker?.dispose();
    _chatScrollController.removeListener(_onChatScroll);
    _chatController.dispose();
    _chatFocusNode.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;

    return Column(
      children: _showSettings
          ? [
              Expanded(
                child: WatchiumPartySettings(
                  onBack: () => setState(() => _showSettings = false),
                ),
              ),
            ]
          : [
              _buildHeader(cs, theme),
              _buildTabBar(cs, theme),
              Expanded(
                child: _currentTab == _PartyTab.chat
                    ? _buildChat(cs, theme)
                    : _buildMembersList(cs, theme),
              ),
            ],
    );
  }

  Widget _buildHeader(ColorScheme cs, ThemeData theme) {
    final state = widget.watchium.roomState.value;
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;

    return Container(
      padding: EdgeInsets.fromLTRB(16, isDesktop ? 16 + 40 : 16, 16, 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: cs.outline.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.live_tv_rounded, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Watch Party',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'Poppins-SemiBold',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (state != null)
                  Text(
                    'Room ${state.code}  ·  ${state.members.where((m) => m.online).length} online',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'Poppins',
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _leaveRoom,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.error.withOpacity(0.2)),
              ),
              child: Icon(Icons.exit_to_app, size: 20, color: cs.error),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _showSettings = true),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withOpacity(0.2)),
              ),
              child: Icon(Icons.settings_rounded,
                  size: 20, color: cs.primary),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.close,
                  size: 20, color: cs.onSurface.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  void _leaveRoom() {
    Logger.i('Leave room from party popup', 'WATCHIUM_UI');
    widget.watchium.leaveRoom();
  }

  Widget _buildTabBar(ColorScheme cs, ThemeData theme) {
    const tabs = [
      (
        label: 'Chat',
        icon: Icons.chat_bubble_rounded,
        tab: _PartyTab.chat
      ),
      (
        label: 'Members',
        icon: Icons.people_rounded,
        tab: _PartyTab.members
      ),
    ];
    final total = tabs.length;
    final currentIndex = tabs.indexWhere((t) => t.tab == _currentTab);
    final alignX = -1.0 + (2.0 * currentIndex / (total - 1));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SizedBox(
        height: 54,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outline.withOpacity(0.1)),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuint,
                alignment: Alignment(alignX, 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / total,
                  heightFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final t in tabs)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (_currentTab != t.tab) {
                            HapticFeedback.lightImpact();
                            setState(() => _currentTab = t.tab);
                            if (t.tab == _PartyTab.chat) {
                              _jumpToBottomAfterFrame();
                            }
                          }
                        },
                        child: AnimatedScale(
                          scale: _currentTab == t.tab ? 1.05 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: AnimatedOpacity(
                            opacity: _currentTab == t.tab ? 1.0 : 0.7,
                            duration: const Duration(milliseconds: 200),
                            child: SizedBox.expand(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    t.icon,
                                    size: 16,
                                    color: _currentTab == t.tab
                                        ? cs.onPrimary
                                        : cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: AnimatedDefaultTextStyle(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      style: TextStyle(
                                        fontFamily: 'Poppins-SemiBold',
                                        fontSize: 14,
                                        color: _currentTab == t.tab
                                            ? cs.onPrimary
                                            : cs.onSurfaceVariant,
                                      ),
                                      child: Text(
                                        t.label,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChat(ColorScheme cs, ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            final messages = widget.watchium.chatMessages;
            final reactions = widget.watchium.reactions;
            final items = <Object>[
              ...messages,
              ...reactions,
            ]..sort((a, b) {
              final aTs = a is WatchiumChatMessage ? a.ts : (a as WatchiumReaction).ts;
              final bTs = b is WatchiumChatMessage ? b.ts : (b as WatchiumReaction).ts;
              return aTs.compareTo(bTs);
            });
            if (items.isEmpty) {
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Be the first to say something!',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: cs.onSurface.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Stack(
              children: [
                ListView.builder(
                  controller: _chatScrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is WatchiumReaction) {
                      return _buildReactionBubble(cs, item);
                    }
                    final msg = item as WatchiumChatMessage;
                    final isSelf = msg.userId == widget.watchium.currentUserId;
                    final prevIsSameUser = index > 0 &&
                        items[index - 1] is WatchiumChatMessage &&
                        (items[index - 1] as WatchiumChatMessage).userId ==
                            msg.userId;
                    final nextIsSameUser =
                        index < items.length - 1 &&
                            items[index + 1] is WatchiumChatMessage &&
                            (items[index + 1] as WatchiumChatMessage).userId ==
                                msg.userId;
                    final isFirstInGroup = !prevIsSameUser;
                    final isLastInGroup = !nextIsSameUser;
                    final isSingle = isFirstInGroup && isLastInGroup;
                    return GestureDetector(
                      onLongPress: () => _showReactionPicker(context),
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: isFirstInGroup ? 8 : 1, bottom: 1),
                        child: Align(
                          alignment: isSelf
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isSelf
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!isSelf && isFirstInGroup)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundColor: cs.surfaceContainer
                                            .withValues(alpha: 0.4),
                                        backgroundImage: msg.avatarUrl != null
                                            ? NetworkImage(msg.avatarUrl!)
                                            : null,
                                        child: msg.avatarUrl == null
                                            ? Icon(Icons.person,
                                                size: 12,
                                                color: cs.onSurface
                                                    .withOpacity(0.6))
                                            : null,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        msg.username,
                                        style: TextStyle(
                                          fontFamily: 'Poppins-SemiBold',
                                          fontSize: 10,
                                          color: cs.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.45,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelf
                                      ? cs.primary.withValues(alpha: 0.2)
                                      : cs.surfaceContainerHighest
                                          .opaque(0.35, iReallyMeanIt: true),
                                  borderRadius: _bubbleRadius(
                                    isSelf: isSelf,
                                    isFirst: isFirstInGroup,
                                    isLast: isLastInGroup,
                                    isSingle: isSingle,
                                  ),
                                  border: Border.all(
                                    color: isSelf
                                        ? cs.primary.withValues(alpha: 0.35)
                                        : cs.onSurface
                                            .opaque(0.08, iReallyMeanIt: true),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  msg.text,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: IgnorePointer(
                    ignoring: !_showJumpToBottom,
                    child: AnimatedOpacity(
                      opacity: _showJumpToBottom ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Center(
                        child: GestureDetector(
                          onTap: _jumpToBottom,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.keyboard_arrow_down_rounded,
                                color: cs.onPrimary, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildQuickReactionBar(cs),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _buildChatInput(cs),
        ),
      ],
    );
  }

  Widget _buildQuickReactionBar(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK REACTIONS',
          style: TextStyle(
            fontFamily: 'Poppins-SemiBold',
            fontSize: 10,
            letterSpacing: 1.2,
            color: cs.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _quickReactions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final emoji = _quickReactions[index];
              return GestureDetector(
                onTap: () {
                  widget.watchium.sendReaction(emoji);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: cs.outline.withValues(alpha: 0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatInput(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cs.surfaceContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _chatController,
              focusNode: _chatFocusNode,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 13),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendChat(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _sendChat,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.send_rounded, color: cs.primary, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildReactionBubble(ColorScheme cs, WatchiumReaction r) {
    final isSelf = r.userId == widget.watchium.currentUserId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.25),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(r.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                r.username,
                style: TextStyle(
                  fontFamily: 'Poppins-SemiBold',
                  fontSize: 11,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BorderRadius _bubbleRadius({
    required bool isSelf,
    required bool isFirst,
    required bool isLast,
    required bool isSingle,
  }) {
    const large = Radius.circular(16);
    const small = Radius.circular(4);

    if (isSelf) {
      return BorderRadius.only(
        topLeft: large,
        bottomLeft: large,
        topRight: isSingle || isFirst ? large : small,
        bottomRight: isSingle || isLast ? large : small,
      );
    }
    return BorderRadius.only(
      topRight: large,
      bottomRight: large,
      topLeft: isSingle || isFirst ? large : small,
      bottomLeft: isSingle || isLast ? large : small,
    );
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    widget.watchium.sendChat(text);
    _chatController.clear();
    _chatFocusNode.requestFocus();
  }

  Widget _buildMembersList(ColorScheme cs, ThemeData theme) {
    return Obx(() {
      final state = widget.watchium.roomState.value;
      if (state == null) return const SizedBox.shrink();

      final isHost = widget.watchium.isHost.value;

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.members.length,
        itemBuilder: (context, index) {
          final member = state.members[index];
          final isSelf = member.userId == widget.watchium.currentUserId;
          final isCohost = member.role == 'cohost';
          final canKick = (isHost || isCohost) && !isSelf && member.role != 'host';
          final canManage = isHost && !isSelf && member.role != 'host';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest
                    .opaque(0.35, iReallyMeanIt: true),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.onSurface.opaque(0.08, iReallyMeanIt: true),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: cs.primary.withValues(alpha: 0.15),
                        backgroundImage: member.avatarUrl != null
                            ? NetworkImage(member.avatarUrl!)
                            : null,
                        child: member.avatarUrl == null
                            ? Icon(Icons.person,
                                size: 18,
                                color: cs.primary.withValues(alpha: 0.7))
                            : null,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: member.online
                                ? Colors.green
                                : cs.onSurface.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: cs.surfaceContainerHighest,
                                width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isSelf
                                    ? '${member.username} (You)'
                                    : member.username,
                                style: TextStyle(
                                  fontFamily: 'Poppins-SemiBold',
                                  fontSize: 14,
                                  color: cs.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (member.role == 'host' || isCohost) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCohost
                                      ? Colors.orange
                                      : cs.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isCohost ? 'CO-HOST' : 'HOST',
                                  style: TextStyle(
                                    fontFamily: 'Poppins-SemiBold',
                                    fontSize: 10,
                                    color: isCohost ? Colors.orange : cs.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.online ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: member.online
                                ? Colors.green.withValues(alpha: 0.8)
                                : cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canManage)
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest
                              .opaque(0.5, iReallyMeanIt: true),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.more_vert, size: 18, color: cs.onSurface),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'kick',
                          child: const Row(
                            children: [
                              Icon(Icons.person_remove_rounded, color: Colors.red, size: 18),
                              SizedBox(width: 10),
                              Text('Remove Member'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'transfer',
                          child: const Row(
                            children: [
                              Icon(Icons.crown, color: Colors.amber, size: 18),
                              SizedBox(width: 10),
                              Text('Transfer Host'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: member.role == 'cohost' ? 'demote' : 'promote',
                          child: Row(
                            children: [
                              Icon(
                                member.role == 'cohost'
                                    ? Icons.remove_circle_outline
                                    : Icons.shield,
                                color: Colors.orange,
                                size: 18,
                              ),
                              SizedBox(width: 10),
                              Text(
                                member.role == 'cohost' ? 'Remove Co-host' : 'Make Co-host',
                              ),
                            ],
                          ),
                        ),
                      ],
 onSelected: (value) => _handleMemberAction(value, member),
                    )
                  else if (canKick)
                    GestureDetector(
                      onTap: () => _confirmKick(member),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.person_remove_rounded,
                            size: 18, color: cs.error),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  void _handleMemberAction(String action, WatchiumMember member) {
    switch (action) {
      case 'kick':
        _confirmKick(member);
        break;
      case 'transfer':
        _confirmTransferHost(member);
        break;
      case 'promote':
        widget.watchium.promoteCohost(member.userId);
        break;
      case 'demote':
        widget.watchium.demoteCohost(member.userId);
        break;
    }
  }

  Future<void> _confirmTransferHost(WatchiumMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transfer host'),
        content: Text('Make ${member.username} the new host? You\'ll become a regular member.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.watchium.transferHost(member.userId);
    }
  }

  Future<void> _confirmKick(WatchiumMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member'),
        content: Text('Remove ${member.username} from this watch party?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.watchium.kickMember(member.userId);
    }
  }

  void _showReactionPicker(BuildContext context) {
    final RenderBox? overlay = context.findRenderObject() as RenderBox?;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        overlay?.localToGlobal(Offset.zero).dx ?? 0,
        (overlay?.localToGlobal(Offset.zero).dy ?? 0) - 50,
        0,
        0,
      ),
      items: _quickReactions.map((emoji) {
        return PopupMenuItem<String>(
          value: emoji,
          height: 40,
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        );
      }).toList(),
    ).then((selected) {
      if (selected != null) {
        widget.watchium.sendReaction(selected);
      }
    });
  }
}
