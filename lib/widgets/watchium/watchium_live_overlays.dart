import 'dart:async';
import 'dart:math';

import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/controllers/watchium/watchium_sync_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Out-of-sync banner shown in Freedom Seek mode.
/// Appears when the member's playback drifts from the host.
class WatchiumSyncBanner extends StatelessWidget {
  const WatchiumSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      try {
        final watchium = Get.find<WatchiumService>();
        final syncCtrl = Get.find<WatchiumSyncController>(tag: 'watchiumSync');

        // Only show in Freedom mode (not following host)
        if (watchium.followHost.value) return const SizedBox.shrink();
        // Only show when out of sync
        if (!syncCtrl.isOutOfSync.value) return const SizedBox.shrink();
        // Don't show while controls are hidden (too intrusive)
        final playerController =
            Get.find<PlayerController>();
        if (!playerController.showControls.value) {
          return const SizedBox.shrink();
        }
      } catch (_) {
        return const SizedBox.shrink();
      }

      return Positioned(
        bottom: 100,
        left: 16,
        right: 16,
        child: GestureDetector(
          onTap: () {
            try {
              Get.find<WatchiumSyncController>(tag: 'watchiumSync')
                  .syncToHost();
            } catch (_) {}
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sync_problem_rounded,
                  color: Colors.orange.shade300,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  'Out of sync with host',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Sync',
                    style: TextStyle(
                      color: Colors.orange.shade300,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// On-screen live comment overlay.
/// Shows recent chat messages (excluding own) as animated cards that
/// slide in and auto-dismiss after a few seconds.
class WatchiumCommentOverlay extends StatefulWidget {
  const WatchiumCommentOverlay({super.key});

  @override
  State<WatchiumCommentOverlay> createState() => _WatchiumCommentOverlayState();
}

class _WatchiumCommentOverlayState extends State<WatchiumCommentOverlay>
    with TickerProviderStateMixin {
  final List<_OverlayEntry<WatchiumChatMessage>> _items = [];
  StreamSubscription? _chatSub;
  int _lastSeenTs = 0;
  static const _maxVisible = 5;
  static const _autoDismissMs = 6000;

  @override
  void initState() {
    super.initState();
    _chatSub = Get.find<WatchiumService>().chatMessages.listen(_onChat);
  }

  void _onChat(List<WatchiumChatMessage> messages) {
    if (!WatchiumKeys.commentOverlay.get<bool>(true)) return;
    final watchium = Get.find<WatchiumService>();
    final myId = watchium.currentUserId;

    for (final msg in messages) {
      if (msg.userId == myId) continue;
      if (msg.ts <= _lastSeenTs) continue;
      _lastSeenTs = msg.ts;

      // Don't show duplicate text within 3 seconds (spam guard)
      if (_items.isNotEmpty &&
          _items.last.data.text == msg.text &&
          msg.ts - _items.last.data.ts < 3000) {
        continue;
      }

      _addItem(msg);
    }
  }

  void _addItem(WatchiumChatMessage msg) {
    final entry = _OverlayEntry(
      data: msg,
      createdAt: DateTime.now(),
      controller: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
    entry.controller.forward();

    setState(() {
      _items.add(entry);
      while (_items.length > _maxVisible) {
        final old = _items.removeAt(0);
        old.controller.dispose();
      }
    });

    // Auto-dismiss
    Future.delayed(const Duration(milliseconds: _autoDismissMs), () {
      if (mounted && _items.contains(entry)) {
        entry.controller.reverse().then((_) {
          if (mounted) setState(() => _items.remove(entry));
          entry.controller.dispose();
        });
      }
    });
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    for (final e in _items) {
      e.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!WatchiumKeys.commentOverlay.get<bool>(true)) {
      return const SizedBox.shrink();
    }
    if (_items.isEmpty) return const SizedBox.shrink();

    final position = WatchiumOverlayPosition.fromString(WatchiumKeys
        .overlayPosition
        .get<String>(WatchiumOverlayPosition.bottomRight.name));

    final isLeft = position == WatchiumOverlayPosition.topLeft ||
        position == WatchiumOverlayPosition.bottomLeft;
    final isTop = position == WatchiumOverlayPosition.topLeft ||
        position == WatchiumOverlayPosition.topRight;

    return Positioned(
      top: isTop ? 60 : null,
      bottom: isTop ? null : 60,
      left: isLeft ? 12 : null,
      right: isLeft ? null : 12,
      child: IgnorePointer(
        child: SizedBox(
          width: 260,
          child: Column(
            crossAxisAlignment:
                isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            verticalDirection: isTop ? VerticalDirection.down : VerticalDirection.up,
            children: _items
                .map((e) => _CommentCard(
                      entry: e,
                      isLeft: isLeft,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final _OverlayEntry<WatchiumChatMessage> entry;
  final bool isLeft;

  const _CommentCard({required this.entry, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: entry.controller,
      child: SlideTransition(
        position: isLeft
            ? Tween<Offset>(
                begin: const Offset(-0.3, 0),
                end: Offset.zero,
              ).animate(entry.controller)
            : Tween<Offset>(
                begin: const Offset(0.3, 0),
                end: Offset.zero,
              ).animate(entry.controller),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '${entry.data.username}: ${entry.data.text}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating emoji reaction overlay.
/// Reactions pop in at a random position, scale up, float upward, and fade out.
class WatchiumReactionOverlay extends StatefulWidget {
  const WatchiumReactionOverlay({super.key});

  @override
  State<WatchiumReactionOverlay> createState() =>
      _WatchiumReactionOverlayState();
}

class _WatchiumReactionOverlayState extends State<WatchiumReactionOverlay>
    with TickerProviderStateMixin {
  final List<_FloatingEmoji> _emojis = [];
  StreamSubscription? _reactionSub;
  int _lastSeenTs = 0;
  static const _maxVisible = 12;

  @override
  void initState() {
    super.initState();
    _reactionSub =
        Get.find<WatchiumService>().reactions.listen(_onReaction);
  }

  void _onReaction(List<WatchiumReaction> reactions) {
    if (!WatchiumKeys.reactionOverlay.get<bool>(true)) return;
    final watchium = Get.find<WatchiumService>();
    final myId = watchium.currentUserId;

    for (final r in reactions) {
      if (r.userId == myId) continue;
      if (r.ts <= _lastSeenTs) continue;
      _lastSeenTs = r.ts;

      _addEmoji(r);
    }
  }

  void _addEmoji(WatchiumReaction reaction) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    final startX = 0.2 + Random().nextDouble() * 0.6;
    final floatX = (Random().nextDouble() - 0.5) * 0.15;

    final emoji = _FloatingEmoji(
      reaction: reaction,
      controller: controller,
      startX: startX,
      floatX: floatX,
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() => _emojis.remove(emoji));
        }
        controller.dispose();
      }
    });

    setState(() {
      _emojis.add(emoji);
      while (_emojis.length > _maxVisible) {
        final old = _emojis.removeAt(0);
        old.controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  void dispose() {
    _reactionSub?.cancel();
    for (final e in _emojis) {
      e.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_emojis.isEmpty) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: _emojis.map((e) {
            return AnimatedBuilder(
              animation: e.controller,
              builder: (context, child) {
                final t = e.controller.value;
                final opacity = t < 0.15
                    ? t / 0.15
                    : (t > 0.7 ? (1.0 - t) / 0.3 : 1.0);
                final yOffset = (1.0 - t) * 0.25;
                final xOffset = e.startX + e.floatX * t;

                return Positioned(
                  left: xOffset * MediaQuery.of(context).size.width,
                  bottom:
                      yOffset * MediaQuery.of(context).size.height + 60,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: t < 0.1
                          ? t / 0.1 * 1.2
                          : (t < 0.2 ? 1.2 - (t - 0.1) * 2.0 : 1.0),
                      child: child,
                    ),
                  ),
                );
              },
              child: _EmojiBubble(emoji: e.reaction),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmojiBubble extends StatelessWidget {
  final WatchiumReaction emoji;

  const _EmojiBubble({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        emoji.emoji,
        style: const TextStyle(fontSize: 28, height: 1),
      ),
    );
  }
}

// -- Helper data classes --

class _OverlayEntry<T> {
  final T data;
  final DateTime createdAt;
  final AnimationController controller;
  _OverlayEntry({
    required this.data,
    required this.createdAt,
    required this.controller,
  });
}

class _FloatingEmoji {
  final WatchiumReaction reaction;
  final AnimationController controller;
  final double startX;
  final double floatX;
  _FloatingEmoji({
    required this.reaction,
    required this.controller,
    required this.startX,
    required this.floatX,
  });
}
