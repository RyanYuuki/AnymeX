import 'dart:io';

import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkScale;

  final List<({String label, String id})> _steps = [
    (label: 'Initializing Aniyomi', id: 'aniyomi'),
    (label: 'Initializing Cloudstream', id: 'cloudstream'),
    (label: 'Plugin loaded successfully', id: 'done'),
  ];

  String _currentManager = '';

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

    Get.find<ExtensionManager>().onRuntimeBridgeInitialization(
      onManagerInitializing: (managerId) {
        if (mounted) setState(() => _currentManager = managerId);
      },
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  Future<void> _startSetup() async {
    await AnymeXRuntimeBridge.setupRuntime();
    if (AnymeXRuntimeBridge.controller.isReady.value) {
      await Get.find<ExtensionManager>().onRuntimeBridgeInitialization();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bridge = AnymeXRuntimeBridge.controller;

    return Obx(() {
      final isDone = bridge.isReady.value;
      if (isDone && !_checkCtrl.isAnimating && _checkCtrl.value == 0) {
        _checkCtrl.forward();
      }

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
              _buildHeader(c, bridge),
              const SizedBox(height: 20),
              _buildPluginChips(c),
              const SizedBox(height: 20),
              if (!bridge.isDownloading.value && !isDone && bridge.error.isEmpty) 
                _buildIdleBody(c),
              if (bridge.isDownloading.value) 
                _buildDownloadBody(c, bridge),
              if ((isDone || bridge.status.value.contains("Finalizing")) && bridge.error.isEmpty)
                _buildStepsBody(c, isDone),
              if (bridge.error.value.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildError(c, bridge),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(ColorScheme c, dynamic bridge) {
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
      if (!bridge.isDownloading.value)
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
              Platform.isAndroid 
                  ? 'To use Aniyomi and Cloudstream extensions, you need to download and install the plugin APK. This is a one-time setup.'
                  : 'To enable Aniyomi support on Windows, you need to download the desktop bridge and a portable Java Runtime (JRE). Total size is approximately 65 MB.',
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
            onPressed: _startSetup,
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

  Widget _buildDownloadBody(ColorScheme c, dynamic bridge) {
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
            Text(bridge.status.value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.onSurface)),
            const SizedBox(height: 2),
            Text(
              bridge.sizeInfo.value,
              style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
            ),
          ]),
        ),
        Text(
          '${(bridge.downloadProgress.value * 100).toStringAsFixed(0)}%',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: c.primary),
        ),
      ]),
      const SizedBox(height: 14),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: bridge.downloadProgress.value > 0 ? bridge.downloadProgress.value : null,
          minHeight: 6,
          backgroundColor: c.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(c.primary),
        ),
      ),
    ]);
  }

  Widget _buildStepsBody(ColorScheme c, bool isReady) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _steps.map((step) {
        final bool isStepDone = isReady || (_currentManager == 'cloudstream' && step.id == 'aniyomi');
        final bool isStepActive = _currentManager == step.id || (isReady && step.id == 'done');
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildStepRow(c, step.label, isStepDone, isStepActive),
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

  Widget _buildError(ColorScheme c, dynamic bridge) {
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
          child: Text(bridge.error.value,
              style: TextStyle(fontSize: 12, color: c.onErrorContainer)),
        ),
        TextButton(
          onPressed: _startSetup,
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
