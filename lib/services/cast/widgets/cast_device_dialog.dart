import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/anymex_slider_m3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../cast_service.dart';

class CastDeviceDialog extends StatefulWidget {
  final PlayerController controller;

  const CastDeviceDialog({super.key, required this.controller});

  static Future<void> show(BuildContext context, PlayerController controller) async {
    await AnymeXSheet.custom(
      CastDeviceDialog(controller: controller),
      context,
      showDragHandle: true,
    );
  }

  @override
  State<CastDeviceDialog> createState() => _CastDeviceDialogState();
}

class _CastDeviceDialogState extends State<CastDeviceDialog> {
  final castService = CastService.instance;
  final RxString _connectingDeviceId = ''.obs;

  @override
  void initState() {
    super.initState();
    castService.startDiscovery();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: 16),
        _buildActiveCastingCard(theme),
        _buildDeviceList(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.cast_rounded, color: theme.colorScheme.primary, size: 22),
        const SizedBox(width: 10),
        const AnymeXText(
          'Cast to Device',
          variant: TextVariant.bold,
          size: 18,
        ),
        const Spacer(),
        Obx(() => castService.isSearching.value
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                onPressed: () => castService.startDiscovery(),
                icon: const Icon(Icons.refresh_rounded),
              )),
      ],
    );
  }

  Widget _buildActiveCastingCard(ThemeData theme) {
    return Obx(() {
      if (!castService.isCasting.value || castService.connectedDevice.value == null) {
        return const SizedBox.shrink();
      }

      final active = castService.connectedDevice.value!;
      final position = castService.castPosition.value;
      final duration = castService.castDuration.value;
      final maxDurationMs = duration.inMilliseconds > 0
          ? duration.inMilliseconds.toDouble()
          : (widget.controller.episodeDuration.value.inMilliseconds > 0
              ? widget.controller.episodeDuration.value.inMilliseconds.toDouble()
              : 1.0);

      final currentPosMs = position.inMilliseconds.toDouble().clamp(0.0, maxDurationMs);

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.opaque(0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.opaque(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _getProtocolIcon(active.protocol),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXText(
                        active.name,
                        variant: TextVariant.bold,
                        size: 14,
                      ),
                      AnymeXText(
                        'Casting via ${_getProtocolLabel(active.protocol)} (${active.host})',
                        size: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await castService.stopCasting();
                  },
                  child: const AnymeXText('Disconnect'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnymeXSliderM3(
              theme: AnymeXSliderM3Theme(
                trackHeight: 15,
                thumbHeight: 20,
                activeColor: theme.colorScheme.primary,
                inactiveColor: theme.colorScheme.surfaceContainerHighest,
              ),
              label: _formatDuration(position),
              divisions: null,
              focusNode: FocusNode(canRequestFocus: false, skipTraversal: true),
              min: 0,
              value: currentPosMs,
              max: maxDurationMs,
              onChanged: (val) {
                castService.seek(Duration(milliseconds: val.round()));
              },
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnymeXText(
                  _formatDuration(position),
                  size: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      iconSize: 24,
                      onPressed: () => castService.seekRelative(-10),
                      icon: const Icon(Icons.replay_10_rounded),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      iconSize: 36,
                      onPressed: () {
                        if (castService.isPlaying.value) {
                          castService.pause();
                        } else {
                          castService.play();
                        }
                      },
                      icon: Icon(
                        castService.isPlaying.value
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      iconSize: 24,
                      onPressed: () => castService.seekRelative(10),
                      icon: const Icon(Icons.forward_10_rounded),
                    ),
                  ],
                ),
                AnymeXText(
                  _formatDuration(duration.inMilliseconds > 0 ? duration : widget.controller.episodeDuration.value),
                  size: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDeviceList(ThemeData theme) {
    return Obx(() {
      final devices = castService.discoveredDevices;
      if (devices.isEmpty && castService.isSearching.value) {
        return const SizedBox(
          height: 120,
          child: Center(child: AnymeXProgressIndicator()),
        );
      }

      if (devices.isEmpty) {
        return const SizedBox(
          height: 120,
          child: Center(
            child: AnymeXText(
              'No casting devices found on local network.',
              size: 14,
            ),
          ),
        );
      }

      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.opaque(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getProtocolIcon(device.protocol),
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              title: AnymeXText(
                device.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(top: 4, right: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.opaque(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: AnymeXText(
                      _getProtocolLabel(device.protocol),
                      size: 10,
                      variant: TextVariant.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: AnymeXText(
                      device.host,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              trailing: Obx(() {
                if (_connectingDeviceId.value == device.id) {
                  return const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                if (castService.connectedDevice.value?.id == device.id && castService.isCasting.value) {
                  return Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary);
                }
                return const Icon(Icons.chevron_right_rounded);
              }),
              onTap: () => _handleDeviceTap(device),
            );
          },
        ),
      );
    });
  }

  Future<void> _handleDeviceTap(CastDevice device) async {
    final videoUrl = widget.controller.selectedVideo.value?.url ?? widget.controller.offlineVideoPath;
    final headers = widget.controller.selectedVideo.value?.headers;
    if (videoUrl == null || videoUrl.isEmpty) return;

    String? subUrl;
    String? subLabel;

    final subs = widget.controller.selectedVideo.value?.subtitles;
    if (subs != null && subs.isNotEmpty) {
      final eng = subs.firstWhereOrNull((s) => (s.label ?? '').toLowerCase().contains('eng')) ?? subs.first;
      subUrl = eng.file;
      subLabel = eng.label ?? 'English';
    } else if (widget.controller.localSubtitles.isNotEmpty) {
      final firstLocal = widget.controller.localSubtitles.first;
      subUrl = firstLocal.file;
      subLabel = firstLocal.label ?? 'Subtitles';
    }

    final title = widget.controller.anilistData.title.isNotEmpty
        ? widget.controller.anilistData.title
        : (widget.controller.currentEpisode.value.title ?? 'AnymeX');
    final startPos = widget.controller.currentPosition.value;

    _connectingDeviceId.value = device.id;
    try {
      final success = await castService.castMedia(
        videoUrl: videoUrl,
        headers: headers,
        subtitleUrl: subUrl,
        subtitleLabel: subLabel,
        title: title,
        startPosition: startPos,
        device: device,
      );
      if (success) {
        widget.controller.pause();
      }
    } finally {
      _connectingDeviceId.value = '';
    }
  }

  IconData _getProtocolIcon(CastProtocol protocol) {
    switch (protocol) {
      case CastProtocol.chromecast:
        return Icons.cast_rounded;
      case CastProtocol.roku:
        return Icons.live_tv_rounded;
      case CastProtocol.dlna:
        return Icons.tv_rounded;
    }
  }

  String _getProtocolLabel(CastProtocol protocol) {
    switch (protocol) {
      case CastProtocol.chromecast:
        return 'CHROMECAST';
      case CastProtocol.roku:
        return 'ROKU';
      case CastProtocol.dlna:
        return 'DLNA / SMART TV';
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

