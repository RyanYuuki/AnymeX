// import 'package:background_downloader/background_downloader.dart';

// class DownloadItem {
//   final String id;
//   final String url;
//   final String filename;
//   final String displayName;
//   final TaskStatus status;
//   final double progress;
//   final int totalBytes;
//   final int downloadedBytes;
//   final DateTime createdAt;
//   final String? localPath;
//   final String? error;
//   final DownloadTask? task;
//   final Map<String, dynamic>? metaData;

//   DownloadItem(
//       {required this.id,
//       required this.url,
//       required this.filename,
//       required this.displayName,
//       required this.status,
//       this.progress = 0.0,
//       this.totalBytes = 0,
//       this.downloadedBytes = 0,
//       required this.createdAt,
//       this.localPath,
//       this.error,
//       this.task,
//       this.metaData});

//   DownloadItem copyWith({
//     String? id,
//     String? url,
//     String? filename,
//     String? displayName,
//     TaskStatus? status,
//     double? progress,
//     int? totalBytes,
//     int? downloadedBytes,
//     DateTime? createdAt,
//     String? localPath,
//     String? error,
//     DownloadTask? task,
//   }) {
//     return DownloadItem(
//       id: id ?? this.id,
//       url: url ?? this.url,
//       filename: filename ?? this.filename,
//       displayName: displayName ?? this.displayName,
//       status: status ?? this.status,
//       progress: progress ?? this.progress,
//       totalBytes: totalBytes ?? this.totalBytes,
//       downloadedBytes: downloadedBytes ?? this.downloadedBytes,
//       createdAt: createdAt ?? this.createdAt,
//       localPath: localPath ?? this.localPath,
//       error: error ?? this.error,
//       task: task ?? this.task,
//     );
//   }

//   bool get isCompleted => status == TaskStatus.complete;
//   bool get isDownloading => status == TaskStatus.running;
//   bool get isPaused => status == TaskStatus.paused;
//   bool get isFailed => status == TaskStatus.failed;
//   bool get isCanceled => status == TaskStatus.canceled;
//   bool get canPause => status == TaskStatus.running;
//   bool get canResume => status == TaskStatus.paused;
//   bool get canRetry =>
//       status == TaskStatus.failed || status == TaskStatus.canceled;

//   String get statusText {
//     switch (status) {
//       case TaskStatus.enqueued:
//         return 'Queued';
//       case TaskStatus.running:
//         return 'Downloading';
//       case TaskStatus.complete:
//         return 'Completed';
//       case TaskStatus.notFound:
//         return 'Not Found';
//       case TaskStatus.failed:
//         return 'Failed';
//       case TaskStatus.canceled:
//         return 'Canceled';
//       case TaskStatus.paused:
//         return 'Paused';
//       case TaskStatus.waitingToRetry:
//         return 'Waiting to Retry';
//     }
//   }

//   String get formattedFileSize {
//     if (totalBytes == 0) return 'Unknown size';
//     return _formatBytes(totalBytes);
//   }

//   String get formattedDownloadedSize {
//     return _formatBytes(downloadedBytes);
//   }

//   String get progressText {
//     if (totalBytes > 0) {
//       return '$formattedDownloadedSize / $formattedFileSize';
//     }
//     return formattedDownloadedSize;
//   }

//   String _formatBytes(int bytes) {
//     if (bytes < 1024) return '$bytes B';
//     if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
//     if (bytes < 1024 * 1024 * 1024) {
//       return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
//     }
//     return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
//   }
// }
