import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

OverlayEntry? _currentBanner;

void _removeBannerEntry(OverlayEntry entry) {
  if (identical(_currentBanner, entry)) {
    _currentBanner = null;
  }
  if (entry.mounted) {
    entry.remove();
  }
}

/// Shows a WhatsApp-style top overlay banner for foreground push
/// notifications. Single instance — a new banner replaces the current one.
/// Tapping the banner fires [onTap] (deep-link navigation); it also
/// auto-dismisses after [duration] and supports swipe-up to dismiss.
void showInAppNotification({
  required String title,
  required String body,
  String? avatarUrl,
  String? type,
  VoidCallback? onTap,
  Duration duration = const Duration(milliseconds: 4500),
}) {
  final navigatorContext = Get.key.currentContext ?? Get.context;

  final overlayState = Get.key.currentState?.overlay ??
      (navigatorContext != null
          ? Overlay.maybeOf(navigatorContext, rootOverlay: true)
          : null);

  if (overlayState == null) {
    debugPrint('[InAppBanner] Overlay unavailable. Dropped: $title');
    return;
  }

  final activeEntry = _currentBanner;
  if (activeEntry != null) {
    _removeBannerEntry(activeEntry);
  }

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _InAppBannerWidget(
      title: title,
      body: body,
      avatarUrl: avatarUrl,
      type: type,
      duration: duration,
      onDismiss: () => _removeBannerEntry(entry),
      onTap: onTap == null
          ? null
          : () {
              _removeBannerEntry(entry);
              onTap();
            },
    ),
  );
  _currentBanner = entry;

  overlayState.insert(entry);
}

Color _accentForType(BuildContext context, String? type) {
  final cs = context.colors;
  switch (type) {
    case 'user_mentioned':
      return cs.primary;
    case 'vote_cast':
    case 'vote_removed':
      return Colors.amber.shade700;
    case 'announcement_published':
      return cs.tertiary;
    case 'user_warned':
    case 'user_muted':
    case 'user_banned':
    case 'user_shadow_banned':
    case 'moderation_action':
    case 'report_filed':
    case 'comment_deleted':
      return cs.error;
    default:
      return cs.primary;
  }
}

class _InAppBannerWidget extends StatefulWidget {
  const _InAppBannerWidget({
    required this.title,
    required this.body,
    this.avatarUrl,
    this.type,
    required this.duration,
    required this.onDismiss,
    this.onTap,
  });

  final String title;
  final String body;
  final String? avatarUrl;
  final String? type;
  final Duration duration;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  @override
  State<_InAppBannerWidget> createState() => _InAppBannerWidgetState();
}

class _InAppBannerWidgetState extends State<_InAppBannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  bool _hasDismissed = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    final curve = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInQuart,
    );

    // Slides down from above the status bar into place.
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(curve);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _entryController.forward();
    Future.delayed(widget.duration, () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    if (_hasDismissed) return;
    _hasDismissed = true;
    _entryController.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final topPad = MediaQuery.paddingOf(context).top;
    final w = MediaQuery.sizeOf(context).width;
    final accent = _accentForType(context, widget.type);

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _entryController,
        builder: (ctx, _) {
          final slide = _slideAnimation.value;
          return Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(
                top: topPad + 10,
                left: 12,
                right: 12,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: w > 600 ? 480 : w - 24),
                child: Transform.translate(
                  offset: Offset(0, slide * 120),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Dismissible(
                      key: const ValueKey('in_app_notification_banner'),
                      direction: DismissDirection.up,
                      onDismissed: (_) => widget.onDismiss(),
                      child: GestureDetector(
                        onTap: widget.onTap,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: cs.outlineVariant.opaque(0.35),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.opaque(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 4,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _buildAvatar(cs),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnymeXText(
                                      widget.title,
                                      size: 13,
                                      variant: TextVariant.bold,
                                      color: cs.onSurface,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    AnymeXText(
                                      widget.body,
                                      size: 12,
                                      color: cs.onSurfaceVariant,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: cs.onSurfaceVariant.opaque(0.7),
                                ),
                                onPressed: _dismiss,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(ColorScheme cs) {
    final url = widget.avatarUrl;
    if (url == null || url.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.primary.opaque(0.15),
        ),
        child: Icon(
          Icons.notifications_rounded,
          size: 20,
          color: cs.primary,
        ),
      );
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 40,
          height: 40,
          color: cs.surfaceContainerHighest,
        ),
        errorWidget: (_, __, ___) => Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primary.opaque(0.15),
          ),
          child: Icon(
            Icons.person_rounded,
            size: 20,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}
