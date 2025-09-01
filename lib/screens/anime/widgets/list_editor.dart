import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ListEditorModal extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 30.0,
          right: 30.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 80.0,
          top: 20.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'List Editor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildStatusDropdown(context),
            const SizedBox(height: 20),
            _buildProgressField(context),
            const SizedBox(height: 20),
            _buildScoreSlider(context),
            const SizedBox(height: 20),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    return SizedBox(
      height: 55,
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.transparent,
          prefixIcon: const Icon(Icons.playlist_add),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              width: 1,
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              width: 1,
              color: Theme.of(context).colorScheme.primary,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          labelText: 'Status',
          labelStyle: const TextStyle(
            fontFamily: 'Poppins-Bold',
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: Obx(() => DropdownButton<String>(
                isExpanded: true,
                value: animeStatus.value,
                items: [
                  'PLANNING',
                  'CURRENT',
                  'COMPLETED',
                  'REPEATING',
                  'PAUSED',
                  'DROPPED',
                ].map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newStatus) {
                  if (newStatus != null) {
                    animeStatus.value = newStatus;
                  }
                },
              )),
        ),
      ),
    );
  }

  Widget _buildProgressField(BuildContext context) {
    return Obx(() {
      final TextEditingController controller = TextEditingController(
        text: animeProgress.value.toString(),
      );

      final bool isForManga = isManga;

      bool isUnknownTotal() {
        final String? total =
            isForManga ? media.totalChapters : media.totalEpisodes;
        return total == '?' || total == '??' || total == null || total.isEmpty;
      }

      int? getMaxTotal() {
        if (isUnknownTotal()) return null;
        final String total = media.totalEpisodes;
        return int.tryParse(total);
      }

      final int? maxTotal = getMaxTotal();
      final bool hasKnownLimit = maxTotal != null;
      final String unitNamePlural = isForManga ? 'chapters' : 'episodes';

      String getDisplayTotal() {
        if (isForManga) {
          return media.totalChapters ?? '??';
        }
        return media.totalEpisodes;
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              height: isUnknownTotal() ? 80 : 55,
              child: TextFormField(
                keyboardType: TextInputType.number,
                controller: controller,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    isForManga
                        ? Icons.menu_book_outlined
                        : Icons.play_circle_outline,
                  ),
                  suffixText: hasKnownLimit
                      ? '${animeProgress.value}/$maxTotal'
                      : '${animeProgress.value}/${getDisplayTotal()}',
                  filled: true,
                  fillColor: Colors.transparent,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1,
                      color: Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 2,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  labelText: isForManga ? 'Chapters Read' : 'Episodes Watched',
                  labelStyle: const TextStyle(
                    fontFamily: 'Poppins-Bold',
                  ),
                  helperText: hasKnownLimit
                      ? null
                      : '${isForManga ? 'Chapters' : 'Episodes'} unknown - enter any value',
                  helperStyle: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter ${isForManga ? 'chapters read' : 'episodes watched'}';
                  }

                  final int? progress = int.tryParse(value);
                  if (progress == null) return 'Enter a valid number';
                  if (progress < 0) return 'Progress cannot be negative';

                  if (hasKnownLimit && progress > maxTotal) {
                    return 'Cannot exceed $maxTotal $unitNamePlural';
                  }

                  return null;
                },
                onChanged: (String value) {
                  final int? newProgress = int.tryParse(value);

                  if (newProgress == null || newProgress < 0) {
                    return;
                  }

                  if (hasKnownLimit) {
                    animeProgress.value =
                        newProgress <= maxTotal ? newProgress : maxTotal;
                  } else {
                    animeProgress.value = newProgress;
                  }

                  if (animeProgress.value != newProgress) {
                    controller.text = animeProgress.value.toString();
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );
                  }
                },
                onEditingComplete: () {
                  controller.text = animeProgress.value.toString();
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              if (hasKnownLimit) {
                if (animeProgress.value < maxTotal) {
                  animeProgress.value++;
                }
              } else {
                animeProgress.value++;
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 55,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(
                  color: (hasKnownLimit && animeProgress.value >= maxTotal)
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
                      : Theme.of(context).colorScheme.secondaryContainer,
                ),
                borderRadius: BorderRadius.circular(18),
                color: (hasKnownLimit && animeProgress.value >= maxTotal)
                    ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
                    : null,
              ),
              alignment: Alignment.center,
              child: AnymexText(
                text: "+1",
                variant: TextVariant.semiBold,
                color: (hasKnownLimit && animeProgress.value >= maxTotal)
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                    : null,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildScoreSlider(BuildContext context) {
    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Obx(() => Text(
                    'Score: ${animeScore.value.toStringAsFixed(1)}/10',
                    style: const TextStyle(
                      fontFamily: 'Poppins-Bold',
                      fontSize: 16,
                    ),
                  )),
            ],
          ),
          Obx(() => CustomSlider(
                value: animeScore.value,
                min: 0.0,
                max: 10.0,
                divisions: 100,
                label: animeScore.value.toStringAsFixed(1),
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Theme.of(context).colorScheme.secondaryContainer,
                onChanged: (double newValue) {
                  animeScore.value = newValue;
                },
              )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          height: 50,
          width: 120,
          child: AnymexButton(
            onTap: () {
              Navigator.pop(context);
              onDelete(media.id);
            },
            color: Colors.transparent,
            border: BorderSide(
                color: Theme.of(context).colorScheme.secondaryContainer),
            radius: 18,
            child: const Text('Delete'),
          ),
        ),
        SizedBox(
          height: 50,
          width: 120,
          child: AnymexButton(
            onTap: () {
              Get.back();
              onUpdate(
                media.id,
                animeScore.value,
                animeStatus.value,
                animeProgress.value,
              );
            },
            color: Colors.transparent,
            border: BorderSide(
                color: Theme.of(context).colorScheme.secondaryContainer),
            radius: 18,
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}
