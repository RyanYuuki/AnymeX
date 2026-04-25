import 'package:anymex/controllers/profile/profile_manager.dart';
import 'package:anymex/controllers/services/cloud/cloud_auth_service.dart';
import 'package:anymex/controllers/services/cloud/cloud_profile_service.dart';
import 'package:anymex/controllers/services/cloud/cloud_sync_service.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/cloud_encryption.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsCloud extends StatefulWidget {
  const SettingsCloud({super.key});

  @override
  State<SettingsCloud> createState() => _SettingsCloudState();
}

class _SettingsCloudState extends State<SettingsCloud> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoginMode = true;
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authService = Get.find<CloudAuthService>();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.length < 3) {
      _showError('Username must be at least 3 characters');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }

    setState(() => _isLoading = true);

    bool success;
    if (_isLoginMode) {
      success = await authService.login(username: username, password: password);
    } else {
      final confirm = _confirmPasswordController.text;
      if (confirm != password) {
        setState(() => _isLoading = false);
        _showError('Passwords do not match');
        return;
      }
      success = await authService.register(username: username, password: password);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _ensureEncryptionSalt();
      final authService = Get.find<CloudAuthService>();
      if (authService.cloudPassword.value.isEmpty) {
        authService.cloudPassword.value = _passwordController.text;
      }
      _navigateToCloudMode();
    } else {
      _showError(authService.errorMessage.value);
    }
  }

  void _ensureEncryptionSalt() {
    final existingSalt = CloudKeys.encryptionSalt.get<String?>();
    if (existingSalt == null || existingSalt.isEmpty) {
      final salt = CloudEncryption.generateSaltBase64();
      CloudKeys.encryptionSalt.set(salt);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _logout() async {
    final authService = Get.find<CloudAuthService>();
    authService.logout();
  }

  Future<void> _navigateToCloudMode() async {
    final authService = Get.find<CloudAuthService>();
    final manager = Get.find<ProfileManager>();

    authService.unskipCloud();
    authService.cloudMode.value = CloudMode.cloud;
    manager.isProfileReady.value = false;

    try {
      final profileService = Get.find<CloudProfileService>();
      final cloudProfiles = await profileService.listProfiles();
      if (cloudProfiles != null && cloudProfiles.isNotEmpty) {
        manager.profiles.clear();
        await manager.importFromCloud(cloudProfiles);
      } else {
        manager.profiles.clear();
      }
    } catch (_) {
      manager.profiles.clear();
    }

    manager.requestProfileSelection();

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _changePassword() async {
    final authService = Get.find<CloudAuthService>();
    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;

    if (current.isEmpty || newPass.isEmpty) {
      _showError('Both fields are required');
      return;
    }
    if (newPass.length < 8) {
      _showError('New password must be at least 8 characters');
      return;
    }

    setState(() => _isLoading = true);
    final success = await authService.changePassword(
      currentPassword: current,
      newPassword: newPass,
    );
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      _showSuccess('Password changed! Re-sync tokens with new password.');
    } else {
      _showError(authService.errorMessage.value);
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message), backgroundColor: Colors.green.shade700),
    );
  }

  Future<void> _fullSync() async {
    final profileManager = Get.find<ProfileManager>();
    final authService = Get.find<CloudAuthService>();
    final syncService = Get.find<CloudSyncService>();
    final currentProfile = profileManager.currentProfile.value;

    if (currentProfile == null) {
      _showError('No profile selected');
      return;
    }

    if (!authService.isLoggedIn.value) {
      _showError('Not signed in to cloud');
      return;
    }

    final encryptionSalt = CloudKeys.encryptionSalt.get<String?>();
    if (encryptionSalt == null || encryptionSalt.isEmpty) {
      _showError('Encryption salt not set. Please re-login.');
      return;
    }

    setState(() => _isLoading = true);

    final success = await syncService.fullSyncPush(
      localProfileId: currentProfile.id,
      cloudProfileId: currentProfile.id,
      encryptionPassword: authService.cloudPassword.value.isNotEmpty
          ? authService.cloudPassword.value
          : await _askForEncryptionPassword(),
      encryptionSalt: encryptionSalt,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSuccess('Sync complete! All data pushed to cloud.');
    } else {
      _showError('Sync failed: ${syncService.syncStatus.value}');
    }
  }

  Future<String?> _askForEncryptionPassword() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encryption Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Your account password',
            hintText: 'Used to encrypt your auth tokens',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = context.colors.onSurface;

    return Glow(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Cloud Sync'),
        ),
        body: Obx(() {
          final authService = Get.find<CloudAuthService>();
          final syncService = Get.find<CloudSyncService>();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer.opaque(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: authService.isLoggedIn.value
                            ? Colors.green.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        authService.isLoggedIn.value
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        color: authService.isLoggedIn.value
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authService.isLoggedIn.value
                                ? 'Connected as ${authService.username.value}'
                                : 'Not Connected',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: onSurface,
                            ),
                          ),
                          if (authService.isLoggedIn.value)
                            Text(
                              authService.email.value.isNotEmpty
                                  ? authService.email.value
                                  : 'No email set',
                              style: TextStyle(
                                fontSize: 12,
                                color: onSurface.withOpacity(0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (authService.isLoggedIn.value)
                      IconButton(
                        icon: Icon(Icons.logout_rounded,
                            color: onSurface.withOpacity(0.5)),
                        onPressed: _logout,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (!authService.isLoggedIn.value) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        colorScheme.surfaceContainer.opaque(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isLoginMode ? 'Sign In' : 'Create Account',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: onSurface,
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _isLoginMode = !_isLoginMode;
                            }),
                            child: Text(
                              _isLoginMode ? 'Register' : 'Login',
                              style: TextStyle(color: colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _usernameController,
                        style: TextStyle(color: onSurface),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline_rounded,
                              color: onSurface.withOpacity(0.5)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        style: TextStyle(color: onSurface),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline_rounded,
                              color: onSurface.withOpacity(0.5)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: onSurface.withOpacity(0.5),
                            ),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      if (!_isLoginMode) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: !_showPassword,
                          style: TextStyle(color: onSurface),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(Icons.lock_outline_rounded,
                                color: onSurface.withOpacity(0.5)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  _isLoginMode ? 'Sign In' : 'Create Account',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (authService.isLoggedIn.value) ...[
                ListTile(
                  leading: const Icon(Icons.sync_rounded),
                  title: const Text('Sync Now'),
                  subtitle: const Text('Push all data to the cloud'),
                  trailing: syncService.isSyncing.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  onTap: syncService.isSyncing.value
                      ? null
                      : _fullSync,
                ),

                if (syncService.syncStatus.value.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AnymexText(
                      text: syncService.syncStatus.value,
                      size: 12,
                      color: onSurface.withOpacity(0.6),
                    ),
                  ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.key_rounded),
                  title: const Text('Change Password'),
                  subtitle: const Text(
                      'Warning: Tokens must be re-encrypted after'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14),
                  onTap: _showChangePasswordDialog,
                ),

                const Divider(),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16,
                              color: colorScheme.primary.withOpacity(0.8)),
                          const SizedBox(width: 6),
                          Text(
                            'Cloud Sync Info',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: colorScheme.primary.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Profiles, settings, library, and custom lists are synced\n'
                        '• Auth tokens (AniList/MAL/Simkl) are encrypted before upload\n'
                        '• Use your account password as the encryption key\n'
                        '• Max 5 profiles per account',
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface.withOpacity(0.6),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              80.height(),
            ],
          );
        }),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password (min 8 chars)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _changePassword();
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
