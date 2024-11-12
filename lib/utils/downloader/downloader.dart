import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class Downloader {
  Future<bool> checkPermission() async {
    final os = await DeviceInfoPlugin().androidInfo;
    final sdkVer = os.version.sdkInt;
    final access =
        sdkVer > 32 ? Permission.manageExternalStorage : Permission.storage;

    final status = await access.request();
    if (status.isPermanentlyDenied) {
      log("Permission permanently denied. Please enable it in settings.");
      return false;
    }
    return status.isGranted;
  }

  Future<void> download(String streamLink, String fileName, String folderName,
      {int retries = 3, int parallelDownloads = 5}) async {
    if (!await checkPermission()) {
      throw Exception("ERR_NO_STORAGE_PERMISSION");
    }
    final downloadDir =
        Directory('/storage/emulated/0/Download/AnymeX/$folderName');
    if (!downloadDir.existsSync()) {
      await downloadDir.create(recursive: true);
      log("Created AnymeX folder at ${downloadDir.path}");
    }

    final outputPath = '${downloadDir.path}/$fileName.mp4';
    final output = File(outputPath);

    try {
      final segments = await _getSegments(streamLink);
      if (segments.isEmpty) throw Exception("No segments found.");

      final buffers = <BufferItem>[];
      final baseUri = _makeBaseLink(streamLink);

      log("Starting download: $fileName");

      final tasks = <Future>[];
      for (int i = 0; i < segments.length; i++) {
        final segmentUri = segments[i].startsWith('http')
            ? segments[i]
            : '$baseUri/${segments[i]}';

        tasks.add(
            _downloadSegmentWithRetry(segmentUri, retries).then((response) {
          buffers.add(BufferItem(index: i, buffer: response.bodyBytes));
          log("Downloaded segment ${i + 1}/${segments.length}");
        }));

        if (tasks.length >= parallelDownloads) {
          await Future.wait(tasks);
          tasks.clear();
        }
      }

      if (tasks.isNotEmpty) await Future.wait(tasks);

      buffers.sort((a, b) => a.index.compareTo(b.index));
      await _writeToFile(output, buffers);

      log("Download Complete: $outputPath");
    } catch (err) {
      log("Download Failed: $err");
      if (await output.exists()) await output.delete();
      throw Exception("Download failed: $err");
    }
  }

  Future<Response> _downloadSegmentWithRetry(String url, int maxRetries) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        attempt++;
        return await get(Uri.parse(url)).timeout(Duration(seconds: 30));
      } catch (err) {
        if (attempt >= maxRetries) {
          throw Exception("Max retries reached: $err");
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
        log("Retrying ($attempt/$maxRetries)... $url");
      }
    }
    throw Exception("Failed to download segment after retries.");
  }

  Future<List<String>> _getSegments(String url) async {
    final response = await get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception(
          "Failed to fetch segments. HTTP Status: ${response.statusCode}");
    }

    return response.body
        .split('\n')
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();
  }

  Future<void> _writeToFile(File file, List<BufferItem> buffers) async {
    final sink = file.openWrite();
    for (final buffer in buffers) {
      sink.add(buffer.buffer);
    }
    await sink.close();
    log("File write complete.");
  }

  String _makeBaseLink(String uri) =>
      uri.split('/').takeWhile((part) => !part.endsWith('.m3u8')).join('/');
}

class BufferItem {
  final int index;
  final Uint8List buffer;

  BufferItem({required this.index, required this.buffer});
}
