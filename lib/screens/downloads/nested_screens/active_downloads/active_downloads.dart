import 'dart:async';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/database/isar_models/video.dart';
import 'package:anymex/screens/downloads/controller/download_controller.dart';
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    hide Video;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class ActiveDownloads extends StatefulWidget {
  const ActiveDownloads({super.key});

  @override
  State<ActiveDownloads> createState() => _ActiveDownloadsState();
}

class _ActiveDownloadsState extends State<ActiveDownloads> {
  final Set<String> _collapsedGroupKeys = {};

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DownloadController>();
    final theme = context.colors;

    return AnymeXScaffold(
      body: Obx(() {
        final animeTasks = controller.activeTasks
            .map((e) => _UnifiedTask.fromAnime(e))
            .toList();
        final mangaTasks = controller.activeMangaTasks
            .map((e) => _UnifiedTask.fromManga(e))
            .toList();
        final tasks = [...animeTasks, ...mangaTasks];

        final Map<String, _MediaDownloadGroup> groupsMap = {};
        for (final task in tasks) {
          final groupKey =
              '${task.isManga ? 'manga' : 'anime'}_${task.mediaTitle}_${task.extensionName}';
          if (!groupsMap.containsKey(groupKey)) {
            final poster = task.media?.poster ??
                task.media?.cover ??
                controller.downloadedMedia
                    .firstWhereOrNull((s) =>
                        s.title.toLowerCase() ==
                        task.mediaTitle.toLowerCase())
                    ?.poster;

            groupsMap[groupKey] = _MediaDownloadGroup(
              key: groupKey,
              mediaTitle: task.mediaTitle,
              isManga: task.isManga,
              extensionName: task.extensionName,
              poster: poster,
              tasks: [task],
            );
          } else {
            groupsMap[groupKey]!.tasks.add(task);
          }
        }
        final groups = groupsMap.values.toList();

        double totalActiveSpeed = 0.0;
        for (final t in tasks) {
          if (t.isDownloading) {
            totalActiveSpeed += controller.getTaskSpeed(t.taskId);
          }
        }

        Widget? headerAction;
        if (totalActiveSpeed > 0) {
          headerAction = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: theme.primary.opaque(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primary.opaque(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(HugeIcons.strokeRoundedFlash,
                    size: 13, color: theme.primary),
                const SizedBox(width: 5),
                AnymeXText(
                  DownloadController.formatSpeed(totalActiveSpeed),
                  size: 11,
                  variant: TextVariant.bold,
                  color: theme.primary,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            NestedHeader(
              title: 'Active Downloads',
              action: headerAction,
            ),
            Expanded(
              child: groups.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        final isExpanded =
                            !_collapsedGroupKeys.contains(group.key);
                        return _buildMediaExpandableCard(
                          context: context,
                          group: group,
                          isExpanded: isExpanded,
                          controller: controller,
                          onToggleExpand: () {
                            setState(() {
                              if (_collapsedGroupKeys.contains(group.key)) {
                                _collapsedGroupKeys.remove(group.key);
                              } else {
                                _collapsedGroupKeys.add(group.key);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      }),
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
          AnymeXText('No active downloads',
              size: 16,
              variant: TextVariant.semiBold,
              color: context.colors.onSurface.opaque(0.4)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AnymeXText('Start a new download from the "New Download" tab',
                size: 13,
                color: context.colors.onSurface.opaque(0.3),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaExpandableCard({
    required BuildContext context,
    required _MediaDownloadGroup group,
    required bool isExpanded,
    required VoidCallback onToggleExpand,
    required DownloadController controller,
  }) {
    final theme = context.colors;

    final activeDownloadingTasks =
        group.tasks.where((t) => t.isDownloading).toList();
    double groupAvgSpeed = 0.0;
    if (activeDownloadingTasks.isNotEmpty) {
      final sum = activeDownloadingTasks.fold<double>(
          0.0, (acc, t) => acc + controller.getTaskSpeed(t.taskId));
      groupAvgSpeed = sum / activeDownloadingTasks.length;
    }

    final hasPausedOnly = group.canResumeAny && !group.canPauseAny;
    final isGroupDownloading = activeDownloadingTasks.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.surfaceContainer.opaque(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGroupDownloading
              ? theme.primary.opaque(0.25)
              : theme.outline.opaque(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleExpand,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(20),
                bottom: Radius.circular(isExpanded ? 0 : 20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: group.poster != null &&
                                  group.poster!.trim().isNotEmpty
                              ? AnymeXImage(
                                  imageUrl: group.poster!,
                                  width: 50,
                                  height: 72,
                                  radius: 12,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 50,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: theme.primary.opaque(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    group.isManga
                                        ? HugeIcons.strokeRoundedBook02
                                        : HugeIcons.strokeRoundedPlayList,
                                    color: theme.primary,
                                    size: 24,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnymeXText(
                                group.mediaTitle,
                                variant: TextVariant.bold,
                                size: 15,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: group.isManga
                                          ? theme.secondaryContainer.opaque(0.35)
                                          : theme.primaryContainer.opaque(0.35),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: AnymeXText(
                                      group.isManga ? 'Manga' : 'Anime',
                                      size: 10.5,
                                      variant: TextVariant.bold,
                                      color: group.isManga
                                          ? theme.secondary
                                          : theme.primary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: theme.surfaceContainerHighest
                                          .opaque(0.4),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: AnymeXText(
                                      group.extensionName,
                                      size: 10.5,
                                      color: theme.onSurface.opaque(0.7),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: theme.surfaceContainerHighest
                                          .opaque(0.3),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: AnymeXText(
                                      '${group.tasks.length} ${group.isManga ? (group.tasks.length == 1 ? 'ch' : 'chs') : (group.tasks.length == 1 ? 'ep' : 'eps')}',
                                      size: 10.5,
                                      color: theme.onSurface.opaque(0.55),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isGroupDownloading
                                      ? theme.primary.opaque(0.12)
                                      : (hasPausedOnly
                                          ? theme.tertiary.opaque(0.12)
                                          : theme.surfaceContainerHighest
                                              .opaque(0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isGroupDownloading
                                          ? HugeIcons.strokeRoundedFlash
                                          : (hasPausedOnly
                                              ? Icons.pause_circle_rounded
                                              : (group.tasks
                                                      .every((t) => t.isQueued)
                                                  ? Icons.schedule_rounded
                                                  : (group.tasks.every(
                                                          (t) => t.isCompleted)
                                                      ? Icons
                                                          .check_circle_rounded
                                                      : Icons.sync_rounded))),
                                      size: 12,
                                      color: isGroupDownloading
                                          ? theme.primary
                                          : (hasPausedOnly
                                              ? theme.tertiary
                                              : theme.onSurface.opaque(0.6)),
                                    ),
                                    const SizedBox(width: 4),
                                    AnymeXText(
                                      isGroupDownloading
                                          ? '${DownloadController.formatSpeed(groupAvgSpeed)} avg'
                                          : (hasPausedOnly
                                              ? 'Paused'
                                              : (group.tasks
                                                      .every((t) => t.isQueued)
                                                  ? 'Queued'
                                                  : (group.tasks.every((t) =>
                                                          t.isCompleted)
                                                      ? 'Completed'
                                                      : (group.tasks.any((t) =>
                                                              t.status ==
                                                              DownloadStatus
                                                                  .fetchingServer)
                                                          ? 'Fetching Server'
                                                          : 'Active')))),
                                      size: 11,
                                      variant: TextVariant.bold,
                                      color: isGroupDownloading
                                          ? theme.primary
                                          : (hasPausedOnly
                                              ? theme.tertiary
                                              : theme.onSurface.opaque(0.7)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (group.canPauseAny)
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () =>
                                        _toggleGroupPause(group, controller),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.primaryContainer.opaque(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.pause_rounded,
                                          size: 16, color: theme.primary),
                                    ),
                                  )
                                else if (group.canResumeAny)
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () =>
                                        _toggleGroupPause(group, controller),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.primaryContainer.opaque(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.play_arrow_rounded,
                                          size: 16, color: theme.primary),
                                    ),
                                  ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () =>
                                      _cancelGroup(group, controller),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.errorContainer.opaque(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.close_rounded,
                                        size: 16, color: theme.error),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOutCubic,
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 24,
                                color: theme.onSurface.opaque(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: group.averageProgress > 0
                            ? group.averageProgress
                            : null,
                        backgroundColor:
                            theme.surfaceContainerHighest.opaque(0.4),
                        valueColor: AlwaysStoppedAnimation(
                          hasPausedOnly
                              ? theme.primary.opaque(0.4)
                              : theme.primary,
                        ),
                        minHeight: 4.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnymeXText(
                          '${(group.averageProgress * 100).toStringAsFixed(0)}% · ${group.completedCount}/${group.tasks.length} completed',
                          size: 11,
                          color: theme.onSurface.opaque(0.55),
                        ),
                        AnymeXText(
                          isExpanded
                              ? 'Hide items'
                              : 'Show items (${group.tasks.length})',
                          size: 11,
                          variant: TextVariant.semiBold,
                          color: theme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(color: theme.outline.opaque(0.08), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: group.tasks
                    .map((t) => _buildChildTaskCard(
                          context: context,
                          task: t,
                          controller: controller,
                          onCancel: () => _cancelTask(t, controller),
                          onRemove: () => _removeTask(t, controller),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChildTaskCard({
    required BuildContext context,
    required _UnifiedTask task,
    required DownloadController controller,
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
      statusLabel = task.isManga
          ? 'Downloading'
          : '${(task.progress * 100).toStringAsFixed(0)}%';
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

    final isActive = task.isDownloading ||
        task.isQueued ||
        task.isPaused ||
        task.status == DownloadStatus.fetchingServer;

    final taskSpeed = controller.getTaskSpeed(task.taskId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surfaceContainerHighest.opaque(0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.outline.opaque(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: AnymeXText(
                        task.displayId,
                        variant: TextVariant.semiBold,
                        size: 13.5,
                        maxLines: 1,
                      ),
                    ),
                    if (task.qualityOrStatus.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.primaryContainer.opaque(0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: AnymeXText(
                          task.qualityOrStatus,
                          size: 10,
                          color: theme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isActive) ...[
                if (task.isDownloading || task.isQueued)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => controller.pauseDownload(task.taskId),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.primaryContainer.opaque(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.pause_rounded,
                          size: 14, color: theme.primary),
                    ),
                  )
                else if (task.isPaused)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => controller.resumeDownload(task.taskId),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.primaryContainer.opaque(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow_rounded,
                          size: 14, color: theme.primary),
                    ),
                  ),
                const SizedBox(width: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.errorContainer.opaque(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 14, color: theme.error),
                  ),
                ),
              ] else
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.surfaceContainerHighest.opaque(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 14, color: theme.onSurface.opaque(0.5)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (task.status == DownloadStatus.fetchingServer) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                backgroundColor: theme.surfaceContainerHighest.opaque(0.4),
                valueColor: AlwaysStoppedAnimation(theme.primary),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
          ] else if (task.isDownloading || task.isPaused) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: task.progress,
                backgroundColor: theme.surfaceContainerHighest.opaque(0.4),
                valueColor: AlwaysStoppedAnimation(
                  task.isPaused
                      ? theme.primary.opaque(0.4)
                      : theme.primary,
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
          ] else if (task.isQueued) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                backgroundColor: theme.surfaceContainerHighest.opaque(0.4),
                valueColor: AlwaysStoppedAnimation(theme.primary.opaque(0.3)),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Icon(statusIcon, size: 13, color: statusColor),
              const SizedBox(width: 5),
              AnymeXText(
                statusLabel,
                size: 11.5,
                color: statusColor,
                variant: TextVariant.semiBold,
              ),
              const Spacer(),
              if (task.isDownloading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: theme.primaryContainer.opaque(0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(HugeIcons.strokeRoundedFlash,
                          size: 11, color: theme.primary),
                      const SizedBox(width: 4),
                      AnymeXText(
                        DownloadController.formatSpeed(taskSpeed),
                        size: 10.5,
                        variant: TextVariant.bold,
                        color: theme.primary,
                      ),
                    ],
                  ),
                ),
              if (!task.isManga &&
                  task.status == DownloadStatus.awaitingServerSelection) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _showManualServerSelection(
                      context, task.originalTask!,
                      preloadedServers:
                          task.originalTask!.availableServers),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: AnymeXText('Select Server',
                        size: 10.5,
                        color: theme.onTertiaryContainer,
                        variant: TextVariant.bold),
                  ),
                ),
              ] else if (task.isFailed &&
                  !task.isManga &&
                  (task.errorMessage?.contains('matching quality') ??
                      false)) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _showManualServerSelection(
                      context, task.originalTask!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: AnymeXText('Select Server',
                        size: 10.5,
                        color: theme.onPrimary,
                        variant: TextVariant.bold),
                  ),
                ),
              ],
            ],
          ),
          if (task.errorMessage != null && task.isFailed) ...[
            const SizedBox(height: 5),
            AnymeXText(
              task.errorMessage!,
              size: 11,
              color: theme.error.opaque(0.75),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  void _toggleGroupPause(
      _MediaDownloadGroup group, DownloadController controller) {
    if (group.canPauseAny) {
      for (final task in group.tasks) {
        if (task.isDownloading || task.isQueued) {
          controller.pauseDownload(task.taskId);
        }
      }
    } else if (group.canResumeAny) {
      for (final task in group.tasks) {
        if (task.isPaused) {
          controller.resumeDownload(task.taskId);
        }
      }
    }
  }

  void _cancelGroup(_MediaDownloadGroup group, DownloadController controller) {
    setState(() {
      _collapsedGroupKeys.remove(group.key);
    });
    final ids = group.tasks.map((t) => t.taskId).toList();
    controller.cancelAndRemoveTasks(ids, isManga: group.isManga);
  }

  void _cancelTask(_UnifiedTask task, DownloadController controller) {
    controller.cancelAndRemoveTasks([task.taskId], isManga: task.isManga);
  }

  void _removeTask(_UnifiedTask task, DownloadController controller) {
    if (task.isManga) {
      controller.removeMangaTask(task.taskId);
    } else {
      controller.removeTask(task.taskId);
    }
  }

  void _showManualServerSelection(
    BuildContext context,
    ActiveDownloadTask task, {
    List<Video>? preloadedServers,
  }) {
    if (preloadedServers != null && preloadedServers.isNotEmpty) {
      _showServerSheet(context, task, preloadedServers);
      return;
    }

    final sourceController = Get.find<SourceController>();
    final allSources = [
      ...sourceController.installedExtensions,
      ...sourceController.installedMangaExtensions,
    ];
    final source =
        DownloadController.findMatchingSource(allSources, task.extensionName);

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

    AnymeXSheet.custom(
      Builder(
        builder: (ctx) {
          if (videoStream != null) {
            final List<Video> streamServers = [];
            bool streamDone = false;
            StreamSubscription? sub;

            return StatefulBuilder(
              builder: (sheetCtx, setSheetState) {
                sub ??= videoStream.listen(
                  (v) {
                    final video = Video.fromVideo(v);
                    setSheetState(() => streamServers.add(video));
                  },
                  onDone: () => setSheetState(() => streamDone = true),
                  onError: (_) => setSheetState(() => streamDone = true),
                );

                return _buildServerSheetContent(
                  context: sheetCtx,
                  servers: streamServers,
                  isLoading: !streamDone,
                  task: task,
                );
              },
            );
          } else {
            return FutureBuilder<List<Video>>(
              future: source.methods
                  .getVideoList(deEpisode)
                  .then((list) => list.map((v) => Video.fromVideo(v)).toList()),
              builder: (futureCtx, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _buildServerSheetContent(
                  context: futureCtx,
                  servers: snapshot.data ?? [],
                  isLoading: false,
                  task: task,
                );
              },
            );
          }
        },
      ),
      context,
      showDragHandle: true,
    );
  }

  void _showServerSheet(
    BuildContext context,
    ActiveDownloadTask task,
    List<Video> servers,
  ) {
    AnymeXSheet.custom(
      _buildServerSheetContent(
        context: context,
        servers: servers,
        isLoading: false,
        task: task,
      ),
      context,
      showDragHandle: true,
    );
  }

  Widget _buildServerSheetContent({
    required BuildContext context,
    required List<Video> servers,
    required bool isLoading,
    required ActiveDownloadTask task,
  }) {
    final theme = context.colors;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AnymeXText('Select Server',
                    variant: TextVariant.bold, size: 18),
                if (isLoading) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (servers.isEmpty && isLoading)
            const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (servers.isEmpty && !isLoading)
            SizedBox(
              height: 180,
              child: Center(
                child: AnymeXText('No servers found.',
                    color: theme.onSurface.opaque(0.5)),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: servers.length,
                itemBuilder: (context, index) {
                  final server = servers[index];
                  return ListTile(
                    leading: Icon(Icons.dns_rounded, color: theme.primary),
                    title: AnymeXText(server.quality ?? 'Unknown Quality',
                        variant: TextVariant.semiBold),
                    subtitle: AnymeXText(
                      server.originalUrl ?? server.url ?? '',
                      size: 12,
                      maxLines: 1,
                    ),
                    onTap: () {
                      Get.find<DownloadController>()
                          .manualSelectServerForTask(task, server);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _MediaDownloadGroup {
  final String key;
  final String mediaTitle;
  final bool isManga;
  final String extensionName;
  final String? poster;
  final List<_UnifiedTask> tasks;

  _MediaDownloadGroup({
    required this.key,
    required this.mediaTitle,
    required this.isManga,
    required this.extensionName,
    this.poster,
    required this.tasks,
  });

  double get averageProgress {
    if (tasks.isEmpty) return 0.0;
    final total = tasks.fold<double>(0.0, (acc, t) => acc + t.progress);
    return total / tasks.length;
  }

  int get downloadingCount => tasks.where((t) => t.isDownloading).length;
  int get queuedCount => tasks.where((t) => t.isQueued).length;
  int get pausedCount => tasks.where((t) => t.isPaused).length;
  int get completedCount => tasks.where((t) => t.isCompleted).length;
  int get failedCount => tasks.where((t) => t.isFailed).length;

  bool get canPauseAny => tasks.any((t) => t.isDownloading || t.isQueued);
  bool get canResumeAny => tasks.any((t) => t.isPaused);
}

class _UnifiedTask {
  final ActiveDownloadTask? originalTask;
  final ActiveMangaDownloadTask? originalMangaTask;
  final String taskId;
  final String mediaTitle;
  final String extensionName;
  final String displayId;
  final double progress;
  final String? errorMessage;
  final bool isManga;
  final String qualityOrStatus;
  final OfflineMedia? media;

  final bool isDownloading;
  final bool isPaused;
  final bool isCompleted;
  final bool isFailed;
  final bool isCancelled;
  final bool isQueued;
  final DownloadStatus? status;

  _UnifiedTask.fromAnime(ActiveDownloadTask task)
      : originalTask = task,
        originalMangaTask = null,
        taskId = task.taskId,
        mediaTitle = task.mediaTitle,
        extensionName = task.extensionName,
        displayId = task.episodeDisplayId,
        progress = task.progress,
        errorMessage = task.errorMessage,
        isManga = false,
        qualityOrStatus = task.videoQuality,
        status = task.status,
        media = task.media,
        isDownloading = task.status == DownloadStatus.downloading,
        isPaused = task.status == DownloadStatus.paused,
        isCompleted = task.status == DownloadStatus.completed,
        isFailed = task.status == DownloadStatus.failed,
        isCancelled = task.status == DownloadStatus.cancelled,
        isQueued = task.status == DownloadStatus.queued;

  _UnifiedTask.fromManga(ActiveMangaDownloadTask task)
      : originalTask = null,
        originalMangaTask = task,
        taskId = task.taskId,
        mediaTitle = task.mediaTitle,
        extensionName = task.extensionName,
        displayId = task.chapterDisplay,
        progress = task.progress,
        errorMessage = task.errorMessage,
        isManga = true,
        qualityOrStatus = task.status == MangaDownloadStatus.fetchingPages
            ? 'Pages'
            : 'Images',
        status = null,
        media = task.media,
        isDownloading = task.status == MangaDownloadStatus.downloading ||
            task.status == MangaDownloadStatus.fetchingPages,
        isPaused = task.status == MangaDownloadStatus.paused,
        isCompleted = task.status == MangaDownloadStatus.completed,
        isFailed = task.status == MangaDownloadStatus.failed,
        isCancelled = task.status == MangaDownloadStatus.cancelled,
        isQueued = task.status == MangaDownloadStatus.queued;
}
