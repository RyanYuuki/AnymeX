// ignore_for_file: deprecated_member_use

import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

OverlayEntry? _currentSnackBar;

void snackBar(
  String message, {
  int duration = 700,
  String? title,
  Color? backgroundColor,
  SnackPosition? snackPosition,
  int? maxLines = 2,
  IconData? icon,
  Color? iconColor,
  bool showCloseButton = false,
  bool showDurationAnimation = true,
  BuildContext? context,
}) {
  final effectiveContext = context ?? Get.context!;
  final theme = Theme.of(effectiveContext);

  if (_currentSnackBar != null) {
    if (_currentSnackBar!.mounted) {
      _currentSnackBar?.remove();
    }
    _currentSnackBar = null;
  }

  _currentSnackBar = OverlayEntry(
    builder: (context) => _BubbleSnackBar(
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

  OverlayState? overlay = Overlay.maybeOf(effectiveContext, rootOverlay: true);
  
  if (overlay != null) {
     overlay.insert(_currentSnackBar!);
  } else {
   
      ScaffoldMessenger.of(effectiveContext).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(milliseconds: duration),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        )
      );
  }
}

class _BubbleSnackBar extends StatefulWidget {
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

  const _BubbleSnackBar({
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
  State<_BubbleSnackBar> createState() => _BubbleSnackBarState();
}

class _BubbleSnackBarState extends State<_BubbleSnackBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _progressController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );



    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack),
      reverseCurve: Curves.easeInBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      reverseCurve: Curves.easeIn,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));

    // Start animations
    _animationController.forward();

    if (widget.showDurationAnimation) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _progressController.forward();
        }
      });
    }

    // Auto dismiss
    Future.delayed(widget.duration + const Duration(milliseconds: 500), () {
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
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Align(
            alignment: widget.snackPosition == SnackPosition.TOP
                ? Alignment.topCenter
                : Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(
                top: widget.snackPosition == SnackPosition.TOP
                    ? topPadding + 20
                    : 0,
                bottom: widget.snackPosition == SnackPosition.BOTTOM ? 40 : 0,
                left: 16,
                right: 16,
              ),
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  alignment: Alignment.center,
                  child: Material(
                    color: Colors.transparent,
                    child: IntrinsicHeight(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth *
                              (getResponsiveSize(context,
                                  mobileSize: 0.9, desktopSize: 0.4)),
                          minWidth: 120,
                          maxHeight: screenHeight * 0.3,
                        ),
                        child: _buildContent(),
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

  Widget _buildContent() {
    return GestureDetector(
      onTap: () => _dismiss(),
      onPanEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx.abs() > 500) {
          _dismiss();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor ??
                      widget.theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              // Duration fill animation
              if (widget.showDurationAnimation)
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: (widget.iconColor ??
                                    widget.theme.colorScheme.primary)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (widget.iconColor ??
                                  widget.theme.colorScheme.primary)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 20,
                          color: widget.iconColor ??
                              widget.theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title != null) ...[
                            AnymexText(
                              text: widget.title!,
                              variant: TextVariant.bold,
                              size: 16,
                              maxLines: 1,
                              color: widget.theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 4),
                          ],
                          AnymexText(
                            text: widget.message,
                            size: 14,
                            maxLines: widget.maxLines,
                            color: widget.theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.9),
                          ),
                        ],
                      ),
                    ),
                    if (widget.showCloseButton) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _dismiss,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: widget.theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: widget.theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Convenience methods
void successSnackBar(
  String message, {
  String? title,
  int duration = 2000,
  bool showDurationAnimation = true,
}) {
  snackBar(
    message,
    title: title,
    duration: duration,
    icon: Icons.check_circle_outline,
    iconColor: const Color(0xFF4CAF50),
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
    title: title,
    duration: duration,
    icon: Icons.error_outline,
    iconColor: const Color(0xFFF44336),
    showCloseButton: true,
    showDurationAnimation: showDurationAnimation,
  );
}

void infoSnackBar(
  String message, {
  String? title,
  int duration = 2000,
  bool showDurationAnimation = true,
}) {
  snackBar(
    message,
    title: title,
    duration: duration,
    icon: Icons.info_outline,
    iconColor: const Color(0xFF2196F3),
    showDurationAnimation: showDurationAnimation,
  );
}

void warningSnackBar(
  String message, {
  String? title,
  int duration = 3000,
  bool showDurationAnimation = true,
}) {
  snackBar(
    message,
    title: title,
    duration: duration,
    icon: Icons.warning_amber_outlined,
    iconColor: const Color(0xFFFF9800),
    showDurationAnimation: showDurationAnimation,
  );
}
