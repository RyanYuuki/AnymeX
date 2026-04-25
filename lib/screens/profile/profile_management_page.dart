import 'dart:io';

import 'package:anymex/controllers/profile/profile_manager.dart';
import 'package:anymex/controllers/services/backup_restore/backup_restore_service.dart';
import 'package:anymex/controllers/services/cloud/cloud_auth_service.dart';
import 'package:anymex/controllers/services/cloud/cloud_profile_service.dart';
import 'package:anymex/models/Service/app_profile.dart';
import 'package:anymex/screens/profile/profile_creation_page.dart';
import 'package:anymex/screens/profile/widgets/profile_avatar.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key});

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = context.colors;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Profile Management',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: theme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Obx(() {
        final manager = Get.find<ProfileManager>();
        final profiles = manager.profiles;
        final currentId = manager.currentProfileId.value;
        final autoStartId = manager.autoStartProfileId.value;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (autoStartId.isNotEmpty) ...[
              _buildTile(
                icon: Icons.auto_awesome_rounded,
                title: 'Auto-start Profile',
                subtitle:
                    'Profile "${profiles.firstWhereOrNull((p) => p.id == autoStartId)?.name ?? "Unknown"}" opens automatically',
                trailing: TextButton(
                  onPressed: () {
                    manager.resetAutoStart();
                    snackBar('Auto-start disabled');
                  },
                  child: Text('Reset',
                      style: TextStyle(color: colorScheme.primary)),
                ),
                colorScheme: colorScheme,
                theme: theme,
              ),
              const SizedBox(height: 8),
            ],
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                '$profiles.length / $kMaxProfiles Profiles',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: theme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...profiles.map((profile) => _buildProfileCard(
                  profile,
                  profile.id == currentId,
                  colorScheme,
                  theme,
                )),
            const SizedBox(height: 16),
            if (profiles.length < kMaxProfiles)
              _buildAddButton(colorScheme, theme),
          ],
        );
      }),
    );
  }

  Widget _buildProfileCard(
    AppProfile profile,
    bool isCurrent,
    ColorScheme colorScheme,
    dynamic theme,
  ) {
    final needsPin =
        !isCurrent && profile.hasPin;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? colorScheme.primary.withOpacity(0.5)
              : colorScheme.onSurface.withOpacity(0.08),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ProfileAvatar(
                profile: profile,
                radius: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          profile.name,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: theme.onSurface,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                        if (profile.hasPin) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.lock_outline,
                              size: 14,
                              color: theme.onSurface.withOpacity(0.5)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (profile.anilistLinked)
                          _miniBadge('AniList', Colors.blue),
                        if (profile.malLinked)
                          _miniBadge('MAL', Colors.blueAccent),
                        if (profile.simklLinked)
                          _miniBadge('Simkl', Colors.green),
                        if (!profile.anilistLinked &&
                            !profile.malLinked &&
                            !profile.simklLinked)
                          Text('No services',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.onSurface
                                      .withOpacity(0.4))),
                      ],
                    ),
                    if (needsPin)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'PIN required to make changes',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.primary.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: theme.onSurface.withOpacity(0.6)),
                color: colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (value) =>
                    _handleAction(value, profile, isCurrent),
                itemBuilder: (context) => [
                  if (isCurrent) ...[
                    const PopupMenuItem(
                        value: 'change_avatar',
                        child: Row(
                          children: [
                            Icon(Icons.photo_camera, size: 18),
                            SizedBox(width: 10),
                            Text('Change Avatar'),
                          ],
                        )),
                    const PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline, size: 18),
                            SizedBox(width: 10),
                            Text('Set / Change PIN'),
                          ],
                        )),
                    if (profile.hasPin)
                      const PopupMenuItem(
                          value: 'remove_pin',
                          child: Row(
                            children: [
                              Icon(Icons.lock_open, size: 18),
                              SizedBox(width: 10),
                              Text('Remove PIN'),
                            ],
                          )),
                    const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 18),
                            SizedBox(width: 10),
                            Text('Export Data'),
                          ],
                        )),
                  ] else ...[
                    if (needsPin)
                      const PopupMenuItem(
                          value: 'verify',
                          child: Row(
                            children: [
                              Icon(Icons.lock_person, size: 18),
                              SizedBox(width: 10),
                              Text('Enter PIN to Manage'),
                            ],
                          ))
                    else ...[
                      const PopupMenuItem(
                          value: 'change_avatar',
                          child: Row(
                            children: [
                              Icon(Icons.photo_camera, size: 18),
                              SizedBox(width: 10),
                              Text('Change Avatar'),
                            ],
                          )),
                      const PopupMenuItem(
                          value: 'pin',
                          child: Row(
                            children: [
                              Icon(Icons.lock_outline, size: 18),
                              SizedBox(width: 10),
                              Text('Set / Change PIN'),
                            ],
                          )),
                      if (profile.hasPin)
                        const PopupMenuItem(
                            value: 'remove_pin',
                            child: Row(
                              children: [
                                Icon(Icons.lock_open, size: 18),
                                SizedBox(width: 10),
                                Text('Remove PIN'),
                              ],
                            )),
                      const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.download, size: 18),
                              SizedBox(width: 10),
                              Text('Export Data'),
                            ],
                          )),
                    ],
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                        value: 'switch',
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz, size: 18),
                            SizedBox(width: 10),
                            Text('Switch to Profile'),
                          ],
                        )),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Delete Profile',
                                style: TextStyle(color: Colors.red)),
                          ],
                        )),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(ColorScheme colorScheme, dynamic theme) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileCreationPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Add Profile',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required ColorScheme colorScheme,
    required dynamic theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: theme.onSurface,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.onSurface.withOpacity(0.5),
                    )),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _miniBadge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }

  Future<void> _handleAction(
      String action, AppProfile profile, bool isCurrent) async {
    if (!isCurrent && profile.hasPin) {
      if (action == 'verify') {
        final verified = await _showPinVerification(profile);
        if (verified != true) return;
        _showUnlockedMenu(profile);
        return;
      }
      final verified = await _showPinVerification(profile);
      if (verified != true) return;
    }

    switch (action) {
      case 'change_avatar':
        _changeAvatar(profile);
        break;
      case 'pin':
        if (!isCurrent && profile.hasPin) {
          _showChangePinAfterVerify(profile);
        } else {
          _showPinSetupDialog(profile);
        }
        break;
      case 'remove_pin':
        _confirmRemovePin(profile);
        break;
      case 'export':
        _exportProfile(profile);
        break;
      case 'switch':
        await _switchToProfile(profile);
        break;
      case 'delete':
        if (isCurrent) {
          snackBar('Switch to another profile first');
          return;
        }
        _confirmDelete(profile);
        break;
    }
  }

  void _showUnlockedMenu(AppProfile profile) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Change Avatar'),
                onTap: () {
                  Navigator.pop(ctx);
                  _changeAvatar(profile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change PIN'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showChangePinAfterVerify(profile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_open),
                title: const Text('Remove PIN'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmRemovePin(profile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export Data'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportProfile(profile);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showPinVerification(AppProfile profile) async {
    final manager = Get.find<ProfileManager>();

    if (profile.isLocked) {
      final remaining =
          profile.lockedUntil!.difference(DateTime.now()).inMinutes + 1;
      snackBar(
          'Profile is locked. Try again in $remaining minute${remaining != 1 ? 's' : ''}');
      return null;
    }

    final pinController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            ProfileAvatar(profile: profile, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verify ${profile.name}',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface),
                  ),
                  Text(
                    'Enter this profile\'s PIN to continue',
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: _PinVerifyContent(
          controller: pinController,
          profile: profile,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = pinController.text.trim();
              if (pin.length < 4) {
                snackBar('PIN must be at least 4 digits');
                return;
              }
              final result = manager.verifyPin(profile.id, pin);
              if (result == true) {
                Navigator.pop(ctx, true);
              } else {
                snackBar(result == null
                    ? 'Profile is temporarily locked'
                    : 'Wrong PIN');
                if (result == null) Navigator.pop(ctx, false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Verify',
                style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    pinController.dispose();
    return verified;
  }

  Future<void> _changeAvatar(AppProfile profile) async {
    final path = await pickAndSaveProfileImage();
    if (path != null) {
      final manager = Get.find<ProfileManager>();
      manager.updateProfileAvatar(profile.id, path);
      snackBar('Avatar updated');

      try {
        final authService = Get.find<CloudAuthService>();
        if (authService.isLoggedIn.value) {
          final profileService = Get.find<CloudProfileService>();
          final file = File(path);
          if (file.existsSync()) {
            final uploadedUrl = await profileService.uploadAvatar(
              profile.id,
              file,
            );
            if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
              manager.updateProfileAvatar(profile.id, uploadedUrl);
              await profileService.updateProfile(
                profileId: profile.id,
                avatarUrl: uploadedUrl,
              );
            }
          }
        }
      } catch (e) {
        Logger.i('Error uploading avatar to cloud: $e');
      }
    }
  }

  Future<void> _switchToProfile(AppProfile profile) async {
    if (profile.hasPin) {
      if (profile.isLocked) {
        final remaining =
            profile.lockedUntil!.difference(DateTime.now()).inMinutes + 1;
        snackBar(
            'Profile is locked. Try again in $remaining minute${remaining != 1 ? 's' : ''}');
        return;
      }
      final verified = await _showPinVerification(profile);
      if (verified != true) return;
    }

    final manager = Get.find<ProfileManager>();
    await manager.switchToProfile(profile.id);

    if (mounted) {
      snackBar('Switched to ${profile.name}');
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showPinSetupDialog(AppProfile profile) {
    final controller = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    final isNew = !profile.hasPin;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          isNew ? 'Set PIN' : 'Change PIN',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isNew
                  ? 'Set a 4-6 digit PIN for "${profile.name}"'
                  : 'Enter new PIN for "${profile.name}"',
              style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              autofocus: true,
              style: TextStyle(
                  color: colorScheme.onSurface,
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = controller.text.trim();
              if (pin.length < 4 || pin.length > 6) {
                snackBar('PIN must be 4-6 digits');
                return;
              }
              if (!RegExp(r'^\d+$').hasMatch(pin)) {
                snackBar('PIN must contain only numbers');
                return;
              }
              final manager = Get.find<ProfileManager>();
              manager.setPin(profile.id, pin);
              Navigator.pop(ctx);
              snackBar('PIN ${isNew ? "set" : "updated"} successfully');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isNew ? 'Set PIN' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showChangePinAfterVerify(AppProfile profile) {
    final controller = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Change PIN for "${profile.name}"',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter new PIN (4-6 digits)',
              style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              autofocus: true,
              style: TextStyle(
                  color: colorScheme.onSurface,
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = controller.text.trim();
              if (pin.length < 4 || pin.length > 6) {
                snackBar('PIN must be 4-6 digits');
                return;
              }
              if (!RegExp(r'^\d+$').hasMatch(pin)) {
                snackBar('PIN must contain only numbers');
                return;
              }
              final manager = Get.find<ProfileManager>();
              manager.setPin(profile.id, pin);
              Navigator.pop(ctx);
              snackBar('PIN updated successfully');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Update PIN',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmRemovePin(AppProfile profile) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove PIN from "${profile.name}"?',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface),
        ),
        content: Text(
          'This profile will no longer be protected. Anyone can access it.',
          style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final manager = Get.find<ProfileManager>();
              manager.removePin(profile.id);
              snackBar('PIN removed from "${profile.name}"');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Remove PIN',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  BackupRestoreService _getBackupService() {
    if (!Get.isRegistered<BackupRestoreService>()) {
      Get.put(BackupRestoreService());
    }
    return Get.find<BackupRestoreService>();
  }

  Future<void> _exportProfile(AppProfile profile) async {
    final backupService = _getBackupService();
    try {
      backupService.isBackingUp.value = true;

      final path = await backupService.exportBackupToExternal(
        requestPath: true,
        backupSettings: true,
        backupAuthTokens: true,
      );

      backupService.isBackingUp.value = false;

      if (path != null) {
        snackBar('Profile "${profile.name}" exported successfully');
      }
    } catch (e) {
      backupService.isBackingUp.value = false;
      snackBar('Export failed: $e');
    }
  }

  Future<void> _confirmDelete(AppProfile profile) async {
    final colorScheme = Theme.of(context).colorScheme;

    final shouldExport = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete "${profile.name}"?',
          style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'All data for this profile will be permanently deleted, including:\n\n'
              '• Linked accounts (AniList, MAL, Simkl)\n'
              '• Settings & preferences\n'
              '• Watch history & progress\n'
              '• Custom lists\n\n'
              'This action cannot be undone.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.download_rounded,
                      color: Colors.orange, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Would you like to export this profile\'s data before deleting?',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Export & Delete',
                style: TextStyle(color: Colors.orange)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete Without Export'),
          ),
        ],
      ),
    );

    if (shouldExport == null) return;

    if (shouldExport == true) {
      await _exportProfile(profile);
    }

    final manager = Get.find<ProfileManager>();
    await manager.deleteProfile(profile.id,
        currentId: manager.currentProfileId.value);
    snackBar('Profile "${profile.name}" deleted');
  }
}

class _PinVerifyContent extends StatefulWidget {
  final TextEditingController controller;
  final AppProfile profile;
  const _PinVerifyContent(
      {required this.controller, required this.profile});

  @override
  State<_PinVerifyContent> createState() => _PinVerifyContentState();
}

class _PinVerifyContentState extends State<_PinVerifyContent> {
  bool _isError = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          autofocus: true,
          style: TextStyle(
              color: colorScheme.onSurface,
              fontFamily: 'Poppins',
              fontSize: 24,
              letterSpacing: 8),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: _isError
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide.none,
            ),
            hintText: '• • • •',
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.2),
              letterSpacing: 4,
            ),
            counterText: '',
          ),
          onChanged: (_) => setState(() {
            _isError = false;
            _errorMessage = '';
          }),
          onSubmitted: (_) {
            final pin = widget.controller.text.trim();
            if (pin.length >= 4) {
              Navigator.pop(context, true);
            }
          },
        ),
        if (_isError) ...[
          const SizedBox(height: 8),
          Text(_errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
        const SizedBox(height: 4),
        Obx(() {
          final manager = Get.find<ProfileManager>();
          final attempts = manager.profiles
                  .firstWhereOrNull((p) => p.id == widget.profile.id)
                  ?.failedPinAttempts ??
              0;
          if (attempts > 0) {
            return Text(
              '$attempts / $kMaxPinAttempts attempts',
              style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 12),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }
}
