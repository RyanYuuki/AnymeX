/// AnymeX Animated Logo Widget

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:anymex/models/logo_animation_type.dart';

class AnymeXAnimatedLogo extends StatefulWidget {
  final double size;
  final bool autoPlay;
  final VoidCallback? onAnimationComplete;
  final Color? color;
  final Gradient? gradient;
  final LogoAnimationType? forceAnimationType;
  
  const AnymeXAnimatedLogo({
    Key? key,
    this.size = 200,
    this.autoPlay = true,
    this.onAnimationComplete,
    this.color,
    this.gradient,
    this.forceAnimationType,
  }) : super(key: key);

  @override
  State<AnymeXAnimatedLogo> createState() => _AnymeXAnimatedLogoState();
}

class _AnymeXAnimatedLogoState extends State<AnymeXAnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late LogoAnimationType _animationType;

  @override
  void initState() {
    super.initState();
    
    // Get animation type from storage or use default
    _animationType = widget.forceAnimationType ?? _getStoredAnimationType();
    
    // Animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: _getCurveForAnimationType(_animationType),
    ));
    
    if (widget.autoPlay) {
      _startAnimation();
    }
  }

  LogoAnimationType _getStoredAnimationType() {
    try {
      final box = Hive.box('themeData');
      final index = box.get('logoAnimationType', defaultValue: 0);
      return LogoAnimationType.fromIndex(index);
    } catch (e) {
      return LogoAnimationType.bottomToTop;
    }
  }

  Curve _getCurveForAnimationType(LogoAnimationType type) {
    switch (type) {
      case LogoAnimationType.bottomToTop:
      case LogoAnimationType.wave:
        return Curves.easeInOut;
      case LogoAnimationType.fadeIn:
        return Curves.easeIn;
      case LogoAnimationType.scale:
        return Curves.elasticOut;
      case LogoAnimationType.rotate:
        return Curves.easeInOutCubic;
      case LogoAnimationType.slideRight:
        return Curves.easeOutCubic;
      case LogoAnimationType.pulse:
        return Curves.easeInOut;
      case LogoAnimationType.glitch:
        return Curves.linear;
      case LogoAnimationType.bounce:
        return Curves.bounceOut;
      case LogoAnimationType.spiral:
        return Curves.easeInOutQuart;
      case LogoAnimationType.netflixSwoosh:
        return Curves.easeInOutQuad;
      case LogoAnimationType.spotifyPulse:
        return Curves.easeInOut;
      case LogoAnimationType.tikTokGlitch:
        return Curves.linear;
      case LogoAnimationType.instagramGradient:
        return Curves.easeOut;
      case LogoAnimationType.youTubeSlide:
        return Curves.easeOutBack;
      case LogoAnimationType.discordBounce:
        return Curves.elasticOut;
      case LogoAnimationType.telegramFlyIn:
        return Curves.easeOutCubic;
      case LogoAnimationType.twitterFlip:
        return Curves.easeInOutCubic;
      case LogoAnimationType.whatsAppBubble:
        return Curves.easeInOut;
      case LogoAnimationType.twitchScan:
        return Curves.linear;
      case LogoAnimationType.redditBob:
        return Curves.easeInOut;
      case LogoAnimationType.snapchatGhost:
        return Curves.easeOut;
      case LogoAnimationType.appleMinimal:
        return Curves.easeInCubic;
      case LogoAnimationType.amazonArrow:
        return Curves.easeInOutCubic;
    }
  }

  Future<void> _startAnimation() async {
    await _controller.forward();
    widget.onAnimationComplete?.call();
  }

  /// Replay the animation
  void replay() {
    _controller.reset();
    _startAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return _buildAnimatedLogo();
        },
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    switch (_animationType) {
      case LogoAnimationType.bottomToTop:
        return _buildBottomToTopLogo();
      case LogoAnimationType.fadeIn:
        return _buildFadeInLogo();
      case LogoAnimationType.scale:
        return _buildScaleLogo();
      case LogoAnimationType.rotate:
        return _buildRotateLogo();
      case LogoAnimationType.slideRight:
        return _buildSlideRightLogo();
      case LogoAnimationType.pulse:
        return _buildPulseLogo();
      case LogoAnimationType.glitch:
        return _buildGlitchLogo();
      case LogoAnimationType.bounce:
        return _buildBounceLogo();
      case LogoAnimationType.wave:
        return _buildWaveLogo();
      case LogoAnimationType.spiral:
        return _buildSpiralLogo();
      case LogoAnimationType.netflixSwoosh:
        return _buildNetflixSwooshLogo();
      case LogoAnimationType.spotifyPulse:
        return _buildSpotifyPulseLogo();
      case LogoAnimationType.tikTokGlitch:
        return _buildTikTokGlitchLogo();
      case LogoAnimationType.instagramGradient:
        return _buildInstagramGradientLogo();
      case LogoAnimationType.youTubeSlide:
        return _buildYouTubeSlideRightLogo();
      case LogoAnimationType.discordBounce:
        return _buildDiscordBounceLogo();
      case LogoAnimationType.telegramFlyIn:
        return _buildTelegramFlyInLogo();
      case LogoAnimationType.twitterFlip:
        return _buildTwitterFlipLogo();
      case LogoAnimationType.whatsAppBubble:
        return _buildWhatsAppBubblePopLogo();
      case LogoAnimationType.twitchScan:
        return _buildTwitchGlitchScanLogo();
      case LogoAnimationType.redditBob:
        return _buildRedditAntennaBobLogo();
      case LogoAnimationType.snapchatGhost:
        return _buildSnapchatGhostFadeLogo();
      case LogoAnimationType.appleMinimal:
        return _buildAppleMinimalLogo();
      case LogoAnimationType.amazonArrow:
        return _buildAmazonArrowLogo();
    }
  }

  Widget _buildBottomToTopLogo() {
    return ClipRect(
      child: _buildBaseLogo(_animation.value * 100),
    );
  }

  Widget _buildFadeInLogo() {
    return Opacity(
      opacity: _animation.value,
      child: _buildBaseLogo(100),
    );
  }

  Widget _buildScaleLogo() {
    return Transform.scale(
      scale: _animation.value,
      child: _buildBaseLogo(100),
    );
  }

  Widget _buildRotateLogo() {
    return Transform.rotate(
      angle: (1 - _animation.value) * math.pi * 2,
      child: Opacity(
        opacity: _animation.value,
        child: _buildBaseLogo(100),
      ),
    );
  }

  Widget _buildSlideRightLogo() {
    return Transform.translate(
      offset: Offset((1 - _animation.value) * -widget.size, 0),
      child: _buildBaseLogo(100),
    );
  }

  Widget _buildPulseLogo() {
    final scale = 0.8 + (math.sin(_animation.value * math.pi * 4) * 0.1) + (_animation.value * 0.2);
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: _animation.value.clamp(0.0, 1.0),
        child: _buildBaseLogo(100),
      ),
    );
  }

  Widget _buildGlitchLogo() {
    final glitchOffset = _animation.value < 0.8 
        ? math.Random(_animation.value.hashCode).nextDouble() * 10 - 5
        : 0.0;
    return Transform.translate(
      offset: Offset(glitchOffset, 0),
      child: Opacity(
        opacity: _animation.value < 0.8 ? 0.5 + (_animation.value * 0.5) : 1.0,
        child: _buildBaseLogo(100),
      ),
    );
  }

  Widget _buildBounceLogo() {
    return Transform.translate(
      offset: Offset(0, (1 - _animation.value) * -widget.size * 0.5),
      child: _buildBaseLogo(100),
    );
  }

  Widget _buildWaveLogo() {
    final fillHeight = _animation.value * 100;
    final waveOffset = math.sin(_animation.value * math.pi * 2) * 5;
    return Transform.translate(
      offset: Offset(waveOffset, 0),
      child: _buildBaseLogo(fillHeight),
    );
  }

  Widget _buildSpiralLogo() {
    final angle = (1 - _animation.value) * math.pi * 4;
    final scale = _animation.value;
    return Transform.rotate(
      angle: angle,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: _animation.value,
          child: _buildBaseLogo(100),
        ),
      ),
    );
  }

  // Netflix-inspired swoosh animation
  Widget _buildNetflixSwooshLogo() {
    return Transform.translate(
      offset: Offset(
        math.sin(_animation.value * math.pi) * widget.size * 0.3,
        (1 - _animation.value) * widget.size * 0.5,
      ),
      child: Opacity(
        opacity: _animation.value,
        child: _buildBaseLogo(100),
      ),
    );
  }

  // Spotify-inspired pulse with glow effect
  Widget _buildSpotifyPulseLogo() {
    final scale = 0.7 + (math.sin(_animation.value * math.pi * 6) * 0.15) + (_animation.value * 0.3);
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        Opacity(
          opacity: (math.sin(_animation.value * math.pi * 3) * 0.3).clamp(0.0, 0.3),
          child: Transform.scale(
            scale: scale * 1.2,
            child: _buildBaseLogo(100),
          ),
        ),
        // Main logo
        Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: _animation.value.clamp(0.0, 1.0),
            child: _buildBaseLogo(100),
          ),
        ),
      ],
    );
  }

  // TikTok-inspired RGB split glitch
  Widget _buildTikTokGlitchLogo() {
    final glitchIntensity = _animation.value < 0.7 ? (_animation.value * 0.3) : 0.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Red channel
        Transform.translate(
          offset: Offset(-glitchIntensity * 10, glitchIntensity * 5),
          child: Opacity(
            opacity: glitchIntensity > 0 ? 0.6 : 0,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.red, BlendMode.screen),
              child: _buildBaseLogo(100),
            ),
          ),
        ),
        // Blue channel
        Transform.translate(
          offset: Offset(glitchIntensity * 10, -glitchIntensity * 5),
          child: Opacity(
            opacity: glitchIntensity > 0 ? 0.6 : 0,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.blue, BlendMode.screen),
              child: _buildBaseLogo(100),
            ),
          ),
        ),
        // Main logo
        Opacity(
          opacity: _animation.value,
          child: _buildBaseLogo(100),
        ),
      ],
    );
  }

  // Instagram-inspired gradient reveal
  Widget _buildInstagramGradientLogo() {
    return ClipRect(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gradient overlay that reveals
          Opacity(
            opacity: _animation.value,
            child: _buildBaseLogo(100),
          ),
          // Shimmer effect
          if (_animation.value < 1.0)
            Transform.translate(
              offset: Offset(
                -widget.size + (_animation.value * widget.size * 2),
                -widget.size + (_animation.value * widget.size * 2),
              ),
              child: Container(
                width: widget.size * 0.5,
                height: widget.size * 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0),
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // YouTube-inspired slide with momentum
  Widget _buildYouTubeSlideRightLogo() {
    final easeOutBack = Curves.easeOutBack.transform(_animation.value);
    return Transform.translate(
      offset: Offset((1 - easeOutBack) * -widget.size * 1.5, 0),
      child: _buildBaseLogo(100),
    );
  }

  // Discord-inspired bounce with overshoot
  Widget _buildDiscordBounceLogo() {
    final bounceValue = Curves.elasticOut.transform(_animation.value);
    return Transform.translate(
      offset: Offset(0, (1 - bounceValue) * -widget.size * 0.8),
      child: _buildBaseLogo(100),
    );
  }

  // Telegram-inspired paper plane fly-in
  Widget _buildTelegramFlyInLogo() {
    final flyProgress = Curves.easeOutCubic.transform(_animation.value);
    return Transform.translate(
      offset: Offset(
        (1 - flyProgress) * widget.size * 0.8,
        (1 - flyProgress) * -widget.size * 0.8,
      ),
      child: Transform.rotate(
        angle: (1 - flyProgress) * math.pi * 0.5,
        child: Opacity(
          opacity: _animation.value,
          child: _buildBaseLogo(100),
        ),
      ),
    );
  }

  // Twitter/X-inspired flip reveal
  Widget _buildTwitterFlipLogo() {
    final flipAngle = (1 - _animation.value) * math.pi;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(flipAngle),
      child: Opacity(
        opacity: _animation.value,
        child: _buildBaseLogo(100),
      ),
    );
  }

  // WhatsApp-inspired bubble pop
  Widget _buildWhatsAppBubblePopLogo() {
    final popScale = _animation.value < 0.5
        ? _animation.value * 2.4
        : 1.2 - ((_animation.value - 0.5) * 0.4);
    return Transform.scale(
      scale: popScale,
      child: Opacity(
        opacity: _animation.value.clamp(0.0, 1.0),
        child: _buildBaseLogo(100),
      ),
    );
  }

  // Twitch-inspired glitch scan
  Widget _buildTwitchGlitchScanLogo() {
    final scanProgress = _animation.value;
    final glitchOffset = math.Random((_animation.value * 100).toInt()).nextDouble() * 5;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildBaseLogo(100),
        if (scanProgress < 1.0)
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: scanProgress,
              child: Transform.translate(
                offset: Offset(glitchOffset, 0),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF9146FF),
                    BlendMode.modulate,
                  ),
                  child: _buildBaseLogo(100),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Reddit-inspired antenna bob
  Widget _buildRedditAntennaBobLogo() {
    final bobAmount = math.sin(_animation.value * math.pi * 4) * 10 * (1 - _animation.value);
    return Transform.translate(
      offset: Offset(0, bobAmount),
      child: Transform.rotate(
        angle: math.sin(_animation.value * math.pi * 4) * 0.1 * (1 - _animation.value),
        child: Opacity(
          opacity: _animation.value.clamp(0.0, 1.0),
          child: _buildBaseLogo(100),
        ),
      ),
    );
  }

  // Snapchat-inspired ghost fade
  Widget _buildSnapchatGhostFadeLogo() {
    final waveOffset = math.sin(_animation.value * math.pi * 3) * 8;
    return Transform.translate(
      offset: Offset(waveOffset, (1 - _animation.value) * -20),
      child: Opacity(
        opacity: _animation.value,
        child: _buildBaseLogo(100),
      ),
    );
  }

  // Apple-inspired smooth minimal fade
  Widget _buildAppleMinimalLogo() {
    return Transform.scale(
      scale: 0.95 + (_animation.value * 0.05),
      child: Opacity(
        opacity: Curves.easeInCubic.transform(_animation.value),
        child: _buildBaseLogo(100),
      ),
    );
  }

  // Amazon-inspired arrow smile
  Widget _buildAmazonArrowLogo() {
    final curveProgress = Curves.easeInOutCubic.transform(_animation.value);
    return Transform.translate(
      offset: Offset(
        math.sin(curveProgress * math.pi) * 15,
        -15 + (curveProgress * 15),
      ),
      child: Opacity(
        opacity: _animation.value,
        child: _buildBaseLogo(100),
      ),
    );
  }

  Widget _buildBaseLogo(double fillHeight) {
    final theme = Theme.of(context);
    final bool useGradient = widget.gradient != null || widget.color == null;
    
    String strokeFill;
    String fillGradientDef;
    
    if (widget.gradient != null) {
      final colors = widget.gradient is LinearGradient 
          ? (widget.gradient as LinearGradient).colors 
          : [theme.colorScheme.primary, theme.colorScheme.tertiary];
      
      strokeFill = 'url(#logoGradient)';
      fillGradientDef = _createFillGradient(colors, fillHeight);
    } else if (widget.color != null) {
      strokeFill = 'url(#logoGradient)';
      fillGradientDef = _createFillGradient([widget.color!, widget.color!], fillHeight);
    } else {
      strokeFill = 'url(#logoGradient)';
      fillGradientDef = _createFillGradient([
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
        theme.colorScheme.tertiary,
      ], fillHeight);
    }

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

  String _createFillGradient(List<Color> colors, double fillHeight) {
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

  String _colorToRgba(Color color, double opacity) {
    return 'rgba(${color.red}, ${color.green}, ${color.blue}, $opacity)';
  }
}
