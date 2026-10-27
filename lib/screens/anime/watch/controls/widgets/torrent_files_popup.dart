import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:anymex_extension_runtime_bridge/Engines/TorrentEngine/Models/TorrentInfo.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/watch_settings_pane.dart';
import 'package:anymex/controllers/services/torrent/torrent_service.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_search_bar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/utils/theme_extensions.dart';

class TorrentFilesPopup extends StatefulWidget {
  final PlayerController controller;

  const TorrentFilesPopup({super.key, required this.controller});

  @override
  State<TorrentFilesPopup> createState() => _TorrentFilesPopupState();
}

class _TorrentFilesPopupState extends State<TorrentFilesPopup> {
  Timer? _refreshTimer;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && widget.controller.isTorrentFilesPaneOpened.value) {
        TorrentService.instance.refreshActiveTorrent().then((info) {
          if (mounted && info != null) {
            widget.controller.currentTorrentInfo.value = info;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _closePane() {
    widget.controller.isTorrentFilesPaneOpened.value = false;
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

  String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec <= 0) return '0 B/s';
    const suffixes = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    var i = 0;
    double speed = bytesPerSec;
    while (speed >= 1024 && i < suffixes.length - 1) {
      speed /= 1024;
      i++;
    }
    return '${speed.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Widget _buildSubtitle(BuildContext context) {
    final colors = context.colors;
    final torrent = widget.controller.currentTorrentInfo.value ??
        TorrentService.instance.activeTorrent;
    final allFiles = TorrentService.instance.activeTorrentFiles;
    final count = allFiles.length;
    final parts = <String>['$count files'];

    if (torrent != null) {
      if (torrent.totalPeers > 0 || torrent.connectedSeeders > 0) {
        parts.add('${torrent.connectedSeeders}/${torrent.totalPeers} peers');
      }
      if (torrent.downloadSpeed > 0) {
        parts.add(_formatSpeed(torrent.downloadSpeed));
      }
    }

    return AnymeXText(
      parts.join(' • '),
      size: 12,
      color: colors.onSurfaceVariant,
    );
  }

  Widget? _buildSearchBar(BuildContext context, int totalCount) {
    if (totalCount <= 5) return null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnymeXSearchBar(
        controller: _searchController,
        hintText: 'Search files...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        onClear: () {
          _searchController.clear();
        },
      ),
    );
  }

  Widget _buildFileList(BuildContext context, List<TorrentFileStat> files) {
    final colors = context.colors;

    final filtered = files.where((file) {
      if (_searchQuery.isEmpty) return true;
      final name = p.basename(file.path).toLowerCase();
      return name.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_file_outlined,
                  size: 48, color: colors.onSurfaceVariant),
              const SizedBox(height: 12),
              AnymeXText(
                _searchQuery.isEmpty ? 'No video files found' : 'No matching files',
                size: 15,
                variant: TextVariant.semiBold,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final file = filtered[index];
        final name = p.basename(file.path);
        final dir = p.dirname(file.path);
        final size = _formatSize(file.length);
        final isSelected =
            widget.controller.currentTorrentFile.value?.id == file.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AnymeXTile(
            title: name,
            subtitle: dir != '.' ? '$dir • $size' : size,
            icon: isSelected
                ? Icons.play_circle_filled_rounded
                : Icons.movie_outlined,
            iconColor: isSelected ? colors.primary : colors.onSurfaceVariant,
            trailing: isSelected
                ? Icon(Icons.check_circle_rounded, color: colors.primary)
                : null,
            showChevron: false,
            borderRadius: BorderRadius.circular(12),
            onTap: () => widget.controller.switchTorrentFile(file),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isVisible = widget.controller.isTorrentFilesPaneOpened.value;
      final files = TorrentService.instance.activeTorrentFiles;

      return EpisodeSidePane(
        isVisible: isVisible,
        onOverlayTap: _closePane,
        child: WatchSettingsPane(
          title: 'Torrent Files',
          subtitle: _buildSubtitle(context),
          onClose: _closePane,
          tabBar: _buildSearchBar(context, files.length),
          child: _buildFileList(context, files),
        ),
      );
    });
  }
}
