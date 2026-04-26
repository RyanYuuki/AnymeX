import 'package:anymex/controllers/profile/profile_manager.dart';
import 'package:anymex/models/Service/app_profile.dart';
import 'package:anymex/screens/profile/widgets/pattern_lock.dart';
import 'package:anymex/screens/profile/widgets/profile_avatar.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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

Future<void> showProfileSwitcher(BuildContext context) async {
  final manager = Get.find<ProfileManager>();
  if (!manager.isMultiProfileEnabled.value) {
    snackBar('Enable profiles in Settings first');
    return;
  }
  if (manager.profiles.length <= 1) {
    snackBar('Create another profile to switch');
    return;
  }

  final colorScheme = Theme.of(context).colorScheme;
  final theme = context.colors;
  final renderBox = context.findRenderObject() as RenderBox;
  final offset = renderBox.localToGlobal(Offset.zero);
  final size = renderBox.size;

  await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + size.height + 8,
      offset.dx + size.width,
      offset.dy,
    ),
    color: colorScheme.surfaceContainer,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 12,
    items: [
      PopupMenuItem(
        enabled: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Switch Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: theme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
      const PopupMenuDivider(height: 4),
      ...manager.profiles.map((profile) {
        final isCurrent = profile.id == manager.currentProfileId.value;
        return PopupMenuItem<String>(
          value: profile.id,
          enabled: !isCurrent,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (profile.hasLock && !isCurrent)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surface,
                    border: Border.all(
                      color: colorScheme.onSurface.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(_getLockIcon(profile.profileLockType),
                        size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                  ),
                )
              else
                ProfileAvatar(
                  profile: profile,
                  radius: 18,
                ),
              const SizedBox(width: 12),
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
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isCurrent
                                ? colorScheme.primary
                                : theme.onSurface,
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
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(profile.lastUsedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (profile.anilistLinked)
                    _miniBadge('AL', Colors.blue, colorScheme),
                  if (profile.malLinked)
                    _miniBadge('MAL', Colors.blueAccent, colorScheme),
                  if (profile.simklLinked)
                    _miniBadge('Sk', Colors.green, colorScheme),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    ],
  ).then((selectedId) async {
    if (selectedId == null) return;

    final profile = manager.profiles
        .firstWhereOrNull((p) => p.id == selectedId);
    if (profile == null) return;

    if (profile.hasLock) {
      final success = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SwitcherLockDialog(profile: profile),
      );
      if (success != true) return;
    }

    await manager.switchToProfile(profile.id);
    snackBar('Switched to ${profile.name}');
  });
}

Widget _miniBadge(String text, Color color, ColorScheme colorScheme) {
  return Container(
    margin: const EdgeInsets.only(left: 3),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
    ),
  );
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(date);
}

class _SwitcherLockDialog extends StatefulWidget {
  final AppProfile profile;
  const _SwitcherLockDialog({required this.profile});

  @override
  State<_SwitcherLockDialog> createState() => _SwitcherLockDialogState();
}

class _SwitcherLockDialogState extends State<_SwitcherLockDialog> {
  final _controller = TextEditingController();
  bool _isError = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = widget.profile;

    if (profile.isLocked) {
      final remaining =
          profile.lockedUntil!.difference(DateTime.now()).inMinutes + 1;
      return AlertDialog(
        backgroundColor: colorScheme.surfaceContainer,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Profile Locked',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface)),
        content: Text(
          'Try again in $remaining minute${remaining != 1 ? 's' : ''}',
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('OK', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      );
    }

    if (profile.profileLockType == ProfileLockType.pattern) {
      return _buildPatternDialog(colorScheme, profile);
    }

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainer,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Enter ${profile.lockLabel} for "${profile.name}"',
        style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: profile.isPinLocked
                ? TextInputType.number
                : TextInputType.text,
            obscureText: true,
            maxLength: profile.isPinLocked ? 6 : 32,
            autofocus: true,
            style: TextStyle(
                color: colorScheme.onSurface,
                fontFamily: 'Poppins',
                fontSize: profile.isPinLocked ? 22 : 16,
                letterSpacing: profile.isPinLocked ? 8 : 0),
            textAlign: profile.isPinLocked ? TextAlign.center : TextAlign.start,
            decoration: InputDecoration(
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: _isError
                    ? const BorderSide(color: Colors.red, width: 2)
                    : BorderSide.none,
              ),
              counterText: '',
            ),
            onChanged: (_) {
              if (_isError) setState(() => _isError = false);
            },
            onSubmitted: profile.isPasswordLocked
                ? (_) {
                    if (_controller.text.isNotEmpty) _verify();
                  }
                : null,
          ),
          if (_isError) ...[
            const SizedBox(height: 8),
            Text(_errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel',
              style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7))),
        ),
        ElevatedButton(
          onPressed: _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Unlock'),
        ),
      ],
    );
  }

  Widget _buildPatternDialog(ColorScheme colorScheme, AppProfile profile) {
    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainer,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Draw Pattern for "${profile.name}"',
        style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: PatternLock(
              onPatternComplete: (pattern) {
                final manager = Get.find<ProfileManager>();
                final patternStr = pattern.join(',');
                final result =
                    manager.verifyLock(profile.id, patternStr);
                if (result == true) {
                  Navigator.pop(context, true);
                } else if (result == false) {
                  final remaining = kMaxLockAttempts -
                      (manager.profiles
                              .firstWhereOrNull(
                                  (p) => p.id == profile.id)
                              ?.failedAttempts ??
                          0);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Wrong pattern. $remaining attempt${remaining != 1 ? 's' : ''} remaining'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  Navigator.pop(context, false);
                }
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel',
              style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7))),
        ),
      ],
    );
  }

  void _verify() {
    final profile = widget.profile;
    String input;

    if (profile.isPinLocked) {
      input = _controller.text.trim();
      if (input.length < 4) {
        setState(() {
          _isError = true;
          _errorMessage = 'PIN must be at least 4 digits';
        });
        return;
      }
    } else {
      input = _controller.text;
      if (input.isEmpty) {
        setState(() {
          _isError = true;
          _errorMessage = 'Enter a password';
        });
        return;
      }
    }

    final result =
        Get.find<ProfileManager>().verifyLock(widget.profile.id, input);

    if (result == true) {
      Navigator.pop(context, true);
    } else if (result == false) {
      setState(() {
        _isError = true;
        final remaining = kMaxLockAttempts -
            (Get.find<ProfileManager>()
                    .profiles
                    .firstWhereOrNull((p) => p.id == widget.profile.id)
                    ?.failedAttempts ??
                0);
        _errorMessage =
            'Wrong ${profile.lockLabel.toLowerCase()}. $remaining attempt${remaining != 1 ? 's' : ''} left';
      });
      _controller.clear();
    } else {
      Navigator.pop(context, false);
    }
  }
}
