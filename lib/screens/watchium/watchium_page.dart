import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex/widgets/watchium/watchium_server_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class WatchiumPage extends StatefulWidget {
  const WatchiumPage({super.key});

  @override
  State<WatchiumPage> createState() => _WatchiumPageState();
}

class _WatchiumPageState extends State<WatchiumPage> {
  final WatchiumService _watchium = Get.find<WatchiumService>();
  final _joinCodeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  bool _isLoading = false;
  String? _error;

  Worker? _deepLinkWorker;
  String? _handlingDeepLinkCode;

  @override
  void initState() {
    super.initState();
    _loadRooms();
    _codeFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _joinCodeController.addListener(() {
      if (mounted) setState(() {});
    });
    _deepLinkWorker =
        ever<String>(_watchium.pendingDeepLinkCode, (code) {
      if (code.isNotEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _handleDeepLinkRoom(code);
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = _watchium.pendingDeepLinkCode.value;
      if (pending.isNotEmpty && mounted) {
        _handleDeepLinkRoom(pending);
      }
    });
  }

  @override
  void dispose() {
    _deepLinkWorker?.dispose();

    if (_handlingDeepLinkCode != null &&
        _watchium.pendingDeepLinkCode.value == _handlingDeepLinkCode) {
      _watchium.completeDeepLinkJoin(false);
    }
    _handlingDeepLinkCode = null;
    _joinCodeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  /// Handles a deeplinked room by reusing the exact Active Rooms join flow.
  Future<void> _handleDeepLinkRoom(String code) async {
    final normalized = code.trim().toUpperCase();
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    if (_handlingDeepLinkCode == normalized) return;
    if (_handlingDeepLinkCode != null) return;
    _handlingDeepLinkCode = normalized;
    try {
      int waits = 0;
      while (_isLoading && mounted && waits < 100) {
        await Future.delayed(const Duration(milliseconds: 100));
        waits++;
      }
      if (!mounted) {
        _watchium.completeDeepLinkJoin(false);
        return;
      }
      WatchiumRoomState? room;
      try {
        room = _watchium.publicRooms.firstWhere(
          (r) => r.code.trim().toUpperCase() == normalized,
        );
      } catch (_) {
        room = null;
      }
      room ??= await _watchium.getRoomInfo(normalized);
      if (!mounted) {
        _watchium.completeDeepLinkJoin(false);
        return;
      }
      if (room == null) {
        _watchium.completeDeepLinkJoin(false);
        return;
      }
      final success = await _joinRoomFromCard(room, fromDeepLink: true);
      try {
        _watchium.completeDeepLinkJoin(success);
      } catch (_) {}
    } finally {
      _handlingDeepLinkCode = null;
    }
  }

  Future<void> _loadRooms() async {
    Logger.d('Loading public rooms', 'WATCHIUM_UI');
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await _watchium.listRooms();
    if (mounted) setState(() => _isLoading = false);
  }


  Future<void> _joinByCode({String? password}) async {
    if (_isLoading || _watchium.isJoining.value) {
      Logger.d('Join by code skipped: already in progress', 'WATCHIUM_UI');
      return;
    }
    final code = _joinCodeController.text.trim().toUpperCase();
    Logger.i('Join by code: $code', 'WATCHIUM_UI');
    if (code.length != 6) {
      setState(() => _error = 'Room code must be 6 characters');
      Logger.w('Join by code: invalid length ${code.length}', 'WATCHIUM_UI');
      return;
    }

    final suppliedPassword = password?.trim() ?? '';
    if (suppliedPassword.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      bool ok = false;
      try {
        ok = await _watchium.joinRoom(code, password: suppliedPassword);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      if (ok) {
        Logger.i('Join by code $code succeeded (with password)', 'WATCHIUM_UI');
        if (mounted) _handleJoinSuccess(code);
      } else if (mounted) {
        final err = _watchium.error.value;
        Logger.w('Join by code $code failed (with password): $err',
            'WATCHIUM_UI');
        if (err == 'Incorrect password') {
          _showPasswordDialog(code, initialError: err);
        } else {
          setState(() => _error = err);
          errorSnackBar(err.isEmpty ? 'Failed to join room' : err);
        }
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    WatchiumRoomState? preview;
    try {
      preview = await _watchium.getRoomInfo(code);
    } catch (e) {
      Logger.w('Resolve room $code failed: $e', 'WATCHIUM_UI');
      preview = null;
    }
    if (!mounted) return;

    if (preview == null) {
      Logger.w('Resolve room $code: not found', 'WATCHIUM_UI');
      setState(() {
        _isLoading = false;
        _error = 'Room not found or expired';
      });
      errorSnackBar('Room not found or expired');
      return;
    }

    if (preview.hasPassword) {
      Logger.i('Room $code requires a password, showing password UI',
          'WATCHIUM_UI');
      setState(() => _isLoading = false);
      _showPasswordDialog(code);
      return;
    }

    bool ok = false;
    try {
      ok = await _watchium.joinRoom(code);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (ok) {
      Logger.i('Join by code $code succeeded', 'WATCHIUM_UI');
      if (mounted) _handleJoinSuccess(code);
    } else if (mounted) {
      final err = _watchium.error.value;
      Logger.w('Join by code $code failed: $err', 'WATCHIUM_UI');
      if (err == 'Incorrect password') {
        _showPasswordDialog(code);
        return;
      }
      setState(() => _error = err);
      errorSnackBar(err.isEmpty ? 'Failed to join room' : err);
    }
  }

  void _handleJoinSuccess(String code) {
    snackBar('Joined room $code!');
    final roomState = _watchium.roomState.value;
    final content = roomState?.content;
    if (content != null && content.availableServers.isNotEmpty) {
      showWatchiumServerSheet(context: context, content: content);
    }
  }

  Future<bool> _showPasswordDialog(String code,
      {String? initialError, bool fromDeepLink = false}) async {
    final pwController = TextEditingController();
    bool obscure = true;
    bool joining = false;
    String? dialogError = initialError;

    final result = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            final cs = Theme.of(context).colorScheme;
            Future<void> submit() async {
              if (joining || _watchium.isJoining.value) return;
              final pw = pwController.text.trim();
              if (pw.isEmpty) {
                setDialogState(() =>
                    dialogError = 'Please enter the room password');
                return;
              }
              setDialogState(() {
                joining = true;
                dialogError = null;
              });
              final ok =
                  await _watchium.joinRoom(code, password: pw);
              if (Get.isDialogOpen != true) {
                return;
              }
              if (ok) {
                Logger.i('Join room $code succeeded (dialog password)',
                    'WATCHIUM_UI');
                Get.back(result: true);
                // For deeplinked rooms the deeplink handler shows the
                // successful-join state; avoid showing it twice.
                if (!fromDeepLink) {
                  _handleJoinSuccess(code);
                }
              } else {
                final err = _watchium.error.value;
                Logger.w('Join room $code failed (dialog password): $err',
                    'WATCHIUM_UI');
                setDialogState(() {
                  joining = false;
                  dialogError = err.isEmpty ? 'Failed to join room' : err;
                });
              }
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.opaque(0.35,
                              iReallyMeanIt: true),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.primary.opaque(0.15, iReallyMeanIt: true),
                          ),
                        ),
                        child: Icon(Icons.lock_rounded,
                            size: 20, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AnymeXText(
                              'Password Required',
                              variant: TextVariant.semiBold,
                              size: 15,
                            ),
                            const SizedBox(height: 2),
                            AnymeXText(
                              'Room $code is private',
                              size: 12,
                              color: cs.onSurface.opaque(0.6),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: joining
                            ? null
                            : () => Get.back(result: false),
                        icon: Icon(Icons.close_rounded,
                            color: cs.onSurface.opaque(0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pwController,
                    obscureText: obscure,
                    enabled: !joining,
                    autofocus: true,
                    onSubmitted: (_) => submit(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: cs.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Room password',
                      hintText: 'Enter the room password',
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: cs.onSurface.opaque(0.35),
                      ),
                      prefixIcon: Icon(Icons.lock_outline_rounded,
                          size: 18, color: cs.onSurface.opaque(0.5)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 18,
                          color: cs.onSurface.opaque(0.5),
                        ),
                        onPressed: () => setDialogState(
                            () => obscure = !obscure),
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.primary, width: 1.5),
                      ),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.error.opaque(0.1, iReallyMeanIt: true),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 16, color: cs.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AnymeXText(
                              dialogError!,
                              size: 12,
                              color: cs.error,
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: joining
                              ? null
                              : () => Get.back(result: false),
                          child: const AnymeXText('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: joining ? null : submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: joining
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: cs.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.login_rounded, size: 18),
                          label: AnymeXText(
                            joining ? 'Joining...' : 'Join',
                            variant: TextVariant.semiBold,
                            size: 14,
                            color: cs.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      barrierDismissible: true,
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnymeXScaffold(
  body: Column(
          children: [
            NestedHeader(
              title: 'Watch Together',
              action: IconButton(
                onPressed: _loadRooms,
                icon: const Icon(Icons.refresh),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildJoinByCodeSection(theme),
                    const SizedBox(height: 24),
                                        Obx(() {
                      if (_watchium.inRoom.value ||
                          _watchium.isJoining.value) {
                        return _buildCurrentRoomSection(theme);
                      }
                      return const SizedBox.shrink();
                    }),
                    const SizedBox(height: 16),
                    AnymeXCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .opaque(0.35, iReallyMeanIt: true),
                                  borderRadius: BorderRadius.circular(
                                      10.multiplyRadius()),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .opaque(0.15, iReallyMeanIt: true),
                                  ),
                                ),
                                child: Icon(Iconsax.people,
                                    size: 18,
                                    color: theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 10),
                              const AnymeXText('Active Rooms',
                                size: 15,
                                variant: TextVariant.semiBold,
                              ),
                              const SizedBox(width: 8),
                              Obx(() {
                                final count = _watchium.publicRooms.length;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: AnymeXText('$count',
                                    size: 12,
                                    color: theme
                                        .colorScheme.onPrimaryContainer,
                                  ),
                                );
                              }),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 14),
                            child: Divider(
                              height: 1,
                              thickness: 0.6,
                              color: theme.colorScheme.outline
                                  .opaque(0.08, iReallyMeanIt: true),
                            ),
                          ),
                          _buildRoomsList(theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
);
  }

  Widget _buildJoinByCodeSection(ThemeData theme) {
    final cs = theme.colorScheme;
    return AnymeXCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.opaque(0.35, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(12.multiplyRadius()),
                  border: Border.all(
                    color: cs.primary.opaque(0.15, iReallyMeanIt: true),
                  ),
                ),
                child: Icon(Icons.vpn_key_rounded, size: 20, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AnymeXText('Join with Code',
                      size: 15,
                      variant: TextVariant.semiBold,
                    ),
                    const SizedBox(height: 2),
                    AnymeXText(
                      'Enter a 6-character room code to join a watch party',
                      size: 12,
                      color: cs.onSurface.opaque(0.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 14),
            child: Divider(
              height: 1,
              thickness: 0.6,
              color: cs.outline.opaque(0.08, iReallyMeanIt: true),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (!_codeFocusNode.hasFocus) _codeFocusNode.requestFocus();
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final code = _joinCodeController.text.toUpperCase();
                    final hasError = _error != null;
                    final isFocused = _codeFocusNode.hasFocus;
                    const gap = 8.0;
                    const maxBoxSize = 48.0;
                    double availableWidth = constraints.maxWidth;
                    double boxSize = (availableWidth - gap * 5) / 6;
                    boxSize = boxSize.clamp(36.0, maxBoxSize);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (i) {
                        final char = i < code.length ? code[i] : '';
                        final hasChar = char.isNotEmpty;
                        final isNext = i == code.length && isFocused;
                        Color borderColor;
                        Color boxColor;
                        double borderWidth = 1;
                        if (hasError) {
                          borderColor = cs.error.opaque(0.6, iReallyMeanIt: true);
                          boxColor = hasChar
                              ? cs.errorContainer
                                  .opaque(0.35, iReallyMeanIt: true)
                              : cs.surfaceContainerLow;
                          if (isNext) borderWidth = 1.4;
                        } else if (isNext) {
                          borderColor = cs.primary;
                          borderWidth = 1.4;
                          boxColor = cs.surfaceContainerLow;
                        } else if (hasChar) {
                          borderColor =
                              cs.primary.opaque(0.55, iReallyMeanIt: true);
                          borderWidth = 1.2;
                          boxColor = cs.primaryContainer
                              .opaque(0.35, iReallyMeanIt: true);
                        } else {
                          borderColor = cs.outlineVariant
                              .opaque(0.6, iReallyMeanIt: true);
                          boxColor = cs.surfaceContainerLow;
                        }
                        return Container(
                          width: boxSize,
                          height: boxSize,
                          margin: EdgeInsets.only(right: i < 5 ? gap : 0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: boxColor,
                            borderRadius:
                                BorderRadius.circular(12.multiplyRadius()),
                            border: Border.all(
                                color: borderColor, width: borderWidth),
                          ),
                          child: AnymeXText(
                            char,
                            size: 18,
                            variant: TextVariant.semiBold,
                            color: hasChar && !hasError
                                ? cs.onPrimaryContainer
                                : hasError && hasChar
                                    ? cs.onErrorContainer
                                    : cs.onSurface,
                          ),
                        );
                      }),
                    );
                  },
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _joinCodeController,
                      focusNode: _codeFocusNode,
                      onChanged: (v) => setState(() => _error = null),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onSubmitted: (_) => _joinByCode(),
                      showCursor: false,
                      enableInteractiveSelection: false,
                      style: const TextStyle(
                          color: Colors.transparent, fontSize: 1),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                      cursorColor: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _joinByCode,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.multiplyRadius()),
                ),
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Icon(Icons.login_rounded, size: 18),
              label: AnymeXText(
                _isLoading ? 'Joining...' : 'Join Room',
                variant: TextVariant.semiBold,
                size: 14,
                color: cs.onPrimary,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.error.opaque(0.1, iReallyMeanIt: true),
                borderRadius: BorderRadius.circular(10.multiplyRadius()),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 16, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnymeXText(
                      _error!,
                      size: 12,
                      color: cs.error,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentRoomSection(ThemeData theme) {
    return Obx(() {
      final roomState = _watchium.roomState.value;
      final isJoining = _watchium.isJoining.value;
      final roomCode = _watchium.roomCode.value;
      final errorMsg = _watchium.error.value;

      // Stuck state: inRoom is true or isJoining, but no roomState
      if (roomState == null) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.opaque(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.error.opaque(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: theme.colorScheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnymeXText(isJoining
                          ? 'Joining room $roomCode...'
                          : 'Failed to join room $roomCode',
                      size: 14,
                      variant: TextVariant.semiBold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              if (errorMsg.isNotEmpty && !isJoining) ...[
                const SizedBox(height: 4),
                AnymeXText(errorMsg,
                  size: 12,
                  color: theme.colorScheme.error.opaque(0.8),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Logger.i('Force leaving from stuck state', 'WATCHIUM_UI');
                    _watchium.forceLeaveRoom();
                    setState(() => _error = null);
                    snackBar('Left room');
                  },
                  icon: const Icon(Icons.exit_to_app, size: 16),
                  label: AnymeXText(isJoining ? 'Cancel' : 'Leave / Reset'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Normal active room state
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.opaque(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.opaque(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_rounded,
                    color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                AnymeXText('In Room: ${roomState.code}',
                  size: 14,
                  variant: TextVariant.semiBold,
                  color: theme.colorScheme.primary,
                ),
                const Spacer(),
                if (_watchium.isHost.value)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AnymeXText('HOST',
                      size: 10,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
              ],
            ),
            if (roomState.content != null) ...[
              const SizedBox(height: 8),
              AnymeXText('${roomState.content!.animeTitle} - Episode ${roomState.content!.episodeNumber}',
                size: 12,
              ),
            ],
            const SizedBox(height: 8),
            // Members list with kick buttons
            if (roomState.members.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...roomState.members.map((m) {
                final isSelf = m.userId == _watchium.roomState.value?.hostUserId;
                final canKick = _watchium.isHost.value && !isSelf;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: m.avatarUrl != null
                            ? NetworkImage(m.avatarUrl!)
                            : null,
                        child: m.avatarUrl == null
                            ? AnymeXText(m.username[0].toUpperCase(),
                                style: const TextStyle(fontSize: 12))
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AnymeXText(m.username,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (m.role == 'host')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: AnymeXText('HOST',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold)),
                        ),
                      if (canKick)
                        IconButton(
                          icon: const Icon(Icons.person_remove, size: 16, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _watchium.kickMember(m.userId);
                            snackBar('Kicked ${m.username}');
                          },
                        ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                AnymeXText('${roomState.members.length}/${roomState.maxMembers} members',
                  size: 12,
                  color: theme.colorScheme.onSurface.opaque(0.6),
                ),
                if (_watchium.hasPassword.value) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.lock, size: 12, color: Colors.orange),
                ],
                const Spacer(),
                if (roomState.content != null &&
                    roomState.content!.availableServers.isNotEmpty &&
                    !_watchium.isHost.value)
                  TextButton.icon(
                    onPressed: () {
                      showWatchiumServerSheet(
                          context: context,
                          content: roomState.content!);
                    },
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const AnymeXText('Play'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                TextButton.icon(
                  onPressed: () {
                    _watchium.leaveRoom();
                    snackBar('Left the room');
                  },
                  icon: const Icon(Icons.logout, size: 16),
                  label: const AnymeXText('Leave'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRoomsList(ThemeData theme) {
    return Obx(() {
      if (_isLoading && _watchium.publicRooms.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (_watchium.publicRooms.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.tv_off_rounded,
                    size: 48, color: theme.colorScheme.onSurface.opaque(0.2)),
                const SizedBox(height: 12),
                AnymeXText('No active rooms',
                  size: 14,
                  color: theme.colorScheme.onSurface.opaque(0.5),
                ),
                const SizedBox(height: 4),
                AnymeXText('Rooms will appear here when someone creates one',
                  size: 12,
                  color: theme.colorScheme.onSurface.opaque(0.3),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: _watchium.publicRooms.map((room) {
          return _buildRoomCard(theme, room);
        }).toList(),
      );
    });
  }

  Future<bool> _joinRoomFromCard(WatchiumRoomState room,
      {bool fromDeepLink = false}) async {
    Logger.i('Join room from card: ${room.code}', 'WATCHIUM_UI');
    if (_isLoading || _watchium.isJoining.value) {
      Logger.d('Join room from card skipped: already in progress',
          'WATCHIUM_UI');
      return false;
    }
    final code = room.code.trim().toUpperCase();
    if (room.hasPassword) {
      Logger.i('Room $code requires a password (from list), showing UI',
          'WATCHIUM_UI');
      return await _showPasswordDialog(code, fromDeepLink: fromDeepLink);
    }
    setState(() => _isLoading = true);
    WatchiumRoomState? preview;
    try {
      preview = await _watchium.getRoomInfo(code);
    } catch (e) {
      Logger.w('Resolve room $code failed: $e', 'WATCHIUM_UI');
      preview = null;
    }
    if (!mounted) return false;
    if (preview == null) {
      setState(() => _isLoading = false);
      if (!fromDeepLink) {
        errorSnackBar('Room not found or expired');
      }
      return false;
    }
    if (preview.hasPassword) {
      setState(() => _isLoading = false);
      return await _showPasswordDialog(code, fromDeepLink: fromDeepLink);
    }
    bool ok = false;
    try {
      ok = await _watchium.joinRoom(code);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (ok) {
      if (!fromDeepLink) {
        _handleJoinSuccess(code);
      }
      return true;
    } else if (mounted) {
      final err = _watchium.error.value;
      if (err == 'Incorrect password' ||
          (fromDeepLink &&
              (err == 'Password required' ||
                  err.toLowerCase().contains('password')))) {
        return await _showPasswordDialog(code, fromDeepLink: fromDeepLink);
      }
      if (!fromDeepLink) {
        errorSnackBar(err.isEmpty ? 'Failed to join room' : err);
      }
      return false;
    }
    return false;
  }

  String _timeAgo(int createdAtMs) {
    final diff = DateTime.now().millisecondsSinceEpoch - createdAtMs;
    if (diff < 0) return 'Just now';
    final mins = diff ~/ 60000;
    if (mins < 1) return 'Just now';
    if (mins < 60) return '${mins}m ago';
    final hours = mins ~/ 60;
    if (hours < 24) return '${hours}h ago';
    final days = hours ~/ 24;
    return '${days}d ago';
  }

  Widget _buildRoomCard(ThemeData theme, WatchiumRoomState room) {
    final cs = theme.colorScheme;
    final isJoinable = room.members.length < room.maxMembers;
    final content = room.content;
    final bannerUrl = content?.animeCoverImage;
    final posterUrl = content?.animePosterImage ?? content?.animeCoverImage;

    // Find host member
    final hostMember = room.members.where((m) => m.role == 'host').firstOrNull;
    final otherMembers = room.members.where((m) => m.role != 'host').toList();
    final showMemberAvatars = otherMembers.isNotEmpty;
    final onlineCount = room.members.where((m) => m.online).length;
    const maxShowAvatars = 3;
    final visibleMembers = otherMembers.take(maxShowAvatars).toList();
    final remainingCount = otherMembers.length - maxShowAvatars;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16.multiplyRadius()),
        border: Border.all(color: cs.outline.opaque(0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnymexOnTap(
        onTap: isJoinable && !_isLoading
            ? () => _joinRoomFromCard(room)
            : null,
        borderRadius: BorderRadius.circular(16.multiplyRadius()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top section: banner bg + poster + info
            Stack(
              children: [
                // Banner background image
                if (bannerUrl != null && bannerUrl.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 7,
                    child: AnymeXImage(
                      imageUrl: bannerUrl,
                      width: double.infinity,
                      radius: 0,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (bannerUrl == null || bannerUrl.isEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 7,
                    child: Container(color: cs.surfaceContainerHighest),
                  ),

                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.opaque(0.1),
                          Colors.black.opaque(0.3),
                          Colors.black.opaque(0.85),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // Viewers count — top right
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.opaque(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.eye, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        AnymeXText(
                          '$onlineCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Poster + title row
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Poster thumbnail
                      if (posterUrl != null && posterUrl.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                10.multiplyRadius()),
                            border:
                                Border.all(color: Colors.white24, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.opaque(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                8.5.multiplyRadius()),
                            child: AnymeXImage(
                              imageUrl: posterUrl,
                              width: 64,
                              height: 88,
                              radius: 0,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 64,
                          height: 88,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius:
                                BorderRadius.circular(10.multiplyRadius()),
                            border:
                                Border.all(color: Colors.white24, width: 1.5),
                          ),
                          child: const Icon(Icons.tv,
                              color: Colors.white54, size: 24),
                        ),
                      const SizedBox(width: 12),

                      // Title + meta
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (content != null)
                              AnymeXText(
                                content.animeTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              )
                            else
                              AnymeXText(
                                'Room ${room.code}',
                                style: TextStyle(
                                  color: Colors.white.opaque(0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (content != null) ...[
                              const SizedBox(height: 4),
                              AnymeXText(
                                'EP ${content.episodeNumber}${content.totalEpisodes != null ? ' / ${content.totalEpisodes}' : ''}',
                                style: TextStyle(
                                  color: Colors.white.opaque(0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Footer section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Host avatar + name
                  Expanded(
                    child: Row(
                      children: [
                        if (hostMember != null)
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: hostMember.avatarUrl != null
                                ? NetworkImage(hostMember.avatarUrl!)
                                : null,
                            backgroundColor: cs.surfaceContainerHighest,
                            child: hostMember.avatarUrl == null
                                ? AnymeXText(
                                    hostMember.username[0].toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                  )
                                : null,
                          )
                        else
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: cs.surfaceContainerHighest,
                            child: Icon(Icons.person,
                                size: 14, color: cs.onSurfaceVariant),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnymeXText(hostMember?.username ?? 'Unknown',
                                size: 13,
                                variant: TextVariant.semiBold,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              AnymeXText('Created · ${_timeAgo(room.createdAt)}',
                                size: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Member avatars stack
                  if (showMemberAvatars) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 22,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (int i = 0;
                              i < visibleMembers.length;
                              i++)
                            Positioned(
                              left: i * 14.0,
                              child: CircleAvatar(
                                radius: 11,
                                backgroundColor: cs.surfaceContainerHighest,
                                backgroundImage:
                                    visibleMembers[i].avatarUrl != null
                                        ? NetworkImage(
                                            visibleMembers[i].avatarUrl!)
                                        : null,
                                child: visibleMembers[i].avatarUrl == null
                                    ? AnymeXText(
                                        visibleMembers[i]
                                            .username[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700),
                                      )
                                    : null,
                              ),
                            ),
                          if (remainingCount > 0)
                            Positioned(
                              left: visibleMembers.length * 14.0,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: AnymeXText(
                                  '+$remainingCount',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],

                  // Join button
                  if (isJoinable)
                    AnymeXText('Join →',
                      size: 13,
                      variant: TextVariant.semiBold,
                      color: cs.primary,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AnymeXText('Full',
                        size: 11,
                        color: cs.onSurfaceVariant,
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
