import 'dart:async';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ListEditorModal extends StatefulWidget {
  final RxString animeStatus;
  final RxDouble animeScore;
  final RxInt animeProgress;
  final Rx<dynamic> currentAnime;
  final Media media;
  final FutureOr<void> Function(String id, double score, String status,
      int progress, int season, DateTime? startedAt, DateTime? completedAt,
      bool? isPrivate) onUpdate;
  final Function(String) onDelete;
  final bool isManga;

  const ListEditorModal({
    super.key,
    required this.animeStatus,
    required this.animeScore,
    required this.animeProgress,
    required this.currentAnime,
    required this.media,
    required this.onUpdate,
    required this.onDelete,
    required this.isManga,
  });

  @override
  State<ListEditorModal> createState() => _ListEditorModalState();
}

class _ListEditorModalState extends State<ListEditorModal> {
  late String _localStatus;
  late double _localScore;
  late int _localProgress;
  late int _localSeason;
  DateTime? _startedAt;
  DateTime? _completedAt;
  bool _isPrivate = false;

  Map<int, int> _simklSeasons = {};
  bool _isLoadingSeasons = false;
  bool _isSaving = false;

  late final TextEditingController _progressController;
  late final TextEditingController _seasonController;

  static const _statuses = [
    ('PLANNING', 'Planning'),
    ('CURRENT', 'Watching'),
    ('COMPLETED', 'Completed'),
    ('REPEATING', 'Repeating'),
    ('PAUSED', 'Paused'),
    ('DROPPED', 'Dropped'),
  ];

  bool get _isAnilist {
    final activeService = Get.find<ServiceHandler>().serviceType;
    return activeService.value == ServicesType.anilist ||
        widget.currentAnime.value?.servicesType == ServicesType.anilist;
  }

  String get _scoreFormat {
    if (_isAnilist && Get.find<AnilistAuth>().isLoggedIn.value) {
      return Get.find<AnilistAuth>().cachedSettings?.scoreFormat ?? 'POINT_10';
    }
    return 'POINT_10_DECIMAL';
  }

  double get _minScore => _scoreFormat == 'POINT_3' ? 1.0 : 0.0;

  double get _maxScore {
    switch (_scoreFormat) {
      case 'POINT_100':
        return 100.0;
      case 'POINT_10_DECIMAL':
      case 'POINT_10':
        return 10.0;
      case 'POINT_5':
        return 5.0;
      case 'POINT_3':
        return 3.0;
      default:
        return 10.0;
    }
  }

  int get _divisions {
    switch (_scoreFormat) {
      case 'POINT_100':
        return 100;
      case 'POINT_10_DECIMAL':
        return 100;
      case 'POINT_10':
        return 10;
      case 'POINT_5':
        return 5;
      case 'POINT_3':
        return 2;
      default:
        return 100;
    }
  }

  String _getScoreDisplayLabel(double score) {
    switch (_scoreFormat) {
      case 'POINT_100':
        return '${score.round()} / 100';
      case 'POINT_10_DECIMAL':
        return '${score.toStringAsFixed(1)} / 10';
      case 'POINT_10':
        return '${score.round()} / 10';
      case 'POINT_5':
        return '${score.round()} / 5';
      case 'POINT_3':
        final val = score.round();
        if (val == 3) return ':)';
        if (val == 2) return ':|';
        return ':(';
      default:
        return '${score.toStringAsFixed(1)} / 10';
    }
  }

  double _getNormalizedScore(double formatScore) {
    switch (_scoreFormat) {
      case 'POINT_100':
        return formatScore;
      case 'POINT_10_DECIMAL':
      case 'POINT_10':
        return formatScore * 10.0;
      case 'POINT_5':
        return formatScore * 20.0;
      case 'POINT_3':
        if (formatScore == 3.0) return 100.0;
        if (formatScore == 2.0) return 50.0;
        return 10.0;
      default:
        return formatScore * 10.0;
    }
  }

  @override
  void initState() {
    super.initState();
    _localStatus =
        widget.animeStatus.value.isEmpty ? 'CURRENT' : widget.animeStatus.value;
    _localProgress = widget.animeProgress.value;
    _localSeason = 1;

    final scoreMin = _minScore;
    final scoreMax = _maxScore;
    
    final rawVal = widget.animeScore.value;
    double initialVal;
    if (_scoreFormat == 'POINT_3') {
      if (rawVal >= 75.0) {
        initialVal = 3.0;
      } else if (rawVal >= 35.0) {
        initialVal = 2.0;
      } else {
        initialVal = 1.0;
      }
    } else {
      initialVal = _isAnilist
          ? Get.find<AnilistAuth>().convertNormalizedToFormat(rawVal)
          : rawVal / 10.0;
    }

    _localScore = initialVal;
    if (_localScore < scoreMin) {
      _localScore = scoreMin;
    } else if (_localScore > scoreMax) {
      _localScore = scoreMax;
    }

    _progressController = TextEditingController(text: _localProgress.toString());
    _seasonController = TextEditingController(text: _localSeason.toString());

    final tracked = widget.currentAnime.value;
    if (tracked != null) {
      _startedAt = tracked.startedAt;
      _completedAt = tracked.completedAt;
      _isPrivate = tracked.isPrivate ?? false;
    }

    final activeService = Get.find<ServiceHandler>().serviceType;
    final isSimklMedia = widget.media.serviceType == ServicesType.simkl ||
        activeService.value == ServicesType.simkl ||
        widget.currentAnime.value?.servicesType == ServicesType.simkl;

    if (isSimklMedia && !widget.isManga) {
      _fetchSimklSeasons();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _seasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchSimklSeasons() async {
    setState(() => _isLoadingSeasons = true);
    final service = Get.find<ServiceHandler>().simklService;
    var listId = widget.currentAnime.value?.id ?? widget.media.id;
    if (!listId.contains('*')) {
      listId = '$listId*SERIES';
    }
    final seasons = await service.getEpisodesBySeason(listId);
    if (mounted) {
      setState(() {
        _simklSeasons = seasons;
        _isLoadingSeasons = false;
        if (_simklSeasons.isNotEmpty && !_simklSeasons.containsKey(_localSeason)) {
          final validSeasons =
              _simklSeasons.keys.where((k) => k > 0).toList()..sort();
          if (validSeasons.isNotEmpty) {
            _localSeason = validSeasons.first;
            _seasonController.text = _localSeason.toString();
          }
        }
      });
    }
  }

  int? get _maxTotal {
    if (_simklSeasons.isNotEmpty && _simklSeasons.containsKey(_localSeason)) {
      return _simklSeasons[_localSeason];
    }
    final tracked = widget.currentAnime.value;
    final preferredRaw = widget.isManga
        ? widget.media.totalChapters
        : widget.media.totalEpisodes;
    final fallbackRaw = tracked?.totalEpisodes;
    final parsedPreferred = _parseKnownPositiveInt(preferredRaw);
    if (parsedPreferred != null) return parsedPreferred;
    return _parseKnownPositiveInt(fallbackRaw);
  }

  String get _displayTotal {
    if (_simklSeasons.isNotEmpty && _simklSeasons.containsKey(_localSeason)) {
      return _simklSeasons[_localSeason]?.toString() ?? '??';
    }
    final tracked = widget.currentAnime.value;
    final preferredRaw = widget.isManga
        ? widget.media.totalChapters
        : widget.media.totalEpisodes;
    final fallbackRaw = tracked?.totalEpisodes;
    final parsedPreferred = _parseKnownPositiveInt(preferredRaw);
    if (parsedPreferred != null) return parsedPreferred.toString();
    final parsedFallback = _parseKnownPositiveInt(fallbackRaw);
    if (parsedFallback != null) return parsedFallback.toString();
    return '??';
  }

  int? _parseKnownPositiveInt(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty || value == '?' || value == '??') return null;
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  int? get _overallTotal {
    if (_simklSeasons.isNotEmpty) {
      return _simklSeasons.entries
          .where((e) => e.key > 0)
          .fold<int>(0, (sum, e) => sum + e.value);
    }
    final tracked = widget.currentAnime.value;
    final preferredRaw = widget.isManga
        ? widget.media.totalChapters
        : widget.media.totalEpisodes;
    final fallbackRaw = tracked?.totalEpisodes;
    return _parseKnownPositiveInt(preferredRaw) ??
        _parseKnownPositiveInt(fallbackRaw);
  }

  void _setProgress(int value, {bool updateController = true}) {
    if (_simklSeasons.isNotEmpty) {
      final validSeasons =
          _simklSeasons.keys.where((k) => k > 0).toList()..sort();
      final currentSeasonMax = _simklSeasons[_localSeason];

      if (currentSeasonMax != null) {
        if (value > currentSeasonMax) {
          final currentIdx = validSeasons.indexOf(_localSeason);
          if (currentIdx != -1 && currentIdx + 1 < validSeasons.length) {
            final nextSeason = validSeasons[currentIdx + 1];
            final remainder = value - currentSeasonMax;
            setState(() {
              _localSeason = nextSeason;
              _seasonController.text = _localSeason.toString();
            });
            _setProgress(remainder, updateController: updateController);
            return;
          }
        } else if (value < 0) {
          final currentIdx = validSeasons.indexOf(_localSeason);
          if (currentIdx > 0) {
            final prevSeason = validSeasons[currentIdx - 1];
            final prevMax = _simklSeasons[prevSeason] ?? 1;
            final remainder = prevMax + value + 1;
            setState(() {
              _localSeason = prevSeason;
              _seasonController.text = _localSeason.toString();
            });
            _setProgress(remainder.clamp(0, prevMax),
                updateController: updateController);
            return;
          }
        }
      }
    }

    final max = _maxTotal;
    setState(() {
      _localProgress =
          max != null ? value.clamp(0, max) : value.clamp(0, 99999);
    });
    if (updateController) {
      _progressController.text = _localProgress.toString();
      _progressController.selection = TextSelection.collapsed(
          offset: _progressController.text.length);
    }
  }

  void _setSeason(int value, {bool updateController = true}) {
    if (_simklSeasons.isNotEmpty) {
      if (!_simklSeasons.containsKey(value)) return;
    }
    setState(() {
      _localSeason = value.clamp(1, 99999);
      if (_simklSeasons.isNotEmpty) {
        final newMax = _simklSeasons[_localSeason];
        if (newMax != null && _localProgress > newMax) {
          _localProgress = 0;
          _progressController.text = '0';
        }
      }
    });
    if (updateController) {
      _seasonController.text = _localSeason.toString();
      _seasonController.selection = TextSelection.collapsed(
          offset: _seasonController.text.length);
    }
  }

  void _applyStatusSideEffects(String newStatus) {
    if (newStatus == 'CURRENT' && _startedAt == null) {
      _startedAt = DateTime.now();
    }
    if (newStatus == 'COMPLETED') {
      _completedAt ??= DateTime.now();
      _startedAt ??= DateTime.now();
    }
    if (newStatus != 'COMPLETED') {
      _completedAt = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildStatusChips(context),
          const SizedBox(height: 20),
          if (widget.media.serviceType == ServicesType.simkl &&
              !widget.isManga) ...[
            if (_isLoadingSeasons) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 20),
            ] else ...[
              _buildSeasonRow(context),
              const SizedBox(height: 20),
            ]
          ],
          _buildProgressRow(context),
          const SizedBox(height: 20),
          _buildScoreRow(context),
          const SizedBox(height: 20),
          _buildDateRow(context),
          if (widget.media.serviceType.isAL) ...[
            const SizedBox(height: 16),
            _buildPrivateRow(context),
          ],
          const SizedBox(height: 24),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Media Entry',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.media.title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surfaceContainerHighest,
            ),
            child: Icon(Icons.close_rounded,
                size: 16, color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChips(BuildContext context) {
    final colors = context.colors;
    final items = _statuses.map((s) {
      final label =
          s.$1 == 'CURRENT' ? (widget.isManga ? 'Reading' : 'Watching') : s.$2;
      return (s.$1, label);
    }).toList();

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final isSelected = _localStatus == items[i].$1;
          return GestureDetector(
            onTap: () {
              setState(() {
                _localStatus = items[i].$1;
                _applyStatusSideEffects(_localStatus);
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                items[i].$2,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeasonRow(BuildContext context) {
    final colors = context.colors;

    final validSeasons =
        _simklSeasons.keys.where((k) => k > 0).toList();
    final maxSeason = validSeasons.isNotEmpty
        ? validSeasons.reduce((a, b) => a > b ? a : b)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Season',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            Text(
              maxSeason != null ? '$_localSeason / $maxSeason' : _localSeason.toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStepButton(
              context,
              icon: Icons.remove_rounded,
              onTap:
                  _localSeason > 1 ? () => _setSeason(_localSeason - 1) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSeasonInput(context),
            ),
            const SizedBox(width: 10),
            _buildStepButton(
              context,
              icon: Icons.add_rounded,
              onTap: (maxSeason == null || _localSeason < maxSeason)
                  ? () => _setSeason(_localSeason + 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeasonInput(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 40,
      child: TextFormField(
        controller: _seasonController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: colors.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          hintText: 'Season',
          hintStyle: TextStyle(color: colors.onSurfaceVariant),
        ),
        onChanged: (v) {
          final n = int.tryParse(v);
          if (n != null && n >= 1) _setSeason(n, updateController: false);
        },
      ),
    );
  }

  Widget _buildProgressRow(BuildContext context) {
    final colors = context.colors;
    final max = _maxTotal;
    final pct = max != null ? (_localProgress / max).clamp(0.0, 1.0) : null;
    final overall = _overallTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                children: [
                  TextSpan(text: '$_localProgress / $_displayTotal'),
                  if (overall != null && _simklSeasons.isNotEmpty)
                    TextSpan(
                      text: '  ($overall total)',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStepButton(
              context,
              icon: Icons.remove_rounded,
              onTap: _localProgress > 0
                  ? () => _setProgress(_localProgress - 1)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: pct != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 4,
                        backgroundColor: colors.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(colors.primary),
                      ),
                    )
                  : _buildProgressInput(context),
            ),
            const SizedBox(width: 10),
            _buildStepButton(
              context,
              icon: Icons.add_rounded,
              onTap: (max == null || _localProgress < max)
                  ? () => _setProgress(_localProgress + 1)
                  : null,
            ),
          ],
        ),
        if (pct != null) ...[
          const SizedBox(height: 8),
          _buildProgressInput(context),
        ],
      ],
    );
  }

  Widget _buildProgressInput(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 40,
      child: TextFormField(
        controller: _progressController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: colors.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          hintText: widget.isManga ? 'Chapters' : 'Episodes',
          hintStyle: TextStyle(color: colors.onSurfaceVariant),
        ),
        onChanged: (v) {
          final n = int.tryParse(v);
          if (n != null && n >= 0) _setProgress(n, updateController: false);
        },
      ),
    );
  }

  Widget _buildStepButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final colors = context.colors;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? colors.onSurface : colors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildScoreRow(BuildContext context) {
    final colors = context.colors;
    final minVal = _minScore;
    final maxVal = _maxScore;
    final divVal = _divisions;
    
    double currentVal = _localScore;
    if (currentVal < minVal) {
      currentVal = minVal;
    } else if (currentVal > maxVal) {
      currentVal = maxVal;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Score',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            Text(
              _getScoreDisplayLabel(currentVal),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Slider(
          year2023: false,
          value: currentVal,
          min: minVal,
          max: maxVal,
          divisions: divVal,
          activeColor: colors.primary,
          inactiveColor: colors.surfaceContainerHighest,
          onChanged: (v) => setState(() => _localScore = v),
        ),
      ],
    );
  }

  Widget _buildDateRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDateTile(context,
              label: 'Start date',
              date: _startedAt,
              onTap: () => _pickDate(context, isStart: true),
              onClear: _startedAt != null
                  ? () => setState(() => _startedAt = null)
                  : null),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDateTile(context,
              label: 'Finish date',
              date: _completedAt,
              onTap: () => _pickDate(context, isStart: false),
              onClear: _completedAt != null
                  ? () => setState(() => _completedAt = null)
                  : null),
        ),
      ],
    );
  }

  Widget _buildDateTile(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ),
                if (onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.close_rounded,
                        size: 13, color: colors.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? _formatDate(date) : 'Not set',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: date != null
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                    fontWeight:
                        date != null ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivateRow(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Private entry',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Hidden from your public profile',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Switch(
          value: _isPrivate,
          onChanged: (val) => setState(() => _isPrivate = val),
          activeColor: colors.primary,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final colors = context.colors;
    final actionsDisabled = _isLoadingSeasons || _isSaving;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: AnymexButton(
              onTap: actionsDisabled ? null : () {
                Navigator.pop(context);
                widget.onDelete(widget.media.id);
              },
              color: colors.surfaceContainerHighest,
              border: BorderSide.none,
              borderRadius: BorderRadius.circular(14),
              child: Text(
                'Delete',
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 46,
            child: AnymexButton(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                      if (actionsDisabled) return;
                      setState(() => _isSaving = true);
                      try {
                        final normalizedScore = _getNormalizedScore(_localScore);
                        await widget.onUpdate(
                          widget.media.id,
                          normalizedScore,
                          _localStatus,
                          _localProgress,
                          _localSeason,
                          _startedAt,
                          _completedAt,
                          widget.media.serviceType.isAL ? _isPrivate : null,
                        );
                        if (mounted) Get.back();
                      } finally {
                        if (mounted) {
                          setState(() => _isSaving = false);
                        }
                      }
                    },
              color: colors.primary,
              border: BorderSide.none,
              child: SizedBox(
                width: 102,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: _isSaving ? 0 : 1,
                      child: Text(
                        'Save changes',
                        style: TextStyle(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_isSaving)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(colors.onPrimary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} / '
      '${date.month.toString().padLeft(2, '0')} / '
      '${date.year}';

  Future<void> _pickDate(BuildContext context, {required bool isStart}) async {
    final initial = isStart
        ? (_startedAt ?? DateTime.now())
        : (_completedAt ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(colorScheme: context.colors),
          child: child!),
    );
    if (picked == null) return;
    setState(() => isStart ? _startedAt = picked : _completedAt = picked);
  }
}
