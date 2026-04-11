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

  const RecommendSheet({
    super.key,
    required this.media,
    required this.mediaItemType,
  });

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
    _runCheck();
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
      Navigator.of(context).pop();
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

  Widget _buildAlreadyAdded(ColorScheme colors, Map<String, dynamic> entry) {
    final user = entry['user'] as Map<String, dynamic>? ?? {};
    final serviceType = widget.media.serviceType;

    Map<String, dynamic>? userService;
    if (serviceType == ServicesType.simkl) {
      userService = user['simkl'] as Map<String, dynamic>?;
    } else if (serviceType == ServicesType.mal) {
      userService = user['mal'] as Map<String, dynamic>?
          ?? user['anilist'] as Map<String, dynamic>?;
    } else {
      userService = user['anilist'] as Map<String, dynamic>?
          ?? user['mal'] as Map<String, dynamic>?;
    }

    final avatar = userService?['avatar']?.toString();
    final username = userService?['username']?.toString()
        ?? entry['author']?.toString()
        ?? 'Unknown';
    final reason = entry['reason']?.toString() ?? '';
    final poster = entry['poster']?.toString() ?? widget.media.poster;
    final title = entry['title']?.toString() ?? widget.media.title;
    final isOwner = _isOwner(entry);
    final canEditOrDelete = isOwner || _isAdmin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  width: 48,
                  height: 68,
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
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colors.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Text('Already recommended',
                          style: TextStyle(
                              fontSize: 12, color: colors.primary)),
                      if (_isAdmin && !isOwner) ...[ 
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.surfaceContainerHigh,
              backgroundImage:
                  avatar != null ? CachedNetworkImageProvider(avatar) : null,
              child: avatar == null
                  ? Icon(Icons.person, size: 16, color: colors.onSurface)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(username,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: colors.onSurface)),
            ),
          ],
        ),

        if (reason.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Text(
              '"$reason"',
              style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  height: 1.5),
            ),
          ),
        ],

        if (canEditOrDelete) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editReason(reason),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit Reason'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _deleteEntry,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Delete'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
      ],
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
