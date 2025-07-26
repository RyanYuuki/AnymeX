// import 'package:anymex/screens/downloader/controller/download_manager.dart';
// import 'package:anymex/utils/function.dart';
// import 'package:anymex/widgets/common/glow.dart';
// import 'package:anymex/widgets/common/slider_semantics.dart';
// import 'package:anymex/widgets/non_widgets/snackbar.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:anymex/screens/downloader/model/download_item.dart';
// import 'package:background_downloader/background_downloader.dart';
// import 'package:iconsax/iconsax.dart';

// class DownloadManagerPage extends StatefulWidget {
//   const DownloadManagerPage({super.key});

//   @override
//   State<DownloadManagerPage> createState() => _DownloadManagerPageState();
// }

// class _DownloadManagerPageState extends State<DownloadManagerPage> {
//   final DownloadManagerController _controller =
//       DownloadManagerController.instance;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Glow(
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         body: Column(
//           children: [
//             _buildAppBar(),
//             Obx(() {
//               if (!_controller.isInitialized) {
//                 return Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: colorScheme.primary.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: CircularProgressIndicator(
//                         color: colorScheme.primary,
//                         strokeWidth: 3,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Text(
//                       'Initializing Downloads...',
//                       style: theme.textTheme.bodyLarge?.copyWith(
//                         color: colorScheme.onSurfaceVariant,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 );
//               }

//               final allDownloads = _controller.downloadsList;
//               final activeDownloads = _controller.activeDownloadsList;
//               final otherDownloads = allDownloads
//                   .where((item) => !activeDownloads.contains(item))
//                   .toList();

//               if (allDownloads.isEmpty) {
//                 return _buildEmptyState(theme, colorScheme);
//               }

//               return Expanded(
//                 child: ListView(
//                   children: ([
//                     if (activeDownloads.isNotEmpty) ...[
//                       _buildSectionHeader(
//                         'Active Downloads',
//                         activeDownloads.length,
//                         theme,
//                         colorScheme,
//                         Iconsax.document_download,
//                         colorScheme.primary,
//                       ),
//                       ...activeDownloads.map(
//                           (item) => _buildDownloadCard(item, isActive: true)),
//                       const SizedBox(height: 24),
//                     ],
//                     if (otherDownloads.isNotEmpty) ...[
//                       _buildSectionHeader(
//                         'All Downloads',
//                         otherDownloads.length,
//                         theme,
//                         colorScheme,
//                         Iconsax.document,
//                         colorScheme.onSurfaceVariant,
//                       ),
//                       ...otherDownloads.map((item) => _buildDownloadCard(item)),
//                     ],
//                     const SizedBox(height: 100),
//                   ]),
//                 ),
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAppBar() {
//     final theme = Theme.of(context);
//     return Container(
//       padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surface.withOpacity(0.4),
//         border: Border(
//           bottom: BorderSide(
//             color: theme.colorScheme.outline.withOpacity(0.2),
//             width: 1,
//           ),
//         ),
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             onPressed: () => Get.back(),
//             icon: Icon(
//               Icons.arrow_back_ios_rounded,
//               color: theme.colorScheme.onSurface,
//             ),
//             style: IconButton.styleFrom(
//               backgroundColor:
//                   theme.colorScheme.surfaceVariant.withOpacity(0.3),
//               padding: const EdgeInsets.all(12),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               'Downloads',
//               style: TextStyle(
//                 color: theme.colorScheme.onSurface,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 22,
//               ),
//             ),
//           ),
//           8.width(),
//           IconButton(
//             onPressed: () {
//               _showSettingsDialog();
//             },
//             icon: Icon(
//               Iconsax.setting,
//               color: theme.colorScheme.onSurface,
//             ),
//             style: IconButton.styleFrom(
//               backgroundColor:
//                   theme.colorScheme.surfaceVariant.withOpacity(0.3),
//               padding: const EdgeInsets.all(12),
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
//     return Expanded(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(32),
//             decoration: BoxDecoration(
//               color: colorScheme.surfaceVariant.withOpacity(0.3),
//               borderRadius: BorderRadius.circular(24),
//               border: Border.all(
//                 color: colorScheme.outline.withOpacity(0.2),
//               ),
//             ),
//             child: Icon(
//               Iconsax.document_download,
//               size: 64,
//               color: colorScheme.onSurfaceVariant.withOpacity(0.6),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             'No downloads yet',
//             style: theme.textTheme.headlineSmall?.copyWith(
//               color: colorScheme.onSurface,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Ah.. so empty..... <_>',
//             style: theme.textTheme.bodyMedium?.copyWith(
//               color: colorScheme.onSurfaceVariant,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionHeader(String title, int count, ThemeData theme,
//       ColorScheme colorScheme, IconData icon, Color iconColor) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: iconColor.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, size: 18, color: iconColor),
//           ),
//           const SizedBox(width: 12),
//           Text(
//             title,
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.w700,
//               color: colorScheme.onSurface,
//               letterSpacing: -0.3,
//             ),
//           ),
//           const SizedBox(width: 8),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//             decoration: BoxDecoration(
//               color: colorScheme.primary.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(
//               count.toString(),
//               style: theme.textTheme.labelSmall?.copyWith(
//                 color: colorScheme.primary,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDownloadCard(DownloadItem item, {bool isActive = false}) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(20),
//         color: isActive
//             ? colorScheme.primary.withOpacity(0.05)
//             : colorScheme.surfaceVariant.withOpacity(0.3),
//         border: Border.all(
//           color: isActive
//               ? colorScheme.primary.withOpacity(0.2)
//               : colorScheme.outline.withOpacity(0.15),
//           width: isActive ? 1.5 : 1,
//         ),
//         boxShadow: isActive
//             ? [
//                 BoxShadow(
//                   color: colorScheme.primary.withOpacity(0.1),
//                   blurRadius: 8,
//                   offset: const Offset(0, 2),
//                 ),
//               ]
//             : null,
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Container(
//                     width: 56,
//                     height: 78,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12),
//                       color: colorScheme.primary.withOpacity(0.1),
//                       border: Border.all(
//                         color: colorScheme.primary.withOpacity(0.2),
//                       ),
//                     ),
//                     clipBehavior: Clip.antiAlias,
//                     child: Image.network(
//                       item.task!.metaData,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) =>
//                           _buildFallbackIcon(colorScheme),
//                     )),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         item.displayName,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.w600,
//                           color: colorScheme.onSurface,
//                           height: 1.3,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           _buildInfoChip(
//                             item.metaData?['season'] ?? 'MP4',
//                             Iconsax.video_play,
//                           ),
//                           const SizedBox(width: 8),
//                           _buildInfoChip(
//                             item.formattedFileSize,
//                             Iconsax.document,
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       _buildStatusChip(item, theme, colorScheme),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             if (isActive && item.status == TaskStatus.running) ...[
//               const SizedBox(height: 16),
//               _buildProgressSection(item, theme, colorScheme),
//             ],
//             if (item.canPause ||
//                 item.canResume ||
//                 item.isFailed ||
//                 item.isCanceled) ...[
//               const SizedBox(height: 16),
//               _buildActionButtons(item, colorScheme, theme),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFallbackIcon(ColorScheme colorScheme) {
//     return Center(
//       child: Icon(
//         Iconsax.video_play,
//         color: colorScheme.primary,
//         size: 24,
//       ),
//     );
//   }

//   Widget _buildInfoChip(String text, IconData icon) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: colorScheme.secondary.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: colorScheme.secondary.withOpacity(0.2),
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             icon,
//             size: 14,
//             color: colorScheme.secondary,
//           ),
//           const SizedBox(width: 6),
//           Text(
//             text,
//             style: theme.textTheme.labelSmall?.copyWith(
//               color: colorScheme.secondary,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusChip(
//       DownloadItem item, ThemeData theme, ColorScheme colorScheme) {
//     final statusColor = _getStatusColor(item.status, colorScheme);
//     final statusText = _getStatusText(item);
//     final statusIcon = _getStatusIcon(item.status);

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: statusColor.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(statusIcon, size: 14, color: statusColor),
//           const SizedBox(width: 6),
//           Text(
//             statusText,
//             style: theme.textTheme.labelSmall?.copyWith(
//               color: statusColor,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProgressSection(
//       DownloadItem item, ThemeData theme, ColorScheme colorScheme) {
//     return Column(
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               '${(item.progress * 100).toInt()}%',
//               style: theme.textTheme.labelMedium?.copyWith(
//                 color: colorScheme.primary,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             Text(
//               _formatBytes(item.downloadedBytes, item.totalBytes),
//               style: theme.textTheme.labelMedium?.copyWith(
//                 color: colorScheme.onSurfaceVariant,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Container(
//           height: 6,
//           decoration: BoxDecoration(
//             color: colorScheme.surfaceVariant.withOpacity(0.5),
//             borderRadius: BorderRadius.circular(3),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(3),
//             child: LinearProgressIndicator(
//               value: item.progress,
//               backgroundColor: Colors.transparent,
//               valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
//               minHeight: 6,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButtons(
//       DownloadItem item, ColorScheme colorScheme, ThemeData theme) {
//     return Row(
//       children: [
//         if (item.canPause)
//           _buildActionButton(
//             icon: Iconsax.pause,
//             label: 'Pause',
//             onPressed: () => _controller.pauseDownload(item.id),
//             backgroundColor: colorScheme.secondaryContainer.withOpacity(0.5),
//             foregroundColor: colorScheme.onSecondaryContainer,
//           )
//         else if (item.canResume)
//           _buildActionButton(
//             icon: Iconsax.play,
//             label: 'Resume',
//             onPressed: () => _controller.resumeDownload(item.id),
//             backgroundColor: colorScheme.primaryContainer.withOpacity(0.5),
//             foregroundColor: colorScheme.onPrimaryContainer,
//           )
//         else if (item.isFailed || item.isCanceled)
//           _buildActionButton(
//             icon: Iconsax.refresh,
//             label: 'Retry',
//             onPressed: () => _controller.retryDownload(item.id),
//             backgroundColor: colorScheme.primaryContainer.withOpacity(0.5),
//             foregroundColor: colorScheme.onPrimaryContainer,
//           ),
//         const Spacer(),
//         _buildActionButton(
//           icon: Iconsax.trash,
//           label: 'Delete',
//           onPressed: () => _showDeleteConfirmation(item),
//           backgroundColor: colorScheme.errorContainer.withOpacity(0.5),
//           foregroundColor: colorScheme.onErrorContainer,
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onPressed,
//     required Color backgroundColor,
//     required Color foregroundColor,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(onTap: onPressed, child: _buildInfoChip(label, icon)),
//     );
//   }

//   IconData _getStatusIcon(TaskStatus status) {
//     switch (status) {
//       case TaskStatus.complete:
//         return Iconsax.tick_circle;
//       case TaskStatus.running:
//         return Iconsax.document_download;
//       case TaskStatus.paused:
//         return Iconsax.pause_circle;
//       case TaskStatus.failed:
//       case TaskStatus.canceled:
//         return Iconsax.close_circle;
//       default:
//         return Iconsax.clock;
//     }
//   }

//   String _getStatusText(DownloadItem item) {
//     switch (item.status) {
//       case TaskStatus.complete:
//         return 'Completed';
//       case TaskStatus.running:
//         return 'Downloading';
//       case TaskStatus.paused:
//         return 'Paused';
//       case TaskStatus.failed:
//         return 'Failed';
//       case TaskStatus.canceled:
//         return 'Canceled';
//       case TaskStatus.enqueued:
//         return 'Queued';
//       default:
//         return 'Unknown';
//     }
//   }

//   Color _getStatusColor(TaskStatus status, ColorScheme colorScheme) {
//     switch (status) {
//       case TaskStatus.complete:
//         return Colors.green;
//       case TaskStatus.running:
//         return colorScheme.primary;
//       case TaskStatus.paused:
//         return Colors.orange;
//       case TaskStatus.failed:
//       case TaskStatus.canceled:
//         return colorScheme.error;
//       default:
//         return colorScheme.onSurfaceVariant;
//     }
//   }

//   String _formatBytes(int downloaded, int total) {
//     if (total == 0) return 'Unknown size';

//     String formatSize(int bytes) {
//       if (bytes < 1024) return '${bytes}B';
//       if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
//       if (bytes < 1024 * 1024 * 1024) {
//         return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
//       }
//       return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
//     }

//     return '${formatSize(downloaded)} / ${formatSize(total)}';
//   }

//   void _showDeleteConfirmation(DownloadItem item) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: colorScheme.surface,
//         surfaceTintColor: Colors.transparent,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(24),
//         ),
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: colorScheme.errorContainer.withOpacity(0.5),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(
//                 Iconsax.trash,
//                 color: colorScheme.error,
//                 size: 20,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Text(
//               'Delete Download',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ],
//         ),
//         content: Text(
//           'Are you sure you want to delete "${item.displayName}"?\n\nThis action cannot be undone.',
//           style: theme.textTheme.bodyMedium?.copyWith(
//             color: colorScheme.onSurfaceVariant,
//             height: 1.4,
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             style: TextButton.styleFrom(
//               foregroundColor: colorScheme.onSurfaceVariant,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: const Text('Cancel'),
//           ),
//           FilledButton(
//             onPressed: () async {
//               await _controller.removeDownload(item.id, deleteFile: true);
//               if (mounted) {
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: const Text('Download deleted'),
//                     backgroundColor: colorScheme.error,
//                     behavior: SnackBarBehavior.floating,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 );
//               }
//             },
//             style: FilledButton.styleFrom(
//               backgroundColor: colorScheme.error,
//               foregroundColor: colorScheme.onError,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showSettingsDialog() {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     showDialog(
//       context: context,
//       builder: (context) {
//         final width = MediaQuery.of(context).size.width * 0.95;
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           insetPadding: EdgeInsets.zero,
//           child: ConstrainedBox(
//             constraints: BoxConstraints(maxWidth: width),
//             child: AlertDialog(
//               backgroundColor: colorScheme.surface,
//               surfaceTintColor: Colors.transparent,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(24),
//               ),
//               title: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: colorScheme.primary.withOpacity(0.15),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Icon(
//                       Iconsax.setting_2,
//                       color: colorScheme.primary,
//                       size: 20,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Text(
//                     'Download Settings',
//                     style: theme.textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ],
//               ),
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     _buildSettingsTile(
//                       icon: Iconsax.folder,
//                       title: 'Download Path',
//                       subtitle: _controller.downloadPath,
//                       onTap: () async {
//                         Navigator.pop(context);
//                         try {
//                           String? selectedDirectory =
//                               await FilePicker.platform.getDirectoryPath();

//                           if (selectedDirectory != null) {
//                             _controller.setDownloadPath(selectedDirectory);
//                           }
//                         } catch (e) {
//                           errorSnackBar(e.toString());
//                         }
//                       },
//                       theme: theme,
//                       colorScheme: colorScheme,
//                     ),
//                     _buildSettingsSliderTile(
//                         icon: Iconsax.speedometer,
//                         title: 'Concurrent Downloads',
//                         subtitle: 'Maximum: 3 (Restart Required)',
//                         onChanged: (e) {},
//                         theme: theme,
//                         colorScheme: colorScheme,
//                         value: 1,
//                         max: 3,
//                         min: 1),
//                     _buildSettingsTile(
//                       icon: Iconsax.notification,
//                       title: 'Download Notifications',
//                       subtitle: 'Get notified when downloads complete',
//                       trailing: Switch.adaptive(
//                         value: true,
//                         onChanged: (value) {},
//                         activeColor: colorScheme.primary,
//                       ),
//                       theme: theme,
//                       colorScheme: colorScheme,
//                     ),
//                     const SizedBox(height: 16),
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: colorScheme.errorContainer.withOpacity(0.3),
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(
//                           color: colorScheme.error.withOpacity(0.2),
//                         ),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Icon(
//                                 Iconsax.danger,
//                                 color: colorScheme.error,
//                                 size: 18,
//                               ),
//                               const SizedBox(width: 8),
//                               Text(
//                                 'Danger Zone',
//                                 style: theme.textTheme.titleSmall?.copyWith(
//                                   color: colorScheme.error,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 12),
//                           SizedBox(
//                             width: double.infinity,
//                             child: OutlinedButton.icon(
//                               onPressed: () => _showClearAllConfirmation(),
//                               icon: const Icon(Iconsax.trash, size: 18),
//                               label: const Text('Clear All Downloads'),
//                               style: OutlinedButton.styleFrom(
//                                 foregroundColor: colorScheme.error,
//                                 side: BorderSide(
//                                   color: colorScheme.error.withOpacity(0.5),
//                                 ),
//                                 padding:
//                                     const EdgeInsets.symmetric(vertical: 12),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 FilledButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: FilledButton.styleFrom(
//                     backgroundColor: colorScheme.primary,
//                     foregroundColor: colorScheme.onPrimary,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 32, vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: const Text('Done'),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSettingsSliderTile({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required Function(double) onChanged,
//     required ThemeData theme,
//     required ColorScheme colorScheme,
//     required double value,
//     required double min,
//     required double max,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: colorScheme.surfaceVariant.withOpacity(0.3),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: colorScheme.outline.withOpacity(0.2),
//         ),
//       ),
//       child: Column(
//         children: [
//           ListTile(
//             onTap: () {},
//             leading: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: colorScheme.primary.withOpacity(0.15),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Icon(
//                 icon,
//                 color: colorScheme.primary,
//                 size: 20,
//               ),
//             ),
//             title: Text(
//               title,
//               style: theme.textTheme.titleSmall?.copyWith(
//                 fontWeight: FontWeight.w600,
//                 color: colorScheme.onSurface,
//               ),
//             ),
//             subtitle: Text(
//               subtitle,
//               style: theme.textTheme.bodySmall?.copyWith(
//                 color: colorScheme.onSurfaceVariant,
//               ),
//             ),
//             contentPadding:
//                 const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             child: Row(
//               children: [
//                 Text(value.toString()),
//                 5.width(),
//                 Expanded(
//                   child: CustomSlider(
//                     value: value,
//                     onChanged: onChanged,
//                     min: min,
//                     max: max,
//                   ),
//                 ),
//                 5.width(),
//                 Text(max.toString()),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSettingsTile({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     Widget? trailing,
//     VoidCallback? onTap,
//     required ThemeData theme,
//     required ColorScheme colorScheme,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: colorScheme.surfaceVariant.withOpacity(0.3),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: colorScheme.outline.withOpacity(0.2),
//         ),
//       ),
//       child: ListTile(
//         onTap: onTap,
//         leading: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: colorScheme.primary.withOpacity(0.15),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Icon(
//             icon,
//             color: colorScheme.primary,
//             size: 20,
//           ),
//         ),
//         title: Text(
//           title,
//           style: theme.textTheme.titleSmall?.copyWith(
//             fontWeight: FontWeight.w600,
//             color: colorScheme.onSurface,
//           ),
//         ),
//         subtitle: Text(
//           subtitle,
//           style: theme.textTheme.bodySmall?.copyWith(
//             color: colorScheme.onSurfaceVariant,
//           ),
//         ),
//         trailing: trailing ??
//             Icon(
//               Iconsax.arrow_right_3,
//               color: colorScheme.onSurfaceVariant,
//               size: 16,
//             ),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//       ),
//     );
//   }

//   void _showClearAllConfirmation() {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     Navigator.pop(context);

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: colorScheme.surface,
//         surfaceTintColor: Colors.transparent,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(24),
//         ),
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: colorScheme.errorContainer.withOpacity(0.5),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(
//                 Iconsax.danger,
//                 color: colorScheme.error,
//                 size: 20,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Text(
//               'Clear All Downloads',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.w700,
//                 color: colorScheme.error,
//               ),
//             ),
//           ],
//         ),
//         content: Text(
//           'This will remove all downloads from the list and delete all downloaded files. This action cannot be undone.\n\nAre you absolutely sure?',
//           style: theme.textTheme.bodyMedium?.copyWith(
//             color: colorScheme.onSurfaceVariant,
//             height: 1.4,
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             style: TextButton.styleFrom(
//               foregroundColor: colorScheme.onSurfaceVariant,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: const Text('Cancel'),
//           ),
//           FilledButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               _controller.clearCompletedDownloads(deleteFiles: true);
//             },
//             style: FilledButton.styleFrom(
//               backgroundColor: colorScheme.error,
//               foregroundColor: colorScheme.onError,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: const Text('Clear All'),
//           ),
//         ],
//       ),
//     );
//   }
// }
