import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/isar_models/video.dart';
import 'package:anymex/screens/downloads/controller/download_controller.dart';
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class ActiveDownloads extends StatelessWidget {
  const ActiveDownloads({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DownloadController>();
    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            const NestedHeader(title: 'Active Downloads'),
            Expanded(
              child: Obx(() {
                final tasks = controller.activeTasks;
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(HugeIcons.strokeRoundedDownload04,
                            size: 64,
                            color: context.colors.onSurface.opaque(0.15)),
                        const SizedBox(height: 16),
                        AnymexText(
                            text: 'No active downloads',
                            size: 16,
                            variant: TextVariant.semiBold,
                            color: context.colors.onSurface.opaque(0.4)),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: AnymexText(
                              text:
                                  'Start a new download from the "New Download" tab',
                              size: 13,
                              color: context.colors.onSurface.opaque(0.3),
                              textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _ActiveTaskCard(
                      task: task,
                      onCancel: () => controller.cancelDownload(task.taskId),
                      onRemove: () => controller.removeTask(task.taskId),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTaskCard extends StatelessWidget {
  final ActiveDownloadTask task;
  final VoidCallback onCancel;
  final VoidCallback onRemove;

  const _ActiveTaskCard(
      {required this.task, required this.onCancel, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;

    Color statusColor = theme.primary;
    String statusLabel = 'Queued';
    IconData statusIcon = Icons.schedule_rounded;

    switch (task.status) {
      case DownloadStatus.downloading:
        statusLabel = '${(task.progress * 100).toStringAsFixed(0)}%';
        statusIcon = Icons.downloading_rounded;
        break;
      case DownloadStatus.paused:
        statusColor = Colors.orange.shade400;
        statusLabel = 'Paused · ${(task.progress * 100).toStringAsFixed(0)}%';
        statusIcon = Icons.pause_circle_rounded;
        break;
      case DownloadStatus.completed:
        statusColor = Colors.green.shade400;
        statusLabel = 'Completed';
        statusIcon = Icons.check_circle_rounded;
        break;
      case DownloadStatus.failed:
        statusColor = theme.error;
        statusLabel = 'Failed';
        statusIcon = Icons.error_outline_rounded;
        break;
      case DownloadStatus.cancelled:
        statusColor = theme.onSurface.opaque(0.4);
        statusLabel = 'Cancelled';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        break;
    }

    final isActive = task.status == DownloadStatus.downloading ||
        task.status == DownloadStatus.queued ||
        task.status == DownloadStatus.paused;

    final controller = Get.find<DownloadController>();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surfaceContainer.opaque(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.outline.opaque(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymexText(
                        text: task.mediaTitle,
                        variant: TextVariant.semiBold,
                        size: 14,
                        maxLines: 1),
                    const SizedBox(height: 2),
                    AnymexText(
                      text: task.episodeDisplayId,
                      size: 12,
                      color: theme.onSurface.opaque(0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (isActive) ...[
                if (task.status == DownloadStatus.downloading ||
                    task.status == DownloadStatus.queued)
                  GestureDetector(
                    onTap: () => controller.pauseDownload(task.taskId),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: theme.primaryContainer.opaque(0.3),
                          shape: BoxShape.circle),
                      child: Icon(Icons.pause_rounded,
                          size: 16, color: theme.primary),
                    ),
                  )
                else if (task.status == DownloadStatus.paused)
                  GestureDetector(
                    onTap: () => controller.resumeDownload(task.taskId),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: theme.primaryContainer.opaque(0.3),
                          shape: BoxShape.circle),
                      child: Icon(Icons.play_arrow_rounded,
                          size: 16, color: theme.primary),
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: theme.errorContainer.opaque(0.3),
                        shape: BoxShape.circle),
                    child:
                        Icon(Icons.close_rounded, size: 16, color: theme.error),
                  ),
                ),
              ] else
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: theme.surfaceContainerHighest.opaque(0.4),
                        shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: theme.onSurface.opaque(0.5)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (task.status == DownloadStatus.downloading ||
              task.status == DownloadStatus.paused) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: task.progress,
                backgroundColor: theme.surfaceContainerHighest.opaque(0.4),
                valueColor: AlwaysStoppedAnimation(
                    task.status == DownloadStatus.paused
                        ? theme.primary.opaque(0.5)
                        : theme.primary),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 8),
          ] else if (task.status == DownloadStatus.queued) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: theme.surfaceContainerHighest.opaque(0.4),
                valueColor: AlwaysStoppedAnimation(theme.primary.opaque(0.4)),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 6),
              AnymexText(
                  text: statusLabel,
                  size: 12,
                  color: statusColor,
                  variant: TextVariant.semiBold),
              const Spacer(),
              if (task.status == DownloadStatus.failed &&
                  (task.errorMessage?.contains('matching quality') ?? false))
                GestureDetector(
                  onTap: () => _showManualServerSelection(context, task),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AnymexText(
                        text: 'Select Server',
                        size: 11,
                        color: theme.onPrimary,
                        variant: TextVariant.bold),
                  ),
                )
              else if (task.videoQuality.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.primaryContainer.opaque(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnymexText(
                      text: task.videoQuality, size: 11, color: theme.primary),
                ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.surfaceContainerHighest.opaque(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnymexText(
                    text: task.extensionName,
                    size: 11,
                    color: theme.onSurface.opaque(0.5)),
              ),
            ],
          ),
          if (task.errorMessage != null &&
              task.status == DownloadStatus.failed) ...[
            const SizedBox(height: 6),
            AnymexText(
                text: task.errorMessage!,
                size: 11,
                color: theme.error.opaque(0.7),
                maxLines: 2),
          ],
        ],
      ),
    );
  }

  void _showManualServerSelection(
      BuildContext context, ActiveDownloadTask task) async {
    final theme = context.colors;
    final sourceController = Get.find<SourceController>();
    final sources = [
      ...sourceController.installedExtensions,
      ...sourceController.installedMangaExtensions
    ];
    final source =
        sources.firstWhereOrNull((s) => s.name == task.extensionName);

    if (source == null) {
      snackBar('Source "${task.extensionName}" not found.');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<List<Video>>(
          future:
              downloadController.fetchServersForEpisode(source, task.episode),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: AnymexText(
                      text: 'No servers found for this episode.',
                      color: theme.onSurface.opaque(0.6)),
                ),
              );
            }

            final servers = snapshot.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: AnymexText(
                      text: 'Select Server',
                      variant: TextVariant.bold,
                      size: 18),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: servers.length,
                    itemBuilder: (context, index) {
                      final server = servers[index];
                      return ListTile(
                        leading: Icon(Icons.dns_rounded, color: theme.primary),
                        title: AnymexText(
                            text: server.quality ?? 'Unknown Quality',
                            variant: TextVariant.semiBold),
                        subtitle: AnymexText(
                            text: server.originalUrl ?? 'Unknown URL',
                            size: 12,
                            maxLines: 1),
                        onTap: () {
                          downloadController.manualSelectServerForTask(
                              task, server);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }
}
