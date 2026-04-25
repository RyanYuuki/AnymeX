import 'dart:io';
import 'dart:typed_data';

import 'package:anymex/models/Service/app_profile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
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

  bool _isGif(String path) {
    return path.toLowerCase().endsWith('.gif');
  }

  bool _isNetworkUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

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
      if (_isNetworkUrl(profile.avatarPath)) {
        return _buildNetworkAvatar(context);
      }

      final file = File(profile.avatarPath);
      if (file.existsSync()) {
        if (_isGif(profile.avatarPath)) {
          return ClipOval(
            child: SizedBox(
              width: radius * 2,
              height: radius * 2,
              child: Image.file(
                file,
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallback(context);
                },
              ),
            ),
          );
        }
        return CircleAvatar(
          radius: radius,
          backgroundColor:
              fallbackColor ?? Theme.of(context).colorScheme.primaryContainer,
          backgroundImage: FileImage(file),
        );
      }
    }

    return _buildFallback(context);
  }

  Widget _buildNetworkAvatar(BuildContext context) {
    final size = radius * 2;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          profile.avatarPath,
          fit: BoxFit.cover,
          width: size,
          height: size,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallback(context);
          },
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
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
    final allowedExts = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];

    String destPath;
    if (allowedExts.contains(ext)) {
      destPath = p.join(
        profilesDir.path,
        '${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      await srcFile.copy(destPath);
    } else {
      final bytes = await srcFile.readAsBytes();
      final image = img.decodeImage(Uint8List.fromList(bytes));
      if (image == null) {
        destPath = p.join(
          profilesDir.path,
          '${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await srcFile.copy(destPath);
      } else {
        final jpgBytes = img.encodeJpg(image, quality: 85);
        destPath = p.join(
          profilesDir.path,
          '${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await File(destPath).writeAsBytes(jpgBytes);
      }
    }

    return destPath;
  } catch (e) {
    debugPrint('Error saving profile image: $e');
    return null;
  }
}
