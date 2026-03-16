import 'dart:io';

import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

enum _InitStage {
  idle,
  downloading,
  moving,
  initAniyomi,
  initCloudstream,
  done
}

class PluginInitDialog extends StatefulWidget {
  const PluginInitDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      barrierDismissible: false,
      builder: (_) => const PluginInitDialog(),
    );
  }

  @override
  State<PluginInitDialog> createState() => _PluginInitDialogState();
}

class _PluginInitDialogState extends State<PluginInitDialog>
    with TickerProviderStateMixin {
  _InitStage _stage = _InitStage.idle;
  double _downloadProgress = 0;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  String? _errorMsg;

  String get pluginUrl =>
      "https://github.com/RyanYuuki/AnymeX/assets/anymex_runtime_bridge.apk";

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkScale;

  final List<({String label, _InitStage stage})> _steps = [
    (label: 'Moving plugin to app storage', stage: _InitStage.moving),
    (label: 'Initializing Aniyomi', stage: _InitStage.initAniyomi),
    (label: 'Initializing Cloudstream', stage: _InitStage.initCloudstream),
    (label: 'Plugin loaded successfully', stage: _InitStage.done),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _checkScale = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() {
      _stage = _InitStage.downloading;
      _errorMsg = null;
      _downloadProgress = 0;
      _downloadedBytes = 0;
      _totalBytes = 0;
    });

    try {
      final request = http.Request('GET', Uri.parse(pluginUrl));
      final response = await http.Client().send(request);

      _totalBytes = response.contentLength ?? 0;

      final dir = await getApplicationDocumentsDirectory();
      final fileName = pluginUrl.split('/').last;
      final file = File('${dir.path}/$fileName');
      final sink = file.openWrite();

      int received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        _downloadedBytes = received;
        if (_totalBytes > 0) {
          setState(() =>
              _downloadProgress = (received / _totalBytes).clamp(0.0, 1.0));
        }
      }
      await sink.flush();
      await sink.close();

      await _runPostDownloadSteps(file);
    } catch (e) {
      if (mounted) {
        setState(() {
          _stage = _InitStage.idle;
          _errorMsg = 'Download failed: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _runPostDownloadSteps(File downloadedFile) async {
    for (final step in _steps) {
      if (!mounted) return;
      setState(() => _stage = step.stage);
      await Future.delayed(const Duration(milliseconds: 900));
    }

    if (mounted) {
      _checkCtrl.forward();
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Dialog(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(c),
            const SizedBox(height: 20),
            _buildPluginChips(c),
            const SizedBox(height: 20),
            if (_stage == _InitStage.idle) _buildIdleBody(c),
            if (_stage == _InitStage.downloading) _buildDownloadBody(c),
            if (_stage != _InitStage.idle && _stage != _InitStage.downloading)
              _buildStepsBody(c),
            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
              _buildError(c),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme c) {
    return Row(children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: c.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.extension_outlined,
            size: 20, color: c.onPrimaryContainer),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Plugin Setup Required',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: c.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            'Aniyomi & Cloudstream not initialized',
            style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
          ),
        ]),
      ),
      if (_stage == _InitStage.idle || _errorMsg != null)
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close_rounded, size: 20, color: c.onSurfaceVariant),
          style: IconButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
    ]);
  }

  Widget _buildPluginChips(ColorScheme c) {
    return Row(children: [
      _pluginChip(c, Icons.video_library_outlined, 'Aniyomi'),
      const SizedBox(width: 8),
      _pluginChip(c, Icons.cloud_outlined, 'Cloudstream'),
    ]);
  }

  Widget _pluginChip(ColorScheme c, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: c.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: c.onSurfaceVariant)),
      ]),
    );
  }

  Widget _buildIdleBody(ColorScheme c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surfaceContainerLow.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.outlineVariant.withOpacity(0.4)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline_rounded, size: 16, color: c.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'To use Aniyomi and Cloudstream extensions, you need to download and install the plugin. This is a one-time setup.',
              style: TextStyle(fontSize: 12.5, color: c.onSurface, height: 1.5),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: c.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: c.outlineVariant),
              ),
            ),
            child: const Text('Later',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _startDownload,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download & Install',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
              elevation: 0,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    ]);
  }

  Widget _buildDownloadBody(ColorScheme c) {
    final hasSize = _totalBytes > 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        ScaleTransition(
          scale: _pulse,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.download_rounded, size: 16, color: c.primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Downloading plugin…',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.onSurface)),
            const SizedBox(height: 2),
            Text(
              hasSize
                  ? '${_formatBytes(_downloadedBytes)} / ${_formatBytes(_totalBytes)}'
                  : _formatBytes(_downloadedBytes),
              style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
            ),
          ]),
        ),
        Text(
          '${(_downloadProgress * 100).toStringAsFixed(0)}%',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: c.primary),
        ),
      ]),
      const SizedBox(height: 14),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: hasSize ? _downloadProgress : null,
          minHeight: 6,
          backgroundColor: c.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(c.primary),
        ),
      ),
    ]);
  }

  Widget _buildStepsBody(ColorScheme c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _steps.map((step) {
        final stageIndex = _steps.indexOf(step);
        final currentIndex = _steps.indexWhere((s) => s.stage == _stage);
        final isDone = stageIndex < currentIndex ||
            (_stage == _InitStage.done && stageIndex <= currentIndex);
        final isActive = step.stage == _stage;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildStepRow(c, step.label, isDone, isActive),
        );
      }).toList(),
    );
  }

  Widget _buildStepRow(
      ColorScheme c, String label, bool isDone, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? c.primaryContainer.withOpacity(0.35)
            : isDone
                ? c.surfaceContainerLow.withOpacity(0.4)
                : c.surfaceContainerLow.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? c.primary.withOpacity(0.4)
              : c.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(children: [
        SizedBox(
          width: 22,
          height: 22,
          child: isDone
              ? ScaleTransition(
                  scale: _checkScale,
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.check_rounded, size: 13, color: c.onPrimary),
                  ),
                )
              : isActive
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: c.primary),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: c.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: c.outlineVariant.withOpacity(0.5)),
                      ),
                    ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? c.onSurface
                  : isDone
                      ? c.onSurface.withOpacity(0.7)
                      : c.onSurfaceVariant,
            ),
          ),
        ),
        if (isDone && label == 'Plugin loaded successfully') ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Done',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.onPrimary)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildError(ColorScheme c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.error.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, size: 16, color: c.error),
        const SizedBox(width: 10),
        Expanded(
          child: Text(_errorMsg!,
              style: TextStyle(fontSize: 12, color: c.onErrorContainer)),
        ),
        TextButton(
          onPressed: _startDownload,
          style: TextButton.styleFrom(
              foregroundColor: c.error,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: const Text('Retry',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
