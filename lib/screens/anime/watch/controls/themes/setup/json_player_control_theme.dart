import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/bottom_sheet.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/progress_slider.dart';
import 'package:anymex/screens/settings/sub_settings/settings_player.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class JsonThemeParseResult {
  const JsonThemeParseResult({
    this.themes = const [],
    this.rawThemes = const [],
    this.errors = const [],
    this.warnings = const [],
  });

  final List<JsonPlayerControlTheme> themes;
  final List<Map<String, dynamic>> rawThemes;
  final List<String> errors;
  final List<String> warnings;

  bool get isValid => errors.isEmpty && themes.isNotEmpty;
}

class JsonPlayerControlTheme extends PlayerControlTheme {
  JsonPlayerControlTheme(this.theDef);

  final ThemeDef theDef;

  static const String defaultCollectionJson = '''
{
  "themes": []
}
''';

  static List<JsonPlayerControlTheme> parseCollection(
    String rawJson, {
    void Function(Object error)? onError,
  }) {
    if (rawJson.trim().isEmpty) return const [];

    final result = parseCollectionDetailed(rawJson);
    for (final error in result.errors) {
      onError?.call(FormatException(error));
    }
    return result.themes;
  }

  static JsonThemeParseResult parseCollectionDetailed(String rawJson) {
    final input = rawJson.trim();
    if (input.isEmpty) {
      return const JsonThemeParseResult(errors: ['JSON payload is empty.']);
    }

    final errors = <String>[];
    final warnings = <String>[];
    final parsed = <JsonPlayerControlTheme>[];
    final validRawThemes = <Map<String, dynamic>>[];

    dynamic decoded;
    try {
      decoded = json.decode(input);
    } catch (error) {
      return JsonThemeParseResult(
        errors: ['Invalid JSON syntax: $error'],
      );
    }

    final rawThemes = _decodeRawThemeMaps(decoded, errors: errors);
    for (var i = 0; i < rawThemes.length; i++) {
      final rawTheme = rawThemes[i];
      try {
        final def = ThemeDef.fromJson(rawTheme);
        parsed.add(JsonPlayerControlTheme(def));
        validRawThemes.add(rawTheme);
        warnings.addAll(_collectUnsupportedThemeItemWarnings(rawTheme, def.id));
      } catch (error) {
        errors.add('Theme #${i + 1} is invalid: $error');
      }
    }

    final seenIds = <String>{};
    for (final theme in parsed) {
      if (!seenIds.add(theme.id)) {
        warnings.add(
          'Duplicate theme id "${theme.id}" in the same import payload. Last value will be used.',
        );
      }
    }

    if (parsed.isEmpty && errors.isEmpty) {
      errors.add('No themes found in payload.');
    }

    return JsonThemeParseResult(
      themes: parsed,
      rawThemes: validRawThemes,
      errors: errors,
      warnings: warnings,
    );
  }

  static bool isValidCollectionJson(String rawJson) {
    return parseCollectionDetailed(rawJson).isValid;
  }

  @override
  String get id => theDef.id;

  @override
  String get name => theDef.name;

  @override
  Widget buildTopControls(BuildContext context, PlayerController controller) {
    return ThemeRenderer(context: context, controller: controller, def: theDef)
        .buildTopShit();
  }

  @override
  Widget buildCenterControls(
      BuildContext context, PlayerController controller) {
    return ThemeRenderer(context: context, controller: controller, def: theDef)
        .buildMiddleShit();
  }

  @override
  Widget buildBottomControls(
      BuildContext context, PlayerController controller) {
    return ThemeRenderer(context: context, controller: controller, def: theDef)
        .buildBottomShit();
  }
}

class ThemeRenderer {
  ThemeRenderer({
    required this.context,
    required this.controller,
    required this.def,
  });

  final BuildContext context;
  final PlayerController controller;
  final ThemeDef def;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;
  bool get _isDesktop => !_isMobile;

  Widget buildTopShit() {
    final zone = def.top;
    return Obx(() {
      final locked = controller.isLocked.value;
      final visible = controller.showControls.value;

      if (!_canShowZone(zone.vibes, locked)) return const SizedBox.shrink();
      if (!_checkCondition(zone.vibes.visibleWhen)) {
        return const SizedBox.shrink();
      }

      final slot = zone.slotFor(locked);
      if (slot.isCompletelyEmpty) return const SizedBox.shrink();

      Widget content = _buildThreeColumnRow(
        left: slot.left,
        center: slot.center,
        right: slot.right,
        vibes: zone.vibes,
        isTitleZone: true,
        absoluteCenter: zone.vibes.absoluteCenter,
      );

      content = _slapPanelOn(
          content, def.styles.panel.mash(zone.vibes.panelOverride));
      content = _wrapInShell(content, zone.vibes, 0);
      content = _animateVisibility(content, zone.vibes, visible);
      return content;
    });
  }

  Widget buildMiddleShit() {
    final zone = def.middle;
    return Obx(() {
      final locked = controller.isLocked.value;
      final visible = controller.showControls.value;

      if (!_canShowZone(zone.vibes, locked)) return const SizedBox.shrink();
      if (!_checkCondition(zone.vibes.visibleWhen)) {
        return const SizedBox.shrink();
      }

      final items = zone.itemsFor(locked);
      if (items.isEmpty) return const SizedBox.shrink();

      final row = _buildFlatRow(items, spacing: zone.vibes.itemSpacing);
      if (row == null) return const SizedBox.shrink();

      Widget content =
          _slapPanelOn(row, def.styles.panel.mash(zone.vibes.panelOverride));
      content = _wrapInShell(content, zone.vibes, 1);
      content = _animateVisibility(content, zone.vibes, visible);
      content = AnimatedScale(
        scale: visible ? 1.0 : zone.vibes.hiddenScale,
        duration: zone.vibes.scaleDuration,
        curve: zone.vibes.scaleCurve,
        child: content,
      );
      return content;
    });
  }

  Widget buildBottomShit() {
    final zone = def.bottom;
    return Obx(() {
      final locked = controller.isLocked.value;
      final visible = controller.showControls.value;

      if (!_canShowZone(zone.vibes, locked)) return const SizedBox.shrink();
      if (!_checkCondition(zone.vibes.visibleWhen)) {
        return const SizedBox.shrink();
      }

      final slot = zone.slotFor(locked);
      final kids = <Widget>[];

      if (!slot.topRow.isCompletelyEmpty) {
        kids.add(_buildThreeColumnRow(
          left: slot.topRow.left,
          center: slot.topRow.center,
          right: slot.topRow.right,
          vibes: zone.vibes,
          isTitleZone: false,
          absoluteCenter: zone.vibes.absoluteCenter,
        ));
        kids.add(SizedBox(height: zone.vibes.topRowBottomSpacing));
      }

      bool alreadyHasProgress = false;
      for (final item in [
        ...slot.left,
        ...slot.center,
        ...slot.right,
        ...slot.topRow.left,
        ...slot.topRow.right,
        ...slot.topRow.center
      ]) {
        if (item.id == 'progress_slider') {
          alreadyHasProgress = true;
          break;
        }
      }

      if (zone.showProgress && !alreadyHasProgress) {
        kids.add(Padding(
          padding: zone.progressPadding,
          child: ProgressSlider(style: zone.progressStyle),
        ));
        kids.add(SizedBox(height: zone.vibes.progressBottomSpacing));
      }

      if (slot.left.isNotEmpty ||
          slot.center.isNotEmpty ||
          slot.right.isNotEmpty) {
        kids.add(_buildThreeColumnRow(
          left: slot.left,
          center: slot.center,
          right: slot.right,
          vibes: zone.vibes,
          isTitleZone: true,
          absoluteCenter: zone.vibes.absoluteCenter,
        ));
      }

      if (kids.isEmpty) return const SizedBox.shrink();

      Widget content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: kids,
      );

      content = _slapPanelOn(
          content, def.styles.panel.mash(zone.vibes.panelOverride));
      content = _wrapInShell(content, zone.vibes, 2);
      content = _animateVisibility(content, zone.vibes, visible);
      return content;
    });
  }

  Widget _buildThreeColumnRow({
    required List<ThemeItem> left,
    required List<ThemeItem> center,
    required List<ThemeItem> right,
    required ZoneVibes vibes,
    required bool isTitleZone,
    bool absoluteCenter = false,
  }) {
    final leftRow = _buildFlatRow(left, spacing: vibes.itemSpacing);
    final centerWidget = isTitleZone
        ? _buildTitleAreaThing(center, vibes.itemSpacing)
        : _buildFlatRow(center, spacing: vibes.itemSpacing);
    final rightRow = _buildFlatRow(right, spacing: vibes.itemSpacing);

    final hasLeft = leftRow != null;
    final hasCenter = centerWidget != null;
    final hasRight = rightRow != null;

    if (!hasLeft && !hasCenter && !hasRight) return const SizedBox.shrink();

    if (absoluteCenter && hasCenter) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasLeft) leftRow,
              const Spacer(),
              if (hasRight) rightRow,
            ],
          ),
          IgnorePointer(ignoring: false, child: centerWidget),
        ],
      );
    }

    final rowKids = <Widget>[];
    if (hasLeft) rowKids.add(leftRow);

    if (hasCenter) {
      if (hasLeft) rowKids.add(SizedBox(width: vibes.groupSpacing));
      rowKids.add(Expanded(
        child: Align(alignment: Alignment.centerLeft, child: centerWidget),
      ));
    } else {
      rowKids.add(const Spacer());
    }

    if (hasRight) {
      if (hasCenter || hasLeft) {
        rowKids.add(SizedBox(width: vibes.groupSpacing));
      }
      rowKids.add(rightRow);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: rowKids,
    );
  }

  Widget? _buildTitleAreaThing(List<ThemeItem> items, double spacing) {
    if (items.isEmpty) return null;

    final titleItems = <ThemeItem>[];
    final badgeItems = <ThemeItem>[];
    final stackItems = <ThemeItem>[];
    final otherItems = <ThemeItem>[];

    for (final item in items) {
      if (item.id == 'title') {
        titleItems.add(item);
      } else if (_badgeIds.contains(item.id)) {
        badgeItems.add(item);
      } else if (item.id == 'label_stack' || item.id == 'watching_label') {
        // this thing wasted so much of my time
        stackItems.add(item);
      } else {
        otherItems.add(item);
      }
    }

    if (stackItems.isEmpty && titleItems.isEmpty && badgeItems.isEmpty) {
      return _buildFlatRow(items, spacing: spacing);
    }

    final colKids = <Widget>[];

    for (final si in stackItems) {
      final w = _buildItem(si);
      if (w != null) {
        if (colKids.isNotEmpty) colKids.add(const SizedBox(height: 4));
        colKids.add(w);
      }
    }

    if (titleItems.isNotEmpty) {
      final tw = _buildItem(titleItems.first);
      if (tw != null) {
        if (colKids.isNotEmpty) colKids.add(const SizedBox(height: 2));
        colKids.add(tw);
      }
    }

    final badgeWidgets = <Widget>[];
    for (final bi in badgeItems) {
      final bw = _buildItem(bi);
      if (bw != null) badgeWidgets.add(bw);
    }

    if (badgeWidgets.isNotEmpty) {
      if (colKids.isNotEmpty) colKids.add(const SizedBox(height: 6));
      colKids
          .add(Wrap(spacing: spacing, runSpacing: 6, children: badgeWidgets));
    }

    final otherRow = _buildFlatRow(otherItems, spacing: spacing);
    if (otherRow != null) {
      if (colKids.isNotEmpty) colKids.add(const SizedBox(height: 6));
      colKids.add(otherRow);
    }

    if (colKids.isEmpty) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: colKids,
    );
  }

  Widget? _buildFlatRow(List<ThemeItem> items, {required double spacing}) {
    if (items.isEmpty) return null;

    final kids = <Widget>[];
    for (final item in items) {
      final built = _buildItem(item);
      if (built != null) {
        if (kids.isNotEmpty &&
            spacing > 0 &&
            kids.last is! Spacer &&
            built is! Spacer) {
          kids.add(SizedBox(width: spacing));
        }
        kids.add(built);
      }
    }

    if (kids.isEmpty) return null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: kids,
    );
  }

  Widget? _buildItem(ThemeItem item) {
    if (!_checkCondition(item.visibleWhen)) return null;

    // witness my genius, the way i handle all this so ineffeciently

    switch (item.id) {
      case 'gap':
        final size = item.grabDouble('size', 8);
        return SizedBox(
            width: item.grabDouble('width', size),
            height: item.grabDouble('height', 0));

      case 'spacer':
        final flex = item.grabInt('flex', 0);
        if (flex > 0) {
          return Expanded(flex: flex, child: const SizedBox.shrink());
        }
        final size = item.grabDouble('size', 8);
        return SizedBox(
            width: item.grabDouble('width', size),
            height: item.grabDouble('height', 0));

      case 'flex_spacer':
        return Expanded(
            flex: item.grabInt('flex', 1), child: const SizedBox.shrink());

      case 'progress_slider':
        return ProgressSlider(
          style: _toSliderStyle(item.grabString('progressStyle'),
              fallback: SliderStyle.capsule),
        );

      case 'time_current':
        return _makeChipThing(controller.formattedCurrentPosition, item);

      case 'time_duration':
        return _makeChipThing(controller.formattedEpisodeDuration, item);

      case 'time_remaining':
        return _makeChipThing(_calcRemainingTime(), item);

      case 'title':
        final text = _getTitleText();
        if (text.isEmpty) return null;
        return _makeTextThing(
            value: text, item: item, maxLines: item.grabInt('maxLines', 1));

      case 'episode_badge':
        return _makeBadgeThing(_getEpisodeLabel(), item);

      case 'series_badge':
        final label = _getSeriesLabel();
        if (label.isEmpty) return null;
        return _makeBadgeThing(label, item);

      case 'quality_badge':
        final label = _heightToQuality(controller.videoHeight.value);
        if (label.isEmpty) return null;
        return _makeBadgeThing(label, item);

      case 'label_stack':
        return _makeLabelStackThing(item);

      case 'watching_label':
        return _makeWatchingLabelThing(item);

      case 'text':
        final source = item.grabString('source');
        final fallbackText = item.grabString('text') ?? '';
        final value = source != null ? _textFromSource(source) : fallbackText;
        if (value.isEmpty) return null;
        return _makeTextThing(
            value: value, item: item, maxLines: item.grabInt('maxLines', 1));

      default:
        return _makeButtonThing(item);
    }
  }

  Widget? _makeLabelStackThing(ThemeItem item) {
    final lines = item.data['lines'];
    if (lines is! List || lines.isEmpty) return null;

    final stackAlign = _parseTextAlign(item.grabString('textAlign'));
    final stackCrossAxis = _textAlignToCrossAxis(stackAlign);

    final colKids = <Widget>[];
    for (final line in lines) {
      if (line is! Map) continue;
      final lineMap = Map<String, dynamic>.from(line);
      final source = _readString(lineMap['source']);
      final rawText = _readString(lineMap['text']) ?? '';
      final value = source != null ? _textFromSource(source) : rawText;
      if (value.isEmpty) continue;

      final lineAlign = _readString(lineMap['textAlign']);
      final resolvedAlign =
          lineAlign != null ? _parseTextAlign(lineAlign) : stackAlign;
      final fakeItem = ThemeItem(id: 'text', data: {
        ...lineMap,
        if (lineAlign == null) 'textAlign': _textAlignToString(stackAlign),
      });
      final w = _makeTextThing(
          value: value,
          item: fakeItem,
          maxLines: _readInt(lineMap['maxLines'], 1));
      if (colKids.isNotEmpty) {
        colKids.add(SizedBox(height: _readDouble(lineMap['gap'], 2)));
      }
      colKids.add(resolvedAlign != TextAlign.start
          ? Align(
              alignment: _textAlignToAlignment(resolvedAlign),
              child: w,
            )
          : w);
    }

    if (colKids.isEmpty) return null;

    return Column(
      crossAxisAlignment: stackCrossAxis,
      mainAxisSize: MainAxisSize.min,
      children: colKids,
    );
  }

  Widget? _makeWatchingLabelThing(ThemeItem item) {
    final title = _getTitleText();
    if (title.isEmpty) return null;

    final topText = item.grabString('topText') ?? "You're watching";
    final topFontSize = item.grabDouble('topFontSize', 11);
    final topFontWeight =
        _parseFontWeight(item.grabString('topFontWeight'), FontWeight.w400);
    final topColor = item.grabString('topColor');
    final bottomFontSize = item.grabDouble('bottomFontSize', 14);
    final bottomFontWeight =
        _parseFontWeight(item.grabString('bottomFontWeight'), FontWeight.w700);
    final bottomColor = item.grabString('bottomColor');
    final gap = item.grabDouble('gap', 2);
    final textAlign = _parseTextAlign(item.grabString('textAlign'));
    final crossAxis = _textAlignToCrossAxis(textAlign);

    final baseTextStyle = def.styles.text.mash(item.style);

    final resolvedTopColor = _resolveColor(
      topColor ?? baseTextStyle.color,
      fallback: Colors.white.withValues(alpha: 0.65),
    );
    final resolvedBottomColor = _resolveColor(
      bottomColor ?? baseTextStyle.color,
      fallback: Colors.white,
    );

    return Column(
      crossAxisAlignment: crossAxis,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          topText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: TextStyle(
            color: resolvedTopColor,
            fontSize: topFontSize,
            fontWeight: topFontWeight,
            letterSpacing: 0.1,
          ),
        ),
        SizedBox(height: gap),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: TextStyle(
            color: resolvedBottomColor,
            fontSize: bottomFontSize,
            fontWeight: bottomFontWeight,
            letterSpacing: baseTextStyle.letterSpacing,
          ),
        ),
      ],
    );
  }

  Widget? _makeButtonThing(ThemeItem item) {
    final id = item.id;

    if ((id == 'server' || id == 'quality') && controller.isOffline.value) {
      return null;
    }
    if (id == 'orientation' && !_isMobile) return null;

    final isPlayPause = id == 'play_pause';
    final wantsBig = item.grabBool('primary', isPlayPause);
    final baseStyle = wantsBig ? def.styles.primaryButton : def.styles.button;
    final style = baseStyle.mash(item.style);

    bool enabled = _isThingEnabled(id);
    if (item.enabledWhen != null) {
      enabled = enabled && _checkCondition(item.enabledWhen);
    }

    if (isPlayPause) return _makePlayPauseButton(item, style, enabled);

    final icon = _pickIcon(item.grabString('icon'), id);
    if (icon == null) return null;

    final iconColor = _resolveColor(style.iconColor, fallback: Colors.white);
    final disabledColor = _resolveColor(style.disabledIconColor,
        fallback: Colors.white.withValues(alpha: 0.55));

    return _makeButtonShell(
      style: style,
      tooltip: item.grabString('tooltip') ?? _tooltipForId(id),
      enabled: enabled,
      onTap: enabled ? () => _doAction(id, item) : null,
      guts: Icon(icon,
          size: style.iconSize, color: enabled ? iconColor : disabledColor),
    );
  }

  Widget _makePlayPauseButton(
      ThemeItem item, ButtonStyleDef style, bool enabled) {
    final iconColor = _resolveColor(style.iconColor, fallback: Colors.white);
    final disabledColor = _resolveColor(style.disabledIconColor,
        fallback: Colors.white.withValues(alpha: 0.55));

    return _makeButtonShell(
      style: style,
      tooltip: item.grabString('tooltip') ?? 'Play / Pause',
      enabled: enabled,
      onTap: enabled ? controller.togglePlayPause : null,
      guts: AnimatedSwitcher(
        duration: const Duration(milliseconds: 140),
        child: controller.isBuffering.value
            ? SizedBox(
                width: style.iconSize,
                height: style.iconSize,
                child: const ExpressiveLoadingIndicator(),
              )
            : Icon(
                controller.isPlaying.value
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                key: ValueKey(controller.isPlaying.value),
                size: style.iconSize,
                color: enabled ? iconColor : disabledColor,
              ),
      ),
    );
  }

  Widget _makeButtonShell({
    required ButtonStyleDef style,
    required Widget guts,
    required bool enabled,
    required VoidCallback? onTap,
    String? tooltip,
  }) {
    final buttonColor = _resolveColor(style.color,
        fallback: Colors.white.withValues(alpha: 0.12));
    final borderColor = _resolveColor(style.borderColor,
        fallback: Colors.white.withValues(alpha: 0.28));

    Widget current = DecoratedBox(
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(style.radius),
        border: Border.all(color: borderColor, width: style.borderWidth),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(style.radius),
          onTap: onTap,
          child: SizedBox(
            width: style.size,
            height: style.size,
            child: Center(
              child: AnimatedOpacity(
                opacity: enabled ? 1.0 : 0.6,
                duration: const Duration(milliseconds: 180),
                child: guts,
              ),
            ),
          ),
        ),
      ),
    );

    if (style.blur > 0) {
      current = ClipRRect(
        borderRadius: BorderRadius.circular(style.radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: style.blur, sigmaY: style.blur),
          child: current,
        ),
      );
    } else {
      current = ClipRRect(
          borderRadius: BorderRadius.circular(style.radius), child: current);
    }

    if (tooltip != null && tooltip.trim().isNotEmpty) {
      return Tooltip(message: tooltip, child: current);
    }
    return current;
  }

  Widget _makeBadgeThing(String text, ThemeItem item) {
    final style = def.styles.chip.mash(item.style);
    final color = _resolveColor(style.color,
        fallback: Colors.white.withValues(alpha: 0.14));
    final borderColor = _resolveColor(style.borderColor,
        fallback: Colors.white.withValues(alpha: 0.30));
    final textColor = _resolveColor(style.textColor, fallback: Colors.white);

    return Container(
      padding: style.padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(style.radius),
        border: Border.all(color: borderColor, width: style.borderWidth),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
          letterSpacing: style.letterSpacing,
        ),
      ),
    );
  }

  Widget _makeChipThing(String text, ThemeItem item) =>
      _makeBadgeThing(text, item);

  Widget _makeTextThing(
      {required String value, required ThemeItem item, int maxLines = 1}) {
    final style = def.styles.text.mash(item.style);
    final color = _resolveColor(style.color, fallback: Colors.white);
    final textAlign = _parseTextAlign(item.grabString('textAlign'));

    return Text(
      value,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: TextStyle(
        color: color,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        letterSpacing: style.letterSpacing,
        height: style.height,
      ),
    );
  }

  Widget _slapPanelOn(Widget child, PanelStyleDef style) {
    if (!style.enabled) return child;

    final wantsBg = style.showBackground;
    final wantsBorder = style.showBorder;
    final wantsBlur = style.blur > 0;
    final wantsShadow = style.shadowBlur > 0;
    final wantsPadding = style.padding != EdgeInsets.zero;

    if (!wantsBg &&
        !wantsBorder &&
        !wantsBlur &&
        !wantsShadow &&
        !wantsPadding) {
      return child;
    }

    final panelColor = wantsBg
        ? _resolveColor(style.color,
            fallback: Colors.white.withValues(alpha: 0.08))
        : Colors.transparent;
    final borderColor = wantsBorder
        ? _resolveColor(style.borderColor,
            fallback: Colors.white.withValues(alpha: 0.22))
        : Colors.transparent;
    final shadowColor = wantsShadow
        ? _resolveColor(style.shadowColor,
            fallback: Colors.black.withValues(alpha: 0.22))
        : Colors.transparent;

    Widget panelKid = DecoratedBox(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(style.radius),
        border: wantsBorder
            ? Border.all(color: borderColor, width: style.borderWidth)
            : null,
        boxShadow: wantsShadow
            ? [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: style.shadowBlur,
                  spreadRadius: -2,
                  offset: Offset(0, style.shadowOffsetY),
                ),
              ]
            : null,
      ),
      child: Padding(padding: style.padding, child: child),
    );

    if (wantsBlur) {
      panelKid = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: style.blur, sigmaY: style.blur),
        child: panelKid,
      );
    }

    if (wantsBlur || wantsBg || wantsBorder) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(style.radius),
        child: panelKid,
      );
    }

    return panelKid;
  }

  Widget _wrapInShell(Widget child, ZoneVibes vibes, int which) {
    Widget current = Padding(padding: vibes.padding, child: child);
    current = SafeArea(
      top: which == 0,
      bottom: which == 2,
      left: false,
      right: false,
      child: current,
    );
    return Align(
      alignment: vibes.alignment,
      child: IntrinsicHeight(child: current),
    );
  }

  Widget _animateVisibility(Widget child, ZoneVibes vibes, bool visible) {
    return IgnorePointer(
      ignoring: vibes.ignorePointerWhenHidden && !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : vibes.hiddenOffset,
        duration: vibes.slideDuration,
        curve: vibes.slideCurve,
        child: AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: vibes.opacityDuration,
          curve: vibes.opacityCurve,
          child: child,
        ),
      ),
    );
  }

  bool _canShowZone(ZoneVibes vibes, bool locked) {
    if (locked && !vibes.showWhenLocked) return false;
    if (!locked && !vibes.showWhenUnlocked) return false;
    return true;
  }

  bool _checkCondition(String? raw) {
    if (raw == null || raw.trim().isEmpty) return true;

    final orParts = raw.split('||');
    for (final orPart in orParts) {
      final andParts = orPart.split('&&');
      bool allGood = true;
      for (var token in andParts) {
        token = token.trim();
        if (token.isEmpty) continue;
        bool expected = true;
        if (token.startsWith('!')) {
          expected = false;
          token = token.substring(1).trim();
        }
        if (_getConditionBool(token) != expected) {
          allGood = false;
          break;
        }
      }
      if (allGood) return true;
    }
    return false;
  }

  bool _getConditionBool(String token) {
    switch (token) {
      case 'locked':
        return controller.isLocked.value;
      case 'unlocked':
        return !controller.isLocked.value;
      case 'showControls':
        return controller.showControls.value;
      case 'controlsHidden':
        return !controller.showControls.value;
      case 'isPlaying':
        return controller.isPlaying.value;
      case 'isBuffering':
        return controller.isBuffering.value;
      case 'isOffline':
        return controller.isOffline.value;
      case 'isOnline':
        return !controller.isOffline.value;
      case 'canGoForward':
        return controller.canGoForward.value;
      case 'canGoBackward':
        return controller.canGoBackward.value;
      case 'isDesktop':
        return _isDesktop;
      case 'isMobile':
        return _isMobile;
      default:
        return false;
    }
  }

  bool _isThingEnabled(String id) {
    switch (id) {
      case 'previous_episode':
        return controller.canGoBackward.value;
      case 'next_episode':
        return controller.canGoForward.value;
      case 'lock_controls':
        return !controller.isLocked.value;
      case 'unlock_controls':
        return controller.isLocked.value;
      default:
        return true;
    }
  }

  void _doAction(String id, ThemeItem item) {
    switch (id) {
      case 'back':
        Get.back();
        break;
      case 'lock_controls':
        controller.isLocked.value = true;
        break;
      case 'unlock_controls':
        controller.isLocked.value = false;
        break;
      case 'toggle_fullscreen':
        controller.toggleFullScreen();
        break;
      case 'open_settings':
        _popSettingsSheet();
        break;
      case 'previous_episode':
        controller.navigator(false);
        break;
      case 'next_episode':
        controller.navigator(true);
        break;
      case 'seek_back':
        final secs =
            item.grabInt('seconds', controller.playerSettings.seekDuration);
        final next = controller.currentPosition.value - Duration(seconds: secs);
        controller.seekTo(next.isNegative ? Duration.zero : next);
        break;
      case 'seek_forward':
        final secs =
            item.grabInt('seconds', controller.playerSettings.seekDuration);
        final next = controller.currentPosition.value + Duration(seconds: secs);
        final max = controller.episodeDuration.value;
        controller.seekTo(next > max ? max : next);
        break;
      case 'play_pause':
        controller.togglePlayPause();
        break;
      case 'playlist':
        controller.isEpisodePaneOpened.value =
            !controller.isEpisodePaneOpened.value;
        break;
      case 'shaders':
        controller.openColorProfileBottomSheet(context);
        break;
      case 'subtitles':
        if (controller.isOffline.value) {
          PlayerBottomSheets.showOfflineSubs(context, controller);
        } else {
          PlayerBottomSheets.showSubtitleTracks(context, controller);
        }
        break;
      case 'server':
        if (!controller.isOffline.value) {
          PlayerBottomSheets.showVideoServers(context, controller);
        }
        break;
      case 'quality':
        if (!controller.isOffline.value) {
          PlayerBottomSheets.showVideoQuality(context, controller);
        }
        break;
      case 'speed':
        PlayerBottomSheets.showPlaybackSpeed(context, controller);
        break;
      case 'audio_track':
        PlayerBottomSheets.showAudioTracks(context, controller);
        break;
      case 'orientation':
        if (_isMobile) controller.toggleOrientation();
        break;
      case 'aspect_ratio':
        controller.toggleVideoFit();
        break;
      case 'mega_seek':
        final secs =
            item.grabInt('seconds', controller.playerSettings.skipDuration);
        controller.megaSeek(secs);
        break;
      default:
        break;
    }
  }

  void _popSettingsSheet() {
    showModalBottomSheet(
      context: Get.context ?? context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        height: MediaQuery.of(sheetCtx).size.height,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const SettingsPlayer(isModal: true),
      ),
    );
  }

  Color _resolveColor(String? raw, {required Color fallback}) {
    if (raw == null || raw.trim().isEmpty) return fallback;

    String token = raw.trim();
    if (token.startsWith('@')) {
      final palVal = def.palette[token.substring(1)];
      if (palVal != null && palVal != token) token = palVal;
    }

    final dynMatch = _dynColorRegex.firstMatch(token);
    if (dynMatch != null) {
      final key = dynMatch.group(1)?.trim() ?? '';
      final alpha = _tryDouble(dynMatch.group(2));
      final dynColor = _getDynamicColor(key);
      if (dynColor != null) {
        return alpha != null
            ? dynColor.withValues(alpha: alpha.clamp(0.0, 1.0))
            : dynColor;
      }
    }

    final hexMatch = _hexColorRegex.firstMatch(token);
    if (hexMatch != null) {
      final c = _parseHex(hexMatch.group(1));
      if (c != null) return c;
    }

    if (token.startsWith('#')) {
      final c = _parseHex(token);
      if (c != null) return c;
    }

    switch (token.toLowerCase()) {
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      case 'transparent':
        return Colors.transparent;
      default:
        return fallback;
    }
  }

  Color? _getDynamicColor(String key) {
    final scheme = Theme.of(context).colorScheme;
    switch (key) {
      case 'primary':
        return scheme.primary;
      case 'onPrimary':
      case 'on_primary':
        return scheme.onPrimary;
      case 'primaryContainer':
      case 'primary_container':
        return scheme.primaryContainer;
      case 'onPrimaryContainer':
      case 'on_primary_container':
        return scheme.onPrimaryContainer;
      case 'secondary':
        return scheme.secondary;
      case 'onSecondary':
      case 'on_secondary':
        return scheme.onSecondary;
      case 'secondaryContainer':
      case 'secondary_container':
        return scheme.secondaryContainer;
      case 'onSecondaryContainer':
      case 'on_secondary_container':
        return scheme.onSecondaryContainer;
      case 'tertiary':
        return scheme.tertiary;
      case 'onTertiary':
      case 'on_tertiary':
        return scheme.onTertiary;
      case 'tertiaryContainer':
      case 'tertiary_container':
        return scheme.tertiaryContainer;
      case 'surface':
        return scheme.surface;
      case 'surfaceDim':
      case 'surface_dim':
        return scheme.surface;
      case 'surfaceBright':
      case 'surface_bright':
        return scheme.surface;
      case 'surfaceContainerLowest':
      case 'surface_container_lowest':
        return scheme.surfaceContainerLowest;
      case 'surfaceContainerLow':
      case 'surface_container_low':
        return scheme.surfaceContainerLow;
      case 'surfaceContainer':
      case 'surface_container':
        return scheme.surfaceContainer;
      case 'surfaceContainerHigh':
      case 'surface_container_high':
        return scheme.surfaceContainerHigh;
      case 'surfaceContainerHighest':
      case 'surface_container_highest':
        return scheme.surfaceContainerHighest;
      case 'onSurface':
      case 'on_surface':
        return scheme.onSurface;
      case 'onSurfaceVariant':
      case 'on_surface_variant':
        return scheme.onSurfaceVariant;
      case 'surfaceVariant':
      case 'surface_variant':
        return scheme.surfaceContainerHighest;
      case 'outline':
        return scheme.outline;
      case 'outlineVariant':
      case 'outline_variant':
        return scheme.outlineVariant;
      case 'error':
        return scheme.error;
      case 'onError':
      case 'on_error':
        return scheme.onError;
      case 'errorContainer':
      case 'error_container':
        return scheme.errorContainer;
      case 'onErrorContainer':
      case 'on_error_container':
        return scheme.onErrorContainer;
      case 'inverseSurface':
      case 'inverse_surface':
        return scheme.inverseSurface;
      case 'onInverseSurface':
      case 'on_inverse_surface':
        return scheme.onInverseSurface;
      case 'inversePrimary':
      case 'inverse_primary':
        return scheme.inversePrimary;
      case 'shadow':
        return scheme.shadow;
      case 'scrim':
        return scheme.scrim;
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      case 'transparent':
        return Colors.transparent;
      default:
        return null;
    }
  }

  Color? _parseHex(String? input) {
    if (input == null) return null;
    var hex = input.trim().replaceAll('#', '');
    if (hex.isEmpty) return null;
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    } else if (hex.length == 4) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    if (hex.length < 6) hex = hex.padLeft(6, '0');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length > 8) hex = hex.substring(hex.length - 8);
    if (hex.length != 8) return null;
    final intVal = int.tryParse(hex, radix: 16);
    if (intVal == null) return null;
    return Color(intVal);
  }

  String _getTitleText() {
    return controller.currentEpisode.value.title ??
        controller.itemName ??
        'Unknown Title';
  }

  String _getEpisodeLabel() {
    if (controller.currentEpisode.value.number == 'Offline') return 'Offline';
    return 'Episode ${controller.currentEpisode.value.number}';
  }

  String _getSeriesLabel() {
    final title = controller.anilistData.title == '?'
        ? controller.folderName
        : controller.anilistData.title;
    return title ?? '';
  }

  String _calcRemainingTime() {
    final remaining =
        controller.episodeDuration.value - controller.currentPosition.value;
    if (remaining.inSeconds <= 0) return '00:00';
    String pad(int n) => n.toString().padLeft(2, '0');
    final mm = pad(remaining.inMinutes.remainder(60));
    final ss = pad(remaining.inSeconds.remainder(60));
    if (remaining.inHours > 0) return '-${pad(remaining.inHours)}:$mm:$ss';
    return '-$mm:$ss';
  }

  String _textFromSource(String source) {
    switch (source) {
      case 'title':
        return _getTitleText();
      case 'episode_label':
        return _getEpisodeLabel();
      case 'series_title':
        return _getSeriesLabel();
      case 'quality_label':
        return _heightToQuality(controller.videoHeight.value);
      case 'current_time':
        return controller.formattedCurrentPosition;
      case 'duration':
        return controller.formattedEpisodeDuration;
      case 'remaining':
        return _calcRemainingTime();
      case 'skip_duration':
        return '+${controller.playerSettings.skipDuration}';
      case 'seek_duration':
        return '${controller.playerSettings.seekDuration}s';
      default:
        return source;
    }
  }

  String? _tooltipForId(String id) {
    switch (id) {
      case 'back':
        return 'Back';
      case 'lock_controls':
        return 'Lock Controls';
      case 'unlock_controls':
        return 'Unlock Controls';
      case 'toggle_fullscreen':
        return 'Fullscreen';
      case 'open_settings':
        return 'Settings';
      case 'previous_episode':
        return 'Previous Episode';
      case 'next_episode':
        return 'Next Episode';
      case 'seek_back':
        return 'Seek Back';
      case 'seek_forward':
        return 'Seek Forward';
      case 'play_pause':
        return 'Play / Pause';
      case 'playlist':
        return 'Playlist';
      case 'shaders':
        return 'Shaders & Color Profiles';
      case 'subtitles':
        return 'Subtitles';
      case 'server':
        return 'Server';
      case 'quality':
        return 'Quality';
      case 'speed':
        return 'Speed';
      case 'audio_track':
        return 'Audio Track';
      case 'orientation':
        return 'Toggle Orientation';
      case 'aspect_ratio':
        return 'Aspect Ratio';
      case 'mega_seek':
        return 'Mega Seek';
      default:
        return null;
    }
  }

  IconData? _pickIcon(String? customIcon, String id) {
    if (customIcon != null) {
      final found = _iconMap[customIcon];
      if (found != null) return found;
    }
    return _iconMap[id];
  }

  static String _heightToQuality(int? h) {
    if (h == null) return '';
    if (h >= 2160) return '2160p';
    if (h >= 1440) return '1440p';
    if (h >= 1080) return '1080p';
    if (h >= 720) return '720p';
    if (h >= 480) return '480p';
    if (h >= 360) return '360p';
    return '';
  }
}

class ThemeDef {
  ThemeDef({
    required this.id,
    required this.name,
    required this.palette,
    required this.styles,
    required this.top,
    required this.middle,
    required this.bottom,
  });

  final String id;
  final String name;
  final Map<String, String> palette;
  final StylesDef styles;
  final TopZone top;
  final MiddleZone middle;
  final BottomZone bottom;

  factory ThemeDef.fromJson(Map<String, dynamic> json) {
    final id = _readString(json['id']);
    if (id == null || id.trim().isEmpty) {
      throw const FormatException('Theme id is required.');
    }

    final palette = <String, String>{};
    if (json['palette'] is Map) {
      final rawPal = Map<String, dynamic>.from(json['palette'] as Map);
      for (final e in rawPal.entries) {
        if (e.key == 'note_by_dev') continue;
        final v = _readString(e.value);
        if (v != null) palette[e.key] = v;
      }
    }

    return ThemeDef(
      id: id,
      name: _readString(json['name']) ?? id,
      palette: palette,
      styles: StylesDef.fromJson(_asMap(json['styles'])),
      top: TopZone.fromJson(_asMap(json['top'])),
      middle: MiddleZone.fromJson(_asMap(json['middle'] ?? json['center'])),
      bottom: BottomZone.fromJson(_asMap(json['bottom'])),
    );
  }
}

class StylesDef {
  const StylesDef({
    required this.panel,
    required this.button,
    required this.primaryButton,
    required this.chip,
    required this.text,
  });

  final PanelStyleDef panel;
  final ButtonStyleDef button;
  final ButtonStyleDef primaryButton;
  final ChipStyleDef chip;
  final TextStyleDef text;

  factory StylesDef.fromJson(Map<String, dynamic> json) {
    return StylesDef(
      panel: PanelStyleDef.fromJson(_asMap(json['panel'])),
      button: ButtonStyleDef.fromJson(_asMap(json['button'])),
      primaryButton: ButtonStyleDef.fromJson(_asMap(json['primaryButton'])),
      chip: ChipStyleDef.fromJson(_asMap(json['chip'])),
      text: TextStyleDef.fromJson(_asMap(json['text'])),
    );
  }
}

class PanelStyleDef {
  const PanelStyleDef({
    this.enabled = true,
    this.showBackground = true,
    this.showBorder = true,
    this.radius = 22,
    this.blur = 18,
    this.color,
    this.borderColor,
    this.borderWidth = 0.8,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.shadowColor,
    this.shadowBlur = 18,
    this.shadowOffsetY = 8,
  });

  final bool enabled;
  final bool showBackground;
  final bool showBorder;
  final double radius;
  final double blur;
  final String? color;
  final String? borderColor;
  final double borderWidth;
  final EdgeInsets padding;
  final String? shadowColor;
  final double shadowBlur;
  final double shadowOffsetY;

  factory PanelStyleDef.fromJson(Map<String, dynamic> json) {
    return PanelStyleDef(
      enabled: _readBool(json['enabled'], true),
      showBackground: _readBool(json['showBackground'], true),
      showBorder: _readBool(json['showBorder'], true),
      radius: _readDouble(json['radius'], 22),
      blur: _readDouble(json['blur'], 18),
      color: _readString(json['color']),
      borderColor: _readString(json['borderColor']),
      borderWidth: _readDouble(json['borderWidth'], 0.8),
      padding: _readEdgeInsets(json['padding'],
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      shadowColor: _readString(json['shadowColor']),
      shadowBlur: _readDouble(json['shadowBlur'], 18),
      shadowOffsetY: _readDouble(json['shadowOffsetY'], 8),
    );
  }

  PanelStyleDef mash(Map<String, dynamic> over) {
    if (over.isEmpty) return this;
    return PanelStyleDef(
      enabled: _readBool(over['enabled'], enabled),
      showBackground: _readBool(over['showBackground'], showBackground),
      showBorder: _readBool(over['showBorder'], showBorder),
      radius: _readDouble(over['radius'], radius),
      blur: _readDouble(over['blur'], blur),
      color: _readString(over['color']) ?? color,
      borderColor: _readString(over['borderColor']) ?? borderColor,
      borderWidth: _readDouble(over['borderWidth'], borderWidth),
      padding: over.containsKey('padding')
          ? _readEdgeInsets(over['padding'], padding)
          : padding,
      shadowColor: _readString(over['shadowColor']) ?? shadowColor,
      shadowBlur: _readDouble(over['shadowBlur'], shadowBlur),
      shadowOffsetY: _readDouble(over['shadowOffsetY'], shadowOffsetY),
    );
  }
}

class ButtonStyleDef {
  const ButtonStyleDef({
    this.size = 40,
    this.iconSize = 20,
    this.radius = 16,
    this.blur = 14,
    this.color,
    this.borderColor,
    this.borderWidth = 0.8,
    this.iconColor,
    this.disabledIconColor,
  });

  final double size;
  final double iconSize;
  final double radius;
  final double blur;
  final String? color;
  final String? borderColor;
  final double borderWidth;
  final String? iconColor;
  final String? disabledIconColor;

  factory ButtonStyleDef.fromJson(Map<String, dynamic> json) {
    return ButtonStyleDef(
      size: _readDouble(json['size'], 40),
      iconSize: _readDouble(json['iconSize'], 20),
      radius: _readDouble(json['radius'], 16),
      blur: _readDouble(json['blur'], 14),
      color: _readString(json['color']),
      borderColor: _readString(json['borderColor']),
      borderWidth: _readDouble(json['borderWidth'], 0.8),
      iconColor: _readString(json['iconColor']),
      disabledIconColor: _readString(json['disabledIconColor']),
    );
  }

  ButtonStyleDef mash(Map<String, dynamic> over) {
    if (over.isEmpty) return this;
    return ButtonStyleDef(
      size: _readDouble(over['size'], size),
      iconSize: _readDouble(over['iconSize'], iconSize),
      radius: _readDouble(over['radius'], radius),
      blur: _readDouble(over['blur'], blur),
      color: _readString(over['color']) ?? color,
      borderColor: _readString(over['borderColor']) ?? borderColor,
      borderWidth: _readDouble(over['borderWidth'], borderWidth),
      iconColor: _readString(over['iconColor']) ?? iconColor,
      disabledIconColor:
          _readString(over['disabledIconColor']) ?? disabledIconColor,
    );
  }
}

class ChipStyleDef {
  const ChipStyleDef({
    this.radius = 14,
    this.color,
    this.borderColor,
    this.borderWidth = 0.6,
    this.textColor,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w600,
    this.letterSpacing = 0.2,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  final double radius;
  final String? color;
  final String? borderColor;
  final double borderWidth;
  final String? textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final EdgeInsets padding;

  factory ChipStyleDef.fromJson(Map<String, dynamic> json) {
    return ChipStyleDef(
      radius: _readDouble(json['radius'], 14),
      color: _readString(json['color']),
      borderColor: _readString(json['borderColor']),
      borderWidth: _readDouble(json['borderWidth'], 0.6),
      textColor: _readString(json['textColor']),
      fontSize: _readDouble(json['fontSize'], 12),
      fontWeight: _parseFontWeight(json['fontWeight'], FontWeight.w600),
      letterSpacing: _readDouble(json['letterSpacing'], 0.2),
      padding: _readEdgeInsets(json['padding'],
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
    );
  }

  ChipStyleDef mash(Map<String, dynamic> over) {
    if (over.isEmpty) return this;
    return ChipStyleDef(
      radius: _readDouble(over['radius'], radius),
      color: _readString(over['color']) ?? color,
      borderColor: _readString(over['borderColor']) ?? borderColor,
      borderWidth: _readDouble(over['borderWidth'], borderWidth),
      textColor: _readString(over['textColor']) ?? textColor,
      fontSize: _readDouble(over['fontSize'], fontSize),
      fontWeight: _parseFontWeight(over['fontWeight'], fontWeight),
      letterSpacing: _readDouble(over['letterSpacing'], letterSpacing),
      padding: over.containsKey('padding')
          ? _readEdgeInsets(over['padding'], padding)
          : padding,
    );
  }
}

class TextStyleDef {
  const TextStyleDef({
    this.color,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w700,
    this.letterSpacing = 0.2,
    this.height = 1.2,
  });

  final String? color;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final double height;

  factory TextStyleDef.fromJson(Map<String, dynamic> json) {
    return TextStyleDef(
      color: _readString(json['color']),
      fontSize: _readDouble(json['fontSize'], 14),
      fontWeight: _parseFontWeight(json['fontWeight'], FontWeight.w700),
      letterSpacing: _readDouble(json['letterSpacing'], 0.2),
      height: _readDouble(json['height'], 1.2),
    );
  }

  TextStyleDef mash(Map<String, dynamic> over) {
    if (over.isEmpty) return this;
    return TextStyleDef(
      color: _readString(over['color']) ?? color,
      fontSize: _readDouble(over['fontSize'], fontSize),
      fontWeight: _parseFontWeight(over['fontWeight'], fontWeight),
      letterSpacing: _readDouble(over['letterSpacing'], letterSpacing),
      height: _readDouble(over['height'], height),
    );
  }
}

class ZoneVibes {
  const ZoneVibes({
    this.alignment = Alignment.center,
    this.padding = EdgeInsets.zero,
    this.hiddenOffset = Offset.zero,
    this.slideDuration = const Duration(milliseconds: 320),
    this.opacityDuration = const Duration(milliseconds: 260),
    this.slideCurve = Curves.easeOutCubic,
    this.opacityCurve = Curves.easeOut,
    this.hiddenScale = 1.0,
    this.scaleDuration = const Duration(milliseconds: 300),
    this.scaleCurve = Curves.easeOutBack,
    this.showWhenLocked = true,
    this.showWhenUnlocked = true,
    this.useNormalWhenLocked = false,
    this.ignorePointerWhenHidden = true,
    this.itemSpacing = 8,
    this.groupSpacing = 10,
    this.topRowBottomSpacing = 8,
    this.progressBottomSpacing = 10,
    this.visibleWhen,
    this.panelOverride = const {},
    this.absoluteCenter = false,
  });

  final Alignment alignment;
  final EdgeInsets padding;
  final Offset hiddenOffset;
  final Duration slideDuration;
  final Duration opacityDuration;
  final Curve slideCurve;
  final Curve opacityCurve;
  final double hiddenScale;
  final Duration scaleDuration;
  final Curve scaleCurve;
  final bool showWhenLocked;
  final bool showWhenUnlocked;
  final bool useNormalWhenLocked;
  final bool ignorePointerWhenHidden;
  final double itemSpacing;
  final double groupSpacing;
  final double topRowBottomSpacing;
  final double progressBottomSpacing;
  final String? visibleWhen;
  final Map<String, dynamic> panelOverride;
  final bool absoluteCenter;

  factory ZoneVibes.fromJson(
    Map<String, dynamic> json, {
    required Alignment defaultAlignment,
    required EdgeInsets defaultPadding,
    required Offset defaultHiddenOffset,
    required bool defaultShowWhenLocked,
    required bool defaultShowWhenUnlocked,
    required bool defaultUseNormalWhenLocked,
  }) {
    return ZoneVibes(
      alignment:
          _parseAlignment(_readString(json['alignment']), defaultAlignment),
      padding: _readEdgeInsets(json['padding'], defaultPadding),
      hiddenOffset: _readOffset(json['hiddenOffset'], defaultHiddenOffset),
      slideDuration:
          Duration(milliseconds: _readInt(json['slideDurationMs'], 320)),
      opacityDuration:
          Duration(milliseconds: _readInt(json['opacityDurationMs'], 260)),
      slideCurve:
          _parseCurve(_readString(json['slideCurve']), Curves.easeOutCubic),
      opacityCurve:
          _parseCurve(_readString(json['opacityCurve']), Curves.easeOut),
      hiddenScale: _readDouble(json['hiddenScale'], 1.0),
      scaleDuration:
          Duration(milliseconds: _readInt(json['scaleDurationMs'], 300)),
      scaleCurve:
          _parseCurve(_readString(json['scaleCurve']), Curves.easeOutBack),
      showWhenLocked: _readBool(json['showWhenLocked'], defaultShowWhenLocked),
      showWhenUnlocked:
          _readBool(json['showWhenUnlocked'], defaultShowWhenUnlocked),
      useNormalWhenLocked: _readBool(
          json['useNormalLayoutWhenLocked'], defaultUseNormalWhenLocked),
      ignorePointerWhenHidden: _readBool(json['ignorePointerWhenHidden'], true),
      itemSpacing: _readDouble(json['itemSpacing'], 8),
      groupSpacing: _readDouble(json['groupSpacing'], 10),
      topRowBottomSpacing: _readDouble(json['topRowBottomSpacing'], 8),
      progressBottomSpacing: _readDouble(json['progressBottomSpacing'], 10),
      visibleWhen: _readString(json['visibleWhen']),
      panelOverride: _asMap(json['panelStyle']),
      absoluteCenter: _readBool(json['absoluteCenter'], false),
    );
  }
}

class ThreeColumnSlot {
  const ThreeColumnSlot({
    this.left = const [],
    this.center = const [],
    this.right = const [],
  });

  final List<ThemeItem> left;
  final List<ThemeItem> center;
  final List<ThemeItem> right;

  bool get isCompletelyEmpty => left.isEmpty && center.isEmpty && right.isEmpty;

  factory ThreeColumnSlot.fromJson(Map<String, dynamic> json) {
    return ThreeColumnSlot(
      left: _parseItems(json['left']),
      center: _parseItems(json['center']),
      right: _parseItems(json['right']),
    );
  }
}

class BottomSlotDef {
  const BottomSlotDef({
    this.topRow = const ThreeColumnSlot(),
    this.left = const [],
    this.center = const [],
    this.right = const [],
  });

  final ThreeColumnSlot topRow;
  final List<ThemeItem> left;
  final List<ThemeItem> center;
  final List<ThemeItem> right;

  bool get isCompletelyEmpty =>
      topRow.isCompletelyEmpty &&
      left.isEmpty &&
      center.isEmpty &&
      right.isEmpty;

  factory BottomSlotDef.fromJson(Map<String, dynamic> json) {
    final topRowRaw = json['top'];
    ThreeColumnSlot topRow;
    if (topRowRaw is Map) {
      topRow = ThreeColumnSlot.fromJson(_asMap(topRowRaw));
    } else {
      topRow = ThreeColumnSlot(
        right: _parseItems(json['topRight']),
        left: _parseItems(json['topLeft']),
        center: _parseItems(json['topCenter']),
      );
    }

    return BottomSlotDef(
      topRow: topRow,
      left: _parseItems(json['left']),
      center: _parseItems(json['center']),
      right: _parseItems(json['right']),
    );
  }
}

class TopZone {
  const TopZone({
    required this.normal,
    required this.locked,
    required this.vibes,
  });

  final ThreeColumnSlot normal;
  final ThreeColumnSlot? locked;
  final ZoneVibes vibes;

  ThreeColumnSlot slotFor(bool isLocked) {
    if (!isLocked) return normal;
    if (locked != null && !locked!.isCompletelyEmpty) return locked!;
    if (vibes.useNormalWhenLocked) return normal;
    return const ThreeColumnSlot();
  }

  factory TopZone.fromJson(Map<String, dynamic> json) {
    final normalSrc =
        json.containsKey('normal') ? _asMap(json['normal']) : json;
    final lockedSrc = _asMap(json['locked']);
    final vibes = ZoneVibes.fromJson(
      json,
      defaultAlignment: Alignment.topCenter,
      defaultPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      defaultHiddenOffset: const Offset(0, -1),
      defaultShowWhenLocked: true,
      defaultShowWhenUnlocked: true,
      defaultUseNormalWhenLocked: false,
    );

    final parsedNormal = ThreeColumnSlot.fromJson(normalSrc);
    final parsedLocked =
        lockedSrc.isEmpty ? null : ThreeColumnSlot.fromJson(lockedSrc);

    return TopZone(
      normal:
          parsedNormal.isCompletelyEmpty ? _defaultTopNormal() : parsedNormal,
      locked: (parsedLocked == null || parsedLocked.isCompletelyEmpty)
          ? (vibes.showWhenLocked ? _defaultTopLocked() : null)
          : parsedLocked,
      vibes: vibes,
    );
  }
}

class MiddleZone {
  const MiddleZone({
    required this.normalItems,
    required this.lockedItems,
    required this.vibes,
  });

  final List<ThemeItem> normalItems;
  final List<ThemeItem>? lockedItems;
  final ZoneVibes vibes;

  List<ThemeItem> itemsFor(bool isLocked) {
    if (!isLocked) return normalItems;
    if (lockedItems != null && lockedItems!.isNotEmpty) return lockedItems!;
    if (vibes.useNormalWhenLocked) return normalItems;
    return const [];
  }

  factory MiddleZone.fromJson(Map<String, dynamic> json) {
    final normalSrc =
        json.containsKey('normal') ? _asMap(json['normal']) : json;
    final lockedSrc = _asMap(json['locked']);
    final vibes = ZoneVibes.fromJson(
      json,
      defaultAlignment: Alignment.center,
      defaultPadding: const EdgeInsets.symmetric(horizontal: 14),
      defaultHiddenOffset: Offset.zero,
      defaultShowWhenLocked: false,
      defaultShowWhenUnlocked: true,
      defaultUseNormalWhenLocked: false,
    );

    final normalItems = _parseItems(normalSrc['items']);
    final lockedItems =
        lockedSrc.isEmpty ? null : _parseItems(lockedSrc['items']);

    return MiddleZone(
      normalItems: normalItems.isEmpty ? _defaultMiddleItems() : normalItems,
      lockedItems:
          (lockedItems == null || lockedItems.isEmpty) ? null : lockedItems,
      vibes: vibes,
    );
  }
}

class BottomZone {
  const BottomZone({
    required this.normal,
    required this.locked,
    required this.showProgress,
    required this.progressStyle,
    required this.progressPadding,
    required this.vibes,
  });

  final BottomSlotDef normal;
  final BottomSlotDef? locked;
  final bool showProgress;
  final SliderStyle progressStyle;
  final EdgeInsets progressPadding;
  final ZoneVibes vibes;

  BottomSlotDef slotFor(bool isLocked) {
    if (!isLocked) return normal;
    if (locked != null && !locked!.isCompletelyEmpty) return locked!;
    if (vibes.useNormalWhenLocked) return normal;
    return const BottomSlotDef();
  }

  factory BottomZone.fromJson(Map<String, dynamic> json) {
    final normalSrc =
        json.containsKey('normal') ? _asMap(json['normal']) : json;
    final lockedSrc = _asMap(json['locked']);
    final vibes = ZoneVibes.fromJson(
      json,
      defaultAlignment: Alignment.bottomCenter,
      defaultPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      defaultHiddenOffset: const Offset(0, 1),
      defaultShowWhenLocked: true,
      defaultShowWhenUnlocked: true,
      defaultUseNormalWhenLocked: false,
    );

    final parsedNormal = BottomSlotDef.fromJson(normalSrc);
    final parsedLocked =
        lockedSrc.isEmpty ? null : BottomSlotDef.fromJson(lockedSrc);

    return BottomZone(
      normal: parsedNormal.isCompletelyEmpty
          ? _defaultBottomNormal()
          : parsedNormal,
      locked: (parsedLocked == null || parsedLocked.isCompletelyEmpty)
          ? (vibes.showWhenLocked ? _defaultBottomLocked() : null)
          : parsedLocked,
      showProgress: _readBool(json['showProgress'], true),
      progressStyle: _toSliderStyle(_readString(json['progressStyle']),
          fallback: SliderStyle.ios),
      progressPadding: _readEdgeInsets(
          json['progressPadding'], const EdgeInsets.symmetric(horizontal: 4)),
      vibes: vibes,
    );
  }
}

class ThemeItem {
  const ThemeItem({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  String? get visibleWhen => _readString(data['visibleWhen']);
  String? get enabledWhen => _readString(data['enabledWhen']);
  Map<String, dynamic> get style => _asMap(data['style']);

  String? grabString(String key) => _readString(data[key]);
  int grabInt(String key, int fallback) => _readInt(data[key], fallback);
  double grabDouble(String key, double fallback) =>
      _readDouble(data[key], fallback);
  bool grabBool(String key, bool fallback) => _readBool(data[key], fallback);

  factory ThemeItem.fromRaw(dynamic raw) {
    if (raw is String) return ThemeItem(id: raw, data: const {});
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final id = _readString(map['id']);
      if (id == null || id.trim().isEmpty) {
        throw const FormatException('Theme item needs an id.');
      }
      return ThemeItem(id: id, data: map);
    }
    throw const FormatException('Theme item must be a string or object.');
  }
}

ThemeItem _yoItem(String id) => ThemeItem(id: id, data: const {});

ThreeColumnSlot _defaultTopNormal() {
  return ThreeColumnSlot(
    left: [_yoItem('back')],
    center: [
      _yoItem('title'),
      _yoItem('episode_badge'),
      _yoItem('series_badge'),
      _yoItem('quality_badge')
    ],
    right: [
      _yoItem('lock_controls'),
      _yoItem('toggle_fullscreen'),
      _yoItem('open_settings')
    ],
  );
}

ThreeColumnSlot _defaultTopLocked() {
  return ThreeColumnSlot(right: [_yoItem('unlock_controls')]);
}

List<ThemeItem> _defaultMiddleItems() {
  return [
    _yoItem('previous_episode'),
    _yoItem('seek_back'),
    _yoItem('play_pause'),
    _yoItem('seek_forward'),
    _yoItem('next_episode'),
  ];
}

BottomSlotDef _defaultBottomNormal() {
  return BottomSlotDef(
    topRow: ThreeColumnSlot(right: [_yoItem('mega_seek')]),
    left: [
      _yoItem('time_current'),
      _yoItem('playlist'),
      _yoItem('shaders'),
      _yoItem('subtitles')
    ],
    right: [
      _yoItem('server'),
      _yoItem('quality'),
      _yoItem('speed'),
      _yoItem('audio_track'),
      _yoItem('orientation'),
      _yoItem('aspect_ratio'),
      _yoItem('time_duration')
    ],
  );
}

BottomSlotDef _defaultBottomLocked() {
  return BottomSlotDef(
    left: [_yoItem('time_current')],
    right: [_yoItem('time_duration')],
  );
}

const Set<String> _badgeIds = {
  'episode_badge',
  'series_badge',
  'quality_badge'
};

const Map<String, IconData> _iconMap = {
  'back': Icons.arrow_back_rounded,
  'arrow_back_rounded': Icons.arrow_back_rounded,
  'lock_controls': Icons.lock_rounded,
  'unlock_controls': Icons.lock_open_rounded,
  'toggle_fullscreen': Icons.fullscreen_rounded,
  'open_settings': Icons.settings_rounded,
  'previous_episode': Icons.skip_previous_rounded,
  'next_episode': Icons.skip_next_rounded,
  'seek_back': Icons.replay_10_rounded,
  'seek_forward': Icons.forward_10_rounded,
  'play_pause': Icons.play_arrow_rounded,
  'playlist': Symbols.playlist_play_rounded,
  'shaders': Symbols.tune_rounded,
  'subtitles': Symbols.subtitles_rounded,
  'server': Symbols.cloud_rounded,
  'quality': Symbols.high_quality_rounded,
  'speed': Symbols.speed_rounded,
  'audio_track': Symbols.music_note_rounded,
  'orientation': Icons.screen_rotation_rounded,
  'aspect_ratio': Symbols.fit_screen,
  'mega_seek': Icons.fast_forward_rounded,
  'skip_previous_rounded': Icons.skip_previous_rounded,
  'skip_next_rounded': Icons.skip_next_rounded,
  'replay_10_rounded': Icons.replay_10_rounded,
  'forward_10_rounded': Icons.forward_10_rounded,
  'replay_30_rounded': Icons.replay_30_rounded,
  'forward_30_rounded': Icons.forward_30_rounded,
  'pause_rounded': Icons.pause_rounded,
  'play_arrow_rounded': Icons.play_arrow_rounded,
  'fullscreen_exit_rounded': Icons.fullscreen_exit_rounded,
  'more_vert_rounded': Icons.more_vert_rounded,
};

final Set<String> _supportedThemeItemIds = {
  ..._iconMap.keys,
  'gap',
  'spacer',
  'flex_spacer',
  'progress_slider',
  'time_current',
  'time_duration',
  'time_remaining',
  'title',
  'episode_badge',
  'series_badge',
  'quality_badge',
  'label_stack',
  'watching_label',
  'text',
};

final RegExp _dynColorRegex =
    RegExp(r'^dynamic\(([^,\)]+)(?:,\s*([0-9]*\.?[0-9]+))?\)$');
final RegExp _hexColorRegex = RegExp(r'^hex\((#[0-9a-fA-F]+)\)$');

Map<String, dynamic> _asMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return const {};
}

List<Map<String, dynamic>> _decodeRawThemeMaps(
  dynamic decoded, {
  required List<String> errors,
}) {
  if (decoded is! Map) {
    if (decoded is List) {
      return _normalizeRawThemeList(decoded, errors: errors);
    }
    errors.add('Root JSON must be a theme object.');
    return const [];
  }

  final map = _asMap(decoded);
  if (map['themes'] is List) {
    return _normalizeRawThemeList(map['themes'] as List, errors: errors);
  }
  if (map['themes'] is Map) {
    return [_asMap(map['themes'])];
  }
  if (map['theme'] is Map) {
    return [_asMap(map['theme'])];
  }

  if (_readString(map['id']) != null) {
    return [map];
  }

  errors.add(
    'Expected a single theme object (or wrapper like {"theme": {...}}).',
  );
  return const [];
}

List<Map<String, dynamic>> _normalizeRawThemeList(
  List<dynamic> rawThemes, {
  required List<String> errors,
}) {
  final out = <Map<String, dynamic>>[];
  for (var i = 0; i < rawThemes.length; i++) {
    final rawTheme = rawThemes[i];
    if (rawTheme is! Map) {
      errors.add('Theme #${i + 1} is not an object.');
      continue;
    }
    out.add(_asMap(rawTheme));
  }
  return out;
}

List<String> _collectUnsupportedThemeItemWarnings(
  Map<String, dynamic> rawTheme,
  String themeId,
) {
  final ids = _collectItemIdsFromTheme(rawTheme);
  final unsupported = ids.where((id) => !_supportedThemeItemIds.contains(id));
  return unsupported
      .map((id) => 'Theme "$themeId" uses unsupported item id "$id".')
      .toList(growable: false);
}

Set<String> _collectItemIdsFromTheme(Map<String, dynamic> rawTheme) {
  final ids = <String>{};

  final top = _asMap(rawTheme['top']);
  if (top.isNotEmpty) {
    if (top.containsKey('normal')) {
      _collectItemIdsFromThreeColumn(top['normal'], ids);
    } else {
      _collectItemIdsFromThreeColumn(top, ids);
    }
    _collectItemIdsFromThreeColumn(top['locked'], ids);
  }

  final middle = _asMap(rawTheme['middle'] ?? rawTheme['center']);
  if (middle.isNotEmpty) {
    if (middle.containsKey('normal')) {
      final normal = _asMap(middle['normal']);
      _collectItemIdsFromList(normal['items'], ids);
    } else {
      _collectItemIdsFromList(middle['items'], ids);
    }

    final locked = _asMap(middle['locked']);
    _collectItemIdsFromList(locked['items'], ids);
  }

  final bottom = _asMap(rawTheme['bottom']);
  if (bottom.isNotEmpty) {
    if (bottom.containsKey('normal')) {
      _collectItemIdsFromBottomSlot(bottom['normal'], ids);
    } else {
      _collectItemIdsFromBottomSlot(bottom, ids);
    }
    _collectItemIdsFromBottomSlot(bottom['locked'], ids);
  }

  return ids;
}

void _collectItemIdsFromThreeColumn(dynamic raw, Set<String> out) {
  final map = _asMap(raw);
  if (map.isEmpty) return;

  _collectItemIdsFromList(map['left'], out);
  _collectItemIdsFromList(map['center'], out);
  _collectItemIdsFromList(map['right'], out);
}

void _collectItemIdsFromBottomSlot(dynamic raw, Set<String> out) {
  final map = _asMap(raw);
  if (map.isEmpty) return;

  _collectItemIdsFromThreeColumn(map['top'], out);
  _collectItemIdsFromList(map['topLeft'], out);
  _collectItemIdsFromList(map['topCenter'], out);
  _collectItemIdsFromList(map['topRight'], out);
  _collectItemIdsFromList(map['left'], out);
  _collectItemIdsFromList(map['center'], out);
  _collectItemIdsFromList(map['right'], out);
}

void _collectItemIdsFromList(dynamic raw, Set<String> out) {
  if (raw is! List) return;

  for (final entry in raw) {
    if (entry is String) {
      final id = entry.trim();
      if (id.isNotEmpty) out.add(id);
      continue;
    }

    if (entry is Map) {
      final id = _readString(entry['id']);
      if (id != null) out.add(id);
    }
  }
}

List<ThemeItem> _parseItems(dynamic raw) {
  if (raw is! List) return const [];
  final items = <ThemeItem>[];
  for (final entry in raw) {
    try {
      items.add(ThemeItem.fromRaw(entry));
    } catch (_) {}
  }
  return items;
}

String? _readString(dynamic raw) {
  if (raw == null) return null;
  final v = raw.toString().trim();
  return v.isEmpty ? null : v;
}

int _readInt(dynamic raw, int fallback) {
  if (raw is int) return raw;
  if (raw is double) return raw.toInt();
  if (raw is String) return int.tryParse(raw) ?? fallback;
  return fallback;
}

double _readDouble(dynamic raw, double fallback) {
  if (raw is double) return raw;
  if (raw is int) return raw.toDouble();
  if (raw is String) return double.tryParse(raw) ?? fallback;
  return fallback;
}

double? _tryDouble(String? raw) => raw == null ? null : double.tryParse(raw);

bool _readBool(dynamic raw, bool fallback) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final n = raw.trim().toLowerCase();
    if (n == 'true') return true;
    if (n == 'false') return false;
  }
  return fallback;
}

EdgeInsets _readEdgeInsets(dynamic raw, EdgeInsets fallback) {
  if (raw is num) return EdgeInsets.all(raw.toDouble());
  if (raw is! Map) return fallback;
  final map = Map<String, dynamic>.from(raw);
  final all = map['all'];
  if (all is num) return EdgeInsets.all(all.toDouble());
  final h = _readDouble(map['horizontal'], 0);
  final v = _readDouble(map['vertical'], 0);
  return EdgeInsets.fromLTRB(
    _readDouble(map['left'], h),
    _readDouble(map['top'], v),
    _readDouble(map['right'], h),
    _readDouble(map['bottom'], v),
  );
}

Offset _readOffset(dynamic raw, Offset fallback) {
  if (raw is List && raw.length >= 2) {
    return Offset(
        _readDouble(raw[0], fallback.dx), _readDouble(raw[1], fallback.dy));
  }
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    return Offset(
        _readDouble(map['x'], fallback.dx), _readDouble(map['y'], fallback.dy));
  }
  return fallback;
}

Alignment _parseAlignment(String? raw, Alignment fallback) {
  switch (raw) {
    case 'topLeft':
      return Alignment.topLeft;
    case 'topCenter':
      return Alignment.topCenter;
    case 'topRight':
      return Alignment.topRight;
    case 'centerLeft':
      return Alignment.centerLeft;
    case 'center':
      return Alignment.center;
    case 'centerRight':
      return Alignment.centerRight;
    case 'bottomLeft':
      return Alignment.bottomLeft;
    case 'bottomCenter':
      return Alignment.bottomCenter;
    case 'bottomRight':
      return Alignment.bottomRight;
    default:
      return fallback;
  }
}

Curve _parseCurve(String? raw, Curve fallback) {
  switch (raw) {
    case 'linear':
      return Curves.linear;
    case 'easeIn':
      return Curves.easeIn;
    case 'easeOut':
      return Curves.easeOut;
    case 'easeInOut':
      return Curves.easeInOut;
    case 'easeOutCubic':
      return Curves.easeOutCubic;
    case 'easeOutBack':
      return Curves.easeOutBack;
    default:
      return fallback;
  }
}

SliderStyle _toSliderStyle(String? raw, {required SliderStyle fallback}) {
  switch (raw) {
    case 'ios':
      return SliderStyle.ios;
    case 'capsule':
      return SliderStyle.capsule;
    default:
      return fallback;
  }
}

TextAlign _parseTextAlign(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'center':
      return TextAlign.center;
    case 'right':
    case 'end':
      return TextAlign.right;
    case 'justify':
      return TextAlign.justify;
    case 'left':
    case 'start':
    default:
      return TextAlign.left;
  }
}

String _textAlignToString(TextAlign align) {
  switch (align) {
    case TextAlign.center:
      return 'center';
    case TextAlign.right:
      return 'right';
    case TextAlign.justify:
      return 'justify';
    default:
      return 'left';
  }
}

CrossAxisAlignment _textAlignToCrossAxis(TextAlign align) {
  switch (align) {
    case TextAlign.center:
      return CrossAxisAlignment.center;
    case TextAlign.right:
      return CrossAxisAlignment.end;
    default:
      return CrossAxisAlignment.start;
  }
}

Alignment _textAlignToAlignment(TextAlign align) {
  switch (align) {
    case TextAlign.center:
      return Alignment.center;
    case TextAlign.right:
      return Alignment.centerRight;
    default:
      return Alignment.centerLeft;
  }
}

FontWeight _parseFontWeight(dynamic raw, FontWeight fallback) {
  if (raw is int) {
    switch (raw) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      default:
        return fallback;
    }
  }
  switch (_readString(raw)?.toLowerCase()) {
    case 'w100':
    case 'thin':
      return FontWeight.w100;
    case 'w200':
    case 'extralight':
      return FontWeight.w200;
    case 'w300':
    case 'light':
      return FontWeight.w300;
    case 'w400':
    case 'normal':
    case 'regular':
      return FontWeight.w400;
    case 'w500':
    case 'medium':
      return FontWeight.w500;
    case 'w600':
    case 'semibold':
      return FontWeight.w600;
    case 'w700':
    case 'bold':
      return FontWeight.w700;
    case 'w800':
    case 'extrabold':
      return FontWeight.w800;
    case 'w900':
    case 'black':
      return FontWeight.w900;
    default:
      return fallback;
  }
}
