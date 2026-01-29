import 'package:anymex/controllers/services/backup_restore/backup_restore_service.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/screens/settings/sub_settings/widgets/backup_and_restore_widgets.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  late final controller = Get.put(BackupRestoreService());

  @override
  void dispose() {
    Get.delete<BackupRestoreService>();
    super.dispose();
  }

  Future<void> _showLoadingDialog(Future<void> Function() task) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(
        statusObs: controller.statusMessage,
        progressObs: controller.isBackingUp.value
            ? controller.backupProgress
            : controller.restoreProgress,
      ),
    );

    try {
      await Future.wait([
        task(),
        Future.delayed(const Duration(seconds: 2)),
      ]);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        snackBar("Error: ${e.toString()}");
      }
      return;
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _handleBackup() async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool usePassword = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BackupPasswordDialog(
        passwordController: passwordController,
        confirmPasswordController: confirmPasswordController,
        onUsePasswordChanged: (value) => usePassword = value,
      ),
    );

    if (result != true) return;

    try {
      String? password;
      if (usePassword && passwordController.text.isNotEmpty) {
        if (passwordController.text != confirmPasswordController.text) {
          snackBar("Passwords don't match!");
          return;
        }
        password = passwordController.text;
      }

      await _showLoadingDialog(() async {
        final path =
            await controller.exportBackupToExternal(password: password);
        if (path != null) {
          if (mounted) {
            snackBar("Backup saved successfully!");
          }
        }
      });
    } catch (e) {
      if (mounted) {
        snackBar("Backup failed: ${e.toString()}");
      }
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    try {
      final path = await controller.pickBackupFile();
      if (path == null) return;

      final isEncrypted = await controller.isBackupEncrypted(path);
      String? password;

      if (isEncrypted) {
        password = await _showPasswordDialog(context);
        if (password == null) return;
      }

      final info = await controller.getBackupInfo(path, password: password);
      if (info == null) {
        snackBar("Invalid backup file or incorrect password");
        return;
      }

      Get.bottomSheet(
        RestorePreviewSheet(
          info: info,
          isEncrypted: isEncrypted,
          onConfirm: () {
            Get.back();
            _showLoadingDialog(() => controller.restoreBackup(path,
                password: password, merge: false));
          },
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    } catch (e) {
      snackBar("Error selecting file: ${e.toString()}");
    }
  }

  Future<String?> _showPasswordDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => PasswordInputDialog(
        controller: passwordController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            const NestedHeader(title: 'Data Management'),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(title: "Current Library"),
                    const SizedBox(height: 16),
                    Obx(() =>
                        LibraryDashboard(stats: controller.getLibraryStats())),
                    const SizedBox(height: 32),
                    const _SectionHeader(title: "Actions"),
                    const SizedBox(height: 16),
                    ActionCard(
                      title: "Create Backup",
                      subtitle: "Secure your library to local storage",
                      icon: Icons.backup_rounded,
                      color: theme.colorScheme.primary,
                      onTap: _handleBackup,
                    ),
                    const SizedBox(height: 16),
                    ActionCard(
                      title: "Restore Data",
                      subtitle: "Import your .anymex backup file",
                      icon: Icons.settings_backup_restore_rounded,
                      color: theme.colorScheme.tertiary,
                      onTap: () => _handleRestore(context),
                    ),
                    const SizedBox(height: 32),
                    _buildLastBackupInfo(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastBackupInfo(ThemeData theme) {
    return Obx(() {
      if (controller.lastBackupPath.value.isEmpty) {
        return const SizedBox.shrink();
      }
      return GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.history, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Last Backup Path",
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12)),
                    Text(
                      controller.lastBackupPath.value.split('/').last,
                      style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      );
    });
  }
}

class BackupPasswordDialog extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final Function(bool) onUsePasswordChanged;

  const BackupPasswordDialog({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onUsePasswordChanged,
  });

  @override
  State<BackupPasswordDialog> createState() => BackupPasswordDialogState();
}

class BackupPasswordDialogState extends State<BackupPasswordDialog> {
  bool _usePassword = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surfaceContainer,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.backup_rounded,
                      color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Backup Options",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Protect your backup",
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: CheckboxListTile(
                value: _usePassword,
                onChanged: (value) {
                  setState(() {
                    _usePassword = value ?? false;
                    widget.onUsePasswordChanged(_usePassword);
                  });
                },
                title: Text(
                  "Password Protect",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  "Add extra security to your backup",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.trailing,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            if (_usePassword) ...[
              const SizedBox(height: 20),
              TextField(
                controller: widget.passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  hintText: "Enter password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: widget.confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  hintText: "Re-enter password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.3),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Create Backup",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }
}
