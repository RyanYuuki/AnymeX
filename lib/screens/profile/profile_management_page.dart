import 'package:anymex/controllers/profile/profile_manager.dart';
import 'package:anymex/controllers/services/backup_restore/backup_restore_service.dart';
import 'package:anymex/models/Service/app_profile.dart';
import 'package:anymex/screens/profile/profile_creation_page.dart';
import 'package:anymex/screens/profile/widgets/profile_avatar.dart';
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
            if (autoStartId != null && autoStartId.isNotEmpty) ...[
              _buildTile(
                icon: Icons.auto_awesome_rounded,
                title: 'Auto-start Profile',
                subtitle: 'Profile "${profiles.firstWhereOrNull((p) => p.id == autoStartId)?.name ?? "Unknown"}" opens automatically',
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
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                '${profiles.length} / ${kMaxProfiles} Profiles',
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
                              color: colorScheme.primary.withOpacity(0.1),
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
                                  color:
                                      theme.onSurface.withOpacity(0.4))),
                      ],
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
                  const PopupMenuItem(
                      value: 'change_avatar',
                      child: Text('Change Avatar')),
                  const PopupMenuItem(
                      value: 'pin', child: Text('Set / Change PIN')),
                  if (profile.hasPin)
                    const PopupMenuItem(
                        value: 'remove_pin', child: Text('Remove PIN')),
                  const PopupMenuItem(
                      value: 'export', child: Text('Export Data')),
                  if (!isCurrent) ...[
                    const PopupMenuItem(
                        value: 'switch',
                        child: Text('Switch to Profile')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Profile',
                            style: TextStyle(color: Colors.red))),
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
          MaterialPageRoute(
              builder: (_) => const ProfileCreationPage()),
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
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Future<void> _handleAction(
      String action, AppProfile profile, bool isCurrent) async {
    final manager = Get.find<ProfileManager>();

    switch (action) {
      case 'change_avatar':
        _changeAvatar(profile);
        break;
      case 'pin':
        _showPinSetupDialog(profile);
        break;
      case 'remove_pin':
        manager.removePin(profile.id);
        snackBar('PIN removed');
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

  Future<void> _changeAvatar(AppProfile profile) async {
    final path = await pickAndSaveProfileImage();
    if (path != null) {
      final manager = Get.find<ProfileManager>();
      manager.updateProfileAvatar(profile.id, path);
      snackBar('Avatar updated');
    }
  }

  Future<void> _switchToProfile(AppProfile profile) async {
    if (profile.hasPin) {
      final pinController = TextEditingController();
      final colorScheme = Theme.of(context).colorScheme;
      final success = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Enter PIN for "${profile.name}"',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface),
          ),
          content: TextField(
            controller: pinController,
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
                final manager = Get.find<ProfileManager>();
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
              child: const Text('Unlock'),
            ),
          ],
        ),
      );
      pinController.dispose();
      if (success != true) return;
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  Future<void> _exportProfile(AppProfile profile) async {
    try {
      final backupService = Get.find<BackupRestoreService>();
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
      Get.find<BackupRestoreService>().isBackingUp.value = false;
      snackBar('Export failed: $e');
    }
  }

  Future<void> _confirmDelete(AppProfile profile) async {
    final colorScheme = Theme.of(context).colorScheme;

    final shouldExport = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainer,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.download_rounded,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
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
            onPressed: () async {
              Navigator.pop(ctx, true);
            },
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
