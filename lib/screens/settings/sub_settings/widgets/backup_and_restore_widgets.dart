import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';

class PasswordInputDialog extends StatefulWidget {
  final TextEditingController controller;

  const PasswordInputDialog({super.key, required this.controller});

  @override
  State<PasswordInputDialog> createState() => PasswordInputDialogState();
}

class PasswordInputDialogState extends State<PasswordInputDialog> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surfaceContainer,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              "Password Required",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "This backup is encrypted. Please enter the password to continue.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: widget.controller,
              obscureText: _obscurePassword,
              autofocus: true,
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
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.opaque(0.3),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
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
                    onPressed: () {
                      if (widget.controller.text.isNotEmpty) {
                        Navigator.of(context).pop(widget.controller.text);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Unlock",
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

class LoadingDialog extends StatelessWidget {
  final RxString statusObs;
  final RxDouble progressObs;

  const LoadingDialog(
      {super.key, required this.statusObs, required this.progressObs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surfaceContainer,
      elevation: 0,
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Obx(() => Text(
                    statusObs.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600),
                  )),
              const SizedBox(height: 8),
              Obx(() => Text(
                    "${(progressObs.value * 100).toInt()}%",
                    style: TextStyle(
                        color: theme.colorScheme.primary, fontSize: 12),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class RestorePreviewSheet extends StatelessWidget {
  final Map<String, dynamic> info;
  final bool isEncrypted;
  final VoidCallback onConfirm;

  const RestorePreviewSheet({
    super.key,
    required this.info,
    required this.isEncrypted,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = info['date'] as String? ?? 'Unknown Date';

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    "Restore Preview",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (isEncrypted) ...[
                        Icon(
                          Icons.lock,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Encrypted • ",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  UserInfoCard(
                    username: info['username'] ?? 'Unknown User',
                    avatar: info['avatar'],
                    appVersion: info['appVersion'] ?? 'Unknown',
                  ),
                  const SizedBox(height: 24),
                  LibraryStatsCard(
                    animeCount: info['animeCount'] ?? 0,
                    mangaCount: info['mangaCount'] ?? 0,
                    novelCount: info['novelCount'] ?? 0,
                    animeCustomListsCount: info['animeCustomListsCount'] ?? 0,
                    mangaCustomListsCount: info['mangaCustomListsCount'] ?? 0,
                    novelCustomListsCount: info['novelCustomListsCount'] ?? 0,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.opaque(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.error.opaque(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "This will completely replace your current library. All existing data will be overwritten.",
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      "CONFIRM & RESTORE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserInfoCard extends StatelessWidget {
  final String username;
  final String? avatar;
  final String appVersion;

  const UserInfoCard({
    super.key,
    required this.username,
    this.avatar,
    required this.appVersion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.opaque(0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: avatar != null && avatar!.isNotEmpty
                    ? Image.network(
                        avatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => DefaultAvatar(),
                      )
                    : DefaultAvatar(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Backup Owner",
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    username,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "v$appVersion",
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DefaultAvatar extends StatelessWidget {
  const DefaultAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.person,
        color: theme.colorScheme.primary,
        size: 32,
      ),
    );
  }
}

class LibraryStatsCard extends StatelessWidget {
  final int animeCount;
  final int mangaCount;
  final int novelCount;
  final int animeCustomListsCount;
  final int mangaCustomListsCount;
  final int novelCustomListsCount;

  const LibraryStatsCard({
    super.key,
    required this.animeCount,
    required this.mangaCount,
    required this.novelCount,
    required this.animeCustomListsCount,
    required this.mangaCustomListsCount,
    required this.novelCustomListsCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalItems = animeCount + mangaCount + novelCount;
    final totalLists =
        animeCustomListsCount + mangaCustomListsCount + novelCustomListsCount;

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Library Statistics",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.opaque(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TotalStat(
                    label: "Total Items",
                    value: totalItems.toString(),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.outline.opaque(0.2),
                  ),
                  TotalStat(
                    label: "Custom Lists",
                    value: totalLists.toString(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CategoryRow(
              icon: Icons.movie_filter,
              label: "Anime",
              itemCount: animeCount,
              listCount: animeCustomListsCount,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            CategoryRow(
              icon: Icons.menu_book,
              label: "Manga",
              itemCount: mangaCount,
              listCount: mangaCustomListsCount,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            CategoryRow(
              icon: Icons.auto_stories,
              label: "Novel",
              itemCount: novelCount,
              listCount: novelCustomListsCount,
              color: theme.colorScheme.tertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class TotalStat extends StatelessWidget {
  final String label;
  final String value;

  const TotalStat({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class CategoryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int itemCount;
  final int listCount;
  final Color color;

  const CategoryRow({
    super.key,
    required this.icon,
    required this.label,
    required this.itemCount,
    required this.listCount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.opaque(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.opaque(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                itemCount.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                "$listCount lists",
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.opaque(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
      ),
    );
  }
}

class LibraryDashboard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const LibraryDashboard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _buildStat(context, "Anime", stats['animeCount'],
            theme.colorScheme.primary, Icons.movie_filter),
        const SizedBox(width: 12),
        _buildStat(context, "Manga", stats['mangaCount'],
            theme.colorScheme.secondary, Icons.menu_book),
        const SizedBox(width: 12),
        _buildStat(context, "Novel", stats['novelCount'],
            theme.colorScheme.tertiary, Icons.auto_stories),
      ],
    );
  }

  Widget _buildStat(BuildContext context, String label, dynamic count,
      Color color, IconData icon) {
    return Expanded(
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 12),
              Text(count.toString(),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label,
                  style: TextStyle(
                      color: context.colors.onSurfaceVariant,
                      fontSize: 12)),
            ],
          ),
        ),
      ),
    );
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
                    color: theme.colorScheme.primary.opaque(0.1),
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
                    theme.colorScheme.surfaceContainerHighest.opaque(0.3),
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
                      .opaque(0.3),
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
                      .opaque(0.3),
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

class GlassContainer extends StatelessWidget {
  final Widget child;
  const GlassContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.opaque(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.opaque(0.5)),
      ),
      child: child,
    );
  }
}
