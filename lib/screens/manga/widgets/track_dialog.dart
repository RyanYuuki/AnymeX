import 'package:anymex/widgets/common/track_dialog.dart' as shared;
import 'package:flutter/material.dart';

Future<bool?> showTrackingDialog(BuildContext context, {String? dbId}) {
  return shared.showTrackingDialog(context, dbId: dbId, isManga: true);
}
