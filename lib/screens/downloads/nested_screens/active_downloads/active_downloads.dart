import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/video.dart';
import 'package:anymex/screens/downloads/controller/download_controller.dart';
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:anymex_extension_runtime_bridge/Models/DEpisode.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart' hide Video;
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
                final animeTasks = controller.activeTasks
                    .map((e) => _UnifiedTask.fromAnime(e))
                    .toList();
                final mangaTasks = controller.activeMangaTasks
                    .map((e) => _UnifiedTask.fromManga(e))
                    .toList();
                final tasks = [...animeTasks, ...mangaTasks];

                if (tasks.isEmpty) {
                  return _buildEmptyState(context);
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildActiveTaskCard(
                      context: context,
                      task: task,
                      onCancel: () => task.isManga
                          ? controller.cancelMangaDownload(task.taskId)
                          : controller.cancelDownload(task.taskId),
                      onRemove: () => task.isManga
                          ? controller.removeMangaTask(task.taskId)
                          : controller.removeTask(task.taskId),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(HugeIcons.strokeRoundedDownload04,
              size: 64, color: context.colors.onSurface.opaque(0.15)),
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
                text: 'Start a new download from the "New Download" tab',
                size: 13,
                color: context.colors.onSurface.opaque(0.3),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTaskCard({
    required BuildContext context,
    required _UnifiedTask task,
    required VoidCallback onCancel,
    required VoidCallback onRemove,
  }) {
    final theme = context.colors;

    Color statusColor = theme.primary;
    String statusLabel = 'Queued';
    IconData statusIcon = Icons.schedule_rounded;

    if (task.status == DownloadStatus.fetchingServer) {
      statusColor = theme.primary;
      statusLabel = 'Fetching server...';
      statusIcon = Icons.cloud_sync_rounded;
    } else if (task.status == DownloadStatus.awaitingServerSelection) {
      statusColor = theme.tertiary;
      statusLabel = 'Needs server selection';
      statusIcon = Icons.dns_rounded;
    } else if (task.isDownloading) {
      statusLabel = task.isManga ? 'Downloading' : '${(task.progress * 100).toStringAsFixed(0)}%';
      statusIcon = Icons.downloading_rounded;
    } else if (task.isPaused) {
      statusColor = theme.tertiary;
      statusLabel = 'Paused · ${(task.progress * 100).toStringAsFixed(0)}%';
      statusIcon = Icons.pause_circle_rounded;
    } else if (task.isCompleted) {
      statusColor = Colors.green.shade400;
      statusLabel = 'Completed';
      statusIcon = Icons.check_circle_rounded;
    } else if (task.isFailed) {
      statusColor = theme.error;
      statusLabel = 'Failed';
      statusIcon = Icons.error_outline_rounded;
    } else if (task.isCancelled) {
      statusColor = theme.onSurface.opaque(0.4);
      statusLabel = 'Cancelled';
      statusIcon = Icons.cancel_outlined;
    }

    final isActive = task.isDownloading || task.isQueued || task.isPaused ||
        task.status == DownloadStatus.fetchingServer;

    final controller = Get.find<DownloadController>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surfaceContainer.opaque(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.outline.opaque(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymexText(
                        text: task.mediaTitle,
                        variant: TextVariant.semiBold,
                        size: 15,
                        maxLines: 2),
                    const SizedBox(height: 4),
                    AnymexText(
                      text: task.displayId,
                      size: 13,
                      maxLines: 1,
                      color: theme.onSurface.opaque(0.55),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (isActive) ...[
                if (task.isDownloading || task.isQueued)

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
                else if (task.isPaused)
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
          if (task.status == DownloadStatus.fetchingServer) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: theme.surfaceContainerHighest.opaque(0.4),
                valueColor: AlwaysStoppedAnimation(theme.primary),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 8),
          ] else if (task.isDownloading || task.isPaused) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: task.progress,
                backgroundColor: theme.surfaceContainerHighest.opaque(0.4),
                valueColor: AlwaysStoppedAnimation(
                    task.isPaused
                        ? theme.primary.opaque(0.5)
                        : theme.primary),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 8),
          ] else if (task.isQueued) ...[
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
              Expanded(
                child: AnymexText(
                    text: statusLabel,
                    size: 12,
                    color: statusColor,
                    variant: TextVariant.semiBold,
                    maxLines: 1),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!task.isManga &&
                  task.status == DownloadStatus.awaitingServerSelection)
                GestureDetector(
                  onTap: () => _showManualServerSelection(
                      context, task.originalTask!,
                      preloadedServers: task.originalTask!.availableServers),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AnymexText(
                        text: 'Select Server',
                        size: 11,
                        color: theme.onTertiaryContainer,
                        variant: TextVariant.bold),
                  ),
                )
              else if (task.isFailed && !task.isManga &&
                  (task.errorMessage?.contains('matching quality') ?? false))
                GestureDetector(
                  onTap: () =>
                      _showManualServerSelection(context, task.originalTask!),
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
              else if (task.qualityOrStatus.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.primaryContainer.opaque(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnymexText(
                      text: task.qualityOrStatus,
                      size: 11,
                      color: theme.primary),
                ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
          if (task.errorMessage != null && task.isFailed) ...[

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
      BuildContext context, ActiveDownloadTask task,
      {List<Video>? preloadedServers}) {
    if (preloadedServers != null && preloadedServers.isNotEmpty) {
      _showServerSheet(context, task, preloadedServers);
      return;
    }

    final sourceController = Get.find<SourceController>();
    final source = [
      ...sourceController.installedExtensions,
      ...sourceController.installedMangaExtensions,
    ].firstWhereOrNull((s) => s.name == task.extensionName);

    if (source == null) {
      snackBar('Source "${task.extensionName}" not found.');
      return;
    }

    final deEpisode = DEpisode(
      episodeNumber: task.episode.number,
      url: task.episode.link,
      sortMap: task.episode.sortMap.isEmpty ? null : task.episode.sortMap,
    );
    final videoStream = source.methods.getVideoListStream(deEpisode);

    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        if (videoStream != null) {
          return _ServerSheetStreamBody(
            stream: videoStream,
            task: task,
            onServerSelected: (server) {
              Get.find<DownloadController>()
                  .manualSelectServerForTask(task, server);
              Navigator.pop(context);
            },
          );
        } else {
          return FutureBuilder<List<Video>>(
            future: source.methods
                .getVideoList(deEpisode)
                .then((list) => list.map((v) => Video.fromVideo(v)).toList()),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SizedBox(
                  height: 240,
                  child: Center(
                    child: AnymexText(
                        text: 'No servers found.',
                        color: context.colors.onSurface.opaque(0.5)),
                  ),
                );
              }
              return _ServerListBody(
                servers: snapshot.data!,
                task: task,
                onServerSelected: (server) {
                  Get.find<DownloadController>()
                      .manualSelectServerForTask(task, server);
                  Navigator.pop(context);
                },
              );
            },
          );
        }
      },
    );
  }

  void _showServerSheet(
      BuildContext context, ActiveDownloadTask task, List<Video> servers) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ServerListBody(
        servers: servers,
        task: task,
        onServerSelected: (server) {
          Get.find<DownloadController>().manualSelectServerForTask(task, server);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _UnifiedTask {
  final ActiveDownloadTask? originalTask;
  final String taskId;
  final String mediaTitle;
  final String extensionName;
  final String displayId;
  final double progress;
  final String? errorMessage;
  final bool isManga;
  final String qualityOrStatus;
  
  final bool isDownloading;
  final bool isPaused;
  final bool isCompleted;
  final bool isFailed;
  final bool isCancelled;
  final bool isQueued;
  final DownloadStatus? status;
  
  _UnifiedTask.fromAnime(ActiveDownloadTask task) :
    originalTask = task,
    taskId = task.taskId,
    mediaTitle = task.mediaTitle,
    extensionName = task.extensionName,
    displayId = task.episodeDisplayId,
    progress = task.progress,
    errorMessage = task.errorMessage,
    isManga = false,
    qualityOrStatus = task.videoQuality,
    status = task.status,
    isDownloading = task.status == DownloadStatus.downloading,
    isPaused = task.status == DownloadStatus.paused,
    isCompleted = task.status == DownloadStatus.completed,
    isFailed = task.status == DownloadStatus.failed,
    isCancelled = task.status == DownloadStatus.cancelled,
    isQueued = task.status == DownloadStatus.queued;
    
  _UnifiedTask.fromManga(ActiveMangaDownloadTask task) :
    originalTask = null,
    taskId = task.taskId,
    mediaTitle = task.mediaTitle,
    extensionName = task.extensionName,
    displayId = task.chapterDisplay,
    progress = task.progress,
    errorMessage = task.errorMessage,
    isManga = true,
    qualityOrStatus = task.status == MangaDownloadStatus.fetchingPages ? 'Pages' : 'Images',
    status = null,
    isDownloading = task.status == MangaDownloadStatus.downloading || task.status == MangaDownloadStatus.fetchingPages,
    isPaused = task.status == MangaDownloadStatus.paused,
    isCompleted = task.status == MangaDownloadStatus.completed,
    isFailed = task.status == MangaDownloadStatus.failed,
    isCancelled = task.status == MangaDownloadStatus.cancelled,
    isQueued = task.status == MangaDownloadStatus.queued;
}

class _ServerListBody extends StatelessWidget {
  final List<Video> servers;
  final ActiveDownloadTask task;
  final void Function(Video) onServerSelected;

  const _ServerListBody({
    required this.servers,
    required this.task,
    required this.onServerSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.onSurface.opaque(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: AnymexText(
                text: 'Select Server', variant: TextVariant.bold, size: 18),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: servers.length,
              itemBuilder: (context, index) {
                final server = servers[index];
                return ListTile(
                  leading: Icon(Icons.dns_rounded, color: theme.primary),
                  title: AnymexText(
                      text: server.quality ?? 'Unknown Quality',
                      variant: TextVariant.semiBold),
                  subtitle: AnymexText(
                      text: server.originalUrl ?? server.url ?? '',
                      size: 12,
                      maxLines: 1),
                  onTap: () => onServerSelected(server),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ServerSheetStreamBody extends StatefulWidget {
  final Stream<dynamic> stream;
  final ActiveDownloadTask task;
  final void Function(Video) onServerSelected;

  const _ServerSheetStreamBody({
    required this.stream,
    required this.task,
    required this.onServerSelected,
  });

  @override
  State<_ServerSheetStreamBody> createState() => _ServerSheetStreamBodyState();
}

class _ServerSheetStreamBodyState extends State<_ServerSheetStreamBody> {
  final List<Video> _servers = [];
  bool _done = false;

  @override
  void initState() {
    super.initState();
    widget.stream.listen(
      (v) {
        final video = Video.fromVideo(v);
        if (mounted) setState(() => _servers.add(video));
      },
      onDone: () {
        if (mounted) setState(() => _done = true);
      },
      onError: (_) {
        if (mounted) setState(() => _done = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.onSurface.opaque(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AnymexText(
                    text: 'Select Server',
                    variant: TextVariant.bold,
                    size: 18),
                if (!_done) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: theme.primary),
                  ),
                ],
              ],
            ),
          ),
          if (_servers.isEmpty && !_done)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else if (_servers.isEmpty && _done)
            Expanded(
              child: Center(
                child: AnymexText(
                    text: 'No servers found.',
                    color: theme.onSurface.opaque(0.5)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: _servers.length,
                itemBuilder: (context, index) {
                  final server = _servers[index];
                  return ListTile(
                    leading: Icon(Icons.dns_rounded, color: theme.primary),
                    title: AnymexText(
                        text: server.quality ?? 'Unknown Quality',
                        variant: TextVariant.semiBold),
                    subtitle: AnymexText(
                        text: server.originalUrl ?? server.url ?? '',
                        size: 12,
                        maxLines: 1),
                    onTap: () => widget.onServerSelected(server),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

