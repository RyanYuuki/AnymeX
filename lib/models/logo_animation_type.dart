/// Logo Animation Types
enum LogoAnimationType {
  // Original Animations
  bottomToTop('Bottom Fill', 'Fills the logo from bottom to top'),
  fadeIn('Fade In', 'Smoothly fades in the logo'),
  scale('Scale', 'Scales up from center'),
  rotate('Rotate', 'Rotates while appearing'),
  slideRight('Slide Right', 'Slides in from left to right'),
  pulse('Pulse', 'Pulses with a heartbeat effect'),
  glitch('Glitch', 'Glitchy digital effect'),
  bounce('Bounce', 'Bounces into view'),
  wave('Wave', 'Fills with a wave effect'),
  spiral('Spiral', 'Spirals into view'),
  
  // Famous App-Inspired Animations
  netflixSwoosh('Netflix Swoosh', 'Dynamic swoosh like Netflix intro'),
  spotifyPulse('Spotify Pulse', 'Energetic pulse with glow effect'),
  tikTokGlitch('TikTok RGB Glitch', 'RGB color split glitch effect'),
  instagramGradient('Instagram Shimmer', 'Gradient reveal with light shimmer'),
  discordBounce('Discord Bounce', 'Playful elastic bounce entrance'),
  telegramFlyIn('Telegram Fly-In', 'Paper plane diagonal fly-in'),
  twitterFlip('Twitter Flip', '3D card flip transformation'),
  whatsAppBubble('WhatsApp Bubble', 'Message bubble pop effect'),
  twitchScan('Twitch Scan', 'Purple glitch scan animation'),
  redditBob('Reddit Bob', 'Antenna bobbing motion'),
  snapchatGhost('Snapchat Ghost', 'Floating ghost fade-in'),
  appleMinimal('Apple Minimal', 'Minimalist elegant fade'),
  amazonArrow('Amazon Arrow', 'Smile curve path animation'),
  
  // Custom Particle Animation
  particleConvergence('Particle Convergence', 'Colorful particles converge to form logo');

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
