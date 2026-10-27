import 'dart:async';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex_extension_runtime_bridge/Engines/TorrentEngine/TorrServerAddon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

OverlayEntry? _activeTorrentOverlay;
_TorrentServerOverlayWidgetState? _activeTorrentOverlayState;

class TorrentServerOverlay {
  static void show({
    required TorrServerAddon addon,
    String status = 'Downloading Torrent Server...',
  }) {
    final navigatorContext = Get.key.currentContext ?? Get.context;
    final overlayState = Get.key.currentState?.overlay ??
        (navigatorContext != null
            ? Overlay.maybeOf(navigatorContext, rootOverlay: true)
            : null);

    if (overlayState == null) return;

    if (_activeTorrentOverlayState != null) {
      _activeTorrentOverlayState?.updateStatus(status);
      return;
    }

    if (_activeTorrentOverlay != null) {
      _removeEntry(_activeTorrentOverlay!);
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TorrentServerOverlayWidget(
        addon: addon,
        initialStatus: status,
        onDismiss: () => _removeEntry(entry),
        onStateReady: (state) => _activeTorrentOverlayState = state,
      ),
    );

    _activeTorrentOverlay = entry;
    overlayState.insert(entry);
  }

  static void updateStatus(String status) {
    _activeTorrentOverlayState?.updateStatus(status);
  }

  static void showError(String message) {
    _activeTorrentOverlayState?.showError(message);
  }

  static void dismiss({bool immediate = false}) {
    if (immediate) {
      final entry = _activeTorrentOverlay;
      if (entry != null) {
        _removeEntry(entry);
      }
    } else {
      _activeTorrentOverlayState?.dismiss();
    }
  }

  static void _removeEntry(OverlayEntry entry) {
    if (identical(_activeTorrentOverlay, entry)) {
      _activeTorrentOverlay = null;
      _activeTorrentOverlayState = null;
    }
    if (entry.mounted) {
      entry.remove();
    }
  }
}

class TorrentServerOverlayWidget extends StatefulWidget {
  final TorrServerAddon addon;
  final String initialStatus;
  final VoidCallback onDismiss;
  final ValueChanged<_TorrentServerOverlayWidgetState> onStateReady;

  const TorrentServerOverlayWidget({
    super.key,
    required this.addon,
    required this.initialStatus,
    required this.onDismiss,
    required this.onStateReady,
  });

  @override
  State<TorrentServerOverlayWidget> createState() =>
      _TorrentServerOverlayWidgetState();
}

class _TorrentServerOverlayWidgetState
    extends State<TorrentServerOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  final RxString _statusText = ''.obs;
  final RxBool _isError = false.obs;
  bool _hasDismissed = false;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _statusText.value = widget.initialStatus;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInQuart,
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(curve);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    widget.onStateReady(this);
  }

  void updateStatus(String status) {
    if (mounted) {
      _statusText.value = status;
    }
  }

  void showError(String message) {
    if (mounted) {
      _isError.value = true;
      _statusText.value = message;
      _autoDismissTimer?.cancel();
      _autoDismissTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) dismiss();
      });
    }
  }

  void dismiss() {
    if (_hasDismissed) return;
    _hasDismissed = true;
    _autoDismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIcon(ColorScheme theme, bool isError) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isError
            ? theme.error.opaque(0.14)
            : theme.primary.opaque(0.14),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        isError ? Icons.error_outline_rounded : Icons.cloud_download_rounded,
        color: isError ? theme.error : theme.primary,
        size: 21,
      ),
    );
  }

  Widget _buildProgressBar(
      ColorScheme theme, bool isDownloading, double progress, bool isError) {
    if (isError) {
      return const SizedBox(height: 4);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: isDownloading
          ? LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              backgroundColor: theme.surfaceContainerHighest.opaque(0.4),
              color: theme.primary,
              minHeight: 4,
            )
          : LinearProgressIndicator(
              backgroundColor: theme.surfaceContainerHighest.opaque(0.4),
              color: theme.primary,
              minHeight: 4,
            ),
    );
  }

  Widget _buildTrailing(ColorScheme theme, bool isDownloading, double progress,
      bool isError) {
    if (isError) {
      return GestureDetector(
        onTap: dismiss,
        child: Icon(
          Icons.close_rounded,
          size: 18,
          color: theme.onSurfaceVariant,
        ),
      );
    }

    if (isDownloading) {
      final percentage = (progress * 100).toInt();
      return AnymeXText(
        '$percentage%',
        variant: TextVariant.bold,
        size: 12.5,
        color: theme.primary,
      );
    }

    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final topPadding = MediaQuery.paddingOf(context).top;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (ctx, _) {
            final slide = _slideAnimation.value;
            final fade = _fadeAnimation.value;

            return Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  top: topPadding + 12,
                  left: 16,
                  right: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: screenWidth > 600 ? 440 : screenWidth - 32,
                  ),
                  child: Transform.translate(
                    offset: Offset(0, slide * 90),
                    child: Opacity(
                      opacity: fade,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.outlineVariant.opaque(0.28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.opaque(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Obx(() {
                          final isDownloading =
                              widget.addon.downloading.value;
                          final progress = widget.addon.progress.value;
                          final isError = _isError.value;
                          final status = _statusText.value;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildIcon(theme, isError),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AnymeXText(
                                          'Torrent Server',
                                          variant: TextVariant.bold,
                                          size: 13.5,
                                          color: theme.onSurface,
                                        ),
                                        const SizedBox(height: 2),
                                        AnymeXText(
                                          status,
                                          size: 11.5,
                                          color: isError
                                              ? theme.error
                                              : theme.onSurfaceVariant,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildTrailing(
                                      theme, isDownloading, progress, isError),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildProgressBar(
                                  theme, isDownloading, progress, isError),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
