import 'package:anymex/controllers/services/backup_restore/backup_restore_service.dart';
import 'package:anymex/controllers/sync/progress_sync_section.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/screens/settings/sub_settings/widgets/backup_and_restore_widgets.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
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

  Future<void> _handleBackup() async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool usePassword = false;
    bool backupSettings = true;
    bool backupAuthTokens = false;
    bool hasSelected = false;

    await showDialog(
      context: context,
      builder: (context) => BackupPasswordDialog(
        passwordController: passwordController,
        confirmPasswordController: confirmPasswordController,
        onConfirm: (usePass, backSettings, backAuthTokens) {
          usePassword = usePass;
          backupSettings = backSettings;
          backupAuthTokens = backAuthTokens;
          hasSelected = true;
          Navigator.of(context).pop();
        },
      ),
    );

    if (!hasSelected) return;

    setState(() {
      controller.isBackingUp.value = true;
    });

    try {
      String? password;
      if (usePassword && passwordController.text.isNotEmpty) {
        if (passwordController.text != confirmPasswordController.text) {
          snackBar("Passwords don't match!");
          return;
        }
        password = passwordController.text;
      }

      final path = await controller.exportBackupToExternal(
        password: password,
        backupSettings: backupSettings,
        backupAuthTokens: backupAuthTokens,
      );
      if (path != null && mounted) {
        snackBar("Backup saved successfully!");
      }
    } catch (e) {
      if (mounted) {
        snackBar("Backup failed: ${e.toString()}");
      }
    } finally {
      setState(() {
        controller.isBackingUp.value = false;
      });
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    try {
      final path = await controller.pickBackupFile();
      if (path == null) return;

      final isEncrypted = await controller.isBackupEncrypted(path);
      String? password;

      if (isEncrypted) {
        if (!context.mounted) return;
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
          onConfirm: (restoreSettings, restoreAuthTokens) async {
            Get.back();
            setState(() {
              controller.isRestoring.value = true;
            });
            try {
              await controller.restoreBackup(
                path,
                password: password,
                merge: false,
                restoreSettings: restoreSettings,
                restoreAuthTokens: restoreAuthTokens,
              );
              if (mounted) {
                snackBar(
                    "Backup restored successfully! Please restart the app.");
              }
            } catch (e) {
              if (mounted) {
                snackBar("Restore failed: ${e.toString()}");
              }
            } finally {
              setState(() {
                controller.isRestoring.value = false;
              });
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

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Data Management',
      body: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXSectionBuilder(
                        title: 'Current Library',
                        children: [
                          Obx(() {
                            controller.isRestoring.value;
                            return FutureBuilder(
                              future: controller.getLibraryStats(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.done &&
                                    snapshot.data != null) {
                                  return LibraryDashboard(
                                      stats: snapshot.data!);
                                } else {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                              },
                            );
                          }),
                        ],
                      ),
                      AnymeXSectionBuilder(
                        title: 'Actions',
                        children: [
                          AnymeXTile(
                            title: "Create Backup",
                            subtitle: "Secure your library to local storage",
                            icon: Icons.backup_rounded,
                            onTap: _handleBackup,
                          ),
                          AnymeXTile(
                            title: "Restore Data",
                            subtitle: "Import your .anymex backup file",
                            icon: Icons.settings_backup_restore_rounded,
                            onTap: () => _handleRestore(context),
                          ),
                        ],
                      ),
                      AnymeXSectionBuilder(
                        title: 'Cloud Sync',
                        children: const [
                          ProgressSyncSection(),
                        ],
                      ),
                    ],
                  ),
                )
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
