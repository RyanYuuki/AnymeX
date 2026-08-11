import 'dart:io';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:anymex/widgets/common/grain_texture.dart';

enum GradientVariant {
  subtle,
  softVignette,
  centerFocus,
  edgeFade,
  warmTone,
  coolTone,
  dynamicFlow,
  minimalDark,
}

class AnymeXScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final List<Widget>? persistentFooterButtons;
  final Widget? drawer;
  final DrawerCallback? onDrawerChanged;
  final Widget? endDrawer;
  final DrawerCallback? onEndDrawerChanged;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool primary;
  final bool? extendBody;

  final DragStartBehavior drawerDragStartBehavior;
  final double? drawerEdgeDragWidth;
  final bool drawerEnableOpenDragGesture;
  final bool endDrawerEnableOpenDragGesture;
  final String? restorationId;

  final Alignment begin;
  final Alignment end;
  final String color;
  final bool disabled;
  final bool isTabScreen;

  final bool showHeader;
  final String? headerTitle;
  final String? headerSubtitle;
  final Widget? headerAction;
  final bool headerEnableSearch;
  final TextEditingController? headerSearchController;
  final ValueChanged<String>? onHeaderSearchChanged;
  final ValueChanged<String>? onHeaderSearchSubmitted;
  final VoidCallback? onHeaderSearchClear;
  final String headerSearchHint;

  const AnymeXScaffold({
    super.key,
    this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.extendBody,
    this.drawer,
    this.onDrawerChanged,
    this.endDrawer,
    this.onEndDrawerChanged,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.color = '',
    this.disabled = false,
    this.isTabScreen = false,
    this.showHeader = false,
    this.headerTitle,
    this.headerSubtitle,
    this.headerAction,
    this.headerEnableSearch = false,
    this.headerSearchController,
    this.onHeaderSearchChanged,
    this.onHeaderSearchSubmitted,
    this.onHeaderSearchClear,
    this.headerSearchHint = 'Search...',
  });

  static final Map<String, ColorScheme> _colorSchemeCache = {};

  ColorScheme _getTheme(BuildContext context, Settings settings) {
    if (color.isEmpty || !settings.usePosterColor) {
      return context.colors;
    }
    final brightnessName = Theme.of(context).brightness.name;
    final key = '${color}_$brightnessName';
    return _colorSchemeCache.putIfAbsent(key, () {
      final parsedColor = _parseColor(color) ?? context.colors.primary;
      return ColorScheme.fromSeed(
        brightness: Theme.of(context).brightness,
        seedColor: parsedColor,
      );
    });
  }

  static Color? _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<Settings>();
    final theme = _getTheme(context, settings);
    final isDesktop = Platform.isWindows;
    final isOled = Provider.of<ThemeProvider>(context).isOled;

    final resolvedBody = showHeader
        ? _HeaderBodyShell(
            title: headerTitle ?? '',
            subtitle: headerSubtitle,
            action: headerAction,
            enableSearch: headerEnableSearch,
            searchController: headerSearchController,
            onSearchChanged: onHeaderSearchChanged,
            onSearchSubmitted: onHeaderSearchSubmitted,
            onSearchClear: onHeaderSearchClear,
            searchHint: headerSearchHint,
            child: body ?? const SizedBox.shrink(),
          )
        : body;

    final scaffold = Scaffold(
      appBar: appBar,
      body: resolvedBody,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      persistentFooterButtons: persistentFooterButtons,
      drawer: drawer,
      extendBody: extendBody ?? false,
      onDrawerChanged: onDrawerChanged,
      endDrawer: endDrawer,
      onEndDrawerChanged: onEndDrawerChanged,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor ?? Colors.transparent,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      primary: primary,
      drawerDragStartBehavior: drawerDragStartBehavior,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
      restorationId: restorationId,
    );

    final ch = (isDesktop && !disabled)
        ? Container(
            margin: const EdgeInsets.only(top: 40),
            child: scaffold,
          )
        : scaffold;

    if (disabled || (isOled && isDesktop)) {
      return Container(
        color: isOled
            ? Colors.black
            : isTabScreen
                ? Colors.transparent
                : theme.surface,
        child: ch,
      );
    }

    return Obx(() {
      settings.liquidBackgroundPath;
      final liquidMode = settings.liquidMode;

      Widget content;
      if (liquidMode) {
        content = _buildLiquidMode(
          context: context,
          theme: theme,
          isOled: isOled,
          child: ch,
        );
      } else {
        content = Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: isOled ? Colors.black : theme.surface,
              ),
            ),
            if (!settings.disableGradient && !isOled)
              Positioned.fill(
                child: _buildLightweightGlow(
                  theme: theme,
                  begin: begin,
                  end: end,
                ),
              ),
            ch,
          ],
        );
      }

      final useGrain = settings.useGrainTexture;
      final intensity = settings.grainIntensity;

      return Stack(
        children: [
          content,
          if (useGrain && intensity > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: GrainTexture(
                  color: Colors.black,
                  opacity: intensity,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildLiquidMode({
    required BuildContext context,
    required ColorScheme theme,
    required bool isOled,
    required Widget child,
  }) {
    final imagePath = settingsController.liquidBackgroundPath.isEmpty
        ? 'assets/images/bg_glass.webp'
        : "file://${settingsController.liquidBackgroundPath}";

    final fallbackColor = isOled
        ? (theme.brightness == Brightness.dark ? Colors.black : Colors.white)
        : theme.surface;

    return Container(
      color: fallbackColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: Obx(() => _buildCachedColorFilteredImage(
                  context: context,
                  imagePath: imagePath,
                  color: settingsController.retainOriginalColor
                      ? null
                      : theme.primary.opaque(0.6),
                )),
          ),
          Positioned.fill(
            child: isOled
                ? Container(color: Colors.black)
                : _buildGradientOverlay(
                    gradientVariant: GradientVariant.subtle,
                    theme: theme,
                  ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildGradientOverlay({
    required GradientVariant gradientVariant,
    required ColorScheme theme,
  }) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: _getGradient(gradientVariant, theme),
        ),
      ),
    );
  }

  Gradient _getGradient(GradientVariant variant, ColorScheme theme) {
    switch (variant) {
      case GradientVariant.subtle:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.surface.opaque(0.65),
            theme.surface.opaque(0.5),
            theme.primary.opaque(0.4),
            theme.surface.opaque(0.6),
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        );

      case GradientVariant.softVignette:
        return RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            theme.surface.opaque(0.2),
            theme.surface.opaque(0.35),
            theme.surface.opaque(0.5),
            theme.surface.opaque(0.6),
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        );

      case GradientVariant.centerFocus:
        return RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            theme.surface.opaque(0.15),
            theme.surface.opaque(0.3),
            theme.surface.opaque(0.45),
            theme.surface.opaque(0.55),
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        );

      case GradientVariant.edgeFade:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.surface.opaque(0.5),
            theme.surface.opaque(0.2),
            theme.surface.opaque(0.2),
            theme.surface.opaque(0.5),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        );

      case GradientVariant.warmTone:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.surface.opaque(0.4),
            Color.lerp(theme.surface, theme.primaryContainer, 0.1)!.opaque(0.3),
            Color.lerp(theme.surface, theme.secondaryContainer, 0.1)!
                .opaque(0.25),
            theme.surface.opaque(0.45),
          ],
          stops: const [0.0, 0.25, 0.75, 1.0],
        );

      case GradientVariant.coolTone:
        return LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            theme.surface.opaque(0.4),
            Color.lerp(theme.surface, theme.primaryContainer, 0.05)!
                .opaque(0.3),
            Color.lerp(theme.surface, theme.tertiaryContainer, 0.05)!
                .opaque(0.25),
            theme.surface.opaque(0.45),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );

      case GradientVariant.dynamicFlow:
        return SweepGradient(
          center: Alignment.center,
          startAngle: 0,
          endAngle: 3.14159 * 2,
          colors: [
            theme.surface.opaque(0.4),
            theme.surface.opaque(0.25),
            theme.surface.opaque(0.35),
            theme.surface.opaque(0.3),
            theme.surface.opaque(0.4),
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        );

      case GradientVariant.minimalDark:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.surface.opaque(0.3),
            theme.surface.opaque(0.25),
            theme.surface.opaque(0.25),
            theme.surface.opaque(0.3),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );
    }
  }

  Widget _buildCachedColorFilteredImage({
    required BuildContext context,
    required String imagePath,
    Color? color,
  }) {
    final isFile = imagePath.startsWith('file://');
    final image = isFile
        ? Image.file(
            File(imagePath.replaceFirst('file://', '')),
            fit: getResponsiveValue(
              context,
              mobileValue: BoxFit.fitHeight,
              desktopValue: BoxFit.cover,
            ),
            filterQuality: FilterQuality.low,
          )
        : Image.asset(
            imagePath,
            fit: getResponsiveValue(
              context,
              mobileValue: BoxFit.fitHeight,
              desktopValue: BoxFit.cover,
            ),
            filterQuality: FilterQuality.low,
          );

    return color != null
        ? ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.color),
            child: image,
          )
        : image;
  }

  Widget _buildLightweightGlow({
    required ColorScheme theme,
    required Alignment begin,
    required Alignment end,
  }) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.surface.opaque(0.3),
              theme.primary.opaque(0.4),
            ],
            begin: begin,
            end: end,
          ),
        ),
      ),
    );
  }
}

BoxShadow glowingShadow(BuildContext context) {
  final controller = Get.find<Settings>();
  if (controller.glowMultiplier == 0.0) {
    return const BoxShadow(color: Colors.transparent);
  } else {
    return BoxShadow(
      color: context.colors.primary.opaque(0.4, iReallyMeanIt: true),
      blurRadius: 50.0.multiplyBlur(),
      spreadRadius: 1.0.multiplyGlow(),
      offset: const Offset(-2.0, 0),
    );
  }
}

BoxShadow lightGlowingShadow(BuildContext context) {
  final controller = Get.find<Settings>();
  if (controller.glowMultiplier == 0.0) {
    return const BoxShadow(color: Colors.transparent);
  } else {
    return BoxShadow(
      color: context.colors.primary
          .opaque(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.6),
      blurRadius: 59.0.multiplyBlur(),
      spreadRadius: 1.0.multiplyGlow(),
      offset: const Offset(-1.0, 0),
    );
  }
}

Shimmer placeHolderWidget(BuildContext context) {
  return Shimmer.fromColors(
    baseColor: context.colors.surfaceContainer,
    highlightColor: context.colors.primary,
    child: Container(
      width: 80,
      height: 80,
      color: context.colors.secondaryContainer,
    ),
  );
}

class _HeaderBodyShell extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool enableSearch;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onSearchClear;
  final String searchHint;
  final Widget child;

  const _HeaderBodyShell({
    required this.title,
    this.subtitle,
    this.action,
    this.enableSearch = false,
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onSearchClear,
    this.searchHint = 'Search...',
    required this.child,
  });

  @override
  State<_HeaderBodyShell> createState() => _HeaderBodyShellState();
}

class _HeaderBodyShellState extends State<_HeaderBodyShell> {
  final _headerKey = GlobalKey<AnymeXHeaderState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          _headerKey.currentState?.onScrollNotification(n);
          return false;
        },
        child: Column(
          children: [
            AnymeXHeader(
              key: _headerKey,
              title: widget.title,
              subtitle: widget.subtitle,
              action: widget.action,
              enableSearch: widget.enableSearch,
              searchController: widget.searchController,
              onSearchChanged: widget.onSearchChanged,
              onSearchSubmitted: widget.onSearchSubmitted,
              onSearchClear: widget.onSearchClear,
              searchHint: widget.searchHint,
            ),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}
