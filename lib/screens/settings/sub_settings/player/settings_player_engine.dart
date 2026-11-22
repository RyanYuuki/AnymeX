import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/player_core_visual_settings.dart';
import 'package:anymex/utils/shaders.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class _DecoderOption {
  final String value;
  final String title;
  final String description;

  const _DecoderOption({
    required this.value,
    required this.title,
    required this.description,
  });
}

class _RendererOption {
  final String value;
  final String title;
  final String description;

  const _RendererOption({
    required this.value,
    required this.title,
    required this.description,
  });
}

class _AudioOption {
  final String value;
  final String title;
  final String description;

  const _AudioOption({
    required this.value,
    required this.title,
    required this.description,
  });
}

class SettingsPlayerEngine extends StatefulWidget {
  final bool isModal;
  final bool isEmbedded;
  const SettingsPlayerEngine({
    super.key,
    this.isModal = false,
    this.isEmbedded = false,
  });

  @override
  State<SettingsPlayerEngine> createState() => _SettingsPlayerEngineState();
}

class _SettingsPlayerEngineState extends State<SettingsPlayerEngine> {
  final settings = Get.find<Settings>();
  late bool _useMpvConf;

  @override
  void initState() {
    super.initState();
    _useMpvConf = PlayerUiKeys.useMpvConf.get<bool>(false);
  }

  bool get _supportsDecoderSelection =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isLinux ||
      Platform.isMacOS ||
      Platform.isWindows;

  List<_DecoderOption> get _decoderOptions {
    if (Platform.isAndroid) {
      return const [
        _DecoderOption(
            value: 'hw+', title: 'HW+', description: 'mediacodec-copy'),
        _DecoderOption(value: 'hw', title: 'HW', description: 'mediacodec'),
        _DecoderOption(value: 'sw', title: 'SW', description: 'no'),
      ];
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return const [
        _DecoderOption(value: 'hw+', title: 'HW+', description: 'videotoolbox'),
        _DecoderOption(value: 'hw', title: 'HW', description: 'videotoolbox'),
        _DecoderOption(value: 'sw', title: 'SW', description: 'no'),
      ];
    }
    if (Platform.isWindows) {
      return const [
        _DecoderOption(value: 'hw+', title: 'HW+', description: 'd3d11va-copy'),
        _DecoderOption(value: 'hw', title: 'HW', description: 'd3d11va'),
        _DecoderOption(value: 'sw', title: 'SW', description: 'no'),
      ];
    }
    if (Platform.isLinux) {
      return const [
        _DecoderOption(value: 'hw+', title: 'HW+', description: 'vaapi-copy'),
        _DecoderOption(value: 'hw', title: 'HW', description: 'vaapi'),
        _DecoderOption(value: 'sw', title: 'SW', description: 'no'),
      ];
    }
    return const [
      _DecoderOption(value: 'hw+', title: 'HW+', description: 'auto-copy'),
      _DecoderOption(value: 'hw', title: 'HW', description: 'auto'),
      _DecoderOption(value: 'sw', title: 'SW', description: 'no'),
    ];
  }

  List<_RendererOption> get _rendererOptions {
    final list = [
      const _RendererOption(
          value: 'auto',
          title: 'Auto (GPU)',
          description: 'Auto-select (default)'),
      const _RendererOption(
          value: 'gpu', title: 'GPU', description: 'Standard GPU rendering'),
      const _RendererOption(
          value: 'gpu-next',
          title: 'GPU Next (Vulkan)',
          description: 'Experimental high-performance renderer'),
    ];
    if (Platform.isAndroid) {
      list.add(
        const _RendererOption(
          value: 'mediacodec_embed',
          title: 'MediaCodec Embed',
          description: 'Direct surface rendering (Android only)',
        ),
      );
    }
    return list;
  }

  List<_AudioOption> get _audioOptions {
    if (Platform.isAndroid) {
      return const [
        _AudioOption(
            value: 'auto',
            title: 'Auto (AudioTrack)',
            description: 'Default Android AudioTrack API'),
        _AudioOption(
            value: 'audiotrack',
            title: 'AudioTrack',
            description: 'Android AudioTrack API'),
        _AudioOption(
            value: 'opensles',
            title: 'OpenSL ES',
            description: 'OpenSL ES native audio engine'),
      ];
    }
    if (Platform.isWindows) {
      return const [
        _AudioOption(
            value: 'auto',
            title: 'Auto (WASAPI)',
            description: 'Default Windows audio driver'),
        _AudioOption(
            value: 'wasapi',
            title: 'WASAPI',
            description: 'Windows Audio Session API'),
        _AudioOption(
            value: 'sdl',
            title: 'SDL',
            description: 'Simple DirectMedia Layer audio output'),
      ];
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return const [
        _AudioOption(
            value: 'auto',
            title: 'Auto (CoreAudio)',
            description: 'Default Apple CoreAudio API'),
        _AudioOption(
            value: 'coreaudio',
            title: 'CoreAudio',
            description: 'Apple CoreAudio API'),
      ];
    }
    if (Platform.isLinux) {
      return const [
        _AudioOption(
            value: 'auto',
            title: 'Auto (PulseAudio)',
            description: 'Default PulseAudio API'),
        _AudioOption(
            value: 'pulse',
            title: 'PulseAudio',
            description: 'PulseAudio sound server'),
        _AudioOption(
            value: 'alsa',
            title: 'ALSA',
            description: 'Advanced Linux Sound Architecture'),
        _AudioOption(
            value: 'sdl',
            title: 'SDL',
            description: 'Simple DirectMedia Layer audio output'),
      ];
    }
    return const [
      _AudioOption(
          value: 'auto',
          title: 'Auto',
          description: 'Default system audio driver'),
    ];
  }

  String _decoderTitle(String value) => _decoderOptions
      .firstWhere((o) => o.value == value, orElse: () => _decoderOptions.first)
      .title;

  String _decoderDescription(String value) => _decoderOptions
      .firstWhere((o) => o.value == value, orElse: () => _decoderOptions.first)
      .description;

  String _rendererTitle(String value) => _rendererOptions
      .firstWhere((o) => o.value == value, orElse: () => _rendererOptions.first)
      .title;

  String _rendererDescription(String value) => _rendererOptions
      .firstWhere((o) => o.value == value, orElse: () => _rendererOptions.first)
      .description;

  String _audioTitle(String value) => _audioOptions
      .firstWhere((o) => o.value == value, orElse: () => _audioOptions.first)
      .title;

  String _audioDescription(String value) => _audioOptions
      .firstWhere((o) => o.value == value, orElse: () => _audioOptions.first)
      .description;

  void _showDecoderModeDialog() {
    showSelectionDialog<String>(
      title: 'Decoder',
      items: _decoderOptions.map((o) => o.value).toList(),
      selectedItem: settings.hardwareDecoder.obs,
      getTitle: _decoderTitle,
      onItemSelected: (value) {
        settings.hardwareDecoder = value;
        setState(() {});
      },
      leadingIcon: Icons.memory_rounded,
    );
  }

  void _showRendererSelectionDialog() {
    showSelectionDialog<String>(
      title: 'Video Renderer',
      items: _rendererOptions.map((o) => o.value).toList(),
      selectedItem: settings.videoOutput.obs,
      getTitle: _rendererTitle,
      onItemSelected: (value) {
        settings.videoOutput = value;
        setState(() {});
      },
      leadingIcon: Icons.settings_system_daydream_rounded,
    );
  }

  void _showAudioSelectionDialog() {
    showSelectionDialog<String>(
      title: 'Audio Engine',
      items: _audioOptions.map((o) => o.value).toList(),
      selectedItem: settings.audioOutput.obs,
      getTitle: _audioTitle,
      onItemSelected: (value) {
        settings.audioOutput = value;
        setState(() {});
      },
      leadingIcon: Icons.audiotrack_rounded,
    );
  }

  void _showMpvCoreSelectionDialog({
    required String title,
    required List<String> items,
    required String selected,
    required String Function(String) getTitle,
    required String key,
  }) {
    showSelectionDialog<String>(
      title: title,
      items: items,
      selectedItem: selected.obs,
      getTitle: getTitle,
      onItemSelected: (value) {
        PlayerCoreVisualSettings.setMpvCoreSetting(key, value);
        setState(() {});
      },
      leadingIcon: Icons.tune_rounded,
    );
  }

  void _showMpvVisualSelectionDialog({
    required String title,
    required List<String> items,
    required String selected,
    required String Function(String) getTitle,
    required String key,
  }) {
    showSelectionDialog<String>(
      title: title,
      items: items,
      selectedItem: selected.obs,
      getTitle: getTitle,
      onItemSelected: (value) {
        PlayerCoreVisualSettings.setMpvVisualSetting(key, value);
        setState(() {});
      },
      leadingIcon: Icons.tune_rounded,
    );
  }

  Future<void> _showMpvConfEditorSheet(BuildContext context) async {
    await PlayerShaders.createMpvConfigFolder();
    final configPath = await PlayerShaders.getMpvConfigPath();
    final file = File(configPath);
    final initialContent = (await file.exists()) ? await file.readAsString() : '';
    final controller = TextEditingController(text: initialContent);

    if (!context.mounted) return;

    await AnymeXSheet.custom(
      StatefulBuilder(
        builder: (ctx, setSheetState) {
          final colors = ctx.colors;
          return Container(
            height: MediaQuery.sizeOf(ctx).height * 0.85,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.description_rounded,
                          color: colors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AnymeXText(
                            'mpv.conf',
                            variant: TextVariant.bold,
                            size: 18,
                          ),
                          AnymeXText(
                            'Custom player flags & parameters',
                            variant: TextVariant.semiBold,
                            color: colors.onSurface.withValues(alpha: 0.6),
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (!await file.parent.exists()) {
                          await file.parent.create(recursive: true);
                        }
                        await file.writeAsString(controller.text);
                        if (ctx.mounted) Navigator.pop(ctx);
                        snackBar('mpv.conf saved successfully');
                      },
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const AnymeXText('Save', variant: TextVariant.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        colors.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: colors.outline.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder_open_rounded,
                          size: 16, color: colors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          configPath,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        tooltip: 'Copy path',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: configPath));
                          snackBar('Path copied to clipboard');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                AnymeXText(
                  'One option per line, like hwdec=auto or scale=ewa_lanczossharp. Lines starting with # are comments. Profiles in [brackets] are ignored.',
                  variant: TextVariant.regular,
                  color: colors.onSurface.withValues(alpha: 0.6),
                  size: 11,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          colors.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colors.outline.withValues(alpha: 0.2)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: controller,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.4,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText:
                            '# Example options:\nhwdec=auto\nscale=ewa_lanczossharp\ncscale=ewa_lanczossharp\ndscale=mitchell\ncorrect-downscaling=yes\nsigmoid-upscaling=yes\ndeband=yes',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        controller.text =
                            '# High Quality Video Options\nhwdec=auto\nscale=ewa_lanczossharp\ncscale=ewa_lanczossharp\ndscale=mitchell\ncorrect-downscaling=yes\nsigmoid-upscaling=yes\ndeband=yes\n\n# Network & Caching\ncache=yes\ndemuxer-readahead-secs=60\n';
                        setSheetState(() {});
                      },
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                      label: const AnymeXText('Load Template',
                          variant: TextVariant.semiBold, size: 12),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        controller.clear();
                        setSheetState(() {});
                      },
                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                      label: const AnymeXText('Clear',
                          variant: TextVariant.semiBold, size: 12),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      context,
      showDragHandle: true,
    );

    controller.dispose();
  }

  Widget _buildExperimentalGateMessage(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer.opaque(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.primary.opaque(0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: context.colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: AnymeXText(
              text,
              style: TextStyle(
                color: context.colors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final experimentalEnabled =
        PlayerUiKeys.playerExperimentalEnabled.get<bool>(false);
    final mpvCore = PlayerCoreVisualSettings.getMpvCoreSettings();
    final mpvVisual = PlayerCoreVisualSettings.getMpvVisualSettings();

    final content = Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_supportsDecoderSelection)
            AnymeXSectionBuilder(
              title: 'Hardware & Drivers',
                    children: [
                      AnymeXTile(
                        icon: Icons.memory_rounded,
                        title: 'Decoder',
                        subtitle: _decoderDescription(settings.hardwareDecoder),
                        onTap: _showDecoderModeDialog,
                      ),
                      AnymeXTile(
                        icon: Icons.settings_system_daydream_rounded,
                        title: 'Video Renderer',
                        subtitle: _rendererDescription(settings.videoOutput),
                        onTap: _showRendererSelectionDialog,
                      ),
                      AnymeXTile(
                        icon: Icons.audiotrack_rounded,
                        title: 'Audio Engine',
                        subtitle: _audioDescription(settings.audioOutput),
                        onTap: _showAudioSelectionDialog,
                      ),
                    ],
                  ),
                AnymeXSectionBuilder(
                  title: 'System & Integrations',
                  children: [
                    AnymeXTile.toggle(
                      icon: Icons.screenshot_rounded,
                      title: 'Save Last Frame',
                      subtitle:
                          'Save a screenshot of the last frame watched (uses extra storage)',
                      value: settings.enableScreenshot,
                      onChanged: (val) => settings.enableScreenshot = val,
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.bluetooth_audio_rounded,
                      title: 'Media Session (Bluetooth Support)',
                      subtitle:
                          'Enable background media controls for Bluetooth headsets and system notifications',
                      value: settings.useMediaSession,
                      onChanged: (val) => settings.useMediaSession = val,
                    ),
                  ],
                ),
                AnymeXSectionBuilder(
                  title: 'Experimental MPV Tuning',
                  children: [
                    AnymeXTile.toggle(
                      icon: Icons.science_outlined,
                      title: 'Enable Experimental Settings',
                      subtitle:
                          'Required for Core and Visual tuning. Keep off on low-end devices.',
                      value: experimentalEnabled,
                      onChanged: (val) {
                        PlayerUiKeys.playerExperimentalEnabled.set<bool>(val);
                        setState(() {});
                      },
                    ),
                    if (!experimentalEnabled)
                      _buildExperimentalGateMessage(
                        'Core and Visual settings are disabled. Enable Experimental to use them.',
                      ),
                    if (experimentalEnabled) ...[
                      AnymeXTile(
                        icon: Icons.sync_rounded,
                        title: 'Video Sync',
                        subtitle: (mpvCore['videoSync'] as String?) ?? 'audio',
                        onTap: () => _showMpvCoreSelectionDialog(
                          title: 'Video Sync',
                          items: const [
                            'audio',
                            'display-resample',
                            'display-vdrop',
                            'display-adrop',
                          ],
                          selected:
                              (mpvCore['videoSync'] as String?) ?? 'audio',
                          getTitle: (item) => item,
                          key: 'videoSync',
                        ),
                      ),
                      AnymeXTile.toggle(
                        icon: Icons.movie_filter_rounded,
                        title: 'Frame Interpolation',
                        subtitle: 'Smoother motion, can increase GPU usage',
                        value: (mpvCore['interpolation'] as bool?) ?? false,
                        onChanged: (val) {
                          PlayerCoreVisualSettings.setMpvCoreSetting(
                              'interpolation', val);
                          setState(() {});
                        },
                      ),
                      AnymeXTile.toggle(
                        icon: Icons.graphic_eq_rounded,
                        title: 'Audio Pitch Correction',
                        subtitle: 'Keep voice pitch stable at higher speeds',
                        value:
                            (mpvCore['audioPitchCorrection'] as bool?) ?? true,
                        onChanged: (val) {
                          PlayerCoreVisualSettings.setMpvCoreSetting(
                              'audioPitchCorrection', val);
                          setState(() {});
                        },
                      ),
                      AnymeXTile.slider(
                        icon: Icons.timer_outlined,
                        title: 'Cache Minutes',
                        subtitle: 'Read-ahead duration in Minutes',
                        value:
                            ((mpvCore['cacheMinutes'] as num?) ?? 5).toDouble(),
                        min: 0,
                        max: 60,
                        divisions: 60,
                        onChanged: (value) {
                          PlayerCoreVisualSettings.setMpvCoreSetting(
                              'cacheMinutes', value.round());
                          setState(() {});
                        },
                      ),
                      AnymeXTile.slider(
                        icon: Icons.downloading_rounded,
                        title: 'Demuxer Readahead',
                        subtitle: 'Readahead seconds',
                        value:
                            ((mpvCore['demuxerReadaheadSeconds'] as num?) ?? 30)
                                .toDouble(),
                        min: 0,
                        max: 120,
                        divisions: 24,
                        onChanged: (value) {
                          PlayerCoreVisualSettings.setMpvCoreSetting(
                              'demuxerReadaheadSeconds', value.round());
                          setState(() {});
                        },
                      ),
                      AnymeXTile.slider(
                        icon: Icons.storage_rounded,
                        title: 'Demuxer Max Buffer',
                        subtitle: 'Maximum demuxer buffer (MB)',
                        value: ((mpvCore['demuxerMaxBytesMb'] as num?) ?? 128)
                            .toDouble(),
                        min: 16,
                        max: 512,
                        divisions: 62,
                        onChanged: (value) {
                          PlayerCoreVisualSettings.setMpvCoreSetting(
                              'demuxerMaxBytesMb', value.round());
                          setState(() {});
                        },
                      ),
                      AnymeXTile.slider(
                        icon: Icons.developer_board_rounded,
                        title: 'Decoder Threads',
                        subtitle: '0 means automatic thread count',
                        value: ((mpvCore['vdLavcThreads'] as num?) ?? 4)
                            .toDouble(),
                        min: 0,
                        max: 16,
                        divisions: 16,
                        onChanged: (value) {
                          PlayerCoreVisualSettings.setMpvCoreSetting(
                              'vdLavcThreads', value.round());
                          setState(() {});
                        },
                      ),
                      AnymeXTile(
                        icon: Icons.aspect_ratio_rounded,
                        title: 'Scaling Algorithm',
                        subtitle: (mpvVisual['scale'] as String?) ?? 'spline36',
                        onTap: () => _showMpvVisualSelectionDialog(
                          title: 'Scaling Algorithm',
                          items: const [
                            'spline36',
                            'ewa_lanczossharp',
                            'bilinear',
                            'bicubic',
                            'oversample',
                          ],
                          selected:
                              (mpvVisual['scale'] as String?) ?? 'spline36',
                          getTitle: (item) => item,
                          key: 'scale',
                        ),
                      ),
                      AnymeXTile(
                        icon: Icons.palette_outlined,
                        title: 'Chroma Scaler',
                        subtitle:
                            (mpvVisual['cscale'] as String?) ?? 'spline36',
                        onTap: () => _showMpvVisualSelectionDialog(
                          title: 'Chroma Scaler',
                          items: const [
                            'spline36',
                            'ewa_lanczossharp',
                            'bilinear',
                            'mitchell',
                          ],
                          selected:
                              (mpvVisual['cscale'] as String?) ?? 'spline36',
                          getTitle: (item) => item,
                          key: 'cscale',
                        ),
                      ),
                      AnymeXTile(
                        icon: Icons.photo_size_select_small_rounded,
                        title: 'Downscaling Algorithm',
                        subtitle:
                            (mpvVisual['dscale'] as String?) ?? 'mitchell',
                        onTap: () => _showMpvVisualSelectionDialog(
                          title: 'Downscaling Algorithm',
                          items: const [
                            'mitchell',
                            'bicubic',
                            'bilinear',
                            'hermite',
                          ],
                          selected:
                              (mpvVisual['dscale'] as String?) ?? 'mitchell',
                          getTitle: (item) => item,
                          key: 'dscale',
                        ),
                      ),
                      AnymeXTile.toggle(
                        icon: Icons.blur_linear_rounded,
                        title: 'Debanding',
                        subtitle: 'Reduce color banding artifacts',
                        value: (mpvVisual['deband'] as bool?) ?? true,
                        onChanged: (val) {
                          PlayerCoreVisualSettings.setMpvVisualSetting(
                              'deband', val);
                          setState(() {});
                        },
                      ),
                      AnymeXTile(
                        icon: Icons.hdr_auto_rounded,
                        title: 'Tone Mapping',
                        subtitle:
                            (mpvVisual['toneMapping'] as String?) ?? 'auto',
                        onTap: () => _showMpvVisualSelectionDialog(
                          title: 'Tone Mapping',
                          items: const [
                            'auto',
                            'clip',
                            'mobius',
                            'reinhard',
                            'hable',
                            'bt.2390',
                            'spline',
                          ],
                          selected:
                              (mpvVisual['toneMapping'] as String?) ?? 'auto',
                          getTitle: (item) => item,
                          key: 'toneMapping',
                        ),
                      ),
                      AnymeXTile(
                        icon: Icons.grain_rounded,
                        title: 'Dither Depth',
                        subtitle:
                            (mpvVisual['ditherDepth'] as String?) ?? 'auto',
                        onTap: () => _showMpvVisualSelectionDialog(
                          title: 'Dither Depth',
                          items: const ['auto', '8', '10', 'no'],
                          selected:
                              (mpvVisual['ditherDepth'] as String?) ?? 'auto',
                          getTitle: (item) => item,
                          key: 'ditherDepth',
                        ),
                      ),
                    ],
                  ],
                ),
                AnymeXSectionBuilder(
                  title: 'MPV Configuration',
                  children: [
                    AnymeXTile.toggle(
                      icon: Icons.description_rounded,
                      title: 'Use mpv.conf',
                      subtitle:
                          'Apply options from your mpv.conf when playback starts',
                      value: _useMpvConf,
                      onChanged: (val) {
                        _useMpvConf = val;
                        PlayerUiKeys.useMpvConf.set<bool>(val);
                        setState(() {});
                      },
                    ),
                    AnymeXTile(
                      icon: Icons.edit_note_rounded,
                      title: 'Edit mpv.conf',
                      subtitle:
                          'Edit custom mpv flags, properties, and configuration file',
                      onTap: () => _showMpvConfEditorSheet(context),
                    ),
                  ],
                ),
              ],
            ),
          );

    if (widget.isEmbedded) {
      return content;
    }

    return AnymeXScaffold(
      showHeader: !widget.isModal,
      headerTitle: 'Engine & Advanced',
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16.0,
            widget.isModal ? 16.0 : AnymeXHeaderScope.of(ctx),
            16.0,
            30.0,
          ),
          child: content,
        ),
      ),
    );
  }
}
