import 'dart:io';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class FullscreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String tag;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.tag,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  Future<void> _saveImage(String url) async {
    try {
      snackBar("Downloading image...");
      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      if (response.statusCode != 200) {
        snackBar("Failed to download image");
        return;
      }

      final bytes = response.bodyBytes;

      String extension = "jpg";
      try {
        final uri = Uri.parse(url);
        final path = uri.path;
        if (path.contains('.')) {
          extension = path.split('.').last;
          if (extension.length > 4 || extension.contains('/')) {
            extension = "jpg";
          }
        }
      } catch (_) {}

      final fileName =
          "anymex_${DateTime.now().millisecondsSinceEpoch}.$extension";

      if (Platform.isAndroid) {
        Future<bool> check(Permission p) async {
          var status = await p.status;
          if (!status.isGranted) {
            status = await p.request();
          }
          return status.isGranted;
        }

        await check(Permission.storage);
        await check(Permission.photos);
        await check(Permission.manageExternalStorage);

        try {
          final directory = Directory('/storage/emulated/0/Download/AnymeX');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }

          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(bytes);

          try {
            const platform = MethodChannel('com.ryan.anymex/utils');
            await platform.invokeMethod('scanFile', {'path': file.path});
          } catch (_) {}

          if (!mounted) return;
          snackBar("Saved to Downloads/AnymeX/$fileName");
        } catch (e) {
          // Fallback
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(bytes);
          await Share.shareXFiles([XFile(file.path)],
              text: "Image shared from AnymeX");
        }
      } else if (Platform.isIOS) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)],
            text: "Image shared from AnymeX");
      } else {
        // pc
        String? downloadPath = (await getDownloadsDirectory())?.path;

        if (Platform.isLinux || Platform.isMacOS) {
          final home = Platform.environment['HOME'];
          if (home != null) {
            final cleanDownload = downloadPath?.replaceAll(RegExp(r'/$'), '');
            final cleanHome = home.replaceAll(RegExp(r'/$'), '');

            if (cleanDownload == null || cleanDownload == cleanHome) {
              downloadPath = '$cleanHome/Downloads';
            }
          }
        } else if (Platform.isWindows) {
          final userProfile = Platform.environment['USERPROFILE'];
          if (userProfile != null &&
              (downloadPath == null || downloadPath == userProfile)) {
            downloadPath = '$userProfile\\Downloads';
          }
        }

        final path = downloadPath ?? '.';
        final saveDir = Directory('$path/AnymeX');
        if (!await saveDir.exists()) {
          await saveDir.create(recursive: true);
        }

        final file = File('${saveDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        if (!mounted) return;
        snackBar("Saved to $path/AnymeX");
      }
    } catch (e) {
      if (mounted) {
        snackBar("Error saving image");
      }
    }
  }

  Future<void> _shareImage(String url) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) snackBar("Link copied to clipboard!");
      return;
    }
    try {
      snackBar("Preparing image to share...");
      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      if (response.statusCode != 200) {
        snackBar("Failed to fetch image for sharing");
        return;
      }

      final bytes = response.bodyBytes;
      String extension = "jpg";
      try {
        final uri = Uri.parse(url);
        final path = uri.path;
        if (path.contains('.')) {
          extension = path.split('.').last;
          if (extension.length > 4 || extension.contains('/')) {
            extension = "jpg";
          }
        }
      } catch (_) {}

      final fileName =
          "anymex_share_${DateTime.now().millisecondsSinceEpoch}.$extension";
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)], text: "Shared from AnymeX");
    } catch (e) {
      if (mounted) {
        snackBar("Error sharing image");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black,
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onLongPress: () {
                _saveImage(widget.imageUrl);
              },
              child: SizedBox.expand(
                child: ClipRect(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Hero(
                      tag: widget.tag,
                      child: AnymeXImage(
                        imageUrl: widget.imageUrl,
                        key: ValueKey(widget.imageUrl),
                        fit: BoxFit.contain,
                        radius: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  10, MediaQuery.of(context).padding.top + 10, 10, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(
                    icon: Icons.close,
                    onTap: () => Get.back(),
                  ),
                  Row(
                    children: [
                      _buildCircleButton(
                        icon: Icons.share_rounded,
                        onTap: () => _shareImage(widget.imageUrl),
                      ),
                      const SizedBox(width: 10),
                      _buildCircleButton(
                        icon: Icons.download_rounded,
                        onTap: () => _saveImage(widget.imageUrl),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withOpacity(0.3),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(
          minWidth: 50,
          minHeight: 50,
        ),
      ),
    );
  }
}
