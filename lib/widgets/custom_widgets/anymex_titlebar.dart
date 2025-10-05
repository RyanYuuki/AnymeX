import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class AnymexTitleBar {
  static final ValueNotifier<bool> isFullScreen = ValueNotifier(false);

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  static Widget titleBar() => ValueListenableBuilder<bool>(
        valueListenable: isFullScreen,
        builder: (_, fullscreen, __) {
          return fullscreen ? const SizedBox.shrink() : _TitleBarWidget();
        },
      );

  static Future<void> setFullScreen(bool enable) async {
    windowManager.setFullScreen(enable);
    isFullScreen.value = enable;
  }
}

class _TitleBarWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final defaultColor = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: ClipRect(
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            border: Border(
              bottom: BorderSide(
                color: defaultColor.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: defaultColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AnymeX',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: defaultColor,
                  letterSpacing: 0.5,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (details) {
                    windowManager.startDragging();
                  },
                  onDoubleTap: () async {
                    bool isMaximized = await windowManager.isMaximized();
                    if (isMaximized) {
                      windowManager.unmaximize();
                    } else {
                      windowManager.maximize();
                    }
                  },
                ),
              ),
              _WindowButton(
                icon: Icons.remove,
                onPressed: () => windowManager.minimize(),
                buttonColor: defaultColor,
              ),
              _WindowButton(
                icon: Icons.crop_square_rounded,
                onPressed: () async {
                  bool isMaximized = await windowManager.isMaximized();
                  if (isMaximized) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                },
                buttonColor: defaultColor,
              ),
              _WindowButton(
                icon: Icons.close_rounded,
                onPressed: () => windowManager.close(),
                isClose: true,
                buttonColor: defaultColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;
  final Color buttonColor;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
    required this.buttonColor,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton>
    with SingleTickerProviderStateMixin {
  bool isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 46,
            height: 40,
            decoration: BoxDecoration(
              color: isHovered
                  ? (widget.isClose
                      ? Colors.red.withOpacity(0.9)
                      : widget.buttonColor.withOpacity(isDark ? 0.15 : 0.1))
                  : Colors.transparent,
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.icon,
                  size: widget.isClose ? 18 : 16,
                  color: isHovered && widget.isClose
                      ? Colors.white
                      : widget.buttonColor.withOpacity(0.9),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
