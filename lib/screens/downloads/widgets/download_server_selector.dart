import 'package:anymex/screens/downloads/controller/download_controller.dart';
import 'package:anymex/utils/download_engine.dart';
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/video.dart' as hive;
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class DownloadServerSelector extends StatefulWidget {
  final List<Episode> episodes;
  final Source source;
  final OfflineMedia media;

  const DownloadServerSelector({
    super.key,
    required this.episodes,
    required this.source,
    required this.media,
  });

  static Future<bool> show(
    BuildContext context, {
    required List<Episode> episodes,
    required Source source,
    required OfflineMedia media,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DownloadServerSelector(
        episodes: episodes,
        source: source,
        media: media,
      ),
    );
    return result ?? false;
  }

  @override
  State<DownloadServerSelector> createState() => _DownloadServerSelectorState();
}

class _DownloadServerSelectorState extends State<DownloadServerSelector> {
  final _servers = <hive.Video>[].obs;
  final _isLoading = true.obs;
  final _errorMsg = Rxn<String>();
  final _selectedQuality = RxnString();

  @override
  void initState() {
    super.initState();
    _fetchServers();
  }

  Future<void> _fetchServers() async {
    _isLoading.value = true;
    _errorMsg.value = null;
    _servers.clear();
    _selectedQuality.value = null;
    try {
      if (widget.episodes.isEmpty) {
        throw Exception('No episodes selected for download.');
      }
      
      final firstEp = widget.episodes.first;
      final deEpisode = DEpisode(
        episodeNumber: firstEp.number,
        url: firstEp.link,
        sortMap: firstEp.sortMap.isEmpty ? null : firstEp.sortMap,
      );
      final token =
          'dl_scrape_${DateTime.now().millisecondsSinceEpoch}_${firstEp.number}';

      final videoStream = widget.source.methods.getVideoListStream(deEpisode,
          parameters: SourceParams(cancelToken: token));

      if (videoStream != null) {
        await for (final v in videoStream) {
          final nextVideo = hive.Video.fromVideo(v);
          final exists = _servers.any((existing) =>
              existing.quality == nextVideo.quality &&
              existing.originalUrl == nextVideo.originalUrl);
          if (!exists) {
            _servers.add(nextVideo);
            if (_selectedQuality.value == null) {
              _selectedQuality.value = nextVideo.quality;
            }
          }
        }
      } else {
        final rawVideos = await widget.source.methods.getVideoList(deEpisode,
            parameters: SourceParams(cancelToken: token));
        final vids = rawVideos.map((v) => hive.Video.fromVideo(v)).toList();
        _servers.value = vids;
        if (vids.isNotEmpty) {
          _selectedQuality.value = vids.first.quality;
        }
      }
    } catch (e, s) {
      _errorMsg.value = e.toString();
      print('Error fetching servers: $e - $s');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _startDownload() async {
    final downloadController = Get.find<DownloadController>();
    if (_selectedQuality.value == null) return;
    Navigator.pop(context, true);
    await downloadController.enqueueDownloadBatch(
      episodes: widget.episodes,
      source: widget.source,
      media: widget.media,
      preferredQuality: _selectedQuality.value!,
    );
    snackBar(
      'Downloading ${widget.episodes.length} episode${widget.episodes.length != 1 ? 's' : ''}...',
      title: 'Download Started',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(theme),
          _buildHeader(theme),
          const Divider(height: 1, thickness: 0.5),
          Flexible(child: _buildBody(theme)),
          _buildFooter(theme),
        ],
      ),
    );
  }

  Widget _buildHandle(ColorScheme theme) => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        decoration: BoxDecoration(
          color: theme.onSurface.opaque(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
      );

  Widget _buildHeader(ColorScheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryContainer.opaque(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(HugeIcons.strokeRoundedPlay,
                size: 20, color: theme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AnymexText(
                    text: 'Choose Quality',
                    variant: TextVariant.bold,
                    size: 16),
                AnymexText(
                  text: 'Fetching from first episode · auto-matched for batch',
                  size: 12,
                  color: theme.onSurface.opaque(0.5),
                ),
              ],
            ),
          ),
          AnymexOnTap(
            onTap: () => Navigator.pop(context),
            child:
                Icon(Icons.close_rounded, color: theme.onSurface.opaque(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme theme) {
    return Obx(() {
      if (_isLoading.value && _servers.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExpressiveLoadingIndicator(),
              SizedBox(height: 16),
              Text('Fetching available servers...',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              SizedBox(height: 6),
              Text('This may take up to 30 seconds',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      }

      if (_errorMsg.value != null) {
        return Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: theme.error.opaque(0.6)),
              const SizedBox(height: 12),
              const AnymexText(
                  text: 'Failed to fetch servers',
                  variant: TextVariant.semiBold,
                  size: 15),
              const SizedBox(height: 6),
              Text(_errorMsg.value!,
                  style: TextStyle(color: theme.error, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              AnymexOnTap(
                onTap: _fetchServers,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.primaryContainer.opaque(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.primary.opaque(0.4)),
                  ),
                  child:
                      AnymexText(text: 'Retry', size: 14, color: theme.primary),
                ),
              ),
            ],
          ),
        );
      }

      if (_servers.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 48, color: theme.onSurface.opaque(0.2)),
              const SizedBox(height: 12),
              AnymexText(
                  text: 'No servers available',
                  variant: TextVariant.semiBold,
                  size: 15,
                  color: theme.onSurface.opaque(0.4)),
            ],
          ),
        );
      }

      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.45,
        ),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          shrinkWrap: true,
          itemCount: _servers.length + (_isLoading.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _servers.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: ExpressiveLoadingIndicator()),
                    const SizedBox(width: 8),
                    AnymexText(
                        text: 'Scanning for more servers...',
                        size: 12,
                        color: theme.onSurface.opaque(0.5)),
                  ],
                ),
              );
            }

            final video = _servers[index];
            final quality = video.quality ?? 'Unknown';
            return Obx(() {
              final isSelected = _selectedQuality.value == quality;
              final linkType =
                  detectLinkType(video.url ?? video.originalUrl ?? '');
              final isHls = linkType == VideoLinkType.hls;

              return AnymexOnTap(
                  onTap: () => _selectedQuality.value = quality,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.primaryContainer.opaque(0.35)
                          : theme.surfaceContainer.opaque(0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? theme.primary.opaque(0.5)
                            : theme.outline.opaque(0.15),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isSelected ? theme.primary : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? theme.primary
                                  : theme.outline.opaque(0.4),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(Icons.check_rounded,
                                  size: 14, color: theme.onPrimary)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: AnymexText(
                            text: quality,
                            variant: TextVariant.semiBold,
                            size: 14,
                            color: isSelected ? theme.primary : theme.onSurface,
                          ),
                        ),
                        if (isHls)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: const Text('HLS',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.3)),
                            ),
                            child: const Text('Direct',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ));
            });
          },
        ),
      );
    });
  }

  Widget _buildFooter(ColorScheme theme) {
    return Obx(() {
      final canDownload = _selectedQuality.value != null && _servers.isNotEmpty;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: AnymexOnTap(
            onTap: canDownload ? _startDownload : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: canDownload ? theme.primary : theme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(HugeIcons.strokeRoundedDownload04,
                      size: 20,
                      color: canDownload
                          ? theme.onPrimary
                          : theme.onSurface.opaque(0.4)),
                  const SizedBox(width: 8),
                  AnymexText(
                    text: canDownload
                        ? 'Download (${widget.episodes.length} ep${widget.episodes.length != 1 ? 's' : ''}) · ${_selectedQuality.value}'
                        : 'Loading servers...',
                    size: 14,
                    variant: TextVariant.semiBold,
                    color: canDownload
                        ? theme.onPrimary
                        : theme.onSurface.opaque(0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
