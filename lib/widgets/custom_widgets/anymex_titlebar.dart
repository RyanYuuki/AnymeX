import 'dart:io';

import 'package:anymex/widgets/custom_widgets/anymex_animated_logo.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:win32/win32.dart';
import 'dart:ffi';

class AnymexTitleBar {
  static final ValueNotifier<bool> isFullScreen = ValueNotifier(false);
  static final ValueNotifier<bool> isMaximized = ValueNotifier(false);

  static Future<void> initialize() async {
    if (!Platform.isWindows) {
      await windowManager.waitUntilReadyToShow(
        const WindowOptions(
          backgroundColor: null,
          titleBarStyle: TitleBarStyle.normal,
          skipTaskbar: null,
        ),
      );
      return;
    }

    const windowOptions = WindowOptions(
      backgroundColor: null,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();

      AnymexTitleBar.isMaximized.value = await windowManager.isMaximized();
      windowManager.addListener(_WindowListener());
    });
  }

  static void listenToWin32() {
    final hwnd = GetForegroundWindow();

    final placement = calloc<WINDOWPLACEMENT>();
    GetWindowPlacement(hwnd, placement);

    final isMaximized = placement.ref.showCmd == SW_SHOWMAXIMIZED;
    AnymexTitleBar.isMaximized.value = isMaximized;

    calloc.free(placement);
  }

  static Widget titleBar() => ValueListenableBuilder<bool>(
        valueListenable: isFullScreen,
        builder: (_, fullscreen, __) {
          return fullscreen ? const SizedBox.shrink() : const _TitleBarWidget();
        },
      );

  static Future<void> setFullScreen(bool enable) async {
    await windowManager.setFullScreen(enable);
    isFullScreen.value = enable;
  }

  static Future<void> toggleFullScreen() async {
    await windowManager.setFullScreen(!isFullScreen.value);
    isFullScreen.value = !isFullScreen.value;
  }
}

class _WindowListener extends WindowListener {
  Future<void> _sync() async {
    AnymexTitleBar.isMaximized.value = await windowManager.isMaximized();
  }

  @override
  void onWindowMaximize() => _sync();

  @override
  void onWindowUnmaximize() => _sync();

  @override
  void onWindowResized() async {
    if (Platform.isWindows) {
      AnymexTitleBar.listenToWin32();
    }
  }
}

class _TitleBarWidget extends StatelessWidget {
  const _TitleBarWidget();

  Future<void> _toggleMaximize() async {
    final maximized = await windowManager.isMaximized();
    if (maximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }

    AnymexTitleBar.isMaximized.value = await windowManager.isMaximized();
  }

  @override
  Widget build(BuildContext context) {
    final isOled = Provider.of<ThemeProvider>(context).isOled;
    final defaultColor = context.colors.onSurface;

    return RepaintBoundary(
        child: Material(
      color: Colors.transparent,
      child: ClipRect(
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isOled ? Colors.black : Colors.black.opaque(0.2),
            border: Border(
              bottom: BorderSide(
                color: isOled ? Colors.transparent : defaultColor.opaque(0.1),
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
                  color: defaultColor.opaque(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnymeXAnimatedLogo(
                  size: 18,
                  autoPlay: true,
                  color: defaultColor,
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
                  onPanStart: (_) {
                    windowManager.startDragging();
                  },
                  onDoubleTap: _toggleMaximize,
                ),
              ),
              _WindowButton(
                icon: Icons.remove,
                onPressed: () => windowManager.minimize(),
                buttonColor: defaultColor,
              ),
              ValueListenableBuilder<bool>(
                valueListenable: AnymexTitleBar.isMaximized,
                builder: (_, isMaximized, __) {
                  return _WindowButton(
                    icon: isMaximized
                        ? Icons.filter_none_rounded
                        : Icons.crop_square_rounded,
                    onPressed: _toggleMaximize,
                    buttonColor: defaultColor,
                  );
                },
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
    ));
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
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

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
                      ? Colors.red.opaque(0.9)
                      : widget.buttonColor.opaque(isDark ? 0.15 : 0.1))
                  : Colors.transparent,
            ),
            child: Center(
              child: Icon(
                widget.icon,
                size: widget.isClose ? 18 : 16,
                color: isHovered && widget.isClose
                    ? Colors.white
                    : widget.buttonColor.opaque(0.9),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
