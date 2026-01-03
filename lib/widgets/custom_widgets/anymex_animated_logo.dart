import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// AnymeX Animated Logo Widget
/// 
/// This widget recreates your animated logo with:
/// - Continuously rotating badge
/// - Stroke drawing effect (starts at 0.5s, 2.3s duration)
/// - Fill fade-in (starts at 2.3s, 0.5s duration)
class AnymeXAnimatedLogo extends StatefulWidget {
  final double size;
  final bool autoPlay;
  final VoidCallback? onAnimationComplete;
  final Color? color;
  
  const AnymeXAnimatedLogo({
    Key? key,
    this.size = 200,
    this.autoPlay = true,
    this.onAnimationComplete,
    this.color,
  }) : super(key: key);

  @override
  State<AnymeXAnimatedLogo> createState() => _AnymeXAnimatedLogoState();
}

class _AnymeXAnimatedLogoState extends State<AnymeXAnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _strokeController;
  late AnimationController _fillController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _strokeAnimation;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    
    // Badge rotation animation (continuous, 3s per rotation)
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(); // Continuously repeat
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 6.28318, // 2π radians = 360°
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    // Stroke drawing animation (2.3s with 0.5s delay)
    _strokeController = AnimationController(
      duration: const Duration(milliseconds: 2300),
      vsync: this,
    );
    
    _strokeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _strokeController,
      curve: Curves.easeInOut,
    ));
    
    // Fill fade animation (0.5s at 2.8s)
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fillAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeIn,
    ));
    
    if (widget.autoPlay) {
      _startAnimation();
    }
  }

  Future<void> _startAnimation() async {
    // Start stroke drawing after 500ms
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _strokeController.forward();
    
    // Start fill fade after 2800ms total
    await Future.delayed(const Duration(milliseconds: 2300));
    if (!mounted) return;
    await _fillController.forward();
    widget.onAnimationComplete?.call();
  }

  /// Replay the animation
  void replay() {
    _strokeController.reset();
    _fillController.reset();
    _startAnimation();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _strokeController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotationAnimation,
          _strokeAnimation,
          _fillAnimation,
        ]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Rotating badge (background)
              Transform.rotate(
                angle: _rotationAnimation.value,
                child: _buildBadge(),
              ),
              
              // Logo with stroke and fill animations
              _buildLogo(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadge() {
    // Use the provided color or default to theme color
    final Color badgeColor = widget.color ?? 
        Theme.of(context).colorScheme.primary;

    // Badge SVG string
    final badgeSvg = '''
      <svg viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
        <g transform="translate(256, 256)">
          <path
            d="M 231.98 0 C 231.98 19.53 201.6 35 196.98 52.71 C 192.36 70.42 210.56 99.68 201.11 115.71 C 191.66 131.74 157.64 130.27 144.2 143.71 C 130.76 157.15 132.72 191.03 116.2 200.62 C 99.68 210.21 71.54 191.52 53.2 196.49 C 34.86 201.46 19.95 231.49 0.49 231.49 C -18.97 231.49 -34.51 201.11 -52.22 196.49 C -69.93 191.87 -99.19 210.07 -115.22 200.62 C -131.25 191.17 -129.78 157.15 -143.22 143.71 C -156.66 130.27 -190.54 132.23 -200.13 115.71 C -209.72 99.19 -191.03 71.05 -196 52.71 C -200.97 34.37 -231 19.46 -231 0 C -231 -19.46 -200.62 -35 -196 -52.71 C -191.38 -70.42 -209.58 -99.68 -200.13 -115.71 C -190.68 -131.74 -156.66 -130.27 -143.22 -143.71 C -129.78 -157.15 -131.74 -191.03 -115.22 -200.62 C -98.7 -210.21 -70.56 -191.52 -52.22 -196.49 C -33.88 -201.46 -18.97 -231.49 0.49 -231.49 C 19.95 -231.49 35.49 -201.11 53.2 -196.49 C 70.91 -191.87 100.17 -210.07 116.2 -200.62 C 132.23 -191.17 130.76 -157.15 144.2 -143.71 C 157.64 -130.27 191.52 -132.23 201.11 -115.71 C 210.7 -99.19 192.01 -71.05 196.98 -52.71 C 201.95 -34.37 231.98 -19.53 231.98 0 Z"
            stroke="${_colorToRgba(badgeColor, 0.6)}"
            stroke-width="5.6"
            fill="none"
          />
          <path
            d="M 204.142 0 C 204.142 17.186 177.408 30.8 173.342 46.385 C 169.277 61.97 185.293 87.718 176.977 101.825 C 168.661 115.931 138.723 114.638 126.896 126.465 C 115.069 138.292 116.794 168.106 102.256 176.546 C 87.718 184.985 62.955 168.538 46.816 172.911 C 30.677 177.285 17.556 203.711 0.431 203.711 C -16.694 203.711 -30.369 176.977 -45.954 172.911 C -61.538 168.846 -87.287 184.862 -101.394 176.546 C -115.5 168.23 -114.206 138.292 -126.034 126.465 C -137.861 114.638 -167.675 116.362 -176.114 101.825 C -184.554 87.287 -168.106 62.524 -172.48 46.385 C -176.854 30.246 -203.28 17.125 -203.28 0 C -203.28 -17.125 -176.546 -30.8 -172.48 -46.385 C -168.414 -61.97 -184.43 -87.718 -176.114 -101.825 C -167.798 -115.931 -137.861 -114.638 -126.034 -126.465 C -114.206 -138.292 -115.931 -168.106 -101.394 -176.546 C -86.856 -184.985 -62.093 -168.538 -45.954 -172.911 C -29.814 -177.285 -16.694 -203.711 0.431 -203.711 C 17.556 -203.711 31.231 -176.977 46.816 -172.911 C 62.401 -168.846 88.15 -184.862 102.256 -176.546 C 116.362 -168.23 115.069 -138.292 126.896 -126.465 C 138.723 -114.638 168.538 -116.362 176.977 -101.825 C 185.416 -87.287 168.969 -62.524 173.342 -46.385 C 177.716 -30.246 204.142 -17.186 204.142 0 Z"
            fill="${_colorToRgba(badgeColor, 0.15)}"
          />
        </g>
      </svg>
    ''';

    return SvgPicture.string(
      badgeSvg,
      width: widget.size,
      height: widget.size,
    );
  }

  Widget _buildLogo() {
    // Use the provided color or default to theme color
    final Color logoColor = widget.color ?? 
        Theme.of(context).colorScheme.primary;

    // Calculate the actual path length for proper stroke animation
    final double pathLength = 2500;
    final double currentDashOffset = pathLength * (1 - _strokeAnimation.value);

    // Logo SVG string with proper stroke animation
    final logoSvg = '''
      <svg viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <linearGradient id="logoGradient" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stop-color="${_colorToRgba(logoColor, 1.0)}" />
            <stop offset="50%" stop-color="${_colorToRgba(logoColor, 0.9)}" />
            <stop offset="100%" stop-color="${_colorToRgba(logoColor, 0.7)}" />
          </linearGradient>
        </defs>
        <path
          d="M 112.215 360.035 L 112.834 357.67 L 126.867 336.96 L 140.899 316.25 L 150.631 303.52 L 160.363 290.789 L 168.307 283.587 L 176.25 276.384 L 184.31 271.867 L 192.37 267.349 L 199.374 264.887 L 206.378 262.426 L 217.512 261.042 L 228.647 259.658 L 238.69 257.09 L 248.733 254.521 L 258.326 249.907 L 267.919 245.293 L 276.548 237.222 L 285.177 229.15 L 292.543 219.4 L 299.91 209.65 L 312.802 190.8 L 325.695 171.95 L 330.184 166.981 L 334.673 162.012 L 339.472 159.563 L 344.271 157.115 L 364.911 156.999 L 385.55 156.882 L 388.475 156.941 L 391.4 157 L 391.4 159.646 L 369.718 191.148 L 348.035 222.65 L 336.893 237.56 L 325.75 252.47 L 313.464 265.291 L 301.178 278.112 L 290.714 285.915 L 280.25 293.719 L 269.85 298.742 L 259.45 303.766 L 249.7 306.419 L 239.95 309.072 L 216.032 312.843 L 192.114 316.613 L 191.115 318.382 L 190.116 320.15 L 179.758 336.4 L 169.4 352.65 L 164.279 356.31 L 159.158 359.97 L 154.054 361.154 L 148.95 362.338 L 130.273 362.369 L 111.597 362.4 Z M 354.35 361.163 L 340.05 360.376 L 334.745 357.574 L 329.439 354.771 L 326.192 350.461 L 322.946 346.15 L 309.3 324.7 L 295.655 303.25 L 294.722 301.66 L 293.79 300.07 L 310.397 283.785 L 327.005 267.5 L 328.601 267.5 L 347.325 297.412 L 366.05 327.324 L 376.125 342.995 L 386.2 358.665 L 386.2 360.797 L 383.275 361.581 L 380.35 362.364 L 374.5 362.157 L 368.65 361.95 Z M 160 276.894 L 160 275.816 L 173.147 253.133 L 186.294 230.45 L 201.904 203.8 L 217.514 177.15 L 222.484 170.478 L 227.454 163.806 L 234.282 160.403 L 241.11 157 L 245.73 157.008 L 250.35 157.016 L 255.094 158.333 L 259.838 159.651 L 264.844 164.589 L 269.85 169.527 L 278.625 184.093 L 287.4 198.658 L 287.4 203.413 L 281.073 211.732 L 274.746 220.051 L 266.869 227.526 L 258.993 235.001 L 256.327 235.001 L 251.608 226.563 L 246.889 218.124 L 245.89 217.507 L 244.89 216.889 L 235.474 233.745 L 226.058 250.6 L 213.898 250.6 L 204.407 253.23 L 194.915 255.86 L 186.072 260.314 L 177.229 264.767 L 168.614 271.37 L 160 277.972 Z"
          stroke="url(#logoGradient)"
          stroke-width="3"
          stroke-linecap="round"
          stroke-linejoin="round"
          fill="url(#logoGradient)"
          fill-opacity="${_fillAnimation.value}"
          stroke-dasharray="${pathLength}"
          stroke-dashoffset="${currentDashOffset}"
        />
      </svg>
    ''';

    return SvgPicture.string(
      logoSvg,
      width: widget.size,
      height: widget.size,
    );
  }

  // Helper method to convert Color to rgba string (works better with SVG)
  String _colorToRgba(Color color, double opacity) {
    return 'rgba(${color.red}, ${color.green}, ${color.blue}, $opacity)';
  }
}