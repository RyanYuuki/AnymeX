import 'dart:math' as math;

import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

OverlayEntry? _currentSnackBar;

void snackBar(
  String message, {
  int duration = 2000,
  String? title,
  Color? backgroundColor,
  SnackPosition? snackPosition,
  int? maxLines = 2,
  IconData? icon,
  Color? iconColor,
  bool showCloseButton = false,
  bool showDurationAnimation = true,
}) {
  final context = Get.context!;
  final theme = Theme.of(context);

  if (_currentSnackBar != null) {
    _currentSnackBar?.remove();
    _currentSnackBar = null;
  }

  _currentSnackBar = OverlayEntry(
    builder: (context) => _SnackBarWidget(
      message: message,
      title: title,
      backgroundColor: backgroundColor,
      position: snackPosition ??
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

class _SnackBarWidget extends StatefulWidget {
  const _SnackBarWidget({
    required this.message,
    this.title,
    this.backgroundColor,
    required this.position,
    this.maxLines,
    this.icon,
    this.iconColor,
    required this.showCloseButton,
    required this.showDurationAnimation,
    required this.duration,
    required this.theme,
    required this.onDismiss,
  });

  final String message;
  final String? title;
  final Color? backgroundColor;
  final SnackPosition position;
  final int? maxLines;
  final IconData? icon;
  final Color? iconColor;
  final bool showCloseButton;
  final bool showDurationAnimation;
  final Duration duration;
  final ThemeData theme;
  final VoidCallback onDismiss;

  @override
  State<_SnackBarWidget> createState() => _SnackBarWidgetState();
}

class _SnackBarWidgetState extends State<_SnackBarWidget>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _progressController;

  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _progressAnimation;

  double _dragOffset = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    final entryCurve = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInQuart,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(entryCurve);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        reverseCurve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    _entryController.forward();

    if (widget.showDurationAnimation) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _progressController.forward();
      });
    }

    Future.delayed(
      widget.duration + const Duration(milliseconds: 400),
      () {
        if (mounted) _dismiss();
      },
    );
  }

  void _dismiss() {
    _entryController.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  void _dismissWithSwipe(double direction) {
    if (!mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;

    setState(() {
      _dragOffset = direction >= 0 ? screenWidth * 1.5 : -screenWidth * 1.5;
    });
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  bool get _isTop => widget.position == SnackPosition.TOP;
  Color get _accentColor =>
      widget.iconColor ?? widget.theme.colorScheme.primary;
  Color get _bgColor =>
      widget.backgroundColor ?? widget.theme.colorScheme.surfaceContainerHigh;

  double get _swipeFadeOpacity {
    if (_dragOffset == 0.0) return 1.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final ratio = (_dragOffset.abs() / (screenWidth * 0.45)).clamp(0.0, 1.0);
    return 1.0 - ratio;
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final w = MediaQuery.of(context).size.width;
    final maxWidth =
        getResponsiveSize(context, mobileSize: w - 32.0, desktopSize: w * 0.38);

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _entryController,
        builder: (ctx, _) {
          final slide = _slideAnimation.value;
          return IgnorePointer(
            ignoring: false,
            child: Align(
              alignment: _isTop ? Alignment.topCenter : Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  top: _isTop ? topPad + 16 : 0,
                  bottom: _isTop ? 0 : bottomPad + 24,
                  left: 16,
                  right: 16,
                ),
                child: AnimatedContainer(
                  duration: _isDragging
                      ? Duration.zero
                      : const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  transform: Matrix4.translationValues(
                    _dragOffset,
                    _isTop ? -60 * slide : 60 * slide,
                    0,
                  ),
                  child: Opacity(
                    opacity: (_fadeAnimation.value * _swipeFadeOpacity)
                        .clamp(0.0, 1.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: _buildCard(ctx),
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

  Widget _buildCard(BuildContext context) {
    final cs = widget.theme.colorScheme;

    return GestureDetector(
      onTap: _dismiss,
      onHorizontalDragStart: (_) {
        _isDragging = true;
        _progressController.stop();
      },
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dx;
        });
      },
      onHorizontalDragEnd: (details) {
        _isDragging = false;
        final velocity = details.velocity.pixelsPerSecond.dx;
        const threshold = 80.0;

        if (_dragOffset.abs() > threshold || velocity.abs() > 400) {
          final direction = velocity.abs() > 400 ? velocity : _dragOffset;
          _dismissWithSwipe(direction);
        } else {
          setState(() => _dragOffset = 0.0);
          if (widget.showDurationAnimation) _progressController.forward();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.outline.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _accentColor.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBody(cs),
                if (widget.showDurationAnimation) _buildTimerBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            _IconBubble(
              icon: widget.icon!,
              color: _accentColor,
              bgColor: _accentColor.withOpacity(0.12),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.title != null) ...[
                  Text(
                    widget.title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: widget.theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  widget.message,
                  maxLines: widget.maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: widget.theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface
                        .withOpacity(widget.title != null ? 0.65 : 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (widget.showCloseButton) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _dismiss,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(width: 10),
            if (widget.showDurationAnimation)
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (_, __) => _ArcTimer(
                  progress: _progressAnimation.value,
                  color: _accentColor,
                  size: 26,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (_, __) {
        return SizedBox(
          height: 3,
          child: Stack(
            children: [
              Container(color: _accentColor.withOpacity(0.08)),
              FractionallySizedBox(
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _accentColor.withOpacity(0.9),
                        _accentColor.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 19, color: color),
    );
  }
}

class _ArcTimer extends StatelessWidget {
  const _ArcTimer({
    required this.progress,
    required this.color,
    required this.size,
  });

  final double progress;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcTimerPainter(progress: progress, color: color),
      ),
    );
  }
}

class _ArcTimerPainter extends CustomPainter {
  const _ArcTimerPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2.5;

    final trackPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    }

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final dotAngle = -math.pi / 2 + (2 * math.pi * progress);
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);
    canvas.drawCircle(Offset(dotX, dotY), 2.8, dotPaint);
  }

  @override
  bool shouldRepaint(_ArcTimerPainter old) => old.progress != progress;
}

void successSnackBar(
  String message, {
  String? title,
  int duration = 2500,
  bool showDurationAnimation = true,
}) {
  snackBar(
    message,
    title: title,
    duration: duration,
    icon: Icons.check_circle_outline_rounded,
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
    icon: Icons.error_outline_rounded,
    iconColor: const Color(0xFFEF5350),
    showCloseButton: true,
    showDurationAnimation: showDurationAnimation,
  );
}

void infoSnackBar(
  String message, {
  String? title,
  int duration = 2500,
  bool showDurationAnimation = true,
}) {
  snackBar(
    message,
    title: title,
    duration: duration,
    icon: Icons.info_outline_rounded,
    iconColor: const Color(0xFF42A5F5),
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
    icon: Icons.warning_amber_rounded,
    iconColor: const Color(0xFFFFB74D),
    showDurationAnimation: showDurationAnimation,
  );
}
