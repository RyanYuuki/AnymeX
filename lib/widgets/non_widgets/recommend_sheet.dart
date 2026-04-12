import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/underrated_service.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RecommendSheet extends StatefulWidget {
  final Media media;
  final ItemType mediaItemType;
  /// Pre-existing entry data from the media peek popup (skips API check).
  final Map<String, dynamic>? existingEntry;

  const RecommendSheet({
    super.key,
    required this.media,
    required this.mediaItemType,
    this.existingEntry,
  });

  static void show(BuildContext context, Media media, ItemType mediaItemType, {Map<String, dynamic>? existingEntry}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: SingleChildScrollView(
            child: RecommendSheet(
              media: media,
              mediaItemType: mediaItemType,
              existingEntry: existingEntry,
            ),
          ),
        );
      },
    );
  }

  @override
  State<RecommendSheet> createState() => _RecommendSheetState();
}

class _RecommendSheetState extends State<RecommendSheet> {
  Object? _checkResult;
  bool _isAdmin = false;
  bool _submitting = false;
  final _reasonController = TextEditingController();

  ServiceHandler get _sh => Get.find<ServiceHandler>();

  String get _botMediaType {
    final t = widget.media.type?.toUpperCase() ?? '';
    if (t == 'MANGA') return 'manga';
    if (t == 'MOVIE') return 'movie';
    if (t == 'SERIES') return 'show';
    return 'anime';
  }

  (String id, String idType) get _idAndType {
    final serviceType = widget.media.serviceType;
    if (serviceType == ServicesType.simkl) {
      final rawId = widget.media.id.split('*').first;
      return (rawId, 'simkl');
    }
    if (serviceType == ServicesType.mal) {
      return (widget.media.id, 'mal');
    }
    return (widget.media.id, 'anilist');
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      // Use pre-existing entry data — skip API check
      _checkResult = widget.existingEntry;
    } else {
      _runCheck();
    }
    _runAdminCheck();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _runCheck() async {
    final (id, idType) = _idAndType;
    final entry = await UnderratedService.checkIfExists(
      mediaType: _botMediaType,
      id: id,
      idType: idType,
    );
    if (!mounted) return;
    setState(() {
      _checkResult = entry ?? false;
    });
  }

  Future<void> _runAdminCheck() async {
    final isAdmin = await UnderratedService.checkIsAdmin(
      serviceType: _sh.serviceType.value,
      profile: _sh.profileData.value,
    );
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.length < 30) {
      warningSnackBar('Please write at least 30 characters');
      return;
    }

    setState(() => _submitting = true);

    final serviceType = _sh.serviceType.value;
    final profile = _sh.profileData.value;

    final error = await UnderratedService.submitRecommendation(
      media: widget.media,
      reason: reason,
      serviceType: serviceType,
      profile: profile,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error == null) {
      successSnackBar('Recommendation submitted! 🎉');
      if (_checkResult is Map) {
        // Adding a reason to an existing entry — refresh instead of pop
        _reasonController.clear();
        _runCheck();
      } else {
        Navigator.of(context).pop();
      }
    } else {
      errorSnackBar(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          _buildBody(colors),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme colors) {
    if (!UnderratedService.votingEnabled) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.link_off_rounded,
                size: 40, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Bot URL not configured',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_checkResult == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_checkResult is Map) {
      return _buildAlreadyAdded(colors, _checkResult as Map<String, dynamic>);
    }

    return _buildSubmitForm(colors);
  }

  bool _isOwner(Map<String, dynamic> entry) {
    final user = entry['user'] as Map<String, dynamic>? ?? {};
    final serviceType = _sh.serviceType.value;
    final profile = _sh.profileData.value;
    final myId = int.tryParse(profile.id ?? '');
    if (myId == null) return false;

    if (serviceType == ServicesType.anilist) {
      final al = user['anilist'] as Map<String, dynamic>?;
      return al != null && al['id'] == myId;
    } else if (serviceType == ServicesType.mal) {
      final mal = user['mal'] as Map<String, dynamic>?;
      return mal != null && mal['id'] == myId;
    } else if (serviceType == ServicesType.simkl) {
      final simkl = user['simkl'] as Map<String, dynamic>?;
      return simkl != null && simkl['id'] == myId;
    }
    return false;
  }

  /// Normalize old-format entries (no `reasons[]` array) into new format in-memory.
  /// Old format has top-level `reason` + `user`; new format has `reasons[]` array.
  static Map<String, dynamic> _ensureMigrated(Map<String, dynamic> entry) {
    final reasons = entry['reasons'] as List<dynamic>?;
    if (reasons != null && reasons.isNotEmpty) return entry; // already new format

    final text = entry['reason']?.toString() ?? '';
    final user = entry['user'] as Map<String, dynamic>?;
    if (text.isEmpty && user == null) return entry; // nothing to migrate

    final migrated = Map<String, dynamic>.from(entry);
    migrated['reasons'] = [
      {
        'user': user ?? {},
        'author': entry['author']?.toString(),
        'text': text,
        'added_at': null,
      },
    ];
    return migrated;
  }

  bool _userHasReason(Map<String, dynamic> entry) {
    final migrated = _ensureMigrated(entry);
    final reasonsList = migrated['reasons'] as List<dynamic>?;
    if (reasonsList == null || reasonsList.isEmpty) return false;

    final serviceType = _sh.serviceType.value;
    final profile = _sh.profileData.value;
    final myId = int.tryParse(profile.id ?? '');
    if (myId == null) return false;

    for (final r in reasonsList) {
      final reason = r as Map<String, dynamic>;
      final user = reason['user'] as Map<String, dynamic>? ?? {};

      if (serviceType == ServicesType.anilist) {
        final al = user['anilist'] as Map<String, dynamic>?;
        if (al != null && al['id'] == myId) return true;
      } else if (serviceType == ServicesType.mal) {
        final mal = user['mal'] as Map<String, dynamic>?;
        if (mal != null && mal['id'] == myId) return true;
      } else if (serviceType == ServicesType.simkl) {
        final simkl = user['simkl'] as Map<String, dynamic>?;
        if (simkl != null && simkl['id'] == myId) return true;
      }
    }
    // Old format: if reasons has one entry and no user matched, check entry-level user as fallback
    if (reasonsList.length == 1 && entry['user'] != null) {
      final topUser = entry['user'] as Map<String, dynamic>;
      if (serviceType == ServicesType.anilist) {
        final al = topUser['anilist'] as Map<String, dynamic>?;
        if (al != null && al['id'] == myId) return true;
      } else if (serviceType == ServicesType.mal) {
        final mal = topUser['mal'] as Map<String, dynamic>?;
        if (mal != null && mal['id'] == myId) return true;
      } else if (serviceType == ServicesType.simkl) {
        final simkl = topUser['simkl'] as Map<String, dynamic>?;
        if (simkl != null && simkl['id'] == myId) return true;
      }
    }
    return false;
  }

  Map<String, dynamic>? _findUserReason(Map<String, dynamic> entry) {
    final migrated = _ensureMigrated(entry);
    final reasonsList = migrated['reasons'] as List<dynamic>?;
    if (reasonsList == null || reasonsList.isEmpty) return null;

    final serviceType = _sh.serviceType.value;
    final profile = _sh.profileData.value;
    final myId = int.tryParse(profile.id ?? '');
    if (myId == null) return null;

    for (final r in reasonsList) {
      final reason = r as Map<String, dynamic>;
      final user = reason['user'] as Map<String, dynamic>? ?? {};

      if (serviceType == ServicesType.anilist) {
        final al = user['anilist'] as Map<String, dynamic>?;
        if (al != null && al['id'] == myId) return reason;
      } else if (serviceType == ServicesType.mal) {
        final mal = user['mal'] as Map<String, dynamic>?;
        if (mal != null && mal['id'] == myId) return reason;
      } else if (serviceType == ServicesType.simkl) {
        final simkl = user['simkl'] as Map<String, dynamic>?;
        if (simkl != null && simkl['id'] == myId) return reason;
      }
    }
    // Old format fallback: if single reason and no per-reason user matched, use entry-level user
    if (reasonsList.length == 1 && entry['user'] != null) {
      final topUser = entry['user'] as Map<String, dynamic>;
      if (serviceType == ServicesType.anilist) {
        final al = topUser['anilist'] as Map<String, dynamic>?;
        if (al != null && al['id'] == myId) return reasonsList[0] as Map<String, dynamic>;
      } else if (serviceType == ServicesType.mal) {
        final mal = topUser['mal'] as Map<String, dynamic>?;
        if (mal != null && mal['id'] == myId) return reasonsList[0] as Map<String, dynamic>;
      } else if (serviceType == ServicesType.simkl) {
        final simkl = topUser['simkl'] as Map<String, dynamic>?;
        if (simkl != null && simkl['id'] == myId) return reasonsList[0] as Map<String, dynamic>;
      }
    }
    return null;
  }

  Future<void> _editReason(String currentReason) async {
    final controller = TextEditingController(text: currentReason);
    final colors = Theme.of(context).colorScheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: MediaQuery.of(ctx).viewInsets,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            color: colors.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colors.onSurfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(children: [
                  Icon(Icons.edit_rounded, color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Edit Reason', style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15,
                    color: colors.onSurface,
                  )),
                ]),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 700,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Why is this underrated? (min 30 chars)',
                    filled: true,
                    fillColor: colors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final newReason = controller.text.trim();
                      if (newReason.length < 30) {
                        warningSnackBar('Please write at least 30 characters');
                        return;
                      }
                      Navigator.of(ctx).pop();
                      final error = await UnderratedService.editReason(
                        mediaType: _botMediaType,
                        mediaId: _idAndType.$1,
                        newReason: newReason,
                        serviceType: _sh.serviceType.value,
                        profile: _sh.profileData.value,
                      );
                      if (error == null) {
                        successSnackBar('Reason updated!');
                        _runCheck();
                      } else {
                        errorSnackBar(error);
                      }
                    },
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Save Changes'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteEntry() async {
    final colors = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recommendation?'),
        content: Text(
          _isAdmin
              ? 'This entry will be deleted immediately.'
              : 'Your deletion request will be sent to admins for review.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final (error, pending) = await UnderratedService.deleteEntryWithStatus(
      mediaType: _botMediaType,
      mediaId: _idAndType.$1,
      serviceType: _sh.serviceType.value,
      profile: _sh.profileData.value,
      isAdmin: _isAdmin,
    );

    if (error == null) {
      if (pending) {
        successSnackBar('Deletion request sent to admins for review.');
      } else {
        successSnackBar('Entry deleted.');
      }
      if (mounted) Navigator.of(context).pop();
    } else {
      errorSnackBar(error);
    }
  }

  Future<void> _deleteReason() async {
    final colors = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Your Reason?'),
        content: Text(
          _isAdmin
              ? 'This reason will be removed immediately.'
              : 'Your removal request will be sent to admins for review.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final (error, pending) = await UnderratedService.deleteReasonWithStatus(
      mediaType: _botMediaType,
      mediaId: _idAndType.$1,
      serviceType: _sh.serviceType.value,
      profile: _sh.profileData.value,
      isAdmin: _isAdmin,
    );

    if (error == null) {
      if (pending) {
        successSnackBar('Removal request sent to admins for review.');
      } else {
        successSnackBar('Your reason has been removed.');
      }
      _runCheck();
    } else {
      errorSnackBar(error);
    }
  }

  Widget _buildAlreadyAdded(ColorScheme colors, Map<String, dynamic> entry) {
    // Migrate old format (no reasons[]) → new format in-memory for uniform handling
    final migrated = _ensureMigrated(entry);
    final serviceType = widget.media.serviceType;

    // Current user's info
    final profile = _sh.profileData.value;
    final myAvatar = profile.avatar;
    final myId = int.tryParse(profile.id ?? '');

    // Check user state
    final userHasReason = _userHasReason(entry);
    final userReason = _findUserReason(entry);
    final isOwner = _isOwner(entry);
    final canEditOrDelete = isOwner || _isAdmin;

    // User reason's avatar (if available from reason's own user block)
    String? userReasonAvatar;
    if (userReason != null) {
      final rUser = userReason['user'] as Map<String, dynamic>? ?? {};
      final rService = serviceType == ServicesType.simkl
          ? rUser['simkl'] as Map<String, dynamic>?
          : serviceType == ServicesType.mal
              ? (rUser['mal'] as Map<String, dynamic>? ?? rUser['anilist'] as Map<String, dynamic>?)
              : (rUser['anilist'] as Map<String, dynamic>? ?? rUser['mal'] as Map<String, dynamic>?);
      userReasonAvatar = rService?['avatar']?.toString();
    }
    // For old format: also check entry-level user for avatar
    if (userReasonAvatar == null && userReason == null && userHasReason) {
      final topUser = entry['user'] as Map<String, dynamic>? ?? {};
      final tService = serviceType == ServicesType.simkl
          ? topUser['simkl'] as Map<String, dynamic>?
          : serviceType == ServicesType.mal
              ? (topUser['mal'] as Map<String, dynamic>? ?? topUser['anilist'] as Map<String, dynamic>?)
              : (topUser['anilist'] as Map<String, dynamic>? ?? topUser['mal'] as Map<String, dynamic>?);
      userReasonAvatar = tService?['avatar']?.toString();
    }
    // Prefer avatar from the reason's own user block, then current profile
    final myDisplayAvatar = userReasonAvatar ?? myAvatar;
    final poster = entry['poster']?.toString() ?? widget.media.poster;
    final title = entry['title']?.toString() ?? widget.media.title;

    // Get other users' reasons (filter by user ID, not text)
    final reasonsList = (migrated['reasons'] as List<dynamic>?) ?? [];
    final otherReasons = reasonsList.where((r) {
      final reasonMap = r as Map<String, dynamic>;
      final rUser = reasonMap['user'] as Map<String, dynamic>? ?? {};
      if (serviceType == ServicesType.anilist) {
        final al = rUser['anilist'] as Map<String, dynamic>?;
        if (al != null && al['id'] == myId) return false;
      } else if (serviceType == ServicesType.mal) {
        final mal = rUser['mal'] as Map<String, dynamic>?;
        if (mal != null && mal['id'] == myId) return false;
      } else if (serviceType == ServicesType.simkl) {
        final simkl = rUser['simkl'] as Map<String, dynamic>?;
        if (simkl != null && simkl['id'] == myId) return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with poster and title
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: poster,
                  width: 48,
                  height: 68,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 48, height: 68,
                    color: colors.surfaceContainerHigh,
                    child: const Icon(Icons.image_not_supported_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.onSurface),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: colors.primary),
                        const SizedBox(width: 4),
                        Text('Already recommended', style: TextStyle(fontSize: 12, color: colors.primary)),
                        if (_isAdmin && !isOwner) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.onErrorContainer)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // User's reason or add form
          if (userHasReason && userReason != null) ...[
            // Show user's own reason
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: colors.primaryContainer,
                        backgroundImage: myDisplayAvatar != null ? CachedNetworkImageProvider(myDisplayAvatar) : null,
                        child: myDisplayAvatar == null ? Icon(Icons.person, size: 14, color: colors.onPrimaryContainer) : null,
                      ),
                      const SizedBox(width: 8),
                      Text('Your Recommendation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.onSurface)),
                    ],
                  ),
                  if (userReason['text']?.toString().isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      '"${userReason['text']}"',
                      style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant, fontStyle: FontStyle.italic, height: 1.5),
                    ),
                  ],
                  if (canEditOrDelete) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _editReason(userReason['text']?.toString() ?? ''),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit Reason'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _deleteReason,
                            icon: const Icon(Icons.delete_outline_rounded, size: 16),
                            label: const Text('Remove'),
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.error,
                              foregroundColor: colors.onError,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            // Show "Add Your Recommendation" form
            _buildAddReasonForm(colors),
          ],

          // Other users' recommendations
          if (otherReasons.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Other Recommendations', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.onSurfaceVariant)),
            const SizedBox(height: 8),
            ...otherReasons.map((r) {
              final reason = r as Map<String, dynamic>;
              final reasonUser = reason['user'] as Map<String, dynamic>? ?? {};
              final rService = serviceType == ServicesType.simkl
                  ? reasonUser['simkl'] as Map<String, dynamic>?
                  : serviceType == ServicesType.mal
                      ? (reasonUser['mal'] as Map<String, dynamic>? ?? reasonUser['anilist'] as Map<String, dynamic>?)
                      : (reasonUser['anilist'] as Map<String, dynamic>? ?? reasonUser['mal'] as Map<String, dynamic>?);
              final rAvatar = rService?['avatar']?.toString();
              final rUsername = rService?['username']?.toString() ?? reason['author']?.toString() ?? 'Unknown';
              final rText = reason['text']?.toString() ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: colors.surfaceContainerHigh,
                            backgroundImage: rAvatar != null ? CachedNetworkImageProvider(rAvatar) : null,
                            child: rAvatar == null ? Icon(Icons.person, size: 12, color: colors.onSurfaceVariant) : null,
                          ),
                          const SizedBox(width: 6),
                          Text(rUsername, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: colors.onSurface)),
                        ],
                      ),
                      if (rText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '"$rText"',
                          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant, fontStyle: FontStyle.italic, height: 1.4),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAddReasonForm(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_comment_rounded, color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Text('Add Your Recommendation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.onSurface)),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reasonController,
            minLines: 2,
            maxLines: 5,
            maxLength: 700,
            decoration: InputDecoration(
              hintText: 'Why is this underrated? (min 30 chars)',
              hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              filled: true,
              fillColor: colors.surfaceContainerHighest.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: TextStyle(fontSize: 13, color: colors.onSurface),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colors.onPrimary))
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(_submitting ? 'Submitting…' : 'Add Recommendation'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitForm(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.recommend_rounded, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Recommend "${widget.media.title}"',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colors.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tell the community why this deserves more attention.',
          style:
              TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _reasonController,
          minLines: 3,
          maxLines: 6,
          maxLength: 700,
          decoration: InputDecoration(
            hintText: 'Why is this underrated? (min 30 chars)',
            hintStyle:
                TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            filled: true,
            fillColor: colors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: TextStyle(fontSize: 13, color: colors.onSurface),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_submitting ? 'Submitting…' : 'Submit Recommendation'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
