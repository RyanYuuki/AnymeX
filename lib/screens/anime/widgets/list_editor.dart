import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dropdown.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ListEditorModal extends StatefulWidget {
  final RxString animeStatus;
  final RxDouble animeScore;
  final RxInt animeProgress;
  final Rx<dynamic> currentAnime;
  final Media media;
  final Function(String, double, String, int) onUpdate;
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
  late TextEditingController _progressController;

  late String _localStatus;
  late double _localScore;
  late int _localProgress;

  @override
  void initState() {
    super.initState();

    _localStatus =
        widget.animeStatus.value.isEmpty ? "CURRENT" : widget.animeStatus.value;
    _localScore = widget.animeScore.value;
    _localProgress = widget.animeProgress.value;

    _progressController = TextEditingController(
      text: _localProgress.toString(),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
          top: 24.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildStatusSection(context),
            const SizedBox(height: 24),
            _buildProgressSection(context),
            const SizedBox(height: 24),
            _buildScoreSection(context),
            const SizedBox(height: 32),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit ${widget.isManga ? 'Manga' : 'Anime'}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Update your progress and rating',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Status',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: AnymexDropdown(
            label: 'Status',
            icon: Icons.info_rounded,
            onChanged: (e) {
              setState(() {
                _localStatus = e.value;
              });
            },
            selectedItem: DropdownItem(
              value: _localStatus,
              text: _getStatusDisplayText(_localStatus),
            ),
            items: [
              ('PLANNING', 'Planning', Icons.schedule_rounded),
              ('CURRENT', 'Watching', Icons.play_circle_rounded),
              ('COMPLETED', 'Completed', Icons.check_circle_rounded),
              ('REPEATING', 'Repeating', Icons.repeat_rounded),
              ('PAUSED', 'Paused', Icons.pause_circle_rounded),
              ('DROPPED', 'Dropped', Icons.cancel_rounded),
            ].map((item) {
              return DropdownItem(
                value: item.$1,
                text: item.$2,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'PLANNING':
        return 'Planning';
      case 'CURRENT':
        return 'Watching';
      case 'COMPLETED':
        return 'Completed';
      case 'REPEATING':
        return 'Repeating';
      case 'PAUSED':
        return 'Paused';
      case 'DROPPED':
        return 'Dropped';
      default:
        return status;
    }
  }

  Widget _buildProgressSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isForManga = widget.isManga;

    bool isUnknownTotal() {
      final String? total =
          isForManga ? widget.media.totalChapters : widget.media.totalEpisodes;
      return total == '?' || total == '??' || total == null || total.isEmpty;
    }

    int? getMaxTotal() {
      if (isUnknownTotal()) return null;
      final String total =
          isForManga ? widget.media.totalChapters! : widget.media.totalEpisodes;
      return int.tryParse(total);
    }

    final int? maxTotal = getMaxTotal();
    final bool hasKnownLimit = maxTotal != null;

    String getDisplayTotal() {
      if (isForManga) {
        return widget.media.totalChapters ?? '??';
      }
      return widget.media.totalEpisodes;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Progress',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.5),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDecrementButton(context),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: TextFormField(
                        controller: _progressController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            isForManga
                                ? Icons.menu_book_rounded
                                : Icons.play_circle_rounded,
                            color: colorScheme.primary,
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withOpacity(0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          labelText:
                              isForManga ? 'Chapters Read' : 'Episodes Watched',
                          labelStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        onChanged: (String value) {
                          final int? newProgress = int.tryParse(value);

                          if (newProgress == null || newProgress < 0) {
                            return;
                          }

                          setState(() {
                            if (hasKnownLimit) {
                              _localProgress = newProgress <= maxTotal
                                  ? newProgress
                                  : maxTotal;
                            } else {
                              _localProgress = newProgress;
                            }
                          });
                        },
                        onEditingComplete: () {
                          setState(() {
                            _progressController.text =
                                _localProgress.toString();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildIncrementButton(context, hasKnownLimit, maxTotal),
                ],
              ),
              const SizedBox(height: 16),
              _buildProgressIndicator(
                  context, hasKnownLimit, maxTotal, getDisplayTotal()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDecrementButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool canDecrement = _localProgress > 0;

    return Material(
      color: canDecrement
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canDecrement
            ? () {
                setState(() {
                  _localProgress--;
                  _progressController.text = _localProgress.toString();
                });
              }
            : null,
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          child: Icon(
            Icons.remove_rounded,
            color: canDecrement
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant.withOpacity(0.5),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildIncrementButton(
      BuildContext context, bool hasKnownLimit, int? maxTotal) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool canIncrement =
        !hasKnownLimit || (hasKnownLimit && _localProgress < maxTotal!);

    return Material(
      color: canIncrement
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canIncrement
            ? () {
                setState(() {
                  _localProgress++;
                  _progressController.text = _localProgress.toString();
                });
              }
            : null,
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          child: Icon(
            Icons.add_rounded,
            color: canIncrement
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant.withOpacity(0.5),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, bool hasKnownLimit,
      int? maxTotal, String displayTotal) {
    final colorScheme = Theme.of(context).colorScheme;
    final double progressPercentage =
        hasKnownLimit ? (_localProgress / maxTotal!).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_localProgress / $displayTotal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (hasKnownLimit)
              Text(
                '${(progressPercentage * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
          ],
        ),
        if (hasKnownLimit) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercentage,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              minHeight: 6,
            ),
          ),
        ],
        if (!hasKnownLimit)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Total ${widget.isManga ? 'chapters' : 'episodes'} unknown',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildScoreSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Rating',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.5),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Score',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_localScore.toStringAsFixed(1)}/10',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomSlider(
                value: _localScore,
                min: 0.0,
                max: 10.0,
                divisions: 100,
                label: _localScore.toStringAsFixed(1),
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                onChanged: (double newValue) {
                  setState(() {
                    _localScore = newValue;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: AnymexButton(
              onTap: () {
                Navigator.pop(context);
                widget.onDelete(widget.media.id);
              },
              color: colorScheme.errorContainer,
              border: BorderSide.none,
              radius: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_rounded,
                    color: colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 56,
            child: AnymexButton(
              onTap: () {
                Get.back();
                widget.onUpdate(
                  widget.media.id,
                  _localScore,
                  _localStatus,
                  _localProgress,
                );
              },
              color: colorScheme.primary,
              border: BorderSide.none,
              radius: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save_rounded,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Save Changes',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
