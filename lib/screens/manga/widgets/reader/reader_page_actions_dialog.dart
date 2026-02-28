import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';

Future<void> showReaderPageActionsDialog(
  BuildContext context,
  ReaderController controller,
) {
  final pageIndex = (controller.currentPageIndex.value - 1)
      .clamp(0, controller.pageList.length - 1);
  final page = controller.pageList.isNotEmpty
      ? controller.pageList[pageIndex]
      : null;

  if (page == null) return Future.value();

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReaderPageActionsSheet(
      pageUrl: page.url,
      headers: page.headers,
    ),
  );
}

class _ReaderPageActionsSheet extends StatelessWidget {
  const _ReaderPageActionsSheet({
    required this.pageUrl,
    required this.headers,
  });

  final String pageUrl;
  final Map<String, String>? headers;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: context.colors.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Page Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.save_alt_rounded,
                label: 'Save',
                onTap: () => _savePage(context),
              ),
              _ActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: () => _sharePage(context),
              ),
              _ActionButton(
                icon: Icons.content_copy_rounded,
                label: 'Copy URL',
                onTap: () => _copyPage(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<Uint8List?> _fetchImageBytes() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(pageUrl));
      headers?.forEach((k, v) => request.headers.add(k, v));
      final response = await request.close();
      final bytes = await response.expand((c) => c).toList();
      return Uint8List.fromList(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<void> _savePage(BuildContext context) async {
    Navigator.pop(context);
    try {
      final bytes = await _fetchImageBytes();
      if (bytes == null) throw Exception('Failed to fetch image');
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/page_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);
      snackBar('Page saved to ${file.path}', duration: 2500);
    } catch (e) {
      snackBar('Failed to save page: $e', duration: 2500);
    }
  }

  Future<void> _sharePage(BuildContext context) async {
    Navigator.pop(context);
    try {
      final bytes = await _fetchImageBytes();
      if (bytes == null) throw Exception('Failed to fetch image');
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/share_page_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Manga page');
    } catch (e) {
      snackBar('Failed to share page: $e', duration: 2500);
    }
  }

  Future<void> _copyPage(BuildContext context) async {
    Navigator.pop(context);
    try {
      await Clipboard.setData(ClipboardData(text: pageUrl));
      snackBar('Page URL copied to clipboard', duration: 1500);
    } catch (e) {
      snackBar('Failed to copy: $e', duration: 2500);
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.outline.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: context.colors.primary),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(fontSize: 12, color: context.colors.onSurface)),
          ],
        ),
      ),
    );
  }
}
