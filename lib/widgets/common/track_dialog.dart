import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

Future<bool?> showTrackingDialog(BuildContext context, {String? dbId, bool isManga = false}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => TrackingDialog(dbId: dbId, isManga: isManga),
  );
}

class TrackingDialog extends StatefulWidget {
  final String? dbId;
  final bool isManga;
  const TrackingDialog({super.key, this.dbId, this.isManga = false});

  @override
  State<TrackingDialog> createState() => _TrackingDialogState();
}

class _TrackingDialogState extends State<TrackingDialog> {
  bool _rememberChoice = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnymeXDialog(
      confirmText: 'Track',
      cancelText: 'Not now',
      confirmResultGetter: () {
        if (_rememberChoice && widget.dbId != null) {
          DynamicKeys.trackingPermission.set<bool>(widget.dbId!, true);
        }
        return true;
      },
      cancelResultGetter: () {
        if (_rememberChoice && widget.dbId != null) {
          DynamicKeys.trackingPermission.set<bool>(widget.dbId!, false);
        }
        return false;
      },
      onConfirm: () {},
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.opaque(0.2, iReallyMeanIt: true),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_add_rounded,
              size: 32,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const AnymeXText(
            text: 'Track your progress?',
            size: 18,
            variant: TextVariant.bold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          AnymeXText(
            text: widget.isManga
                ? 'Sync your reading progress with AniList and MyAnimeList'
                : 'Sync your watch progress with AniList and MyAnimeList',
            size: 13,
            color: colors.onSurface.opaque(0.6, iReallyMeanIt: true),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (widget.dbId != null)
            AnymeXTile.checkbox(
              title: 'Remember my choice',
              value: _rememberChoice,
              onChanged: (val) {
                setState(() {
                  _rememberChoice = val;
                });
              },
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
        ],
      ),
    );
  }
}
