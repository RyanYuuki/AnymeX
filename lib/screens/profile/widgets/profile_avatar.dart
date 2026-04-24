import 'dart:io';

import 'package:anymex/models/Service/app_profile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ProfileAvatar extends StatelessWidget {
  final AppProfile profile;
  final double radius;
  final Color? fallbackColor;
  final bool showLocked;

  const ProfileAvatar({
    super.key,
    required this.profile,
    this.radius = 28,
    this.fallbackColor,
    this.showLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showLocked) {
      return CircleAvatar(
        radius: radius,
        backgroundColor:
            fallbackColor ?? Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.lock_rounded,
          size: radius * 0.6,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (profile.avatarPath.isNotEmpty) {
      final file = File(profile.avatarPath);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundColor:
              fallbackColor ?? Theme.of(context).colorScheme.primaryContainer,
          backgroundImage: FileImage(file),
        );
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor:
          fallbackColor ?? Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        profile.initials,
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

Future<String?> pickAndSaveProfileImage() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowCompression: true,
    compressionQuality: 85,
  );

  if (result == null || result.files.isEmpty) return null;

  final pickedFile = result.files.first;
  if (pickedFile.path == null) return null;

  final srcFile = File(pickedFile.path!);
  if (!srcFile.existsSync()) return null;

  try {
    final appDir = await getApplicationDocumentsDirectory();
    final profilesDir = Directory(p.join(appDir.path, 'profile_avatars'));
    if (!profilesDir.existsSync()) {
      profilesDir.createSync(recursive: true);
    }

    final ext = p.extension(pickedFile.name).toLowerCase();
    final destPath = p.join(
      profilesDir.path,
      '${DateTime.now().millisecondsSinceEpoch}$ext',
    );

    final destFile = await srcFile.copy(destPath);
    return destFile.path;
  } catch (e) {
    debugPrint('Error saving profile image: $e');
    return null;
  }
}
