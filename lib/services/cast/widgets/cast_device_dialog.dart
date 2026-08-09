import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../cast_service.dart';

class CastDeviceDialog extends StatefulWidget {
  final PlayerController controller;

  const CastDeviceDialog({super.key, required this.controller});

  static Future<void> show(BuildContext context, PlayerController controller) async {
    await AnymexSheet.custom(
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
        Row(
          children: [
            Icon(Icons.cast_rounded, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 10),
            const AnymexText(
              text: 'Cast to Device',
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
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (castService.isCasting.value && castService.connectedDevice.value != null) {
            final active = castService.connectedDevice.value!;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.opaque(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.opaque(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.cast_connected_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymexText(
                          text: active.name,
                          variant: TextVariant.bold,
                          size: 14,
                        ),
                        AnymexText(
                          text: 'Connected (${active.host})',
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await castService.stopCasting();
                      Get.back();
                    },
                    child: const Text('Disconnect'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        Obx(() {
          final devices = castService.discoveredDevices;
          if (devices.isEmpty && castService.isSearching.value) {
            return const SizedBox(
              height: 120,
              child: Center(child: AnymexProgressIndicator()),
            );
          }

          if (devices.isEmpty) {
            return const SizedBox(
              height: 120,
              child: Center(
                child: AnymexText(
                  text: 'No casting devices found on local network.',
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
                  leading: Icon(
                    device.protocol == CastProtocol.chromecast
                        ? Icons.cast_connected_rounded
                        : Icons.tv_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    device.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${device.protocol.name.toUpperCase()} • ${device.host}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
                  onTap: () async {
                    final videoUrl = widget.controller.selectedVideo.value?.url ?? widget.controller.offlineVideoPath;
                    final headers = widget.controller.selectedVideo.value?.headers;
                    if (videoUrl == null || videoUrl.isEmpty) return;
                    _connectingDeviceId.value = device.id;
                    await castService.castMedia(
                      videoUrl: videoUrl,
                      headers: headers,
                      device: device,
                    );
                    _connectingDeviceId.value = '';
                  },
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
