import 'package:anymex/controllers/sync/gist_sync_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:url_launcher/url_launcher.dart';

class ProgressSyncSection extends StatelessWidget {
  const ProgressSyncSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<GistSyncController>()) {
      Get.put(GistSyncController(), permanent: true);
    }
    final ctrl = Get.find<GistSyncController>();
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: AnymexText(
            text: 'PROGRESS SYNC',
            variant: TextVariant.bold,
            color: colors.onSurfaceVariant.withOpacity(0.7),
            size: 12,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: AnymexText(
            text: 'Resume exactly where you left off across all your devices. '
                'Stored in a private GitHub Gist — data never leaves your account.',
            color: colors.onSurfaceVariant.withOpacity(0.55),
            size: 11,
          ),
        ),
        _SyncCard(ctrl: ctrl),
      ],
    );
  }
}

class _SyncCard extends StatelessWidget {
  final GistSyncController ctrl;
  const _SyncCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Obx(() {
      final connected = ctrl.isConnected.value;
      final syncing = ctrl.isSyncing.value;
      final authenticating = ctrl.isAuthenticating.value;
      final syncEnabled = ctrl.syncEnabled.value;
      final lastSync = ctrl.lastSyncTime.value;
      final username = ctrl.githubUsername.value;
      final isBusy = syncing || authenticating;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: connected
                ? [
                    colors.primary.withOpacity(0.12),
                    colors.surfaceContainer.withOpacity(0.4),
                  ]
                : [
                    colors.surfaceContainer.withOpacity(0.4),
                    colors.surfaceContainerHighest.withOpacity(0.4),
                  ],
          ),
          border: Border.all(
            color: connected
                ? colors.primary.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: isBusy
                    ? null
                    : () {
                        if (connected) {
                          _showManageSheet(context, ctrl);
                        } else {
                          _showLoginSheet(context, ctrl);
                        }
                      },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _StatusIcon(
                          colors: colors,
                          connected: connected,
                          busy: isBusy),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AnymexText(
                              text: 'GitHub Gist Sync',
                              variant: TextVariant.bold,
                              size: 16,
                            ),
                            const SizedBox(height: 4),
                            AnymexText(
                              text: _subtitle(connected, syncing,
                                  authenticating, lastSync,
                                  username: username),
                              color: connected
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                              size: 12,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: connected
                              ? colors.primary
                              : colors.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          connected ? Icons.cloud_done : Icons.cloud_upload,
                          color: connected
                              ? colors.onPrimary
                              : colors.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (connected)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20)
                      .copyWith(bottom: 12),
                  child: Row(
                    children: [
                      Icon(IconlyLight.tick_square,
                          size: 18, color: colors.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnymexText(
                          text: 'Auto-sync while watching / reading',
                          size: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Switch(
                        value: syncEnabled,
                        onChanged: (v) => ctrl.syncEnabled.value = v,
                        activeColor: colors.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  String _subtitle(
    bool connected,
    bool syncing,
    bool authenticating,
    DateTime? lastSync, {
    String? username,
  }) {
    if (authenticating) return 'Waiting for GitHub authorisation…';
    if (!connected) return 'Tap to connect with GitHub';
    if (syncing) return 'Syncing…';
    final name = username != null ? '@$username' : 'Connected';
    if (lastSync == null) return '$name · waiting for first sync';
    final diff = DateTime.now().difference(lastSync);
    if (diff.inSeconds < 60) return '$name · synced just now';
    if (diff.inMinutes < 60) return '$name · synced ${diff.inMinutes}m ago';
    return '$name · synced ${diff.inHours}h ago';
  }
  
  void _showLoginSheet(BuildContext context, GistSyncController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _DeviceFlowSheet(ctrl: ctrl),
    );
  }

  void _showManageSheet(BuildContext context, GistSyncController ctrl) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnymexText(
              text: 'Manage Progress Sync',
              variant: TextVariant.bold,
              size: 18,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(IconlyLight.logout, color: colors.error),
              title: Text('Sign out',
                  style: TextStyle(color: colors.error)),
              subtitle: const Text('Progress sync will be disabled'),
              onTap: () {
                ctrl.signOut();
                Navigator.pop(ctx);
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: colors.surfaceContainer,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceFlowSheet extends StatefulWidget {
  final GistSyncController ctrl;
  const _DeviceFlowSheet({required this.ctrl});

  @override
  State<_DeviceFlowSheet> createState() => _DeviceFlowSheetState();
}

class _DeviceFlowSheetState extends State<_DeviceFlowSheet> {
  GistDeviceCodeInfo? _info;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    if (widget.ctrl.isAuthenticating.value) {
      widget.ctrl.cancelDeviceFlow();
    }
    super.dispose();
  }

  Future<void> _start() async {
    final info = await widget.ctrl.startDeviceFlow();
    if (mounted) {
      setState(() {
        _info = info;
        _started = true;
      });
    }

    ever(widget.ctrl.isConnected, (connected) {
      if (connected && mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Obx(() {
        final error = widget.ctrl.authError.value;
        final authenticating = widget.ctrl.isAuthenticating.value;

        if (error != null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: colors.error, size: 48),
              const SizedBox(height: 12),
              AnymexText(
                text: error,
                color: colors.error,
                size: 14,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    widget.ctrl.authError.value = null;
                    _started = false;
                    _start();
                  },
                  child: const Text('Try Again'),
                ),
              ),
            ],
          );
        }

        if (!_started || _info == null) {
          return const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 32),
              CircularProgressIndicator(),
              SizedBox(height: 16),
              AnymexText(text: 'Connecting to GitHub…'),
              SizedBox(height: 32),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AnymexText(
              text: 'Connect with GitHub',
              variant: TextVariant.bold,
              size: 18,
            ),
            const SizedBox(height: 16),

            _StepRow(
              number: '1',
              label: 'Open this URL in your browser:',
            ),
            const SizedBox(height: 8),
            _UrlButton(url: _info!.verificationUri, colors: colors),
            const SizedBox(height: 16),
            _StepRow(number: '2', label: 'Enter this code:'),
            const SizedBox(height: 8),
            _CodeBox(code: _info!.userCode, colors: colors),
            const SizedBox(height: 20),

            if (authenticating)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: colors.primary),
                  ),
                  const SizedBox(width: 10),
                  AnymexText(
                    text: 'Waiting for authorisation…',
                    color: colors.onSurfaceVariant,
                    size: 13,
                  ),
                ],
              ),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  widget.ctrl.cancelDeviceFlow();
                  Navigator.pop(context);
                },
                child: Text('Cancel',
                    style: TextStyle(color: colors.onSurfaceVariant)),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String label;
  const _StepRow({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number,
                style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 10),
        AnymexText(text: label, size: 13),
      ],
    );
  }
}

class _UrlButton extends StatelessWidget {
  final String url;
  final dynamic colors;
  const _UrlButton({required this.url, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.primary.withOpacity(0.3)),
        ),
        child: Text(
          url,
          style: TextStyle(
            color: colors.primary,
            fontSize: 14,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  final String code;
  final dynamic colors;
  const _CodeBox({required this.code, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.primary.withOpacity(0.4), width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              code,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colors.primary,
                letterSpacing: 6,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.copy, size: 18, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final dynamic colors;
  final bool connected;
  final bool busy;
  const _StatusIcon(
      {required this.colors, required this.connected, required this.busy});

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return SizedBox(
        width: 56,
        height: 56,
        child: CircularProgressIndicator(
            strokeWidth: 2.5, color: colors.primary),
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: connected
            ? colors.primary.withOpacity(0.15)
            : colors.surfaceContainerHighest.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.cloud_sync,
        color: connected ? colors.primary : colors.onSurfaceVariant,
        size: 28,
      ),
    );
  }
}
