/// Logo Animation Types
enum LogoAnimationType {
  // Core Professional Animations
  bottomToTop('Bottom Fill', 'Fills the logo from bottom to top with gradient mask'),
  fadeIn('Fade In', 'Smoothly fades in with subtle scale'),
  scale('Scale', 'Elastic scale up from center'),
  rotate('Rotate', '3D rotation with depth perspective'),
  slideRight('Slide Right', 'Slides in from left with momentum'),
  pulse('Pulse', 'Professional pulse with glow effect'),
  glitch('Glitch', 'Controlled chromatic aberration glitch'),
  bounce('Bounce', 'Realistic physics-based bounce'),
  wave('Wave', 'Fluid wave motion with rotation'),
  spiral('Spiral', 'Spirals into view with 3D depth'),
  
  // Advanced Particle & Physics Animations
  particleConvergence('Particle Convergence', 'Colorful particles converge with spiral motion'),
  particleExplosion('Particle Explosion', 'Logo explodes into rotating particles then reforms'),
  orbitalRings('Orbital Rings', 'Multiple rotating rings collapse with glow'),
  pixelAssembly('Pixel Assembly', 'Dynamic pixels randomly assemble with rotation'),
  liquidMorph('Liquid Morph', 'Liquid drops merge with realistic physics'),
  geometricUnfold('Geometric Unfold', 'Geometric shapes unfold with transformations');

  final String displayName;
  final String description;
  
  const LogoAnimationType(this.displayName, this.description);
  
  static LogoAnimationType fromIndex(int index) {
    if (index < 0 || index >= LogoAnimationType.values.length) {
      return LogoAnimationType.bottomToTop;
    }
    return LogoAnimationType.values[index];
  }
}
