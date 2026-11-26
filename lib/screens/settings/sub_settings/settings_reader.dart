import 'package:anymex/l10n/l10n_extension.dart';
import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/reader/tap_zones.dart';
import 'package:anymex/repositories/tap_zone_repository.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme_registry.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_chip.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';

class SettingsReader extends StatefulWidget {
  const SettingsReader({super.key});

  @override
  State<SettingsReader> createState() => _SettingsReaderState();
}

class _SettingsReaderState extends State<SettingsReader> {
  final settings = Get.find<Settings>();

  int _mangaLayout = ReaderKeys.readingLayout.get<int>(0);
  int _mangaDirection = ReaderKeys.readingDirection.get<int>(1);
  int _mangaDualPageMode = ReaderKeys.dualPageMode.get<int>(0);
  int _mangaFilterQuality = ReaderKeys.imageFilterQuality.get<int>(2);
  bool _mangaSpacedPages = ReaderKeys.spacedPages.get<bool>(false);
  bool _mangaPageIndicator = ReaderKeys.showPageIndicator.get<bool>(false);
  bool _mangaCropBorders = ReaderKeys.cropImages.get<bool>(false);
  bool _mangaFitToScreen = ReaderKeys.fitToScreen.get<bool>(false);
  bool _mangaKeepScreenOn = ReaderKeys.keepScreenOn.get<bool>(true);
  bool _mangaAutoWebtoon = ReaderKeys.autoWebtoonMode.get<bool>(false);
  bool _mangaChapterTransition =
      ReaderKeys.alwaysShowChapterTransition.get<bool>(false);
  bool _mangaOverscroll = ReaderKeys.overscrollToChapter.get<bool>(true);
  bool _mangaLongPressActions =
      ReaderKeys.longPressPageActionsEnabled.get<bool>(true);
  bool _mangaAutoScroll = ReaderKeys.autoScrollEnabled.get<bool>(false);
  double _mangaAutoScrollSpeed = ReaderKeys.autoScrollSpeed.get<double>(3.0);
  bool _mangaVolumeKeys = ReaderKeys.volumeKeysEnabled.get<bool>(false);
  bool _mangaInvertVolumeKeys = ReaderKeys.invertVolumeKeys.get<bool>(false);

  int _novelThemeMode = NovelReaderKeys.themeMode.get<int>(3);
  double _novelBackgroundOpacity =
      NovelReaderKeys.backgroundOpacity.get<double>(1.0);
  String _novelFontFamily = NovelReaderKeys.fontFamily.get<String>('System');
  double _novelFontSize = NovelReaderKeys.fontSize.get<double>(16.0);
  double _novelLineHeight = NovelReaderKeys.lineHeight.get<double>(1.6);
  double _novelLetterSpacing = NovelReaderKeys.letterSpacing.get<double>(0.0);
  double _novelWordSpacing = NovelReaderKeys.wordSpacing.get<double>(0.0);
  double _novelParagraphSpacing =
      NovelReaderKeys.paragraphSpacing.get<double>(16.0);
  bool _novelPageReaderMode = NovelReaderKeys.pageReader.get<bool>(false);
  bool _novelKeepScreenOn = NovelReaderKeys.keepScreenOn.get<bool>(true);
  bool _novelReadingProgress =
      NovelReaderKeys.showReadingProgress.get<bool>(true);
  bool _novelBatteryTime = NovelReaderKeys.showBatteryTime.get<bool>(true);
  bool _novelTtsEnabled = NovelReaderKeys.ttsEnabled.get<bool>(false);
  double _novelTtsSpeed = NovelReaderKeys.ttsSpeed.get<double>(0.5);
  double _novelTtsPitch = NovelReaderKeys.ttsPitch.get<double>(1.0);
  bool _novelTtsAutoAdvance = NovelReaderKeys.ttsAutoAdvance.get<bool>(true);
  bool _novelTapToScroll = NovelReaderKeys.tapToScroll.get<bool>(false);
  bool _novelSwipeGestures = NovelReaderKeys.swipeGestures.get<bool>(true);
  bool _novelVolumeScrolling = NovelReaderKeys.volumeScrolling.get<bool>(false);
  bool _novelAutoScroll = NovelReaderKeys.autoScroll.get<bool>(false);
  double _novelAutoScrollSpeed =
      NovelReaderKeys.autoScrollSpeed.get<double>(3.0);

  static const List<String> _novelFonts = [
    'System',
    'Serif',
    'Roboto',
    'Open Sans',
    'Lato',
    'Merriweather',
    'Crimson Text',
    'Libre Baskerville',
  ];

  ReaderController _acquirePreviewReaderController() {
    if (Get.isRegistered<ReaderController>()) {
      return Get.find<ReaderController>();
    }
    return Get.put<ReaderController>(ReaderController.preview());
  }

  void _releasePreviewReaderController(bool createdTemp) {
    if (createdTemp && Get.isRegistered<ReaderController>()) {
      final ctrl = Get.find<ReaderController>();
      if (ctrl.isPreview) {
        Get.delete<ReaderController>(force: true);
      }
    }
  }

  void _setReaderBool(ReaderKeys key, bool value, void Function() update) {
    setState(() {
      update();
      key.set(value);
    });
  }

  String _mangaDirectionLabel() {
    return switch (_mangaDirection) {
      0 => 'Bottom-Up',
      1 => 'Top-Down',
      2 => 'RTL',
      _ => 'LTR',
    };
  }

  String _mangaQualityLabel() {
    return switch (_mangaFilterQuality) {
      0 => 'None (Nearest)',
      1 => 'Low (Bilinear)',
      3 => 'High (Bicubic)',
      4 => 'Lanczos Pre-scale (Best)',
      _ => 'Medium (Default)',
    };
  }

  void _showMangaLayoutDialog() {
    showSelectionDialog<int>(
      title: context.l10n.readingLayout,
      items: const [0, 1],
      selectedItem: _mangaLayout.obs,
      getTitle: (value) => value == 0 ? 'Continuous' : 'Paged',
      onItemSelected: (value) {
        setState(() {
          _mangaLayout = value;
          ReaderKeys.readingLayout.set(value);
        });
      },
      leadingIcon: Iconsax.card,
    );
  }

  void _showMangaDirectionDialog() {
    showSelectionDialog<int>(
      title: context.l10n.readingDirection,
      items: const [0, 1, 2, 3],
      selectedItem: _mangaDirection.obs,
      getTitle: (value) => switch (value) {
        0 => 'Bottom-Up',
        1 => 'Top-Down',
        2 => 'RTL',
        _ => 'LTR',
      },
      onItemSelected: (value) {
        setState(() {
          _mangaDirection = value;
          ReaderKeys.readingDirection.set(value);
        });
      },
      leadingIcon: Iconsax.direct_right,
    );
  }

  void _showMangaDualPageDialog() {
    showSelectionDialog<int>(
      title: context.l10n.dualPageMode,
      items: const [0, 1, 2],
      selectedItem: _mangaDualPageMode.obs,
      getTitle: (value) => switch (value) {
        1 => 'Auto (Laptop/Tab)',
        2 => 'Force (Dual)',
        _ => 'Standard (Single)',
      },
      onItemSelected: (value) {
        setState(() {
          _mangaDualPageMode = value;
          ReaderKeys.dualPageMode.set(value);
        });
      },
      leadingIcon: Iconsax.book_1,
    );
  }

  void _showMangaFilterQualityDialog() {
    showSelectionDialog<int>(
      title: context.l10n.imageFilterQuality,
      items: const [0, 1, 2, 3, 4],
      selectedItem: _mangaFilterQuality.obs,
      getTitle: (value) => switch (value) {
        0 => 'None (Nearest-neighbor)',
        1 => 'Low (Bilinear)',
        3 => 'High (Bicubic)',
        4 => 'Lanczos Pre-scale (Best quality, slower)',
        _ => 'Medium (Default)',
      },
      onItemSelected: (value) {
        setState(() {
          _mangaFilterQuality = value;
          ReaderKeys.imageFilterQuality.set(value);
        });
      },
      leadingIcon: Icons.image_search_rounded,
    );
  }

  void _showChapterStyleDialog() {
    showSelectionDialog<String>(
      title: context.l10n.chapterTileStyle,
      items: const ['compact', 'detailed'],
      selectedItem: settings.chapterStyleRx,
      getTitle: (value) =>
          value == 'compact' ? 'Compact' : 'Detailed (Classic)',
      onItemSelected: (value) {
        setState(() {
          settings.chapterStyle = value;
        });
      },
      leadingIcon: Icons.list_alt_rounded,
    );
  }

  void _setNovelBool(NovelReaderKeys key, bool value, void Function() update) {
    setState(() {
      update();
      key.set(value);
    });
  }

  String _novelThemeLabel() {
    return switch (_novelThemeMode) {
      0 => 'Light',
      1 => 'Dark',
      2 => 'Sepia',
      _ => 'System',
    };
  }

  void _showNovelThemeDialog() {
    showSelectionDialog<int>(
      title: context.l10n.novelTheme,
      items: const [0, 1, 2, 3],
      selectedItem: _novelThemeMode.obs,
      getTitle: (value) => switch (value) {
        0 => 'Light',
        1 => 'Dark',
        2 => 'Sepia',
        _ => 'System',
      },
      onItemSelected: (value) {
        setState(() {
          _novelThemeMode = value;
          NovelReaderKeys.themeMode.set(value);
        });
      },
      leadingIcon: Icons.palette_rounded,
    );
  }

  void _showNovelFontDialog() {
    showSelectionDialog<String>(
      title: context.l10n.novelFontFamily,
      items: _novelFonts,
      selectedItem: _novelFontFamily.obs,
      getTitle: (value) => value,
      onItemSelected: (value) {
        setState(() {
          _novelFontFamily = value;
          NovelReaderKeys.fontFamily.set(value);
        });
      },
      leadingIcon: HugeIcons.strokeRoundedTextFont,
    );
  }

  void _resetNovelDefaults() {
    setState(() {
      _novelThemeMode = 3;
      _novelBackgroundOpacity = 1.0;
      _novelFontFamily = 'System';
      _novelFontSize = 16.0;
      _novelLineHeight = 1.6;
      _novelLetterSpacing = 0.0;
      _novelWordSpacing = 0.0;
      _novelParagraphSpacing = 16.0;
      _novelPageReaderMode = false;
      _novelKeepScreenOn = true;
      _novelReadingProgress = true;
      _novelBatteryTime = true;
      _novelTtsEnabled = false;
      _novelTtsSpeed = 0.5;
      _novelTtsPitch = 1.0;
      _novelTtsAutoAdvance = true;
      _novelAutoScroll = false;
      _novelAutoScrollSpeed = 3.0;
      _novelVolumeScrolling = false;
      _novelTapToScroll = false;
      _novelSwipeGestures = true;
    });

    NovelReaderKeys.themeMode.set(_novelThemeMode);
    NovelReaderKeys.backgroundOpacity.set(_novelBackgroundOpacity);
    NovelReaderKeys.fontFamily.set(_novelFontFamily);
    NovelReaderKeys.fontSize.set(_novelFontSize);
    NovelReaderKeys.lineHeight.set(_novelLineHeight);
    NovelReaderKeys.letterSpacing.set(_novelLetterSpacing);
    NovelReaderKeys.wordSpacing.set(_novelWordSpacing);
    NovelReaderKeys.paragraphSpacing.set(_novelParagraphSpacing);
    NovelReaderKeys.pageReader.set(_novelPageReaderMode);
    NovelReaderKeys.autoScroll.set(false);
    NovelReaderKeys.autoScrollSpeed.set(3.0);
    NovelReaderKeys.volumeScrolling.set(false);
    NovelReaderKeys.tapToScroll.set(false);
    NovelReaderKeys.keepScreenOn.set(_novelKeepScreenOn);
    NovelReaderKeys.swipeGestures.set(true);
    NovelReaderKeys.showReadingProgress.set(_novelReadingProgress);
    NovelReaderKeys.showBatteryTime.set(_novelBatteryTime);
    NovelReaderKeys.ttsEnabled.set(_novelTtsEnabled);
    NovelReaderKeys.ttsSpeed.set(_novelTtsSpeed);
    NovelReaderKeys.ttsPitch.set(_novelTtsPitch);
    NovelReaderKeys.ttsAutoAdvance.set(_novelTtsAutoAdvance);
  }

  Widget _buildNovelPreviewCard() {
    final colors = context.colors;
    final Color bgColor;
    final Color fgColor;
    switch (_novelThemeMode) {
      case 0:
        bgColor = Colors.white;
        fgColor = const Color(0xFF1B1B1F);
        break;
      case 1:
        bgColor = const Color(0xFF121318);
        fgColor = const Color(0xFFE6E1E5);
        break;
      case 2:
        bgColor = const Color(0xFFF4ECD8);
        fgColor = const Color(0xFF3E3021);
        break;
      default:
        bgColor = colors.surface;
        fgColor = colors.onSurface;
        break;
    }

    final resolvedFontFamily = switch (_novelFontFamily) {
      'System' => null,
      'Serif' => 'serif',
      _ => _novelFontFamily,
    };

    return AnymeXContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      color: colors.surfaceContainer.opaque(0.45),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: colors.outline.opaque(0.16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnymeXText(context.l10n.liveNovelPreview,
                variant: TextVariant.bold,
                size: 14,
              ),
              const Spacer(),
              AnymeXText(
                context.l10n.ptDetails(_novelFontFamily, _novelFontSize.toInt().toString()),
                size: 11,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: _novelBackgroundOpacity),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outline.opaque(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The wind swept quietly across the lantern-lit courtyard as the final bell echoed through the valley.',
                  style: TextStyle(
                    fontFamily: resolvedFontFamily,
                    fontSize: _novelFontSize,
                    height: _novelLineHeight,
                    letterSpacing: _novelLetterSpacing,
                    wordSpacing: _novelWordSpacing,
                    color: fgColor,
                  ),
                ),
                SizedBox(height: _novelParagraphSpacing.clamp(4.0, 24.0)),
                Text(
                  'He adjusted his coat and stepped forward into the mist.',
                  style: TextStyle(
                    fontFamily: resolvedFontFamily,
                    fontSize: _novelFontSize,
                    height: _novelLineHeight,
                    letterSpacing: _novelLetterSpacing,
                    wordSpacing: _novelWordSpacing,
                    color: fgColor.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReaderControlThemeDialog() async {
    final hadController = Get.isRegistered<ReaderController>();
    final previewController = _acquirePreviewReaderController();
    final themes = ReaderControlThemeRegistry.themes;
    String selectedId = settings.readerControlTheme;

    await AnymeXDialog(
      title: context.l10n.readerControlTheme,
      showCancelButton: false,
      confirmText: context.l10n.actionDone,
      padding: const EdgeInsets.all(20),
      width: getResponsiveValue(
        context,
        mobileValue: Get.width * 0.94,
        desktopValue: 560.0,
      ),
      onConfirm: () {},
      contentWidget: StatefulBuilder(
        builder: (ctx, setDialogState) {
          final colors = ctx.colors;
          final themeObj = ReaderControlThemeRegistry.resolve(selectedId);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnymeXText(
                    context.l10n.livePreview,
                    size: 12,
                    color: colors.onSurfaceVariant,
                  ),
                  AnymeXText(
                    themeObj.name,
                    size: 12,
                    color: colors.primary,
                    variant: TextVariant.semiBold,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 16 / 11,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    color: const Color(0xFF10131A),
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            width: 110,
                            height: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F4EE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    color: const Color(0xFF232732),
                                    alignment: Alignment.center,
                                    child: AnymeXText(context.l10n.mangaPage,
                                      size: 8,
                                      variant: TextVariant.bold,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          color: const Color(0xFFD6D2C9),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Container(
                                          color: const Color(0xFF333847),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: 480,
                              height: 330,
                              child: MediaQuery(
                                data: const MediaQueryData(
                                  size: Size(480, 330),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Builder(
                                  builder: (innerCtx) => Stack(
                                    fit: StackFit.expand,
                                    children: [
                                        themeObj.buildTopControls(
                                            innerCtx, previewController),
                                        themeObj.buildBottomControls(
                                            innerCtx, previewController),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: themes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, index) {
                    final item = themes[index];
                    return AnymeXTile.radio(
                      selected: item.id == selectedId,
                      title: item.name,
                      onTap: () {
                        setDialogState(() {
                          selectedId = item.id;
                          settings.readerControlTheme = item.id;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ).show(context);

    _releasePreviewReaderController(!hadController);
    if (mounted) setState(() {});
  }

  Color _tapActionColor(ReaderAction action, ColorScheme colors) {
    return switch (action) {
      ReaderAction.nextPage || ReaderAction.scrollDown => colors.primary,
      ReaderAction.prevPage || ReaderAction.scrollUp => colors.secondary,
      ReaderAction.toggleMenu => colors.tertiary,
      ReaderAction.nextChapter || ReaderAction.prevChapter => colors.error,
      ReaderAction.none => colors.outline,
    };
  }

  Future<void> _showTapZonesDialog() async {
    final repo = TapZoneRepository();
    bool isEnabled = repo.getTapZonesEnabled();
    bool isWebtoon = repo.getActiveIsWebtoon();
    bool isVertical = repo.getActiveIsVertical();
    TapZoneLayout pagedLayout = repo.getPagedLayout();
    TapZoneLayout pagedVerticalLayout = repo.getPagedVerticalLayout();
    TapZoneLayout webtoonLayout = repo.getWebtoonLayout();
    TapZoneLayout webtoonHorizontalLayout = repo.getWebtoonHorizontalLayout();
    int selectedZoneIndex = 0;

    TapZoneLayout currentLayout() {
      if (isWebtoon) {
        return isVertical ? webtoonLayout : webtoonHorizontalLayout;
      }
      return isVertical ? pagedVerticalLayout : pagedLayout;
    }

    void setCurrentLayout(TapZoneLayout updated) {
      if (isWebtoon) {
        if (isVertical) {
          webtoonLayout = updated;
        } else {
          webtoonHorizontalLayout = updated;
        }
      } else {
        if (isVertical) {
          pagedVerticalLayout = updated;
        } else {
          pagedLayout = updated;
        }
      }
    }

    TapZoneLayout defaultForCurrent() {
      if (isWebtoon) {
        return isVertical
            ? TapZoneLayout.defaultWebtoon
            : TapZoneLayout.defaultWebtoonHorizontal;
      }
      return isVertical
          ? TapZoneLayout.defaultPagedVertical
          : TapZoneLayout.defaultPaged;
    }

    await AnymeXDialog(
      title: context.l10n.tapZones,
      confirmText: context.l10n.actionSave,
      cancelText: context.l10n.actionCancel,
      padding: const EdgeInsets.all(20),
      width: getResponsiveValue(
        context,
        mobileValue: Get.width * 0.94,
        desktopValue: 560.0,
      ),
      onConfirm: () {
        repo.saveTapZonesEnabled(isEnabled);
        repo.savePagedLayout(pagedLayout);
        repo.savePagedVerticalLayout(pagedVerticalLayout);
        repo.saveWebtoonLayout(webtoonLayout);
        repo.saveWebtoonHorizontalLayout(webtoonHorizontalLayout);
        if (mounted) setState(() {});
      },
      contentWidget: StatefulBuilder(
        builder: (ctx, setDialogState) {
          final colors = ctx.colors;
          final layout = currentLayout();
          final safeIndex = selectedZoneIndex.clamp(0, layout.zones.length - 1);
          final selectedZone = layout.zones[safeIndex];

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AnymeXText(
                      context.l10n.enableTapZones,
                      variant: TextVariant.semiBold,
                      size: 14,
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    onChanged: (v) => setDialogState(() => isEnabled = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: false, label: Text(context.l10n.paged)),
                        ButtonSegment(value: true, label: Text(context.l10n.webtoon)),
                      ],
                      selected: {isWebtoon},
                      onSelectionChanged: (s) {
                        setDialogState(() {
                          isWebtoon = s.first;
                          selectedZoneIndex = 0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: false, label: Text(context.l10n.horiz)),
                        ButtonSegment(value: true, label: Text(context.l10n.vert)),
                      ],
                      selected: {isVertical},
                      onSelectionChanged: (s) {
                        setDialogState(() {
                          isVertical = s.first;
                          selectedZoneIndex = 0;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnymeXText(
                    context.l10n.tapARegionToSelect,
                    size: 12,
                    color: colors.onSurfaceVariant,
                  ),
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        setCurrentLayout(defaultForCurrent());
                        selectedZoneIndex = 0;
                      });
                    },
                    child: AnymeXText(context.l10n.actionReset, size: 12),
                  ),
                ],
              ),
              AspectRatio(
                aspectRatio: 16 / 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    color: const Color(0xFF10131A),
                    child: LayoutBuilder(
                      builder: (_, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        return Stack(
                          children: [
                            for (int i = 0; i < layout.zones.length; i++)
                              Positioned(
                                left: layout.zones[i].bounds.left * w,
                                top: layout.zones[i].bounds.top * h,
                                width: layout.zones[i].bounds.width * w,
                                height: layout.zones[i].bounds.height * h,
                                child: GestureDetector(
                                  onTap: () {
                                    setDialogState(() => selectedZoneIndex = i);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: _tapActionColor(
                                              layout.zones[i].action, colors)
                                          .withOpacity(
                                              i == safeIndex ? 0.38 : 0.18),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: i == safeIndex
                                            ? Colors.white
                                            : _tapActionColor(
                                                layout.zones[i].action, colors),
                                        width: i == safeIndex ? 2 : 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: AnymeXText(
                                          layout.zones[i].action.displayName,
                                          size: 11,
                                          variant: TextVariant.semiBold,
                                          color: Colors.white,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnymeXText(
                context.l10n.zoneAction(selectedZone.action.displayName),
                size: 12,
                variant: TextVariant.semiBold,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ReaderAction.values.map((action) {
                  final isSelected = selectedZone.action == action;
                  return AnymeXChip(
                    label: action.displayName,
                    isSelected: isSelected,
                    showCheck: false,
                    onSelected: (_) {
                      setDialogState(() {
                        final updatedZones = List<TapZone>.from(layout.zones);
                        updatedZones[safeIndex] =
                            TapZone(bounds: selectedZone.bounds, action: action);
                        setCurrentLayout(TapZoneLayout(
                          id: layout.id,
                          name: layout.name,
                          zones: updatedZones,
                        ));
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    ).show(context);
  }



  Widget _buildControlsSection() {
    return AnymeXSectionBuilder(
      title: context.l10n.controlsTapZones,
      children: [
        AnymeXTile(
          icon: Icons.style_rounded,
          title: context.l10n.controlTheme,
          subtitle: ReaderControlThemeRegistry.resolve(
            settings.readerControlTheme,
          ).name,
          onTap: _showReaderControlThemeDialog,
        ),
        AnymeXTile(
          icon: Icons.touch_app_rounded,
          title: context.l10n.customizeTapZones,
          subtitle: context.l10n.configurePagedAndWebtoonTapRegions,
          onTap: _showTapZonesDialog,
        ),
      ],
    );
  }

  Widget _buildMangaReaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 4.0),
          child: AnymeXText(
            context.l10n.mangaReader,
            size: 13.5,
            variant: TextVariant.semiBold,
            color: context.colors.primary,
          ),
        ),
        AnymeXExpansionTile(
          title: context.l10n.layoutDirection,
          subtitle:
              '${_mangaLayout == 0 ? 'Continuous' : 'Paged'} • ${_mangaDirectionLabel()}',
          icon: Iconsax.card,
          initialExpanded: true,
          useCard: true,
          useContentContainer: true,
          content: Column(
            children: [
              AnymeXTile(
                icon: Iconsax.card,
                title: context.l10n.layout,
                subtitle: _mangaLayout == 0 ? 'Continuous' : 'Paged',
                onTap: _showMangaLayoutDialog,
              ),
              AnymeXTile(
                icon: Iconsax.direct_right,
                title: context.l10n.direction,
                subtitle: _mangaDirectionLabel(),
                onTap: _showMangaDirectionDialog,
              ),
              AnymeXTile(
                icon: Iconsax.book_1,
                title: context.l10n.dualPageMode,
                subtitle: switch (_mangaDualPageMode) {
                  1 => 'Auto (Laptop/Tab)',
                  2 => 'Force (Dual)',
                  _ => 'Standard (Single)',
                },
                onTap: _showMangaDualPageDialog,
              ),
              AnymeXTile.toggle(
                icon: Icons.swap_vert_rounded,
                title: context.l10n.autoWebtoonMode,
                subtitle: context.l10n.autoSwitchToVerticalModeFor,
                value: _mangaAutoWebtoon,
                onChanged: (value) => _setReaderBool(
                  ReaderKeys.autoWebtoonMode,
                  value,
                  () => _mangaAutoWebtoon = value,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AnymeXExpansionTile(
          title: context.l10n.imageDisplay,
          subtitle: context.l10n.fitBordersSpacing((_mangaQualityLabel()).toString()),
          icon: Icons.image_search_rounded,
          initialExpanded: false,
          useCard: true,
          useContentContainer: true,
          content: Column(
            children: [
              AnymeXTile(
                icon: Icons.image_search_rounded,
                title: context.l10n.imageFilterQuality,
                subtitle: _mangaQualityLabel(),
                onTap: _showMangaFilterQualityDialog,
              ),
              AnymeXTile.toggle(
                icon: Icons.fullscreen_rounded,
                title: context.l10n.fitToScreenWidth,
                subtitle: context.l10n.stretchImagesToFitScreenWidth,
                value: _mangaFitToScreen,
                onChanged: (value) => _setReaderBool(
                  ReaderKeys.fitToScreen,
                  value,
                  () => _mangaFitToScreen = value,
                ),
              ),
              AnymeXTile.toggle(
                icon: Icons.crop_rounded,
                title: context.l10n.cropBorders,
                subtitle: context.l10n.removeWhiteBlackBorders,
                value: _mangaCropBorders,
                onChanged: (value) => _setReaderBool(
                  ReaderKeys.cropImages,
                  value,
                  () => _mangaCropBorders = value,
                ),
              ),
              AnymeXTile.toggle(
                icon: Iconsax.pharagraphspacing,
                title: context.l10n.spacedPages,
                subtitle: context.l10n.continuousModeOnly,
                value: _mangaSpacedPages,
                onChanged: (value) => _setReaderBool(
                  ReaderKeys.spacedPages,
                  value,
                  () => _mangaSpacedPages = value,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AnymeXExpansionTile(
          title: context.l10n.interfaceSession,
          subtitle: context.l10n.chapterStylePageIndicatorScreenLock,
          icon: Iconsax.eye,
          initialExpanded: false,
          useCard: true,
          useContentContainer: true,
          content: Column(
            children: [
              Obx(
                () => AnymeXTile(
                  icon: Icons.list_alt_rounded,
                  title: context.l10n.chapterTileStyle,
                  subtitle: settings.chapterStyle == 'compact'
                      ? 'Compact'
                      : 'Detailed (Classic)',
                  onTap: _showChapterStyleDialog,
                ),
              ),
              AnymeXTile.toggle(
                icon: Iconsax.eye,
                title: context.l10n.persistentPageIndicator,
                subtitle: context.l10n.alwaysShowPageIndicator,
                value: _mangaPageIndicator,
                onChanged: (value) => _setReaderBool(
                  ReaderKeys.showPageIndicator,
                  value,
                  () => _mangaPageIndicator = value,
                ),
              ),
              AnymeXTile.toggle(
                icon: Icons.swap_horiz_rounded,
                title: context.l10n.alwaysShowChapterTransition,
                subtitle: context.l10n.showChapterTransitionEvenWithoutGaps,
                value: _mangaChapterTransition,
                onChanged: (value) => _setReaderBool(
                  ReaderKeys.alwaysShowChapterTransition,
                  value,
                  () => _mangaChapterTransition = value,
                ),
              ),
              AnymeXTile.toggle(
                icon: Icons.lock_clock_rounded,
                title: context.l10n.keepScreenOn,
                subtitle: context.l10n.preventScreenFromSleepingWhileReading,
                value: _mangaKeepScreenOn,
                onChanged: (value) => _setReaderBool(
                  ReaderKeys.keepScreenOn,
                  value,
                  () => _mangaKeepScreenOn = value,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AnymeXExpansionTile(
          title: context.l10n.controlsGestures,
          subtitle: context.l10n.overscrollActionsAutoScrollVolume,
          icon: Iconsax.arrow,
          initialExpanded: false,
          useCard: true,
          useContentContainer: true,
          content: Column(
            children: [
              AnymeXTile.toggle(
                icon: Iconsax.arrow,
                title: context.l10n.overscroll,
                subtitle: context.l10n.overscrollToPreviousNextChapter,
                value: _mangaOverscroll,
                onChanged: (value) => _setReaderBool(
                  ReaderKeys.overscrollToChapter,
                  value,
                  () => _mangaOverscroll = value,
                ),
              ),
              AnymeXTile.toggle(
                icon: Icons.touch_app_rounded,
                title: context.l10n.longPressPageActions,
                subtitle: context.l10n.enableLongPressQuickActions,
                value: _mangaLongPressActions,
                onChanged: (value) => _setReaderBool(
                  ReaderKeys.longPressPageActionsEnabled,
                  value,
                  () => _mangaLongPressActions = value,
                ),
              ),
              AnymeXTile.toggle(
                icon: Icons.play_arrow_rounded,
                title: context.l10n.autoScroll,
                subtitle: context.l10n.automaticallyScrollMangaPages,
                value: _mangaAutoScroll,
                onChanged: (value) => _setReaderBool(
                  ReaderKeys.autoScrollEnabled,
                  value,
                  () => _mangaAutoScroll = value,
                ),
              ),
              if (_mangaAutoScroll)
                AnymeXTile.slider(
                  icon: Icons.speed_rounded,
                  title: context.l10n.autoScrollSpeed,
                  subtitle: context.l10n.secondsPerScreenPageLowerIs,
                  value: _mangaAutoScrollSpeed,
                  min: 1.0,
                  max: 10.0,
                  divisions: 18,
                  onChanged: (value) {
                    setState(() => _mangaAutoScrollSpeed = value);
                    ReaderKeys.autoScrollSpeed.set(value);
                  },
                ),
              if (Platform.isAndroid)
                AnymeXTile.toggle(
                  icon: Iconsax.volume_high,
                  title: context.l10n.volumeKeysNavigation,
                  subtitle: context.l10n.useVolumeKeysToChangePages,
                  value: _mangaVolumeKeys,
                  onChanged: (value) => _setReaderBool(
                    ReaderKeys.volumeKeysEnabled,
                    value,
                    () => _mangaVolumeKeys = value,
                  ),
                ),
              if (Platform.isAndroid)
                AnymeXTile.toggle(
                  icon: Iconsax.arrow_swap_horizontal,
                  title: context.l10n.invertVolumeKeys,
                  subtitle: context.l10n.swapVolumeUpDownActions,
                  value: _mangaInvertVolumeKeys,
                  onChanged: (value) => _setReaderBool(
                    ReaderKeys.invertVolumeKeys,
                    value,
                    () => _mangaInvertVolumeKeys = value,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNovelReaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 4.0),
          child: AnymeXText(
            context.l10n.novelReader,
            size: 13.5,
            variant: TextVariant.semiBold,
            color: context.colors.primary,
          ),
        ),
        _buildNovelPreviewCard(),
        AnymeXExpansionTile(
          title: context.l10n.themeTypography,
          subtitle:
              context.l10n.pt2(_novelThemeLabel(), _novelFontFamily, (_novelFontSize.toInt()).toString()),
          icon: Icons.palette_rounded,
          initialExpanded: true,
          useCard: true,
          useContentContainer: true,
          content: Column(
            children: [
              AnymeXTile(
                icon: Icons.palette_rounded,
                title: context.l10n.novelTheme,
                subtitle: _novelThemeLabel(),
                onTap: _showNovelThemeDialog,
              ),
              AnymeXTile.slider(
                icon: Icons.opacity_rounded,
                title: context.l10n.backgroundOpacity,
                subtitle: '${(_novelBackgroundOpacity * 100).toInt()}%',
                value: _novelBackgroundOpacity,
                min: 0.1,
                max: 1.0,
                divisions: 18,
                onChanged: (value) {
                  setState(() => _novelBackgroundOpacity = value);
                  NovelReaderKeys.backgroundOpacity.set(value);
                },
              ),
              AnymeXTile(
                icon: HugeIcons.strokeRoundedTextFont,
                title: context.l10n.fontFamily,
                subtitle: _novelFontFamily,
                onTap: _showNovelFontDialog,
              ),
              AnymeXTile.slider(
                icon: Icons.format_size_rounded,
                title: context.l10n.fontSize,
                subtitle: context.l10n.pt((_novelFontSize.toInt()).toString()),
                value: _novelFontSize,
                min: 12.0,
                max: 32.0,
                divisions: 20,
                onChanged: (value) {
                  setState(() => _novelFontSize = value);
                  NovelReaderKeys.fontSize.set(value);
                },
              ),
              AnymeXTile.slider(
                icon: Icons.format_line_spacing_rounded,
                title: context.l10n.lineHeight,
                subtitle: _novelLineHeight.toStringAsFixed(1),
                value: _novelLineHeight,
                min: 1.0,
                max: 3.0,
                divisions: 20,
                onChanged: (value) {
                  setState(() => _novelLineHeight = value);
                  NovelReaderKeys.lineHeight.set(value);
                },
              ),
              AnymeXTile.slider(
                icon: Icons.space_bar_rounded,
                title: context.l10n.letterSpacing,
                subtitle: _novelLetterSpacing.toStringAsFixed(1),
                value: _novelLetterSpacing,
                min: -1.0,
                max: 5.0,
                divisions: 12,
                onChanged: (value) {
                  setState(() => _novelLetterSpacing = value);
                  NovelReaderKeys.letterSpacing.set(value);
                },
              ),
              AnymeXTile.slider(
                icon: Icons.view_headline_rounded,
                title: context.l10n.wordSpacing,
                subtitle: _novelWordSpacing.toStringAsFixed(1),
                value: _novelWordSpacing,
                min: -2.0,
                max: 10.0,
                divisions: 24,
                onChanged: (value) {
                  setState(() => _novelWordSpacing = value);
                  NovelReaderKeys.wordSpacing.set(value);
                },
              ),
              AnymeXTile.slider(
                icon: Icons.format_line_spacing_rounded,
                title: context.l10n.paragraphSpacing,
                subtitle: context.l10n.px((_novelParagraphSpacing.toInt()).toString()),
                value: _novelParagraphSpacing,
                min: 4.0,
                max: 36.0,
                divisions: 16,
                onChanged: (value) {
                  setState(() => _novelParagraphSpacing = value);
                  NovelReaderKeys.paragraphSpacing.set(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AnymeXExpansionTile(
          title: context.l10n.readingModeDisplay,
          subtitle: context.l10n.pageModeProgressBatteryIndicator,
          icon: Iconsax.book_1,
          initialExpanded: false,
          useCard: true,
          useContentContainer: true,
          content: Column(
            children: [
              AnymeXTile.toggle(
                icon: Iconsax.book,
                title: context.l10n.pageReaderMode,
                subtitle: context.l10n.readPageByPageInsteadOf,
                value: _novelPageReaderMode,
                onChanged: (value) => _setNovelBool(
                  NovelReaderKeys.pageReader,
                  value,
                  () => _novelPageReaderMode = value,
                ),
              ),
              AnymeXTile.toggle(
                icon: Icons.lock_clock_rounded,
                title: context.l10n.keepScreenOn,
                subtitle: context.l10n.preventScreenFromSleepingWhileReading,
                value: _novelKeepScreenOn,
                onChanged: (value) => _setNovelBool(
                  NovelReaderKeys.keepScreenOn,
                  value,
                  () => _novelKeepScreenOn = value,
                ),
              ),
              AnymeXTile.toggle(
                icon: Iconsax.document_text,
                title: context.l10n.showReadingProgress,
                subtitle: context.l10n.displayPercentageInReadingBar,
                value: _novelReadingProgress,
                onChanged: (value) => _setNovelBool(
                  NovelReaderKeys.showReadingProgress,
                  value,
                  () => _novelReadingProgress = value,
                ),
              ),
              AnymeXTile.toggle(
                icon: Icons.battery_charging_full_rounded,
                title: context.l10n.showBatteryTime,
                subtitle: context.l10n.displayBatteryAndTimeInReader,
                value: _novelBatteryTime,
                onChanged: (value) => _setNovelBool(
                  NovelReaderKeys.showBatteryTime,
                  value,
                  () => _novelBatteryTime = value,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AnymeXExpansionTile(
          title: context.l10n.gesturesNavigation,
          subtitle: context.l10n.tapToScrollSwipeAutoScroll,
          icon: Icons.touch_app_rounded,
          initialExpanded: false,
          useCard: true,
          useContentContainer: true,
          content: Column(
            children: [
              AnymeXTile.toggle(
                icon: Icons.touch_app_rounded,
                title: context.l10n.tapToScroll,
                subtitle: context.l10n.tapEdgesOfScreenToScroll,
                value: _novelTapToScroll,
                onChanged: (value) => _setNovelBool(
                  NovelReaderKeys.tapToScroll,
                  value,
                  () => _novelTapToScroll = value,
                ),
              ),
              AnymeXTile.toggle(
                icon: Icons.swipe_rounded,
                title: context.l10n.swipeGestures,
                subtitle: context.l10n.swipeHorizontallyToChangeChapters,
                value: _novelSwipeGestures,
                onChanged: (value) => _setNovelBool(
                  NovelReaderKeys.swipeGestures,
                  value,
                  () => _novelSwipeGestures = value,
                ),
              ),
              if (Platform.isAndroid)
                AnymeXTile.toggle(
                  icon: Iconsax.volume_high,
                  title: context.l10n.volumeKeyScrolling,
                  subtitle: context.l10n.useVolumeKeysToScroll,
                  value: _novelVolumeScrolling,
                  onChanged: (value) => _setNovelBool(
                    NovelReaderKeys.volumeScrolling,
                    value,
                    () => _novelVolumeScrolling = value,
                  ),
                ),
              AnymeXTile.toggle(
                icon: Icons.play_arrow_rounded,
                title: context.l10n.autoScroll,
                subtitle: context.l10n.automaticallyScrollContent,
                value: _novelAutoScroll,
                onChanged: (value) => _setNovelBool(
                  NovelReaderKeys.autoScroll,
                  value,
                  () => _novelAutoScroll = value,
                ),
              ),
              if (_novelAutoScroll)
                AnymeXTile.slider(
                  icon: Icons.speed_rounded,
                  title: context.l10n.autoScrollSpeed,
                  subtitle: context.l10n.secondsPerScreenLowerIsFaster,
                  value: _novelAutoScrollSpeed,
                  min: 1.0,
                  max: 10.0,
                  divisions: 18,
                  onChanged: (value) {
                    setState(() => _novelAutoScrollSpeed =
                        value.clamp(1.0, 10.0).toDouble());
                    NovelReaderKeys.autoScrollSpeed
                        .set(_novelAutoScrollSpeed);
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AnymeXExpansionTile(
          title: context.l10n.textToSpeechTts2,
          subtitle: _novelTtsEnabled
              ? 'Enabled • ${_novelTtsSpeed.toStringAsFixed(1)}x speed'
              : 'Disabled',
          icon: Icons.record_voice_over_rounded,
          initialExpanded: false,
          useCard: true,
          useContentContainer: true,
          content: Column(
            children: [
              AnymeXTile.toggle(
                icon: Icons.record_voice_over_rounded,
                title: context.l10n.enableTts,
                subtitle: context.l10n.textToSpeechReadingSupport,
                value: _novelTtsEnabled,
                onChanged: (value) => _setNovelBool(
                  NovelReaderKeys.ttsEnabled,
                  value,
                  () => _novelTtsEnabled = value,
                ),
              ),
              if (_novelTtsEnabled) ...[
                AnymeXTile.slider(
                  icon: Icons.speed_rounded,
                  title: context.l10n.speechRate2,
                  subtitle: context.l10n.x((_novelTtsSpeed.toStringAsFixed(1)).toString()),
                  value: _novelTtsSpeed,
                  min: 0.1,
                  max: 2.0,
                  divisions: 19,
                  onChanged: (value) {
                    setState(() => _novelTtsSpeed = value);
                    NovelReaderKeys.ttsSpeed.set(value);
                  },
                ),
                AnymeXTile.slider(
                  icon: Icons.graphic_eq_rounded,
                  title: context.l10n.voicePitch2,
                  subtitle: _novelTtsPitch.toStringAsFixed(1),
                  value: _novelTtsPitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: (value) {
                    setState(() => _novelTtsPitch = value);
                    NovelReaderKeys.ttsPitch.set(value);
                  },
                ),
                AnymeXTile.toggle(
                  icon: Icons.skip_next_rounded,
                  title: context.l10n.ttsAutoAdvance,
                  subtitle: context.l10n.automaticallyMoveToNextTextSegment,
                  value: _novelTtsAutoAdvance,
                  onChanged: (value) => _setNovelBool(
                    NovelReaderKeys.ttsAutoAdvance,
                    value,
                    () => _novelTtsAutoAdvance = value,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        AnymeXTile(
          icon: Icons.restart_alt_rounded,
          title: context.l10n.resetNovelReaderSettings,
          subtitle: context.l10n.restoreAllNovelReaderDefaults,
          onTap: _resetNovelDefaults,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: context.l10n.readerSettings,
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16.0,
            AnymeXHeaderScope.of(ctx),
            16.0,
            30.0,
          ),
          child: Column(
            children: [
              _buildControlsSection(),
              const SizedBox(height: 16),
              _buildMangaReaderSection(),
              const SizedBox(height: 16),
              _buildNovelReaderSection(),
            ],
          ),
        ),
      ),
    );
  }
}
