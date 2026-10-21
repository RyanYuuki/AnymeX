import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';

const int torrentFileAuto = -1;

const _videoExtensions = {
  '.mp4',
  '.mkv',
  '.avi',
  '.mov',
  '.webm',
  '.m4v',
  '.flv',
  '.wmv',
  '.ts',
};

class TorrentFileSelectorSheet extends StatefulWidget {
  final TorrServerAddon addon;
  final String url;
  final String title;

  const TorrentFileSelectorSheet({
    super.key,
    required this.addon,
    required this.url,
    required this.title,
  });

  @override
  State<TorrentFileSelectorSheet> createState() =>
      _TorrentFileSelectorSheetState();
}

class _TorrentFileSelectorSheetState extends State<TorrentFileSelectorSheet> {
  List<TorrentFileStat>? _files;
  String? _error;
  String? _hash;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    final hash = _hash;
    if (hash != null && _selectedId == null) {
      unawaited(widget.addon.release(hash));
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _files = null;
      _error = null;
    });
    try {
      final info = await widget.addon.addForDownload(
        url: widget.url,
        title: widget.title,
      );
      if (!mounted) {
        unawaited(widget.addon.release(info.hash));
        return;
      }
      _hash = info.hash;
      final videos = [
        for (final f in info.fileStats)
          if (_videoExtensions.contains(p.extension(f.path).toLowerCase())) f,
      ]..sort((a, b) => a.path.compareTo(b.path));

      if (videos.length < 2) {
        Navigator.of(context).pop(torrentFileAuto);
        return;
      }
      setState(() {
        _files = videos;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AnymeXText(
                      'Select Video File',
                      size: 18,
                      variant: TextVariant.bold,
                    ),
                    const SizedBox(height: 4),
                    AnymeXText(
                      widget.title,
                      size: 12,
                      color: colors.onSurfaceVariant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AnymexOnTap(
                onTap: () => Navigator.of(context).pop(torrentFileAuto),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: colors.onSurface),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: _buildBody(colors),
        ),
      ],
    );
  }

  Widget _buildBody(ColorScheme colors) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: colors.error),
              const SizedBox(height: 12),
              const AnymeXText(
                'Failed to load torrent metadata',
                size: 15,
                variant: TextVariant.semiBold,
              ),
              const SizedBox(height: 6),
              AnymeXText(
                _error!,
                size: 12,
                color: colors.onSurfaceVariant,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              AnymeXButton(
                onTap: _load,
                width: 120,
                height: 38,
                borderRadius: BorderRadius.circular(12),
                child: const AnymeXText('Retry', variant: TextVariant.semiBold),
              ),
            ],
          ),
        ),
      );
    }

    final files = _files;
    if (files == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              AnymeXText(
                'Fetching torrent file list...',
                size: 13,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final f = files[index];
        final name = p.basename(f.path);
        final size = _formatSize(f.length);
        final selected = _selectedId == f.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: AnymeXTile(
            title: name,
            subtitle: size,
            icon: Icons.movie_outlined,
            trailing: selected
                ? Icon(Icons.check_circle_rounded, color: colors.primary)
                : null,
            onTap: () {
              setState(() => _selectedId = f.id);
              Navigator.of(context).pop(f.id);
            },
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}
