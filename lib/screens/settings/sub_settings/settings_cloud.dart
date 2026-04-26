import 'package:anymex/controllers/profile/profile_manager.dart';
import 'package:anymex/controllers/services/cloud/cloud_auth_service.dart';
import 'package:anymex/controllers/services/cloud/cloud_profile_service.dart';
import 'package:anymex/controllers/services/cloud/cloud_sync_service.dart';
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
  final _emailController = TextEditingController();
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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  // Auth actions
  // ──────────────────────────────────────────────────────────

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
      success = await authService.register(
          username: username,
          password: password,
          email: _emailController.text.trim());
      _emailController.clear();
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _navigateToCloudMode();
    } else {
      _showError(authService.errorMessage.value);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
            'Your cloud data will remain safe on the server. You can sign back in anytime to restore it.\n\nLocal cached data will still be accessible as guest.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final authService = Get.find<CloudAuthService>();
    authService.logout();
    _showSuccess('Signed out successfully');
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
        await manager.importFromCloud(cloudProfiles);
      }
    } catch (_) {
      // Import failed — keep local profiles as-is
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

    if (success) {
      // Server issues new tokens, already handled in service
    }

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      _showSuccess('Password changed successfully.');
    } else {
      _showError(authService.errorMessage.value);
    }
  }

  // ──────────────────────────────────────────────────────────
  // Sync actions
  // ──────────────────────────────────────────────────────────

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

    final cloudId =
        syncService.getCloudProfileId(currentProfile.id) ?? currentProfile.id;

    setState(() => _isLoading = true);

    final success = await syncService.fullSyncPush(
      localProfileId: currentProfile.id,
      cloudProfileId: cloudId,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSuccess('Sync complete! All data pushed and pulled.');
    } else {
      _showError('Sync failed: ${syncService.syncStatus.value}');
    }
  }

  Future<void> _pullFromCloud() async {
    final profileManager = Get.find<ProfileManager>();
    final syncService = Get.find<CloudSyncService>();
    final currentProfile = profileManager.currentProfile.value;

    if (currentProfile == null) {
      _showError('No profile selected');
      return;
    }

    setState(() => _isLoading = true);

    await syncService.pullAllForProfile(currentProfile.id);

    if (!mounted) return;
    setState(() => _isLoading = false);

    _showSuccess('Pull complete! Data downloaded from cloud.');
  }

  // ──────────────────────────────────────────────────────────
  // Account management actions
  // ──────────────────────────────────────────────────────────

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'This will PERMANENTLY delete your account and ALL cloud data, including:'),
            const SizedBox(height: 8),
            Text('• All profiles and their data'),
            Text('• Library (anime, manga, novel)'),
            Text('• Custom lists'),
            Text('• Settings and preferences'),
            Text('• Auth tokens (AniList/MAL/Simkl)'),
            Text('• Watch history and continue watching'),
            const SizedBox(height: 8),
            const Text(
                'This action CANNOT be undone. Local data on this device will remain.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter your password to confirm',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final password = passwordController.text;
    if (password.isEmpty) {
      _showError('Password is required to delete account');
      return;
    }

    setState(() => _isLoading = true);
    final authService = Get.find<CloudAuthService>();
    final success = await authService.deleteAccount(password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSuccess('Account deleted. All cloud data has been removed.');
    } else {
      _showError(authService.errorMessage.value);
    }
  }

  Future<void> _logoutAllDevices() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out All Devices'),
        content: const Text(
            'This will sign out your account on ALL devices. You will need to sign in again on each device.\n\nThe current device will also be signed out.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final authService = Get.find<CloudAuthService>();
    final success = await authService.logoutAllDevices();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      // Also logout locally since all sessions were revoked
      authService.logout();
      _showSuccess('All devices signed out.');
    } else {
      _showError(authService.errorMessage.value);
    }
  }

  Future<void> _showSessions() async {
    final authService = Get.find<CloudAuthService>();

    setState(() => _isLoading = true);
    final sessions = await authService.getSessions();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (sessions == null) {
      _showError('Failed to load sessions');
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Active Sessions'),
        content: SizedBox(
          width: double.maxFinite,
          child: sessions.isEmpty
              ? const Text('No active sessions found.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final isCurrent = session['is_current'] == true;
                    final deviceName =
                        session['device_name'] as String? ?? 'Unknown';
                    final deviceType =
                        session['device_type'] as String? ?? '';
                    final lastActive =
                        session['last_active_at'] as String? ?? '';
                    final deviceId =
                        session['device_id'] as String? ?? '';

                    return ListTile(
                      leading: Icon(
                        _deviceIcon(deviceType),
                        color: isCurrent ? Colors.green : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              deviceName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'This device',
                                style: TextStyle(
                                    color: Colors.green, fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '${_formatSessionDate(lastActive)}\n$deviceType',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      isThreeLine: true,
                      trailing: isCurrent
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              tooltip: 'Sign out this device',
                              onPressed: () async {
                                final ok = await authService
                                    .logoutDevice(deviceId);
                                if (ok) {
                                  Navigator.pop(ctx);
                                  _showSuccess('Device signed out');
                                  // Refresh sessions list
                                  _showSessions();
                                } else {
                                  _showError('Failed to sign out device');
                                }
                              },
                            ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────

  IconData _deviceIcon(String? deviceType) {
    if (deviceType == null) return Icons.devices_rounded;
    final lower = deviceType.toLowerCase();
    if (lower.contains('android')) return Icons.phone_android_rounded;
    if (lower.contains('ios')) return Icons.phone_iphone_rounded;
    if (lower.contains('windows')) return Icons.laptop_windows_rounded;
    if (lower.contains('mac')) return Icons.laptop_mac_rounded;
    if (lower.contains('linux')) return Icons.desktop_windows_rounded;
    return Icons.devices_rounded;
  }

  String _formatSessionDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message), backgroundColor: Colors.green.shade700),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Dialogs
  // ──────────────────────────────────────────────────────────

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Enter the email address associated with your account.'),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSending
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid email address'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSending = true);
                      final authService = Get.find<CloudAuthService>();
                      await authService.forgotPassword(email: email);

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        _showSuccess(
                            'If an account with this email exists, a reset link has been generated.');
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Send Reset Link'),
            ),
          ],
        ),
      ),
    ).then((_) => emailController.dispose());
  }

  void _showChangePasswordDialog() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
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
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password (min 8 chars)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
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

  // ──────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────

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
              // ── Connection status banner ──
              _buildStatusBanner(authService, onSurface),

              const SizedBox(height: 16),

              // ── Auth form (when not logged in) ──
              if (!authService.isLoggedIn.value) ...[
                _buildAuthForm(colorScheme, onSurface, authService),
              ],

              // ── Logged-in sections ──
              if (authService.isLoggedIn.value) ...[
                // Sync actions
                _buildSyncSection(syncService, colorScheme, onSurface),

                const SizedBox(height: 8),

                // Account section
                _buildAccountSection(authService, colorScheme, onSurface),

                const SizedBox(height: 8),

                // Auto-sync toggle
                _buildAutoSyncSection(syncService, colorScheme, onSurface),

                const SizedBox(height: 8),

                // Danger zone
                _buildDangerZone(authService, colorScheme, onSurface),

                const SizedBox(height: 8),

                // Info box
                _buildInfoBox(colorScheme, onSurface),
              ],

              80.height(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatusBanner(CloudAuthService authService, Color onSurface) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: authService.isLoggedIn.value
            ? Colors.green.withOpacity(0.08)
            : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: authService.isLoggedIn.value
              ? Colors.green.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: authService.isLoggedIn.value
                  ? Colors.green.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              authService.isLoggedIn.value
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_off_rounded,
              color:
                  authService.isLoggedIn.value ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authService.isLoggedIn.value
                      ? authService.username.value
                      : 'Not Connected',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: onSurface,
                  ),
                ),
                if (authService.isLoggedIn.value)
                  Text(
                    'Cloud sync active',
                    style: TextStyle(
                      fontSize: 12,
                      color: onSurface.withOpacity(0.5),
                    ),
                  )
                else
                  Text(
                    'Sign in to sync your data across devices',
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
              tooltip: 'Sign Out',
              onPressed: _logout,
            ),
        ],
      ),
    );
  }

  Widget _buildAuthForm(ColorScheme colorScheme, Color onSurface,
      CloudAuthService authService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.opaque(0.3),
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
          if (!_isLoginMode) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: 'Email (optional)',
                hintText: 'For password recovery',
                prefixIcon: Icon(Icons.email_outlined,
                    color: onSurface.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
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
          if (_isLoginMode) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _showForgotPasswordDialog,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(color: colorScheme.primary, fontSize: 13),
                ),
              ),
            ),
          ],
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
                      child: CircularProgressIndicator(strokeWidth: 2),
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
    );
  }

  Widget _buildSyncSection(CloudSyncService syncService,
      ColorScheme colorScheme, Color onSurface) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.opaque(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'SYNC',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.sync_rounded),
            title: const Text('Full Sync'),
            subtitle: const Text('Push all local data, then pull latest from cloud'),
            trailing: syncService.isSyncing.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            onTap: syncService.isSyncing.value ? null : _fullSync,
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_rounded),
            title: const Text('Pull from Cloud'),
            subtitle: const Text('Download all cloud data (replaces local)'),
            trailing: syncService.isSyncing.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_download_rounded),
            onTap: syncService.isSyncing.value ? null : _pullFromCloud,
          ),
          if (syncService.syncStatus.value.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AnymexText(
                text: syncService.syncStatus.value,
                size: 12,
                color: onSurface.withOpacity(0.6),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildAccountSection(CloudAuthService authService,
      ColorScheme colorScheme, Color onSurface) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.opaque(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'ACCOUNT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.key_rounded),
            title: const Text('Change Password'),
            subtitle: const Text('Update your cloud account password'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: _showChangePasswordDialog,
          ),
          ListTile(
            leading: const Icon(Icons.devices_rounded),
            title: const Text('Active Sessions'),
            subtitle: const Text('View and manage devices logged into your account'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: _isLoading ? null : _showSessions,
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign Out All Devices'),
            subtitle: const Text('Revoke all sessions on every device'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: _isLoading ? null : _logoutAllDevices,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildAutoSyncSection(CloudSyncService syncService,
      ColorScheme colorScheme, Color onSurface) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.opaque(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'PREFERENCES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: colorScheme.primary,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.autorenew_rounded),
            title: const Text('Auto-Sync'),
            subtitle: Text(
              syncService.autoSyncEnabled.value
                  ? 'Sync on app resume and pause'
                  : 'Only sync when you tap Sync Now',
            ),
            value: syncService.autoSyncEnabled.value,
            activeColor: colorScheme.primary,
            onChanged: (value) {
              syncService.setAutoSync(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(CloudAuthService authService,
      ColorScheme colorScheme, Color onSurface) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'DANGER ZONE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.red.shade700,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_rounded, color: Colors.red[700]),
            title: Text('Delete Account',
                style: TextStyle(color: Colors.red[700])),
            subtitle: const Text(
                'Permanently delete your account and all cloud data'),
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.red[400]),
            onTap: _isLoading ? null : _deleteAccount,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildInfoBox(ColorScheme colorScheme, Color onSurface) {
    return Container(
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
                  size: 16, color: colorScheme.primary.withOpacity(0.8)),
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
            '• Auth tokens (AniList/MAL/Simkl) are encrypted on the server\n'
            '• Max 5 profiles per account\n'
            '• Cloud is the source of truth — client is cached backup\n'
            '• Auto-sync runs on app resume and pause',
            style: TextStyle(
              fontSize: 12,
              color: onSurface.withOpacity(0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
