import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/screens/anime/details/controller/media_details_controller.dart';
import 'package:anymex/screens/anime/widgets/custom_list_dialog.dart';
import 'package:anymex/screens/anime/widgets/list_editor.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/l10n/ui_labels.dart';
import 'package:anymex/l10n/l10n_extension.dart';

Widget buildMediaQuickActions(
  BuildContext context,
  MediaDetailsController controller, {
  EdgeInsetsGeometry? padding,
  double height = 42,
}) {
  final isOnlineService =
      controller.media.value.serviceType != ServicesType.extensions;

  final isLoggedIn = isOnlineService &&
      controller.media.value.serviceType.onlineService.isLoggedIn.value;

  return Padding(
    padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Obx(() {
      controller.media.value;
      return Row(
        children: [
          if (isLoggedIn) ...[
            Expanded(
              child: Obx(() {
                final isListed = controller.isListedMedia.value;
                final statusText = isListed
                    ? (controller.mediaStatus.value.isNotEmpty
                        ? controller.mediaStatus.value
                        : 'TRACKING')
                    : 'ADD TO LIST';

                return _buildQuickActionButton(
                  context: context,
                  radius: BorderRadius.circular(16),
                  icon:
                      isListed ? Icons.check_circle_rounded : Icons.add_rounded,
                  label: statusText,
                  isPrimary: true,
                  height: height,
                  onTap: () {
                    AnymeXSheet.custom(
                        ListEditorModal(
                          animeStatus: controller.mediaStatus,
                          animeScore: controller.mediaScore,
                          animeProgress: controller.mediaProgress,
                          currentAnime: controller.trackedMedia,
                          media: controller.media.value,
                          isManga: !controller.isAnime,
                          onUpdate: (id, score, status, progress, season,
                              startedAt, completedAt, isPrivate) {
                            controller.updateListEntry(
                              status: status,
                              progress: progress,
                              score: score,
                              season: season,
                              startedAt: startedAt,
                              completedAt: completedAt,
                              isPrivate: isPrivate,
                            );
                          },
                          onDelete: (id) {
                            controller.deleteListEntry();
                          },
                        ),
                        context);
                  },
                );
              }),
            ),
          ],
          if (isLoggedIn) const SizedBox(width: 8),
          Expanded(
            child: Obx(() {
              final inList = controller.isInCustomList.value;
              return _buildQuickActionButton(
                context: context,
                icon: inList
                    ? Icons.bookmark_added_rounded
                    : Icons.bookmark_add_outlined,
                label: uiLabel(context.l10n, inList ? 'In Custom List' : 'Custom List'),
                isPrimary: inList,
                radius: BorderRadius.circular(16),
                height: height,
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => CustomListDialog(
                      original: controller.media.value,
                    ),
                  );
                  controller.checkIfInCustomList();
                },
              );
            }),
          ),
        ],
      );
    }),
  );
}

Widget _buildQuickActionButton({
  required BuildContext context,
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  required BorderRadius radius,
  bool isPrimary = false,
  double height = 42,
}) {
  final colors = context.colors;
  final borderClr = isPrimary
      ? colors.primary.opaque(0.25, iReallyMeanIt: true)
      : colors.onSurface.opaque(0.08, iReallyMeanIt: true);
  final bgClr = isPrimary
      ? colors.primary.opaque(0.12, iReallyMeanIt: true)
      : colors.surfaceContainerHighest.opaque(0.35, iReallyMeanIt: true);
  final textClr = isPrimary ? colors.primary : colors.onSurface;

  return Material(
    color: bgClr,
    borderRadius: radius,
    child: InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: borderClr, width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: textClr,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: AnymeXText(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textClr,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
