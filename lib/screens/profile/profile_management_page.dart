import 'package:anymex/controllers/profile/profile_manager.dart';
import 'package:anymex/controllers/services/backup_restore/backup_restore_service.dart';
import 'package:anymex/models/Service/app_profile.dart';
import 'package:anymex/screens/profile/profile_creation_page.dart';
import 'package:anymex/screens/profile/widgets/pattern_lock.dart';
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
    final needsLock = !isCurrent && profile.hasLock;

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
                        if (profile.hasLock) ...[
                          const SizedBox(width: 6),
                          Icon(
                            _getLockIcon(profile.profileLockType),
                            size: 14,
                            color: theme.onSurface.withOpacity(0.5),
                          ),
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
                    if (needsLock)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${profile.lockLabel} required to make changes',
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
                        value: 'lock',
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline, size: 18),
                            SizedBox(width: 10),
                            Text('Change Protection'),
                          ],
                        )),
                    if (profile.hasLock)
                      const PopupMenuItem(
                          value: 'remove_lock',
                          child: Row(
                            children: [
                              Icon(Icons.lock_open, size: 18),
                              SizedBox(width: 10),
                              Text('Remove Protection'),
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
                    if (needsLock)
                      PopupMenuItem(
                          value: 'verify',
                          child: Row(
                            children: [
                              Icon(Icons.lock_person, size: 18),
                              SizedBox(width: 10),
                              Text('Enter ${profile.lockLabel} to Manage'),
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
                          value: 'lock',
                          child: Row(
                            children: [
                              Icon(Icons.lock_outline, size: 18),
                              SizedBox(width: 10),
                              Text('Change Protection'),
                            ],
                          )),
                      if (profile.hasLock)
                        const PopupMenuItem(
                            value: 'remove_lock',
                            child: Row(
                              children: [
                                Icon(Icons.lock_open, size: 18),
                                SizedBox(width: 10),
                                Text('Remove Protection'),
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

  IconData _getLockIcon(ProfileLockType type) {
    switch (type) {
      case ProfileLockType.none:
        return Icons.lock_open_rounded;
      case ProfileLockType.pin:
        return Icons.dialpad_rounded;
      case ProfileLockType.password:
        return Icons.password_rounded;
      case ProfileLockType.pattern:
        return Icons.grid_3x3_rounded;
    }
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
    if (!isCurrent && profile.hasLock) {
      if (action == 'verify') {
        final verified = await _showLockVerification(profile);
        if (verified != true) return;
        _showUnlockedMenu(profile);
        return;
      }
      final verified = await _showLockVerification(profile);
      if (verified != true) return;
    }

    switch (action) {
      case 'change_avatar':
        _changeAvatar(profile);
        break;
      case 'lock':
        _showLockSetupDialog(profile);
        break;
      case 'remove_lock':
        _confirmRemoveLock(profile);
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
                leading: Icon(_getLockIcon(profile.profileLockType)),
                title: Text('Change ${profile.lockLabel}'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLockSetupDialog(profile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_open),
                title: Text('Remove ${profile.lockLabel}'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmRemoveLock(profile);
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

  Future<bool?> _showLockVerification(AppProfile profile) async {
    final manager = Get.find<ProfileManager>();

    if (profile.isLocked) {
      final remaining =
          profile.lockedUntil!.difference(DateTime.now()).inMinutes + 1;
      snackBar(
          'Profile is locked. Try again in $remaining minute${remaining != 1 ? 's' : ''}');
      return null;
    }

    switch (profile.profileLockType) {
      case ProfileLockType.pin:
        return _showPinVerification(profile);
      case ProfileLockType.password:
        return _showPasswordVerification(profile);
      case ProfileLockType.pattern:
        return _showPatternVerification(profile);
      case ProfileLockType.none:
        return true;
    }
  }

  Future<bool?> _showPinVerification(AppProfile profile) async {
    final manager = Get.find<ProfileManager>();
    final pinController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    final contentKey = GlobalKey<_PinVerifyContentState>();

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
                    'Enter PIN to continue',
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
          key: contentKey,
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
                contentKey.currentState?.setError('PIN must be at least 4 digits');
                return;
              }
              final result = manager.verifyLock(profile.id, pin);
              if (result == true) {
                Navigator.pop(ctx, true);
              } else if (result == false) {
                final remaining = kMaxLockAttempts -
                    (manager.profiles
                            .firstWhereOrNull((p) => p.id == profile.id)
                            ?.failedAttempts ??
                        0);
                contentKey.currentState?.setError(
                    'Wrong PIN. $remaining attempt${remaining != 1 ? 's' : ''} remaining');
                contentKey.currentState?.clearInput();
              } else {
                Navigator.pop(ctx, false);
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

  Future<bool?> _showPasswordVerification(AppProfile profile) async {
    final manager = Get.find<ProfileManager>();
    final passwordController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    final contentKey = GlobalKey<_PasswordVerifyContentState>();

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
                    'Enter password to continue',
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: _PasswordVerifyContent(
          key: contentKey,
          controller: passwordController,
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
              final password = passwordController.text;
              if (password.isEmpty) {
                contentKey.currentState?.setError('Enter a password');
                return;
              }
              final result = manager.verifyLock(profile.id, password);
              if (result == true) {
                Navigator.pop(ctx, true);
              } else if (result == false) {
                final remaining = kMaxLockAttempts -
                    (manager.profiles
                            .firstWhereOrNull((p) => p.id == profile.id)
                            ?.failedAttempts ??
                        0);
                contentKey.currentState?.setError(
                    'Wrong password. $remaining attempt${remaining != 1 ? 's' : ''} remaining');
                contentKey.currentState?.clearInput();
              } else {
                Navigator.pop(ctx, false);
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
    passwordController.dispose();
    return verified;
  }

  Future<bool?> _showPatternVerification(AppProfile profile) async {
    final manager = Get.find<ProfileManager>();
    final colorScheme = Theme.of(context).colorScheme;
    bool? result;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
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
                        'Draw pattern to continue',
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: PatternLock(
                    onPatternComplete: (pattern) {
                      final patternStr = pattern.join(',');
                      final verifyResult =
                          manager.verifyLock(profile.id, patternStr);
                      if (verifyResult == true) {
                        Navigator.pop(ctx, true);
                      } else if (verifyResult == false) {
                        final remaining = kMaxLockAttempts -
                            (manager.profiles
                                    .firstWhereOrNull(
                                        (p) => p.id == profile.id)
                                    ?.failedAttempts ??
                                0);
                        setDialogState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Wrong pattern. $remaining attempt${remaining != 1 ? 's' : ''} remaining'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        Navigator.pop(ctx, false);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final attempts = manager.profiles
                          .firstWhereOrNull((p) => p.id == profile.id)
                          ?.failedAttempts ?? 0;
                  if (attempts > 0) {
                    return Text(
                      '$attempts / $kMaxLockAttempts attempts',
                      style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 12),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7))),
              ),
            ],
          );
        },
      ),
    );

    return result;
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
    if (profile.hasLock) {
      if (profile.isLocked) {
        final remaining =
            profile.lockedUntil!.difference(DateTime.now()).inMinutes + 1;
        snackBar(
            'Profile is locked. Try again in $remaining minute${remaining != 1 ? 's' : ''}');
        return;
      }
      final verified = await _showLockVerification(profile);
      if (verified != true) return;
    }

    final manager = Get.find<ProfileManager>();
    await manager.switchToProfile(profile.id);

    if (mounted) {
      snackBar('Switched to ${profile.name}');
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showLockSetupDialog(AppProfile profile) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => _LockSetupSheet(profile: profile),
    );
  }

  void _confirmRemoveLock(AppProfile profile) {
    final colorScheme = Theme.of(context).colorScheme;
    final lockLabel = profile.lockLabel;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove $lockLabel from "${profile.name}"?',
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
              manager.removeLock(profile.id);
              snackBar('$lockLabel removed from "${profile.name}"');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Remove $lockLabel',
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
      {super.key, required this.controller, required this.profile});

  @override
  State<_PinVerifyContent> createState() => _PinVerifyContentState();
}

class _PinVerifyContentState extends State<_PinVerifyContent> {
  bool _isError = false;
  String _errorMessage = '';

  void setError(String message) {
    setState(() {
      _isError = true;
      _errorMessage = message;
    });
  }

  void clearInput() {
    widget.controller.clear();
  }

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
            hintText: '\u2022 \u2022 \u2022 \u2022',
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
                  ?.failedAttempts ??
              0;
          if (attempts > 0) {
            return Text(
              '$attempts / $kMaxLockAttempts attempts',
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

class _PasswordVerifyContent extends StatefulWidget {
  final TextEditingController controller;
  final AppProfile profile;
  const _PasswordVerifyContent(
      {super.key, required this.controller, required this.profile});

  @override
  State<_PasswordVerifyContent> createState() =>
      _PasswordVerifyContentState();
}

class _PasswordVerifyContentState extends State<_PasswordVerifyContent> {
  bool _isError = false;
  String _errorMessage = '';

  void setError(String message) {
    setState(() {
      _isError = true;
      _errorMessage = message;
    });
  }

  void clearInput() {
    widget.controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.controller,
          obscureText: true,
          autofocus: true,
          style: TextStyle(
              color: colorScheme.onSurface,
              fontFamily: 'Poppins',
              fontSize: 18),
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: _isError
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide.none,
            ),
            hintText: 'Enter password',
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
          onChanged: (_) => setState(() {
            _isError = false;
            _errorMessage = '';
          }),
          onSubmitted: (_) {
            if (widget.controller.text.isNotEmpty) {
              final parentCtx = context;
              Navigator.of(parentCtx).pop(true);
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
                  ?.failedAttempts ??
              0;
          if (attempts > 0) {
            return Text(
              '$attempts / $kMaxLockAttempts attempts',
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

class _LockSetupSheet extends StatefulWidget {
  final AppProfile profile;
  const _LockSetupSheet({required this.profile});

  @override
  State<_LockSetupSheet> createState() => _LockSetupSheetState();
}

class _LockSetupSheetState extends State<_LockSetupSheet> {
  ProfileLockType _selectedType = ProfileLockType.none;
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  List<int> _firstPattern = [];
  List<int> _confirmedPattern = [];
  bool _patternConfirmed = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _resetInputs() {
    _pinController.clear();
    _passwordController.clear();
    _firstPattern.clear();
    _confirmedPattern.clear();
    _patternConfirmed = false;
    _error = null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = context.colors;
    final isNew = !widget.profile.hasLock;

    return Dialog(
      backgroundColor: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isNew ? 'Set Protection' : 'Change Protection',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Choose how to protect "${widget.profile.name}"',
                style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ProfileLockType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return ChoiceChip(
                    avatar: Icon(
                      _chipIcon(type),
                      size: 16,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withOpacity(0.6),
                    ),
                    label: Text(
                      type == ProfileLockType.none
                          ? 'None'
                          : type == ProfileLockType.pin
                              ? 'PIN'
                              : type == ProfileLockType.password
                                  ? 'Password'
                                  : 'Pattern',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: colorScheme.primary,
                    onSelected: (val) {
                      setState(() {
                        _selectedType = type;
                        _resetInputs();
                      });
                    },
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }).toList(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(_error!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ),
              ],
              if (_selectedType == ProfileLockType.pin) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  autofocus: true,
                  style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 22, letterSpacing: 8),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: isNew ? 'Create PIN' : 'New PIN',
                    labelStyle: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
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
              if (_selectedType == ProfileLockType.password) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  maxLength: 32,
                  autofocus: true,
                  style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 16),
                  decoration: InputDecoration(
                    labelText: isNew ? 'Create Password' : 'New Password',
                    labelStyle: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
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
              if (_selectedType == ProfileLockType.pattern) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _firstPattern.isEmpty
                        ? 'Draw a pattern (min 4 dots)'
                        : _patternConfirmed
                            ? 'Pattern confirmed'
                            : 'Draw pattern again to confirm',
                    style: TextStyle(
                        fontSize: 12,
                        color: _patternConfirmed
                            ? Colors.green.shade400
                            : colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: PatternLock(
                      onPatternComplete: (pattern) {
                        if (pattern.length < 4) {
                          setState(() {
                            _error = 'Connect at least 4 dots';
                          });
                          return;
                        }
                        if (_firstPattern.isEmpty) {
                          setState(() {
                            _firstPattern = pattern;
                            _error = null;
                          });
                        } else {
                          bool same = pattern.length == _firstPattern.length;
                          if (same) {
                            for (int i = 0; i < pattern.length; i++) {
                              if (pattern[i] != _firstPattern[i]) {
                                same = false;
                                break;
                              }
                            }
                          }
                          if (same) {
                            setState(() {
                              _confirmedPattern = pattern;
                              _patternConfirmed = true;
                              _error = null;
                            });
                          } else {
                            setState(() {
                              _firstPattern.clear();
                              _error = 'Patterns do not match. Try again.';
                            });
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.7))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final manager = Get.find<ProfileManager>();
                      setState(() => _error = null);

                      switch (_selectedType) {
                        case ProfileLockType.none:
                          manager.removeLock(widget.profile.id);
                          Navigator.pop(context);
                          snackBar('Protection removed');
                          break;
                        case ProfileLockType.pin:
                          final pin = _pinController.text.trim();
                          if (pin.length < 4 || pin.length > 6) {
                            setState(() => _error = 'PIN must be 4-6 digits');
                            return;
                          }
                          if (!RegExp(r'^\d+$').hasMatch(pin)) {
                            setState(
                                () => _error = 'PIN must be numbers only');
                            return;
                          }
                          manager.setPin(widget.profile.id, pin);
                          Navigator.pop(context);
                          snackBar('PIN ${isNew ? "set" : "updated"} successfully');
                          break;
                        case ProfileLockType.password:
                          final password = _passwordController.text;
                          if (password.length < 4 || password.length > 32) {
                            setState(
                                () => _error = 'Password must be 4-32 characters');
                            return;
                          }
                          manager.setPassword(
                              widget.profile.id, password);
                          Navigator.pop(context);
                          snackBar(
                              'Password ${isNew ? "set" : "updated"} successfully');
                          break;
                        case ProfileLockType.pattern:
                          if (!_patternConfirmed) {
                            setState(() => _error = 'Draw and confirm a pattern first');
                            return;
                          }
                          manager.setPattern(
                              widget.profile.id, _confirmedPattern);
                          Navigator.pop(context);
                          snackBar(
                              'Pattern ${isNew ? "set" : "updated"} successfully');
                          break;
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isNew ? 'Save' : 'Update',
                      style: const TextStyle(
                          fontFamily: 'Poppins', fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _chipIcon(ProfileLockType type) {
    switch (type) {
      case ProfileLockType.none:
        return Icons.lock_open_rounded;
      case ProfileLockType.pin:
        return Icons.dialpad_rounded;
      case ProfileLockType.password:
        return Icons.password_rounded;
      case ProfileLockType.pattern:
        return Icons.grid_3x3_rounded;
    }
  }
}
