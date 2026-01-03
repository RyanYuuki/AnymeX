import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// AnymeX Animated Logo Widget
/// 
/// This widget recreates your animated logo with:
/// - Bottom-to-top fill (starts immediately, 2s duration)
class AnymeXAnimatedLogo extends StatefulWidget {
  final double size;
  final bool autoPlay;
  final VoidCallback? onAnimationComplete;
  final Color? color;
  final Gradient? gradient;
  
  const AnymeXAnimatedLogo({
    Key? key,
    this.size = 200,
    this.autoPlay = true,
    this.onAnimationComplete,
    this.color,
    this.gradient,
  }) : super(key: key);

  @override
  State<AnymeXAnimatedLogo> createState() => _AnymeXAnimatedLogoState();
}

class _AnymeXAnimatedLogoState extends State<AnymeXAnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    
    // Fill animation (bottom to top)
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fillAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.autoPlay) {
      _startAnimation();
    }
  }

  Future<void> _startAnimation() async {
    // Start fill animation immediately
    await _fillController.forward();
    widget.onAnimationComplete?.call();
  }

  /// Replay the animation
  void replay() {
    _fillController.reset();
    _startAnimation();
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _fillAnimation,
        builder: (context, child) {
          return _buildLogo();
        },
      ),
    );
  }

  Widget _buildLogo() {
    // Use theme colors
    final theme = Theme.of(context);
    final bool useGradient = widget.gradient != null || widget.color == null;
    
    String strokeFill;
    String fillGradientDef;
    
    if (widget.gradient != null) {
      // Use provided gradient
      final colors = widget.gradient is LinearGradient 
          ? (widget.gradient as LinearGradient).colors 
          : [theme.colorScheme.primary, theme.colorScheme.tertiary];
      
      strokeFill = 'url(#logoGradient)';
      fillGradientDef = _createFillGradient(colors);
    } else if (widget.color != null) {
      // Use single color
      strokeFill = 'url(#logoGradient)';
      fillGradientDef = _createFillGradient([widget.color!, widget.color!]);
    } else {
      // Use theme colors for gradient (primary -> secondary -> tertiary)
      strokeFill = 'url(#logoGradient)';
      fillGradientDef = _createFillGradient([
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
        theme.colorScheme.tertiary,
      ]);
    }
    
    // Calculate fill height for bottom-to-top effect
    final double fillHeight = _fillAnimation.value * 100;

    // Logo SVG string with bottom-to-top fill
    final logoSvg = '''
      <svg viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
        <defs>
          $fillGradientDef
        </defs>
        <path
          d="M 112.215 360.035 L 112.834 357.67 L 126.867 336.96 L 140.899 316.25 L 150.631 303.52 L 160.363 290.789 L 168.307 283.587 L 176.25 276.384 L 184.31 271.867 L 192.37 267.349 L 199.374 264.887 L 206.378 262.426 L 217.512 261.042 L 228.647 259.658 L 238.69 257.09 L 248.733 254.521 L 258.326 249.907 L 267.919 245.293 L 276.548 237.222 L 285.177 229.15 L 292.543 219.4 L 299.91 209.65 L 312.802 190.8 L 325.695 171.95 L 330.184 166.981 L 334.673 162.012 L 339.472 159.563 L 344.271 157.115 L 364.911 156.999 L 385.55 156.882 L 388.475 156.941 L 391.4 157 L 391.4 159.646 L 369.718 191.148 L 348.035 222.65 L 336.893 237.56 L 325.75 252.47 L 313.464 265.291 L 301.178 278.112 L 290.714 285.915 L 280.25 293.719 L 269.85 298.742 L 259.45 303.766 L 249.7 306.419 L 239.95 309.072 L 216.032 312.843 L 192.114 316.613 L 191.115 318.382 L 190.116 320.15 L 179.758 336.4 L 169.4 352.65 L 164.279 356.31 L 159.158 359.97 L 154.054 361.154 L 148.95 362.338 L 130.273 362.369 L 111.597 362.4 Z M 354.35 361.163 L 340.05 360.376 L 334.745 357.574 L 329.439 354.771 L 326.192 350.461 L 322.946 346.15 L 309.3 324.7 L 295.655 303.25 L 294.722 301.66 L 293.79 300.07 L 310.397 283.785 L 327.005 267.5 L 328.601 267.5 L 347.325 297.412 L 366.05 327.324 L 376.125 342.995 L 386.2 358.665 L 386.2 360.797 L 383.275 361.581 L 380.35 362.364 L 374.5 362.157 L 368.65 361.95 Z M 160 276.894 L 160 275.816 L 173.147 253.133 L 186.294 230.45 L 201.904 203.8 L 217.514 177.15 L 222.484 170.478 L 227.454 163.806 L 234.282 160.403 L 241.11 157 L 245.73 157.008 L 250.35 157.016 L 255.094 158.333 L 259.838 159.651 L 264.844 164.589 L 269.85 169.527 L 278.625 184.093 L 287.4 198.658 L 287.4 203.413 L 281.073 211.732 L 274.746 220.051 L 266.869 227.526 L 258.993 235.001 L 256.327 235.001 L 251.608 226.563 L 246.889 218.124 L 245.89 217.507 L 244.89 216.889 L 235.474 233.745 L 226.058 250.6 L 213.898 250.6 L 204.407 253.23 L 194.915 255.86 L 186.072 260.314 L 177.229 264.767 L 168.614 271.37 L 160 277.972 Z"
          fill="url(#fillGradient)"
        />
      </svg>
    ''';

    return SvgPicture.string(
      logoSvg,
      width: widget.size,
      height: widget.size,
    );
  }

  String _createFillGradient(List<Color> colors) {
    final double fillHeight = _fillAnimation.value * 100;
    
    // Create gradient stops
    String gradientStops = '';
    for (int i = 0; i < colors.length; i++) {
      final offset = (i / (colors.length - 1)) * 100;
      gradientStops += '<stop offset="$offset%" stop-color="${_colorToRgba(colors[i], 1.0)}" />';
    }
    
    return '''
      <linearGradient id="logoGradient" x1="0%" y1="0%" x2="100%" y2="100%">
        $gradientStops
      </linearGradient>
      <linearGradient id="fillGradient" x1="0%" y1="100%" x2="0%" y2="0%">
        <stop offset="0%" stop-color="${_colorToRgba(colors[0], 1.0)}" />
        <stop offset="$fillHeight%" stop-color="${_colorToRgba(colors.last, 1.0)}" />
        <stop offset="$fillHeight%" stop-color="transparent" />
        <stop offset="100%" stop-color="transparent" />
      </linearGradient>
    ''';
  }

  // Helper method to convert Color to rgba string (works better with SVG)
  String _colorToRgba(Color color, double opacity) {
    return 'rgba(${color.red}, ${color.green}, ${color.blue}, $opacity)';
  }
}
