/// Logo Animation Types

enum LogoAnimationType {
  bottomToTop('Bottom Fill', 'Fills the logo from bottom to top'),
  fadeIn('Fade In', 'Smoothly fades in the logo'),
  scale('Scale', 'Scales up from center'),
  rotate('Rotate', 'Rotates while appearing'),
  slideRight('Slide Right', 'Slides in from left to right'),
  pulse('Pulse', 'Pulses with a heartbeat effect'),
  glitch('Glitch', 'Glitchy digital effect'),
  bounce('Bounce', 'Bounces into view'),
  wave('Wave', 'Fills with a wave effect'),
  spiral('Spiral', 'Spirals into view');

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
