import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

OverlayEntry? _currentSnackBar;

void snackBar(
  String message, {
  int duration = 3000,
  String? title,
  Color? backgroundColor,
  SnackPosition? snackPosition,
  int? maxLines = 2,
  IconData? icon,
  Color? iconColor,
  bool showCloseButton = true,
  bool showDurationAnimation = true,
}) {
  final context = Get.context!;
  final theme = Theme.of(context);

  if (_currentSnackBar != null) {
    _currentSnackBar?.remove();
    _currentSnackBar = null;
  }

  _currentSnackBar = OverlayEntry(
    builder: (context) => _AnymexSnackBar(
      message: message,
      title: title,
      backgroundColor: backgroundColor,
      snackPosition: snackPosition ??
          getResponsiveValue(context,
              mobileValue: SnackPosition.BOTTOM,
              desktopValue: SnackPosition.TOP),
      maxLines: maxLines,
      icon: icon,
      iconColor: iconColor,
      showCloseButton: showCloseButton,
      showDurationAnimation: showDurationAnimation,
      duration: Duration(milliseconds: duration),
      theme: theme,
      onDismiss: () {
        _currentSnackBar?.remove();
        _currentSnackBar = null;
      },
    ),
  );

  Overlay.of(Get.overlayContext!).insert(_currentSnackBar!);
}

class _AnymexSnackBar extends StatefulWidget {
  final String message;
  final String? title;
  final Color? backgroundColor;
  final SnackPosition snackPosition;
  final int? maxLines;
  final IconData? icon;
  final Color? iconColor;
  final bool showCloseButton;
  final bool showDurationAnimation;
  final Duration duration;
  final ThemeData theme;
  final VoidCallback onDismiss;

  const _AnymexSnackBar({
    required this.message,
    this.title,
    this.backgroundColor,
    required this.snackPosition,
    this.maxLines,
    this.icon,
    this.iconColor,
    required this.showCloseButton,
    required this.showDurationAnimation,
    required this.duration,
    required this.theme,
    required this.onDismiss,
  });

  @override
  State<_AnymexSnackBar> createState() => _AnymexSnackBarState();
}

class _AnymexSnackBarState extends State<_AnymexSnackBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    if (widget.showDurationAnimation) {
      _progressController.forward();
    }

    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final isDesktop = screenWidth > 600;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Align(
            alignment: widget.snackPosition == SnackPosition.TOP
                ? Alignment.topCenter
                : Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(
                      0, widget.snackPosition == SnackPosition.TOP ? -1 : 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: _animationController, curve: Curves.easeOutQuart)),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: widget.snackPosition == SnackPosition.TOP
                        ? topPadding + 16
                        : 0,
                    bottom:
                        widget.snackPosition == SnackPosition.BOTTOM ? 32 : 0,
                    left: 16,
                    right: 16,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 400 : screenWidth,
                        minWidth: 300,
                      ),
                      child: _buildProfessionalContent(),
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

  Widget _buildProfessionalContent() {
    final isDark = widget.theme.brightness == Brightness.dark;

    final bgColor = widget.backgroundColor ??
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    final statusColor = widget.iconColor ?? widget.theme.colorScheme.primary;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: statusColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: statusColor,
                            size: 24,
                          ),
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.title != null &&
                                  widget.title!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: AnymexText(
                                    text: widget.title!,
                                    variant: TextVariant.bold,
                                    size: 15,
                                    maxLines: 1,
                                    color: widget.theme.colorScheme.onSurface,
                                  ),
                                ),
                              AnymexText(
                                text: widget.message,
                                size: 14,
                                maxLines: widget.maxLines,
                                color: widget.theme.colorScheme.onSurface
                                    .withOpacity(0.8),
                              ),
                            ],
                          ),
                        ),
                        if (widget.showCloseButton) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: _dismiss,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: widget.theme.colorScheme.onSurface
                                    .withOpacity(0.4),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showDurationAnimation)
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: 1.0 - _progressController.value,
                  backgroundColor: Colors.transparent,
                  color: statusColor.withOpacity(0.3),
                  minHeight: 2,
                );
              },
            ),
        ],
      ),
    );
  }
}

void successSnackBar(
  String message, {
  String? title,
  int duration = 3000,
  bool showDurationAnimation = true,
}) {
  snackBar(
    message,
    title: title ?? "Success",
    duration: duration,
    icon: Icons.check_circle_rounded,
    iconColor: const Color(0xFF2E7D32),
    showCloseButton: true,
    showDurationAnimation: showDurationAnimation,
  );
}

void errorSnackBar(
  String message, {
  String? title,
  int duration = 4000,
  bool showDurationAnimation = true,
}) {
  snackBar(
    message,
    title: title ?? "Error",
    duration: duration,
    icon: Icons.error_rounded,
    iconColor: const Color(0xFFD32F2F),
    showCloseButton: true,
    showDurationAnimation: showDurationAnimation,
  );
}

void infoSnackBar(
  String message, {
  String? title,
  int duration = 3000,
  bool showDurationAnimation = true,
}) {
  snackBar(
    message,
    title: title ?? "Information",
    duration: duration,
    icon: Icons.info_rounded,
    iconColor: const Color(0xFF0288D1),
    showCloseButton: true,
    showDurationAnimation: showDurationAnimation,
  );
}

void warningSnackBar(
  String message, {
  String? title,
  int duration = 4000,
  bool showDurationAnimation = true,
}) {
  snackBar(
    message,
    title: title ?? "Warning",
    duration: duration,
    icon: Icons.warning_rounded,
    iconColor: const Color(0xFFED6C02),
    showCloseButton: true,
    showDurationAnimation: showDurationAnimation,
  );
}
