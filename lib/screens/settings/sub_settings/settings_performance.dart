import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class SettingsPerformance extends StatefulWidget {
  const SettingsPerformance({super.key});

  @override
  State<SettingsPerformance> createState() => _SettingsPerformanceState();
}

class _SettingsPerformanceState extends State<SettingsPerformance> {
  final settings = Get.find<Settings>();
  List<DisplayMode> _supportedModes = [];
  bool _isLoading = true;
  String? _selectedResolution;

  @override
  void initState() {
    super.initState();
    _loadDisplayModes();
  }

  Future<void> _loadDisplayModes() async {
    if (!Platform.isAndroid) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final modes = await FlutterDisplayMode.supported;
      final active = await FlutterDisplayMode.active;
      settings.activeDisplayMode.value = active;
      if (mounted) {
        setState(() {
          _supportedModes = modes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onRefreshRateSelected(
      int newHz, String currentRes, List<DisplayMode> validModes) async {
    if (newHz == 0) {
      await settings.savePreferredDisplayMode(DisplayMode.auto);
      final active = await FlutterDisplayMode.active;
      settings.activeDisplayMode.value = active;
      setState(() {});
      return;
    }
    DisplayMode? match = validModes.firstWhereOrNull(
      (m) =>
          '${m.width}x${m.height}' == currentRes &&
          m.refreshRate.round() == newHz,
    );
    match ??= validModes.firstWhereOrNull(
      (m) => m.refreshRate.round() == newHz,
    );
    if (match != null) {
      await settings.savePreferredDisplayMode(match);
      final active = await FlutterDisplayMode.active;
      settings.activeDisplayMode.value = active;
      setState(() {});
    }
  }

  void _onResolutionSelected(
      String newRes, int currentHz, List<DisplayMode> validModes) async {
    _selectedResolution = newRes;
    if (currentHz != 0) {
      DisplayMode? match = validModes.firstWhereOrNull(
        (m) =>
            '${m.width}x${m.height}' == newRes &&
            m.refreshRate.round() == currentHz,
      );
      match ??= validModes.firstWhereOrNull(
        (m) => '${m.width}x${m.height}' == newRes,
      );
      if (match != null) {
        await settings.savePreferredDisplayMode(match);
        final active = await FlutterDisplayMode.active;
        settings.activeDisplayMode.value = active;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      return const AnymeXScaffold(
        showHeader: true,
        headerTitle: 'Performance',
        body: Center(
          child: AnymeXText(
              'Display mode tuning is not applicable on desktop platforms.'),
        ),
      );
    }

    final validModes = _supportedModes
        .where((m) =>
            m != DisplayMode.auto &&
            m.id != 0 &&
            m.width != 0 &&
            m.height != 0)
        .toList();

    final resolutions =
        validModes.map((m) => '${m.width}x${m.height}').toSet().toList();
    resolutions.sort((a, b) {
      final aParts = a.split('x').map(int.parse).toList();
      final bParts = b.split('x').map(int.parse).toList();
      final aPixels = aParts[0] * aParts[1];
      final bPixels = bParts[0] * bParts[1];
      return aPixels.compareTo(bPixels);
    });

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Performance',
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16.0, AnymeXHeaderScope.of(ctx), 16.0, 30.0),
          child: Obx(() {
            final preferred = settings.preferredDisplayMode.value;
            final active = settings.activeDisplayMode.value;

            String currentRes = _selectedResolution ??
                ((preferred != null &&
                        preferred != DisplayMode.auto &&
                        preferred.width > 0)
                    ? '${preferred.width}x${preferred.height}'
                    : (active != null && active.width > 0
                        ? '${active.width}x${active.height}'
                        : (resolutions.isNotEmpty ? resolutions.first : '')));

            if (resolutions.isNotEmpty && !resolutions.contains(currentRes)) {
              currentRes = resolutions.first;
            }

            final modesForRes = validModes
                .where((m) => '${m.width}x${m.height}' == currentRes)
                .toList();

            final distinctHz =
                (modesForRes.isNotEmpty ? modesForRes : validModes)
                    .map((m) => m.refreshRate.round())
                    .toSet()
                    .toList()
                  ..sort();

            final hzOptions = [0, ...distinctHz];

            int currentHz = 0;
            if (preferred != null && preferred != DisplayMode.auto) {
              currentHz = preferred.refreshRate.round();
            }
            if (currentHz != 0 && !distinctHz.contains(currentHz)) {
              currentHz = 0;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ] else if (validModes.isEmpty) ...[
                  const AnymeXTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Display Mode',
                    subtitle:
                        'Hardware display mode switching is not supported by your device.',
                  ),
                ] else ...[
                  AnymeXSectionBuilder(
                    title: 'Display',
                    children: [
                      if (resolutions.length > 1)
                        AnymeXTile.pills<String>(
                          icon: Icons.aspect_ratio_rounded,
                          title: 'Resolution',
                          value: currentRes,
                          options: resolutions,
                          optionLabelTransformer: (res) => res,
                          onChanged: (newRes) => _onResolutionSelected(
                              newRes, currentHz, validModes),
                        )
                      else if (resolutions.isNotEmpty)
                        AnymeXTile(
                          icon: Icons.aspect_ratio_rounded,
                          title: 'Resolution',
                          subtitle: resolutions.first,
                        ),
                      AnymeXTile.pills<int>(
                        icon: HugeIcons.strokeRoundedDashboardSpeed01,
                        title: 'Refresh Rate',
                        value: currentHz,
                        options: hzOptions,
                        optionLabelTransformer: (hz) =>
                            hz == 0 ? 'Auto' : '${hz}Hz',
                        onChanged: (newHz) => _onRefreshRateSelected(
                            newHz, currentRes, validModes),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AnymeXSectionBuilder(
                    title: 'Info',
                    children: [
                      AnymeXTile(
                        icon: Icons.monitor_rounded,
                        title: 'Display Mode',
                        subtitle: active != null
                            ? '${active.width}x${active.height} @ ${active.refreshRate.round()}Hz'
                            : 'Unknown',
                      ),
                      AnymeXTile(
                        icon: Icons.layers_outlined,
                        title: 'Supported Modes',
                        subtitle: '${validModes.length} modes',
                      ),
                    ],
                  ),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }
}
