import 'dart:math' as math;

import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/logo_animation_type.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    _animationType = widget.forceAnimationType ?? _getStoredAnimationType();
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
      final index = ThemeKeys.logoAnimationType.get<int>(0);
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
        return Curves.easeInOutQuad;
      case LogoAnimationType.bounce:
        return Curves.bounceOut;
      case LogoAnimationType.spiral:
        return Curves.easeInOutQuart;
      case LogoAnimationType.particleConvergence:
        return Curves.easeInOutCubic;
      case LogoAnimationType.particleExplosion:
        return Curves.easeInOutCubic;
      case LogoAnimationType.orbitalRings:
        return Curves.easeInOutQuart;
      case LogoAnimationType.pixelAssembly:
        return Curves.easeOut;
      case LogoAnimationType.liquidMorph:
        return Curves.easeInOutSine;
      case LogoAnimationType.geometricUnfold:
        return Curves.easeInOutCubic;
      case LogoAnimationType.matrixRain:
        return Curves.easeInOut;
      case LogoAnimationType.shatter:
        return Curves.easeOutBack;
      case LogoAnimationType.hologram:
        return Curves.easeInOutCubic;
      case LogoAnimationType.vortex:
        return Curves.easeInOutQuart;
    }
  }

  Future<void> _startAnimation() async {
    await _controller.forward();
    widget.onAnimationComplete?.call();
  }

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
          // Don't show anything during initial delay
          if (_animation.value < 0.05) {
            return const SizedBox.shrink();
          }
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
      case LogoAnimationType.particleConvergence:
        return _buildParticleConvergenceLogo();
      case LogoAnimationType.particleExplosion:
        return _buildParticleExplosionLogo();
      case LogoAnimationType.orbitalRings:
        return _buildOrbitalRingsLogo();
      case LogoAnimationType.pixelAssembly:
        return _buildPixelAssemblyLogo();
      case LogoAnimationType.liquidMorph:
        return _buildLiquidMorphLogo();
      case LogoAnimationType.geometricUnfold:
        return _buildGeometricUnfoldLogo();
      case LogoAnimationType.matrixRain:
        return _buildMatrixRainLogo();
      case LogoAnimationType.shatter:
        return _buildShatterLogo();
      case LogoAnimationType.hologram:
        return _buildHologramLogo();
      case LogoAnimationType.vortex:
        return _buildVortexLogo();
    }
  }

  // bottom to top
  Widget _buildBottomToTopLogo() {
    return ClipRect(
      child: _buildBaseLogo(_animation.value * 100),
    );
  }

  // fade in
  Widget _buildFadeInLogo() {
    final scale = 0.95 + (_animation.value * 0.05);
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: _animation.value,
        child: _buildBaseLogo(100),
      ),
    );
  }

  // scale
  Widget _buildScaleLogo() {
    return Transform.scale(
      scale: _animation.value,
      child: Opacity(
        opacity: _animation.value.clamp(0.0, 1.0),
        child: _buildBaseLogo(100),
      ),
    );
  }

  // rotation
  Widget _buildRotateLogo() {
    final rotationAngle = (1 - _animation.value) * math.pi * 1.5;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateY(rotationAngle),
      child: Opacity(
        opacity: _animation.value,
        child: _buildBaseLogo(100),
      ),
    );
  }

  // horizontal slide
  Widget _buildSlideRightLogo() {
    final slideValue = Curves.easeOutCubic.transform(_animation.value);
    return Transform.translate(
      offset: Offset((1 - slideValue) * -widget.size * 1.2, 0),
      child: Opacity(
        opacity: _animation.value.clamp(0.0, 1.0),
        child: _buildBaseLogo(100),
      ),
    );
  }

  // pulse
  Widget _buildPulseLogo() {
    final pulseScale = 0.85 +
        (math.sin(_animation.value * math.pi * 3) * 0.08) +
        (_animation.value * 0.15);
    final glowIntensity = math.sin(_animation.value * math.pi * 2) * 0.3;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (glowIntensity > 0)
          Opacity(
            opacity: glowIntensity,
            child: Transform.scale(
              scale: pulseScale * 1.15,
              child: _buildBaseLogo(100),
            ),
          ),
        Transform.scale(
          scale: pulseScale,
          child: Opacity(
            opacity: _animation.value.clamp(0.0, 1.0),
            child: _buildBaseLogo(100),
          ),
        ),
      ],
    );
  }

  // glitch
  Widget _buildGlitchLogo() {
    final phase = (_animation.value * 5) % 1.0;
    final glitchActive = phase > 0.85;
    final glitchOffset =
        glitchActive ? (math.Random().nextDouble() - 0.5) * 8 : 0.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (glitchActive)
          Transform.translate(
            offset: Offset(-glitchOffset * 1.5, glitchOffset * 0.5),
            child: Opacity(
              opacity: 0.4,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.cyan.opaque(0.7, iReallyMeanIt: true),
                  BlendMode.modulate,
                ),
                child: _buildBaseLogo(100),
              ),
            ),
          ),
        if (glitchActive)
          Transform.translate(
            offset: Offset(glitchOffset * 1.5, -glitchOffset * 0.5),
            child: Opacity(
              opacity: 0.4,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.red.opaque(0.7, iReallyMeanIt: true),
                  BlendMode.modulate,
                ),
                child: _buildBaseLogo(100),
              ),
            ),
          ),
        Transform.translate(
          offset: Offset(glitchOffset * 0.3, 0),
          child: Opacity(
            opacity: _animation.value.clamp(0.0, 1.0),
            child: _buildBaseLogo(100),
          ),
        ),
      ],
    );
  }

  // bounce
  Widget _buildBounceLogo() {
    final bounceProgress = Curves.bounceOut.transform(_animation.value);
    return Transform.translate(
      offset: Offset(0, (1 - bounceProgress) * -widget.size * 0.6),
      child: Opacity(
        opacity: _animation.value.clamp(0.0, 1.0),
        child: _buildBaseLogo(100),
      ),
    );
  }

  // Professional wave animation with fluid motion
  Widget _buildWaveLogo() {
    final wavePhase = _animation.value * math.pi * 2;
    final waveAmplitude = (1 - _animation.value) * 12;
    final xOffset = math.sin(wavePhase) * waveAmplitude;
    final yOffset = math.cos(wavePhase * 1.5) * waveAmplitude * 0.5;

    return Transform.translate(
      offset: Offset(xOffset, yOffset),
      child: Transform.rotate(
        angle: math.sin(wavePhase) * 0.08,
        child: Opacity(
          opacity: _animation.value.clamp(0.0, 1.0),
          child: _buildBaseLogo(_animation.value * 100),
        ),
      ),
    );
  }

  // spiral
  Widget _buildSpiralLogo() {
    final spiralAngle = (1 - _animation.value) * math.pi * 3;
    final spiralScale = _animation.value * _animation.value;
    final distance = (1 - _animation.value) * widget.size * 0.3;

    return Transform.translate(
      offset: Offset(
        math.cos(spiralAngle) * distance,
        math.sin(spiralAngle) * distance,
      ),
      child: Transform.rotate(
        angle: spiralAngle,
        child: Transform.scale(
          scale: spiralScale,
          child: Opacity(
            opacity: _animation.value,
            child: _buildBaseLogo(100),
          ),
        ),
      ),
    );
  }

  // PARTICLE CONVERGENCE
  Widget _buildParticleConvergenceLogo() {
    // Adjust timing so animation starts after initial delay
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final particlePhase = adjustedProgress.clamp(0.0, 0.5) / 0.5;
    final convergePhase = (adjustedProgress - 0.4).clamp(0.0, 0.5) / 0.5;
    final logoPhase = (adjustedProgress - 0.7).clamp(0.0, 0.3) / 0.3;

    final particles = List.generate(16, (index) {
      final angle = (index / 16) * 2 * math.pi;
      final radius = widget.size * 0.5;
      final startX = math.cos(angle) * radius;
      final startY = math.sin(angle) * radius;

      final spiralFactor = math.sin(particlePhase * math.pi * 2 + index * 0.3);
      final moveX = startX + (math.cos(angle + spiralFactor) * 40);
      final moveY = startY + (math.sin(angle + spiralFactor) * 40);

      final currentX = convergePhase < 1.0 ? moveX * (1 - convergePhase) : 0.0;
      final currentY = convergePhase < 1.0 ? moveY * (1 - convergePhase) : 0.0;

      final colorPhase = (particlePhase + (index / 16)) % 1.0;
      final particleColor =
          HSVColor.fromAHSV(1.0, colorPhase * 360, 0.9, 1.0).toColor();
      final particleSize =
          10.0 + (math.sin(particlePhase * math.pi + index) * 4);
      final particleOpacity =
          convergePhase < 0.9 ? 1.0 : 1.0 - ((convergePhase - 0.9) / 0.1);

      return Positioned(
        left: widget.size / 2 + currentX - particleSize / 2,
        top: widget.size / 2 + currentY - particleSize / 2,
        child: Opacity(
          opacity: particleOpacity,
          child: Container(
            width: particleSize,
            height: particleSize,
            decoration: BoxDecoration(
              color: particleColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: particleColor.opaque(0.8, iReallyMeanIt: true),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        ),
      );
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        ...particles,
        if (logoPhase > 0)
          Transform.scale(
            scale: Curves.easeOutBack.transform(logoPhase),
            child: Opacity(
              opacity: logoPhase,
              child: _buildBaseLogo(logoPhase * 100),
            ),
          ),
      ],
    );
  }

  // PARTICLE EXPLOSION
  Widget _buildParticleExplosionLogo() {
    // Adjust timing
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final initialPhase = (adjustedProgress.clamp(0.0, 0.2) / 0.2);
    final explosionPhase = (adjustedProgress.clamp(0.2, 0.5) / 0.3);
    final reformPhase = (adjustedProgress - 0.5).clamp(0.0, 0.5) / 0.5;

    final logoOpacity = adjustedProgress < 0.2
        ? 1.0 - initialPhase
        : adjustedProgress > 0.6
            ? reformPhase
            : 0.0;
    final particles = List.generate(24, (index) {
      final angle = (index / 24) * 2 * math.pi;
      final speed = 0.8 + (math.Random(index).nextDouble() * 0.4);
      final distance = explosionPhase * widget.size * 0.9 * speed;
      final x = math.cos(angle) * distance * (1 - reformPhase);
      final y = math.sin(angle) * distance * (1 - reformPhase);

      final rotation = explosionPhase * math.pi * 6 * (1 - reformPhase);
      final particleOpacity =
          adjustedProgress > 0.15 && adjustedProgress < 0.85 ? 1.0 : 0.0;

      final colorIndex = (index / 24);
      final color =
          HSVColor.fromAHSV(1.0, colorIndex * 360, 0.95, 1.0).toColor();
      final particleSize = 8.0 + (index % 3) * 3.0;

      return Positioned(
        left: widget.size / 2 + x - particleSize / 2,
        top: widget.size / 2 + y - particleSize / 2,
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(
            opacity: particleOpacity,
            child: Container(
              width: particleSize,
              height: particleSize,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [color, color.opaque(0.6, iReallyMeanIt: true)],
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: color.opaque(0.6, iReallyMeanIt: true),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        ...particles,
        if (logoOpacity > 0)
          Transform.scale(
            scale: Curves.easeOutBack.transform(logoOpacity),
            child: Opacity(
              opacity: logoOpacity,
              child: _buildBaseLogo(logoOpacity * 100),
            ),
          ),
      ],
    );
  }

  // ORBITAL RINGS
  Widget _buildOrbitalRingsLogo() {
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final ringPhase = adjustedProgress.clamp(0.0, 0.7) / 0.7;
    final logoPhase = (adjustedProgress - 0.5).clamp(0.0, 0.5) / 0.5;

    final rings = List.generate(5, (index) {
      final ringSize = widget.size * (0.3 + (index * 0.18));
      final rotationSpeed = (index % 2 == 0 ? 1 : -1) * (1 + index * 0.3);
      final rotation = ringPhase * math.pi * 2.5 * rotationSpeed;
      final scale = 1.2 - (ringPhase * (0.9 - index * 0.12));
      final opacity = (1.0 - ringPhase) * (1.0 - index * 0.15);

      final colors = [
        Colors.cyan,
        Colors.purple,
        Colors.pink,
        Colors.amber,
        Colors.teal,
      ];

      return Transform.rotate(
        angle: rotation,
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors[index],
                  width: 3.0 + (index * 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors[index].opaque(0.5, iReallyMeanIt: true),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        ...rings,
        if (logoPhase > 0)
          Transform.scale(
            scale: Curves.easeOutBack.transform(logoPhase),
            child: Opacity(
              opacity: logoPhase,
              child: _buildBaseLogo(logoPhase * 100),
            ),
          ),
      ],
    );
  }

  // PIXEL ASSEMBLY
  Widget _buildPixelAssemblyLogo() {
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;
    final assemblyPhase = adjustedProgress;
    final logoPhase = (adjustedProgress - 0.7).clamp(0.0, 0.3) / 0.3;

    final gridSize = 10;
    final pixels = <Widget>[];

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final pixelIndex = i * gridSize + j;
        final totalPixels = gridSize * gridSize;
        final random = math.Random(pixelIndex);
        final appearTime = (random.nextDouble() * 0.5) + 0.1;
        final pixelProgress =
            (assemblyPhase - appearTime).clamp(0.0, 0.3) / 0.3;

        if (pixelProgress > 0) {
          final pixelSize = widget.size / gridSize;
          final startAngle = random.nextDouble() * math.pi * 2;
          final startDistance = random.nextDouble() * widget.size * 1.5;
          final startX = math.cos(startAngle) * startDistance;
          final startY = math.sin(startAngle) * startDistance;

          final currentX = startX * (1 - pixelProgress);
          final currentY = startY * (1 - pixelProgress);

          final colorValue = (pixelIndex / totalPixels);
          final color = HSVColor.fromAHSV(
            1.0,
            (colorValue * 360 + assemblyPhase * 60) % 360,
            0.8,
            0.95,
          ).toColor();

          pixels.add(
            Positioned(
              left: (i * pixelSize) + currentX,
              top: (j * pixelSize) + currentY,
              child: Transform.rotate(
                angle: (1 - pixelProgress) * math.pi * 2,
                child: Opacity(
                  opacity: pixelProgress,
                  child: Container(
                    width: pixelSize - 1.5,
                    height: pixelSize - 1.5,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: color.opaque(0.4, iReallyMeanIt: true),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        if (assemblyPhase < 0.8)
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(children: pixels),
          ),
        if (logoPhase > 0)
          Opacity(
            opacity: logoPhase,
            child: _buildBaseLogo(logoPhase * 100),
          ),
      ],
    );
  }

  // LIQUID MORPH
  Widget _buildLiquidMorphLogo() {
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final dropPhase = adjustedProgress.clamp(0.0, 0.4) / 0.4;
    final mergePhase = (adjustedProgress - 0.3).clamp(0.0, 0.5) / 0.5;
    final logoPhase = (adjustedProgress - 0.6).clamp(0.0, 0.4) / 0.4;

    final drops = List.generate(10, (index) {
      final angle = (index / 10) * 2 * math.pi;
      final radius = widget.size * 0.45;
      final startX = math.cos(angle) * radius;
      final startY = math.sin(angle) * radius - widget.size * 0.4;

      final gravity = dropPhase * dropPhase;
      final bounceHeight = startY + (widget.size * 0.4 * gravity);
      final elasticity =
          dropPhase > 0.8 ? math.sin((dropPhase - 0.8) * math.pi * 5) * 5 : 0.0;

      final currentX = startX * (1 - mergePhase);
      final currentY = (bounceHeight + elasticity) * (1 - mergePhase);

      final dropSize = 12.0 +
          (mergePhase * 15) +
          (math.sin(dropPhase * math.pi * 3 + index) * 3);
      final opacity = adjustedProgress < 0.75 ? 1.0 : 1.0 - logoPhase;

      final colors = [
        Colors.blue.shade400,
        Colors.cyan.shade400,
        Colors.teal.shade400,
        Colors.lightBlue.shade300,
        Colors.indigo.shade400,
        Colors.blue.shade600,
        Colors.cyan.shade600,
        Colors.teal.shade600,
        Colors.lightBlue.shade500,
        Colors.indigo.shade600,
      ];

      return Positioned(
        left: widget.size / 2 + currentX - dropSize / 2,
        top: widget.size / 2 + currentY - dropSize / 2,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: dropSize,
            height: dropSize,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  colors[index].opaque(0.9, iReallyMeanIt: true),
                  colors[index],
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors[index].opaque(0.6, iReallyMeanIt: true),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      );
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        ...drops,
        if (logoPhase > 0)
          Transform.scale(
            scale: Curves.easeOutBack.transform(logoPhase),
            child: Opacity(
              opacity: logoPhase,
              child: _buildBaseLogo(logoPhase * 100),
            ),
          ),
      ],
    );
  }

  // GEOMETRIC UNFOLD
  Widget _buildGeometricUnfoldLogo() {
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final unfoldPhase = adjustedProgress.clamp(0.0, 0.7) / 0.7;
    final logoPhase = (adjustedProgress - 0.5).clamp(0.0, 0.5) / 0.5;

    final shapes = List.generate(8, (index) {
      final angle = (index / 8) * 2 * math.pi;
      final distance = (1 - unfoldPhase) * widget.size * 0.6;
      final x = math.cos(angle) * distance;
      final y = math.sin(angle) * distance;

      final rotation = unfoldPhase * math.pi * 3 + (index * math.pi / 4);
      final scale = 1.2 - (unfoldPhase * 0.7);

      final shapeColors = [
        Colors.red.shade400,
        Colors.orange.shade400,
        Colors.amber.shade400,
        Colors.lime.shade400,
        Colors.green.shade400,
        Colors.cyan.shade400,
        Colors.blue.shade400,
        Colors.purple.shade400,
      ];

      Widget shape;
      final shapeType = index % 4;

      if (shapeType == 0) {
        shape = CustomPaint(
          size: const Size(45, 45),
          painter: _TrianglePainter(shapeColors[index]),
        );
      } else if (shapeType == 1) {
        shape = Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: shapeColors[index],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: shapeColors[index].opaque(0.6, iReallyMeanIt: true),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      } else if (shapeType == 2) {
        shape = Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: shapeColors[index],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: shapeColors[index].opaque(0.6, iReallyMeanIt: true),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      } else {
        shape = Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: shapeColors[index],
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: shapeColors[index].opaque(0.6, iReallyMeanIt: true),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      }

      return Positioned(
        left: widget.size / 2 + x - 22.5,
        top: widget.size / 2 + y - 22.5,
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: 1.0 - unfoldPhase,
              child: shape,
            ),
          ),
        ),
      );
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        ...shapes,
        if (logoPhase > 0)
          Transform.scale(
            scale: Curves.easeOutBack.transform(logoPhase),
            child: Opacity(
              opacity: logoPhase,
              child: _buildBaseLogo(logoPhase * 100),
            ),
          ),
      ],
    );
  }

  // MATRIX RAIN
  Widget _buildMatrixRainLogo() {
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final rainPhase = adjustedProgress.clamp(0.0, 0.6) / 0.6;
    final formPhase = (adjustedProgress - 0.4).clamp(0.0, 0.6) / 0.6;
    final logoPhase = (adjustedProgress - 0.7).clamp(0.0, 0.3) / 0.3;

    final columns = 15;
    final rainDrops = List.generate(columns, (col) {
      final drops = <Widget>[];
      final dropsPerColumn = 8;

      for (int row = 0; row < dropsPerColumn; row++) {
        final random = math.Random(col * 100 + row);
        final dropDelay = random.nextDouble() * 0.3;
        final dropProgress = (rainPhase - dropDelay).clamp(0.0, 1.0);

        if (dropProgress > 0) {
          final x = (col / columns) * widget.size;
          final fallDistance = dropProgress * widget.size * 1.3;
          final y = -20.0 + fallDistance - (row * 25);

          final opacity =
              dropProgress < 0.8 ? 1.0 : 1.0 - ((dropProgress - 0.8) / 0.2);
          final fade = formPhase > 0 ? 1.0 - formPhase : 1.0;

          final brightness = 1.0 - (row / dropsPerColumn) * 0.6;

          drops.add(
            Positioned(
              left: x,
              top: y,
              child: Opacity(
                opacity: opacity * fade,
                child: Container(
                  width: widget.size / columns * 0.8,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.lightGreen
                            .opaque(brightness, iReallyMeanIt: true),
                        Colors.green
                            .opaque(brightness * 0.3, iReallyMeanIt: true),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green
                            .opaque(0.5 * brightness, iReallyMeanIt: true),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(33 + random.nextInt(94)),
                      style: TextStyle(
                        color: Colors.white
                            .opaque(brightness, iReallyMeanIt: true),
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
      return drops;
    }).expand((x) => x).toList();

    return Stack(
      alignment: Alignment.center,
      children: [
        if (formPhase < 1.0) ...rainDrops,
        if (logoPhase > 0)
          Transform.scale(
            scale: Curves.easeOutBack.transform(logoPhase),
            child: Opacity(
              opacity: logoPhase,
              child: _buildBaseLogo(logoPhase * 100),
            ),
          ),
      ],
    );
  }

  // SHATTER
  Widget _buildShatterLogo() {
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final shatterPhase = adjustedProgress.clamp(0.0, 0.5) / 0.5;
    final reformPhase = (adjustedProgress - 0.5).clamp(0.0, 0.5) / 0.5;

    final shards = List.generate(20, (index) {
      final angle = (index / 20) * 2 * math.pi;
      final random = math.Random(index);
      final distance =
          shatterPhase * widget.size * (0.6 + random.nextDouble() * 0.4);
      final x = math.cos(angle) * distance * (1 - reformPhase);
      final y = math.sin(angle) * distance * (1 - reformPhase);

      final rotation = shatterPhase *
          (random.nextDouble() * math.pi * 4 - math.pi * 2) *
          (1 - reformPhase);
      final scale = 0.3 + (shatterPhase * 0.7) * (1 - reformPhase * 0.5);

      final shardOpacity = adjustedProgress < 0.2
          ? 1.0 - (adjustedProgress / 0.2)
          : adjustedProgress > 0.8
              ? reformPhase
              : 0.8;

      final colors = [
        Colors.cyan.shade200,
        Colors.blue.shade200,
        Colors.lightBlue.shade200,
        Colors.teal.shade200,
      ];
      final color = colors[index % colors.length];

      return Positioned(
        left: widget.size / 2 + x - 25,
        top: widget.size / 2 + y - 25,
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: shardOpacity,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.opaque(0.3, iReallyMeanIt: true),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.white.opaque(0.5, iReallyMeanIt: true),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.opaque(0.4, iReallyMeanIt: true),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });

    final logoOpacity = adjustedProgress < 0.15
        ? 1.0 - (adjustedProgress / 0.15)
        : adjustedProgress > 0.7
            ? reformPhase
            : 0.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (adjustedProgress > 0.1 && adjustedProgress < 0.9) ...shards,
        if (logoOpacity > 0)
          Transform.scale(
            scale: Curves.easeOutBack.transform(logoOpacity),
            child: Opacity(
              opacity: logoOpacity,
              child: _buildBaseLogo(logoOpacity * 100),
            ),
          ),
      ],
    );
  }

  // HOLOGRAM
  Widget _buildHologramLogo() {
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final scanPhase = adjustedProgress.clamp(0.0, 0.6) / 0.6;
    final stabilizePhase = (adjustedProgress - 0.5).clamp(0.0, 0.5) / 0.5;

    final flickerOffset = adjustedProgress < 0.7
        ? math.sin(adjustedProgress * math.pi * 30) * 2 * (1 - stabilizePhase)
        : 0.0;

    final scanLineY = -widget.size + (scanPhase * widget.size * 2);
    final glitchActive = adjustedProgress > 0.3 &&
        adjustedProgress < 0.6 &&
        ((adjustedProgress * 20) % 1.0) > 0.8;

    final logoOpacity = adjustedProgress.clamp(0.2, 0.9);
    final hologramColor = Colors.cyan.shade400;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (scanPhase < 1.0)
          Positioned(
            top: scanLineY,
            child: Container(
              width: widget.size,
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    hologramColor,
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: hologramColor.opaque(0.8, iReallyMeanIt: true),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        if (glitchActive)
          Transform.translate(
            offset: Offset(flickerOffset * 3, 0),
            child: Opacity(
              opacity: 0.3,
              child: _buildBaseLogo(logoOpacity * 100),
            ),
          ),
        Transform.translate(
          offset: Offset(flickerOffset, 0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0.4 * logoOpacity,
                child: Transform.scale(
                  scale: 1.1,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      hologramColor,
                      BlendMode.srcATop,
                    ),
                    child: _buildBaseLogo(logoOpacity * 100),
                  ),
                ),
              ),
              Opacity(
                opacity: logoOpacity * 0.9,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    hologramColor.opaque(0.6, iReallyMeanIt: true),
                    BlendMode.modulate,
                  ),
                  child: _buildBaseLogo(logoOpacity * 100),
                ),
              ),
            ],
          ),
        ),
        ...List.generate(8, (index) {
          return Positioned(
            top: (index / 8) * widget.size,
            child: Opacity(
              opacity: 0.1 * logoOpacity,
              child: Container(
                width: widget.size,
                height: 1,
                color: Colors.cyan.shade100,
              ),
            ),
          );
        }),
      ],
    );
  }

  // VORTEX
  Widget _buildVortexLogo() {
    final adjustedProgress = (_animation.value - 0.05).clamp(0.0, 0.95) / 0.95;

    final vortexPhase = adjustedProgress.clamp(0.0, 0.7) / 0.7;
    final logoPhase = (adjustedProgress - 0.5).clamp(0.0, 0.5) / 0.5;

    final rings = List.generate(12, (index) {
      final progress = (vortexPhase - (index * 0.05)).clamp(0.0, 1.0);
      final ringSize = widget.size * (0.1 + index * 0.08) * progress;
      final depth = (1 - progress) * 0.8;
      final rotation = progress * math.pi * 6 + (index * math.pi / 6);

      final opacity = progress < 0.8
          ? (progress * 1.2).clamp(0.0, 1.0)
          : 1.0 - ((progress - 0.8) / 0.2);

      final zDepth = 1.0 - (depth * 0.5);

      final colors = [
        Colors.purple.shade400,
        Colors.deepPurple.shade400,
        Colors.indigo.shade400,
        Colors.blue.shade400,
      ];
      final color = colors[index % colors.length];

      return Transform.scale(
        scale: zDepth,
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(
            opacity: opacity * (1 - logoPhase),
            child: Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.opaque(0.6, iReallyMeanIt: true),
                    blurRadius: 12 * zDepth,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        ...rings,
        if (logoPhase > 0)
          Transform.scale(
            scale: Curves.easeOutBack.transform(logoPhase),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX((1 - logoPhase) * math.pi * 0.5),
              child: Opacity(
                opacity: logoPhase,
                child: _buildBaseLogo(logoPhase * 100),
              ),
            ),
          ),
      ],
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
      fillGradientDef =
          _createFillGradient([widget.color!, widget.color!], fillHeight);
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
      gradientStops +=
          '<stop offset="$offset%" stop-color="${_colorToRgba(colors[i], 1.0)}" />';
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

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawShadow(path, color.opaque(0.5, iReallyMeanIt: true), 10.0, true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
