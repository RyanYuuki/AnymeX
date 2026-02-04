import 'package:anymex/controllers/services/backup_restore/backup_restore_service.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/screens/settings/sub_settings/widgets/backup_and_restore_widgets.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
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

      final path = await controller.exportBackupToExternal(password: password);
      if (path != null && mounted) {
        snackBar("Backup saved successfully!");
      }
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
          onConfirm: () async {
            Get.back();
            try {
              await controller.restoreBackup(path,
                  password: password, merge: false);
              if (mounted) {
                snackBar("Backup restored successfully!");
              }
            } catch (e) {
              if (mounted) {
                snackBar("Restore failed: ${e.toString()}");
              }
            }
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
                  ],
                ),
              ),
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
        color: context.colors.primary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }
}
