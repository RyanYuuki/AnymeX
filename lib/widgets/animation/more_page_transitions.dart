import 'package:flutter/material.dart';

// Main page animation wrapper - perfect for entire screens
class PageAnimationWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final AnimationType animationType;
  final Curve curve;

  const PageAnimationWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.animationType = AnimationType.slideUp,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<PageAnimationWrapper> createState() => _PageAnimationWrapperState();
}

enum AnimationType {
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  fade,
  scale,
  slideUpFade,
  scaleRotate,
  slideUpScale,
  elasticSlide,
}

class _PageAnimationWrapperState extends State<PageAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _setupAnimations();

    // Start animation after delay
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  void _setupAnimations() {
    // Opacity animation
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.8, curve: widget.curve),
    ));

    // Scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Rotation animation (subtle)
    _rotationAnimation = Tween<double>(
      begin: -0.01,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Slide animation based on type
    Offset beginOffset;
    switch (widget.animationType) {
      case AnimationType.slideUp:
      case AnimationType.slideUpFade:
      case AnimationType.slideUpScale:
      case AnimationType.elasticSlide:
        beginOffset = const Offset(0.0, 0.1); // Subtle slide up
        break;
      case AnimationType.slideDown:
        beginOffset = const Offset(0.0, -0.1);
        break;
      case AnimationType.slideLeft:
        beginOffset = const Offset(0.1, 0.0);
        break;
      case AnimationType.slideRight:
        beginOffset = const Offset(-0.1, 0.0);
        break;
      default:
        beginOffset = Offset.zero;
    }

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.animationType == AnimationType.elasticSlide
          ? Curves.elasticOut
          : widget.curve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.animationType) {
      case AnimationType.fade:
        return FadeTransition(
          opacity: _opacityAnimation,
          child: widget.child,
        );

      case AnimationType.scale:
        return ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: widget.child,
          ),
        );

      case AnimationType.scaleRotate:
        return RotationTransition(
          turns: _rotationAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: widget.child,
            ),
          ),
        );

      case AnimationType.slideUpScale:
        return SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: widget.child,
            ),
          ),
        );

      case AnimationType.slideUpFade:
      case AnimationType.slideUp:
      case AnimationType.slideDown:
      case AnimationType.slideLeft:
      case AnimationType.slideRight:
      case AnimationType.elasticSlide:
      default:
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: widget.child,
          ),
        );
    }
  }
}

// Smooth entrance wrapper with preset configurations
class SmoothPageEntrance extends StatelessWidget {
  final Widget child;
  final PageEntranceStyle style;
  final Duration delay;

  const SmoothPageEntrance({
    super.key,
    required this.child,
    this.style = PageEntranceStyle.slideUpGentle,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case PageEntranceStyle.slideUpGentle:
        return PageAnimationWrapper(
          duration: const Duration(milliseconds: 600),
          delay: delay,
          animationType: AnimationType.slideUpFade,
          curve: Curves.easeOutCubic,
          child: child,
        );

      case PageEntranceStyle.elastic:
        return PageAnimationWrapper(
          duration: const Duration(milliseconds: 1000),
          delay: delay,
          animationType: AnimationType.elasticSlide,
          curve: Curves.elasticOut,
          child: child,
        );

      case PageEntranceStyle.smooth:
        return PageAnimationWrapper(
          duration: const Duration(milliseconds: 500),
          delay: delay,
          animationType: AnimationType.fade,
          curve: Curves.easeOut,
          child: child,
        );

      case PageEntranceStyle.bouncy:
        return PageAnimationWrapper(
          duration: const Duration(milliseconds: 800),
          delay: delay,
          animationType: AnimationType.slideUpScale,
          curve: Curves.elasticOut,
          child: child,
        );

      case PageEntranceStyle.professional:
        return PageAnimationWrapper(
          duration: const Duration(milliseconds: 400),
          delay: delay,
          animationType: AnimationType.slideUpFade,
          curve: Curves.easeOutQuart,
          child: child,
        );
    }
  }
}

enum PageEntranceStyle {
  slideUpGentle, // Subtle slide up with fade - great for most pages
  elastic, // Bouncy elastic animation
  smooth, // Simple fade in
  bouncy, // Scale + slide with bounce
  professional, // Quick, clean animation for business apps
}

// Usage examples in a demo page
class PageAnimationDemo extends StatefulWidget {
  const PageAnimationDemo({super.key});
  @override
  State<PageAnimationDemo> createState() => _PageAnimationDemoState();
}

class _PageAnimationDemoState extends State<PageAnimationDemo> {
  PageEntranceStyle selectedStyle = PageEntranceStyle.slideUpGentle;
  int animationKey = 0;

  void _triggerAnimation(PageEntranceStyle style) {
    setState(() {
      selectedStyle = style;
      animationKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SmoothPageEntrance(
        key: ValueKey(animationKey),
        style: selectedStyle,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Page Animation Demo',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try different animation styles for page entrances',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),

                const SizedBox(height: 32),

                // Content cards
                Expanded(
                  child: ListView(
                    children: [
                      _buildCard(
                        'Slide Up Gentle',
                        'Perfect for most pages - subtle and smooth',
                        Colors.blue,
                        () =>
                            _triggerAnimation(PageEntranceStyle.slideUpGentle),
                      ),
                      const SizedBox(height: 16),
                      _buildCard(
                        'Elastic Bounce',
                        'Fun bouncy animation with elastic curve',
                        Colors.purple,
                        () => _triggerAnimation(PageEntranceStyle.elastic),
                      ),
                      const SizedBox(height: 16),
                      _buildCard(
                        'Smooth Fade',
                        'Simple fade in - minimal and clean',
                        Colors.green,
                        () => _triggerAnimation(PageEntranceStyle.smooth),
                      ),
                      const SizedBox(height: 16),
                      _buildCard(
                        'Bouncy Scale',
                        'Scale + slide with bounce effect',
                        Colors.orange,
                        () => _triggerAnimation(PageEntranceStyle.bouncy),
                      ),
                      const SizedBox(height: 16),
                      _buildCard(
                        'Professional',
                        'Quick, clean animation for business apps',
                        Colors.teal,
                        () => _triggerAnimation(PageEntranceStyle.professional),
                      ),
                    ],
                  ),
                ),

                // Bottom info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usage:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Wrap your Scaffold or main page widget:\n\nSmoothPageEntrance(\n  style: PageEntranceStyle.slideUpGentle,\n  child: YourPageContent(),\n)',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
      String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_arrow,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
